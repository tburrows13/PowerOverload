-- Draws each transformer's output (downstream) network on the map:
--   * a coloured dot over every tracked pole of that network, and
--   * a persistent name label at the transformer (like a train-stop name).
--
-- Objects are persistent (drawn once, kept until something changes) rather than
-- redrawn every tick, to stay within the mod's performance budget. A dirty flag
-- coalesces bursts of build/mine events into at most one rebuild per throttle
-- window, plus a slow periodic rebuild to catch rewiring (which changes
-- electric_network_id without a build event).

local REBUILD_THROTTLE = 15    -- ticks between rebuilds while dirty (~0.25s)
local PERIODIC_REBUILD = 300   -- ticks between forced rebuilds (~5s)

-- Marks the overlay for a rebuild on the next throttle window.
function mark_overlay_dirty()
  storage.overlay_dirty = true
end

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
local function build_network_identity_map()
  local map = {}
  for unit_number, transformer_parts in pairs(storage.transformers) do
    local entity = transformer_parts.transformer
    if entity and entity.valid then
      local net_id = get_transformer_output_network_id(transformer_parts)
      if net_id then
        local existing = map[net_id]
        if not existing or unit_number < existing.unit_number then
          ensure_transformer_identity(transformer_parts, unit_number)
          map[net_id] = {
            color = transformer_parts.color,
            name = transformer_parts.name,
            surface = entity.surface,
            force = entity.force,
            unit_number = unit_number,
            position = entity.position,
          }
        end
      end
    end
  end
  return map
end

-- Destroys any previously drawn overlay objects. Tracked by numeric id, which
-- is safe to store across save/load (unlike the LuaRenderObject handle itself).
local function clear_overlay_objects()
  local ids = storage.network_overlay_object_ids
  if ids then
    for i = #ids, 1, -1 do
      local object = rendering.get_object_by_id(ids[i])
      if object and object.valid then
        object.destroy()
      end
      ids[i] = nil
    end
  else
    storage.network_overlay_object_ids = {}
  end
end

local COPPER = defines.wire_connector_id.pole_copper

-- Draws a small coloured dot on every tracked pole belonging to a coloured
-- network (so isolated poles with no wires still show).
---@param pole_list PoleData[]
---@param identity_map table
---@param ids uint64[]
local function draw_pole_dots(pole_list, identity_map, ids)
  for _, pole_data in pairs(pole_list) do
    local pole = pole_data.entity
    if pole and pole.valid then
      local entry = identity_map[pole.electric_network_id]
      if entry then
        local c = entry.color
        ids[#ids + 1] = rendering.draw_circle{
          color = {r = c.r, g = c.g, b = c.b, a = 0.8},
          radius = 0.8,
          filled = true,
          target = pole.position,
          surface = pole.surface,
          forces = {entry.force},
          render_mode = "chart",
        }.id
      end
    end
  end
end

-- Draws a coloured line along every copper connection between poles of a
-- coloured network (this is what makes the network read as coloured on the map,
-- since the game's own wire colour can't be changed). Connections are de-duped
-- via `drawn` so each wire is only drawn once.
---@param pole_list PoleData[]
---@param identity_map table
---@param ids uint64[]
---@param drawn table<string, boolean>
local function draw_pole_lines(pole_list, identity_map, ids, drawn)
  for _, pole_data in pairs(pole_list) do
    local pole = pole_data.entity
    if pole and pole.valid then
      local entry = identity_map[pole.electric_network_id]
      if entry then
        local connector = pole.get_wire_connector(COPPER, false)
        if connector then
          local c = entry.color
          for _, connection in pairs(connector.connections) do
            local other = connection.target and connection.target.owner
            if other and other.valid then
              local a, b = pole.unit_number, other.unit_number
              local key = (a < b) and (a .. "_" .. b) or (b .. "_" .. a)
              if not drawn[key] then
                drawn[key] = true
                ids[#ids + 1] = rendering.draw_line{
                  color = {r = c.r, g = c.g, b = c.b, a = 0.9},
                  width = 8,
                  from = pole.position,
                  to = other.position,
                  surface = pole.surface,
                  forces = {entry.force},
                  render_mode = "chart",
                }.id
              end
            end
          end
        end
      end
    end
  end
end

-- Rebuilds the whole overlay from scratch.
function rebuild_network_overlay()
  clear_overlay_objects()
  local ids = storage.network_overlay_object_ids

  local identity_map = build_network_identity_map()

  -- Coloured lines along the wires + a dot on each pole of every coloured network.
  local drawn = {}
  draw_pole_lines(storage.poles, identity_map, ids, drawn)
  draw_pole_lines(storage.fuses, identity_map, ids, drawn)
  draw_pole_dots(storage.poles, identity_map, ids)
  draw_pole_dots(storage.fuses, identity_map, ids)

  -- One name label per network, at its lowest-unit_number transformer.
  for _, entry in pairs(identity_map) do
    local players = {}
    if entry.name and entry.name ~= "" then
      for _, player in pairs(entry.force.connected_players) do
        if names_visible_for(player.index) then
          players[#players + 1] = player
        end
      end
    end
    if #players > 0 then
      ids[#ids + 1] = rendering.draw_text{
        text = entry.name,
        surface = entry.surface,
        target = {x = entry.position.x, y = entry.position.y - 1.5},
        color = entry.color,
        scale = 6,
        alignment = "center",
        vertical_alignment = "middle",
        render_mode = "chart",
        players = players,
      }.id
    end
  end
end

-- Called every tick from the main loop. Rebuilds when dirty (throttled) and
-- periodically to catch rewiring.
---@param tick GameTick
function update_network_overlay(tick)
  if tick % PERIODIC_REBUILD == 0 then
    storage.overlay_dirty = true
  end
  if storage.overlay_dirty and tick % REBUILD_THROTTLE == 0 then
    rebuild_network_overlay()
    storage.overlay_dirty = false
  end
end

-- Sets whether a player sees network name labels, and refreshes immediately.
---@param player LuaPlayer
---@param visible boolean
function set_network_names_visible(player, visible)
  storage.show_network_names = storage.show_network_names or {}
  storage.show_network_names[player.index] = visible
  rebuild_network_overlay()
end
