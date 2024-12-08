local big_pole = data.raw["electric-pole"]["big-electric-pole"]

scale = 1.5
translate = -0.2
local pylon =  {
    type = "electric-pole",
    name = "po-huge-electric-pole",
    icon = "__PowerOverload__/graphics/icons/huge-electric-pole.png",
    icon_size = 32, icon_mipmaps = 1,
    flags = {"placeable-neutral", "player-creation", "fast-replaceable-no-build-while-moving"},
    minable = {mining_time = 0.1, result = "po-huge-electric-pole"},
    max_health = 250,
    corpse = "big-electric-pole-remnants",
    dying_explosion = "big-electric-pole-explosion",
    resistances =
    {
      {
        type = "fire",
        percent = 100
      }
    },
    collision_box = {{-scale+(1-0.6),-scale+(1-0.6)}, {scale-(1-0.6), scale-(1-0.6)}},  -- {{-0.65, -0.65}, {0.65, 0.65}},
    selection_box = {{-1*scale, -1*scale}, {1*scale, 1*scale}},  -- {{-1, -1}, {1, 1}}
    damaged_trigger_effect = big_pole.damaged_trigger_effect,
    drawing_box = {{-1*scale, -3*scale}, {1*scale, 0.5*scale}},
    maximum_wire_distance = 50,
    supply_area_distance = 0,
    vehicle_impact_sound =  big_pole.vehicle_impact_sound,
    open_sound = big_pole.open_sound,
    close_sound = big_pole.close_sound,
    pictures =
    {
      filename = "__PowerOverload__/graphics/huge-electric-pole.png",
      priority = "extra-high",
      width = 168,
      height = 165,
      direction_count = 4,
      shift = {1.6*scale, (-1.1 + translate)*scale}, -- {1.6, -1.1},
      scale = scale,
    },
    connection_points =
    {
      {
        shadow =
        {
          copper = {2.7*scale, translate},
          green = {1.8*scale, translate},
          red = {3.6*scale, translate}
        },
        wire =
        {
          copper = {0, (-3.125 + translate)*scale},
          green = {-0.59375*scale, (-3.125 + translate)*scale},
          red = {0.625*scale, (-3.125 + translate)*scale}
        }
      },
      {
        shadow =
        {
          copper = {3.1*scale, (0.2 + translate)*scale},
          green = {2.3*scale, (-0.3 + translate)*scale},
          red = {3.8*scale, (0.6 + translate)*scale}
        },
        wire =
        {
          copper = {-0.0625*scale, (-3.125 + translate)*scale},
          green = {-0.5*scale, (-3.4375 + translate)*scale},
          red = {0.34375*scale, (-2.8125 + translate)*scale}
        }
      },
      {
        shadow =
        {
          copper = {2.9*scale, (0.06 + translate)*scale},
          green = {3.0*scale, (-0.6 + translate)*scale},
          red = {3.0*scale, (0.8 + translate)*scale}
        },
        wire =
        {
          copper = {-0.09375*scale, (-3.09375 + translate)*scale},
          green = {-0.09375*scale, (-3.53125 + translate)*scale},
          red = {-0.09375*scale, (-2.65625 + translate)*scale}
        }
      },
      {
        shadow =
        {
          copper = {3.1*scale, (0.2 + translate)*scale},
          green = {3.8*scale, (-0.3 + translate)*scale},
          red = {2.35*scale, (0.6 + translate)*scale}
        },
        wire =
        {
          copper = {-0.0625*scale, (-3.1875 + translate)*scale},
          green = {0.375*scale, (-3.5 + translate)*scale},
          red = {-0.46875*scale, (-2.90625 + translate)*scale}
        }
      }
    },
    radius_visualisation_picture =
    {
      filename = "__base__/graphics/entity/small-electric-pole/electric-pole-radius-visualization.png",
      width = 12,
      height = 12,
      priority = "extra-high-no-scale",
    },
    water_reflection =
    {
      pictures =
      {
        filename = "__base__/graphics/entity/big-electric-pole/big-electric-pole-reflection.png",
        priority = "extra-high",
        width = 16,
        height = 32,
        shift = {util.by_pixel(0, 60)[1]*scale,  (util.by_pixel(0, 60)[2] + translate)*scale},
        variation_count = 1,
        scale = 5*scale
      },
      rotate = false,
      orientation_to_variation = false
    }
  }

local pylon_item = table.deepcopy(data.raw.item["big-electric-pole"])
pylon_item.name = "po-huge-electric-pole"
pylon_item.place_result = "po-huge-electric-pole"
pylon_item.icon = "__PowerOverload__/graphics/icons/huge-electric-pole.png"
pylon_item.icon_size = 32
pylon_item.icon_mipmaps = 1


pylon_recipe = {
  type = "recipe",
  name = "po-huge-electric-pole",
  ingredients =
  {
    {type="item", name="iron-stick", amount=20},
    {type="item", name="steel-plate", amount=15},
    {type="item", name="advanced-circuit", amount=10},
    {type="item", name="copper-plate", amount=15}
  },
  results = {{type="item", name="po-huge-electric-pole", amount=1}},
  energy_required = 1.5,  -- in seconds
  enabled = false
}

data:extend{pylon, pylon_item, pylon_recipe}