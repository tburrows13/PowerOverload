-- Draws each transformer's output (downstream) network on the map:
--   * a coloured line along every copper wire of that network,
--   * a coloured dot over every tracked pole of that network, and
--   * a persistent name label at the transformer (like a train-stop name).
--
-- The overlay is maintained *incrementally*. Nothing ever rebuilds the whole
-- world in a single tick, so the per-tick cost is bounded and proportional to
-- what actually changed:
--
--   * build/mine events queue only the affected poles (and their neighbours),
--   * a cursor walks the pole lists a slice at a time to catch rewiring, which
--     changes electric_network_id without raising any event,
--   * transformer identities (name/colour/output network) are diffed on a slow
--     cadence and only the affected networks are touched.
--
-- Render objects are anchored to entities rather than to positions, so they
-- follow moved poles and are cleaned up by the game when the entity dies. They
-- are tracked by numeric id, which is safe to store across save/load (unlike
-- the LuaRenderObject handle itself).

local IDENTITY_INTERVAL = 20     -- ticks between transformer identity diffs
local SCAN_TICKS = 300           -- target ticks for one full pass over the pole lists (~5s)
local MAX_SCAN_PER_TICK = 100    -- hard cap on poles examined per tick
local MAX_DIRTY_PER_TICK = 60    -- hard cap on poles redrawn per tick (>= scan budget, so the queue drains)
local SWEEP_INTERVAL = 36000     -- ~10 min: drop overlay entries whose pole is gone

local COPPER = defines.wire_connector_id.pole_copper

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

-- storage.overlay = {
--   poles    = {[pole_unit_number] = {net = net_id, dot = id, lines = {[other_unit_number] = id}}},
--   labels   = {[net_id] = {id = id?, revision = uint}},
--   identity = {[net_id] = {name, color, unit_number, force, surface_index, x, y}},
--   by_net   = {[net_id] = {[pole_unit_number] = true}},
--   dirty    = {[pole_unit_number] = true},
--   scan_pos, scan_list, names_revision, identity_dirty, identity_full,
-- }

-- Creates the overlay state from scratch. Any render objects already tracked are
-- destroyed first, so this doubles as the migration path from the old flat
-- `storage.network_overlay_object_ids` array.
function init_network_overlay()
  local old_ids = storage.network_overlay_object_ids
  if old_ids then
    for i = #old_ids, 1, -1 do
      local object = rendering.get_object_by_id(old_ids[i])
      if object and object.valid then
        object.destroy()
      end
    end
    storage.network_overlay_object_ids = nil
  end

  local overlay = storage.overlay
  if overlay then
    for unit_number in pairs(overlay.poles or {}) do
      clear_pole_overlay(unit_number)
    end
    for _, label in pairs(overlay.labels or {}) do
      if label.id then
        local object = rendering.get_object_by_id(label.id)
        if object and object.valid then
          object.destroy()
        end
      end
    end
  end

  storage.overlay = {
    poles = {},
    labels = {},
    identity = {},
    by_net = {},
    dirty = {},
    scan_pos = 1,
    scan_list = "poles",
    names_revision = 1,
    identity_dirty = true,
    identity_full = true,
  }
end

---@param id uint64?
local function destroy_object(id)
  if not id then return end
  local object = rendering.get_object_by_id(id)
  if object and object.valid then
    object.destroy()
  end
end

--------------------------------------------------------------------------------
-- Dirty marking (called from event handlers)
--------------------------------------------------------------------------------

-- Queues a single pole for a redraw on one of the next few ticks.
---@param unit_number uint?
function mark_pole_dirty(unit_number)
  local overlay = storage.overlay
  if overlay and unit_number then
    overlay.dirty[unit_number] = true
  end
end

-- Queues a pole and everything it is wired to. Neighbours matter because a wire
-- is drawn by exactly one of its two ends (see `owns_edge`), so a new or removed
-- connection can be the neighbour's responsibility rather than this pole's.
---@param pole LuaEntity?
function mark_pole_and_neighbours_dirty(pole)
  if not (pole and pole.valid) then return end
  mark_pole_dirty(pole.unit_number)
  local connector = pole.get_wire_connector(COPPER, false)
  if not connector then return end
  for _, connection in pairs(connector.connections) do
    local other = connection.target and connection.target.owner
    if other and other.valid then
      mark_pole_dirty(other.unit_number)
    end
  end
end

-- Called when a pole is about to disappear, while it is still wired up so its
-- neighbours can still be found.
---@param pole LuaEntity?
function on_pole_removed(pole)
  if not (pole and pole.valid) then return end
  mark_pole_and_neighbours_dirty(pole)
  local unit_number = pole.unit_number
  if unit_number then
    storage.pole_index[unit_number] = nil
    clear_pole_overlay(unit_number)
  end
