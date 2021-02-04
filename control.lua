require "__PowerOverload__/shared"
require "__PowerOverload__/scripts/create-surface"



local function on_pole_built(pole)
  local pole_name = pole.name
  for _, neighbour in pairs(pole.neighbours.copper) do
    -- TODO allow attaching to equivalent transformer
    if neighbour.type == "electric-pole" and
        (pole_name ~= neighbour.name or pole_name == "hidden-electric-pole-in" or pole_name == "hidden-electric-pole-out") then
      pole.disconnect_neighbour(neighbour)
    end
  end
    table.insert(global.poles, pole)
end



local function create_update_transformer(transformer)
  local surface = transformer.surface
  local transformer_surface = game.get_surface(surface.name .. "-transformer")
  local transformer_parts = global.transformers[transformer.unit_number]
  if not transformer_parts or not transformer_parts.transformer then
    transformer_parts = {transformer = transformer}
  end
  transformer.power_switch_state = true

  local position = transformer.position
  local position_in = {position.x - 0.6, position.y}
  local position_out = {position.x + 0.6, position.y}
  if not (transformer_parts.pole_in and transformer_parts.pole_in.valid) then
    local pole_in = surface.create_entity{name = "hidden-electric-pole-in",
                                         position = position_in,
                                         force = transformer.force,
                                         raise_built = true}
    transformer_parts.pole_in = pole_in
  end
  if not (transformer_parts.pole_in_alt and transformer_parts.pole_in_alt.valid) then
    local pole_in_alt = transformer_surface.create_entity{name = "hidden-electric-pole-alt",
                                             position = position_in,
                                             force = transformer.force,
                                             raise_built = true}
    pole_in_alt.connect_neighbour(transformer_parts.pole_in)
    transformer_parts.pole_in_alt = pole_in_alt
  end
  if not (transformer_parts.interface_in and transformer_parts.interface_in.valid) then
    local interface_in = transformer_surface.create_entity{name = "transformer-interface-hidden-in",
                                              position = position_in,
                                              force = transformer.force}
    transformer_parts.interface_in = interface_in
  end

  if not (transformer_parts.pole_out and transformer_parts.pole_out.valid) then
    local pole_out = surface.create_entity{name = "hidden-electric-pole-out",
                                         position = position_out,
                                         force = transformer.force,
                                         raise_built = true}
    transformer_parts.pole_out = pole_out
  end
  if not (transformer_parts.pole_out_alt and transformer_parts.pole_out_alt.valid) then
    local pole_out_alt = transformer_surface.create_entity{name = "hidden-electric-pole-alt",
                                             position = position_out,
                                             force = transformer.force,
                                             raise_built = true}
    pole_out_alt.connect_neighbour(transformer_parts.pole_out)
    transformer_parts.pole_out_alt = pole_out_alt
  end
  if not (transformer_parts.interface_out and transformer_parts.interface_out.valid) then
    local interface_out = transformer_surface.create_entity{name = "transformer-interface-hidden-out",
                                              position = position_out,
                                              force = transformer.force}
    transformer_parts.interface_out = interface_out
  end

  global.transformers[transformer.unit_number] = transformer_parts

  script.register_on_entity_destroyed(transformer)
end



local function on_built(event)
  local entity = event.created_entity or event.entity
  if entity then
    if entity.type == "electric-pole" then
      on_pole_built(entity)
    elseif entity.name == "po-transformer" then
      create_update_transformer(entity)
    end
  end
end
-- Needs to be 4 separate lines so that the filters work
script.on_event(defines.events.on_built_entity, on_built, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}})
script.on_event(defines.events.on_robot_built_entity, on_built, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}})
script.on_event(defines.events.script_raised_revive, on_built, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}})
script.on_event(defines.events.script_raised_built, on_built, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}})

local function on_destroyed(event)
  local transformer = event.entity
  if transformer then
    local transformer_parts = global.transformers[transformer.unit_number]
    if transformer_parts then
      for _, entity in pairs(transformer_parts) do
        entity.destroy()
      end
    end
  end
