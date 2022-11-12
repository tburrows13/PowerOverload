-- data-updates

if mods["bzlead"] then
  table.insert(data.raw.recipe["po-huge-electric-pole"].ingredients, {"lead-plate", 10})
  table.insert(data.raw.recipe["po-huge-electric-fuse"].ingredients, {"lead-plate", 200})
  table.insert(data.raw.recipe["po-interface"].ingredients, {"lead-plate", 25})  
end

if mods["space-exploration"] then
  table.insert(data.raw.technology["se-energy-beam-defence"].prerequisites, "po-electric-energy-distribution-3")
end