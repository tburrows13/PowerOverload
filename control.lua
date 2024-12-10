local util = require "util"
local shared = require "__PowerOverload__/shared"
require "__PowerOverload__/scripts/create-surface"
require "__PowerOverload__/scripts/transformer"
require "__PowerOverload__/scripts/poles"
require "__PowerOverload__/scripts/power-interface"

---@alias ElectricNetworkID uint
---@alias PoleType "pole"|"fuse"

copper = defines.wire_connector_id.pole_copper
local quality_prototypes = prototypes.quality
quality_names = {}
for name, _ in pairs(quality_prototypes) do
  quality_names[name] = true
end
quality_names["quality-unknown"] = nil

max_consumptions = {}

function is_fuse(pole)
  return string.sub(pole.name, -5) == "-fuse"
end

---@param player LuaPlayer?
---@return BlueprintEntity[]?
local function get_blueprint_entities(player)
  if not player or not player.is_cursor_blueprint() then return end

  local blueprint = player.cursor_record
  if blueprint then
    if blueprint.type == "blueprint-book" then
      -- TODO check active_index once added to API
      return
    elseif blueprint.type == "blueprint" and not blueprint.is_blueprint_preview then
      return blueprint.get_blueprint_entities()
    else
      return
    end
  else
    -- No library book or blueprint, so check cursor item
    blueprint = player.cursor_stack
    if not (blueprint and blueprint.valid_for_read) then
      return
    end
    -- Check item blueprint book recursively
    while blueprint.is_blueprint_book do
      -- Get active blueprint from this book item
      blueprint = blueprint.get_inventory(defines.inventory.item_main)[blueprint.active_index]
    end
    if blueprint.is_blueprint then
      -- Check the blueprint for pumps
      return blueprint.get_blueprint_entities()
    end
    -- Cursor is not a blueprint, or entry from book was not a blueprint
    return
  end
end

local function on_pre_build(event)
  -- If a blueprint is placed, ensure that we aren't changing connections within the blueprint
  local player = game.get_player(event.player_index)
  local blueprint_entities = get_blueprint_entities(player)
  if not blueprint_entities then return end

  storage.blueprints_this_tick[event.player_index] = {
    blueprint_entities = blueprint_entities,
    position = event.position,
    direction = event.direction,
    flip_horizontal = event.flip_horizontal and -1 or 1,
    flip_vertical = event.flip_vertical and -1 or 1,
  }
end
script.on_event(defines.events.on_pre_build, on_pre_build)

local function on_built(event)
  local entity = event.entity
  if entity then
    local player
    if event.name == defines.events.on_built_entity then
      player = game.get_player(event.player_index)
    end
    if entity.type == "electric-pole" then
      on_pole_built(entity, event.tags and event.tags["po-pole-ghost"] == true, player)
    elseif entity.type == "entity-ghost" then
      local tags = entity.tags or {}
      tags["po-pole-ghost"] = true
      entity.tags = tags
      local blueprint_data = player and storage.blueprints_this_tick[event.player_index]
      on_pole_built(entity, false, player, blueprint_data)

    elseif entity.name == "po-transformer" then
      create_transformer(entity)
    end
  end
end
-- Needs to be 4 separate lines so that the filters work
script.on_event(defines.events.on_built_entity, on_built, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}, {filter = "ghost_type", type = "electric-pole"}})
script.on_event(defines.events.on_robot_built_entity, on_built, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}})
script.on_event(defines.events.script_raised_revive, on_built, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}})
script.on_event(defines.events.script_raised_built, on_built, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}})

local function on_destroyed(event)
  local entity = event.entity
  if entity and entity.name == "po-transformer" then
    on_transformer_destroyed(entity.unit_number)
  elseif entity and is_fuse(entity) then
    entity.get_wire_connector(copper, false).disconnect_all()
  end
end
script.on_event(defines.events.on_pre_player_mined_item, on_destroyed, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}})
script.on_event(defines.events.on_robot_pre_mined, on_destroyed, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}})
script.on_event(defines.events.on_entity_died, on_destroyed, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}})
script.on_event(defines.events.script_raised_destroy, on_destroyed, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}})
script.on_event(defines.events.on_object_destroyed,
  function(event)
    local unit_number = event.useful_id
    if unit_number then
      on_transformer_destroyed(unit_number)
    end
  end
)

script.on_event(defines.events.on_tick,
  function(event)
    ---@type table<ElectricNetworkID, double>
    local consumption_cache = {}
    update_poles("fuse", consumption_cache)
    update_poles("pole", consumption_cache)
    update_transformers(event.tick)

    storage.blueprints_this_tick = {}
  end
)

-- Surface changes handling
script.on_event(defines.events.on_surface_created,
  function(event)
    local surface = game.get_surface(event.surface_index)  ---@cast surface -?
    create_transformer_surface(surface.name)
  end
)

script.on_event(defines.events.on_pre_surface_deleted,
  function(event)
    local surface = game.get_surface(event.surface_index)  ---@cast surface -?
    local transformer_surface_name = surface.name .. "-transformer"
    if game.get_surface(transformer_surface_name) then
      game.delete_surface(transformer_surface_name)
    end
  end
)

script.on_event(defines.events.on_surface_cleared,
  function(event)
    local surface = game.get_surface(event.surface_index)  ---@cast surface -?
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
      old_transformer_surface.name = new_transformer_surface_name
      log("Renaming transformer surface " .. old_transformer_surface_name .. " to " .. new_transformer_surface_name)
    end
  end
)

local toggle_auto_connect_poles = function(event)
  local player = game.get_player(event.player_index)  ---@cast player -?
  local toggle_on = not player.is_shortcut_toggled("po-auto-connect-poles")
  player.set_shortcut_toggled("po-auto-connect-poles", toggle_on)