end
script.on_event(defines.events.on_pre_player_mined_item, on_destroyed, {{filter = "name", name = "po-transformer"}})
script.on_event(defines.events.on_robot_pre_mined, on_destroyed, {{filter = "name", name = "po-transformer"}})
script.on_event(defines.events.on_entity_died, on_destroyed, {{filter = "name", name = "po-transformer"}})
script.on_event(defines.events.script_raised_destroy, on_destroyed, {{filter = "name", name = "po-transformer"}})
script.on_event(defines.events.on_entity_destroyed,
  function(event)
    local unit_number = event.unit_number
    if unit_number then
      local transformer_parts = global.transformers[unit_number]
      if transformer_parts then
        for _, entity in pairs(transformer_parts) do
          entity.destroy()
        end
      end
    end
  end
)
local function get_total_consumption(statistics)
  local total = 0
  for name, _ in pairs(statistics.input_counts) do
    total = total + 60 * statistics.get_flow_count{name = name,
                                                   input = true,
                                                   precision_index = defines.flow_precision_index.one_second,
                                                   count = false}
  end
  return total
end
local function update_poles()
  local poles = global.poles
  local table_size = #poles
  if table_size == 0 then return end
  -- Check each pole on average every 5 seconds (60 * 5 = 300)
  -- + 1 ensures that we always check at least one pole 1
  local poles_to_check = math.floor(table_size / 300) + 1
  for _ = 1, poles_to_check do
    local i = math.random(table_size)
    local pole = poles[i]
    if pole and pole.valid then
      local consumption = get_total_consumption(pole.electric_network_statistics)
      local max_consumption = max_consumptions[pole.name]
      if max_consumption and consumption > max_consumption then
        log("Pole being killed at consumption " .. consumption .. " which is above max_consumption " .. max_consumption)
        local force = pole.force
        if force then
          for _, player in pairs(force.players) do
            player.add_alert(pole, defines.alert_type.entity_destroyed)
          end
          if settings.global["power-overload-log-to-chat"].value then
            force.print({"overload-alert.alert", pole.name, math.floor(consumption)})
          end
        end
        pole.die()
        global.poles[i] = nil
      end
    else
      global.poles[i] = nil
    end
  end
end

local function update_transformers()
  for i, transformer in pairs(global.transformers) do
    local transformer_entity = transformer.transformer
    if transformer_entity and transformer_entity.valid then
      if transformer_entity.power_switch_state then
        create_update_transformer(transformer_entity)
        local interface_in = transformer.interface_in
        local interface_out = transformer.interface_out
        local buffer_size = interface_in.electric_buffer_size
        local energy_in = interface_in.energy
        local energy_out = interface_out.energy

        -- Double buffer size if necessary
        if energy_in == buffer_size and energy_out == 0 then
          buffer_size = buffer_size * 2
          log("Increasing buffer size to " .. buffer_size)
          interface_in.electric_buffer_size = buffer_size
          interface_out.electric_buffer_size = buffer_size
        end

        -- Transfer as much energy as possible
        energy_out = energy_out + energy_in
        local overflow = energy_out - buffer_size
        interface_in.energy = overflow
        interface_out.energy = energy_out
      end
    else
      global.transformers[i] = nil
    end
  end
end

script.on_event(defines.events.on_tick,
  function()
    update_poles()
    update_transformers()
  end
)

script.on_init(
  function()
    global.poles = {}
    global.transformers = {}
    local surface_names = {}
    for _, surface in pairs(game.surfaces) do
      table.insert(surface_names, surface.name)
      for _, pole in pairs(surface.find_entities_filtered{type = "electric-pole"}) do
        table.insert(global.poles, pole)
      end
    end
    -- Do loop twice to avoid infinite loop
    for _, surface_name in pairs(surface_names) do
      create_editor_surface(surface_name .. "-transformer")
    end

    -- Enable transformer recipe
    for _, force in pairs(game.forces) do
      if force.technologies["electric-energy-distribution-1"].researched then
        force.recipes["po-transformer"].enabled = true
      end
    end
  end
)

