%% FlowbiteButton Communication Test
% Test that button clicks properly communicate from JavaScript to MATLAB

clear all; close all; clc;

% Setup paths
[testFile, ~, ~] = fileparts(mfilename('fullpath'));
projRoot = fileparts(fileparts(testFile));
addpath(fullfile(projRoot, 'controllers'));

fprintf('\n=== FlowbiteButton Communication Test ===\n\n');

%% Test: Button Click Communication
fprintf('Creating button component...\n');

try
    fig = uifigure('Name', 'Communication Test', 'NumberTitle', 'off', ...
        'Position', [100 100 600 300]);
    
    btn = FlowbiteButton(fig, 'Position', [50 100 500 150]);
    btn.Label = 'Click to Test Communication';
    btn.Variant = 'success';
    
    % Set up callback with detailed logging
    clickLog = {};
    clickCounter = 0;
    
    btn.ButtonClickedFcn = @(src, event) handleClick(src, event, clickLog);
    
    fprintf('✓ Button created successfully\n');
    fprintf('✓ Callback registered\n');
    fprintf('\nButton is ready. Click it 3-5 times to test communication.\n');
    fprintf('Watch the MATLAB console for click events.\n');
    fprintf('Close the figure when done testing.\n\n');
    
    % Wait for figure to close
    waitfor(fig);
    
    fprintf('\n=== Communication Test Results ===\n');
    fprintf('Total clicks recorded: %d\n', length(clickLog));
    
    if length(clickLog) > 0
        fprintf('\n✓ Button communication WORKING!\n');
        fprintf('Click events received:\n');
        for i = 1:length(clickLog)
            fprintf('  Click %d: %s\n', i, clickLog{i});
        end
    else
        fprintf('\n✗ No click events received\n');
        fprintf('Debugging tips:\n');
        fprintf('  1. Open browser developer console (F12)\n');
        fprintf('  2. Look for [FlowbiteButton] messages\n');
        fprintf('  3. Check for JavaScript errors\n');
    end
    
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    disp(ME);
end

%% Helper function
function handleClick(src, event, clickLog)
    try
        % Extract click data
        if isfield(event, 'HTMLEventData') && ~isempty(event.HTMLEventData)
            data = jsondecode(event.HTMLEventData);
            msg = sprintf('Count: %d, Time: %s', data.clickCount, data.timestamp);
        else
            msg = 'Event received (no data)';
        end
        
        % Log the click
        clickLog{end+1} = msg;
        fprintf('[%s] %s\n', datetime('now', 'Format', 'HH:mm:ss.SSS'), msg);
        
    catch ME
        fprintf('Error in callback: %s\n', ME.message);
    end
end
