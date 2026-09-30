# Roadmap

This roadmap is intentionally high level. Agents should create concrete tasks before implementation.

## Phase 0 — Foundation
- [x] Repository structure & documentation hierarchy
- [x] AI memory protocol & governance files
- [x] Godot 4 project foundation (`project.godot` initialization)
- [x] Core directory structure (`src/`, `scenes/`, `assets/`, `tests/`)
- [x] Git repository initialization & `.gitignore`
- [ ] Scripting language decision (GDScript vs C# ADR)
- [ ] Development/testing conventions




## Phase 1 — Core Prototype
- Player character
- Movement
- Camera
- Basic world/map
- Basic interaction
- Basic UI

## Phase 2 — RPG Systems
- Stats
- Combat
- Skills
- Items
- Inventory
- Equipment
- Enemies
- NPCs
- Quests
- Progression

## Phase 3 — Content
- Maps
- Towns
- Dungeons
- Monsters
- Bosses
- Characters
- Story
- Audio
- Effects

## Phase 4 — Persistence
- Save/load
- Character persistence
- Configuration
- Data validation

## Phase 5 — Multiplayer Research
Only after the single-player architecture provides enough evidence to choose an appropriate multiplayer architecture.

Every major transition should be documented through ADRs.
