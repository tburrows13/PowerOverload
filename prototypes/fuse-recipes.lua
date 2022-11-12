local shared = require "__PowerOverload__/shared"

local function multiply_ingredients(from_recipe, to_recipe, name)
  to_recipe.result = name
  local result_count
  if to_recipe.results then
    result_count = to_recipe.results[1].amount
    to_recipe.results = nil
  end
  if name == "po-small-electric-fuse" then
    to_recipe.enabled = true
  end

  local ingredient_multiplier = 20 / (result_count or from_recipe.result_count or 1)

  local new_ingredients = {}
  for _, ingredient in pairs(from_recipe.ingredients) do
    local ingredient_name = ingredient[1] or ingredient.name
    if string.sub(ingredient_name, -13) ~= "electric-pole" then
      -- Don't copy electric poles to fuse recipes
      table.insert(new_ingredients, {ingredient[1] or ingredient.name, (ingredient[2] or ingredient.amount) * ingredient_multiplier})
    end
  end
  to_recipe.ingredients = new_ingredients

  to_recipe.result_count = 1

  to_recipe.enabled = true  -- overridden in technology-updates
end

for _, pole_name in pairs(shared.get_poles_to_make_fuses(mods)) do
  local name = shared.get_name_for_fuse(pole_name)
  local prototype_name = shared.get_prototype_name_for_pole(pole_name)

  local base_recipe = data.raw.recipe[prototype_name]
  local recipe = table.deepcopy(base_recipe)
  recipe.name = name

  if base_recipe.normal or base_recipe.expensive then
    if base_recipe.normal then
      multiply_ingredients(base_recipe.normal, recipe.normal, name)
    end
    if base_recipe.expensive then
      multiply_ingredients(base_recipe.expensive, recipe.expensive, name)
    end
  else
    multiply_ingredients(base_recipe, recipe, name)
  end

  data:extend{recipe}
end