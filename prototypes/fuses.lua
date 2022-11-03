local shared = require "__PowerOverload__/shared"

local red_tint = {r=1, g=0.6, b=0.6}

for _, pole_name in pairs(shared.get_poles_to_make_fuses(mods)) do
  local name = shared.get_name_for_fuse(pole_name)
  local prototype_name = shared.get_prototype_name_for_pole(pole_name)

  log("Making fuse " .. name .. " from " .. prototype_name)
  local fuse = table.deepcopy(data.raw["electric-pole"][prototype_name])
  fuse.name = name
  fuse.minable.result = name
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


local small_fuse = data.raw["electric-pole"]["po-small-electric-fuse"]
small_fuse.pictures.layers[1].direction_count = 1
small_fuse.pictures.layers[2].direction_count = 1
small_fuse.pictures.layers[2].hr_version.direction_count = 1
small_fuse.pictures.layers[1].hr_version = {
  filename = "__PowerOverload__/graphics/Small_Fuse.png",
  priority = "extra-high",
  width = 80,
  height = 207,
  direction_count = 1,
  shift = util.by_pixel(0, -51),
  scale = 0.5
}
small_fuse.connection_points =
{
  {
    shadow =
    {
      copper = util.by_pixel_hr(245.0, -34.0),
    },
    wire =
    {
      copper = util.by_pixel_hr(0, -120.0),
    }
  },
}

local medium_fuse = data.raw["electric-pole"]["po-medium-electric-fuse"]
medium_fuse.pictures.layers[1].direction_count = 1
medium_fuse.pictures.layers[2].direction_count = 1
medium_fuse.pictures.layers[2].hr_version.direction_count = 1
medium_fuse.pictures.layers[1].hr_version = {
  filename = "__PowerOverload__/graphics/Medium_Fuse.png",
  priority = "extra-high",
  width = 67,
  height = 194,
  direction_count = 1,
  shift = util.by_pixel(0, -51),
  scale = 0.5
}
medium_fuse.connection_points =
{
  {
    shadow =
    {
      copper = util.by_pixel_hr(245.0, -34.0),
    },
    wire =
    {
      copper = util.by_pixel_hr(0, -120.0),
    }
  },
}

local big_fuse = data.raw["electric-pole"]["po-big-electric-fuse"]
big_fuse.pictures.layers[1].direction_count = 1
big_fuse.pictures.layers[2].direction_count = 1
big_fuse.pictures.layers[2].hr_version.direction_count = 1
big_fuse.pictures.layers[1].hr_version = {
  filename = "__PowerOverload__/graphics/Large_Fuse_2.png",
  priority = "extra-high",
  --width = 111,
  --height = 197,
  width = 110,
  height = 215,
  direction_count = 1,
  shift = util.by_pixel(0, -51),
  scale = 0.5
}
big_fuse.connection_points =
{
  {
    shadow =
    {
      copper = util.by_pixel_hr(245.0, -34.0),
    },
    wire =
    {
      copper = util.by_pixel_hr(0, -120.0),
    }
  },
}
