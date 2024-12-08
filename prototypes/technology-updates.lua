local sizes = {"small", "medium", "big"}

for name, technology in pairs(data.raw.technology) do
  if technology.effects then
    for _, effect in pairs(technology.effects) do
      if effect.type == "unlock-recipe" then
        for _, size in pairs(sizes) do
          if effect.recipe == size .. "-electric-pole" then
            local recipe_name = "po-" .. size .. "-electric-fuse"
            table.insert(technology.effects, {
              type = "unlock-recipe",
              recipe = recipe_name
            })
            data.raw.recipe[recipe_name].enabled = false
          end
        end
      end
    end
  end
end

data.raw.recipe["po-huge-electric-fuse"].enabled = false
