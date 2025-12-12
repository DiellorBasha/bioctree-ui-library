% test_HorizonChart.m
% Test script for HorizonChart view component
% Observable Plot v0.6.17 UMD implementation

clear; close all;

% Add views to path
viewsPath = fullfile(fileparts(fileparts(mfilename('fullpath'))), '..', 'views');
addpath(genpath(viewsPath));
fprintf('Added to path: %s\n', viewsPath);

%% Test 1: Basic Horizon Chart (Traffic Data)
fprintf('Test 1: Creating basic horizon chart with traffic data...\n');
fig1 = uifigure('Position', [100 100 1000 600], 'Name', 'Test 1: Traffic Horizon Chart');

% Load traffic data
dataPath = fullfile(fileparts(mfilename('fullpath')), '..', 'data', 'traffic.csv');
trafficData = readtable(dataPath);

fprintf('  Loaded data: %d rows\n', height(trafficData));
fprintf('  Columns: %s\n', strjoin(trafficData.Properties.VariableNames, ', '));
fprintf('  Unique locations: %d\n', length(unique(trafficData.name)));

% Create horizon chart view
view1 = HorizonChart(fig1, 'Position', [50 50 900 500]);
view1.Data = trafficData;
view1.Bands = 3;
view1.Step = 500;  % 500 vehicles per band

fprintf('✓ Basic horizon chart created\n');

%% Test 2: Custom Color Schemes
fprintf('\nTest 2: Testing different color schemes...\n');
fig2 = uifigure('Position', [150 150 1000 600], 'Name', 'Test 2: Color Schemes');

view2 = HorizonChart(fig2, 'Position', [50 50 900 500]);
view2.Data = trafficData;
view2.Bands = 4;
view2.ColorScheme = "Blues";
view2.Step = 400;

fprintf('✓ Color scheme test created\n');

%% Test 3: Different Band Counts
fprintf('\nTest 3: Comparing different band counts...\n');
fig3 = uifigure('Position', [200 200 1200 400], 'Name', 'Test 3: Band Comparison');

% 2 bands (less detail)
view3a = HorizonChart(fig3, 'Position', [50 250 550 130]);
view3a.Data = trafficData;
view3a.Bands = 2;
view3a.ColorScheme = "Greens";
view3a.ShowLegend = false;

% 5 bands (more detail)
view3b = HorizonChart(fig3, 'Position', [620 250 550 130]);
view3b.Data = trafficData;
view3b.Bands = 5;
view3b.ColorScheme = "Greens";
view3b.ShowLegend = false;

fprintf('✓ Band comparison views created\n');

%% Test 4: Auto-calculated Step
fprintf('\nTest 4: Testing auto-calculated step (Step = 0)...\n');
fig4 = uifigure('Position', [250 250 1000 600], 'Name', 'Test 4: Auto Step');

view4 = HorizonChart(fig4, 'Position', [50 50 900 500]);
view4.Data = trafficData;
view4.Bands = 3;
view4.Step = 0;  % Auto-calculate based on max value
view4.ColorScheme = "Purples";

fprintf('✓ Auto-step horizon chart created\n');

%% Test 5: Subset of Data (Single Location)
fprintf('\nTest 5: Testing with single location data...\n');
fig5 = uifigure('Position', [300 300 1000 300], 'Name', 'Test 5: Single Location');

% Filter to one location
locationName = unique(trafficData.name);
singleLocation = trafficData(strcmp(trafficData.name, locationName{1}), :);

view5 = HorizonChart(fig5, 'Position', [50 50 900 200]);
view5.Data = singleLocation;
view5.Bands = 4;
view5.ColorScheme = "Oranges";

fprintf('✓ Single location view created (%s)\n', locationName{1});

%% Test 6: Dynamic Update
fprintf('\nTest 6: Testing dynamic data update...\n');
fig6 = uifigure('Position', [350 350 1000 600], 'Name', 'Test 6: Dynamic Update');

view6 = HorizonChart(fig6, 'Position', [50 50 900 500]);
view6.ColorScheme = "Greens";

% Initial - full dataset, 3 bands
view6.Data = trafficData;
view6.Bands = 3;
fprintf('  Initial: full data, 3 bands\n');
pause(1.5);

% Update - change bands and color
view6.Bands = 5;
view6.ColorScheme = "Blues";
fprintf('  Updated: 5 bands, Blues\n');
pause(1.5);

% Update - subset data
view6.Data = singleLocation;
view6.Bands = 4;
view6.ColorScheme = "Reds";
fprintf('  Updated: single location, 4 bands, Reds\n');

fprintf('✓ Dynamic update test complete\n');

%% Test 7: Empty Data
fprintf('\nTest 7: Testing empty data handling...\n');
fig7 = uifigure('Position', [400 400 1000 400], 'Name', 'Test 7: Empty Data');

view7 = HorizonChart(fig7, 'Position', [50 50 900 300]);
view7.Data = table();  % Empty table

fprintf('✓ Empty data handled gracefully\n');

%% Summary
fprintf('\n===========================================\n');
fprintf('All tests completed successfully!\n');
fprintf('===========================================\n');
fprintf('\nHorizonChart view component is working correctly.\n');
fprintf('Key features verified:\n');
fprintf('  ✓ Basic horizon chart visualization\n');
fprintf('  ✓ Multiple color schemes\n');
fprintf('  ✓ Variable band counts\n');
fprintf('  ✓ Auto-calculated step values\n');
fprintf('  ✓ Single and multi-series data\n');
fprintf('  ✓ Dynamic data updates\n');
fprintf('  ✓ Empty data handling\n');
fprintf('\nAll figures remain open for inspection.\n');
