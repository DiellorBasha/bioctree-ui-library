% Quick test for toolbar in grid layout

% Add paths
testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(testDir));
addpath(fullfile(projectRoot, 'controllers'));

fig = uifigure('Position', [100 100 800 600]);
root = uigridlayout(fig);
root.RowHeight = {'1x'};
root.ColumnWidth = {60, '1x'};

context = ManifoldBrushContext();

toolbar = ManifoldBrushToolbar(root, 'Context', context);
toolbar.Layout.Column = 1;

% Give it a moment to render and force layout
drawnow;
pause(1);

fprintf('\nToolbar Position: [%s]\n', num2str(toolbar.Position));
fprintf('Active Brush: %s\n', toolbar.ActiveBrush);

% Add a panel to see if grid is working
testPanel = uipanel(root, 'Title', 'Test Panel', 'BackgroundColor', 'red');
testPanel.Layout.Column = 2;

drawnow;
pause(0.5);

fprintf('\nAfter adding test panel:\n');
fprintf('Toolbar Position: [%s]\n', num2str(toolbar.Position));

% Try changing active brush
fprintf('\nChanging to delta brush...\n');
toolbar.ActiveBrush = 'delta';
pause(0.5);

fprintf('Active Brush: %s\n', toolbar.ActiveBrush);
fprintf('\nIf you see 3 tool buttons (point, graph, wave), test passed!\n');
