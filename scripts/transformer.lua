function create_transformer(transformer_entity, old_transformer_parts)
  -- Use transformer_parts for migration only

  local surface = transformer_entity.surface
  local transformer_surface = game.get_surface(surface.name .. "-transformer")
  if not transformer_surface then
    game.print("Transformer surface missing. Please report this at https://mods.factorio.com/mod/PowerOverload/discussion")
    return
  end

  local position = transformer_entity.position
  local position_in = {position.x - 0.6, position.y}
  local position_out = {position.x + 0.6, position.y}

  local transformer_parts = {
    transformer = transformer_entity,
    surface = surface,
    transformer_surface = transformer_surface,
    force = transformer_entity.force,
    position_in = position_in,
    position_out = position_out,
  }

  global.transformers[transformer_entity.unit_number] = transformer_parts

  transformer_entity.power_switch_state = true
  script.register_on_entity_destroyed(transformer_entity)

  if old_transformer_parts then  -- Migration
    transformer_parts.pole_in = old_transformer_parts.pole_in
    transformer_parts.pole_in_alt = old_transformer_parts.pole_in_alt
    transformer_parts.interface_in = old_transformer_parts.interface_in
    transformer_parts.pole_out = old_transformer_parts.pole_out
    transformer_parts.pole_out_alt = old_transformer_parts.pole_out_alt
    transformer_parts.interface_out = old_transformer_parts.interface_out
  end

  check_transformer(transformer_parts)  -- Creates all the extra entities
end

function check_transformer(transformer_parts)
  if not (transformer_parts.pole_in and transformer_parts.pole_in.valid) then
    local pole_in = transformer_parts.surface.create_entity{name = "po-hidden-electric-pole-in",
                                         position = transformer_parts.position_in,
                                         force = transformer_parts.force,
                                         raise_built = true}
    transformer_parts.pole_in = pole_in
  end
  if not (transformer_parts.pole_in_alt and transformer_parts.pole_in_alt.valid) then
    local pole_in_alt = transformer_parts.transformer_surface.create_entity{name = "po-hidden-electric-pole-alt",
                                             position = transformer_parts.position_in,
                                             force = transformer_parts.force,
                                             raise_built = true}
    pole_in_alt.connect_neighbour(transformer_parts.pole_in)
    transformer_parts.pole_in_alt = pole_in_alt
  end
  if not (transformer_parts.interface_in and transformer_parts.interface_in.valid) then
    local interface_in = transformer_parts.transformer_surface.create_entity{name = "po-transformer-interface-hidden-in",
                                              position = transformer_parts.position_in,
                                              force = transformer_parts.force}
    transformer_parts.interface_in = interface_in
  end

  if not (transformer_parts.pole_out and transformer_parts.pole_out.valid) then
    local pole_out = transformer_parts.surface.create_entity{name = "po-hidden-electric-pole-out",
                                         position = transformer_parts.position_out,
                                         force = transformer_parts.force,
                                         raise_built = true}
    transformer_parts.pole_out = pole_out
  end
  if not (transformer_parts.pole_out_alt and transformer_parts.pole_out_alt.valid) then
    local pole_out_alt = transformer_parts.transformer_surface.create_entity{name = "po-hidden-electric-pole-alt",
                                             position = transformer_parts.position_out,
                                             force = transformer_parts.force,
                                             raise_built = true}
    pole_out_alt.connect_neighbour(transformer_parts.pole_out)
    transformer_parts.pole_out_alt = pole_out_alt
  end
  if not (transformer_parts.interface_out and transformer_parts.interface_out.valid) then
    local interface_out = transformer_parts.transformer_surface.create_entity{name = "po-transformer-interface-hidden-out",
                                              position = transformer_parts.position_out,
                                              force = transformer_parts.force}
    transformer_parts.interface_out = interface_out
  end
end

function on_transformer_destroyed(unit_number)
  local transformer_parts = global.transformers[unit_number]
  if transformer_parts then
    -- If the transformer itself is destroyed then the player won't get the item back
    for _, part_name in pairs({"pole_in", "pole_in_alt", "interface_in", "pole_out", "pole_out_alt", "interface_out"}) do
      local part = transformer_parts[part_name]
      if part and part.valid then
        part.destroy()
      end
    end
    global.transformers[unit_number] = nil
  end
end


function update_transformers()
  local efficiency = global.global_settings["power-overload-transformer-efficiency"]

  for unit_number, transformer in pairs(global.transformers) do
    local transformer_entity = transformer.transformer
    if transformer_entity and transformer_entity.valid then
      if transformer_entity.power_switch_state then
        check_transformer(transformer)
        local interface_in = transformer.interface_in
        local interface_out = transformer.interface_out
        local buffer_size = interface_in.electric_buffer_size
        local energy_in = interface_in.energy
        local energy_out = interface_out.energy
        -- Double buffer size if necessary
        -- Due to effiency calculations we don't always empty the buffer when we need more energy
        local effective_energy_out = (energy_out - buffer_size) / efficiency + buffer_size
        if energy_in == buffer_size and effective_energy_out <= 0 then
          buffer_size = buffer_size * 1.2
          --log("Increasing buffer size to support " .. math.floor(buffer_size * 60 / 1000000) .. "MW")
          interface_in.electric_buffer_size = buffer_size
          interface_out.electric_buffer_size = buffer_size
        elseif effective_energy_out / energy_in > 0.01 and buffer_size > 1000 then
          -- Shrink the buffer size if necessary
          buffer_size = buffer_size * 0.99
          --log("Decreasing buffer size to support " .. math.floor(buffer_size * 60 / 1000000) .. "MW")
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
      on_transformer_destroyed(unit_number)
    end
  end
end
