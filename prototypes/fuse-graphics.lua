local small_fuse = data.raw["electric-pole"]["po-small-electric-fuse"]
small_fuse.pictures.layers[1] = {
  filename = "__PowerOverload__/graphics/entity/small-electric-fuse/small-fuse.png",
  priority = "extra-high",
  width = 40,
  height = 104,
  direction_count = 1,
  shift = util.by_pixel(9, -44.25),
}
small_fuse.pictures.layers[1].hr_version = {
  filename = "__PowerOverload__/graphics/entity/small-electric-fuse/hr-small-fuse.png",
  priority = "extra-high",
  width = 80,
  height = 207,
  direction_count = 1,
  shift = util.by_pixel(9, -44.25),
  scale = 0.5
}
small_fuse.pictures.layers[2] = {
  filename = "__PowerOverload__/graphics/entity/small-electric-fuse/small-fuse-shadow.png",
  priority = "extra-high",
  width = 133,
  height = 28,
  direction_count = 1,
  shift = util.by_pixel(60, -2),
  draw_as_shadow = true
}
small_fuse.pictures.layers[2].hr_version = {
  filename = "__PowerOverload__/graphics/entity/small-electric-fuse/hr-small-fuse-shadow.png",
  priority = "extra-high",
  width = 266,
  height = 56,
  direction_count = 1,
  shift = util.by_pixel(60, -2),
  draw_as_shadow = true,
  scale = 0.5
}
small_fuse.connection_points =
{
  {
    shadow =
    {
      copper = util.by_pixel_hr(230, -2),
    },
    wire =
    {
      copper = util.by_pixel_hr(19, -177.5),
    }
  },
}

local medium_fuse = data.raw["electric-pole"]["po-medium-electric-fuse"]
medium_fuse.pictures.layers[1] = {
  filename = "__PowerOverload__/graphics/entity/medium-electric-fuse/medium-fuse.png",
  priority = "extra-high",
  width = 34,
  height = 98,
  direction_count = 1,
  shift = util.by_pixel(-0.75, -30.5),
}
medium_fuse.pictures.layers[1].hr_version = {
  filename = "__PowerOverload__/graphics/entity/medium-electric-fuse/hr-medium-fuse.png",
  priority = "extra-high",
  width = 67,
  height = 194,
  direction_count = 1,
  shift = util.by_pixel(-0.75, -30.5),
  scale = 0.5
}
medium_fuse.pictures.layers[2] = {
  filename = "__PowerOverload__/graphics/entity/medium-electric-fuse/medium-fuse-shadow.png",
  priority = "extra-high",
  width = 113,
  height = 22,
  direction_count = 1,
  shift = util.by_pixel(43, 4),
  draw_as_shadow = true
}
medium_fuse.pictures.layers[2].hr_version = {
  filename = "__PowerOverload__/graphics/entity/medium-electric-fuse/hr-medium-fuse-shadow.png",
  priority = "extra-high",
  width = 225,
  height = 44,
  direction_count = 1,
  shift = util.by_pixel(43, 4),
  draw_as_shadow = true,
  scale = 0.5
}

medium_fuse.connection_points =
{
  {
    shadow =
    {
      copper = util.by_pixel_hr(193.5, -6.5),
    },
    wire =
    {
      copper = util.by_pixel(8.25, -76.5),
    }
  },
}

local big_fuse = data.raw["electric-pole"]["po-big-electric-fuse"]
big_fuse.pictures.layers[1] = {
  filename = "__PowerOverload__/graphics/entity/big-electric-fuse/big-fuse.png",
  priority = "extra-high",
  width = 56,
  height = 99,
  direction_count = 1,
  shift = util.by_pixel(0, -29),
}
big_fuse.pictures.layers[1].hr_version = {
  filename = "__PowerOverload__/graphics/entity/big-electric-fuse/hr-big-fuse.png",
  priority = "extra-high",
  width = 111,
  height = 197,
  direction_count = 1,
  shift = util.by_pixel(0, -29),
  scale = 0.5
}
big_fuse.pictures.layers[2] = {
  filename = "__PowerOverload__/graphics/entity/big-electric-fuse/big-fuse-shadow.png",
  priority = "extra-high",
  width = 105,
  height = 39,
  direction_count = 1,
  shift = util.by_pixel(30, 0),
  draw_as_shadow = true
}
big_fuse.pictures.layers[2].hr_version = {
  filename = "__PowerOverload__/graphics/entity/big-electric-fuse/hr-big-fuse-shadow.png",
  priority = "extra-high",
  width = 209,
  height = 78,
  direction_count = 1,
  shift = util.by_pixel(30, 0),
  draw_as_shadow = true,
  scale = 0.5
}

big_fuse.connection_points =
{
  {
    shadow =
    {
      copper = util.by_pixel_hr(158, -26),
    },
    wire =
    {
      copper = util.by_pixel(8.5, -74),
    }
  },
}


-- Icons

local small_fuse_icon = {{
  icon = "__PowerOverload__/graphics/icons/small-electric-fuse.png",
  icon_size = 64,
  icon_mipmaps = 4,
}}
small_fuse.icons = small_fuse_icon
data.raw.item["po-small-electric-fuse"].icons = small_fuse_icon
data.raw.corpse["po-small-electric-fuse-remnants"].icons = small_fuse_icon

local medium_fuse_icon = {{
  icon = "__PowerOverload__/graphics/icons/medium-electric-fuse.png",
  icon_size = 64,
  icon_mipmaps = 4,
}}
medium_fuse.icons = medium_fuse_icon
data.raw.item["po-medium-electric-fuse"].icons = medium_fuse_icon
data.raw.corpse["po-medium-electric-fuse-remnants"].icons = medium_fuse_icon

local big_fuse_icon = {{
  icon = "__PowerOverload__/graphics/icons/big-electric-fuse.png",
  icon_size = 64,
  icon_mipmaps = 4,
}}
big_fuse.icons = big_fuse_icon
data.raw.item["po-big-electric-fuse"].icons = big_fuse_icon
data.raw.corpse["po-big-electric-fuse-remnants"].icons = big_fuse_icon
