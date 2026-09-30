# OriginalRPG — AI Development & Project Memory Protocol

> **Project type:** Original RPG inspired by the broad design space of classic online RPGs such as Ragnarok Online  
> **Engine:** Godot 4  
> **Development model:** AI-first, human-supervised, one AI agent active at a time  
> **Initial mode:** Single-player  
> **Future direction:** Multiplayer is possible, but networking architecture is intentionally undecided

## 1. Purpose of This Repository

This repository is designed to allow different AI coding agents to work on the same RPG project at different times without losing project knowledge.

The repository itself is the project's persistent memory.

A new AI agent must be able to answer:

1. What is this game?
2. What has already been built?
3. What is currently being worked on?
4. What decisions have been made?
5. Why were those decisions made?
6. What files and systems changed?
7. What was added?
8. What was modified?
9. What was deleted, and why?
10. What remains unfinished?
11. What dependencies exist between systems?
12. What should the next agent do?

**Do not rely on conversation history as project memory. If important knowledge is not in the repository, future agents may not know it.**

---

# 2. Core Agent Rule

Every AI agent working on this project must follow this cycle:

```text
READ
  ↓
AUDIT
  ↓
PLAN
  ↓
IMPLEMENT
  ↓
TEST
  ↓
DOCUMENT
  ↓
VERIFY
  ↓
HANDOFF
```

An agent must not begin substantial implementation before reading the project memory files and inspecting the relevant existing code.

---

# 3. Current Technology Decisions

Some technical choices are deliberately undecided.

| Area | Current decision | Status |
|---|---|---|
| Engine | Godot 4 | Confirmed |
| Initial game mode | Single-player | Confirmed |
| Future multiplayer | Possible | Undecided architecture |
| Programming language | Agent decision | Undecided |
| Game architecture | Agent decision | Undecided |
| Backend language | Agent decision | Undecided |
| Database | Agent decision | Undecided |
| Networking | Agent decision | Undecided |
| Version control strategy | Git recommended | To be formalized |
| AI agents | Multiple AI tools | Confirmed |
| Concurrent agents | One active agent at a time | Confirmed |
| Art pipeline | AI + manual, primarily AI | Confirmed |
| Asset manifest | Required | Confirmed |

### Important

**Do not make a major technical choice simply because it is convenient for the current task.**

For example, an agent should not introduce a server, database, networking library, or programming language merely because it is familiar with it.

Major choices must be documented as an Architecture Decision Record in:

```text
docs/decisions/
```

---

# 4. Repository Memory System

The following files form the project's persistent AI memory.

```text
README.md
AI_CONTEXT.md
PROJECT_STATUS.md
ARCHITECTURE.md
ROADMAP.md

docs/
├── agents/
│   ├── AGENT_PROTOCOL.md
│   └── AGENT_ROLES.md
│
├── decisions/
│   └── ADR-TEMPLATE.md
│
├── tasks/
│   ├── TODO.md
│   ├── IN_PROGRESS.md
│   └── COMPLETED.md
│
├── changelog/
│   └── CHANGELOG_TEMPLATE.md
│
└── assets/
    └── ASSET_MANIFEST.md
```

These files have different purposes.

### README.md
The operating manual for the entire project.

### AI_CONTEXT.md
The compact context an AI agent should read first.

### PROJECT_STATUS.md
The current state of implementation.

### ARCHITECTURE.md
The current technical architecture.

### ROADMAP.md
Long-term development direction.

### Agent Protocol
Rules that every AI agent must follow.

### ADRs
Permanent records explaining important technical decisions.

### Tasks
Current, completed, and future work.

### Changelog
Historical record of changes made by agents.

### Asset Manifest
Persistent knowledge about game assets.

---

# 5. New Agent Startup Procedure

Every new AI agent must perform the following before modifying the project.

## Step 1 — Read project memory

Read:

```text
README.md
AI_CONTEXT.md
PROJECT_STATUS.md
ARCHITECTURE.md
ROADMAP.md
docs/agents/AGENT_PROTOCOL.md
```

Then inspect the relevant task and system documentation.

## Step 2 — Inspect repository state

Determine:

- current branch
- recent commits
- modified files
- untracked files
- project structure
- relevant scripts/scenes/resources
- existing tests
- unfinished work

Do not assume that documentation is perfectly synchronized with the code.

## Step 3 — Compare documentation with reality

If documentation says a feature exists, verify that the relevant implementation exists.

If code contains an important feature that documentation does not mention, document it before or during the current task.

## Step 4 — Check previous agent changes

