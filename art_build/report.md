# Terrain Tiles Quality & Validation Report

> [!WARNING]
> **Transition Boundary Warning**: One or more transition boundaries are not at the exact midpoint (+/-8px). Source art adjustment recommended for seamless alignment:
> - outer_ne top crossing (x=115, target 128+/-8)
> - inner_ne right crossing (y=109, target 128+/-8)
> **Self-Seam Flags**: 4 tile(s) deviate >12 on 2px self-seam.
> **Cross-Variant Seam Flags**: 32 ordered pair(s) deviate >12 on 2px cross-seam.


## 1. Executive Summary
- **Source Tile Resolution**: All source images verified at **256 x 256 px**.
- **Generated Tile Count**: 22 tiles (8 center, 4 edge, 4 outer corner, 4 inner corner, 2 diagonal).
- **Pure Area Checks**: All 4 pure area tests **PASSED** (100% pure).
- **Edge Transition Midpoint**: edge_n left crossing = y:132, right crossing = y:133 (diff = 1 px) -> **PASS**.
- **Corner Transition Midpoints**:
  - `outer_ne`: top x = 115 (FAIL), right y = 129 (PASS)
  - `inner_ne`: top x = 127 (PASS), right y = 109 (FAIL)

---

## 2. Brightness Check (Section 3.1)
Mean RGB brightness comparison against terrain group mean:
- **Grass Group Mean**: 104.04
- **Dirt Group Mean**: 94.07

| Tile | Mean Brightness | Group Mean | Diff | Status |
|---|---|---|---|---|
| terrain_grass_center_01.png | 102.71 | 104.04 | 1.33 | PASS |
| terrain_grass_center_02.png | 104.61 | 104.04 | 0.57 | PASS |
| terrain_grass_center_03.png | 104.59 | 104.04 | 0.55 | PASS |
| terrain_grass_center_04.png | 104.26 | 104.04 | 0.22 | PASS |
| terrain_dirt_center_01.png | 94.38 | 94.07 | 0.31 | PASS |
| terrain_dirt_center_02.png | 93.66 | 94.07 | 0.41 | PASS |
| terrain_dirt_center_03.png | 94.19 | 94.07 | 0.12 | PASS |
| terrain_dirt_center_04.png | 94.05 | 94.07 | 0.02 | PASS |

---

## 3. Self-Seam Seam Continuity (Section 3.2)
Comparison of 2 px boundary strips within the same tile:
- Horizontal seam: Right 2px strip against Left 2px strip
- Vertical seam: Bottom 2px strip against Top 2px strip

| Tile | H-Seam Diff (Left vs Right) | V-Seam Diff (Top vs Bot) | Max Diff | Status |
|---|---|---|---|---|
| terrain_grass_center_01.png | 12.07 | 16.37 | 16.37 | **FLAG (>12)** |
| terrain_grass_center_02.png | 13.29 | 18.29 | 18.29 | **FLAG (>12)** |
| terrain_grass_center_03.png | 13.28 | 18.38 | 18.38 | **FLAG (>12)** |
| terrain_grass_center_04.png | 12.92 | 18.66 | 18.66 | **FLAG (>12)** |
| terrain_dirt_center_01.png | 5.27 | 6.40 | 6.40 | PASS (<=12) |
| terrain_dirt_center_02.png | 5.42 | 6.41 | 6.41 | PASS (<=12) |
| terrain_dirt_center_03.png | 5.45 | 6.49 | 6.49 | PASS (<=12) |
| terrain_dirt_center_04.png | 5.52 | 6.63 | 6.63 | PASS (<=12) |

---

## 4. Cross-Variant Seam Matrices (Section 3.3)
Mean absolute difference per channel across all ordered 4x4 pairs (2 px wide strip):

### Grass Variants (4x4)
**Horizontal Seam (A right vs B left):**
| From \ To | _01 | _02 | _03 | _04 |
|---|---|---|---|---|
| **_01** | 12.07 | 12.78 | 12.91 | 12.68 |
| **_02** | 12.77 | 13.29 | 13.45 | 13.27 |
| **_03** | 12.76 | 13.31 | 13.28 | 13.11 |
| **_04** | 12.71 | 13.13 | 13.21 | 12.92 |

**Vertical Seam (A bottom vs B top):**
| From \ To | _01 | _02 | _03 | _04 |
|---|---|---|---|---|
| **_01** | 16.37 | 16.44 | 16.92 | 16.80 |
| **_02** | 18.45 | 18.29 | 18.73 | 18.64 |
| **_03** | 18.11 | 17.94 | 18.38 | 18.28 |
| **_04** | 18.61 | 18.32 | 18.73 | 18.66 |

### Dirt Variants (4x4)
**Horizontal Seam (A right vs B left):**
| From \ To | _01 | _02 | _03 | _04 |
|---|---|---|---|---|
| **_01** | 5.27 | 5.64 | 5.58 | 5.61 |
| **_02** | 5.74 | 5.42 | 5.43 | 5.64 |
| **_03** | 5.69 | 5.62 | 5.45 | 5.64 |
| **_04** | 5.71 | 5.67 | 5.53 | 5.52 |

**Vertical Seam (A bottom vs B top):**
| From \ To | _01 | _02 | _03 | _04 |
|---|---|---|---|---|
| **_01** | 6.40 | 6.30 | 6.38 | 6.38 |
| **_02** | 6.54 | 6.41 | 6.54 | 6.56 |
| **_03** | 6.51 | 6.41 | 6.49 | 6.53 |
| **_04** | 6.70 | 6.53 | 6.59 | 6.63 |

---

## 5. Transition Boundary Midpoint & Pure Area Verification (Section 3.4)
- **Classifier Colors**:
  - Grass Reference: RGB(93.3, 149.4, 65.4)
  - Dirt Reference: RGB(131.3, 92.0, 59.8)
- **Boundary Crossings**:
  - `edge_n`: left column (x=0) crosses at y=132 (expected 128±8) -> **PASS**
  - `edge_n`: right column (x=255) crosses at y=133 (expected 128±8) -> **PASS**
  - `edge_n`: crossing difference = 1 px (expected <= 8 px) -> **PASS**
  - `outer_ne`: top row (y=0) crosses at x=115 (expected 128±8) -> **FAIL**
  - `outer_ne`: right column (x=255) crosses at y=129 (expected 128±8) -> **PASS**
  - `inner_ne`: top row (y=0) crosses at x=127 (expected 128±8) -> **PASS**
  - `inner_ne`: right column (x=255) crosses at y=109 (expected 128±8) -> **FAIL**
- **Pure Areas**:
  - `edge_n` top 25% (y 0..63) all grass: **PASS (100% pure)**
  - `edge_n` bottom 25% (y 192..255) all dirt: **PASS (100% pure)**
  - `outer_ne` bottom-left corner all dirt: **PASS (100% pure)**
  - `inner_ne` bottom-left corner all grass: **PASS (100% pure)**
