local function set_recipe_enabled(recipe_name, enabled)
  local recipe = data.raw.recipe[recipe_name]
  if recipe.normal or recipe.expensive then
    if recipe.normal then
      recipe.normal.enabled = enabled
    end
    if recipe.expensive then
      recipe.expensive.enabled = enabled
    end
  else
    recipe.enabled = enabled
  end
end


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
            set_recipe_enabled(recipe_name, false)
          end
        end
      end
    end
  end
end

set_recipe_enabled("po-huge-electric-fuse", false)
