local hit_effects = require ("__base__.prototypes.entity.hit-effects")
local sounds = require("__base__.prototypes.entity.sounds")


local blue_tint = {r=0.5, g=0.7, b=1}


local recipe = {
  type = "recipe",
  name = "po-interface",
  enabled = false,
  ingredients =
  {
    {"steel-plate", 100},
    {"processing-unit", 50},
    {"copper-cable", 200},
  },
  result = "po-interface"
}
if mods["bzlead"] then
  table.insert(recipe.ingredients, {"lead-plate", 25})
end

local item = {
  type = "item",
  name = "po-interface",
  icons = {{
    icon = "__base__/graphics/icons/substation.png",
    icon_size = 64, icon_mipmaps = 4,
    tint = blue_tint
  }},
  subgroup = "energy-pipe-distribution",
  order = "a[energy]-e[po-interface]",
  place_result = "po-interface",
  stack_size = 50
}

local translate = 2
local scale = 2.5
local gfx_scale = 2

local function translate_pos(pos, pos_scale)
  scale = pos_scale or gfx_scale
  return {scale*pos[1] + translate, scale*pos[2]}
end

local function translate_box(box)
  return {translate_pos(box[1], scale), translate_pos(box[2], scale)}
end

local interface = {
  type = "electric-pole",
  name = "po-interface",
  icons = {{
    icon = "__base__/graphics/icons/substation.png",
    icon_size = 64, icon_mipmaps = 4,
    tint = blue_tint
  }},
  flags = {"placeable-neutral", "player-creation"},
  minable = {mining_time = 0.1, result = "po-interface"},
  max_health = 200,
  corpse = "substation-remnants",
  dying_explosion = "substation-explosion",
  track_coverage_during_build_by_moving = true,
  resistances =
  {
    {
      type = "fire",
      percent = 90
    }
  },
  collision_box = translate_box({{-0.95, -0.95}, {0.95, 0.95}}),
  selection_box = translate_box({{-1, -1}, {1, 1}}),
  damaged_trigger_effect = hit_effects.entity(translate_box({{-0.5, -2.5}, {0.5, 0.5}})),
  drawing_box = translate_box({{-1, -3}, {1, 1}}),
  maximum_wire_distance = 8,
  supply_area_distance = 1.5,
  localised_description = {"entity-description.po-interface"},
  pictures =
  {
    layers =
    {

      {
        filename = "__base__/graphics/entity/substation/substation.png",
        priority = "high",
        width = 70,
        height = 136,
        direction_count = 4,
        shift = translate_pos(util.by_pixel(0, 1-32)),
        tint = blue_tint,
        scale = gfx_scale,
        hr_version =
        {
          filename = "__base__/graphics/entity/substation/hr-substation.png",
          priority = "high",
          width = 138,
          height = 270,
          direction_count = 4,
          shift = translate_pos(util.by_pixel(0, 1-32)),
          tint = blue_tint,
          scale = gfx_scale * 0.5
        }
      },
      {
        filename = "__base__/graphics/entity/substation/substation-shadow.png",
        priority = "high",
        width = 186,
        height = 52,
        direction_count = 4,
        shift = translate_pos(util.by_pixel(62, 42-32)),
        draw_as_shadow = true,
        scale = gfx_scale,
        hr_version =
        {
          filename = "__base__/graphics/entity/substation/hr-substation-shadow.png",
          priority = "high",
          width = 370,
          height = 104,
          direction_count = 4,
          shift = translate_pos(util.by_pixel(62, 42-32)),
          draw_as_shadow = true,
          scale = gfx_scale * 0.5
        }
      }
    }
  },

  --active_picture =
  --{
  --  filename = "__base__/graphics/entity/substation/substation-light.png",
  --  priority = "high",
  --  width = 46,
  --  height = 78,
  --  --direction_count = 4,
  --  shift = util.by_pixel(0, 16-32),
  --  blend_mode = "additive",
  --  hr_version =
  --  {
  --    filename = "__base__/graphics/entity/substation/hr-substation-light.png",
  --    priority = "high",
  --    width = 92,
  --    height = 156,
  --    --direction_count = 4,
  --    shift = util.by_pixel(0.5, 16.5-32),
  --    blend_mode = "additive",
  --    scale = 0.5
  --  }
  --},
  --light = {intensity = 0.75, size = 3, color = {r = 1.0, g = 1.0, b = 1.0}},

  vehicle_impact_sound = sounds.generic_impact,
  open_sound = sounds.electric_network_open,
  close_sound = sounds.electric_network_close,
  working_sound =
  {
    sound =
    {
      filename = "__base__/sound/substation.ogg",
      volume = 0.4
    },
    max_sounds_per_type = 3,
    audible_distance_modifier = 0.32,
    fade_in_ticks = 30,
    fade_out_ticks = 40,
    use_doppler_shift = false
  },
  connection_points =
  {
    {
      shadow =
      {
        copper = translate_pos(util.by_pixel(136, 8)),
        green = translate_pos(util.by_pixel(124, 8)),
        red = translate_pos(util.by_pixel(151, 9))
      },
      wire =
      {
        copper = translate_pos(util.by_pixel(0, -86)),
        green = translate_pos(util.by_pixel(-21, -82)),
        red = translate_pos(util.by_pixel(22, -81))
      }
    },
    {
      shadow =
      {
        copper = translate_pos(util.by_pixel(133, 9)),
        green = translate_pos(util.by_pixel(144, 21)),
        red = translate_pos(util.by_pixel(110, -3))
      },
      wire =
      {
        copper = translate_pos(util.by_pixel(0, -85)),
        green = translate_pos(util.by_pixel(15, -70)),
        red = translate_pos(util.by_pixel(-15, -92))
      }
    },
    {
      shadow =
      {
        copper = translate_pos(util.by_pixel(133, 9)),
        green = translate_pos(util.by_pixel(127, 26)),
        red = translate_pos(util.by_pixel(127, -8))
      },
      wire =
      {
        copper = translate_pos(util.by_pixel(0, -85)),
        green = translate_pos(util.by_pixel(0, -66)),
        red = translate_pos(util.by_pixel(0, -97))
      }
    },
    {
      shadow =
      {
        copper = translate_pos(util.by_pixel(133, 9)),
        green = translate_pos(util.by_pixel(111, 20)),
        red = translate_pos(util.by_pixel(144, -3))
      },
      wire =
      {
        copper = translate_pos(util.by_pixel(0, -86)),
        green = translate_pos(util.by_pixel(-15, -71)),
        red = translate_pos(util.by_pixel(15, -92))
      }
    }
  },
  radius_visualisation_picture =
  {
    filename = "__base__/graphics/entity/small-electric-pole/electric-pole-radius-visualization.png",
    width = 12,
    height = 12,
    priority = "extra-high-no-scale"
  },
  water_reflection =
  {
    pictures =
    {
      filename = "__base__/graphics/entity/substation/substation-reflection.png",
      priority = "extra-high",
      width = 20,
      height = 28,
      shift = translate_pos(util.by_pixel(0, 55)),
      variation_count = 1,
      scale = 5
    },
    rotate = false,
    orientation_to_variation = false
  }
}

data:extend{recipe, item, interface}