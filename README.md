# Godot 4 - Basic First Person Controller
This project contains the basic implementation of a First Person character controller for the [Godot 4 [Beta 17]](https://downloads.tuxfamily.org/godotengine/4.0/beta17/).

The code found in [player.gd](Player/player.gd) uses vector forces to move the player. You can tweak the values of the forces in the editor directly. The _velocity_ of the player is calculated as a result of the vector sum of different vector forces: walk, jump and gravity.

The main scene is a _Sandbox_ scene used to test the controls:

![EditorView](Assets/BasicFPCBeta17.png)

## Controls
| Keys | Action Name | Description |
|:------:|:-------------:|:-------------:|
| `W`, <kbd>left stick up</kbd> | `move_forward` | Move forward |
| `S`, <kbd>left stick down</kbd> | `move_backwards` | Move backwards |
| `A`, <kbd>left stick left</kbd> | `move_left` | Move to the left |
| `D`, <kbd>left stick right</kbd>| `move_right` | Move to the right |
| `mouse`, <kbd>right stick</kbd> | `look_` + _dir_ | Look/Aim |
| `Space`, <kbd>Xbox Ⓐ</kbd> | `jump` | Apply jump force |
| `Esc`, <kbd>Xbox Ⓑ</kbd> | `exit` | Close the game |

You can change any of this keys in: Project Settings → Input Map.
