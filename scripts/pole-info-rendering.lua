-- Draws the "consumption / max" text above the pole currently hovered by each
-- player.
--
-- Runs every tick, so the text object is kept alive between ticks and only its
-- text and colour are updated: destroying and recreating it every tick was
-- noticeable in large bases. It is recreated only when the hovered pole changes.
-- Objects are tracked by numeric id, which is safe to store across save/load
-- (unlike the LuaRenderObject handle itself).

-- Drops every text object this module owns, including the flat id list used by
-- versions before the per-player objects existed.
function reset_pole_info_rendering()
  local old_ids = storage.pole_info_object_ids
  if old_ids then
    for i = #old_ids, 1, -1 do
      local object = rendering.get_object_by_id(old_ids[i])
      if object and object.valid then
        object.destroy()
      end
    end
    storage.pole_info_object_ids = nil
  end
  for _, info in pairs(storage.pole_info or {}) do
    local object = rendering.get_object_by_id(info.id)
    if object and object.valid then
      object.destroy()
    end
  end
  storage.pole_info = {}
end

---@param player_index uint
local function clear_player_info(player_index)
  local info = storage.pole_info[player_index]
  if not info then return end
  local object = rendering.get_object_by_id(info.id)
  if object and object.valid then
    object.destroy()
  end
  storage.pole_info[player_index] = nil
end

local TRANSFORMER_NAMES = {
  ["po-transformer"] = true,
  ["po-transformer-high"] = true,
  ["po-transformer-low"] = true,
}
local TRANSFORMER_NAME_LIST = {"po-transformer", "po-transformer-high", "po-transformer-low"}
-- The transformer's hidden in/out poles sit on top of it with a higher
-- selection priority, so hovering a transformer usually selects one of them.
local HIDDEN_TRANSFORMER_POLES = {
  ["po-hidden-electric-pole-in"] = true,
  ["po-hidden-electric-pole-out"] = true,
}

-- hidden pole unit_number -> transformer entity, per player. Only avoids
-- repeating the lookup every tick; the result is the same with or without it,
-- so it does not need to live in storage.
local hover_cache = {}

---@param player_index uint
---@param hidden_pole LuaEntity
---@return LuaEntity?
local function transformer_of_hidden_pole(player_index, hidden_pole)
  local cache = hover_cache[player_index]
  if cache and cache.unit_number == hidden_pole.unit_number and cache.transformer.valid then
    return cache.transformer
  end
  local transformer = hidden_pole.surface.find_entities_filtered{
    position = hidden_pole.position, radius = 1, name = TRANSFORMER_NAME_LIST, limit = 1,
  }[1]
  hover_cache[player_index] = transformer and {unit_number = hidden_pole.unit_number, transformer = transformer} or nil
  return transformer
end

-- "consumption / max" for a pole.
---@return LocalisedString?, string?, string?  text, comparison key, colour key
local function pole_info(pole, tick)
  local max_consumptions = storage.max_consumptions[pole.name]
  if not max_consumptions then return nil end
  -- Divide by 1.01 because amount is originally multiplied by that for hidden leeway
  local max_consumption = max_consumptions[pole.quality.name] / 1.01
  local consumption = get_network_consumption(pole, tick)
  local ratio = consumption / max_consumption
  local colour_key = "ok"
  if ratio > 1 then
    colour_key = "over"
  elseif ratio > 0.8 then
    colour_key = "near"
  end
  local text = shared.format_energy_number(consumption) .. " / " .. shared.format_energy_number(max_consumption)
  return text, text, colour_key
end

-- "Line loss: x%" for a transformer: the loss of the power arriving at it
-- (upstream). Green below 10%, yellow below 50%, red above.
---@return LocalisedString?, string?, string?
local function transformer_info(transformer)
  if not storage.global_settings["power-overload-line-losses"] then return nil end
  if not storage.transformers[transformer.unit_number] then return nil end
  -- nil: not fed through another transformer (e.g. straight from generators),
  -- so no line loss is modelled upstream of it
  local loss = get_upstream_line_loss(transformer.unit_number) or 0
  local colour_key = "ok"
  if loss >= 0.5 then
    colour_key = "over"
  elseif loss >= 0.1 then
    colour_key = "near"
  end
  local value = string.format("%.1f", loss * 100)
  return {"po-gui.line-loss-hover", value}, value, colour_key
end

---@param tick GameTick
function update_pole_rendering(tick)
  local infos = storage.pole_info

  for _, player in pairs(game.connected_players) do
    local player_index = player.index
    local pole = player.selected
    local text, key, colour_key
    local anchor = pole  -- entity the text is drawn on
    if pole and pole.force == player.force then
      if HIDDEN_TRANSFORMER_POLES[pole.name] then
        local transformer = transformer_of_hidden_pole(player_index, pole)
        if transformer then
          text, key, colour_key = transformer_info(transformer)
          anchor = transformer  -- keep the text centred whichever hidden pole is hovered
        end
      elseif pole.type == "electric-pole" then
        text, key, colour_key = pole_info(pole, tick)
      elseif TRANSFORMER_NAMES[pole.name] then
        text, key, colour_key = transformer_info(pole)
      end
    end

    if not text then
      clear_player_info(player_index)
    else
      local info = infos[player_index]
      local object = info and rendering.get_object_by_id(info.id)
      if object and object.valid and info.unit_number == pole.unit_number then
        if info.text ~= key then
          object.text = text
          info.text = key
        end
        if info.colour_key ~= colour_key then
          object.color = shared.pole_info_colours[colour_key]
          info.colour_key = colour_key
        end
      else
        clear_player_info(player_index)
        infos[player_index] = {
          id = rendering.draw_text{
            text = text,
            surface = pole.surface,
            target = {entity = anchor, offset = {x = 0, y = 0.7}},
            color = shared.pole_info_colours[colour_key],
            scale = 1.5 * player.display_scale,
            alignment = "center",
            scale_with_zoom = true,
            players = {player},
          }.id,
          unit_number = pole.unit_number,
          text = key,
          colour_key = colour_key,
        }
      end
    end
  end

  -- Players that disconnected while their text was up.
  for player_index in pairs(infos) do
    local player = game.get_player(player_index)
    if not (player and player.connected) then
      clear_player_info(player_index)
    end
  end
end
