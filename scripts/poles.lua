local always_disconnect = {
  --["po-hidden-electric-pole-in"] = true,
  --["po-hidden-electric-pole-out"] = true,
}

local never_disconnect = {
  ["factory-power-pole"] = true,
  ["factory-power-connection"] = true,
  ["factory-overflow-pole"] = true,
  ["factory-circuit-connector"] = true,
}

local function modify_position(local_position, blueprint_data)
  local_position = {
    x = local_position.x * blueprint_data.flip_horizontal,
    y = local_position.y * blueprint_data.flip_vertical,
  }

  if blueprint_data.direction == defines.direction.east then
    local_position = {x = -local_position.y, y = local_position.x}
  elseif blueprint_data.direction == defines.direction.south then
    local_position = {x = -local_position.x, y = -local_position.y}
  elseif blueprint_data.direction == defines.direction.west then
    local_position = {x = local_position.y, y = -local_position.x}
  end

  local global_position = blueprint_data.position
  return {
    x = local_position.x + global_position.x,
    y = local_position.y + global_position.y,
  }
end

local function is_ghost_from_blueprint(entity, blueprint_data)
  if not blueprint_data then return false end
  if entity.type ~= "entity-ghost" then return false end

  local entity_name = entity.ghost_name
  local entity_position = entity.position
  for _, blueprint_entity in pairs(blueprint_data.blueprint_entities) do
    if entity_name == blueprint_entity.name and entity_position == modify_position(blueprint_entity.position, blueprint_data) then
      return true
    end
  end
end

---@param pole LuaEntity
---@param is_revive boolean?
---@param player LuaPlayer?
---@param blueprint_data table?
function on_pole_built(pole, is_revive, player, blueprint_data)
  local pole_name = pole.type == "entity-ghost" and pole.ghost_name or pole.name
  if not is_revive then
    -- If entity was built as part of a revive, don't do any processing, since processing occured when the ghost was placed
    local pole_connector = pole.get_wire_connector(copper, true)
    for _, connection in pairs(pole_connector.connections) do
      local neighbour_connector = connection.target
      local neighbour = neighbour_connector.owner
      local neighbour_type = neighbour.type
      local neighbour_name = neighbour.name
      if neighbour_type == "entity-ghost" then
        neighbour_type = neighbour.ghost_type
        neighbour_name = neighbour.ghost_name
      end
      local disconnect_all = player and not player.is_shortcut_toggled("po-auto-connect-poles")
      if neighbour_type == "electric-pole"
          and not (never_disconnect[pole_name] or never_disconnect[neighbour_name])
          and (
            disconnect_all --or always_disconnect[pole_name] or always_disconnect[neighbour_name]
            or (pole_name ~= neighbour_name and storage.global_settings["power-overload-disconnect-different-poles"])
          )
          and not is_ghost_from_blueprint(neighbour, blueprint_data)
          then
            pole_connector.disconnect_from(neighbour_connector)
      end
    end
  end
  if storage.max_consumptions[pole_name] and pole.type ~= "entity-ghost" then
    if is_fuse(pole) then
      table.insert(storage.fuses, pole)
    else
      table.insert(storage.poles, pole)
    end
  end
end

---@param statistics LuaFlowStatistics
---@return double
local function get_total_consumption(statistics)
  local total = 0
  for name, _ in pairs(statistics.input_counts) do
    for quality_name, _ in pairs(quality_names) do
      total = total + 60 * statistics.get_flow_count{
        name = {name = name, quality = quality_name},
        category = "input",
        precision_index = defines.flow_precision_index.five_seconds,
        sample_index = 1,
        count = false,
      }
    end
  end
  return total
end

---@param pole LuaEntity
---@param consumption double
---@param log_to_chat boolean
local function alert_on_destroyed(pole, consumption, log_to_chat)
  local force = pole.force
  if force then
    for _, player in pairs(force.players) do
      player.add_alert(pole, defines.alert_type.entity_destroyed)
    end
    if log_to_chat then
      force.print({"overload-alert.alert", pole.name, math.ceil(consumption / 1000000)})  -- In MW
    end
  end
end

---@param pole_type PoleType
---@param consumption_cache table<ElectricNetworkID, double>
function update_poles(pole_type, consumption_cache)
  local poles
  if pole_type == "pole" then
    poles = storage.poles
  elseif pole_type == "fuse" then
    poles = storage.fuses
  end
  local table_size = #poles
  if table_size == 0 then return end

  local max_consumptions = storage.max_consumptions
  local global_settings = storage.global_settings
  local log_to_chat = global_settings["power-overload-log-to-chat"]
  local destroy_pole_setting = global_settings["power-overload-on-pole-overload"]

  if destroy_pole_setting == "nothing" then
    return
  elseif destroy_pole_setting == "fire" then
    average_tick_delay = 600
  elseif destroy_pole_setting == "destroy" then
    -- Check each pole on average every 5 seconds (60 * 5 = 300)
    average_tick_delay = 300
  else
    -- Check each pole on average every 1 second
    average_tick_delay = 60
  end

  if pole_type == "fuse" then
    -- Check fuses 10x as often
    average_tick_delay = average_tick_delay / 10
  end

  -- + 1 ensures that we always check at least one pole 1
  local poles_to_check = math.floor(table_size / average_tick_delay) + 1
  for _ = 1, poles_to_check do
    local i = math.random(table_size)
    local pole = poles[i]
    if pole and pole.valid then
      local electric_network_id = pole.electric_network_id
      local consumption = consumption_cache[electric_network_id]
      if not consumption then
        consumption = get_total_consumption(pole.electric_network_statistics)
        consumption_cache[electric_network_id] = consumption
      end
      local max_consumption = max_consumptions[pole.name]
      if max_consumption and consumption > max_consumption then
        if destroy_pole_setting == "destroy" then
          --log("Pole being killed at consumption " .. math.ceil(consumption / 1000000) .. "MW which is above max_consumption " .. math.ceil(max_consumption / 1000000) .. "MW")
          alert_on_destroyed(pole, consumption, log_to_chat)
          pole.die()
          poles[i] = poles[table_size]
          poles[table_size] = nil
          table_size = table_size - 1
        elseif destroy_pole_setting == "fire" and pole_type ~= "fuse" then
          local consumption_ratio = consumption / max_consumption
          if consumption_ratio > 1 then
            if (consumption_ratio + 0.01) * math.random() > 1 then
              --log("Pole has caught fire")
              pole.surface.create_entity{
                name = "fire-flame",
                position = pole.position,
              }
            end
          end
        else
          local damage_amount = (consumption / max_consumption - 0.95) * 10
          --log("Pole being damaged " .. damage_amount)
          if damage_amount > pole.health then
            alert_on_destroyed(pole, consumption, log_to_chat)
          end
          pole.damage(damage_amount, 'neutral')
        end
      end
    else
      poles[i] = poles[table_size]
      poles[table_size] = nil
      table_size = table_size - 1
    end
  end
end
