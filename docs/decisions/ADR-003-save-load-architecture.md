# ADR-003 — Save / Load & Persistence Architecture

## Status
Accepted


## Date
2026-10-01

## Agent
Agent-1 (Architecture & Evaluation)

## Context
OriginalRPG requires a mechanism to serialize and restore player state, character progression, inventory, quest progress, and world state for single-player gameplay. The architecture should be robust, safe against corrupted saves, and format-agnostic so it does not impede future database or network synchronization.

## Requirements
1. Serializable representation of player character (level, stats, position, inventory, equipment, quest log).
2. Backward compatibility / schema migration capability as game systems evolve.
3. Security and corruption prevention (atomic file writing, checksum/validation).
4. Decoupling from visual scene instances (saving pure data dictionaries/structs rather than node trees).

## Options Considered

### Option A: Direct Godot Resource Saving (`ResourceSaver.save`)
- **Description:** Storing runtime state inside a custom `SaveGame` Resource object and saving to disk as `.tres` or `.res`.
- **Advantages:** Very concise code; native Godot types supported directly.
- **Disadvantages:** Security risk (loading untrusted `.tres` files can instantiate arbitrary scripts/classes); tight coupling to engine class structures makes schema migrations difficult when class members change.
- **Complexity:** Low.
- **Scalability:** Moderate.
- **Godot 4 Compatibility:** High.
- **Reversibility:** Moderate.

### Option B: Structured JSON with Schema Versioning (Recommended)
- **Description:** Components implement a standardized interface (e.g. `to_dict() -> Dictionary` and `from_dict(data: Dictionary) -> void`). State is saved as structured JSON with a `save_version` header and written atomically to `user://saves/`.
- **Advantages:** Human-readable for debugging; completely secure against script injection; straightforward schema migrations (`v1 -> v2`); directly portable to web APIs, databases, or network packets if multiplayer is introduced later.
- **Disadvantages:** Requires explicit serialization/deserialization methods on stateful components; does not automatically serialize complex engine objects (Vector2/3 must be serialized as dicts/arrays).
- **Complexity:** Low to Moderate.
- **Scalability:** High.
- **Godot 4 Compatibility:** 100% native (via `JSON` class and `FileAccess`).
- **Reversibility:** High.

### Option C: Embedded SQLite Database
- **Description:** Embedding a local SQLite database file in `user://` via a GDExtension plugin.
- **Advantages:** Relational queries; robust atomic transactions.
- **Disadvantages:** Overkill for single-player save slots; adds an external GDExtension dependency.
- **Complexity:** High.
- **Scalability:** High.
- **Godot 4 Compatibility:** Requires third-party plugin/extension.
- **Reversibility:** Difficult.

## Recommendation
**Option B: Structured JSON with Schema Versioning.**
Each stateful component (`StatsComponent`, `InventoryComponent`, `QuestManager`) provides `serialize()` and `deserialize()` dictionaries. A centralized `SaveService` coordinates writing and reading to `user://saves/<slot>.json` using safe atomic writes.

## Consequences
- Positive: Safe, version-controlled save files; painless debugging; 100% decoupled from engine node instances.
- Negative: Must write manual serializer/deserializer mappings for custom types.

## Reversibility
Easy to Moderate.
