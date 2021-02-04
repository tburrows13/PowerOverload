-- Source: https://github.com/mspielberg/factorio-editor/blob/master/BaseEditor.lua
---------------------------------------------------------------------------------------------------
-- surface handling

local function editor_autoplace_control()
  for control in pairs(game.autoplace_control_prototypes) do
    if control:find("dirt") then
      return control
    end
  end
end

function create_editor_surface(name)
  local autoplace_control = editor_autoplace_control()
  local autoplace_controls, tile_settings
  if autoplace_control then
    autoplace_controls = {
      [autoplace_control] = {
        frequency = "very-low",
        size = "very-high",
      }
    }
  else
    tile_settings = {
      ["sand-1"] = {
        frequency = "very-low",
        size = "very-high",
      }
    }
  end
  local surface = game.create_surface(
    name,
    {
      starting_area = "none",
      water = "none",
      cliff_settings = { cliff_elevation_0 = 1024 },
      default_enable_all_autoplace_controls = false,
      autoplace_controls = autoplace_controls,
      autoplace_settings = {
        decorative = { treat_missing_as_default = false },
        entity = { treat_missing_as_default = false },
        tile = { treat_missing_as_default = false, settings = tile_settings },
      },
    }
  )
  surface.daytime = 0.35
  surface.freeze_daytime = true

  if remote.interfaces["RSO"] and remote.interfaces["RSO"]["ignoreSurface"] then
    remote.call("RSO", "ignoreSurface", name)
  end
end
