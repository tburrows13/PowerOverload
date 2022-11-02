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

-- These values are only the default values used in settings so changing them won't
--change the actual values: use mod settings for that
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
    ["space-exploration"] = {
      ["se-pylon"] = "50GW",
      ["se-pylon-substation"] = "2GW",
      ["se-pylon-construction"] = "20GW",
      ["se-pylon-construction-radar"] = "2GW",
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
      ["po-small-electric-fuse"] = "15MW",
      ["po-medium-electric-fuse"] = "160MW",
      ["po-big-electric-fuse"] = "1.6GW",
      ["po-huge-electric-fuse"] = "8GW",
      ["substation"] = "400MW"
    },
    ["fixLargeElectricPole"] = {
      ["large-electric-pole"] = "16GW"
    },
    ["Advanced_Electric"] = {
      ["small-electric-pole-2"] = "24MW",
      ["medium-electric-pole-2"] = "110MW",
      ["medium-electric-pole-3"] = "120MW",
      ["medium-electric-pole-4"] = "130MW",
      ["big-electric-pole-2"] = "550MW",
      ["big-electric-pole-3"] = "600MW",
      ["big-electric-pole-4"] = "650MW",
      ["substation-2"] = "220MW",
      ["substation-3"] = "240MW",
      ["substation-4"] = "260MW"
    },
    ["IndustrialRevolution"] = {
      ["small-bronze-pole"] = "30MW",
      ["small-iron-pole"] = "30MW",
      ["big-wooden-pole"] = "200MW",
    },
    ["pyalternativeenergy"] = {
      ["small-electric-pole"] = "20MW",
      ["medium-electric-pole"] = "200MW",
      ["big-electric-pole"] = "2GW",
      ["po-huge-electric-pole"] = "10GW",
      ["po-small-electric-fuse"] = "15MW",
      ["po-medium-electric-fuse"] = "160MW",
      ["po-big-electric-fuse"] = "1.6GW",
      ["po-huge-electric-fuse"] = "8GW",
      ["substation"] = "400MW",
      ["nexelit-power-pole"] = "800MW",
      ["po-nexelit-power-fuse"] = "640MW",
      ["nexelit-substation"] = "4GW"
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

local function get_poles_to_make_fuses(mods)
  -- Note, this assumes the naming convention always ends in '-pole'.  If this is not true, this and
  -- other functions will need to be further modified.
  local pole_names = { "small-electric", "medium-electric", "big-electric", "huge-electric" }

  if mods["pyalternativeenergy"] then
    table.insert(pole_names, "nexelit-power")
  end

  return pole_names
end

-- Returns the name of a fuse for a given pole name, defined in 'get_poles_to_make_fuses'
local function get_name_for_fuse(pole_name)
  local name_prefix = "po-"
  local name_suffix = "-fuse"
  local name = name_prefix .. pole_name .. name_suffix
  return name
end

-- Returns the prototype of the pole used to make a fuse from a given pole name, defined in 'get_poles_to_make_fuses'
local function get_prototype_name_for_pole(pole_name)
  local prototype_name = pole_name .. "-pole"
  if pole_name == "huge-electric" then  -- Huge electric pole is defined as 'po-huge-electric-pole', so we need a special case here.
    prototype_name = "po-huge-electric-pole"
  end
  return prototype_name
end

return {
  get_pole_names = get_pole_names,
  validate_and_parse_energy = validate_and_parse_energy,
  get_poles_to_make_fuses = get_poles_to_make_fuses,
  get_name_for_fuse = get_name_for_fuse,
  get_prototype_name_for_pole = get_prototype_name_for_pole
}