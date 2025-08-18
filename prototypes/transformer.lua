-- Each transformer is comprised of a 'power switch', an input pole, and an output pole on the main surface
-- and 2 alt poles and 2 EEIs on an alt surface

local big_pole = data.raw["electric-pole"]["big-electric-pole"]

local transformer = table.deepcopy(data.raw["power-switch"]["power-switch"])
transformer.name = "po-transformer"
transformer.wire_max_distance = 0
transformer.minable.result = "po-transformer"
transformer.placeable_by = {item = "po-transformer", count = 1}
transformer.power_on_animation.layers[1].filename = "__PowerOverload__/graphics/transformer.png"
transformer.icons = {{
  icon = "__PowerOverload__/graphics/icons/transformer.png",
  icon_size = 64,
}}
local transformer_high = table.deepcopy(transformer)
transformer_high.name = "po-transformer-high"
transformer_high.minable.result = "po-transformer-high"
transformer_high.placeable_by = {item = "po-transformer-high", count = 1}
local transformer_low = table.deepcopy(transformer)
transformer_low.name = "po-transformer-low"
transformer_low.minable.result = "po-transformer-low"
transformer_low.placeable_by = {item = "po-transformer-low", count = 1}


local transformer_item = table.deepcopy(data.raw.item["power-switch"])
transformer_item.name = "po-transformer"
transformer_item.place_result = "po-transformer"
transformer_item.subgroup = "energy-pipe-distribution"
transformer_item.order = "a[energy]-f[transformer]-1"
transformer_item.icons = table.deepcopy(transformer.icons)
local transformer_item_high = table.deepcopy(transformer_item)
transformer_item_high.name = "po-transformer-high"
transformer_item_high.place_result = "po-transformer-high"
transformer_item_high.order = "a[energy]-f[transformer]-2"
local transformer_item_low = table.deepcopy(transformer_item)
transformer_item_low.name = "po-transformer-low"
transformer_item_low.place_result = "po-transformer-low"
transformer_item_low.order = "a[energy]-f[transformer]-3"

local transformer_recipe = table.deepcopy(data.raw.recipe["power-switch"])
transformer_recipe.name = "po-transformer"
transformer_recipe.results[1].name = "po-transformer"
local transformer_high_recipe = table.deepcopy(data.raw.recipe["power-switch"])
transformer_high_recipe.name = "po-transformer-high"
transformer_high_recipe.results[1].name = "po-transformer-high"
local transformer_low_recipe = table.deepcopy(data.raw.recipe["power-switch"])
transformer_low_recipe.name = "po-transformer-low"
transformer_low_recipe.results[1].name = "po-transformer-low"

local hidden_pole_item = table.deepcopy(data.raw.item["small-electric-pole"])
hidden_pole_item.name = "po-hidden-electric-pole"
hidden_pole_item.hidden = true
hidden_pole_item.place_result = nil
hidden_pole_item.icons = {
  transformer_item.icons[1],
  {
    icon = "__base__/graphics/icons/copper-cable.png",
    icon_size = 64,
    scale = 0.35,
    --tint = transformer_tint
  }
}

local hidden_pole_in = {
  type = "electric-pole",
  name = "po-hidden-electric-pole-in",
  icons = transformer.icons,
  hidden = true,
  flags = {"player-creation",
           "not-on-map",
           "not-deconstructable",
           "hide-alt-info",
           "not-flammable",
           "not-repairable",
           "not-upgradable",
           "no-copy-paste",
           "placeable-off-grid"},
  minable = nil,
  max_health = 50,
  --corpse = "small-electric-pole-remnants",
  collision_box = {{-0.15, -0.15}, {0.15, 0.15}},
  selection_box = {{-0.4, -1}, {0.4, 1}},
  selection_priority = 255,  -- Default 50
  maximum_wire_distance = 5,
  supply_area_distance = 0.2,
  placeable_by = {item = "po-hidden-electric-pole", count = 1},
  collision_mask = {layers={}},
  open_sound = big_pole.open_sound,
  close_sound = big_pole.close_sound,
  connection_points =
  {
    {
      shadow =
      {
        copper = util.by_pixel(6, -5+3), --(-8, -5+3),
      },
      wire =
      {
        copper = util.by_pixel(-7, -33+3), --(-26, -33+3),
      }
    },
  }
}

local hidden_pole_out = table.deepcopy(hidden_pole_in)
hidden_pole_out.name = "po-hidden-electric-pole-out"
hidden_pole_out.connection_points = {
  {
    shadow =
    {
      copper = util.by_pixel(28, -3+3), --(45, -3+3),
    },
    wire =
    {
      copper = util.by_pixel(8, -32+3), --(29, -32+3),
    }
  },
}

local hidden_pole_alt = table.deepcopy(hidden_pole_in)
hidden_pole_alt.name = "po-hidden-electric-pole-alt"
hidden_pole_alt.maximum_wire_distance = 0.1

local hidden_eei_in = {
  type = "electric-energy-interface",
  name = "po-transformer-interface-hidden-in",
  localised_name = {"entity-name.po-transformer"},
  selection_box = {{-0.75, -0.75}, {0.75, 0.75}},
  collision_mask = {layers={}},
  energy_source = {
      type = "electric",
      -- For reference, steam engines produce 15kJ/tick
      buffer_capacity = "20kJ",  -- Gets doubled every tick until it is no longer limiting
      usage_priority = "secondary-input",
      input_flow_limit = "1YJ",
      output_flow_limit = "0YJ"
    },
  icons = transformer.icons,
  hidden = true,
  flags = {
    "not-on-map",
    "not-blueprintable",
    "not-deconstructable",
    "hide-alt-info",
    "not-flammable",
    "not-repairable",
    "not-upgradable",
    "no-copy-paste",
    "placeable-off-grid"
    --"not-selectable-in-game"
  },
}
local hidden_eei_out = table.deepcopy(hidden_eei_in)
hidden_eei_out.name = "po-transformer-interface-hidden-out"
hidden_eei_out.energy_source.usage_priority = "secondary-output"
hidden_eei_out.energy_source.input_flow_limit = "0J"
hidden_eei_out.energy_source.output_flow_limit = "1YJ"
local hidden_eei_out_high = table.deepcopy(hidden_eei_out)
hidden_eei_out_high.name = "po-transformer-interface-hidden-out-high"
hidden_eei_out_high.localised_name = {"entity-name.po-transformer-high"}
hidden_eei_out_high.energy_source.usage_priority = "primary-output"
local hidden_eei_out_low = table.deepcopy(hidden_eei_out)
hidden_eei_out_low.name = "po-transformer-interface-hidden-out-low"
hidden_eei_out_low.localised_name = {"entity-name.po-transformer-low"}
hidden_eei_out_low.energy_source.usage_priority = "tertiary"

-- Compatibility with dont-build-on-ores
-- Probably doesn't actually work: https://mods.factorio.com/mod/PowerOverload/discussion/60757b90339b4cc3502cabea
for _, prototype in pairs({transformer, hidden_pole_in, hidden_pole_out}) do
  if not prototype.mod_exceptions then
    prototype.mod_exceptions = {["dont-build-on-ores"] = false}
  else
    prototype.mod_exceptions["dont-build-on-ores"] = false
  end
end


data:extend{transformer, transformer_high, transformer_low, transformer_item, transformer_item_high, transformer_item_low, transformer_recipe, transformer_high_recipe, transformer_low_recipe, hidden_pole_item, hidden_pole_in, hidden_pole_out, hidden_pole_alt, hidden_eei_in, hidden_eei_out, hidden_eei_out_high, hidden_eei_out_low}