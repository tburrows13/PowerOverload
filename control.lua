local util = require "util"
local shared = require "__PowerOverload__/shared"
require "__PowerOverload__/scripts/create-surface"

max_consumptions = {}

local function on_pole_built(pole)
  local pole_name = pole.name
  for _, neighbour in pairs(pole.neighbours.copper) do
    -- TODO allow attaching to equivalent transformer
    if neighbour.type == "electric-pole" and
        (pole_name ~= neighbour.name or pole_name == "po-hidden-electric-pole-in" or pole_name == "po-hidden-electric-pole-out") then
      pole.disconnect_neighbour(neighbour)

      -- Poles were momentarily connected so they shared electric network statistics.
      -- This can cause the weaker poles to explode so we initiate a grace period of 5 seconds to prevent this.
      global.network_grace_ticks[pole.electric_network_id] = game.tick
      global.network_grace_ticks[neighbour.electric_network_id] = game.tick
    end
  end
  if max_consumptions[pole.name] then
    table.insert(global.poles, pole)
  end
end



local function create_update_transformer(transformer)
  local surface = transformer.surface
  local transformer_surface = game.get_surface(surface.name .. "-transformer")
  if not transformer_surface then
    game.print("Transformer surface missing. Please report this at https://mods.factorio.com/mod/PowerOverload/discussion")
    return
  end
  local transformer_parts = global.transformers[transformer.unit_number]
  if not transformer_parts or not transformer_parts.transformer then
    transformer_parts = {transformer = transformer}
  end
  transformer.power_switch_state = true

  local position = transformer.position
  local position_in = {position.x - 0.6, position.y}
  local position_out = {position.x + 0.6, position.y}
  if not (transformer_parts.pole_in and transformer_parts.pole_in.valid) then
    local pole_in = surface.create_entity{name = "po-hidden-electric-pole-in",
                                         position = position_in,
                                         force = transformer.force,
                                         raise_built = true}
    transformer_parts.pole_in = pole_in
  end
  if not (transformer_parts.pole_in_alt and transformer_parts.pole_in_alt.valid) then
    local pole_in_alt = transformer_surface.create_entity{name = "po-hidden-electric-pole-alt",
                                             position = position_in,
                                             force = transformer.force,
                                             raise_built = true}
    pole_in_alt.connect_neighbour(transformer_parts.pole_in)
    transformer_parts.pole_in_alt = pole_in_alt
  end
  if not (transformer_parts.interface_in and transformer_parts.interface_in.valid) then
    local interface_in = transformer_surface.create_entity{name = "po-transformer-interface-hidden-in",
                                              position = position_in,
                                              force = transformer.force}
    transformer_parts.interface_in = interface_in
  end

  if not (transformer_parts.pole_out and transformer_parts.pole_out.valid) then
    local pole_out = surface.create_entity{name = "po-hidden-electric-pole-out",
                                         position = position_out,
                                         force = transformer.force,
                                         raise_built = true}
    transformer_parts.pole_out = pole_out
  end
  if not (transformer_parts.pole_out_alt and transformer_parts.pole_out_alt.valid) then
    local pole_out_alt = transformer_surface.create_entity{name = "po-hidden-electric-pole-alt",
                                             position = position_out,
                                             force = transformer.force,
                                             raise_built = true}
    pole_out_alt.connect_neighbour(transformer_parts.pole_out)
    transformer_parts.pole_out_alt = pole_out_alt
  end
  if not (transformer_parts.interface_out and transformer_parts.interface_out.valid) then
    local interface_out = transformer_surface.create_entity{name = "po-transformer-interface-hidden-out",
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
      for name, entity in pairs(transformer_parts) do
        if name ~= "transformer" then
          -- If the transformer is destryed then the player won't get the item back
          entity.destroy()
        end
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
        global.transformers[unit_number] = nil
      end
    end
  end
)
local function get_total_consumption(statistics)
  local total = 0
  for name, _ in pairs(statistics.input_counts) do
    total = total + 60 * statistics.get_flow_count{name = name,
                                                   input = true,
                                                   precision_index = defines.flow_precision_index.five_seconds   -- >= 1.1.25
                                                                     or defines.flow_precision_index.one_second, --  < 1.1.25
                                                   count = false}
  end
  return total
end

local function alert_on_destroyed(pole, consumption)
  local force = pole.force
  if force then
    for _, player in pairs(force.players) do
      player.add_alert(pole, defines.alert_type.entity_destroyed)
    end
    if settings.global["power-overload-log-to-chat"].value then
      force.print({"overload-alert.alert", pole.name, math.ceil(consumption / 1000000)})  -- In MW
    end
  end
end

