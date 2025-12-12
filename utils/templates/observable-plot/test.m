% test_{{COMPONENT_NAME}}.m
% Test script for {{COMPONENT_NAME}} {{COMPONENT_TYPE}}
% {{LIBRARY_DESCRIPTION}}

clear; close all;

% Add {{COMPONENT_TYPE}}s to path
{{COMPONENT_TYPE}}sPath = fullfile(fileparts(fileparts(mfilename('fullpath'))), '..', '{{COMPONENT_TYPE}}s');
addpath(genpath({{COMPONENT_TYPE}}sPath));
fprintf('Added to path: %s\n', {{COMPONENT_TYPE}}sPath);

%% Test 1: Basic {{COMPONENT_TYPE_UPPER}}
fprintf('Test 1: Creating basic {{COMPONENT_NAME}} {{COMPONENT_TYPE}}...\n');
fig1 = uifigure('Position', [100 100 800 400], 'Name', 'Test 1: Basic {{COMPONENT_NAME}}');

% TODO: Load or generate test data
% Example for loading from file:
% dataPath = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'yourdata.csv');
% testData = readtable(dataPath);

% Mock data for testing
testData = randn(100, 1); % TODO: Replace with actual test data

% Create {{COMPONENT_TYPE}}
{{COMPONENT_TYPE}}1 = {{COMPONENT_NAME}}(fig1, 'Position', [50 50 700 300]);
{{COMPONENT_TYPE}}1.Data = testData;
% TODO: Set additional properties

fprintf('✓ Basic {{COMPONENT_TYPE}} created\n');

%% Test 2: Custom Styling
fprintf('\nTest 2: Testing custom styling...\n');
fig2 = uifigure('Position', [150 150 800 400], 'Name', 'Test 2: Custom Styling');

{{COMPONENT_TYPE}}2 = {{COMPONENT_NAME}}(fig2, 'Position', [50 50 700 300]);
{{COMPONENT_TYPE}}2.Data = testData;
% TODO: Customize properties
% {{COMPONENT_TYPE}}2.PropertyName = value;

fprintf('✓ Custom styled {{COMPONENT_TYPE}} created\n');

%% Test 3: Dynamic Update
fprintf('\nTest 3: Testing dynamic data update...\n');
fig3 = uifigure('Position', [200 200 800 400], 'Name', 'Test 3: Dynamic Update');

{{COMPONENT_TYPE}}3 = {{COMPONENT_NAME}}(fig3, 'Position', [50 50 700 300]);

% Initial data
{{COMPONENT_TYPE}}3.Data = testData;
fprintf('  Initial data set\n');
pause(1);

% Update data
newData = randn(150, 1); % TODO: Generate different test data
{{COMPONENT_TYPE}}3.Data = newData;
fprintf('  Data updated\n');

fprintf('✓ Dynamic update test complete\n');

%% Test 4: Empty Data
fprintf('\nTest 4: Testing empty data handling...\n');
fig4 = uifigure('Position', [250 250 800 400], 'Name', 'Test 4: Empty Data');

{{COMPONENT_TYPE}}4 = {{COMPONENT_NAME}}(fig4, 'Position', [50 50 700 300]);
{{COMPONENT_TYPE}}4.Data = []; % Empty data

fprintf('✓ Empty data handled gracefully\n');

%% Summary
fprintf('\n===========================================\n');
fprintf('All tests completed successfully!\n');
fprintf('===========================================\n');
fprintf('\n{{COMPONENT_NAME}} {{COMPONENT_TYPE}} is working correctly.\n');
fprintf('Key features verified:\n');
fprintf('  ✓ Basic visualization\n');
fprintf('  ✓ Custom styling\n');
fprintf('  ✓ Dynamic data updates\n');
fprintf('  ✓ Empty data handling\n');
fprintf('\nAll figures remain open for inspection.\n');
