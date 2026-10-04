# Feature Specification: Experience & Character Stats (GameState & Allocation)

## Overview
This feature introduces the persistent RPG character state tracking and attribute allocation system for `OriginalRPG`. It defines `GameState` as a central singleton tracking base level, job level, HP, stamina, available stat points, and the 6 core RPG attributes (STR, AGI, VIT, INT, DEX, LUK).

## Core Architecture

### 1. `GameState` (Autoload Singleton)
`GameState` manages the global progression state of the player character, decoupled from temporary presentation nodes.

#### State Tracked:
- **Base Level (`base_level`)**: Current player character level (default 1).
- **Job Level (`job_level`)**: Current class/job mastery level (default 1).
- **Stat Points (`stat_points`)**: Free points available to allocate into attributes (default 48).
- **Resources**:
  - `hp` / `max_hp`: Vitality hit points.
  - `stamina` / `max_stamina`: Energy pool for physical maneuvers.
  - `mana` / `max_mana`: Magic / skill resource pool.
- **Attributes (`stats`)**:
  - `STR`: Physical power, attack damage, and carrying capacity.
  - `AGI`: Attack speed, agility, and evasion.
  - `VIT`: Maximum HP, physical defense, and durability.
  - `INT`: Maximum SP/mana, magic power, and mental resistance.
  - `DEX`: Accuracy, hit rate, and damage stability.
  - `LUK`: Critical strike chance and lucky outcomes.

#### Progression Signals:
- `stat_points_changed(new_points: int)`: Emitted whenever stat points are earned or spent.
- `leveled_up(new_level: int)`: Emitted when base level increases.
- `job_leveled_up(new_job_level: int)`: Emitted when job level increases.
- `stats_changed()`: Emitted when any attribute is modified.

### 2. Stat Point Allocation Economy
Attributes cost increasingly more points as they rise.
- **Cost Formula**:
  $$\text{cost} = \max\left(1, \left\lfloor \frac{\text{current} - 1}{10} \right\rfloor + 2\right)$$
  - Values 1–10: Cost 2 points per +1
  - Values 11–20: Cost 3 points per +1
  - Values 21–30: Cost 4 points per +1
  - Values 31–40: Cost 5 points per +1, etc.
- **Allocation Rules**:
  - `try_increase_stat(stat_name: String) -> bool` checks whether `stat_points >= stat_increase_cost(current)`.
  - If affordable, deducts the cost, increments `stats[stat_name]`, recalculates derived stats, and emits signals.
  - Decreasing allocated stats is locked in v1 to preserve character progression consequence.

### 3. Derived Stat Scaling
- **VIT**: Adds $+10$ to `max_hp` per point above base.
- **AGI**: Adds $+2$ to `max_stamina` per point above base.
- **STR**: Contributes $+1$ to baseline physical attack power.

### 4. Integration
- `CharacterStatsComponent`: Player entity components can synchronize two-way with `GameState`.
- `CharacterStatsWindow`: Consumes `GameState` signals directly to display live level, resources, stat points, and attribute rows.
