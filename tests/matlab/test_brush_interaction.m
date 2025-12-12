% Test script to demonstrate d3Brush interaction and value updates
% Run this script and interact with the brush to see updates in real-time

clear; clc;

% Add component to path
addpath(genpath('controllers'));

% Create figure
fig = uifigure('Position', [100 100 700 500], 'Name', 'd3Brush Interaction Test');

% Create brush
brush = d3Brush(fig, 'Position', [50 300 600 150]);
brush.Min = 0;
brush.Max = 100;
brush.SnapInterval = 5;
brush.Value = [20, 80];

% Create display labels
titleLbl = uilabel(fig, ...
    'Position', [50 460 600 30], ...
    'Text', 'Drag the brush handles and watch the updates below:', ...
    'FontSize', 14, ...
    'FontWeight', 'bold');

currentLbl = uilabel(fig, ...
    'Position', [50 250 600 40], ...
    'Text', sprintf('Current Value: [%.0f, %.0f]', brush.Value(1), brush.Value(2)), ...
    'FontSize', 16, ...
    'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center');

statusLbl = uilabel(fig, ...
    'Position', [50 200 600 30], ...
    'Text', 'Status: Ready', ...
    'FontSize', 12, ...
    'HorizontalAlignment', 'center');

% Event log area
logArea = uitextarea(fig, ...
    'Position', [50 50 600 140], ...
    'Value', {'Event Log:', ''}, ...
    'Editable', 'off');

% Helper function to add log entry
function addLog(msg)
    current = logArea.Value;
    current{end+1} = msg;
    % Keep only last 8 entries
    if length(current) > 9
        current = current(end-8:end);
    end
    logArea.Value = current;
    drawnow;
end

% Set up event callbacks
brush.BrushStartedFcn = @(src, ~) onBrushStarted();
brush.ValueChangingFcn = @(src, event) onValueChanging(event);
brush.ValueChangedFcn = @(src, event) onValueChanged(event);
brush.BrushEndedFcn = @(src, ~) onBrushEnded();

% Callback functions
function onBrushStarted()
    statusLbl.Text = '🟢 Status: Dragging...';
    statusLbl.FontColor = [0.2 0.6 0.2];
    addLog(sprintf('[%s] BrushStarted', datestr(now, 'HH:MM:SS')));
end

function onValueChanging(event)
    % This fires repeatedly during drag (throttled to ~50ms)
    statusLbl.Text = sprintf('↻ Dragging: [%.0f, %.0f]', event.Value(1), event.Value(2));
    statusLbl.FontColor = [0.9 0.5 0];
    % Only log occasionally to avoid spam
    persistent lastLog;
    if isempty(lastLog) || (now - lastLog) > 0.5/86400  % Log every 0.5 seconds
        addLog(sprintf('[%s] ValueChanging: [%.0f, %.0f]', ...
            datestr(now, 'HH:MM:SS'), event.Value(1), event.Value(2)));
        lastLog = now;
    end
end

function onValueChanged(event)
    % This fires once when you release the mouse
    newVal = event.Value;
    oldVal = event.PreviousValue;
    
    % Update display
    currentLbl.Text = sprintf('Current Value: [%.0f, %.0f]', newVal(1), newVal(2));
    currentLbl.FontColor = [0 0.5 0];
    
    statusLbl.Text = '✓ Status: Updated!';
    statusLbl.FontColor = [0 0.6 0];
    
    % Log the change
    addLog(sprintf('[%s] ValueChanged: [%.0f, %.0f] → [%.0f, %.0f]', ...
        datestr(now, 'HH:MM:SS'), oldVal(1), oldVal(2), newVal(1), newVal(2)));
    
    % Also verify the brush.Value property was updated
    fprintf('✓ brush.Value property updated to: [%.0f, %.0f]\n', brush.Value(1), brush.Value(2));
end

function onBrushEnded()
    addLog(sprintf('[%s] BrushEnded', datestr(now, 'HH:MM:SS')));
    
    % Reset status after a delay
    pause(1);
    if isvalid(statusLbl)
        statusLbl.Text = 'Status: Ready';
        statusLbl.FontColor = [0 0 0];
    end
    if isvalid(currentLbl)
        currentLbl.FontColor = [0 0 0];
    end
end

% Display instructions
fprintf('\n╔════════════════════════════════════════════════════════╗\n');
fprintf('║         d3Brush Interactive Test Started              ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');
fprintf('Initial brush.Value: [%.0f, %.0f]\n\n', brush.Value(1), brush.Value(2));
fprintf('INSTRUCTIONS:\n');
fprintf('  1. Drag a brush handle in the figure\n');
fprintf('  2. Watch the labels update in real-time\n');
fprintf('  3. Check the event log\n');
fprintf('  4. See console output when ValueChanged fires\n\n');
fprintf('Try these actions:\n');
fprintf('  • Drag the left handle\n');
fprintf('  • Drag the right handle\n');
fprintf('  • Drag the middle to move both\n\n');
fprintf('What to observe:\n');
fprintf('  📊 Visual: Brush position in figure\n');
fprintf('  📝 Labels: Current value and status\n');
fprintf('  📋 Log: Event history with timestamps\n');
fprintf('  💻 Console: Confirmation of brush.Value updates\n\n');
fprintf('Close the figure when done testing.\n\n');

% Wait for figure to close
waitfor(fig);

fprintf('\n✓ Test complete! Final brush value was: [%.0f, %.0f]\n\n', ...
    brush.Value(1), brush.Value(2));