Read recent changelog entries and relevant Git history.

Identify:

- additions
- modifications
- deletions
- architecture changes
- known problems
- unfinished work

## Step 5 — Select one task

Because only one AI agent works at a time, the agent should claim a clearly defined task in:

```text
docs/tasks/IN_PROGRESS.md
```

Do not silently work on unrelated features.

---

# 6. Agent Work Boundaries

An agent may:

- inspect the whole repository
- modify files required by its task
- create new files
- refactor code when necessary
- fix directly related bugs
- create tests
- update documentation
- update the asset manifest
- update project memory
- create ADRs for required architectural decisions

An agent should avoid:

- unrelated refactoring
- unnecessary rewrites
- changing established architecture without documenting it
- deleting working systems merely to simplify implementation
- introducing external dependencies without documenting them
- changing public interfaces without checking dependants

---

# 7. Addition / Modification / Deletion Tracking

Every completed agent task must produce a change record.

Use:

```text
docs/changelog/YYYY-MM-DD-<agent-or-task>.md
```

Each record must contain:

```yaml
agent:
date:
task:
status:

summary:

added:
  - path

modified:
  - path

deleted:
  - path

renamed:
  - old_path -> new_path

architecture_changes:
  - none

dependencies:
  - none

tests:
  - none

known_issues:
  - none

next_agent:
```

### Why this matters

The changelog is not just a human history.

It is an **AI-readable delta system**.

A future agent can determine:

```text
Previous state
      +
Change records
      +
Current repository
      =
Current project state
```

---

# 8. Deletion Protocol

Deletion requires more care than addition.

Before deleting a file, an agent must determine:

1. Why is it obsolete?
2. Is it referenced anywhere?
3. Is another system depending on it?
4. Is it replaced by something else?
5. Does the deletion affect assets, scenes, scripts, resources, tests, or documentation?
6. Can Git recover the old version?

Document significant deletions in the changelog.

Example:

```yaml
deleted:
  - src/combat/OldDamageSystem.gd

reason:
  Replaced by the new modular DamageService.

replacement:
  src/combat/DamageService.gd

dependants_checked:
  - PlayerCombat
  - EnemyCombat
  - CombatTests
```

Never silently delete an important system.

---

# 9. Rename / Move Protocol

A rename is not the same as a deletion.

Record:

```yaml
renamed:
  - src/player/old_name.gd -> src/player/new_name.gd
```

Also verify:

- script references
- scene references
- resource paths
- preload/load paths
- documentation
- tests

---

# 10. Architecture Decision Records

Major technical decisions must use an ADR.

Examples:

- choosing GDScript vs C#
- choosing a networking model
- choosing a server architecture
- choosing a database
- choosing ECS or traditional node-based architecture
- changing map architecture
- choosing an inventory architecture
- choosing persistence architecture

Use:

```text
docs/decisions/ADR-001-short-title.md
```

An ADR should contain:

```text
# ADR-XXX — Decision Title

## Status
Proposed / Accepted / Superseded / Rejected

## Context

What problem are we solving?

## Options Considered

What alternatives were considered?

## Decision

What was selected?

## Consequences

What becomes easier?

What becomes harder?

## Reversibility

Can this decision be changed later?

## Date

## Agent
```

Agents must not silently turn a temporary implementation choice into a permanent architectural rule.

---

# 11. Project Status

`PROJECT_STATUS.md` is the current snapshot.

It should answer:

```text
What works?
What is partially implemented?
What is broken?
What is being developed?
What is next?
```

Keep it short enough that an AI can read it quickly.

---

# 12. AI Context

`AI_CONTEXT.md` should contain the smallest useful project summary.

It should include:

- game concept
- design philosophy
- current engine
- current architecture
- important systems
- important constraints
- current development phase
- critical known problems
- links to deeper documentation

Do not turn AI_CONTEXT.md into a giant dump of implementation details.

---

# 13. Task System

Tasks are divided into:

```text
TODO.md
IN_PROGRESS.md
COMPLETED.md
```

Only one active AI agent exists at a time, but tasks should still be separated so that future agents can understand project history.

A task should contain:

```text
## Task

### Goal

### Scope

### Relevant Files

### Dependencies

### Acceptance Criteria

### Notes
```

When completed, move the task to `COMPLETED.md` and create a changelog entry.

---

# 14. Git Strategy

Git should be used as the authoritative low-level history.

Although direct commits to `main` may be used during early development, the preferred safety model is:

```text
main
  ↓
agent performs work
  ↓
tests
  ↓
documentation
  ↓
commit
  ↓
main
```

