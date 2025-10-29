# MATLAB Manual Transmission Simulation

This MATLAB project provides a simulation and visualization of a 6-speed manual transmission's control logic. The script simulates a full-throttle acceleration run, applying predefined shift logic based on optimal engine RPMs, and generates plots to analyze the vehicle's performance.

##  Key Features

* **Configurable Parameters:** Easily modify engine specifications (RPM limits, redline), 6-speed gear ratios, final drive, and basic vehicle parameters (tire radius, mass).
* **Shift Map Generation:** Automatically generates a detailed "Shift Map" plot, visualizing the relationship between Engine RPM and Vehicle Speed for each gear.
    
* **Acceleration Simulation:** Runs a time-based simulation of a full-throttle acceleration run, calculating vehicle speed, engine RPM, and current gear at each time step.
* **Dynamic Shift Logic:** Implements a core `evaluate_shift` function to automatically determine upshift and downshift commands based on RPM and throttle thresholds.
* **Performance Visualization:** Creates a comprehensive output plot with three subplots:
    1.  Vehicle Speed vs. Time
    2.  Engine RPM vs. Time (with shift points and redline)
    3.  Gear Selection vs. Time


    
##  License

This project is open-sourced under the MIT License. See the `LICENSE` file for more details.