local function update_poles()
  local poles = global.poles
  local table_size = #poles
  if table_size == 0 then return end
  local destroy_pole_setting = settings.global["power-overload-on-pole-overload"].value
  
  local average_tick_delay
  if destroy_pole_setting == "destroy" then
    -- Check each pole on average every 5 seconds (60 * 5 = 300)
    average_tick_delay = 300
  else
    -- Check each pole on average every 5 seconds (60 * 5 = 300)
    average_tick_delay = 60
  end

  -- + 1 ensures that we always check at least one pole 1
  local poles_to_check = math.floor(table_size / average_tick_delay) + 1
  for _ = 1, poles_to_check do
    local i = math.random(table_size)
    local pole = poles[i]
    if pole and pole.valid then
      local pole_electric_network_id = pole.electric_network_id
      local grace_period_tick = global.network_grace_ticks[pole_electric_network_id]
      if not grace_period_tick or game.tick - grace_period_tick > 301 then -- 301 = 5 seconds
        local consumption = get_total_consumption(pole.electric_network_statistics)
        local max_consumption = max_consumptions[pole.name]
        if max_consumption and consumption > max_consumption then
          if destroy_pole_setting == "destroy" then
            log("Pole being killed at consumption " .. math.ceil(consumption / 1000000) .. "MW which is above max_consumption " .. math.ceil(max_consumption / 1000000) .. "MW")
            alert_on_destroyed(pole, consumption)
            pole.die()
            global.poles[i] = global.poles[table_size]
            global.poles[table_size] = nil
            table_size = table_size - 1
          else
            local damage_amount = (consumption / max_consumption - 0.95) * 10
            if damage_amount > pole.health then
              alert_on_destroyed(pole, consumption)
            end
            log("Pole being damaged " .. damage_amount)
            pole.damage(damage_amount, 'neutral')
          end
        end
      end
    else
      global.poles[i] = global.poles[table_size]
      global.poles[table_size] = nil
      table_size = table_size - 1
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

        local efficiency = settings.global["power-overload-transformer-efficiency"].value

        -- Double buffer size if necessary
        -- Due to effiency calculations we don't always empty the buffer when we need more energy
        local effective_energy_out = (energy_out - buffer_size) / efficiency + buffer_size
        if energy_in == buffer_size and effective_energy_out <= 0 then
          buffer_size = buffer_size * 1.2
          log("Increasing buffer size to support " .. math.floor(buffer_size * 60 / 1000000) .. "MW")
          interface_in.electric_buffer_size = buffer_size
          interface_out.electric_buffer_size = buffer_size
        elseif effective_energy_out / energy_in > 0.01 and buffer_size > 1000 then
          -- Shrink the buffer size if necessary
          buffer_size = buffer_size * 0.99
          log("Decreasing buffer size to support " .. math.floor(buffer_size * 60 / 1000000) .. "MW")
          interface_in.electric_buffer_size = buffer_size
          interface_out.electric_buffer_size = buffer_size
        end

        -- Transfer as much energy as possible
        local output_space = buffer_size - energy_out
        local ideal_input_used = output_space / efficiency
        local actual_input_used = math.min(ideal_input_used, energy_in)
        local actual_output_gained = actual_input_used * efficiency

        interface_in.energy = energy_in - actual_input_used
        interface_out.energy = energy_out + actual_output_gained
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

-- Surface changes handling

local function create_transformer_surface(surface_name)
  local new_surface_name = surface_name .. "-transformer"
  if not game.get_surface(new_surface_name) and string.sub(surface_name, -12) ~= "-transformer" then
    create_editor_surface(new_surface_name)
    log("Creating transformer surface " .. new_surface_name)
  end

end

script.on_event(defines.events.on_surface_created,
  function(event)
    local surface = game.get_surface(event.surface_index)
    create_transformer_surface(surface.name)
  end
)

script.on_event(defines.events.on_pre_surface_deleted,
  function(event)
    local surface = game.get_surface(event.surface_index)
    local transformer_surface_name = surface.name .. "-transformer"
    if game.get_surface(transformer_surface_name) then
      game.delete_surface(transformer_surface_name)
    end
  end
)

script.on_event(defines.events.on_surface_cleared,
  function(event)
    local surface = game.get_surface(event.surface_index)
    local transformer_surface_name = surface.name .. "-transformer"
    local transformer_surface = game.get_surface(transformer_surface_name)
    if transformer_surface then
      transformer_surface.clear()
      log("Clearing transformer surface " .. transformer_surface_name)
    end
  end
)

script.on_event(defines.events.on_surface_renamed,
  function(event)
    local old_transformer_surface_name = event.old_name .. "-transformer"
    local old_transformer_surface = game.get_surface(old_transformer_surface_name)
    local new_transformer_surface_name = event.new_name .. "-transformer"
    if old_transformer_surface and not game.get_surface(new_transformer_surface_name) then
      old_transformer_surface.name = 
      log("Renaming transformer surface " .. old_transformer_surface_name .. " to " .. new_transformer_surface_name)
    end
  end
)


local function reset_global_poles()
  local poles = {}
  for _, surface in pairs(game.surfaces) do
    for _, pole in pairs(surface.find_entities_filtered{type = "electric-pole"}) do
      if max_consumptions[pole.name] then
        table.insert(poles, pole)
      end
    end
  end
  global.poles = poles
end

local function create_transformer_surfaces()
  for _, surface in pairs(game.surfaces) do
    create_transformer_surface(surface.name)
  end
end

script.on_configuration_changed(
  function()
    -- Mainly needed for 1.1.3 migration
    reset_global_poles()

    global.network_grace_ticks = {} -- Deliberate cleanup to stop it increasing forever :P
    create_transformer_surfaces()
  end
)

script.on_init(
  function()
    global.poles = {}
    global.transformers = {}
    global.network_grace_ticks = {}
    reset_global_poles()
    create_transformer_surfaces()

    -- Enable transformer recipe
    for _, force in pairs(game.forces) do
      if force.technologies["electric-energy-distribution-1"].researched then
        force.recipes["po-transformer"].enabled = true
      end
    end
  end
)

script.on_load(
  function()
    -- Hopefully doesn't cause desyncs...
    local pole_names = shared.get_pole_names(script.active_mods)
    for pole_name, default_consumption in pairs(pole_names) do
      local max_consumption_string = settings.startup["power-overload-max-power-" .. pole_name].value
      max_consumptions[pole_name] = shared.validate_and_parse_energy(max_consumption_string, default_consumption)
    end
  end
)
