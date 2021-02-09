# Power Overload

## Features
- Power poles may explode if their network's total consumption goes over the maximum consumption for that power pole type
- Separate your network into subnetworks using transformers, but ensure that each subnetwork does not get too large!
- You will usually want your subnetworks to only contain one type of power pole, so different power pole types do not automatically connect to each other
- New 4th tier power pole with very long range, high maximum power consumption, but no supply area
- Each type of pole has a fully configurable maximum power consumption, but I'd appreciate feedback if you think that the default values should change
- Option to have overloading a power pole damage it instead of instantly destroying it (current formula: `damage = (consumption / max_consumption - 0.95) * 10` applied on average once a second)

## Tips
- You'll want to have a central 'spine' of higher tier poles. Use transformers to branch off it into subnetworks with lower tier poles or substations
- Don't forget the vanilla methods of removing wires:
    - `Shift + Click` on a power pole to remove all wires
    - 'Connect' two connected poles with copper cable to disconnect them
- Useful mods:
    - [Wire Shortcuts](https://mods.factorio.com/mod/WireShortcutshttps://mods.factorio.com/mod/WireShortcuts) for easier connecting and disconnecting of wires
    - [Rate Calculator](https://mods.factorio.com/mod/RateCalculator) for ensuring that subnetworks' power requirements are not too large

## Future updates
- Allow transformer wire connections to be included in blueprints
- Fuses to prevent power pole losses

## Compatibility
- Currently pole from the following mods are supported:
    - [AAI Industry](https://mods.factorio.com/mod/aai-industry)
    - [Bob's Power](https://mods.factorio.com/mod/bobpower)
    - [Cargo Ships](https://mods.factorio.com/mod/cargo-ships)
- If you would like support for a particular mod, let me know. Since I haven't played many other mods, balance suggestions would be helpful

## Graphics
The tier 4 power pole uses the pre-0.17 "Big electric pole" graphics and the transformer uses the current power switch graphics. If you would be interested in creating better graphics for either of these, let me know.

---

If you've been using this mod, I'd love to see some screenshots or saves from your playthrough.
If you have any bug reports, feedback, or balance suggestions, please let me know through the mod portal's "Discussion" page.