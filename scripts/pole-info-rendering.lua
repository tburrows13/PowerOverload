-- Draws the "consumption / max" text above the pole currently hovered by each
-- player.
--
-- Runs every tick, so the text object is kept alive between ticks and only its
-- text and colour are updated: destroying and recreating it every tick was
-- noticeable in large bases. It is recreated only when the hovered pole changes.
-- Objects are tracked by numeric id, which is safe to store across save/load
-- (unlike the LuaRenderObject handle itself).

-- Drops every text object this module owns, including the flat id list used by
-- versions before the per-player objects existed.
function reset_pole_info_rendering()
  local old_ids = storage.pole_info_object_ids
  if old_ids then
    for i = #old_ids, 1, -1 do
      local object = rendering.get_object_by_id(old_ids[i])
      if object and object.valid then
        object.destroy()
      end
    end
    storage.pole_info_object_ids = nil
  end
  for _, info in pairs(storage.pole_info or {}) do
    local object = rendering.get_object_by_id(info.id)
    if object and object.valid then
      object.destroy()
    end
  end
  storage.pole_info = {}
end

---@param player_index uint
local function clear_player_info(player_index)
  local info = storage.pole_info[player_index]
  if not info then return end
  local object = rendering.get_object_by_id(info.id)
  if object and object.valid then
    object.destroy()
  end
  storage.pole_info[player_index] = nil
end

---@param tick GameTick
function update_pole_rendering(tick)
  local infos = storage.pole_info

  for _, player in pairs(game.connected_players) do
    local player_index = player.index
    local pole = player.selected
    local max_consumptions = pole and pole.type == "electric-pole" and pole.force == player.force
      and storage.max_consumptions[pole.name]

    if not max_consumptions then
      clear_player_info(player_index)
    else
      -- Divide by 1.01 because amount is originally multiplied by that for hidden leeway
      local max_consumption = max_consumptions[pole.quality.name] / 1.01
      local consumption = get_network_consumption(pole, tick)
      local ratio = consumption / max_consumption
      local colour_key = "ok"
      if ratio > 1 then
        colour_key = "over"
      elseif ratio > 0.8 then
        colour_key = "near"
      end
      local text = shared.format_energy_number(consumption) .. " / " .. shared.format_energy_number(max_consumption)

      local info = infos[player_index]
      local object = info and rendering.get_object_by_id(info.id)
      if object and object.valid and info.unit_number == pole.unit_number then
        if info.text ~= text then
          object.text = text
          info.text = text
        end
        if info.colour_key ~= colour_key then
          object.color = shared.pole_info_colours[colour_key]
          info.colour_key = colour_key
        end
      else
        clear_player_info(player_index)
        infos[player_index] = {
          id = rendering.draw_text{
            text = text,
            surface = pole.surface,
            target = {entity = pole, offset = {x = 0, y = 0.7}},
            color = shared.pole_info_colours[colour_key],
            scale = 1.5 * player.display_scale,
            alignment = "center",
            scale_with_zoom = true,
            players = {player},
          }.id,
          unit_number = pole.unit_number,
          text = text,
          colour_key = colour_key,
        }
      end
    end
  end

  -- Players that disconnected while their text was up.
  for player_index in pairs(infos) do
    local player = game.get_player(player_index)
    if not (player and player.connected) then
      clear_player_info(player_index)
    end
  end
end
