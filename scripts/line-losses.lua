-- Distance-based line losses (distance only: the loss percentage does not
-- grow with power).
--
-- Each transformer gets an electrical distance D: the load-weighted
-- shortest-path distance, along copper wires, from its output pole to the
-- consumers of its output network. Each wire's length is weighted by a
-- resistance factor derived from the poles' maximum consumption, so long runs
-- of small poles cost much more than big or huge pole trunks. The
-- transformer's efficiency is then multiplied by (1 - loss_per_tile * D).
--
-- Consumers (proportional sharing: every source on a network sees the same
-- consumers with the same weights, only its own distances differ):
--   * downstream transformers, found by the search at their hidden input
--     pole, weighted by their measured input power;
--   * everything else (machines), = network consumption minus the downstream
--     transformers' draw, spread evenly over the network's real poles,
--     because the game does not say which pole powers which machine.
--   D = (sum_k P_k * d_k + P_rest * mean_pole_d) / (sum_k P_k + P_rest)
-- Because each transformer applies its own D to the energy it actually
-- moves, the network's total loss is automatically power-weighted across
-- its sources.
--
-- UPS: D is cached on the transformer. It is refreshed by a background job
-- that runs Dijkstra one transformer at a time, settling at most
-- POLES_PER_TICK poles per tick across all transformers, so cost per tick is
-- bounded regardless of base size and topology changes are picked up within
-- one full round. The per-tick transformer update only does one extra
-- multiplication.

local POLES_PER_TICK = 100
local LINE_LOSS_MAX = 0.75
local REFERENCE_POLE = "big-electric-pole"
local HIDDEN_PREFIX = "po-hidden-"
local HIDDEN_INPUT_POLE = "po-hidden-electric-pole-in"

