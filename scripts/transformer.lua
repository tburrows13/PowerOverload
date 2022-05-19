function create_update_transformer(transformer)
  local surface = transformer.surface
  local transformer_surface = game.get_surface(surface.name .. "-transformer")
  if not transformer_surface then
    game.print("Transformer surface missing. Please report this at https://mods.factorio.com/mod/PowerOverload/discussion")
    return
  end
  local transformer_parts = global.transformers[transformer.unit_number]
  if not transformer_parts or not transformer_parts.transformer then
    transformer_parts = {transformer = transformer}
  end
  transformer.power_switch_state = true

  local position = transformer.position
  local position_in = {position.x - 0.6, position.y}
  local position_out = {position.x + 0.6, position.y}
  if not (transformer_parts.pole_in and transformer_parts.pole_in.valid) then
    local pole_in = surface.create_entity{name = "po-hidden-electric-pole-in",
                                         position = position_in,
                                         force = transformer.force,
                                         raise_built = true}
    transformer_parts.pole_in = pole_in
  end
  if not (transformer_parts.pole_in_alt and transformer_parts.pole_in_alt.valid) then
    local pole_in_alt = transformer_surface.create_entity{name = "po-hidden-electric-pole-alt",
                                             position = position_in,
                                             force = transformer.force,
                                             raise_built = true}
    pole_in_alt.connect_neighbour(transformer_parts.pole_in)
    transformer_parts.pole_in_alt = pole_in_alt
  end
  if not (transformer_parts.interface_in and transformer_parts.interface_in.valid) then
    local interface_in = transformer_surface.create_entity{name = "po-transformer-interface-hidden-in",
                                              position = position_in,
                                              force = transformer.force}
    transformer_parts.interface_in = interface_in
  end

  if not (transformer_parts.pole_out and transformer_parts.pole_out.valid) then
    local pole_out = surface.create_entity{name = "po-hidden-electric-pole-out",
                                         position = position_out,
                                         force = transformer.force,
                                         raise_built = true}
    transformer_parts.pole_out = pole_out
  end
  if not (transformer_parts.pole_out_alt and transformer_parts.pole_out_alt.valid) then
    local pole_out_alt = transformer_surface.create_entity{name = "po-hidden-electric-pole-alt",
                                             position = position_out,
                                             force = transformer.force,
                                             raise_built = true}
    pole_out_alt.connect_neighbour(transformer_parts.pole_out)
    transformer_parts.pole_out_alt = pole_out_alt
  end
  if not (transformer_parts.interface_out and transformer_parts.interface_out.valid) then
    local interface_out = transformer_surface.create_entity{name = "po-transformer-interface-hidden-out",
                                              position = position_out,
                                              force = transformer.force}
    transformer_parts.interface_out = interface_out
  end

  global.transformers[transformer.unit_number] = transformer_parts

  script.register_on_entity_destroyed(transformer)
end

function on_transformer_destroyed(transformer)
  local transformer_parts = global.transformers[transformer.unit_number]
  if transformer_parts then
    for name, entity in pairs(transformer_parts) do
      if name ~= "transformer" then
        -- If the transformer is destryed then the player won't get the item back
        entity.destroy()
      end
    end
  end
end


function update_transformers()
  for i, transformer in pairs(global.transformers) do
    local transformer_entity = transformer.transformer
    if transformer_entity and transformer_entity.valid then
      if transformer_entity.power_switch_state then
        create_update_transformer(transformer_entity)
        local interface_in = transformer.interface_in
        local interface_out = transformer.interface_out
        local buffer_size = interface_in.electric_buffer_size
        local energy_in = interface_in.energy
        local energy_out = interface_out.energy

        local efficiency = settings.global["power-overload-transformer-efficiency"].value

        -- Double buffer size if necessary
        -- Due to effiency calculations we don't always empty the buffer when we need more energy
        local effective_energy_out = (energy_out - buffer_size) / efficiency + buffer_size
        if energy_in == buffer_size and effective_energy_out <= 0 then
          buffer_size = buffer_size * 1.2
          log("Increasing buffer size to support " .. math.floor(buffer_size * 60 / 1000000) .. "MW")
          interface_in.electric_buffer_size = buffer_size
          interface_out.electric_buffer_size = buffer_size
        elseif effective_energy_out / energy_in > 0.01 and buffer_size > 1000 then
          -- Shrink the buffer size if necessary
          buffer_size = buffer_size * 0.99
          log("Decreasing buffer size to support " .. math.floor(buffer_size * 60 / 1000000) .. "MW")
          interface_in.electric_buffer_size = buffer_size
          interface_out.electric_buffer_size = buffer_size
        end

        -- Transfer as much energy as possible
        local output_space = buffer_size - energy_out
        local ideal_input_used = output_space / efficiency
        local actual_input_used = math.min(ideal_input_used, energy_in)
        local actual_output_gained = actual_input_used * efficiency

        interface_in.energy = energy_in - actual_input_used
        interface_out.energy = energy_out + actual_output_gained
      end
    else
      global.transformers[i] = nil
    end
  end
end
