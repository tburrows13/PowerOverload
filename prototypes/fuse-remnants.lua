-- remnant icons set in remnant-graphics.lua

local small_fuse_remnants = table.deepcopy(data.raw.corpse["small-electric-pole-remnants"])
small_fuse_remnants.name = "po-small-electric-fuse-remnants"
small_fuse_remnants.animation_overlay = {
  filename = "__PowerOverload__/graphics/entity/small-electric-fuse/small-fuse-remnants.png",
  line_length = 1,
  width = 40,
  height = 104,
  frame_count = 1,
  direction_count = 1,
  shift = util.by_pixel(9, -44.25),
  hr_version =
  {
    filename = "__PowerOverload__/graphics/entity/small-electric-fuse/hr-small-fuse-remnants.png",
    line_length = 1,
    width = 80,
    height = 207,
    frame_count = 1,
    direction_count = 1,
    shift = util.by_pixel(9, -44.25),
    scale = 0.5
  }
}
small_fuse_remnants.animation = {
  filename = "__PowerOverload__/graphics/entity/small-electric-fuse/small-fuse-remnants-shadow.png",
  line_length = 1,
  width = 133,
  height = 28,
  frame_count = 1,
  direction_count = 1,
  shift = util.by_pixel(60, -2),
  draw_as_shadow = true,
  hr_version =
  {
    filename = "__PowerOverload__/graphics/entity/small-electric-fuse/hr-small-fuse-remnants-shadow.png",
    line_length = 1,
    width = 266,
    height = 56,
    frame_count = 1,
    direction_count = 1,
    shift = util.by_pixel(60, -2),
    draw_as_shadow = true,
    scale = 0.5
  }
}
data.raw["electric-pole"]["po-small-electric-fuse"].corpse = "po-small-electric-fuse-remnants"

local medium_fuse_remnants = table.deepcopy(data.raw.corpse["medium-electric-pole-remnants"])
medium_fuse_remnants.name = "po-medium-electric-fuse-remnants"
medium_fuse_remnants.animation_overlay = {
  filename = "__PowerOverload__/graphics/entity/medium-electric-fuse/medium-fuse-remnants.png",
  line_length = 1,
  width = 34,
  height = 82,
  frame_count = 1,
  direction_count = 1,
  shift = util.by_pixel(-0.5, -24.75),
  hr_version =
  {
    filename = "__PowerOverload__/graphics/entity/medium-electric-fuse/hr-medium-fuse-remnants.png",
    line_length = 1,
    width = 68,
    height = 163,
    frame_count = 1,
    direction_count = 1,
    shift = util.by_pixel(-0.5, -24.75),
    scale = 0.5
  }
}
medium_fuse_remnants.animation = {
  filename = "__PowerOverload__/graphics/entity/medium-electric-fuse/medium-fuse-remnants-shadow.png",
  line_length = 1,
  width = 95,
  height = 22,
  frame_count = 1,
  direction_count = 1,
  shift = util.by_pixel(34.5, 4),
  draw_as_shadow = true,
  hr_version =
  {
    filename = "__PowerOverload__/graphics/entity/medium-electric-fuse/hr-medium-fuse-remnants-shadow.png",
    line_length = 1,
    width = 190,
    height = 44,
    frame_count = 1,
    direction_count = 1,
    shift = util.by_pixel(34.5, 4),
    draw_as_shadow = true,
    scale = 0.5
  }
}
data.raw["electric-pole"]["po-medium-electric-fuse"].corpse = "po-medium-electric-fuse-remnants"

local big_fuse_remnants = table.deepcopy(data.raw.corpse["big-electric-pole-remnants"])
big_fuse_remnants.name = "po-big-electric-fuse-remnants"
big_fuse_remnants.animation_overlay = {
  filename = "__PowerOverload__/graphics/entity/big-electric-fuse/big-fuse-remnants.png",
  line_length = 1,
  width = 56,
  height = 81,
  frame_count = 1,
  direction_count = 1,
  shift = util.by_pixel(-0.5, -20),
  hr_version =
  {
    filename = "__PowerOverload__/graphics/entity/big-electric-fuse/hr-big-fuse-remnants.png",
    line_length = 1,
    width = 111,
    height = 161,
    frame_count = 1,
    direction_count = 1,
    shift = util.by_pixel(-0.5, -20),
    scale = 0.5
  }
}
big_fuse_remnants.animation = {
  filename = "__PowerOverload__/graphics/entity/big-electric-fuse/big-fuse-remnants-shadow.png",
  line_length = 1,
  width = 96,
  height = 39,
  frame_count = 1,
  direction_count = 1,
  shift = util.by_pixel(25.5, 0.5),
  draw_as_shadow = true,
  hr_version =
  {
    filename = "__PowerOverload__/graphics/entity/big-electric-fuse/hr-big-fuse-remnants-shadow.png",
    line_length = 1,
    width = 192,
    height = 78,
    frame_count = 1,
    direction_count = 1,
    shift = util.by_pixel(25.5, 0.5),
    draw_as_shadow = true,
    scale = 0.5
  }
}
data.raw["electric-pole"]["po-big-electric-fuse"].corpse = "po-big-electric-fuse-remnants"

data:extend{small_fuse_remnants, medium_fuse_remnants, big_fuse_remnants}
