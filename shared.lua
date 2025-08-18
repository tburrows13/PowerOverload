local function combine_tables(first_table, second_table)
  for k,v in pairs(second_table) do first_table[k] = v end
  return first_table
end


local function validate_and_parse_energy(consumption)
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
    return false
  end

end

-- These values are only the default values used in settings so changing them
-- won't change the actual values: use mod settings for that
local function get_pole_names(mods)
  local mod_pole_names = {
    ["base"] = {
      ["small-electric-pole"] = "10MW",  -- (10 MW is just over 20 steam engines-worth)
      ["medium-electric-pole"] = "60MW",
      ["big-electric-pole"] = "300MW",
      ["po-huge-electric-pole"] = "3GW",
      ["po-small-electric-fuse"] = "8MW",
      ["po-medium-electric-fuse"] = "48MW",
      ["po-big-electric-fuse"] = "240MW",
      ["po-huge-electric-fuse"] = "2.4GW",
      ["substation"] = "125MW",
      ["po-substation-fuse"] = "100MW",
      ["po-interface"] = "100GW",
      ["po-interface-north"] = "100GW",  -- Hidden from settings
      ["po-interface-east"] = "100GW",  -- Hidden from settings
      ["po-interface-south"] = "100GW",  -- Hidden from settings
    },
    ["aai-industry"] = {
      ["small-iron-electric-pole"] = "10MW"
    },
    ["space-exploration"] = {
      ["se-addon-power-pole"] = "2GW",
      ["se-pylon"] = "50GW",
      ["se-pylon-substation"] = "2GW",
      ["se-pylon-construction"] = "20GW",
      ["se-pylon-construction-radar"] = "2GW",
    },
    ["bobpower"] = {
      ["medium-electric-pole-2"] = "100MW",
      ["medium-electric-pole-3"] = "140MW",
      ["medium-electric-pole-4"] = "180MW",
      ["big-electric-pole-2"] = "400MW",
      ["big-electric-pole-3"] = "500MW",
      ["big-electric-pole-4"] = "600MW",
      ["substation-2"] = "200MW",
      ["substation-3"] = "275MW",
      ["substation-4"] = "350MW"
    },
    ["cargo-ships"] = {
      ["floating-electric-pole"] = "1.5GW"
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
      ["po-small-electric-fuse"] = "16MW",
      ["po-medium-electric-fuse"] = "160MW",
      ["po-big-electric-fuse"] = "1.6GW",
      ["po-huge-electric-fuse"] = "8GW",
      ["substation"] = "400MW",
      ["po-substation-fuse"] = "320MW",
      ["kr-substation-mk2"] = "600MW"
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
      ["substation-2"] = "150MW",
      ["substation-3"] = "175MW",
      ["substation-4"] = "200MW"
    },
    ["AdvancedSubstation"] = {
      ["substation-2"] = "250MW",
      ["substation-3"] = "300MW",
    },
    ["FactorioExtended-Plus-Power"] = {
      ["medium-electric-pole-mk2"] = "120MW",
      ["medium-electric-pole-mk3"] = "140MW",
      ["big-electric-pole-mk2"] = "600MW",
      ["big-electric-pole-mk3"] = "700MW",
      ["substation-mk2"] = "175MW",
      ["substation-mk3"] = "225MW",
    },
    ["fpp"] = {
      ["long-distance-electric-pole"] = "5GW",
    },
    ["omnimatter_energy"] = {
      ["small-iron-electric-pole"] = "25MW",
      ["small-omnium-electric-pole"] = "30MW",
    },
    ["pycoalprocessing"] = {  -- Py 'base': covers all py combinations, overwrites base limits
      ["small-electric-pole"] = "30MW",
      ["medium-electric-pole"] = "200MW",
      ["big-electric-pole"] = "2GW",
      ["po-huge-electric-pole"] = "10GW",
      ["po-small-electric-fuse"] = "24MW",
      ["po-medium-electric-fuse"] = "160MW",
      ["po-big-electric-fuse"] = "1.6GW",
      ["po-huge-electric-fuse"] = "8GW",
      ["substation"] = "400MW",
      ["po-substation-fuse"] = "320MW"
    },
    ["pyalternativeenergy"] = {
      ["nexelit-power-pole"] = "800MW",
      ["po-nexelit-power-fuse"] = "640MW",
      ["nexelit-substation"] = "4GW"
    },
  }

  local loaded_pole_names = {}

  for mod, pole_names in pairs(mod_pole_names) do
    if mods[mod] then
      loaded_pole_names = combine_tables(loaded_pole_names, pole_names)
    end
  end
  if mods["LightedPolesPlus"] then
    local lighted_pole_names = {}
    for pole_name, max_consumption in pairs(loaded_pole_names) do
      lighted_pole_names["lighted-" .. pole_name] = max_consumption
    end
    combine_tables(loaded_pole_names, lighted_pole_names)
  end
  log(serpent.block(loaded_pole_names))
  return loaded_pole_names
end

local function get_pole_aliases()
  return {
    ["po-interface-north"] = "po-interface",
    ["po-interface-east"] = "po-interface",
    ["po-interface-south"] = "po-interface",
  }
end

local function get_poles_to_make_fuses(mods)
  -- Note, this assumes the naming convention always ends in '-pole'. If not, then implement a custom override
  -- in get_name_for_fuse and get_prototype_name_for_pole
  local pole_names = { "small-electric", "medium-electric", "big-electric", "huge-electric", "substation" }

  if mods["pyalternativeenergy"] then
    table.insert(pole_names, "nexelit-power")
  end

  return pole_names
end

-- Returns the name of a fuse for a given pole name, defined in 'get_poles_to_make_fuses'
local function get_name_for_fuse(pole_name)
  if pole_name == "substation" then return "po-substation-fuse" end
  local name_prefix = "po-"
  local name_suffix = "-fuse"
  local name = name_prefix .. pole_name .. name_suffix
  return name
end

-- Returns the prototype of the pole used to make a fuse from a given pole name, defined in 'get_poles_to_make_fuses'
local function get_prototype_name_for_pole(pole_name)
  if pole_name == "substation" then return "substation" end
  if pole_name == "huge-electric" then
    -- Huge electric pole is defined as 'po-huge-electric-pole', so we need a special case here.
    return "po-huge-electric-pole"
  end
  local prototype_name = pole_name .. "-pole"
  return prototype_name
end

return {
  get_pole_names = get_pole_names,
  get_pole_aliases = get_pole_aliases,
  validate_and_parse_energy = validate_and_parse_energy,
  get_poles_to_make_fuses = get_poles_to_make_fuses,
  get_name_for_fuse = get_name_for_fuse,
  get_prototype_name_for_pole = get_prototype_name_for_pole
}