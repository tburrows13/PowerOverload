local electric_1_effects = data.raw.technology["electric-energy-distribution-1"].effects

for _, recipe_name in pairs({"po-nexelit-power-fuse"}) do
  table.insert(electric_1_effects, {
    type = "unlock-recipe",
    recipe = recipe_name
  })
end