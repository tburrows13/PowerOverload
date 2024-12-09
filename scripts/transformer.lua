---@class TransformerData
---@field transformer LuaEntity
---@field surface LuaSurface
---@field transformer_surface LuaSurface
---@field force LuaForce
---@field position_in MapPosition
---@field position_out MapPosition
---@field pole_in LuaEntity?
---@field pole_in_alt LuaEntity?
---@field interface_in LuaEntity?
---@field pole_out LuaEntity?
---@field pole_out_alt LuaEntity?
---@field interface_out LuaEntity?
---@field bucket number

---@param transformer_entity LuaEntity
---@param old_transformer_parts table?  -- For migration only
function create_transformer(transformer_entity, old_transformer_parts)

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
    bucket = transformer_entity.unit_number % 600
  }

  storage.transformers[transformer_entity.unit_number] = transformer_parts

  transformer_entity.power_switch_state = true
  script.register_on_object_destroyed(transformer_entity)

  if old_transformer_parts then  -- Migration
    transformer_parts.pole_in = old_transformer_parts.pole_in
    transformer_parts.pole_in_alt = old_transformer_parts.pole_in_alt
    transformer_parts.interface_in = old_transformer_parts.interface_in
    transformer_parts.pole_out = old_transformer_parts.pole_out
    transformer_parts.pole_out_alt = old_transformer_parts.pole_out_alt
    transformer_parts.interface_out = old_transformer_parts.interface_out
  end

  -- Creates all the extra entities
  revive_ghost_poles(transformer_parts)
  check_transformer_poles(transformer_parts)
  check_transformer_interfaces(transformer_parts)
end

---@param transformer_parts TransformerData
function revive_ghost_poles(transformer_parts)
  -- Called on transformer creation
  local surface = transformer_parts.surface
  local bounding_box = transformer_parts.transformer.bounding_box

  local pole_in_ghost = surface.find_entities_filtered{area = bounding_box, ghost_name = "po-hidden-electric-pole-in", limit = 1}[1]
  if pole_in_ghost then
    _, transformer_parts.pole_in = pole_in_ghost.revive()
    transformer_parts.pole_in.teleport(transformer_parts.position_in)
  end

  local pole_out_ghost = surface.find_entities_filtered{area = bounding_box, ghost_name = "po-hidden-electric-pole-out", limit = 1}[1]
  if pole_out_ghost then
    _, transformer_parts.pole_out = pole_out_ghost.revive()
    transformer_parts.pole_out.teleport(transformer_parts.position_out)
  end
end

---@param transformer_parts TransformerData
function check_transformer_poles(transformer_parts)
  -- Called occasionally to fix breakages
  local pole_in = transformer_parts.pole_in
  if not (pole_in and pole_in.valid) then
    pole_in = transformer_parts.surface.create_entity{
      name = "po-hidden-electric-pole-in",
      position = transformer_parts.position_in,
      force = transformer_parts.force,
      raise_built = true
    }  ---@cast pole_in -?
    transformer_parts.pole_in = pole_in
  end
  local pole_in_connector = pole_in.get_wire_connector(copper, true)

  local pole_in_alt = transformer_parts.pole_in_alt
  if not (pole_in_alt and pole_in_alt.valid) then
    pole_in_alt = transformer_parts.transformer_surface.create_entity{
      name = "po-hidden-electric-pole-alt",
      position = transformer_parts.position_in,
      force = transformer_parts.force,
      raise_built = true
    }  ---@cast pole_in_alt -?
    transformer_parts.pole_in_alt = pole_in_alt
  end
  pole_in_alt.get_wire_connector(copper, true).connect_to(pole_in_connector)

  local pole_out = transformer_parts.pole_out
  if not (pole_out and pole_out.valid) then
    pole_out = transformer_parts.surface.create_entity{
      name = "po-hidden-electric-pole-out",
      position = transformer_parts.position_out,
      force = transformer_parts.force,
      raise_built = true
    }  ---@cast pole_out -?
    transformer_parts.pole_out = pole_out
  end
  local pole_out_connector = pole_out.get_wire_connector(copper, true)

  local pole_out_alt = transformer_parts.pole_out_alt
  if not (pole_out_alt and pole_out_alt.valid) then
    pole_out_alt = transformer_parts.transformer_surface.create_entity{
      name = "po-hidden-electric-pole-alt",
      position = transformer_parts.position_out,
      force = transformer_parts.force,
      raise_built = true
    }   ---@cast pole_out_alt -?
    transformer_parts.pole_out_alt = pole_out_alt
  end
  pole_out_alt.get_wire_connector(copper, true).connect_to(pole_out_connector)

  pole_in_connector.disconnect_from(pole_out_connector)
end

---@param transformer_parts TransformerData
function check_transformer_interfaces(transformer_parts)
  -- Called every tick
  if not (transformer_parts.interface_in and transformer_parts.interface_in.valid) then
    local interface_in = transformer_parts.transformer_surface.create_entity{
      name = "po-transformer-interface-hidden-in",
      position = transformer_parts.position_in,
      force = transformer_parts.force
    }
    transformer_parts.interface_in = interface_in
  end

  if not (transformer_parts.interface_out and transformer_parts.interface_out.valid) then
    local interface_out = transformer_parts.transformer_surface.create_entity{
      name = "po-transformer-interface-hidden-out",
      position = transformer_parts.position_out,
      force = transformer_parts.force
    }
    transformer_parts.interface_out = interface_out
  end
end

---@param unit_number UnitNumber
function on_transformer_destroyed(unit_number)
  local transformer_parts = storage.transformers[unit_number]
  if transformer_parts then
    -- If the transformer itself is destroyed then the player won't get the item back
    for _, part_name in pairs({"pole_in", "pole_in_alt", "interface_in", "pole_out", "pole_out_alt", "interface_out"}) do
      local part = transformer_parts[part_name]
      if part and part.valid then
        part.destroy()
      end
    end
    storage.transformers[unit_number] = nil
  end
end

---@param tick GameTick
function update_transformers(tick)
  local efficiency = storage.global_settings["power-overload-transformer-efficiency"]
  local current_bucket = tick % 600

  for unit_number, transformer in pairs(storage.transformers) do
    local transformer_entity = transformer.transformer
    if transformer_entity and transformer_entity.valid then
      if transformer_entity.power_switch_state then
        check_transformer_interfaces(transformer)
        if transformer.bucket == current_bucket then
          --log("Checking poles")
          check_transformer_poles(transformer)
        end
        local interface_in = transformer.interface_in
        local interface_out = transformer.interface_out
        local buffer_size = interface_in.electric_buffer_size
        local energy_in = interface_in.energy
        local energy_out = interface_out.energy
        -- Double buffer size if necessary
        -- Due to effiency calculations we don't always empty the buffer when we need more energy
        local effective_energy_out = (energy_out - buffer_size) / efficiency + buffer_size
        if energy_in == buffer_size and effective_energy_out <= 0 then
          buffer_size = buffer_size * 1.01 + 1666.667
          -- Add a constant amount so that networks with low consumption and high variance can spin up in time
          -- 100kW = 100,000 / 60 = 1666.667
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
