table.insert(data.raw.technology["electric-energy-distribution-1"].effects,
  {
    type = "unlock-recipe",
    recipe = "po-transformer"
  }
)

data:extend{
  {
    type = "technology",
    name = "electric-energy-distribution-3",
    icon_size = 165, icon_mipmaps = 1,
    icon = "__PowerOverload__/graphics/big-electric-pole-tech.png",
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "po-huge-electric-pole"
      }
    },
    prerequisites = {"electric-energy-distribution-2", "chemical-science-pack"},
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