end

-- Requests a transformer identity diff. `full` also re-reads transformer
-- positions, which are otherwise carried over from the previous diff.
---@param full boolean?
function mark_identity_dirty(full)
  local overlay = storage.overlay
  if not overlay then return end
  overlay.identity_dirty = true
  if full then
    overlay.identity_full = true
  end
end

-- Invalidates every name label (a player toggled the labels, joined or left).
function mark_names_dirty()
  local overlay = storage.overlay
  if not overlay then return end
  overlay.names_revision = overlay.names_revision + 1
  overlay.identity_dirty = true
end

--------------------------------------------------------------------------------
-- Per-pole overlay
--------------------------------------------------------------------------------

-- Moves a pole between the reverse net_id -> poles buckets. Every tracked pole
-- is in a bucket, including poles whose network has no transformer identity, so
-- that an identity appearing later can find them again.
--
-- A pole moving from one real network to another is the only evidence we get
-- that networks were merged or split, so the rest of the network it left is
-- queued as well. That propagates the change across the whole network within a
-- few ticks without having to scan for it, and it terminates on its own: poles
-- that find their network unchanged do not move bucket and so cascade nothing.
local function set_pole_net(overlay, unit_number, net_id)
  local entry = overlay.poles[unit_number]
  local old_net = entry and entry.net
  if old_net == net_id then return end
  if old_net then
    local bucket = overlay.by_net[old_net]
    if bucket then
      bucket[unit_number] = nil
      if next(bucket) == nil then
        overlay.by_net[old_net] = nil
      elseif net_id then
        local dirty = overlay.dirty
        for other_unit_number in pairs(bucket) do
          dirty[other_unit_number] = true
        end
      end
    end
  end
  if net_id then
    local bucket = overlay.by_net[net_id]
    if not bucket then
      bucket = {}
      overlay.by_net[net_id] = bucket
    end
    bucket[unit_number] = true
  end
end

-- Destroys everything drawn for one pole and forgets it.
---@param unit_number uint
function clear_pole_overlay(unit_number)
  local overlay = storage.overlay
  if not overlay then return end
  local entry = overlay.poles[unit_number]
  if not entry then return end
  destroy_object(entry.dot)
  for _, id in pairs(entry.lines) do
    destroy_object(id)
  end
  set_pole_net(overlay, unit_number, nil)
  overlay.poles[unit_number] = nil
end

-- Decides which end of a wire draws it, so each wire is drawn exactly once
-- without needing a per-rebuild dedup table. Both ends of a copper wire are
-- always in the same electric network, so they always agree on the colour.
-- Untracked neighbours (the transformer's hidden poles, poles from mods that
-- did not register) never draw, so the tracked end always does.
local function owns_edge(unit_number, other_unit_number)
  local other = storage.pole_index[other_unit_number]
  if other then
    return unit_number < other_unit_number
  end
  return true
end

-- Redraws one pole: its dot and the wires it owns.
---@param unit_number uint
local function refresh_pole(unit_number)
  local overlay = storage.overlay
  local pole_data = storage.pole_index[unit_number]
  local pole = pole_data and pole_data.entity
  if not (pole and pole.valid) then
    clear_pole_overlay(unit_number)
    return
  end

  local entry = overlay.poles[unit_number]
  if not entry then
    entry = {lines = {}}
    overlay.poles[unit_number] = entry
  end

  local net_id = pole.electric_network_id
  set_pole_net(overlay, unit_number, net_id)
  entry.net = net_id

  local identity = net_id and overlay.identity[net_id]
  local lines = entry.lines
  if not identity then
    destroy_object(entry.dot)
    entry.dot = nil
    for other_unit_number, id in pairs(lines) do
      destroy_object(id)
      lines[other_unit_number] = nil
    end
    return
  end

  local c = identity.color
  local force = identity.force
  local surface = pole.surface

  local dot_color = {r = c.r, g = c.g, b = c.b, a = 0.8}
  local dot = entry.dot and rendering.get_object_by_id(entry.dot)
  if dot and dot.valid then
    dot.color = dot_color
  else
    entry.dot = rendering.draw_circle{
      color = dot_color,
      radius = 0.8,
      filled = true,
      target = pole,
      surface = surface,
      forces = {force},
      render_mode = "chart",
    }.id
  end

  local line_color = {r = c.r, g = c.g, b = c.b, a = 0.9}
  local seen
  local connector = pole.get_wire_connector(COPPER, false)
  if connector then
    for _, connection in pairs(connector.connections) do
      local other = connection.target and connection.target.owner
      local other_unit_number = other and other.valid and other.unit_number
      if other_unit_number and owns_edge(unit_number, other_unit_number) then
        seen = seen or {}
        seen[other_unit_number] = true
        local line = lines[other_unit_number] and rendering.get_object_by_id(lines[other_unit_number])
        if line and line.valid then
          line.color = line_color
        else
          lines[other_unit_number] = rendering.draw_line{
            color = line_color,
            width = 8,
            from = pole,
            to = other,
            surface = surface,
            forces = {force},
            render_mode = "chart",
          }.id
        end
      end
    end
  end
  for other_unit_number, id in pairs(lines) do
    if not (seen and seen[other_unit_number]) then
      destroy_object(id)
      lines[other_unit_number] = nil
    end
  end
