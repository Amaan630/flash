# Flash 3D

Flash 3D is an early Unity prototype for a first-person open-world game inspired by Barry Allen and The Flash. The design intent is not a pure superhero combat game. The center of gravity is Barry Allen as the primary playable identity, with Flash powers treated as a special open-world state layered onto normal first-person exploration.

The repo is currently closer to a systems sandbox than a complete game. It contains first-person movement, Flash-mode movement/time effects, city/world assets, day-night support, early traffic simulation, and initial NPC behavior scaffolding.

## Project Status

This project was made as a learning project and has several unfinished or experimental systems. Expect placeholder scenes, incomplete behavior code, and imported asset packages.

Current core ideas present in the repo:

- First-person player controller with walk, run, mouse look, and camera shake states.
- Flash mode that increases movement speed, changes FOV, adjusts time scale, and drives chromatic aberration.
- Slow-motion behavior when Flash mode is held while standing still, or when the slow-motion input is also held.
- URP post-processing setup through a `PostProcessingManager`.
- Day-night rotation script for world lighting.
- Early traffic simulation with cars, lane segments, inferred intersections, lane changes, and opt-in traffic obstacles.
- Early NPC behavior tree and personality scaffolding for civilian routines and reactions.

## Unity Version

Open with:

```text
Unity 2023.2.0f1
```

The version is recorded in `ProjectSettings/ProjectVersion.txt`.

## Main Scenes

The scenes currently present are:

- `Assets/Scenes/DayScene.unity`
- `Assets/Scenes/DayScene 1.unity`
- `Assets/Scenes/SampleScene.unity`

`ProjectSettings/EditorBuildSettings.asset` currently references `Assets/Scenes/The_Viking_Village.unity`, but that scene is not present in the current file tree. Open one of the scenes above directly from the Unity Editor.

## Controls

Default controls are defined in `Assets/Player/Movement/PlayerControls.cs`.

| Action | Key |
| --- | --- |
| Move forward | `W` |
| Move backward | `S` |
| Strafe left | `A` |
| Strafe right | `D` |
| Run | `Left Control` |
| Flash mode | `Left Shift` |
| Slow motion while in Flash mode | `Space` |
| Mouse look | Mouse movement |

In the editor, `F` toggles the focused Unity editor window maximized while play mode is running.

## Key Project Areas

### Player

Located under `Assets/Player/`.

- `Movement/PlayerControls.cs` centralizes keyboard and mouse input.
- `Movement/PlayerController.cs` handles first-person look, movement speed selection, camera shake animation selection, Flash-mode input routing, and `CharacterController` movement.
- `Movement/FlashTimeController.cs` manages Flash mode, slow motion, time scale, FOV, and post-processing intensity triggers.
- `Movement/CameraController.cs` appears to be an alternate or earlier camera/Flash effect controller. Check scene and prefab wiring before changing it.
- `Prefabs/Player.prefab` is the main player prefab.
- `Prefabs/PostProcessingManager.prefab` supports Flash-mode visual effects.

### Post Processing

Located under `Assets/Scripts/PostProcessing/`.

- `PostProcessingManager.cs` expects a URP `Volume`, defaults to finding a scene object named `Global Volume`, and drives chromatic aberration between normal and Flash-mode values.

### World Time

Located under `Assets/Scripts/`.

- `DayNightCycle.cs` rotates a light over a configurable 24-hour game day.

### Traffic

Located under `Assets/NPC/Traffic/`.

- `Scripts/TrafficSystem.cs` belongs on the top-level `TRAFFIC` object. It scans child lanes and auto-builds lane connections, adjacent-lane checks, and simple intersection flow.
- `Scripts/TrafficLane.cs` defines one physical lane segment from the end of one intersection to the start of another. Its gizmos draw the centerline and lane width.
- `Scripts/CarController.cs` drives cars on the lane system, using mph speed, smooth lane transitions, blocker detection, lane changes, and traffic-system intersection permission.
- `Scripts/TrafficObstacle.cs` is an opt-in trait for objects traffic should avoid. Add it to the player for now; unmarked street lights, curbs, road meshes, and scenery will not make cars brake.

### NPC Behavior

Located under `Assets/NPC/Behavior/`.

This is early scaffolding for civilians and routine/reactive behavior. Several classes still throw `NotImplementedException`, especially leisure activities and abstract behavior implementations.

Notable files:

- `BehaviorTree/NPCController.cs`
- `BehaviorTree/BehaviorManager.cs`
- `BehaviorTree/ScheduleManager.cs`
- `BehaviorTree/RoutineBehaviors/Work/WorkBehavior.cs`
- `BehaviorTree/ReactiveBehaviors/FightReaction.cs`
- `Personality/PersonalityTraits.cs`

## Asset Packages

The project includes a large set of imported visual/environment packages under `Assets/Packages/`, including city, sky, weather, fog, water, volume profile, and lighting assets. There is also a large `WeatheradeDemoContent.unitypackage` at the repo root.

Because this is a Unity asset-heavy repo, avoid broad file moves or asset renames unless Unity is open and `.meta` files are preserved.

## Known Caveats

- The git worktree may already contain unrelated local changes. Check `git status` before editing.
- Some NPC behavior classes are stubs and may throw at runtime if invoked.
- `EditorBuildSettings.asset` references a missing scene.
- The generated `.csproj` and `.sln` files are Unity-generated and may change when the project opens.
- Large imported packages make status output noisy.
- There are Mono crash logs in the root from a previous Unity session.

## Development Notes

- Keep gameplay code under `Assets/Player`, `Assets/NPC`, or `Assets/Scripts` unless a new system clearly deserves its own folder.
- Prefer small, inspector-friendly `MonoBehaviour` components over large manager classes.
- Preserve Unity `.meta` files when adding, moving, or deleting assets.
- If changing serialized fields, consider existing prefab and scene references before renaming fields.
- When working on Flash-mode feel, tune `FlashTimeController` first before adding new effects.
