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
      name = "description.max-energy-consumption",
      value = max_consumption_string,
    }
    table.insert(prototype.custom_tooltip_fields, tooltip_field)
  end
end
