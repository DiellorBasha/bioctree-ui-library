% Test toolbar button clicks
% This test verifies that clicking toolbar buttons works without warnings

% Add paths
testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(testDir));
addpath(fullfile(projectRoot, 'controllers'));

fprintf('Creating toolbar...\n');
fig = uifigure('Position', [100 100 400 600]);
context = ManifoldBrushContext();

toolbar = ManifoldBrushToolbar(fig, 'Position', [10 10 80 580], 'Context', context);

% Give it time to render
drawnow;
pause(1);

fprintf('Initial Active Brush: %s\n', toolbar.ActiveBrush);

% Simulate clicking by changing ActiveBrush
fprintf('\nSimulating button clicks by changing ActiveBrush property...\n');

fprintf('Clicking delta brush...\n');
toolbar.ActiveBrush = 'delta';
pause(0.5);
fprintf('Active Brush: %s\n', toolbar.ActiveBrush);

fprintf('Clicking graph brush...\n');
toolbar.ActiveBrush = 'graph';
pause(0.5);
fprintf('Active Brush: %s\n', toolbar.ActiveBrush);

fprintf('Clicking spectral brush...\n');
toolbar.ActiveBrush = 'spectral';
pause(0.5);
fprintf('Active Brush: %s\n', toolbar.ActiveBrush);

fprintf('\nTest complete! Check for warnings above.\n');
fprintf('If no "unsupported functionality" warnings, test PASSED!\n');