If branches are later introduced, the protocol can evolve to:

```text
main
 ├── feature/...
 ├── fix/...
 └── experiment/...
```

### Important

Never rely exclusively on Git commit messages to explain project knowledge.

Git tells us **what changed**.

The project memory system explains:

**what changed + why + consequences + dependencies + what the next agent needs to know.**

---

# 15. Commit Rules

Prefer small, meaningful commits.

Good:

```text
feat: add player inventory model
fix: prevent duplicate item pickup
docs: document inventory architecture
```

Avoid:

```text
update stuff
changes
AI work
final
```

A commit should describe the technical change.

The changelog should explain the project-level meaning of the change.

---

# 16. Testing Requirement

Before completing a task, an agent should test the affected functionality.

Testing may include:

- Godot project validation
- unit tests
- integration tests
- scene tests
- gameplay tests
- asset validation
- manual verification

The agent must document what was tested.

If testing could not be performed, state:

```text
NOT TESTED
Reason: ...
```

Never claim that something works when it was not verified.

---

# 17. Asset Management

The project uses:

```text
AI-generated assets
+
Manual assets
```

AI generation is expected to be the primary asset creation method.

Every significant asset must be recorded in:

```text
docs/assets/ASSET_MANIFEST.md
```

Recommended fields:

```text
Asset ID
Name
Type
Path
Source
Generator / Tool
Prompt reference
Author
Dimensions
Frame size
Animation frames
Directions
Format
Transparency
Intended use
Related entity
Status
License / usage notes
Created date
Modified date
Notes
```

Example:

```yaml
asset_id: CHAR-NOVICE-001
name: Novice Female Healer
type: character_sprite
path: assets/characters/novice_female/
source: AI-generated
tool: <tool>
dimensions: <dimensions>
frame_size: <frame dimensions>
animation_frames: <number>
directions: <directions>
intended_use: player_character
status: approved
```

The manifest prevents future agents from treating existing assets as unexplained files.

---

# 18. Game Design Independence

The project may take inspiration from classic MMORPG design patterns.

However:

- do not copy copyrighted assets
- do not copy proprietary code
- do not reproduce another game's exact characters
- do not reproduce another game's exact maps
- do not assume that a mechanic must exist merely because it exists in a reference game

The objective is an **original RPG with its own identity**.

Reference games may inform design analysis, but project decisions must be documented independently.

---

# 19. AI Agent Handoff

At the end of every task, the agent must leave the repository understandable to another agent.

The handoff must answer:

```text
What did I do?

Why did I do it?

What files changed?

What did I add?

What did I modify?

What did I delete?

What tests did I run?

What remains unfinished?

Are there known bugs?

Did I make an architecture decision?

What should the next agent inspect?
```

A handoff may be placed in:

```text
docs/changelog/
```

and summarized in:

```text
PROJECT_STATUS.md
```

---

# 20. Recovery When Documentation Is Wrong

Documentation can become stale.

If an agent finds:

```text
documentation != actual code
```

the agent must trust verified repository reality over an outdated description.

Then:

1. determine the correct current state
2. update the documentation
3. document the discrepancy if significant
4. continue the task

Never preserve an incorrect architecture merely because an old document says it exists.

---

# 21. Dependency Awareness

Before changing a shared system, inspect its dependants.

Examples:

```text
PlayerStats
   ↓
Combat
   ↓
Damage
   ↓
Enemy
   ↓
Loot
   ↓
Inventory
```

A change to a foundational system may affect many downstream systems.

When practical, record important dependencies in architecture documentation.

---

# 22. Unknown Technology Decisions

When a technical decision is still marked:

```text
UNDECIDED
```

the first agent facing that decision should not guess.

Instead:

1. identify the problem
2. identify realistic options
3. compare them against project requirements
4. choose only if the decision is necessary
5. create an ADR
6. update ARCHITECTURE.md
7. update AI_CONTEXT.md if the decision is fundamental

This allows the project to evolve without prematurely locking the technology stack.

---

# 23. Definition of Done

A task is complete only when:

- implementation is complete
- affected systems were tested
- no obvious broken references remain
- relevant documentation is updated
- additions are recorded
- modifications are recorded
- deletions are recorded
- architecture decisions are documented
- task status is updated
- known limitations are documented
- next-agent information is recorded

---

# 24. Golden Rule

> **Every AI agent must leave the repository easier for the next AI agent to understand than it found it.**

The purpose of this system is not merely to make agents write code.

It is to create a persistent development history in which independent AI agents can safely continue the same RPG project over months or years.

