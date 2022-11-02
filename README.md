# Power Overload

## Features
- Power poles may explode if their network's total consumption goes over the maximum consumption for that power pole type
- Separate your network into subnetworks using transformers, but ensure that each subnetwork does not get too large!
    - You will usually want your subnetworks to only contain one type of power pole, so different power pole types do not automatically connect to each other
    - Transformers only have 98% efficiency by default, but this can be changed with a mod setting
- New 4th tier power pole with very long range, high maximum power consumption, but no supply area
- High energy interface that only provide energy on one side for providing energy to (primarily modded) buildings with very high power requirements
- Four tiers of fuses which have a lower max consumption than the corresponding electric pole and are more likely to explode when overloaded
- Each type of pole has a fully configurable maximum power consumption, but I'd appreciate feedback if you think that the default values should change
- Modes of destruction:
    - Destroy _(default)_: Poles are destroyed (each pole checked on average every 5 seconds)
    - Damage: Poles are damaged (each pole receives damage of `(consumption / max_consumption - 0.95) * 10` applied on average once a second)
    - Catch fire: Poles catch fire, damaging surrounding entities (each pole is set on fire if `consumption / max_consumption + 0.01) * math.random() > 1` applied on average every 10 seconds)

## Tips
- You'll want to have a central 'spine' of higher tier poles. Use transformers to branch off it into subnetworks with lower tier poles or substations
- Don't forget the vanilla methods of removing wires:
    - `Shift + Click` on a power pole to remove all wires
    - 'Connect' two connected poles with copper cable to disconnect them
- Useful mods:
    - [Wire Shortcuts](https://mods.factorio.com/mod/WireShortcutshttps://mods.factorio.com/mod/WireShortcuts) for easier connecting and disconnecting of wires
    - [Rate Calculator](https://mods.factorio.com/mod/RateCalculator) for ensuring that a subnetworks' power requirements are not too large

## Future updates
- Allow transformer wire connections to be included in blueprints

## Compatibility
- Currently poles from the following mods are supported:
    - [AAI Industry](https://mods.factorio.com/mod/aai-industry)
    - [Space Exploration](https://mods.factorio.com/mod/space-exploration)
    - [Bob's Power](https://mods.factorio.com/mod/bobpower)
    - [Bio Industries](https://mods.factorio.com/mod/Bio_Industries)
    - [Cargo Ships](https://mods.factorio.com/mod/cargo-ships)
    - [Advanced Electric](https://mods.factorio.com/mod/Advanced_Electric)
    - [Large Electric Pole](https://mods.factorio.com/mod/fixLargeElectricPole)
    - [Krastorio2](https://mods.factorio.com/mod/Krastorio2)
    - [Industrial Revolution 2](https://mods.factorio.com/mod/IndustrialRevolution)
    - [Pyanodons Alternative Energy](https://mods.factorio.com/mod/pyalternativeenergy)
- If you would like support for a particular mod, let me know. Since I haven't played many other mods, balance suggestions would be helpful

## Graphics
The "Huge electric pole" uses the pre-0.17 "Big electric pole" graphics. The transformer, fuses, and high energy interface
are just red/blue tints of vanilla entities. If you would be interested in creating better graphics for any of these, let me know.

---

You can help by translating this mod into your language using [CrowdIn](https://crowdin.com/project/factorio-mods-localization). Any translations made will be included in the next release.
If you've been using this mod, I'd love to see some screenshots or saves from your playthrough.
If you have any bug reports, feedback, or balance suggestions, please let me know through the [Discussion page](https://mods.factorio.com/mod/PowerOverload/discussion).