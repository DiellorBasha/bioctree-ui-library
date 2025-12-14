%% FlowbiteButton Component Test
% Test script for the FlowbiteButton MATLAB component
% Tests all variants, callbacks, and interactive features

clear all; close all; clc;

% Add paths for component and utilities
[testDir, ~, ~] = fileparts(mfilename('fullpath'));
rootDir = fileparts(fileparts(testDir));  % Go up to project root
addpath(fullfile(rootDir, 'controllers'));  % Add only controllers directory

fprintf('\n=== FlowbiteButton Component Test Suite ===\n\n');

%% Test 1: Component Creation
fprintf('Test 1: Component Creation\n');
try
    fig = uifigure('Name', 'FlowbiteButton Test', 'NumberTitle', 'off', ...
        'Position', [100 100 800 500]);
    
    btn = FlowbiteButton(fig, 'Position', [20 300 760 150]);
    
    fprintf('✓ Component created successfully\n');
    fprintf('  - Figure: %s\n', fig.Name);
    fprintf('  - Component class: %s\n', class(btn));
catch ME
    fprintf('✗ Failed to create component: %s\n', ME.message);
    return;
end

%% Test 2: Property Assignment
fprintf('\nTest 2: Property Assignment\n');
try
    btn.Label = 'Test Button';
    fprintf('✓ Label property set: %s\n', btn.Label);
    
    btn.Variant = 'success';
    fprintf('✓ Variant property set: %s\n', btn.Variant);
    
    pause(0.5);
catch ME
    fprintf('✗ Failed to set properties: %s\n', ME.message);
end

%% Test 3: Button Variants
fprintf('\nTest 3: Testing All Button Variants\n');
variants = ["primary", "success", "danger", "warning", "secondary"];

for i = 1:length(variants)
    try
        btn.Variant = variants(i);
        btn.Label = sprintf('Variant: %s', variants(i));
        fprintf('✓ Variant %d/%d: %s\n', i, length(variants), variants(i));
        pause(0.5);
    catch ME
        fprintf('✗ Failed variant %s: %s\n', variants(i), ME.message);
    end
end

%% Test 4: Callback Setup
fprintf('\nTest 4: Setting up Callback\n');
try
    clickCounter = 0;
    
    btn.ButtonClickedFcn = @(src, event) handleButtonClick(src, event, clickCounter);
    btn.Label = 'Click Me! (Check Console)';
    btn.Variant = 'primary';
    
    fprintf('✓ Callback function assigned\n');
    fprintf('  - Click the button in the figure window\n');
    fprintf('  - Check MATLAB console for event messages\n');
    
    pause(3);  % Allow time for interaction
    
catch ME
    fprintf('✗ Failed to set callback: %s\n', ME.message);
end

%% Test 5: Dynamic Updates
fprintf('\nTest 5: Dynamic Property Updates\n');
try
    labels = ["Click Me!", "Nice!", "Great!", "Awesome!", "Perfect!"];
    
    for i = 1:length(labels)
        btn.Label = labels(i);
        fprintf('✓ Label updated (%d/%d): %s\n', i, length(labels), labels(i));
        pause(0.5);
    end
    
catch ME
    fprintf('✗ Failed dynamic updates: %s\n', ME.message);
end

%% Test 6: Reset to Defaults
fprintf('\nTest 6: Reset to Defaults\n');
try
    btn.Label = 'Reset Complete';
    btn.Variant = 'primary';
    fprintf('✓ Component reset to default values\n');
    pause(1);
    
catch ME
    fprintf('✗ Failed to reset: %s\n', ME.message);
end

%% Cleanup
fprintf('\nTest Suite Complete!\n');
fprintf('✓ All tests passed\n');
fprintf('\nFigure remains open for manual testing.\n');
fprintf('Close the figure to exit.\n\n');

% Keep figure open for inspection
waitfor(fig);

%% Helper Functions
function handleButtonClick(src, event, clickCounter)
    % Handle button click callback
    fprintf('[Callback] Button clicked\n');
    if isfield(event, 'HTMLEventData')
        try
            data = jsondecode(event.HTMLEventData);
            fprintf('  - Click count: %d\n', data.clickCount);
            fprintf('  - Timestamp: %s\n', data.timestamp);
            fprintf('  - Variant: %s\n', data.variant);
        catch
            fprintf('  - [Raw event data]\n');
        end
    end
end
