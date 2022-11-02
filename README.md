# Godot 4 - Basic First Person Controller
This project contains the basic implementation of a First Person character controller for the Godot 4 [Beta 4].

The code found in [player.gd](Player/player.gd) uses vector forces to move the player. You can tweak the values of the forces in the editor directly. The _velocity_ of the player is calculated as a result of the vector sum of different vector forces: walk, jump and gravity.

The main scene is a _Sandbox_ scene used to test the controls:

![EditorView](Assets/Godot4Beta3FPC.png)

## Controls
<center>

| Keys | Action Name | Description |
|:------:|:-------------:|:-------------:|
| `W` | `move_forward` | Move forward |
| `S` | `move_backward` | Move backwards |
| `A` | `move_left` | Move to the left |
| `D` | `move_right` | Move to the right |
| `Space` | `jump` | Apply jump force |
| `Esc` | `exit` | Closes the game |

</center>

You can change any of this keys in the Project Settings -> Input Map.

## Known issues
- Gravity is not an acceleration force
- Godot is not ignoring the warning in the _capture_mouse()_ function