end
script.on_event("po-auto-connect-poles", toggle_auto_connect_poles)
script.on_event(defines.events.on_lua_shortcut,
  function(event)
    if event.prototype_name and event.prototype_name ~= "po-auto-connect-poles" then return end
    toggle_auto_connect_poles(event)
  end
)

local function on_dolly_moved_entity(event)
  local transformer = event.moved_entity
  if not transformer.name == "po-transformer" then return end
  local transformer_parts = storage.transformers[transformer.unit_number]
  if not transformer_parts then return end

  check_transformer_interfaces(transformer_parts)
  check_transformer_poles(transformer_parts)

  local position = transformer.position
  local position_in = {position.x - 0.6, position.y}
  local position_out = {position.x + 0.6, position.y}

  transformer_parts.position_in = position_in
  transformer_parts.position_out = position_out

  transformer_parts.pole_in.teleport(position_in)
  transformer_parts.pole_in_alt.teleport(position_in)
  transformer_parts.interface_in.teleport(position_in)
  transformer_parts.pole_out.teleport(position_out)
  transformer_parts.pole_out_alt.teleport(position_out)
  transformer_parts.interface_out.teleport(position_out)
end

local function handle_picker_dollies()
  if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
    script.on_event(remote.call("PickerDollies", "dolly_moved_entity_id"), on_dolly_moved_entity)
    remote.call("PickerDollies", "add_blacklist_name", "po-hidden-electric-pole-in")
    remote.call("PickerDollies", "add_blacklist_name", "po-hidden-electric-pole-out")
    -- The next 3 entities are only ever on transformer surfaces so don't actually need to be blacklisted
    remote.call("PickerDollies", "add_blacklist_name", "po-hidden-electric-pole-alt")
    remote.call("PickerDollies", "add_blacklist_name", "po-transformer-interface-hidden-in")
    remote.call("PickerDollies", "add_blacklist_name", "po-transformer-interface-hidden-out")

  end

end

local function update_global_settings()
  local global_settings = {}
  for _, setting in pairs({
    "power-overload-disconnect-different-poles",
    "power-overload-on-pole-overload",
    "power-overload-log-to-chat",
    "power-overload-transformer-efficiency",
  }) do
    global_settings[setting] = settings.global[setting].value
  end
  storage.global_settings = global_settings
end
script.on_event(defines.events.on_runtime_mod_setting_changed, update_global_settings)


local function generate_max_consumption_table()
  local pole_names = shared.get_pole_names(script.active_mods)
  local max_consumptions = {}
  for pole_name, default_consumption in pairs(pole_names) do
    local setting_pole_name = shared.get_pole_aliases()[pole_name] or pole_name
    local max_consumption_string = settings.startup["power-overload-max-power-" .. setting_pole_name].value
    local max_consumption = shared.validate_and_parse_energy(max_consumption_string)
    if not max_consumption then
      game.print("Consumption setting '" .. max_consumption_string .. "' is not valid")
      max_consumption = shared.validate_and_parse_energy(default_consumption)
    end
    if max_consumption then
      max_consumptions[pole_name] = max_consumption
    end
  end
  storage.max_consumptions = max_consumptions
end

local function reset_global_poles()
  local poles = {}
  for _, surface in pairs(game.surfaces) do
    for _, pole in pairs(surface.find_entities_filtered{type = "electric-pole"}) do
      if storage.max_consumptions[pole.name] then
        table.insert(poles, pole)
      end
    end
  end
  storage.poles = poles
end

script.on_event(defines.events.on_player_created,
  function(event)
    local player = game.get_player(event.player_index)  ---@cast player -?
    player.set_shortcut_toggled("po-auto-connect-poles", true)
  end
)
local function enable_shortcut()
  for _, player in pairs(game.players) do
    player.set_shortcut_toggled("po-auto-connect-poles", true)
  end
end

script.on_configuration_changed(
  function(changed_data)
    storage.blueprints_this_tick = storage.blueprints_this_tick or {}
    update_global_settings()

    generate_max_consumption_table()
    reset_global_poles()

    storage.network_grace_ticks = nil
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
        storage.fuses = {}
        storage.tick_installed = game.tick
      end
      if old_version[2] < 2 or (old_version[2] == 2 and old_version[3] < 5) then
        -- Run on 1.2.5 load
        for _, transformer_parts in pairs(storage.transformers) do
          create_transformer(transformer_parts.transformer, transformer_parts)
        end
      end
      if old_version[2] < 3 or (old_version[2] == 3 and old_version[3] < 1) then
        -- Run on 1.3.1 load
        for _, transformer_parts in pairs(storage.transformers) do
          transformer_parts.bucket = transformer_parts.transformer.unit_number % 600
        end
      end
      if old_version[2] < 4 or (old_version[2] == 4 and old_version[3] < 6) then
        -- Run on 1.4.6 load
        enable_shortcut()
      end
    end
  end
)

script.on_init(
  function()
    storage.poles = {}
    storage.fuses = {}
    ---@type table<UnitNumber, TransformerData>
    storage.transformers = {}
    storage.tick_installed = game.tick
    ---@type <PlayerIndex, table>
    storage.blueprints_this_tick = {}

    update_global_settings()
    generate_max_consumption_table()
    reset_global_poles()
    create_transformer_surfaces()
    handle_picker_dollies()
    enable_shortcut()

    -- Enable transformer recipe
    for _, force in pairs(game.forces) do
      force.reset_technology_effects()
    end
  end
)

script.on_load(handle_picker_dollies)
script.on_event(defines.events.on_cutscene_cancelled, enable_shortcut)