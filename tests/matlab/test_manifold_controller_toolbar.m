% Test ManifoldController with ManifoldBrushToolbar
% This test verifies that the toolbar appears on the left of the viewer

% Add paths
testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(testDir));
addpath(fullfile(projectRoot, 'controllers'));

fprintf('===========================================\n');
fprintf('Testing ManifoldController with Toolbar\n');
fprintf('===========================================\n\n');

fprintf('Creating figure...\n');
fig = uifigure('Position', [100 100 1000 600], 'Name', 'ManifoldController Test');

fprintf('Creating ManifoldController...\n');
mc = ManifoldController(fig);

% Wait for UI to render
drawnow;
pause(0.5);

fprintf('\nManifoldController created successfully!\n');
fprintf('Toolbar Position: [%s]\n', num2str(mc.BrushToolbar.Position));
fprintf('Viewer Position: [%s]\n', num2str(mc.Viewer.Position));
fprintf('Active brush: %s\n', mc.BrushToolbar.ActiveBrush);

fprintf('\n===========================================\n');
fprintf('You should see:\n');
fprintf('  - Narrow toolbar on the left (3 buttons)\n');
fprintf('  - Large viewer panel on the right (black)\n');
fprintf('===========================================\n');

fprintf('\nWindow will stay open. Close figure to exit.\n');
waitfor(fig);
fprintf('Figure closed. Test complete.\n');
