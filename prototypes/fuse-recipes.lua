local pole_names = { "small-electric", "medium-electric", "big-electric", "huge-electric" }
local name_prefix = "po-"
local name_suffix = "-fuse"

for _, pole_name in pairs(pole_names) do
  local name = name_prefix .. pole_name .. name_suffix

  local prototype_name = pole_name .. "-pole"
  if pole_name == "huge-electric" then  -- Already contains "po-" suffix
    prototype_name = "po-huge-electric-pole"
  end

  local recipe = data.raw.recipe[name]
  local base_recipe = data.raw.recipe[prototype_name]

  local ingredient_multiplier = 20 / (base_recipe.result_count or 1)
  local new_ingredients = {}
  for _, ingredient in pairs(base_recipe.ingredients) do
    table.insert(new_ingredients, {ingredient[1] or ingredient.name, (ingredient[2] or ingredient.amount) * ingredient_multiplier})
  end
  recipe.ingredients = new_ingredients
  recipe.result_count = 1
end