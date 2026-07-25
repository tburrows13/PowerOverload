PowerOverload = PowerOverload or {}

local registered_poles = PowerOverload.registered_poles or {}
PowerOverload.registered_poles = registered_poles

function PowerOverload.register_pole(def)
  if type(def) ~= "table" then
    log("PowerOverload.register_pole expected a table")
    return
  end

  if type(def.name) ~= "string" then
    log("PowerOverload.register_pole expected def.name to be a string")
    return
  end

  if type(def.default) ~= "string" then
    log("PowerOverload.register_pole expected def.default to be a string for " .. def.name)
    return
  end

  if registered_poles[def.name] then
    log("PowerOverload pole registration for " .. def.name .. " overwritten")
  end

  registered_poles[def.name] = {
    default = def.default,
  }
end

function PowerOverload.get_registered_poles()
  return registered_poles
end

return PowerOverload
