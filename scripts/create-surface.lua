function create_transformer_surface(surface_name)
  local new_surface_name = surface_name .. "-transformer"
  if not game.get_surface(new_surface_name) and string.sub(surface_name, -12) ~= "-transformer" then
    local surface = game.create_surface(new_surface_name)
    surface.generate_with_lab_tiles = true
    surface.show_clouds = false
    surface.always_day = true
  
    if remote.interfaces["RSO"] and remote.interfaces["RSO"]["ignoreSurface"] then
      remote.call("RSO", "ignoreSurface", new_surface_name)
    end
  
    log("Creating transformer surface " .. new_surface_name)
  end
end

function create_transformer_surfaces()
  for _, surface in pairs(game.surfaces) do
    create_transformer_surface(surface.name)
  end
end
