# Ashen Covenant

A 2D pixel-art soulslike in Godot 4. Face the evil necromancer cult.

## How to Run

Open the project in **Godot 4.3+**: File → Open Project → select this folder.
Press **F5** or the Play button to run.

## Controls

| Action | Key |
|--------|-----|
| Move | WASD or Arrow Keys |
| Jump | Space / Up Arrow |
| Attack | Z |
| Special Ability | X |
| Dodge Roll | C |
| Use Flask (heal) | Q |
| Rest at Bonfire | E |

## Classes

| Class | HP | Stamina | Speed | Special |
|-------|-----|---------|-------|---------|
| **Knight** | 150 | 120 | Slow | Shield Bash – close-range stagger |
| **Pyromancer** | 100 | 100 | Medium | Fire Wave – ranged AoE blast |
| **Assassin** | 80 | 150 | Fast | Shadow Strike – teleport backstab |

## Enemies

- **Cultists** – robed melee fighters with ritual blades
- **Necromancers** – ranged casters that fire cursed bolts and summon skeletons
- **Skeletons** – fast, fragile undead raised by necromancers
- **High Priest Malachar** *(boss)* – two-phase boss fight with AoE slams, bolt bursts, and skeleton summons

## Soulslike Mechanics

- **Stamina** – depletes on attacks and dodges; regenerates after a pause
- **Dodge roll** – grants invincibility frames
- **Flask** – 3 uses per checkpoint rest; heals 40 HP
- **Souls** – dropped by enemies; lost on death; recover by reaching your death location
- **Bonfires** – rest with **E** to restore flasks and HP; enemies respawn