end

-- Queues every pole of one network for a redraw.
local function mark_net_dirty(overlay, net_id)
  local bucket = overlay.by_net[net_id]
  if not bucket then return end
  local dirty = overlay.dirty
  for unit_number in pairs(bucket) do
    dirty[unit_number] = true
  end
end

--------------------------------------------------------------------------------
-- Transformer identities and name labels
--------------------------------------------------------------------------------

-- Returns true if the given player currently wants network name labels shown.
---@param player_index uint
---@return boolean
local function names_visible_for(player_index)
  local show = storage.show_network_names
  -- Default on: only an explicit false hides them.
  return not (show and show[player_index] == false)
end

-- Builds a map of output-network-id -> identity, resolving conflicts (several
-- transformers feeding the same output network) in favour of the lowest
-- unit_number so the shown name/colour is stable.
--
-- Position, force and surface are carried over from the previous diff unless
-- `full` is set, so the common case costs only a validity check and a network
-- id read per transformer.
local function collect_identities(overlay, full)
  local previous = overlay.identity
  local map = {}
  for unit_number, transformer_parts in pairs(storage.transformers) do
    local entity = transformer_parts.transformer
    if entity and entity.valid then
      local net_id = get_transformer_output_network_id(transformer_parts)
      if net_id then
        local existing = map[net_id]
        if not existing or unit_number < existing.unit_number then
          ensure_transformer_identity(transformer_parts, unit_number)
          local color = transformer_parts.color
          local old = previous[net_id]
          if not full and old and old.unit_number == unit_number
              and old.name == transformer_parts.name
              and old.color.r == color.r and old.color.g == color.g and old.color.b == color.b then
            -- Unchanged: reuse the entry rather than rebuilding it. Most passes
            -- change nothing, and a base can hold thousands of transformers.
            map[net_id] = old
          else
            local identity = {
              name = transformer_parts.name,
              color = {r = color.r, g = color.g, b = color.b, a = 1},
              unit_number = unit_number,
            }
            if full or not (old and old.unit_number == unit_number) then
              local position = entity.position
              identity.force = entity.force.index
              identity.surface_index = entity.surface.index
              identity.x = position.x
              identity.y = position.y
            else
              identity.force = old.force
              identity.surface_index = old.surface_index
              identity.x = old.x
              identity.y = old.y
            end
            map[net_id] = identity
          end
        end
      end
    end
  end
  return map
end

