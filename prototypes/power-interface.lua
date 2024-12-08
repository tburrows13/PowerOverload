local hit_effects = require ("__base__.prototypes.entity.hit-effects")
local sounds = require("__base__.prototypes.entity.sounds")


local blue_tint = {r=0.5, g=0.7, b=1}


local recipe = {
  type = "recipe",
  name = "po-interface",
  enabled = false,
  ingredients =
  {
    {type="item", name="steel-plate", amount=100},
    {type="item", name="processing-unit", amount=50},
    {type="item", name="copper-cable", amount=200},
  },
  results = {{type="item", name="po-interface", amount=1}},
}

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

local gfx_scale = 2

local interface = {
  type = "electric-pole",
  name = "po-interface",
  localised_name = {"entity-name.po-interface"},
  localised_description = {"entity-description.po-interface"},
  icons = {{
    icon = "__base__/graphics/icons/substation.png",
    icon_size = 64, icon_mipmaps = 4,
    tint = blue_tint
  }},
  flags = {"placeable-neutral", "player-creation"},
  placeable_by = {item = "po-interface", count = 1},
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
  collision_box = {{-0.85, -0.85}, {0.85, 0.85}},
  selection_box = {{-1, -1}, {1, 1}},
  damaged_trigger_effect_box = {{-0.5, -2.5}, {0.5, 0.5}},  -- Used to generate damaged_trigger_effect
  damaged_trigger_effect = hit_effects.entity({{-0.5, -2.5}, {0.5, 0.5}}),  -- Overriden in translate_interface
  drawing_box = {{-1, -3}, {1, 1}},
  maximum_wire_distance = 8,
  supply_area_distance = 1.5,
  pictures =
  {
    layers =
    {

      {
        filename = "__base__/graphics/entity/substation/hr-substation.png",
        priority = "high",
        width = 138,
        height = 270,
        direction_count = 4,
        shift = util.by_pixel(0, 1-32),
        tint = blue_tint,
        scale = gfx_scale * 0.5
      },
      {
        filename = "__base__/graphics/entity/substation/hr-substation-shadow.png",
        priority = "high",
        width = 370,
        height = 104,
        direction_count = 4,
        shift = util.by_pixel(62, 42-32),
        draw_as_shadow = true,
        scale = gfx_scale * 0.5
      }
    }
  },
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
        copper = util.by_pixel(136, 8),
        green = util.by_pixel(124, 8),
        red = util.by_pixel(151, 9)
      },
      wire =
      {
        copper = util.by_pixel(0, -86),
        green = util.by_pixel(-21, -82),
        red = util.by_pixel(22, -81)
      }
    },
    {
      shadow =
      {
        copper = util.by_pixel(133, 9),
        green = util.by_pixel(144, 21),
        red = util.by_pixel(110, -3)
      },
      wire =
      {
        copper = util.by_pixel(0, -85),
        green = util.by_pixel(15, -70),
        red = util.by_pixel(-15, -92)
      }
    },
    {
      shadow =
      {
        copper = util.by_pixel(133, 9),
        green = util.by_pixel(127, 26),
        red = util.by_pixel(127, -8)
      },
      wire =
      {
        copper = util.by_pixel(0, -85),
        green = util.by_pixel(0, -66),
        red = util.by_pixel(0, -97)
      }
    },
    {
      shadow =
      {
        copper = util.by_pixel(133, 9),
        green = util.by_pixel(111, 20),
        red = util.by_pixel(144, -3)
      },
      wire =
      {
        copper = util.by_pixel(0, -86),
        green = util.by_pixel(-15, -71),
        red = util.by_pixel(15, -92)
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
      shift = util.by_pixel(0, 55),
      variation_count = 1,
      scale = 5
    },
    rotate = false,
    orientation_to_variation = false
  }
}

local function translate_pos(pos, scale, translate)
  --scale = pos_scale or gfx_scale
  pos[1] = scale*pos[1] + translate.x
  pos[2] = scale*pos[2] + translate.y
  --return {scale*pos[1] + translate.x, scale*pos[2] + translate.y}
end

local function translate_box(box, scale, translate)
  translate_pos(box[1], scale, translate)
  translate_pos(box[2], scale, translate)
  --return {translate_pos(box[1], scale, translate), translate_pos(box[2], scale, translate)}
end


local function translate_interface(interface, scale, gfx_scale, translate)
  translate_box(interface.collision_box, scale, translate)
  translate_box(interface.selection_box, scale, translate)
  translate_box(interface.damaged_trigger_effect_box, scale, translate)
  interface.damaged_trigger_effect = hit_effects.entity(interface.damaged_trigger_effect_box)
  translate_box(interface.drawing_box, scale, translate)

  translate_pos(interface.pictures.layers[1].shift, gfx_scale, translate)
  translate_pos(interface.pictures.layers[2].shift, gfx_scale, translate)

  for _, direction in pairs(interface.connection_points) do
    for wire_type, data in pairs(direction) do
      translate_pos(data.copper, gfx_scale, translate)
      translate_pos(data.green, gfx_scale, translate)
      translate_pos(data.red, gfx_scale, translate)
    end
  end
  translate_pos(interface.water_reflection.pictures.shift, gfx_scale, translate)
end

local translate = 2
local scale = 2.5

local interface_north = table.deepcopy(interface)
interface_north.name = "po-interface-north"
translate_interface(interface_north, scale, gfx_scale, {x = 0, y = translate})

local interface_east = table.deepcopy(interface)
interface_east.name = "po-interface-east"
translate_interface(interface_east, scale, gfx_scale, {x = -translate, y = 0})

local interface_south = table.deepcopy(interface)
interface_south.name = "po-interface-south"
translate_interface(interface_south, scale, gfx_scale, {x = 0, y = -translate})

local interface_west = table.deepcopy(interface)  -- Keeps original name
translate_interface(interface_west, scale, gfx_scale, {x = translate, y = 0})

local rotate = {
  type = "custom-input",
  name = "po-rotate",
  key_sequence = "",
  linked_game_control = "rotate",
  order = "a",
}

local reverse_rotate = {
  type = "custom-input",
  name = "po-reverse-rotate",
  key_sequence = "",
  linked_game_control = "reverse-rotate",
  order = "b",
}


data:extend{recipe, item, interface_north, interface_east, interface_south, interface_west, rotate, reverse_rotate}