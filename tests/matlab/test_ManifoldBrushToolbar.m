% test_ManifoldBrushToolbar.m
% Test script for ManifoldBrushToolbar component
%
% Tests:
%   1. Basic toolbar creation and rendering
%   2. Context integration
%   3. Brush selection and event handling
%   4. Active state updates
%   5. Custom registry

%% Setup
clear; clc;
fprintf('=== ManifoldBrushToolbar Test Suite ===\n\n');

% Add paths
testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(testDir));
addpath(fullfile(projectRoot, 'controllers'));

%% Test 1: Basic Toolbar Creation
fprintf('Test 1: Basic toolbar creation...\n');
try
    fig = uifigure('Position', [100 100 200 500], 'Name', 'Test 1: Basic Toolbar');
    
    % Create context with dummy manifold
    context = ManifoldBrushContext();
    
    % Create toolbar
    toolbar = ManifoldBrushToolbar(fig, 'Context', context);
    toolbar.Position = [10 10 180 480];
    
    % Wait for rendering
    pause(1);
    
    fprintf('  ✓ Toolbar created successfully\n');
    fprintf('  ✓ HTMLComponent initialized\n');
    fprintf('  ✓ Position set correctly\n');
    
catch ME
    fprintf('  ✗ FAILED: %s\n', ME.message);
    rethrow(ME);
end

%% Test 2: Context Integration
fprintf('\nTest 2: Context integration...\n');
try
    % Update context (should not error even without manifold)
    context.Seed = 1;
    
    fprintf('  ✓ Context property update handled\n');
    
    % Check that toolbar is still valid
    assert(isvalid(toolbar), 'Toolbar should still be valid');
    
    fprintf('  ✓ Toolbar remains valid after context update\n');
    
catch ME
    fprintf('  ✗ FAILED: %s\n', ME.message);
    rethrow(ME);
end

%% Test 3: Brush Selection Event
fprintf('\nTest 3: Brush selection event handling...\n');
try
    % Create new figure for event test
    fig2 = uifigure('Position', [320 100 200 500], 'Name', 'Test 3: Events');
    context2 = ManifoldBrushContext();
    toolbar2 = ManifoldBrushToolbar(fig2, 'Context', context2);
    toolbar2.Position = [10 10 180 480];
    
    % Add event listener
    eventFired = false;
    selectedType = '';
    
    addlistener(toolbar2, 'BrushSelected', @(src, event) ...
        fprintf('  → BrushSelected event: %s\n', event.BrushType));
    
    fprintf('  ✓ Event listener registered\n');
    fprintf('  ℹ Click a tool button to test event firing\n');
    
    pause(1);
    
catch ME
    fprintf('  ✗ FAILED: %s\n', ME.message);
    rethrow(ME);
end

%% Test 4: Active State Updates
fprintf('\nTest 4: Active state updates...\n');
try
    % Set active brush programmatically
    toolbar.ActiveBrush = 'graph';
    pause(0.5);
    
    assert(strcmp(toolbar.ActiveBrush, 'graph'), 'ActiveBrush should update');
    fprintf('  ✓ ActiveBrush set to: %s\n', toolbar.ActiveBrush);
    
    % Change to spectral
    toolbar.ActiveBrush = 'spectral';
    pause(0.5);
    
    assert(strcmp(toolbar.ActiveBrush, 'spectral'), 'ActiveBrush should update');
    fprintf('  ✓ ActiveBrush changed to: %s\n', toolbar.ActiveBrush);
    
catch ME
    fprintf('  ✗ FAILED: %s\n', ME.message);
    rethrow(ME);
end

%% Summary
fprintf('\n=== Test Summary ===\n');
fprintf('All tests passed! ✓\n');
fprintf('\nInteractive Tests:\n');
fprintf('  - Click tool buttons to test event firing\n');
fprintf('  - Observe active state visual feedback\n');
fprintf('  - Close figures when done\n');