-- Redraws the single name label of one network. An entry is stored even when
-- nothing is drawn (no name, or nobody wants to see it) so the diff does not
-- keep considering it stale.
local function refresh_label(overlay, net_id, identity)
  local label = overlay.labels[net_id]
  if label then
    destroy_object(label.id)
  end
  if not identity then
    overlay.labels[net_id] = nil
    return
  end

  local id
  if identity.name and identity.name ~= "" then
    local players
    for _, player in pairs(game.connected_players) do
      if player.force.index == identity.force and names_visible_for(player.index) then
        players = players or {}
        players[#players + 1] = player.index
      end
    end
    if players then
      id = rendering.draw_text{
        text = identity.name,
        surface = identity.surface_index,
        target = {x = identity.x, y = identity.y - 1.5},
        color = identity.color,
        scale = 6,
        alignment = "center",
        vertical_alignment = "middle",
        render_mode = "chart",
        use_rich_text = true,
        players = players,
      }.id
    end
  end
  overlay.labels[net_id] = {id = id, revision = overlay.names_revision}
end

local function colors_differ(a, b)
  return a.r ~= b.r or a.g ~= b.g or a.b ~= b.b
end

-- Diffs the transformer identities against the last pass and touches only what
-- changed: labels are redrawn one at a time, and networks whose colour appeared,
-- changed or disappeared have their poles queued for a redraw.
local function update_identities(overlay)
  local new_map = collect_identities(overlay, overlay.identity_full)
  local old_map = overlay.identity
  local revision = overlay.names_revision

  local relabel, recolour, removed
  for net_id, identity in pairs(new_map) do
    local old = old_map[net_id]
    local label = overlay.labels[net_id]
    if not old
        or old.name ~= identity.name
        or old.force ~= identity.force
        or old.surface_index ~= identity.surface_index
        or old.x ~= identity.x
        or old.y ~= identity.y
        or colors_differ(old.color, identity.color)
        or not label
        or label.revision ~= revision then
      relabel = relabel or {}
      relabel[net_id] = true
    end
    if not old or colors_differ(old.color, identity.color) then
      recolour = recolour or {}
      recolour[net_id] = true
    end
  end
  for net_id in pairs(old_map) do
    if not new_map[net_id] then
      removed = removed or {}
      removed[net_id] = true
    end
  end

  -- Publish the new identities before redrawing: refresh_pole reads them.
  overlay.identity = new_map
  overlay.identity_full = nil

  if relabel then
    for net_id in pairs(relabel) do
      refresh_label(overlay, net_id, new_map[net_id])
    end
  end
  if recolour then
    for net_id in pairs(recolour) do
      mark_net_dirty(overlay, net_id)
    end
  end
  if removed then
    for net_id in pairs(removed) do
      refresh_label(overlay, net_id, nil)
      mark_net_dirty(overlay, net_id)
    end
  end
end

--------------------------------------------------------------------------------
-- Incremental scan
--------------------------------------------------------------------------------

-- Walks a slice of the pole lists looking for poles whose electric network
-- changed without an event (someone dragged a copper wire, or a pole died and
-- split a network). Invalid entries are swap-removed on the way, which also
-- keeps storage.poles/storage.fuses from accumulating dead poles.
local function scan_slice(overlay)
  local poles = storage.poles
  local fuses = storage.fuses
  local pole_count = #poles
  local fuse_count = #fuses
  local total = pole_count + fuse_count
  if total == 0 then return end

  local budget = math.ceil(total / SCAN_TICKS)
  if budget > MAX_SCAN_PER_TICK then budget = MAX_SCAN_PER_TICK end

  local dirty = overlay.dirty
  local entries = overlay.poles
  local on_fuses = overlay.scan_list == "fuses"
  local list = on_fuses and fuses or poles
  local size = on_fuses and fuse_count or pole_count
  local position = overlay.scan_pos
  local switches = 0

  while budget > 0 do
    if position > size then
      if switches >= 2 then break end
      switches = switches + 1
      on_fuses = not on_fuses
      overlay.scan_list = on_fuses and "fuses" or "poles"
      list = on_fuses and fuses or poles
      size = on_fuses and fuse_count or pole_count
      position = 1
    else
      local pole_data = list[position]
      local pole = pole_data.entity
      if pole and pole.valid then
        local unit_number = pole_data.unit_number
        local entry = entries[unit_number]
        if not entry or entry.net ~= pole.electric_network_id then
          dirty[unit_number] = true
        end
        position = position + 1
      else
        local unit_number = pole_data.unit_number
        if unit_number then
          storage.pole_index[unit_number] = nil
          clear_pole_overlay(unit_number)
        end
        list[position] = list[size]
        list[size] = nil
        size = size - 1
        -- Deliberately not advancing: the swapped-in entry still needs checking.
      end
      budget = budget - 1
    end
  end

  overlay.scan_pos = position
end

-- Safety net for overlay entries whose pole vanished without going through
-- on_pole_removed or the scan. Cheap enough to run every few minutes.
local function sweep_orphans(overlay)
  local index = storage.pole_index
  for unit_number in pairs(overlay.poles) do
    if not index[unit_number] then
      clear_pole_overlay(unit_number)
    end
  end
end

--------------------------------------------------------------------------------
-- Main loop
--------------------------------------------------------------------------------

-- Called every tick from the main loop. Every stage is budgeted, so the cost of
-- a single tick never scales with the size of the base.
---@param tick GameTick
function update_network_overlay(tick)
  local overlay = storage.overlay
  if not overlay then return end

  if overlay.identity_dirty or tick % IDENTITY_INTERVAL == 0 then
    overlay.identity_dirty = nil
    update_identities(overlay)
  end

  local dirty = overlay.dirty
  local processed = 0
  local unit_number = next(dirty)
  while unit_number and processed < MAX_DIRTY_PER_TICK do
    dirty[unit_number] = nil
    refresh_pole(unit_number)
    processed = processed + 1
    unit_number = next(dirty)
  end

  scan_slice(overlay)

  if tick % SWEEP_INTERVAL == 0 then
    sweep_orphans(overlay)
  end
end

-- Sets whether a player sees network name labels.
---@param player LuaPlayer
---@param visible boolean
function set_network_names_visible(player, visible)
  storage.show_network_names = storage.show_network_names or {}
  storage.show_network_names[player.index] = visible
  mark_names_dirty()
end
