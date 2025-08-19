local util = require "util"
local shared = require "__PowerOverload__/shared"
require "__PowerOverload__/scripts/create-surface"
require "__PowerOverload__/scripts/transformer"
require "__PowerOverload__/scripts/poles"
require "__PowerOverload__/scripts/power-interface"

---@alias ElectricNetworkID uint
---@alias PoleType "pole"|"fuse"

---@class PoleData
---@field entity LuaEntity
---@field max_consumption double


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

local function on_built(event)
  local entity = event.entity
  if entity then
    if entity.type == "electric-pole" then
      on_pole_built(entity, event.tags, event.name == defines.events.on_built_entity and game.get_player(event.player_index))
    elseif entity.type == "entity-ghost" and game.get_player(event.player_index).is_cursor_blueprint() then
      -- Entity was (probably) built as part of blueprint, so prevent automatic disconnection of wires when it is built
      local tags = entity.tags or {}
      tags["po-skip-disconnection"] = true
      entity.tags = tags
    elseif entity.name == "po-transformer" or entity.name == "po-transformer-high" or entity.name == "po-transformer-low" then
      create_transformer(entity)
    end
  end
end
-- Needs to be 4 separate lines so that the filters work
script.on_event(defines.events.on_built_entity, on_built, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}, {filter = "name", name = "po-transformer-high"}, {filter = "name", name = "po-transformer-low"}, {filter = "ghost_type", type = "electric-pole"}})
script.on_event(defines.events.on_robot_built_entity, on_built, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}, {filter = "name", name = "po-transformer-high"}, {filter = "name", name = "po-transformer-low"}})
script.on_event(defines.events.script_raised_revive, on_built, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}, {filter = "name", name = "po-transformer-high"}, {filter = "name", name = "po-transformer-low"}})
script.on_event(defines.events.script_raised_built, on_built, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}, {filter = "name", name = "po-transformer-high"}, {filter = "name", name = "po-transformer-low"}})

local function on_destroyed(event)
  local entity = event.entity
  if entity and entity.name == "po-transformer" then
    on_transformer_destroyed(entity.unit_number)
  elseif entity and is_fuse(entity) then
    entity.get_wire_connector(copper, false).disconnect_all()
  end
end
script.on_event(defines.events.on_pre_player_mined_item, on_destroyed, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}, {filter = "name", name = "po-transformer-high"}, {filter = "name", name = "po-transformer-low"}})
script.on_event(defines.events.on_robot_pre_mined, on_destroyed, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}, {filter = "name", name = "po-transformer-high"}, {filter = "name", name = "po-transformer-low"}})
script.on_event(defines.events.on_entity_died, on_destroyed, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}, {filter = "name", name = "po-transformer-high"}, {filter = "name", name = "po-transformer-low"}})
script.on_event(defines.events.script_raised_destroy, on_destroyed, {{filter = "type", type = "electric-pole"}, {filter = "name", name = "po-transformer"}, {filter = "name", name = "po-transformer-high"}, {filter = "name", name = "po-transformer-low"}})
script.on_event(defines.events.on_object_destroyed,
  function(event)
    if event.type ~= defines.target_type.entity then return end
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
  if not transformer.name == "po-transformer" and not transformer.name == "po-transformer-high" and not transformer.name == "po-transformer-low" then return end
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
    remote.call("PickerDollies", "add_blacklist_name", "po-transformer-interface-hidden-out-high")
    remote.call("PickerDollies", "add_blacklist_name", "po-transformer-interface-hidden-out-low")
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
      local consumption_per_quality = {}
      for quality_name, quality_prototype in pairs(prototypes.quality) do
        local quality_consumption = max_consumption * quality_prototype.default_multiplier
        consumption_per_quality[quality_name] = quality_consumption
      end
      max_consumptions[pole_name] = consumption_per_quality
    end
  end
  storage.max_consumptions = max_consumptions
end

local function reset_global_poles()
  local poles = {}
  local fuses = {}
  for _, surface in pairs(game.surfaces) do
    for _, pole in pairs(surface.find_entities_filtered{type = "electric-pole"}) do
      if storage.max_consumptions[pole.name] then
        ---@type PoleData
        local pole_data = {
          entity = pole,
          max_consumption = storage.max_consumptions[pole.name][pole.quality.name]
        }
        if is_fuse(pole) then
          table.insert(fuses, pole_data)
        else
          table.insert(poles, pole_data)
        end
      end
    end
  end
  storage.poles = poles
  storage.fuses = fuses
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
    if helpers.compare_versions(old_version, "1.2.5") == -1 then
      -- Run on 1.2.5 load
      for _, transformer_parts in pairs(storage.transformers) do
        create_transformer(transformer_parts.transformer, transformer_parts)
      end
    end
    if helpers.compare_versions(old_version, "1.3.1") == -1 then
      -- Run on 1.3.1 load
      for _, transformer_parts in pairs(storage.transformers) do
        transformer_parts.bucket = transformer_parts.transformer.unit_number % 600
      end
    end
    if helpers.compare_versions(old_version, "1.4.6") == -1 then
      -- Run on 1.4.6 load
      enable_shortcut()
    end
  end
)

script.on_init(
  function()
    ---@type PoleData[]
    storage.poles = {}
    ---@type PoleData[]
    storage.fuses = {}
    ---@type table<UnitNumber, TransformerData>
    storage.transformers = {}

    update_global_settings()
    generate_max_consumption_table()
    reset_global_poles()
    create_transformer_surfaces()
    handle_picker_dollies()
    enable_shortcut()
  end
)

script.on_load(handle_picker_dollies)
script.on_event(defines.events.on_cutscene_cancelled, enable_shortcut)