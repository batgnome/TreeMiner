# TreeMiner: Cooling Station

An early playable graybox for a squirrel action-platformer inside an industrialized living tree. Built with Godot **4.6.3**, GDScript, and the Compatibility renderer. Placeholder shapes intentionally leave character modeling and art to you.

## Play on Windows

1. Install Godot 4.6.3 standard (no .NET required).
2. Copy or clone this project onto your PC.
3. In Godot's Project Manager, import `project.godot`.
4. Press **F6** with `main.tscn` open, or **F5** to run the project.

| Control | Action |
| --- | --- |
| WASD | Camera-relative movement |
| Mouse | Rotate camera |
| Space | Jump; release early for a shorter jump |
| Left mouse | Katana swing |
| Right mouse | Short-range cryo pulse in facing direction |
| E | Pick up / release nearby crate |
| T | Reset crate if lost |
| R | Restart entire room, including enemy and puzzle |
| Escape | Release mouse; click to capture again |

The player is the brown capsule. The metallic bar indicates the sword and facing direction.

## Factory loop

Push or carry the tan crate against the orange balcony. Jump onto the crate, then onto the balcony. The balcony is too tall for a normal floor jump. Face the cyan rotor and use cryo from nearby: the blue gate opens for ten seconds. Cross it, then return through the permanently opened gold shortcut to finish. Fight the red miner along the way; its squash pose telegraphs an attack, followed by a recovery window. Three sword hits defeat it. Its defeat is optional for opening the gate.

Ordinary sword attacks cost no energy. Cryo costs 35, draws from regenerating energy first, then gems. Regeneration resumes after 1.5 seconds. There are no gem pickups yet; required puzzles remain solvable after gems run out. Cryo also freezes the miner for three seconds. Cryo is currently an immediate targeted pulse, not a simulated projectile.

## Code map

- `scripts/player.gd`: character physics, jump buffering/coyote time, camera spring arm, input, health, energy, sword visualization.
- `scripts/world.gd`: graybox construction, crate, enemy state machine, cryo interaction, gate, shortcut, HUD.
- `scenes/main.tscn`: entry scene; geometry is built by `world.gd` at runtime.
- `tests/smoke.gd`: headless integration checks.

Movement tuning starts with exported `speed`, `acceleration`, `jump_speed`, and `gravity` values in `player.gd`. The character is spawned in code; edit those defaults initially. As the prototype grows, extract the player, crate, and enemy into their own editable scenes.

## Validation

Run from the project directory:

```
godot --headless --path . --script res://tests/smoke.gd
```

The suite exercises floor contact, movement/jump/landing, resource spending/regeneration, crate interaction, cryo gate/thaw, enemy defeat, shortcut and completion. It moves actors directly for isolated encounter checks; it does not prove a human can complete the route or judge movement feel.

For restricted cloud machines, set `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `XDG_CACHE_HOME` to writable directories before invoking Godot. No packages or external assets are required. Use the existing checkout; cloud tasks are already isolated and do not need extra Git worktrees.

## Next hands-on check

Run the room on your home PC. Check jump reach, camera behavior near walls, crate placement, enemy attack readability, and the full route without repositioning actors. Tune movement before adding features.

This is a first prototype, not a finished demo. It has no squirrel model, custom animations/audio, dodge, saving, gamepad support, fixed-camera/2D sections, or other world zones. Combat applies one hit per input swing immediately; animation-timed hit windows and more expressive sword feedback are next combat work. Environment art, accessibility and performance need local review.
