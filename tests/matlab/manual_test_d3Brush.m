%% Manual Test Script for d3Brush Component
% This script provides interactive tests for the d3Brush component
% Run each section to test different features visually
%
% Usage: Open this file and run sections using Ctrl+Enter (or Cmd+Enter on Mac)

%% Setup - Add component to path
addpath(genpath(fullfile(fileparts(fileparts(pwd)), 'components')));

%% Test 1: Basic Component Creation
% Create a simple brush with default settings

fig1 = uifigure('Position', [100 100 600 300], 'Name', 'Test 1: Basic Brush');
brush1 = d3Brush(fig1, 'Position', [50 50 500 200]);

fprintf('Test 1: Basic brush created with defaults\n');
fprintf('  Min: %.1f, Max: %.1f, SnapInterval: %.1f\n', brush1.Min, brush1.Max, brush1.SnapInterval);
fprintf('  Value: [%.1f, %.1f]\n', brush1.Value(1), brush1.Value(2));
fprintf('Try dragging the brush handles!\n\n');

%% Test 2: Custom Range and Snap Interval
% Create brush with custom settings

fig2 = uifigure('Position', [150 150 600 300], 'Name', 'Test 2: Custom Range');
brush2 = d3Brush(fig2, 'Position', [50 50 500 200]);

brush2.Min = -50;
brush2.Max = 50;
brush2.SnapInterval = 10;
brush2.Value = [-30, 20];

fprintf('Test 2: Custom range brush created\n');
fprintf('  Min: %.1f, Max: %.1f, SnapInterval: %.1f\n', brush2.Min, brush2.Max, brush2.SnapInterval);
fprintf('  Value: [%.1f, %.1f]\n', brush2.Value(1), brush2.Value(2));
fprintf('Try dragging - should snap to multiples of 10\n\n');

%% Test 3: Event Callbacks
% Test all event callbacks with console output

fig3 = uifigure('Position', [200 200 600 300], 'Name', 'Test 3: Event Callbacks');
brush3 = d3Brush(fig3, 'Position', [50 50 500 200]);

% Set up all callbacks
brush3.BrushStartedFcn = @(src, event) fprintf('  → BrushStarted\n');

brush3.ValueChangingFcn = @(src, event) fprintf('  → ValueChanging: [%.1f, %.1f]\n', ...
    event.Value(1), event.Value(2));

brush3.ValueChangedFcn = @(src, event) fprintf('  → ValueChanged: [%.1f, %.1f] (PreviousValue: [%.1f, %.1f])\n', ...
    event.Value(1), event.Value(2), event.PreviousValue(1), event.PreviousValue(2));

brush3.BrushEndedFcn = @(src, event) fprintf('  → BrushEnded\n\n');

fprintf('Test 3: Event callbacks configured\n');
fprintf('Drag the brush and watch the console for events:\n');
fprintf('  - BrushStarted: When you start dragging\n');
fprintf('  - ValueChanging: While dragging (throttled)\n');
fprintf('  - ValueChanged: When you release\n');
fprintf('  - BrushEnded: When interaction completes\n\n');

%% Test 4: Programmatic Value Changes
% Update value programmatically and verify synchronization

fig4 = uifigure('Position', [250 250 600 300], 'Name', 'Test 4: Programmatic Updates');
brush4 = d3Brush(fig4, 'Position', [50 50 500 200]);

brush4.ValueChangedFcn = @(src, event) fprintf('  Value updated to: [%.1f, %.1f]\n', ...
    event.Value(1), event.Value(2));

fprintf('Test 4: Programmatic value updates\n');
fprintf('Updating values every 2 seconds...\n');

% Animate the brush selection
values = [
    10, 30;
    20, 60;
    40, 80;
    60, 90;
    30, 70;
];

for i = 1:size(values, 1)
    pause(2);
    brush4.Value = values(i, :);
    fprintf('  Set Value to: [%.1f, %.1f]\n', values(i, 1), values(i, 2));
end

fprintf('Animation complete!\n\n');

%% Test 5: Multiple Brushes in One Figure
% Create multiple independent brush components

fig5 = uifigure('Position', [300 300 600 400], 'Name', 'Test 5: Multiple Brushes');

brush5a = d3Brush(fig5, 'Position', [50 250 500 100]);
brush5a.Min = 0;
brush5a.Max = 100;
brush5a.Value = [20, 40];

brush5b = d3Brush(fig5, 'Position', [50 50 500 100]);
brush5b.Min = 0;
brush5b.Max = 200;
brush5b.SnapInterval = 10;
brush5b.Value = [80, 120];

fprintf('Test 5: Multiple brushes created\n');
fprintf('  Brush A: Range [%.1f, %.1f], Value [%.1f, %.1f]\n', ...
    brush5a.Min, brush5a.Max, brush5a.Value(1), brush5a.Value(2));
fprintf('  Brush B: Range [%.1f, %.1f], Value [%.1f, %.1f]\n', ...
    brush5b.Min, brush5b.Max, brush5b.Value(1), brush5b.Value(2));
fprintf('Try interacting with both brushes independently!\n\n');

%% Test 6: Property Validation
% Test property validation and error handling

fig6 = uifigure('Position', [350 350 600 300], 'Name', 'Test 6: Validation');
brush6 = d3Brush(fig6, 'Position', [50 50 500 200]);

fprintf('Test 6: Property validation\n');

