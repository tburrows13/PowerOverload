# Power Overload
## Features
- Power poles may explode if their network's total consumption goes over the maximum consumption for that power pole type
- Separate your network into subnetworks using transformers, but ensure that each subnetwork does not get too large!
    - You will usually want your subnetworks to only contain one type of power pole, so power poles of different types no longer automatically connect to each other
    - Added a new "Toggle automatic pole connections" shortcut (`Alt + P`), useful for temporarily disabling all automatic connections
    - Transformers are only 98% efficient (this can be changed in settings)
- New 4th tier power pole with very long range, high maximum power consumption, but no supply area
- High energy interface that only provides electricity on one side for supplying any (primarily modded) buildings with very high power requirements
- Four tiers of fuses which have a lower max consumption than the corresponding electric pole and are more likely to explode when overloaded
- Each type of pole has a fully configurable maximum power consumption
- Modes of destruction:
    - Destroy _(default)_: Poles are destroyed (each pole checked on average every 5 seconds)
    - Damage: Poles are damaged (each pole receives damage of `(consumption / max_consumption - 0.95) * 10` applied on average once a second)
    - Catch fire: Poles catch fire, damaging surrounding entities (each pole is set on fire if `consumption / max_consumption + 0.01) * math.random() > 1` applied on average every 10 seconds)
    - Nothing: Nothing happens. Use temporarily when adding the mod to an existing save so that the necessary adjustments can be made first.

## Line losses (optional)
Off by default: enable "Line losses" in the map settings. Transformers then lose extra energy depending on how far their power has to travel to reach its consumers.
- Distance is measured along the copper wires and weighted by pole type. Each pole's line resistance comes from its maximum consumption setting, `r = sqrt(P_big / P_pole)`: small 5.5×, medium 2.2×, substation 1.5×, big 1×, huge 0.32× per tile. Fuses count as their pole
- Each wire costs `length × (r_A + r_B) / 2`. For every transformer, the cheapest wire route to each consumer of its output network gives the distance `D`
- `D` is weighted by load: downstream transformers count by the power they actually draw, and the rest of the network's consumption (machines) is spread over its poles
- The transformer's efficiency becomes `efficiency × (1 − loss per tile × D)`, with the loss capped at 75%. "Line loss per tile (%)" defaults to 0.01, so `D = 100` loses 1%
- Each transformer applies its own loss to the energy it actually moves, so a network fed by several transformers loses in proportion to how much power each delivers and over how far
- Hovering a transformer shows the line loss of the power arriving at it (green below 10%, yellow below 50%, red above); the transformer window also shows the distance
- To lose less: use big or huge poles for long runs, place transformers close to what they power, and keep distribution networks compact
- Performance: distances are computed in the background, at most 100 poles per tick across all transformers, and refreshed as you build. Per tick, each transformer only adds a couple of arithmetic operations

### Grid diagram
A map overlay of the transformer grid, toggled per player with the "Toggle grid diagram" shortcut (off by default; a hotkey can be set in Controls). Requires line losses to be enabled.
- One line from each transformer to each transformer it feeds, with a dot at the receiving end
- Width shows the power on that route; colour shows its line loss (green below 10%, yellow below 50%, red above, grey when idle); a label shows both, e.g. `1.0MW · 0.4%`
- Only drawn in map view, only for players who switched it on, and updated once a second

## Tips
- You'll want to have a central 'spine' of higher tier poles. Use transformers to branch off it into subnetworks containing lower tier poles
- Don't forget the vanilla methods of removing wires:
    - `Shift + Click` on a power pole to remove all wires
    - 'Connect' two connected poles with copper cable to disconnect them
- Useful mods:
    - [Wire Shortcut X](https://mods.factorio.com/mod/WireShortcutX) for easier connecting and disconnecting of wires
    - [Rate Calculator](https://mods.factorio.com/mod/RateCalculator) for ensuring that a subnetworks' power requirements are not too large

## Compatibility
- Poles from the following mods are supported:
    - [AAI Industry](https://mods.factorio.com/mod/aai-industry)
    - [Space Exploration](https://mods.factorio.com/mod/space-exploration)
    - [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)
    - [Industrial Revolution 2/3](https://mods.factorio.com/mod/IndustrialRevolution3)
    - [Bob's Power](https://mods.factorio.com/mod/bobpower)
    - [Bio Industries](https://mods.factorio.com/mod/Bio_Industries)
    - [Cargo Ships](https://mods.factorio.com/mod/cargo-ships)
    - [Advanced Electric](https://mods.factorio.com/mod/Advanced_Electric)
    - [Advanced Substation](https://mods.factorio.com/mod/AdvancedSubstation)
    - [Omnienergy](https://mods.factorio.com/mod/omnimatter_energy)
    - [FactorioExtended Plus-Power](https://mods.factorio.com/mod/FactorioExtended-Plus-Power)
    - [Factorio Plus Plus](https://mods.factorio.com/mod/fpp)
    - [Large Electric Pole](https://mods.factorio.com/mod/fixLargeElectricPole)
    - [Lighted Electric Poles +](https://mods.factorio.com/mod/LightedPolesPlus)
    - [Pyanodons Alternative Energy](https://mods.factorio.com/mod/pyalternativeenergy) (also adds a Nexelit fuse)
- When the following mods are loaded, the default maximum consumptions are increased:
    - [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)
    - [Pyanodons Coal Processing](https://mods.factorio.com/mod/pycoalprocessing)
- Most recipes are generated dynamically and so should be balanced no matter which mod is installed
- Angel's and 248k do not add any extra power poles, so should work. Nullius and 5Dim's are not supported
- If you would like support for a particular mod, let me know. Since I haven't played many other mods, balance suggestions would be helpful

## For modders
Other mods can register electric poles for Power Overload to manage without needing direct compatibility changes here. Add an optional dependency on Power Overload, then register poles during `settings.lua` or `settings-updates.lua`:

```lua
if mods["PowerOverload"] then
  require("__PowerOverload__/registry")

  PowerOverload.register_pole{
    name = "my-electric-pole",
    default = "4GW"
  }
end
```

Power Overload will create a startup setting named `power-overload-max-power-my-electric-pole` and use that setting for tooltips and runtime overload handling if the prototype exists.

## Performance
At the current level of optimisation, you should expect to be able to maintain 60UPS well into the hundreds of science-per-minute.
As such, it works particularly well with smaller overhaul mods like Krastorio 2 and Industrial Revolution 2. Late-game Space Exploration or Pyanodons will likely run into UPS issues, although I do have future plans for further optimisation.

## Graphics
Thanks to busdriver4 for creating the amazing fuse and transformer graphics!

---

You can help by translating this mod into your language using [CrowdIn](https://crowdin.com/project/factorio-mods-localization). Any translations made will be included in the next release.
If you've been using this mod, I'd love to see some screenshots or saves from your playthrough.
If you have any bug reports, feedback, or balance suggestions, please let me know through the [Discussion page](https://mods.factorio.com/mod/PowerOverload/discussion) or by [opening an issue](https://github.com/enrik-0/PowerOverload/issues) on GitHub.