---@param entity LuaEntity
local function is_hidden(entity)
  return string.sub(entity.name, 1, #HIDDEN_PREFIX) == HIDDEN_PREFIX
end

-- A fuse is the same line as its pole, so it uses its pole's rating rather
-- than its own (fuses are rated lower so that they blow first).
local fuse_to_pole
local function rating_name(name)
  if not fuse_to_pole then
    fuse_to_pole = {}
    for _, pole_name in pairs(shared.get_poles_to_make_fuses(script.active_mods)) do
      fuse_to_pole[shared.get_name_for_fuse(pole_name)] = shared.get_prototype_name_for_pole(pole_name)
    end
  end
  return fuse_to_pole[name] or name
end

-- Resistance per tile, relative to the big electric pole (= 1).
-- r = sqrt(P_ref / P_pole): a pole rated for 30x less power has ~5.5x the
-- resistance. Derived only from storage and the active mods, so every client
-- computes the same values and the cache needs no saving.
local resistance_cache = {}
---@param pole LuaEntity
local function resistance(pole)
  local name = pole.name
  local r = resistance_cache[name]
  if r then return r end
  local max_consumptions = storage.max_consumptions
  local ref = max_consumptions[REFERENCE_POLE] and max_consumptions[REFERENCE_POLE]["normal"]
  local rated = rating_name(name)
  local own = max_consumptions[rated] and max_consumptions[rated]["normal"]
  if ref and own and own > 0 then
    r = math.sqrt(ref / own)
  else
    r = 1
  end
  resistance_cache[name] = r
  return r
end

function reset_line_loss_cache()
  resistance_cache = {}
  fuse_to_pole = nil
end

-- Binary min-heap of {distance, unit_number, entity} ------------------------

local function heap_push(heap, item)
  local i = #heap + 1
  heap[i] = item
  while i > 1 do
    local parent = math.floor(i / 2)
    if heap[parent][1] <= item[1] then break end
    heap[i], heap[parent] = heap[parent], item
    i = parent
  end
end

local function heap_pop(heap)
  local n = #heap
  local top = heap[1]
  local last = heap[n]
  heap[n] = nil
  n = n - 1
  if n > 0 then
    heap[1] = last
    local i = 1
    while true do
      local l, r = 2 * i, 2 * i + 1
      local smallest = i
      if l <= n and heap[l][1] < heap[smallest][1] then smallest = l end
      if r <= n and heap[r][1] < heap[smallest][1] then smallest = r end
      if smallest == i then break end
      heap[i], heap[smallest] = heap[smallest], heap[i]
      i = smallest
    end
  end
  return top
end

-- Job management --------------------------------------------------------------

function init_line_losses()
  storage.line_loss_queue = {}
  storage.line_loss_input_poles = {}
  -- sink transformer unit_number -> {source transformer unit_number -> distance}
  storage.line_loss_feeders = {}
  storage.line_loss_job = nil
  reset_line_loss_cache()
end

local function refill_queue()
  local queue = {}
  -- hidden input pole unit_number -> transformer unit_number, so a search can
  -- tell which downstream transformer it has reached
  local input_poles = {}
  for unit_number, transformer_parts in pairs(storage.transformers) do
    queue[#queue + 1] = unit_number
    local pole_in = transformer_parts.pole_in
    if pole_in and pole_in.valid then
      input_poles[pole_in.unit_number] = unit_number
    end
  end
  table.sort(queue)  -- deterministic order
  storage.line_loss_queue = queue
  storage.line_loss_input_poles = input_poles
end

---@return table?
local function start_next_job()
  local queue = storage.line_loss_queue
  if not queue or #queue == 0 then
    refill_queue()
    queue = storage.line_loss_queue
  end
  while #queue > 0 do
    local unit_number = table.remove(queue)
    local transformer_parts = storage.transformers[unit_number]
    local pole_out = transformer_parts and transformer_parts.pole_out
    if pole_out and pole_out.valid then
      local job = {
        transformer = unit_number,
        start = pole_out.unit_number,
        heap = {},
        dist = {[pole_out.unit_number] = 0},
        done = {},
        sum = 0,
        count = 0,
        sinks = {},
      }
      heap_push(job.heap, {0, pole_out.unit_number, pole_out})
      return job
    end
  end
  return nil
end

local function finish_job(job, tick)
  local transformer_parts = storage.transformers[job.transformer]
  if transformer_parts then
    -- Keep the reverse index (who feeds each downstream transformer) in step
    storage.line_loss_feeders = storage.line_loss_feeders or {}
    local feeders = storage.line_loss_feeders
    for _, sink in pairs(transformer_parts.line_sinks or {}) do
      local f = feeders[sink.unit]
      if f then f[job.transformer] = nil end
    end
    for _, sink in pairs(job.sinks) do
      feeders[sink.unit] = feeders[sink.unit] or {}
      feeders[sink.unit][job.transformer] = sink.d
    end
    transformer_parts.line_sinks = job.sinks
    transformer_parts.line_sum_d = job.sum
    transformer_parts.line_n = job.count
    update_line_distance(transformer_parts, tick)
  end
end

-- Settles poles until the heap is empty or the budget runs out.
---@return integer remaining budget
local function step_job(job, budget, tick)
  local heap, dist, done = job.heap, job.dist, job.done
  while budget > 0 and #heap > 0 do
    local item = heap_pop(heap)
    local d, unit_number, pole = item[1], item[2], item[3]
    if not done[unit_number] and pole.valid then
      done[unit_number] = true
      budget = budget - 1
      local hidden = is_hidden(pole)
      if not hidden then
        job.sum = job.sum + d
        job.count = job.count + 1
      elseif pole.name == HIDDEN_INPUT_POLE then
        -- Another transformer's input: a consumer on this network
        local sink = storage.line_loss_input_poles and storage.line_loss_input_poles[unit_number]
        if sink and sink ~= job.transformer then
          job.sinks[#job.sinks + 1] = {unit = sink, d = d}
        end
      end
      -- Hidden poles (other transformers' inputs, alt-surface poles) are
      -- endpoints: the network does not continue through them.
      if unit_number == job.start or not hidden then
        local connector = pole.get_wire_connector(copper, false)
        if connector then
          local r1 = resistance(pole)
          local p1 = pole.position
          for _, connection in pairs(connector.connections) do
            local other = connection.target.owner
            if other.valid and other.type == "electric-pole" then
              local other_unit_number = other.unit_number
              if not done[other_unit_number] then
                local p2 = other.position
                local dx, dy = p2.x - p1.x, p2.y - p1.y
                local weight = math.sqrt(dx * dx + dy * dy) * 0.5 * (r1 + resistance(other))
                local new_d = d + weight
                local best = dist[other_unit_number]
                if not best or new_d < best then
                  dist[other_unit_number] = new_d
                  heap_push(heap, {new_d, other_unit_number, other})
                end
              end
            end
          end
        end
      end
    end
  end
  if #heap == 0 then
    finish_job(job, tick)
    job.finished = true
  end
  return budget
end

---@param tick GameTick
function update_line_losses(tick)
  if not storage.global_settings["power-overload-line-losses"] then return end
  local budget = POLES_PER_TICK
  -- Bounded so that a round of transformers with tiny networks cannot spin
  local starts = 0
  while budget > 0 and starts < 10 do
    local job = storage.line_loss_job
    if not job then
      job = start_next_job()
      if not job then return end
      storage.line_loss_job = job
      starts = starts + 1
    end
    budget = step_job(job, budget, tick)
    if job.finished then
      storage.line_loss_job = nil
    end
  end
end

-- Recomputes D from the cached distances and the current power flows.
-- Called when a search finishes and every 60 ticks per transformer.
---@param transformer_parts TransformerData
---@param tick GameTick
function update_line_distance(transformer_parts, tick)
  if not storage.global_settings["power-overload-line-losses"] then return end
  local n = transformer_parts.line_n
  if not n then return end  -- not searched yet
  local sinks = transformer_parts.line_sinks or {}
  local transformers = storage.transformers

  local num, den = 0, 0
  for _, sink in pairs(sinks) do
    local sink_parts = transformers[sink.unit]
    local p = sink_parts and sink_parts.p_in or 0
    num = num + p * sink.d
    den = den + p
  end

  local p_rest = 0
  local pole_out = transformer_parts.pole_out
  if n > 0 and pole_out and pole_out.valid then
    -- Network consumption includes the downstream transformers' draw (their
    -- hidden input interfaces are on this network), so subtract it.
    p_rest = get_network_consumption(pole_out, tick) - den
    if p_rest < 0 then p_rest = 0 end
  end
  local mean_pole_d = n > 0 and transformer_parts.line_sum_d / n or 0
  -- Total load on the output network, used to split this transformer's
  -- output among its consumers (grid-diagram.lua)
  transformer_parts.line_load_total = den + p_rest

  if den + p_rest > 0 then
    transformer_parts.line_distance = (num + p_rest * mean_pole_d) / (den + p_rest)
  elseif n > 0 then
    -- No load at all: fall back to the plain mean so the readout is not 0
    transformer_parts.line_distance = mean_pole_d
  elseif #sinks > 0 then
    local total = 0
    for _, sink in pairs(sinks) do total = total + sink.d end
    transformer_parts.line_distance = total / #sinks
  else
    transformer_parts.line_distance = 0
  end
end

-- Line loss for a single route of the given distance (capped).
---@param distance number
---@return number
function get_route_line_loss(distance)
  local loss = distance * storage.global_settings["power-overload-line-loss-per-tile"] / 100
  if loss > LINE_LOSS_MAX then loss = LINE_LOSS_MAX end
  return loss
end

-- Line loss of the power arriving at a transformer from upstream (display
-- only: the loss itself is charged at the transformers feeding the network).
-- Under proportional sharing this transformer receives each source's power
-- in proportion to that source's output, so the arriving power's distance is
-- the power-weighted mean of the routes from those sources to it.
---@param unit_number UnitNumber
---@return number? loss, number? distance  nil when nothing feeds it through a transformer
function get_upstream_line_loss(unit_number)
  local global_settings = storage.global_settings
  if not global_settings["power-overload-line-losses"] then return nil end
  local feeders = storage.line_loss_feeders and storage.line_loss_feeders[unit_number]
  if not feeders then return nil end
  local transformers = storage.transformers
  local num, den, sum_d, count = 0, 0, 0, 0
  for source, d in pairs(feeders) do
    local source_parts = transformers[source]
    if source_parts then
      local p = source_parts.p_out or 0
      num = num + p * d
      den = den + p
      sum_d = sum_d + d
      count = count + 1
    end
  end
  if count == 0 then return nil end
  local distance = den > 0 and num / den or sum_d / count
  local loss = distance * global_settings["power-overload-line-loss-per-tile"] / 100
  if loss > LINE_LOSS_MAX then loss = LINE_LOSS_MAX end
  return loss, distance
end

-- Fraction of energy that survives the line, for a transformer.
---@param transformer_parts TransformerData
---@return number
function get_line_factor(transformer_parts)
  local global_settings = storage.global_settings
  if not global_settings["power-overload-line-losses"] then return 1 end
  local loss = (transformer_parts.line_distance or 0) * global_settings["power-overload-line-loss-per-tile"] / 100
  if loss > LINE_LOSS_MAX then loss = LINE_LOSS_MAX end
  return 1 - loss
end
