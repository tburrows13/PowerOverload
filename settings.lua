local shared = require "shared"

data:extend{
  {
    type = "string-setting",
    name = "power-overload-on-pole-overload",
    setting_type = "runtime-global",
    default_value = "destroy",
    allowed_values = {"destroy", "damage"},
    order = "a"
  },
  {
    type = "bool-setting",
    name = "power-overload-log-to-chat",
    setting_type = "runtime-global",
    default_value = true,
    order = "b"
  }
}

order = 0
log(serpent.dump(shared))
for pole_name, default_power in pairs(shared.get_pole_names(mods)) do
  data:extend{
    {
      type = "string-setting",
      name = "power-overload-max-power-" .. pole_name,
      localised_name = {"mod-setting-name.power-overload-max-power", pole_name},

      setting_type = "startup",
      default_value = default_power,
      order = order  -- Doesn't really work with more than 10 types of pole
    }
  }
  order = order + 1
end
  