% Test automatic sorting
fprintf('  Setting Value = [80, 20] (reversed)...\n');
brush6.Value = [80, 20];
fprintf('  Result: [%.1f, %.1f] (automatically sorted)\n', brush6.Value(1), brush6.Value(2));

% Test clamping
fprintf('  Setting Value = [-10, 120] (out of range)...\n');
brush6.Value = [-10, 120];
fprintf('  Result: [%.1f, %.1f] (clamped to [%.1f, %.1f])\n', ...
    brush6.Value(1), brush6.Value(2), brush6.Min, brush6.Max);

% Test invalid input
fprintf('  Trying to set Value = 50 (single value)...\n');
try
    brush6.Value = 50;
    fprintf('  ERROR: Should have thrown exception!\n');
catch ME
    fprintf('  Correctly threw error: %s\n', ME.identifier);
end

fprintf('Validation tests complete!\n\n');

%% Test 7: Dynamic Range Updates
% Test changing Min/Max with active selection

fig7 = uifigure('Position', [400 400 600 300], 'Name', 'Test 7: Dynamic Range');
brush7 = d3Brush(fig7, 'Position', [50 50 500 200]);

brush7.Min = 0;
brush7.Max = 100;
brush7.Value = [30, 70];

fprintf('Test 7: Dynamic range updates\n');
fprintf('  Initial: Min=%.1f, Max=%.1f, Value=[%.1f, %.1f]\n', ...
    brush7.Min, brush7.Max, brush7.Value(1), brush7.Value(2));

pause(2);
fprintf('  Changing Max to 50...\n');
brush7.Max = 50;
fprintf('  New range: Min=%.1f, Max=%.1f\n', brush7.Min, brush7.Max);

pause(2);
fprintf('  Adjusting Value to fit new range...\n');
brush7.Value = [min(brush7.Value(1), brush7.Max), min(brush7.Value(2), brush7.Max)];
fprintf('  New Value: [%.1f, %.1f]\n', brush7.Value(1), brush7.Value(2));

fprintf('Dynamic range test complete!\n\n');

%% Test 8: Stress Test - Rapid Updates
% Test component stability with rapid programmatic updates

fig8 = uifigure('Position', [450 450 600 300], 'Name', 'Test 8: Stress Test');
brush8 = d3Brush(fig8, 'Position', [50 50 500 200]);

fprintf('Test 8: Stress test - rapid updates\n');
fprintf('Performing 50 rapid value updates...\n');

tic;
for i = 1:50
    startVal = randi([0, 50]);
    endVal = randi([51, 100]);
    brush8.Value = [startVal, endVal];
    pause(0.05);  % 50ms between updates
end
elapsedTime = toc;

fprintf('Completed 50 updates in %.2f seconds\n', elapsedTime);
fprintf('Average update time: %.2f ms\n', (elapsedTime / 50) * 1000);
fprintf('Final Value: [%.1f, %.1f]\n\n', brush8.Value(1), brush8.Value(2));

%% Test 9: Integration with MATLAB UI Components
% Test brush component alongside standard MATLAB UI components

fig9 = uifigure('Position', [500 500 600 400], 'Name', 'Test 9: UI Integration');

% Create brush
brush9 = d3Brush(fig9, 'Position', [50 200 500 150]);
brush9.Min = 0;
brush9.Max = 100;
brush9.Value = [25, 75];

% Create standard UI components
minLabel = uilabel(fig9, 'Position', [50 160 100 22], 'Text', 'Min Value:');
minField = uieditfield(fig9, 'numeric', 'Position', [150 160 100 22], 'Value', 0);

maxLabel = uilabel(fig9, 'Position', [300 160 100 22], 'Text', 'Max Value:');
maxField = uieditfield(fig9, 'numeric', 'Position', [400 160 100 22], 'Value', 100);

snapLabel = uilabel(fig9, 'Position', [50 120 100 22], 'Text', 'Snap Interval:');
snapField = uieditfield(fig9, 'numeric', 'Position', [150 120 100 22], 'Value', 5);

applyBtn = uibutton(fig9, 'Position', [300 120 100 22], 'Text', 'Apply Settings');

valueLabel = uilabel(fig9, 'Position', [50 80 500 22], ...
    'Text', sprintf('Current Selection: [%.1f, %.1f]', brush9.Value(1), brush9.Value(2)));

% Set up callbacks
applyBtn.ButtonPushedFcn = @(btn, event) applySettings();
brush9.ValueChangedFcn = @(src, event) updateLabel();

    function applySettings()
        brush9.Min = minField.Value;
        brush9.Max = maxField.Value;
        brush9.SnapInterval = snapField.Value;
        fprintf('Settings applied: Min=%.1f, Max=%.1f, Snap=%.1f\n', ...
            brush9.Min, brush9.Max, brush9.SnapInterval);
    end

    function updateLabel()
        valueLabel.Text = sprintf('Current Selection: [%.1f, %.1f]', ...
            brush9.Value(1), brush9.Value(2));
    end

fprintf('Test 9: UI integration demo created\n');
fprintf('Try:\n');
fprintf('  1. Drag the brush\n');
fprintf('  2. Modify the settings below\n');
fprintf('  3. Click "Apply Settings"\n\n');

%% Cleanup All Test Figures
% Close all test figures (optional)

fprintf('\nTo close all test figures, run:\n');
fprintf('  close all force\n\n');
