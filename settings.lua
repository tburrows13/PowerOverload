local shared = require "shared"

data:extend{
  {
    type = "bool-setting",
    name = "power-overload-disconnect-different-poles",
    setting_type = "runtime-global",
    default_value = true,
    order = "a"
  },
  {
    type = "string-setting",
    name = "power-overload-on-pole-overload",
    setting_type = "runtime-global",
    default_value = "destroy",
    allowed_values = {"destroy", "damage", "fire", "nothing"},
    order = "b"
  },
  {
    type = "bool-setting",
    name = "power-overload-log-to-chat",
    setting_type = "runtime-global",
    default_value = true,
    order = "c"
  },
  {
    type = "double-setting",
    name = "power-overload-transformer-efficiency",
    setting_type = "runtime-global",
    default_value = 0.98,
    minimum_value = 0,
    maximum_value = 1,
    order = "d"
  },
}

order = 0
for pole_name, default_power in pairs(shared.get_pole_names(mods)) do
  if not shared.get_pole_aliases()[pole_name] then
    data:extend{
      {
        type = "string-setting",
        name = "power-overload-max-power-" .. pole_name,
        localised_name = {"", {"description.max-energy-consumption"}, ": [entity=" .. pole_name .. "] ", pole_name},

        setting_type = "startup",
        default_value = default_power,
        order = string.format("%03d", tostring(order))
      }
    }
    order = order + 1
  end
end
