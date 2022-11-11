local shared = require "__PowerOverload__/shared"

-- Fuse custom graphics are specified in fuse-graphics.lua

local red_tint = {r=1, g=0.6, b=0.6}

for _, pole_name in pairs(shared.get_poles_to_make_fuses(mods)) do
  local name = shared.get_name_for_fuse(pole_name)
  local prototype_name = shared.get_prototype_name_for_pole(pole_name)

  log("Making fuse " .. name .. " from " .. prototype_name)
  local fuse = table.deepcopy(data.raw["electric-pole"][prototype_name])
  fuse.name = name
  fuse.minable.result = name

  fuse.supply_area_distance = 0

  fuse.icons = {{
    icon = fuse.icon,
    icon_size = fuse.icon_size,
    icon_mipmaps = fuse.icon_mipmaps,
    tint = red_tint,
  }}
  if fuse.pictures.layers then
    fuse.pictures.layers[1].tint = red_tint
    if fuse.pictures.layers[1].hr_version then
      fuse.pictures.layers[1].hr_version.tint = red_tint
    end
  else
    fuse.pictures.tint = red_tint
    if fuse.pictures.hr_version then
      fuse.pictures.hr_version.tint = red_tint
    end
  end
  fuse.localised_description = {"entity-description.po-electric-fuse"}

  local item = table.deepcopy(data.raw.item[prototype_name])
  item.name = name
  item.place_result = name
  item.order = "a[energy]-f[fuse]-" .. item.order
  item.icons = {{
    icon = item.icon,
    icon_size = item.icon_size,
    icon_mipmaps = item.icon_mipmaps,
    tint = red_tint,
  }}

  -- Recipe is created in data-updates, as ingredients are dynamically set from the power pole ingredients

  data:extend({fuse, item})
end
