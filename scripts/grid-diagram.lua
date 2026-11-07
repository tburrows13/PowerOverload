-- Grid diagram: a one-line schematic of the transformer grid on the map.
--
-- One straight line per route, from each transformer to each downstream
-- transformer it feeds (the routes found by line-losses.lua):
--   width  = power on the route (the source's output split among the
--            transformers it feeds in proportion to their draw)
--   colour = line loss on the route: green < 10%, yellow < 50%, red above;
--            grey when no power flows
--   label  = "power · loss" at the midpoint, dot at the downstream end
-- Map view only, and only for players who switched it on with the
-- "Toggle grid diagram" shortcut (off by default, per player).
--
-- Self-contained so it is easy to disable or remove:
--   * disable: leave the shortcut off. When no connected player has it on,
--     nothing is computed and every drawing is removed.
--   * remove:  switch it off for everyone (clears the drawings), then delete
--     this file and every block marked "grid-diagram" (control.lua,
--     prototypes/shortcuts.lua, locale), plus the two grid-diagram icons in
--     graphics/shortcuts.

local UPDATE_INTERVAL = 60
local SHORTCUT = "po-toggle-grid-diagram"

local COLOURS = {
  ok = {r = 0.2, g = 0.9, b = 0.2},
  near = {r = 1, g = 0.85, b = 0.1},
  over = {r = 1, g = 0.2, b = 0.2},
  idle = {r = 0.5, g = 0.5, b = 0.5},
}

local function destroy(id)
  if not id then return end
  local object = rendering.get_object_by_id(id)
  if object and object.valid then object.destroy() end
end

local function destroy_route(route)
  destroy(route.line)
  destroy(route.label)
  destroy(route.dot)
end

-- Removes every drawing this module made.
function grid_diagram_clear()
  local state = storage.grid_diagram
  if not state then return end
  for _, route in pairs(state.routes) do
    destroy_route(route)
  end
  storage.grid_diagram = nil
end

---@return uint[] players, string key  players with the diagram on, and a key to detect changes
local function viewers()
  local list, parts = {}, {}
  for _, player in pairs(game.connected_players) do
    if player.is_shortcut_toggled(SHORTCUT) then
      list[#list + 1] = player.index
      parts[#parts + 1] = player.index
    end
  end
  return list, table.concat(parts, ",")
end

local function band_for(power, loss)
  if power <= 0 then return "idle" end
  if loss >= 0.5 then return "over" end
  if loss >= 0.1 then return "near" end
  return "ok"
end

-- 10 kW -> 1 ... 1 GW -> 8, logarithmic so small and huge flows both read
local function width_for(power)
  if power <= 10000 then return 1 end
  local w = 1 + 1.5 * math.log(power / 10000, 10)
  if w > 8 then w = 8 end
  return math.floor(w * 2 + 0.5) / 2  -- half steps, so tiny changes do not redraw
end

local function midpoint(a, b)
  return {x = (a.x + b.x) / 2, y = (a.y + b.y) / 2}
end

-- Flips the shortcut for a player and redraws straight away rather than
-- waiting for the next 60-tick update.
---@param player LuaPlayer
---@param tick GameTick
function toggle_grid_diagram(player, tick)
  player.set_shortcut_toggled(SHORTCUT, not player.is_shortcut_toggled(SHORTCUT))
  update_grid_diagram(tick, true)
end

---@param tick GameTick
---@param force boolean?  update now regardless of the interval
function update_grid_diagram(tick, force)
  if not force and tick % UPDATE_INTERVAL ~= 0 then return end
  local players, players_key = viewers()
  if #players == 0 or not storage.global_settings["power-overload-line-losses"] then
    grid_diagram_clear()
    return
  end

  local state = storage.grid_diagram
  if not state then
    state = {routes = {}, players_key = players_key}
    storage.grid_diagram = state
  end
  local players_changed = state.players_key ~= players_key
  state.players_key = players_key

  local transformers = storage.transformers
  local seen = {}

  for source_unit, source in pairs(transformers) do
    local source_entity = source.transformer
    local load_total = source.line_load_total or 0
    if source_entity and source_entity.valid and source.line_sinks then
      for _, sink in pairs(source.line_sinks) do
        local sink_parts = transformers[sink.unit]
        local sink_entity = sink_parts and sink_parts.transformer
        if sink_entity and sink_entity.valid and sink_entity.surface.index == source_entity.surface.index then
          local key = source_unit .. ">" .. sink.unit
          seen[key] = true

          -- Proportional sharing: this route carries the source's output
          -- times the sink's share of the network's load
          local power = 0
          if load_total > 0 then
            power = (source.p_out or 0) * (sink_parts.p_in or 0) / load_total
          end
          local loss = get_route_line_loss(sink.d)
          local band = band_for(power, loss)
          local width = width_for(power)
          local text = shared.format_energy_number(power) .. " · " .. string.format("%.1f", loss * 100) .. "%"

          local route = state.routes[key]
          if route and not (rendering.get_object_by_id(route.line) or {}).valid then
            destroy_route(route)
            route = nil
          end

          if not route then
            local from, to = source_entity.position, sink_entity.position
            route = {
              band = band, width = width, text = text,
              line = rendering.draw_line{
                color = COLOURS[band], width = width,
                from = source_entity, to = sink_entity,
                surface = source_entity.surface, players = players,
                render_mode = "chart",
              }.id,
              dot = rendering.draw_circle{
                color = COLOURS[band], radius = 1.5, filled = true,
                target = sink_entity,
                surface = source_entity.surface, players = players,
                render_mode = "chart",
              }.id,
              label = rendering.draw_text{
                text = text, color = COLOURS[band], scale = 3,
                target = midpoint(from, to),
                surface = source_entity.surface, players = players,
                alignment = "center", vertical_alignment = "middle",
                render_mode = "chart",
              }.id,
            }
            state.routes[key] = route
          else
            local line = rendering.get_object_by_id(route.line)
            local dot = rendering.get_object_by_id(route.dot)
            local label = rendering.get_object_by_id(route.label)
            if route.band ~= band then
              for _, object in pairs({line, dot, label}) do
                if object and object.valid then object.color = COLOURS[band] end
              end
              route.band = band
            end
            if route.width ~= width and line and line.valid then
              line.width = width
              route.width = width
            end
            if route.text ~= text and label and label.valid then
              label.text = text
              route.text = text
            end
            if players_changed then
              for _, object in pairs({line, dot, label}) do
                if object and object.valid then object.players = players end
              end
            end
          end
        end
      end
    end
  end

  -- Routes that no longer exist (transformer removed, rewired)
  for key, route in pairs(state.routes) do
    if not seen[key] then
      destroy_route(route)
      state.routes[key] = nil
    end
  end
end
