local function combine_tables(first_table, second_table)
  for k,v in pairs(second_table) do first_table[k] = v end
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
      ["very-big-electric-pole"] = "5GW",
      ["substation"] = "200MW"
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
  }

  local loaded_pole_names = {}

  for mod, pole_names in pairs(mod_pole_names) do
    if mods[mod] then
      combine_tables(loaded_pole_names, pole_names)
    end
  end
  return loaded_pole_names
end

return {get_pole_names = get_pole_names, validate_and_parse_energy = validate_and_parse_energy}