local shared = require "__PowerOverload__/shared"

local function multiply_ingredients(from_recipe, to_recipe, name)
  to_recipe.results[1].name = name
  to_recipe.main_product = nil  -- In case some other mod has set it

  local ingredient_multiplier = 20 / (from_recipe.results[1].amount)

  local new_ingredients = {}
  for _, ingredient in pairs(from_recipe.ingredients) do
    local ingredient_name = ingredient.name
    if string.sub(ingredient_name, -13) ~= "electric-pole" then
      -- Don't copy electric poles to fuse recipes
      table.insert(new_ingredients, {type=ingredient.type, name=ingredient.name, amount=ingredient.amount * ingredient_multiplier})
    end
  end
  to_recipe.ingredients = new_ingredients

  to_recipe.results[1].amount = 1

  if not mods["pypostprocessing"] then  -- https://mods.factorio.com/mod/PowerOverload/discussion/6371d7602024262b14858736
    to_recipe.enabled = true  -- overridden in technology-updates
  end
end

for _, pole_name in pairs(shared.get_poles_to_make_fuses(mods)) do
  local name = shared.get_name_for_fuse(pole_name)
  local prototype_name = shared.get_prototype_name_for_pole(pole_name)

  local base_recipe = data.raw.recipe[prototype_name]
  local recipe = table.deepcopy(base_recipe)
  recipe.name = name

  multiply_ingredients(base_recipe, recipe, name)

  data:extend{recipe}
end