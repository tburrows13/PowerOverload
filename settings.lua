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
