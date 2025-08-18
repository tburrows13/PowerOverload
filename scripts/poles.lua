local always_disconnect = {
  ["po-hidden-electric-pole-in"] = true,
  ["po-hidden-electric-pole-out"] = true,
}

local never_disconnect = {
  ["factory-power-pole"] = true,
  ["factory-power-connection"] = true,
  ["factory-overflow-pole"] = true,
  ["factory-circuit-connector"] = true,
}

---@param pole LuaEntity
---@param tags Tags?
---@param player LuaPlayer?
function on_pole_built(pole, tags, player)
  local pole_name = pole.name
  local pole_connector = pole.get_wire_connector(copper, true)
  for _, connection in pairs(pole_connector.real_connections) do
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
        and not (tags and tags["po-skip-disconnection"])
        and not (never_disconnect[pole_name] or never_disconnect[neighbour_name])
        and (
          disconnect_all or always_disconnect[pole_name] or always_disconnect[neighbour_name]
          or (pole_name ~= neighbour_name and storage.global_settings["power-overload-disconnect-different-poles"])
        )
        then
          pole_connector.disconnect_from(neighbour_connector)
    end
  end
  if storage.max_consumptions[pole.name] then
    ---@type PoleData
    local pole_data = {
      entity = pole,
      max_consumption = storage.max_consumptions[pole.name][pole.quality.name]
    }
    if is_fuse(pole) then
      table.insert(storage.fuses, pole_data)
    else
      table.insert(storage.poles, pole_data)
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
    local pole_data = poles[i]
    local pole = pole_data.entity
    if pole and pole.valid then
      local electric_network_id = pole.electric_network_id  ---@cast electric_network_id -?
      local consumption = consumption_cache[electric_network_id]
      if not consumption then
        consumption = get_total_consumption(pole.electric_network_statistics)
        consumption_cache[electric_network_id] = consumption
      end
      local max_consumption = pole_data.max_consumption
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
