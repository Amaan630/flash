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
- Traffic code is in progress. `RoadManager`, `RoadSegment`, `IntersectionController`, and `CarController` are intended to cooperate through tags, colliders, waypoints, and layer masks.
- NPC behavior code is early scaffolding. Several classes still throw `NotImplementedException`.

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
- If Unity is unavailable, at least inspect scripts for compile errors and report that Play Mode was not run.

## Scene and Build Settings Caveat

`ProjectSettings/EditorBuildSettings.asset` currently references `Assets/Scenes/The_Viking_Village.unity`, which is not present in the current tree. Do not treat build settings as authoritative until they are cleaned up in Unity.

## Asset Handling

Imported packages under `Assets/Packages/` are large and should be treated as vendor/content assets. Avoid reformatting, moving, or bulk editing them. If a gameplay script lives inside an imported package, prefer wrapping or calling it from project-owned code before modifying vendor files.

