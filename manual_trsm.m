% Manual Transmission Control Logic Simulation
% This script simulates a 6-speed manual transmission with shift logic
% based on optimal engine RPM range and vehicle performance

clear all; close all; clc;

%% Vehicle and Engine Parameters
% Engine characteristics (configurable)
engine.max_rpm = 7000;          % Maximum engine RPM
engine.idle_rpm = 700;          % Idle RPM
engine.max_torque_rpm = 4500;   % RPM at maximum torque
engine.redline = 6500;          % Redline RPM

% Transmission ratios (example for a sporty manual car)
trans.ratios = [3.82, 2.20, 1.40, 1.03, 0.84, 0.69]; % 6-speed gear ratios
trans.final_drive = 3.73;       % Final drive ratio
trans.num_gears = length(trans.ratios);

% Shift point parameters
shift.upshift_rpm = 4500;       % Target RPM for upshift
shift.downshift_rpm = 1200;     % Minimum RPM before downshift
shift.optimal_rpm = 4500;       % Optimal RPM for performance

% Vehicle parameters
vehicle.tire_radius = 0.32;     % Tire radius in meters
vehicle.mass = 1400;            % Vehicle mass in kg
vehicle.drag_coeff = 0.32;      % Aerodynamic drag coefficient
vehicle.frontal_area = 2.2;     % Frontal area in m^2

%% Generate Shift Map (RPM vs Speed for each gear)
figure('Name', 'Transmission Shift Map', 'Position', [100 100 1000 600]);

rpm_range = engine.idle_rpm:100:engine.max_rpm;
colors = lines(trans.num_gears);

for gear = 1:trans.num_gears
    speeds = arrayfun(@(r) rpm_to_speed(r, trans.ratios(gear), trans.final_drive, vehicle.tire_radius), rpm_range);
    plot(speeds, rpm_range, 'LineWidth', 2, 'Color', colors(gear,:), 'DisplayName', sprintf('Gear %d', gear));
    hold on;
end

% Add shift points
yline(shift.upshift_rpm, '--r', 'LineWidth', 1.5, 'DisplayName', 'Upshift Point');
yline(shift.downshift_rpm, '--b', 'LineWidth', 1.5, 'DisplayName', 'Downshift Point');
yline(shift.optimal_rpm, '--g', 'LineWidth', 1.5, 'DisplayName', 'Optimal RPM');
yline(engine.redline, '--k', 'LineWidth', 2, 'DisplayName', 'Redline');

