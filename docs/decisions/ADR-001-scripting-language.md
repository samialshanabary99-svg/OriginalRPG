# ADR-001 — Primary Scripting Language Selection (GDScript vs C#)

## Status
Accepted


## Date
2026-10-01

## Agent
Agent-1 (Architecture & Evaluation)

## Context
OriginalRPG requires a primary programming language for gameplay logic, systems architecture, UI, and data handling within Godot 4.
The engine supports GDScript natively and C# via the .NET build. Currently, the local environment has Godot 4.7.2 standard installed, and no .NET SDK is installed on the host machine.

## Requirements
1. Seamless integration with Godot 4 scene tree, signals, resources, and editor tools.
2. Low cognitive overhead and clean readability for multi-agent AI pair-programming.
3. Rapid iteration without compilation delays or external toolchain dependencies.
4. Minimal environment friction across different machines/agents.
5. Sufficient performance for 2D/isometric RPG calculations (combat math, pathfinding, inventory operations).

## Options Considered

### Option A: GDScript (Godot Native, Statically Typed)
- **Advantages:** Built directly into Godot; runs out of the box with zero external dependencies (no .NET SDK required); first-class engine signal/resource serialization support; high AI generation reliability; fast hot-reloading.
- **Disadvantages:** Slower execution speed compared to compiled C# for heavy numeric crunching (e.g. thousands of concurrent complex entity simulations without engine-level C++ support).
- **Complexity:** Low.
- **Scalability:** High for standard single-player and moderate-scale RPG logic when utilizing typed GDScript (`:=`, static types).
- **Godot 4 Compatibility:** 100% native.
- **Reversibility:** Moderate (re-writing game logic to C# requires refactoring, though architecture can isolate core models).

### Option B: C# (.NET)
- **Advantages:** High raw execution performance; strong enterprise typing; rich NuGet ecosystem; easy sharing of data contracts if an external C# dedicated server is ever built.
- **Disadvantages:** Requires .NET 8/9 SDK (currently not installed on this system); requires the Godot .NET build (currently standard binary installed); slower build/compile cycle; potential cross-platform export friction.
- **Complexity:** Moderate to High.
- **Scalability:** Very high for heavy algorithmic computation.
- **Godot 4 Compatibility:** Supported via dedicated .NET build, but requires extra tooling and compilation steps.
- **Reversibility:** Moderate to Difficult.

### Option C: GDExtension (C++ / Rust)
- **Advantages:** Native machine speed; maximum optimization.
- **Disadvantages:** Heavy build toolchains; slow iteration; massive overhead for general RPG gameplay rules.
- **Complexity:** Very High.
- **Reversibility:** Difficult.

## Recommendation
**Option A: GDScript with strict static typing.**
Given that Godot standard 4.7.2 is already operational, no .NET SDK is installed, and GDScript offers seamless zero-friction serialization and AI tooling support, GDScript is the recommended primary language. If extreme performance bottlenecks arise in specific algorithms later, they can be isolated to GDExtension or C#.

## Consequences
- Positive: Immediate productivity, zero toolchain friction, full engine serialization compatibility, readable and clean AI diffs.
- Negative: Requires adhering to strict typed GDScript practices to maintain large codebase maintainability.
- Trade-offs: Sacrifices third-party NuGet library access in favor of native Godot integration.

## Reversibility
Moderate. Keeping game logic decoupled from scene trees ensures data structures can be ported if ever required.

## Related Systems
All gameplay scripts, data models, and UI.

## Follow-up
Await user approval before writing gameplay scripts in GDScript.
