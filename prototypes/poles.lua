local pole_names = shared.get_pole_names(mods)
pole_names = shared.get_pole_names_from_settings(pole_names, data.raw["electric-pole"], settings.startup)
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
      order = 150,
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

-- Line resistance row (used by line losses): r = sqrt(P_big / P_pole) per tile of
-- wire, from the same max consumption settings as above. Fuses are the same line
-- as their pole, so they show their pole's value. Normal quality.
local ratings = {}
for pole_name, default_consumption in pairs(pole_names) do
  local setting = settings.startup["power-overload-max-power-" .. pole_name]
  local consumption_string = setting and setting.value
  if not (consumption_string and shared.validate_and_parse_energy(consumption_string)) then
    consumption_string = default_consumption
  end
  ratings[pole_name] = shared.validate_and_parse_energy(consumption_string, true)
end
local fuse_to_pole = {}
for _, pole_name in pairs(shared.get_poles_to_make_fuses(mods)) do
  fuse_to_pole[shared.get_name_for_fuse(pole_name)] = shared.get_prototype_name_for_pole(pole_name)
end
local reference = ratings["big-electric-pole"]
if reference then
  for prototype_name, prototype in pairs(data.raw["electric-pole"]) do
    local pole_name = shared.get_pole_aliases()[prototype_name] or prototype_name
    local rating = ratings[fuse_to_pole[pole_name] or pole_name]
    if rating and rating > 0 and pole_name ~= "po-interface" then
      prototype.custom_tooltip_fields = prototype.custom_tooltip_fields or {}
      table.insert(prototype.custom_tooltip_fields, {
        name = {"description.po-line-resistance"},
        value = string.format("%.2g", math.sqrt(reference / rating)) .. "×",
        order = 151,
      })
    end
  end
end
