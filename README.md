# grappler

a 3D game of a player swinging through a cavern with a grappling hook, using physics and momentum to climb to the escape portal and progress to the next level but if you fall you fall back to level 1. how far can you go?

play here!: https://evmaagca.itch.io/grappler

https://github.com/user-attachments/assets/820850b4-ab4b-4f02-a7e9-abfeb18ca12b

A first-person 3D grappling game made with Godot and GDScript (my third ever game)! I created grappler using Godot's scene system, GDScript, and godot resource files. The game features 20 handcrafted levels where players use a grappling hook to climb higher, overcome obstacles, and reach the summit. I developed the player movement, grappling hook mechanics, level progression, upgrade system, UI, achievement system, and game management using Godot's scripting and scene systems. The grappling hook features a charge and release mechanic, allowing players to control their launches and build momentum while navigating each level. I also implemented separate scripts and systems for features such as the player, grappling hook, HUD, levels, achievements, upgrades, and game management. I used signals to communicate between different parts of the game, including interactions, achievement unlocks, and other gameplay events. The game also includes upgrade chests, customizable grappling improvements, a height and level tracking system, a pause menu, volume controls, and a run summary that tracks your progress. I designed the game to support both desktop and mobile devices, including touchscreen controls for mobile players. I'm super excited for people to play grappler, and I hope you enjoy it!

p.s. the game works on mobile too, so feel free to try it out!

# features
- 20 levels
- charge and release grappling hook mechanics
- grappling upgrades and upgrade chests
- multiple upgrade types
- height and level progression tracking
- achievement and unlock system
- custom HUD and menus
- pause menu with volume controls
- run summaries and personal best tracking
- custom sound effects and music
- animated portal transitions
- custom victory sequence
- desktop and mobile support
- on screen touchscreen controls
- titlescreen with controls and run stats buttons

# controls
- WASD / move
- space / jump
- e / interact with chests
- q / use grappler (hold to charge, let go to release, recommended to release just before you hit the rock as it propels you farther)
- esc / pause
- tab / achivements
  
(all have specialized buttons on mobile)

# development
1.) clone this repo
```sh
git clone https://github.com/evacoffee/grappler.git
```

2.) go on godot

3.) click import and select the project.godot file inside the downloaded project
