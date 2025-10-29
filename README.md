# MATLAB Manual Transmission Simulation

This MATLAB project provides a simulation and visualization of a 6-speed manual transmission's control logic. The script simulates a full-throttle acceleration run, applying predefined shift logic based on optimal engine RPMs, and generates plots to analyze the vehicle's performance.

## 🏁 Key Features

* **Configurable Parameters:** Easily modify engine specifications (RPM limits, redline), 6-speed gear ratios, final drive, and basic vehicle parameters (tire radius, mass).
* **Shift Map Generation:** Automatically generates a detailed "Shift Map" plot, visualizing the relationship between Engine RPM and Vehicle Speed for each gear.
    
* **Acceleration Simulation:** Runs a time-based simulation of a full-throttle acceleration run, calculating vehicle speed, engine RPM, and current gear at each time step.
* **Dynamic Shift Logic:** Implements a core `evaluate_shift` function to automatically determine upshift and downshift commands based on RPM and throttle thresholds.
* **Performance Visualization:** Creates a comprehensive output plot with three subplots:
    1.  Vehicle Speed vs. Time
    2.  Engine RPM vs. Time (with shift points and redline)
    3.  Gear Selection vs. Time
    
* **Console Metrics:** Prints a summary of the simulation results (final speed, total shifts, average RPM) to the MATLAB Command Window.

## 🚀 Getting Started

### Prerequisites

* MATLAB (R2016b or newer should be compatible, as it uses basic plotting and functions).

### How to Run

1.  Clone this repository or download the `.m` script file.
2.  Open the main script file (e.g., `simulation_script.m`) in MATLAB.
3.  **(Optional)** Modify any values in the `%% Vehicle and Engine Parameters` section to simulate a different vehicle.
4.  Run the script by pressing **F5** or clicking the **Run** button in the MATLAB Editor.
5.  Two new figure windows will open with the 'Shift Map' and 'Acceleration Simulation' results.
6.  Check the MATLAB Command Window for the final performance metrics.

## 🔧 Code Overview

The script is divided into several logical sections:

1.  **Vehicle and Engine Parameters:** All constants for the simulation are defined here. This is the main configuration section.
2.  **Generate Shift Map:** This section calculates the speed range for each gear and plots the RPM vs. Speed map.
3.  **Simulation: Acceleration Run:** This is the main `for` loop that iterates through time (`dt`). It uses a simplified physics model to calculate acceleration and then calls `speed_to_rpm` and `evaluate_shift` to update the vehicle's state.
4.  **Plot Simulation Results:** This section generates the second figure with the three subplots for analysis.
5.  **Display Performance Metrics:** Prints the final summary to the console using `fprintf`.
6.  **Local Functions:**
    * `rpm_to_speed`: A helper function to calculate vehicle speed (km/h) from a given RPM and gear.
    * `speed_to_rpm`: A helper function to calculate engine RPM from a given vehicle speed (km/h) and gear.
    * `evaluate_shift`: The core control logic. It takes the current state (gear, RPM, throttle) and decides if an upshift or downshift is necessary.

## 📄 License

This project is open-sourced under the MIT License. See the `LICENSE` file for more details.
