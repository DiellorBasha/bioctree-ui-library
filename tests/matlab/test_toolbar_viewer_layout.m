% Simple test replicating ManifoldController's toolbar + viewer layout
% Use this for debugging layout issues

% Add paths
testDir = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(testDir));
addpath(fullfile(projectRoot, 'controllers'));

% Create figure
fig = uifigure('Position', [100 100 1000 600], 'Name', 'Toolbar + Viewer Layout Test');

% Create grid layout - two columns
grid = uigridlayout(fig);
grid.RowHeight = {'1x'};
           grid.ColumnWidth = {60, '1x'};  % 60px toolbar, rest for viewer

% Create brush context
context = ManifoldBrushContext();

% Create toolbar in column 1
toolbar = ManifoldBrushToolbar(grid, 'Context', context);
toolbar.Layout.Row = 1;
toolbar.Layout.Column = 1;

% Create viewer3d directly in column 2
viewer = viewer3d(grid, ...
    "BackgroundColor", [0 0 0], ...
    "BackgroundGradient", "off", ...
    "RenderingQuality", "high");
viewer.Layout.Row = 1;
viewer.Layout.Column = 2;

% Set default camera
viewer.Mode.Default.CameraVector = [-1 -1 1];

% Optional: Add a simple mesh for testing
% Uncomment these lines if you want to test with a sphere
% [X, Y, Z] = sphere(50);
% V = [X(:), Y(:), Z(:)];
% F = convhull(V);
% tri = triangulation(F, V);
% surf = images.ui.graphics3d.Surface(viewer, 'Data', tri, 'Color', [0.8 0.8 0.8]);

fprintf('Layout created successfully!\n');
fprintf('Toolbar Position: [%s]\n', num2str(toolbar.Position));
fprintf('Viewer Position: [%s]\n', num2str(viewer.Position));
fprintf('Active brush: %s\n', toolbar.ActiveBrush);

fprintf('\nClick toolbar buttons to test interaction.\n');
fprintf('Close figure to exit.\n');

% Keep window open
waitfor(fig);
