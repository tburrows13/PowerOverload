-- Draws the "consumption / max" text above the pole currently hovered by each
-- player. Runs every tick, so it destroys only its own render objects instead of
-- rendering.clear(script.mod_name) which would also wipe the persistent network
-- overlay (see scripts/network-rendering.lua).
--
-- We track render objects by their numeric id (safe to store across save/load)
-- and resolve them with rendering.get_object_by_id.
function update_pole_rendering()
  local ids = storage.pole_info_object_ids
  if ids then
    for i = #ids, 1, -1 do
      local object = rendering.get_object_by_id(ids[i])
      if object and object.valid then
        object.destroy()
      end
      ids[i] = nil
    end
  else
    ids = {}
    storage.pole_info_object_ids = ids
  end

  for _, player in pairs(game.players) do
    if player.valid and player.connected then
      local pole = player.selected
      if pole and pole.force == player.force and pole.type == "electric-pole" then
        if storage.max_consumptions[pole.name] then
          max_consumption = storage.max_consumptions[pole.name][pole.quality.name] / 1.01  -- Divide by 1.01 because amount is originally multiplied by that for hidden leeway
          consumption = get_total_consumption(pole.electric_network_statistics)
          local ratio = consumption / max_consumption
          local color = {0, 1, 0}
          if ratio > 1 then
            color = {1, 0, 0}
          elseif ratio > 0.8 then
            color = {1, 1, 0}
          end
          ids[#ids + 1] = rendering.draw_text{
            text = shared.format_energy_number(consumption) .. " / " .. shared.format_energy_number(max_consumption),
            surface = pole.surface,
            target = {entity = pole, offset = {x = 0, y = 0.7}},
            color = color,
            scale = 1.5 * player.display_scale,
            alignment = "center",
            scale_with_zoom = true,
            players = {player},
          }.id
        end
      end
    end
  end
end
