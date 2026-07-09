-- shared.validate_and_parse_energy() (below) relies on the global `util`, which
-- is not set up automatically during the settings stage, so load it here.
util = require "__core__/lualib/util"
local shared = require "shared"
require "__PowerOverload__/registry"

local pole_names = shared.get_pole_names(mods, PowerOverload.get_registered_poles())

local order = 0
for pole_name, default_power in pairs(pole_names) do
  if not shared.get_pole_aliases()[pole_name] then
    if shared.validate_and_parse_energy(default_power) then
      data:extend{
        {
          type = "string-setting",
          name = "power-overload-max-power-" .. pole_name,
          localised_name = {"", {"description.max-energy-consumption"}, ": [entity=" .. pole_name .. "] ", pole_name},

          setting_type = "startup",
          default_value = default_power,
          order = string.format("%03d", order)
        }
      }
      order = order + 1
    else
      log("Skipping Power Overload setting for " .. pole_name .. " with invalid default '" .. default_power .. "'")
    end
  end
end
