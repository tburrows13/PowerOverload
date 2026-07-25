-- GUI shown next to a transformer's window, letting the player name and colour
-- its output (downstream) network. This is the first GUI in the mod.
--
-- Colour preview note: Factorio only lets a mod set an arbitrary colour on a
-- `progressbar` at runtime (LuaStyle.color), so the live preview is a fully
-- filled progressbar. The colour itself is chosen with three RGB sliders.

local FRAME_NAME = "po-transformer-gui"
local CONTENT_NAME = "po-transformer-gui-content"
local NAME_FIELD = "po-tf-name"
local PREVIEW_NAME = "po-tf-preview"
local SLIDER_PREFIX = "po-tf-slider-"
local VALUE_PREFIX = "po-tf-value-"

local CHANNELS = {"r", "g", "b"}

---@param entity LuaEntity
---@return boolean
local function is_transformer(entity)
  local name = entity.name
  return name == "po-transformer" or name == "po-transformer-high" or name == "po-transformer-low"
end

-- Recursively finds a descendant element by name.
---@param root LuaGuiElement
---@param name string
---@return LuaGuiElement?
local function find_child(root, name)
  local direct = root[name]
  if direct then return direct end
  for _, child in pairs(root.children) do
    local found = find_child(child, name)
    if found then return found end
  end
  return nil
end

-- Returns the transformer entity whose window the player currently has open,
-- or nil if it is not one of ours.
---@param player LuaPlayer
---@return LuaEntity?
local function opened_transformer(player)
  local opened = player.opened
  -- player.opened is always a LuaObject or nil, so indexing object_name is safe.
  if opened and opened.object_name == "LuaEntity" and opened.valid and is_transformer(opened) then
    return opened
  end
  return nil
end

-- 0-1 float channel -> 0-255 int.
local function to255(v)
  return math.floor((v or 0) * 255 + 0.5)
end

---@param player LuaPlayer
function close_transformer_gui(player)
  local frame = player.gui.relative[FRAME_NAME]
  if frame then frame.destroy() end
end

---@param player LuaPlayer
---@param transformer_entity LuaEntity
function open_transformer_gui(player, transformer_entity)
  local transformer_parts = storage.transformers[transformer_entity.unit_number]
  if not transformer_parts then return end
  ensure_transformer_identity(transformer_parts, transformer_entity.unit_number)

  close_transformer_gui(player)

  local color = transformer_parts.color

  local frame = player.gui.relative.add{
    type = "frame",
    name = FRAME_NAME,
    direction = "vertical",
    caption = {"po-gui.network-title"},
    anchor = {
      gui = defines.relative_gui_type.power_switch_gui,
      position = defines.relative_gui_position.right,
    },
  }
  local content = frame.add{
    type = "frame",
    name = CONTENT_NAME,
    style = "inside_shallow_frame_with_padding",
    direction = "vertical",
  }

  -- Name row
  local name_flow = content.add{type = "flow", direction = "horizontal"}
  name_flow.style.vertical_align = "center"
  name_flow.add{type = "label", caption = {"po-gui.name"}}
  local name_field = name_flow.add{
    type = "textfield",
    name = NAME_FIELD,
    text = transformer_parts.name,
    icon_selector = true,
  }
  name_field.style.horizontally_stretchable = true

  content.add{type = "line", direction = "horizontal"}

  -- Colour preview (progressbar is the only element that takes a runtime colour)
  content.add{type = "label", caption = {"po-gui.color"}}
  local preview = content.add{type = "progressbar", name = PREVIEW_NAME, value = 1}
  preview.style.horizontally_stretchable = true
  preview.style.height = 16
  preview.style.color = {r = color.r, g = color.g, b = color.b}

  -- RGB sliders
  local sliders = content.add{type = "table", column_count = 3}
  sliders.style.horizontal_spacing = 8
  sliders.style.vertical_align = "center"
  for _, channel in pairs(CHANNELS) do
    sliders.add{type = "label", caption = {"po-gui.channel-" .. channel}}
    sliders.add{
      type = "slider",
      name = SLIDER_PREFIX .. channel,
      minimum_value = 0,
      maximum_value = 255,
      value = to255(color[channel]),
      value_step = 1,
      discrete_slider = true,
    }
    sliders.add{
      type = "label",
      name = VALUE_PREFIX .. channel,
      caption = tostring(to255(color[channel])),
    }
  end
end

-- Applies the current slider values to the transformer's colour and refreshes
-- the preview, value labels and the map overlay.
---@param player LuaPlayer
---@param transformer_entity LuaEntity
local function apply_color_from_sliders(player, transformer_entity)
  local transformer_parts = storage.transformers[transformer_entity.unit_number]
  if not transformer_parts then return end
  local frame = player.gui.relative[FRAME_NAME]
  if not frame then return end

  local color = {a = 1}
  for _, channel in pairs(CHANNELS) do
    local slider = find_child(frame, SLIDER_PREFIX .. channel)
    local value = slider and slider.slider_value or 0
    color[channel] = value / 255
    local value_label = find_child(frame, VALUE_PREFIX .. channel)
    if value_label then value_label.caption = tostring(math.floor(value + 0.5)) end
  end
  transformer_parts.color = color

  local preview = find_child(frame, PREVIEW_NAME)
  if preview then preview.style.color = {r = color.r, g = color.g, b = color.b} end

  -- Refresh the map overlay via the throttled dirty flag so dragging a slider
  -- doesn't trigger a full rebuild on every value change.
  mark_overlay_dirty()
end

-- Event entry points, wired up in control.lua --------------------------------

---@param event EventData.on_gui_opened
function transformer_gui_on_opened(event)
  if event.gui_type ~= defines.gui_type.entity then return end
  local entity = event.entity
  if not (entity and entity.valid and is_transformer(entity)) then return end
  local player = game.get_player(event.player_index)  ---@cast player -?
  open_transformer_gui(player, entity)
end

---@param event EventData.on_gui_closed
function transformer_gui_on_closed(event)
  if event.gui_type ~= defines.gui_type.entity then return end
  local entity = event.entity
  if not (entity and entity.valid and is_transformer(entity)) then return end
  local player = game.get_player(event.player_index)  ---@cast player -?
  close_transformer_gui(player)
end

---@param event EventData.on_gui_text_changed
function transformer_gui_on_text_changed(event)
  if event.element.name ~= NAME_FIELD then return end
  local player = game.get_player(event.player_index)  ---@cast player -?
  local transformer_entity = opened_transformer(player)
  if not transformer_entity then return end
  local transformer_parts = storage.transformers[transformer_entity.unit_number]
  if not transformer_parts then return end
  transformer_parts.name = event.element.text
  mark_overlay_dirty()
end

---@param event EventData.on_gui_value_changed
function transformer_gui_on_value_changed(event)
  if string.sub(event.element.name, 1, #SLIDER_PREFIX) ~= SLIDER_PREFIX then return end
  local player = game.get_player(event.player_index)  ---@cast player -?
  local transformer_entity = opened_transformer(player)
  if not transformer_entity then return end
  apply_color_from_sliders(player, transformer_entity)
end
