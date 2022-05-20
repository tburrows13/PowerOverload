local function is_fuse(pole)
  return string.sub(pole.name, -5) == "-fuse"
end

function on_pole_built(pole)
  local pole_name = pole.name
  for _, neighbour in pairs(pole.neighbours.copper) do
    if neighbour.type == "electric-pole" and
        (pole_name == "po-hidden-electric-pole-in" or pole_name == "po-hidden-electric-pole-out" or
         neighbour.name == "po-hidden-electric-pole-in" or neighbour.name == "po-hidden-electric-pole-out" or
        (pole_name ~= neighbour.name and global.global_settings["power-overload-disconnect-different-poles"])) then
      pole.disconnect_neighbour(neighbour)

      -- Poles were momentarily connected so they shared electric network statistics.
      -- This can cause the weaker poles to explode so we initiate a grace period of 5 seconds to prevent this.
      global.network_grace_ticks[pole.electric_network_id] = game.tick
      global.network_grace_ticks[neighbour.electric_network_id] = game.tick
    end
  end
  if global.max_consumptions[pole.name] then
    if is_fuse(pole) then
      table.insert(global.fuses, pole)
    else
      table.insert(global.poles, pole)
    end
  end
end

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

function update_poles(pole_type, consumption_cache)
  local poles
  if pole_type == "pole" then
    poles = global.poles
  elseif pole_type == "fuse" then
    poles = global.fuses
  end
  local table_size = #poles
  if table_size == 0 then return end

  local max_consumptions = global.max_consumptions
  local global_settings = global.global_settings
  local log_to_chat = global_settings["power-overload-log-to-chat"]
  local destroy_pole_setting = global_settings["power-overload-on-pole-overload"]

  if destroy_pole_setting == "destroy" then
    -- Check each pole on average every 5 seconds (60 * 5 = 300)
    average_tick_delay = 300
  else
    -- Check each pole on average every 1 seconds (60 * 5 = 300)
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
      local pole_electric_network_id = pole.electric_network_id
      local grace_period_tick = global.network_grace_ticks[pole_electric_network_id]
      if not grace_period_tick or game.tick - grace_period_tick > 301 then -- 301 = 5 seconds
        local electric_network_id = pole.electric_network_id
        local consumption = consumption_cache[electric_network_id]
        if not consumption then
          consumption = get_total_consumption(pole.electric_network_statistics)
          consumption_cache[electric_network_id] = consumption
        end
        local max_consumption = max_consumptions[pole.name]
        if max_consumption and consumption > max_consumption then
          if destroy_pole_setting == "destroy" then
            log("Pole being killed at consumption " .. math.ceil(consumption / 1000000) .. "MW which is above max_consumption " .. math.ceil(max_consumption / 1000000) .. "MW")
            alert_on_destroyed(pole, consumption, log_to_chat)
            pole.die()
            poles[i] = poles[table_size]
            poles[table_size] = nil
            table_size = table_size - 1
          else
            local damage_amount = (consumption / max_consumption - 0.95) * 10
            log("Pole being damaged " .. damage_amount)
            if damage_amount > pole.health then
              alert_on_destroyed(pole, consumption, log_to_chat)
            end
            pole.damage(damage_amount, 'neutral')
          end
        end
      end
    else
      poles[i] = poles[table_size]
      poles[table_size] = nil
      table_size = table_size - 1
    end
  end
end
