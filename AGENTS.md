# AGENTS.md

Guidance for coding agents working in this Unity repo.

## Project Context

This is a Unity 2023.2.0f1 URP prototype called `Flash 3D`. The design direction is a first-person Barry Allen / Flash-inspired open-world prototype where Barry is the baseline identity and Flash mode is a power state layered on top of ordinary exploration.

Treat the project as a prototype with asset packs, unfinished systems, and local work in progress. Do not assume the project currently compiles or that every scene is playable.

## Before Editing

- Run `git status --short` and expect noise from imported assets and local Unity changes.
- Do not revert or clean unrelated changes.
- Keep edits scoped. This repo is asset-heavy, and broad operations can create massive `.meta` churn.
- Do not edit `Library/`, `Temp/`, `Logs/`, `UserSettings/`, generated `.csproj` files, or generated `.sln` files unless explicitly asked.
- Preserve `.meta` files for any Unity asset, scene, prefab, or script changes.

## Important Files

- Unity version: `ProjectSettings/ProjectVersion.txt`
- Package manifest: `Packages/manifest.json`
- Player input: `Assets/Player/Movement/PlayerControls.cs`
- Player movement: `Assets/Player/Movement/PlayerController.cs`
- Flash mode/time effects: `Assets/Player/Movement/FlashTimeController.cs`
- Alternate camera/effect controller: `Assets/Player/Movement/CameraController.cs`
- Post-processing bridge: `Assets/Scripts/PostProcessing/PostProcessingManager.cs`
- Day-night cycle: `Assets/Scripts/DayNightCycle.cs`
- Traffic scripts: `Assets/NPC/Traffic/Scripts/`
- NPC behavior scaffolding: `Assets/NPC/Behavior/`
- Main available scenes: `Assets/Scenes/DayScene.unity`, `Assets/Scenes/DayScene 1.unity`, `Assets/Scenes/SampleScene.unity`

## Current Architecture Notes

- `PlayerControls` owns key bindings and mouse sensitivity.
- `PlayerController` chooses walk/run/Flash speed, drives camera look, selects camera shake animation names, and moves the `CharacterController`.
- `FlashTimeController` owns Flash-mode state, slow motion, `Time.timeScale`, `Time.fixedDeltaTime`, FOV transitions, and chromatic aberration triggers.
- `PostProcessingManager` expects a URP `Volume` and currently looks for a scene object named `Global Volume` if one is not assigned.
- Traffic code is lane-system based: a top-level `TRAFFIC` object should have `TrafficSystem`, child `TrafficLane` objects define physical lane segments, and `CarController` asks `TrafficSystem` for next lanes, adjacent lanes, blocker checks, and intersection flow. Traffic obstacle detection is opt-in through the reusable `TrafficObstacle` trait, plus other traffic cars.
- NPC behavior code is early scaffolding. Several classes still throw `NotImplementedException`.

## Gameplay Philosophy

The preferred gameplay architecture is composable behavior traits. A trait is a small component that gives an object one predictable behavior: breakable, flammable, movable, impact-reactive, climbable, alarm-triggering, destructible glass, and so on.

Favor this style over one-off object scripts. For example, a breakable trait should define what happens when enough force hits an object. That same trait can later be applied to glass, props, street objects, SWAT enemies, or anything else that should react consistently to Flash-speed impacts.

The player should be able to learn these traits and expect them across the world. If glass breaks from a high-speed collision in one place, similar glass should break elsewhere unless there is an explicit reason it does not. This matters especially because the player is the Flash and can hit the world with extreme speed.

Do not confuse composable traits with splitting one system into many files. A component should only become a separate trait when it can sensibly be applied to different kinds of objects. A car motor that only makes sense inside a car is not a gameplay trait and should usually stay inside the car controller. For traffic specifically, the current blocker behavior is an intentional opt-in trait: only objects with `TrafficObstacle`, plus other traffic cars, should make traffic brake or avoid.

When adding gameplay:

- Prefer reusable components with clear thresholds, inputs, and inspector-tunable responses.
- Keep traits independent where possible, so designers can stack them on the same object.
- Put shared event/input concepts, such as impact data, damage data, or interaction data, in small neutral types instead of coupling them to one object.
- Avoid hardcoding behavior into a specific prefab or scene object when the same behavior could become a reusable trait.
- Make the behavior legible from the player's perspective. Consistency is more important than simulation complexity.

## Communication Style For This Project

Explain plans and architecture from the gameplay perspective first. Start with what the player, car, NPC, prop, or world object will do in-game, then explain the code shape only as much as needed.

Keep explanations short and concrete. Prefer a compact explanation over a broad architecture essay. When naming files or components, briefly say what each one does in gameplay terms.

Do not present a list of files as if that explains the design. The user needs to understand the gameplay behavior and authoring workflow before code structure details.

When suggesting architecture, avoid over-splitting. Explain why a component deserves to exist as a standalone reusable gameplay trait. If it only supports one specific system internally, keep it inside that system.

## Coding Conventions

- Use C# and Unity `MonoBehaviour` patterns already present in the repo.
- Prefer inspector-exposed serialized fields for gameplay tuning.
- Avoid renaming public serialized fields without a migration plan because scenes and prefabs may depend on them.
- Keep gameplay code readable and direct. This is a prototype, so avoid heavy abstractions unless they remove real duplication.
- Use `Time.unscaledDeltaTime` for visual transitions that should keep running during slow motion.
- Be careful with `Time.timeScale`; always restore normal scale when leaving Flash mode or disabling related components.

## Testing and Verification

There is no dedicated automated test suite in the repo. For code changes:

- Prefer opening the project in Unity 2023.2.0f1 and checking the Console.
- Enter Play Mode in a known scene, usually `DayScene.unity` or `SampleScene.unity`.
- Verify player movement, Flash mode, slow motion, and post-processing behavior when touching player systems.
- Verify traffic prefabs, tags, road layers, obstacle layers, colliders, and gizmos when touching traffic.
- Do not use `dotnet build`, `dotnet test`, or other standalone .NET compile checks for this Unity project. The generated `.csproj` files can be stale until Unity regenerates them, so these checks create misleading failures.
- If Unity is unavailable, at least inspect scripts for compile errors and report that Play Mode was not run.

## Scene and Build Settings Caveat

`ProjectSettings/EditorBuildSettings.asset` currently references `Assets/Scenes/The_Viking_Village.unity`, which is not present in the current tree. Do not treat build settings as authoritative until they are cleaned up in Unity.

## Asset Handling

Imported packages under `Assets/Packages/` are large and should be treated as vendor/content assets. Avoid reformatting, moving, or bulk editing them. If a gameplay script lives inside an imported package, prefer wrapping or calling it from project-owned code before modifying vendor files.
