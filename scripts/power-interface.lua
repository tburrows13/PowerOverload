local rotate_cycle = {
  ["po-interface"] = "po-interface-north",
  ["po-interface-north"] = "po-interface-east",
  ["po-interface-east"] = "po-interface-south",
  ["po-interface-south"] = "po-interface",
}

local reverse_rotate_cycle = {}
for first, second in pairs(rotate_cycle) do
  reverse_rotate_cycle[second] = first
end

local translate = 2
local translate_from = {
  ["po-interface"] = {x = translate, y = 0},
  ["po-interface-north"] = {x = 0, y = translate},
  ["po-interface-east"] = {x = -translate, y = 0},
  ["po-interface-south"] = {x = 0, y = -translate},
}

local translate_to = {
  ["po-interface"] = {x = -translate, y = 0},
  ["po-interface-north"] = {x = 0, y = -translate},
  ["po-interface-east"] = {x = translate, y = 0},
  ["po-interface-south"] = {x = 0, y = translate},
}

local function translate_position(position, translate)
  return {x = position.x + translate.x, y = position.y + translate.y}
end

local function translate_entity_position(position, entity_from, entity_to)
  local center = translate_position(position, translate_from[entity_from])
  return translate_position(center, translate_to[entity_to])
end

script.on_event({"po-rotate", "po-reverse-rotate"},
  function(event )
    ---@cast event EventData.CustomInputEvent
    local player = game.get_player(event.player_index)  ---@cast player -?
    local selected = player.selected
    if selected and selected.force == player.force then
      local cycle = event.input_name == "po-rotate" and rotate_cycle or reverse_rotate_cycle
      local next_rotation = cycle[selected.name]
      if next_rotation then
        local entity = player.surface.create_entity{
          name = next_rotation,
          position = translate_entity_position(selected.position, selected.name, next_rotation),
          force = player.force,
          create_build_effect_smoke = false,
          raise_built = true,
        }
        if entity then
          -- Transfer connections with neighbours
          selected.destroy()
        end
      end
    end
  end
)