local recall_shortcut = {
  type = "shortcut",
  name = "po-auto-connect-poles",
  action = "lua",
  associated_control_input = "po-auto-connect-poles",
  toggleable = true,
  order = "a",
  icon =
  {
    filename = "__PowerOverload__/graphics/shortcuts/wire-x32.png",
    size = 32,
    flags = {"gui-icon"}
  },
  small_icon = {
    filename = "__PowerOverload__/graphics/shortcuts/wire-x24.png",
    size = 24,
    flags = {"gui-icon"}
  },
  disabled_icon = {
    filename = "__PowerOverload__/graphics/shortcuts/wire-x32-white.png",
    size = 32,
    flags = {"gui-icon"}
  },
  disabled_small_icon =
  {
    filename = "__PowerOverload__/graphics/shortcuts/wire-x24-white.png",
    size = 24,
    flags = {"gui-icon"}
  }
}
local recall_input = {
	type = "custom-input",
	name = "po-auto-connect-poles",
  localised_name = { "shortcut-name.po-auto-connect-poles" },
	key_sequence = "ALT + P",
  consuming = "none",
  order = "a"
}

data:extend{recall_shortcut, recall_input}