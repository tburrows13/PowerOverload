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