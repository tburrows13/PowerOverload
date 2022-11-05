local electric_1_effects = data.raw.technology["electric-energy-distribution-1"].effects

for _, recipe_name in pairs({"po-medium-electric-fuse", "po-big-electric-fuse", "po-transformer"}) do
  table.insert(electric_1_effects, {
    type = "unlock-recipe",
    recipe = recipe_name
  })
end
if mods["pyalternativeenergy"] then
  table.insert(electric_1_effects, {
    type = "unlock-recipe",
    recipe = "po-nexelit-power-fuse"
  })
end

data:extend{
  {
    type = "technology",
    name = "electric-energy-distribution-3",
    icon_size = 165, icon_mipmaps = 1,
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
    prerequisites = {"electric-energy-distribution-2", "chemical-science-pack", "advanced-electronics-2"},
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
