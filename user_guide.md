# UUV Minefield Simulation Software - User Guide

## Overview

This simulation tool models Unmanned Underwater Vehicle (UUV) fleets attempting to cross minefields. The interface is divided into three main components:

1. **Grid Display** – Visual representation of the minefield and UUV positions.
2. **Input Interface (Three Tabs)** – Configure simulation, fleet, and minefield settings.
3. **Textual Output** – Displays simulation status and results.

---

## Initial Screen Components
![Initial Screen Components][def_0]

### Grid Display

- Shows a 6x9 rectangular grid.
- **UUVs**: Gray lozenges.
- **Mines**: Red six-point stars.
- **Trajectories**: Dash-dot lines.
- Axis markings included.

---

## Input Tabs

### 1. Simulation Tab
![Simulation Tab][def_1]

- **Number of Runs**: Input total simulation runs.
- **Time Limit (s)**: Define max duration per simulation.
- **Animate**: Checkbox to enable/disable animation.
- **Start Button**: Runs the simulation (enabled when status is `Ready`).
- **Simulation Status**: Indicates `Ready`, `Running`, or `Finished`.

### 2. Fleet Tab
![Fleet Tab][def_2]

- **Ships**: Number of UUVs in the fleet.
- **Behavior**: Dropdown list to define fleet behavior:
  - `Kamikaze`: All UUVs go straight from start to finish.
  - `Random_Start_Point`: Random start points → common end point.
  - `Random_End_Point`: Common start point → random end points.
  - `Rand_Start_Rand_End`: Each UUV gets random start and end points.

### 3. Minefield Tab
![Minefield Tab][def_3]

- **Mine Count**: Number of mines.
- **Layout**: Mine distribution method:
  - `uniform`: Even spacing.
  - `rand`: Randomly, uniformly distributed.
  - `randn`: Gaussian distribution centered on screen.
  - `uniform-e`: Uniform with Gaussian error (std dev = 1/num_mines).
- **Damage Range (m)**: Effective damage radius of mines.
- **Detection Range (m)**: Mine detection radius.
- **Mine Type**: Dropdown selector for mine types.
- **Export**: Save minefield configuration to JSON.
- **Import**: Load minefield configuration from JSON.

---

## Running the Simulation
![Simulation while running][def_4]

1. Configure simulation, fleet, and minefield settings.
2. Click **Start**.
3. While `Running`, all inputs are disabled.
4. Each run uses the same minefield configuration.
5. Fleet behavior determines UUV start and end points.
6. After completion (all runs or time limit), the system reactivates input options.

---

## Output
![Simulation Output][def_5]

- A table displays:
  - Number of remaining and destroyed UUVs.
  - Number of destroyed mines.
  - Percentage of surviving assets.

---

## Notes

- All layouts and positions are scaled to the grid display dimensions.
- The interface dynamically updates based on the current simulation state.
- Exported/imported configurations must be valid JSON format.

---

## Troubleshooting

- **Start button disabled**: Ensure status is `Ready` and all required fields are filled.
- **No visible objects on grid**: Verify non-zero UUV and mine counts.

---

## Version

*UUV Minefield Simulation Software* – Version 1.0


[def_0]: ./Images/Initial_Screen_Components.svg
[def_1]: ./Images/Simulation_tab.svg
[def_2]: ./Images/Fleet_tab.svg
[def_3]: ./Images/Minefield_tab.svg
[def_4]: ./Images/Simulation_running.svg
[def_5]: ./Images/Sim_output.svg