xlabel('Vehicle Speed (km/h)', 'FontSize', 12);
ylabel('Engine RPM', 'FontSize', 12);
title('Manual Transmission Shift Map', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest');
grid on;
xlim([0 250]);
ylim([0 engine.max_rpm]);

%% Simulation: Acceleration Run with Shift Logic
sim_time = 100; % seconds
dt = 0.01; % time step
time = 0:dt:sim_time;
n_steps = length(time);

% Initialize arrays
speed = zeros(1, n_steps);
rpm = zeros(1, n_steps);
gear = ones(1, n_steps);
throttle = zeros(1, n_steps);

% Throttle profile (0-100%)
throttle = 100 * ones(1, n_steps); % Full throttle acceleration

% Initial conditions
speed(1) = 0;
gear(1) = 1;
rpm(1) = engine.idle_rpm;
current_gear = 1;

% Simplified physics simulation
for i = 2:n_steps
    % Simple acceleration model (not physics-accurate, for demonstration)
    current_ratio = trans.ratios(gear(i-1)) * trans.final_drive;
    
    % Acceleration based on gear and throttle
    accel = (throttle(i) / 100) * (10 / current_ratio) * (1 - speed(i-1)/250); % m/s^2
    speed(i) = speed(i-1) + accel * dt * 3.6; % km/h
    
    % Calculate RPM from speed and gear
    rpm(i) = speed_to_rpm(speed(i), trans.ratios(gear(i-1)), trans.final_drive, vehicle.tire_radius);
    
    % Evaluate shift logic
    [current_gear, shift_cmd] = evaluate_shift(current_gear, rpm(i), throttle(i), ...
        shift.upshift_rpm, shift.downshift_rpm, trans.num_gears);
    
    % Apply shift (with RPM drop simulation)
    if shift_cmd == 1 % Upshift
        new_ratio = trans.ratios(current_gear);
        old_ratio = trans.ratios(current_gear - 1);
        rpm(i) = rpm(i) * (new_ratio / old_ratio);
    elseif shift_cmd == -1 % Downshift
        new_ratio = trans.ratios(current_gear);
        old_ratio = trans.ratios(current_gear + 1);
        rpm(i) = rpm(i) * (new_ratio / old_ratio);
    end
    
    gear(i) = current_gear;
    
    % Limit RPM to redline
    if rpm(i) > engine.redline
        rpm(i) = engine.redline;
    end
end

%% Plot Simulation Results
figure('Name', 'Acceleration Simulation', 'Position', [150 150 1200 700]);

% Speed vs Time
subplot(3,1,1);
plot(time, speed, 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
xlabel('Time (s)', 'FontSize', 11);
ylabel('Speed (km/h)', 'FontSize', 11);
title('Vehicle Speed vs Time', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% RPM vs Time with shift points
subplot(3,1,2);
plot(time, rpm, 'LineWidth', 2, 'Color', [0.8500 0.3250 0.0980]);
hold on;
yline(shift.upshift_rpm, '--r', 'Upshift', 'LineWidth', 1.5);
yline(shift.downshift_rpm, '--b', 'Downshift', 'LineWidth', 1.5);
yline(engine.redline, '--k', 'Redline', 'LineWidth', 2);
xlabel('Time (s)', 'FontSize', 11);
ylabel('Engine RPM', 'FontSize', 11);
title('Engine RPM vs Time', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
ylim([0 engine.max_rpm]);

% Gear vs Time
subplot(3,1,3);
stairs(time, gear, 'LineWidth', 2, 'Color', [0.4660 0.6740 0.1880]);
xlabel('Time (s)', 'FontSize', 11);
ylabel('Gear', 'FontSize', 11);
title('Gear Selection vs Time', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
ylim([0 trans.num_gears + 1]);
yticks(1:trans.num_gears);

%% Display Performance Metrics
fprintf('\n========== TRANSMISSION CONTROL SIMULATION ==========\n');
fprintf('Final Speed: %.1f km/h\n', speed(end));
fprintf('Final Gear: %d\n', gear(end));
fprintf('Total Shifts: %d\n', sum(abs(diff(gear))));
fprintf('Average RPM: %.0f\n', mean(rpm));
fprintf('Time in optimal RPM range (4000-5500): %.1f%%\n', ...
    sum(rpm >= 4000 & rpm <= 5500) / n_steps * 100);
fprintf('=====================================================\n\n');

%% LOCAL FUNCTIONS

% Calculate Vehicle Speed from RPM and Gear
function speed_kmh = rpm_to_speed(rpm, gear_ratio, final_drive, tire_radius)
    % Convert engine RPM to vehicle speed in km/h
    wheel_rpm = rpm / (gear_ratio * final_drive);
    wheel_speed_ms = wheel_rpm * 2 * pi * tire_radius / 60;
    speed_kmh = wheel_speed_ms * 3.6;
end

% Calculate Engine RPM from Vehicle Speed and Gear
function rpm = speed_to_rpm(speed_kmh, gear_ratio, final_drive, tire_radius)
    % Convert vehicle speed in km/h to engine RPM
    speed_ms = speed_kmh / 3.6;
    wheel_rpm = speed_ms / (2 * pi * tire_radius) * 60;
    rpm = wheel_rpm * gear_ratio * final_drive;
end

% Shift Logic Evaluation Function
function [new_gear, shift_cmd] = evaluate_shift(current_gear, rpm, throttle, upshift_rpm, downshift_rpm, max_gears)
    % Evaluate whether to shift up or down
    % Returns: new gear and shift command (-1: downshift, 0: no shift, 1: upshift)
    
    shift_cmd = 0;
    new_gear = current_gear;
    
    % Upshift logic (only if throttle > 20% to prevent lugging)
    if rpm >= upshift_rpm && current_gear < max_gears && throttle > 20
        new_gear = current_gear + 1;
        shift_cmd = 1;
    end
    
    % Downshift logic (manual mode - driver anticipating need for power)
    if rpm <= downshift_rpm && current_gear > 1 && throttle > 60
        new_gear = current_gear - 1;
        shift_cmd = -1;
    end
end