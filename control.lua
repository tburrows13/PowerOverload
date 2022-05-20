local util = require "util"
local shared = require "__PowerOverload__/shared"
require "__PowerOverload__/scripts/create-surface"
require "__PowerOverload__/scripts/transformer"
require "__PowerOverload__/scripts/poles"


max_consumptions = {}



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
    on_transformer_destroyed(transformer)
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

script.on_event(defines.events.on_tick,
  function()
    local consumption_cache = {}
    update_poles("fuse", consumption_cache)
    update_poles("pole", consumption_cache)
    update_transformers()
  end
)

-- Surface changes handling
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

script.on_event(defines.events.on_gui_closed,
  function(event)
    if event.gui_type == defines.gui_type.entity and event.entity.type == "electric-pole" then
      if not global.notif_shown and game.tick - global.tick_installed > 432000 then  -- 2 hours: 2 * 60m * 60s * 60t = 432,000
        game.print("[Power Overload] I hope you are enjoying playing with Power Overload!\n" ..
          "Please start a discussion thread on the mod portal if you would like to help with improving the graphics " ..
          "or if you have balance suggestions.")
        global.notif_shown = true
      end
    end
  end
)

local function generate_max_consumption_table()
  local pole_names = shared.get_pole_names(script.active_mods)
  local max_consumptions = {}
  for pole_name, default_consumption in pairs(pole_names) do
    local max_consumption_string = settings.startup["power-overload-max-power-" .. pole_name].value
    max_consumptions[pole_name] = shared.validate_and_parse_energy(max_consumption_string, default_consumption)
  end
  global.max_consumptions = max_consumptions
end

local function reset_global_poles()
  local poles = {}
  for _, surface in pairs(game.surfaces) do
    for _, pole in pairs(surface.find_entities_filtered{type = "electric-pole"}) do
      if global.max_consumptions[pole.name] then
        table.insert(poles, pole)
      end
    end
  end
  global.poles = poles
end

script.on_configuration_changed(
  function(changed_data)
    generate_max_consumption_table()
    reset_global_poles()

    global.network_grace_ticks = {} -- Deliberate cleanup to stop it increasing forever :P
    create_transformer_surfaces()

    local old_version
    local mod_changes = changed_data.mod_changes
    if mod_changes and mod_changes["PowerOverload"] and mod_changes["PowerOverload"]["old_version"] then
      old_version = mod_changes["PowerOverload"]["old_version"]
    else
      return
    end
    old_version = util.split(old_version, ".")
    for i=1, #old_version do
      old_version[i] = tonumber(old_version[i])
    end
    if old_version[1] <= 1 then
      if old_version[2] < 2 then
        -- Run on 1.2.0 load
        game.forces["player"].reset_technology_effects()
        global.fuses = {}
        global.tick_installed = game.tick
      end
    end
  end
)

script.on_init(
  function()
    global.poles = {}
    global.fuses = {}
    global.transformers = {}
    global.network_grace_ticks = {}
    global.tick_installed = game.tick
    generate_max_consumption_table()
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
