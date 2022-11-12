# Power Overload

## Features
- Power poles may explode if their network's total consumption goes over the maximum consumption for that power pole type
- Separate your network into subnetworks using transformers, but ensure that each subnetwork does not get too large!
    - You will usually want your subnetworks to only contain one type of power pole, so power poles of different types no longer automatically connect to each other
    - Transformers are only 98% efficient (this can be changed in settings)
- New 4th tier power pole with very long range, high maximum power consumption, but no supply area
- High energy interface that only provides electricity on one side for supplying any (primarily modded) buildings with very high power requirements
- Four tiers of fuses which have a lower max consumption than the corresponding electric pole and are more likely to explode when overloaded
- Each type of pole has a fully configurable maximum power consumption
- Modes of destruction:
    - Destroy _(default)_: Poles are destroyed (each pole checked on average every 5 seconds)
    - Damage: Poles are damaged (each pole receives damage of `(consumption / max_consumption - 0.95) * 10` applied on average once a second)
    - Catch fire: Poles catch fire, damaging surrounding entities (each pole is set on fire if `consumption / max_consumption + 0.01) * math.random() > 1` applied on average every 10 seconds)

## Tips
- You'll want to have a central 'spine' of higher tier poles. Use transformers to branch off it into subnetworks containing lower tier poles
- Don't forget the vanilla methods of removing wires:
    - `Shift + Click` on a power pole to remove all wires
    - 'Connect' two connected poles with copper cable to disconnect them
- Useful mods:
    - [Wire Shortcuts](https://mods.factorio.com/mod/WireShortcutshttps://mods.factorio.com/mod/WireShortcuts) for easier connecting and disconnecting of wires
    - [Rate Calculator](https://mods.factorio.com/mod/RateCalculator) for ensuring that a subnetworks' power requirements are not too large

## Compatibility
- Poles from the following mods are supported:
    - [AAI Industry](https://mods.factorio.com/mod/aai-industry)
    - [Space Exploration](https://mods.factorio.com/mod/space-exploration)
    - [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)
    - [Industrial Revolution 2](https://mods.factorio.com/mod/IndustrialRevolution)
    - [Bob's Power](https://mods.factorio.com/mod/bobpower)
    - [Bio Industries](https://mods.factorio.com/mod/Bio_Industries)
    - [Cargo Ships](https://mods.factorio.com/mod/cargo-ships)
    - [Advanced Electric](https://mods.factorio.com/mod/Advanced_Electric)
    - [Large Electric Pole](https://mods.factorio.com/mod/fixLargeElectricPole)
    - [Pyanodons Alternative Energy](https://mods.factorio.com/mod/pyalternativeenergy) (also adds a Nexelit fuse)
- When the following mods are loaded, the default maximum consumptions are increased:
    - [Krastorio 2](https://mods.factorio.com/mod/Krastorio2)
    - [Pyanodons Coal Processing](https://mods.factorio.com/mod/pycoalprocessing)
- Most recipes are generated dynamically and so should be balanced no matter which mod is installed
- Angel's and 248k do not add any extra power poles, so should work. Nullius and 5Dim's are not supported
- Pyanodons compatibility is currently broken
- If you would like support for a particular mod, let me know. Since I haven't played many other mods, balance suggestions would be helpful

## Performance
At the current level of optimisation, you should expect to be able to maintain 60UPS well into the hundreds of science-per-minute.
As such, it works particularly well with smaller overhaul mods like Krastorio 2 and Industrial Revolution 2. Late-game Space Exploration will likely run into UPS issues, although I do have future plans for further optimisation.

## Graphics
Thanks to busdriver4 for creating the amazing fuse and transformer graphics!

---

You can help by translating this mod into your language using [CrowdIn](https://crowdin.com/project/factorio-mods-localization). Any translations made will be included in the next release.
If you've been using this mod, I'd love to see some screenshots or saves from your playthrough.
If you have any bug reports, feedback, or balance suggestions, please let me know through the [Discussion page](https://mods.factorio.com/mod/PowerOverload/discussion).
