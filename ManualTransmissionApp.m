classdef ManualTransmissionApp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        GridLayout                 matlab.ui.container.GridLayout
        LeftPanel                  matlab.ui.container.Panel
        RightPanel                 matlab.ui.container.Panel
        
        % Control Components
        ThrottleSlider             matlab.ui.control.Slider
        ThrottleLabel              matlab.ui.control.Label
        ThrottleValueLabel         matlab.ui.control.Label
        
        GearUpButton               matlab.ui.control.Button
        GearDownButton             matlab.ui.control.Button
        CurrentGearLabel           matlab.ui.control.Label
        
        StartButton                matlab.ui.control.Button
        StopButton                 matlab.ui.control.Button
        ResetButton                matlab.ui.control.Button
        
        SpeedGauge                 matlab.ui.control.Gauge
        RPMGauge                   matlab.ui.control.Gauge
        
        % Display Components
        SpeedLabel                 matlab.ui.control.Label
        RPMLabel                   matlab.ui.control.Label
        
        % Plot Components
        RPMAxes                    matlab.ui.control.UIAxes
        SpeedAxes                  matlab.ui.control.UIAxes
    end

    properties (Access = private)
        % Vehicle parameters
        GearRatios = [3.82, 2.20, 1.40, 1.03, 0.84, 0.69]
        FinalDrive = 3.73
        TireRadius = 0.32
        Redline = 6500
        MaxRPM = 7000
        
        % Simulation state
        CurrentGear = 1
        CurrentSpeed = 0  % km/h
        CurrentRPM = 800
        Throttle = 0
        
        % History for plotting
        TimeHistory = []
        SpeedHistory = []
        RPMHistory = []
        
        % Timer for simulation
        SimTimer
        IsRunning = false
        SimTime = 0
        
        % Plot lines
        RPMLine
        SpeedLine
    end

    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)
            % Create UIFigure
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1200 700];
            app.UIFigure.Name = 'Manual Transmission Control';
            
            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x', '2x'};
            app.GridLayout.RowHeight = {'1x'};
            
            % Create LeftPanel (Controls)
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Title = 'Vehicle Controls';
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;
            app.LeftPanel.FontWeight = 'bold';
            app.LeftPanel.FontSize = 14;
            
            % Create RightPanel (Displays)
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Title = 'Vehicle Status';
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;
            app.RightPanel.FontWeight = 'bold';
            app.RightPanel.FontSize = 14;
            
            % ===== LEFT PANEL COMPONENTS =====
            
            % RPM Gauge
            app.RPMGauge = uigauge(app.LeftPanel, 'circular');
            app.RPMGauge.Position = [30 480 150 150];
            app.RPMGauge.Limits = [0 7000];
            app.RPMGauge.MajorTicks = [0 1000 2000 3000 4000 5000 6000 7000];
            app.RPMGauge.ScaleColors = {'green', 'yellow', 'red'};
            app.RPMGauge.ScaleColorLimits = [0 5000; 5000 6500; 6500 7000];
            
            app.RPMLabel = uilabel(app.LeftPanel);
            app.RPMLabel.Position = [60 460 100 22];
            app.RPMLabel.Text = 'Engine RPM';
            app.RPMLabel.FontWeight = 'bold';
            app.RPMLabel.HorizontalAlignment = 'center';
            
            % Speed Gauge
            app.SpeedGauge = uigauge(app.LeftPanel, 'circular');
            app.SpeedGauge.Position = [220 480 150 150];
            app.SpeedGauge.Limits = [0 250];
            app.SpeedGauge.MajorTicks = [0 50 100 150 200 250];
            
            app.SpeedLabel = uilabel(app.LeftPanel);
            app.SpeedLabel.Position = [245 460 100 22];
            app.SpeedLabel.Text = 'Speed (km/h)';
            app.SpeedLabel.FontWeight = 'bold';
            app.SpeedLabel.HorizontalAlignment = 'center';
            
            % Current Gear Display
            app.CurrentGearLabel = uilabel(app.LeftPanel);
            app.CurrentGearLabel.Position = [120 390 160 60];
            app.CurrentGearLabel.Text = 'GEAR: 1';
            app.CurrentGearLabel.FontSize = 32;
            app.CurrentGearLabel.FontWeight = 'bold';
            app.CurrentGearLabel.HorizontalAlignment = 'center';
            app.CurrentGearLabel.BackgroundColor = [0.2 0.2 0.2];
            app.CurrentGearLabel.FontColor = [0 1 0];
            
            % Gear Shift Buttons
            app.GearUpButton = uibutton(app.LeftPanel, 'push');
            app.GearUpButton.Position = [150 330 100 40];
            app.GearUpButton.Text = '↑ Shift Up';
            app.GearUpButton.FontSize = 14;
            app.GearUpButton.FontWeight = 'bold';
            app.GearUpButton.ButtonPushedFcn = createCallbackFcn(app, @GearUpButtonPushed, true);
            
            app.GearDownButton = uibutton(app.LeftPanel, 'push');
            app.GearDownButton.Position = [150 280 100 40];
            app.GearDownButton.Text = '↓ Shift Down';
            app.GearDownButton.FontSize = 14;
            app.GearDownButton.FontWeight = 'bold';
            app.GearDownButton.ButtonPushedFcn = createCallbackFcn(app, @GearDownButtonPushed, true);
            
            % Throttle Slider
            app.ThrottleLabel = uilabel(app.LeftPanel);
            app.ThrottleLabel.Position = [50 230 120 22];
            app.ThrottleLabel.Text = 'Throttle Position';
            app.ThrottleLabel.FontWeight = 'bold';
            
            app.ThrottleSlider = uislider(app.LeftPanel);
            app.ThrottleSlider.Position = [50 210 300 3];
            app.ThrottleSlider.Limits = [0 100];
            app.ThrottleSlider.Value = 0;
            app.ThrottleSlider.ValueChangedFcn = createCallbackFcn(app, @ThrottleSliderValueChanged, true);
            
            app.ThrottleValueLabel = uilabel(app.LeftPanel);
            app.ThrottleValueLabel.Position = [170 180 80 22];
            app.ThrottleValueLabel.Text = '0 %';
            app.ThrottleValueLabel.FontSize = 14;
            app.ThrottleValueLabel.HorizontalAlignment = 'center';
            
            % Control Buttons
            app.StartButton = uibutton(app.LeftPanel, 'push');
            app.StartButton.Position = [50 120 100 40];
            app.StartButton.Text = 'START';
            app.StartButton.FontSize = 14;
            app.StartButton.FontWeight = 'bold';
            app.StartButton.BackgroundColor = [0 0.8 0];
            app.StartButton.FontColor = [1 1 1];
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            
            app.StopButton = uibutton(app.LeftPanel, 'push');
            app.StopButton.Position = [160 120 100 40];
            app.StopButton.Text = 'STOP';
            app.StopButton.FontSize = 14;
            app.StopButton.FontWeight = 'bold';
            app.StopButton.BackgroundColor = [0.8 0 0];
            app.StopButton.FontColor = [1 1 1];
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.Enable = 'off';
            
            app.ResetButton = uibutton(app.LeftPanel, 'push');
            app.ResetButton.Position = [270 120 100 40];
            app.ResetButton.Text = 'RESET';
            app.ResetButton.FontSize = 14;
            app.ResetButton.FontWeight = 'bold';
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            
            % Instructions
            instructions = uilabel(app.LeftPanel);
            instructions.Position = [20 20 360 80];
            instructions.Text = ['Instructions:' newline ...
                                '1. Adjust throttle slider' newline ...
                                '2. Press START to begin' newline ...
                                '3. Use shift buttons to change gears' newline ...
                                '4. Watch RPM to avoid redline!'];
            instructions.FontSize = 11;
            
            % ===== RIGHT PANEL COMPONENTS =====
            
            % RPM History Plot
            app.RPMAxes = uiaxes(app.RightPanel);
            app.RPMAxes.Position = [20 350 680 250];
            title(app.RPMAxes, 'Engine RPM vs Time');
            xlabel(app.RPMAxes, 'Time (s)');
            ylabel(app.RPMAxes, 'RPM');
            app.RPMAxes.YLim = [0 7000];
            app.RPMAxes.XGrid = 'on';
            app.RPMAxes.YGrid = 'on';
            hold(app.RPMAxes, 'on');
            
            % Add redline to RPM plot
            yline(app.RPMAxes, 6500, '--r', 'Redline', 'LineWidth', 2);
            
            app.RPMLine = plot(app.RPMAxes, 0, 800, 'b-', 'LineWidth', 2);
            
            % Speed History Plot
            app.SpeedAxes = uiaxes(app.RightPanel);
            app.SpeedAxes.Position = [20 50 680 250];
            title(app.SpeedAxes, 'Vehicle Speed vs Time');
            xlabel(app.SpeedAxes, 'Time (s)');
            ylabel(app.SpeedAxes, 'Speed (km/h)');
            app.SpeedAxes.YLim = [0 250];
            app.SpeedAxes.XGrid = 'on';
            app.SpeedAxes.YGrid = 'on';
            hold(app.SpeedAxes, 'on');
            
            app.SpeedLine = plot(app.SpeedAxes, 0, 0, 'r-', 'LineWidth', 2);
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % Callbacks
    methods (Access = private)

        % Button pushed function: GearUpButton
        function GearUpButtonPushed(app, event)
            if app.CurrentGear < length(app.GearRatios)
                % Calculate new RPM after upshift
                old_ratio = app.GearRatios(app.CurrentGear);
                new_ratio = app.GearRatios(app.CurrentGear + 1);
                app.CurrentRPM = app.CurrentRPM * (new_ratio / old_ratio);
                
                app.CurrentGear = app.CurrentGear + 1;
                app.CurrentGearLabel.Text = sprintf('GEAR: %d', app.CurrentGear);
                
                % Update RPM gauge
                app.RPMGauge.Value = app.CurrentRPM;
            end
        end

        % Button pushed function: GearDownButton
        function GearDownButtonPushed(app, event)
            if app.CurrentGear > 1
                % Calculate new RPM after downshift
                old_ratio = app.GearRatios(app.CurrentGear);
                new_ratio = app.GearRatios(app.CurrentGear - 1);
                new_rpm = app.CurrentRPM * (new_ratio / old_ratio);
                
                % Check if downshift would over-rev
                if new_rpm <= app.Redline
                    app.CurrentRPM = new_rpm;
                    app.CurrentGear = app.CurrentGear - 1;
                    app.CurrentGearLabel.Text = sprintf('GEAR: %d', app.CurrentGear);
                    
                    % Update RPM gauge
                    app.RPMGauge.Value = app.CurrentRPM;
                else
                    % Flash warning
                    app.CurrentGearLabel.BackgroundColor = [1 0 0];
                    pause(0.2);
                    app.CurrentGearLabel.BackgroundColor = [0.2 0.2 0.2];
                end
            end
        end

        % Value changed function: ThrottleSlider
        function ThrottleSliderValueChanged(app, event)
            app.Throttle = app.ThrottleSlider.Value;
            app.ThrottleValueLabel.Text = sprintf('%.0f %%', app.Throttle);
        end

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            app.IsRunning = true;
            app.StartButton.Enable = 'off';
            app.StopButton.Enable = 'on';
            
            % Create and start timer
            app.SimTimer = timer('ExecutionMode', 'fixedRate', ...
                               'Period', 0.05, ...
                               'TimerFcn', @(~,~) app.UpdateSimulation());
            start(app.SimTimer);
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            app.IsRunning = false;
            app.StartButton.Enable = 'on';
            app.StopButton.Enable = 'off';
            
            if ~isempty(app.SimTimer) && isvalid(app.SimTimer)
                stop(app.SimTimer);
                delete(app.SimTimer);
            end
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            % Stop simulation if running
            if app.IsRunning
                app.StopButtonPushed();
            end
            
            % Reset all values
            app.CurrentGear = 1;
            app.CurrentSpeed = 0;
            app.CurrentRPM = 800;
            app.Throttle = 0;
            app.SimTime = 0;
            
            app.TimeHistory = [];
            app.SpeedHistory = [];
            app.RPMHistory = [];
            
            % Update displays
            app.CurrentGearLabel.Text = 'GEAR: 1';
            app.ThrottleSlider.Value = 0;
            app.ThrottleValueLabel.Text = '0 %';
            app.RPMGauge.Value = 800;
            app.SpeedGauge.Value = 0;
            
            % Clear plots
            app.RPMLine.XData = 0;
            app.RPMLine.YData = 800;
            app.SpeedLine.XData = 0;
            app.SpeedLine.YData = 0;
            
            app.RPMAxes.XLim = [0 10];
            app.SpeedAxes.XLim = [0 10];
        end

        % Simulation update function
        function UpdateSimulation(app)
            dt = 0.05; % Time step in seconds
            app.SimTime = app.SimTime + dt;
            
            % Calculate acceleration based on throttle and current gear
            current_ratio = app.GearRatios(app.CurrentGear) * app.FinalDrive;
            
            % Simple physics model
            base_accel = (app.Throttle / 100) * (10 / current_ratio);
            drag = 0.001 * app.CurrentSpeed^2; % Aerodynamic drag
            accel = base_accel - drag;
            
            % Update speed
            app.CurrentSpeed = max(0, app.CurrentSpeed + accel * dt * 3.6);
            
            % Calculate RPM from speed and gear
            speed_ms = app.CurrentSpeed / 3.6;
            wheel_rpm = speed_ms / (2 * pi * app.TireRadius) * 60;
            app.CurrentRPM = wheel_rpm * app.GearRatios(app.CurrentGear) * app.FinalDrive;
            
            % Idle RPM limit
            if app.CurrentRPM < 800
                app.CurrentRPM = 800;
            end
            
            % Redline limiter (acts like rev limiter)
            if app.CurrentRPM > app.Redline
                app.CurrentRPM = app.Redline;
                % Flash gear display
                if mod(app.SimTime, 0.2) < 0.1
                    app.CurrentGearLabel.BackgroundColor = [1 0 0];
                else
                    app.CurrentGearLabel.BackgroundColor = [0.2 0.2 0.2];
                end
            else
                app.CurrentGearLabel.BackgroundColor = [0.2 0.2 0.2];
            end
            
            % Update history
            app.TimeHistory = [app.TimeHistory, app.SimTime];
            app.SpeedHistory = [app.SpeedHistory, app.CurrentSpeed];
            app.RPMHistory = [app.RPMHistory, app.CurrentRPM];
            
            % Update gauges
            app.RPMGauge.Value = app.CurrentRPM;
            app.SpeedGauge.Value = app.CurrentSpeed;
            
            % Update plots
            app.RPMLine.XData = app.TimeHistory;
            app.RPMLine.YData = app.RPMHistory;
            app.SpeedLine.XData = app.TimeHistory;
            app.SpeedLine.YData = app.SpeedHistory;
            
            % Auto-scale X axis
            if app.SimTime > 10
                app.RPMAxes.XLim = [app.SimTime-10, app.SimTime];
                app.SpeedAxes.XLim = [app.SimTime-10, app.SimTime];
            end
        end
    end

    % App initialization and construction
    methods (Access = public)

        % Construct app
        function app = ManualTransmissionApp
            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            % Stop and delete timer if it exists
            if ~isempty(app.SimTimer) && isvalid(app.SimTimer)
                stop(app.SimTimer);
                delete(app.SimTimer);
            end

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end