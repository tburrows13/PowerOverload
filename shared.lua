local function combine_tables(first_table, second_table)
  for k,v in pairs(second_table) do first_table[k] = v end
  return first_table
end


local function validate_and_parse_energy(consumption, default_consumption)
  -- Sanitise user-input energy values
  local ending = consumption:sub(consumption:len())
  local status, result
  if ending == "W" then
    -- Must check for "W" because parse_energy accepts "J"
    status, result = pcall(util.parse_energy, consumption)
  else 
    status, result = false, "Does not end in W"
  end

  if status then
    -- 60 undoes parse_energy per-sec to per-tick conversion because we work in per-sec
    -- 1.01 gives a bit of leeway for the user
    return result * 60 * 1.01
  else
    log("Parsing energy setting '" .. consumption .. "' failed with error: " .. result)
    return default_consumption or false
  end

end

local function get_pole_names(mods)
  local mod_pole_names = {
    ["base"] = {
      ["small-electric-pole"] = "20MW",  -- (Just over 40 steam engines-worth)
      ["medium-electric-pole"] = "100MW",
      ["big-electric-pole"] = "500MW",
      ["po-huge-electric-pole"] = "5GW",
      ["po-small-electric-fuse"] = "15MW",
      ["po-medium-electric-fuse"] = "80MW",
      ["po-big-electric-fuse"] = "400MW",
      ["po-huge-electric-fuse"] = "4GW",
      ["substation"] = "200MW",
      ["po-interface"] = "100GW",
    },
    ["aai-industry"] = {
      ["small-iron-electric-pole"] = "20MW"
    },
    ["bobpower"] = {
      ["medium-electric-pole-2"] = "150MW",
      ["medium-electric-pole-3"] = "200MW",
      ["medium-electric-pole-4"] = "250MW",
      ["big-electric-pole-2"] = "600MW",
      ["big-electric-pole-3"] = "700MW",
      ["big-electric-pole-4"] = "800MW",
      ["substation-2"] = "300MW",
      ["substation-3"] = "400MW",
      ["substation-4"] = "500MW"
    },
    ["cargo-ships"] = {
      ["floating-electric-pole"] = "2GW"
    },
    ["Bio_Industries"] = {
      ["bi-wooden-pole-big"] = "400MW",
      ["bi-wooden-pole-huge"] = "1GW",
      ["bi-large-substation"] = "500MW",
    },
    ["Krastorio2"] = {  -- Increased limits in K2 that overwrites base limits
      ["small-electric-pole"] = "20MW",
      ["medium-electric-pole"] = "200MW",
      ["big-electric-pole"] = "2GW",
      ["po-huge-electric-pole"] = "10GW",
      ["substation"] = "400MW"
    }
  }

  local loaded_pole_names = {}

  for mod, pole_names in pairs(mod_pole_names) do
    if mods[mod] then
      loaded_pole_names = combine_tables(loaded_pole_names, pole_names)
    end
  end
  log(serpent.block(loaded_pole_names))
  return loaded_pole_names
end

return {get_pole_names = get_pole_names, validate_and_parse_energy = validate_and_parse_energy}