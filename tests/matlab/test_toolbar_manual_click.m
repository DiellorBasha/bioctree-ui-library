% Manual test for toolbar button clicks
% This keeps the window open so you can click buttons in the UI

% Add paths
testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(testDir));
addpath(fullfile(projectRoot, 'controllers'));

fprintf('Creating toolbar...\n');
fig = uifigure('Position', [100 100 800 600]);
root = uigridlayout(fig);
root.RowHeight = {'1x'};
root.ColumnWidth = {60, '1x'};

context = ManifoldBrushContext();

toolbar = ManifoldBrushToolbar(root, 'Context', context);
toolbar.Layout.Column = 1;

% Add a callback to see when clicks happen
toolbar.ValueChangedFcn = @(src, event) fprintf('Button clicked! New brush: %s\n', src.ActiveBrush);

% Add a panel to visualize the grid
testPanel = uipanel(root, 'Title', 'Click buttons on left', 'BackgroundColor', [0.2 0.2 0.2]);
testPanel.Layout.Column = 2;

drawnow;

fprintf('\n===========================================\n');
fprintf('Window is ready!\n');
fprintf('Initial Active Brush: %s\n', toolbar.ActiveBrush);
fprintf('===========================================\n');
fprintf('MANUALLY CLICK the toolbar buttons on the left.\n');
fprintf('Watch the command window for:\n');
fprintf('  1. "Button clicked!" messages\n');
fprintf('  2. Any warnings about "unsupported functionality"\n');
fprintf('===========================================\n');
fprintf('\nPress Ctrl+C in command window to exit, or close the figure.\n\n');

% Keep running until figure is closed
waitfor(fig);
fprintf('Figure closed. Test complete.\n');
