local electric_1_effects = data.raw.technology["electric-energy-distribution-1"].effects

table.insert(electric_1_effects, {
  type = "unlock-recipe",
  recipe = "po-transformer"
})

data:extend{
  {
    type = "technology",
    name = "po-electric-energy-distribution-3",
    localised_name = {"", {"technology-name.electric-energy-distribution"}, " 3"},
    localised_description = {"technology-description.electric-energy-distribution"},
    icon_size = 165,
    icon = "__PowerOverload__/graphics/huge-electric-pole-tech.png",
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "po-huge-electric-pole"
      },
      {
        type = "unlock-recipe",
        recipe = "po-huge-electric-fuse"
      },
      {
        type = "unlock-recipe",
        recipe = "po-interface"
      }
    },
    prerequisites = {"electric-energy-distribution-2", "chemical-science-pack", "processing-unit"},
    unit =
    {
      count = 400,
      ingredients =
      {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1}
      },
      time = 45
    },
    order = "c-e-c"
  },
}
