# Sprite Rigger (Godot 4 Editor Plugin)

An in-editor dev tool for semi-automatic character sprite rigging. Mark joints by clicking, crop body part bounding boxes, and automatically generate a complete `Skeleton2D` + `Bone2D` + `Sprite2D` rig scene with extracted textures.

---

## Features

- **Fixed Humanoid Skeleton Hierarchy**:
  ```
  hip (root)
  ├─ torso
  │  ├─ head
  │  ├─ upper_arm_L → forearm_L → hand_L
  │  └─ upper_arm_R → forearm_R → hand_R   (sword arm)
  ├─ upper_leg_L → lower_leg_L
  └─ upper_leg_R → lower_leg_R
  ```
  *(Includes separate hand bones `hand_L` and `hand_R` for weapon swapping).*

- **8 Direction Support**:
  Quick selector for `south`, `southwest`, `west`, `northwest`, `north`, `northeast`, `east`, and `southeast`.

- **Interactive Canvas**:
  - Live preview with checkerboard transparency background.
  - Zoom controls (`50%`, `100%`, `150%`, `200%`, `Fit View`).
  - Real-time coordinate indicator showing exact pixel position under the cursor.
  - Color-coded joint markers with visual bone connection lines.
  - Visual bounding boxes with translucent color fill and labels.
  - Rubber-band dragging for intuitive box drawing.

- **Automated Rig Builder**:
  - Automatically crops each defined body part using `Image.get_region()`.
  - Saves individual part textures to disk as `.png` files under `<direction>/parts/`.
  - Calculates local `Bone2D` offsets and transforms based on hierarchical parent-child relationships.
  - Sets `bone.rest = bone.transform` and calculates bone lengths and angles.
  - Attaches a `Sprite2D` to each bone with the correct `offset` relative to the joint pivot (`centered = false`).
  - Configurable Z-index per body part for proper 2D layering.
  - Packs and saves `.tscn` scenes via `ResourceSaver` using external file paths so scenes reload seamlessly across editor restarts.

---

## Workflow

1. **Open the Plugin**:
   - In Godot Editor: `Project` > `Project Settings` > `Plugins` > Ensure **Sprite Rigger** is enabled.
   - The **Sprite Rigger** dock appears on the right dock bar (or under `Project` > `Tools` > `Open Sprite Rigger`).

2. **Load Sprite**:
   - Click **📁 Load Sprite Image...** to browse for your character sprite (e.g. `South.png`).
   - Quick load buttons are also available in the toolbar.

3. **Step 1: Place Joints**:
   - Switch to the **1. Place Joints** tab.
   - Click on the image to place each joint in sequence:
     1. `hip (root)`
     2. `torso`
     3. `head`
     4. `upper_arm_L`
     5. `forearm_L`
     6. `hand_L`
     7. `upper_arm_R`
     8. `forearm_R`
     9. `hand_R`
     10. `upper_leg_L`
     11. `lower_leg_L`
     12. `upper_leg_R`
     13. `lower_leg_R`
   - You can click any joint in the tree list to reposition it, or right-click to clear.

4. **Step 2: Crop Body Parts**:
   - Switch to the **2. Crop Body Parts** tab.
   - Click and drag a rectangle around each body part.
   - Or click **⚡ Guess from Joints** to generate starting bounding boxes centered on your placed joints.
   - Adjust Z-Index values if you want specific layering (e.g. back arm behind torso).

5. **Step 3: Generate Rig**:
   - Switch to the **3. Generate Rig** tab.
   - Review or adjust the output path (default: `res://assets/sprites/player/<direction>/`).
   - Click **🚀 GENERATE RIG SCENE**.
   - The plugin crops and writes all textures, builds the node tree, and saves `rig.tscn`.
   - Click **Open Generated Scene in Editor** to immediately view and animate the rig.

---

## Output Structure

```
res://assets/sprites/player/
├── south/
│   ├── parts/
│   │   ├── torso.png
│   │   ├── head.png
│   │   ├── upper_arm_L.png
│   │   ├── forearm_L.png
│   │   ├── hand_L.png
│   │   ├── upper_arm_R.png
│   │   ├── forearm_R.png
│   │   ├── hand_R.png
│   │   ├── upper_leg_L.png
│   │   ├── lower_leg_L.png
│   │   ├── upper_leg_R.png
│   │   └── lower_leg_R.png
│   └── rig.tscn
├── north/
...
```
