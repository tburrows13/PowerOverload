local pole_names = shared.get_pole_names(mods)
for pole_name, prototype in pairs(data.raw["electric-pole"]) do
  pole_name = shared.get_pole_aliases()[pole_name] or pole_name
  local default_consumption = pole_names[pole_name]
  if default_consumption then
    local max_consumption_string = settings.startup["power-overload-max-power-" .. pole_name].value
    if not shared.validate_and_parse_energy(max_consumption_string) then
      max_consumption_string = default_consumption
    end
    prototype.custom_tooltip_fields = prototype.custom_tooltip_fields or {}
    local tooltip_field = {
      name = {"description.max-energy-consumption"},
      value = max_consumption_string,
      quality_values = {},
    }
    for quality_name, quality_prototype in pairs(data.raw.quality) do
      local default_multiplier = quality_prototype.default_multiplier
      if not default_multiplier then
        default_multiplier = 1 + (0.3 * quality_prototype.level)
      end
      local quality_consumption = shared.validate_and_parse_energy(max_consumption_string, true) * default_multiplier
      local quality_consumption_formatted = util.format_number(quality_consumption, true) .. "W"
      quality_consumption_formatted = quality_consumption_formatted:gsub("B", "G")
      tooltip_field.quality_values[quality_name] = quality_consumption_formatted
    end
    table.insert(prototype.custom_tooltip_fields, tooltip_field)
  end
end
