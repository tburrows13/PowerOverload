local shortcut = {
  type = "shortcut",
  name = "po-auto-connect-poles",
  action = "lua",
  associated_control_input = "po-auto-connect-poles",
  toggleable = true,
  order = "c[toggles]-f[auto-connect-poles]",
  icon  = "__PowerOverload__/graphics/shortcuts/wire-x32.png",
  icon_size = 32,
  small_icon = "__PowerOverload__/graphics/shortcuts/wire-x24.png",
  small_icon_size = 24,
}
local input = {
	type = "custom-input",
	name = "po-auto-connect-poles",
  localised_name = { "shortcut-name.po-auto-connect-poles" },
	key_sequence = "ALT + P",
  consuming = "none",
  order = "a"
}

local network_names_shortcut = {
  type = "shortcut",
  name = "po-toggle-network-names",
  action = "lua",
  associated_control_input = "po-toggle-network-names",
  toggleable = true,
  order = "c[toggles]-g[network-names]",
  icon  = "__PowerOverload__/graphics/shortcuts/network-names-x32.png",
  icon_size = 32,
  small_icon = "__PowerOverload__/graphics/shortcuts/network-names-x24.png",
  small_icon_size = 24,
}
local network_names_input = {
  type = "custom-input",
  name = "po-toggle-network-names",
  localised_name = { "shortcut-name.po-toggle-network-names" },
  key_sequence = "",
  consuming = "none",
  order = "b"
}

data:extend{shortcut, input, network_names_shortcut, network_names_input}