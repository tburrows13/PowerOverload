local pole_names = shared.get_pole_names(mods)
for pole_name, prototype in pairs(data.raw["electric-pole"]) do
  pole_name = shared.get_pole_aliases()[pole_name] or pole_name
  local default_consumption = pole_names[pole_name]
  if default_consumption then
    local max_consumption_string = settings.startup["power-overload-max-power-" .. pole_name].value
    if not shared.validate_and_parse_energy(max_consumption_string) then
      max_consumption_string = default_consumption
    end
    local localised_string = {"", "[font=default-semibold][color=255, 230, 192]", {"description.max-energy-consumption"}, ":[/color][/font] ", max_consumption_string}
    local description = prototype.localised_description
    if description then
      prototype.localised_description = {"", description, "\n", localised_string}
    else
      prototype.localised_description = localised_string
    end
  end
end
