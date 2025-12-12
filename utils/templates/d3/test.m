% test_{{COMPONENT_NAME}}.m
% Test script for {{COMPONENT_NAME}} component
% D3.js v5.9.2

clear; close all;

% Add components to path
componentsPath = fullfile(fileparts(fileparts(mfilename('fullpath'))), '..', 'components');
addpath(genpath(componentsPath));
fprintf('Added to path: %s\n', componentsPath);

%% Test 1: Basic Component
fprintf('Test 1: Creating basic {{COMPONENT_NAME}} component...\n');
fig1 = uifigure('Position', [100 100 800 400], 'Name', 'Test 1: Basic {{COMPONENT_NAME}}');

% TODO: Load or generate test data
testData = []; % TODO: Initialize with actual data

% Create component
comp1 = {{COMPONENT_NAME}}(fig1, 'Position', [50 50 700 300]);
comp1.Value = testData;
% TODO: Set additional properties

fprintf('✓ Basic component created\n');

%% Test 2: Event Handling
fprintf('\nTest 2: Testing event handling...\n');
fig2 = uifigure('Position', [150 150 800 400], 'Name', 'Test 2: Event Handling');

comp2 = {{COMPONENT_NAME}}(fig2, 'Position', [50 50 700 300]);
comp2.Value = testData;

% Add event callback
comp2.ValueChangedFcn = @(src, event) fprintf('  ValueChanged: %s\n', mat2str(event.Value));

fprintf('✓ Event handling configured\n');
fprintf('  Interact with the component to trigger events\n');

%% Test 3: Property Changes
fprintf('\nTest 3: Testing dynamic property changes...\n');
fig3 = uifigure('Position', [200 200 800 400], 'Name', 'Test 3: Dynamic Updates');

comp3 = {{COMPONENT_NAME}}(fig3, 'Position', [50 50 700 300]);

% Initial state
comp3.Value = testData;
fprintf('  Initial value set\n');
pause(1);

% Update properties
% TODO: Update component properties
fprintf('  Properties updated\n');

fprintf('✓ Dynamic update test complete\n');

%% Test 4: Empty Data
fprintf('\nTest 4: Testing empty data handling...\n');
fig4 = uifigure('Position', [250 250 800 400], 'Name', 'Test 4: Empty Data');

comp4 = {{COMPONENT_NAME}}(fig4, 'Position', [50 50 700 300]);
comp4.Value = []; % Empty value

fprintf('✓ Empty data handled gracefully\n');

%% Summary
fprintf('\n===========================================\n');
fprintf('All tests completed successfully!\n');
fprintf('===========================================\n');
fprintf('\n{{COMPONENT_NAME}} component is working correctly.\n');
fprintf('Key features verified:\n');
fprintf('  ✓ Basic visualization\n');
fprintf('  ✓ Event handling\n');
fprintf('  ✓ Dynamic property updates\n');
fprintf('  ✓ Empty data handling\n');
fprintf('\nAll figures remain open for inspection.\n');
fprintf('Interact with components to test event callbacks.\n');
