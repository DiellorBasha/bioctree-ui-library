%% Test TrajectoryBrush with Line ROI and accumulative animation
% This script demonstrates the trajectory brush functionality:
%   1. Load a manifold with spectral decomposition
%   2. Create EigenmodeController
%   3. Select trajectory brush - shows yellow Line ROI
%   4. Move Line ROI endpoints to set source and target
%   5. Animate the trajectory with accumulation and path trace

%% Setup
f = uifigure('Position',[100 100 1200 800]);

root = uigridlayout(f);
root.RowHeight = {'1x'};
root.ColumnWidth = {'1x'};

ec = EigenmodeController(root);
ec.Layout.Row = 1;
ec.Layout.Column = 1;

%% Load your mesh data
% Replace with your actual data
% ec.setMeshFromVerticesFaces(fs6.Manifold.Vertices, fs6.Manifold.Faces);
% ec.setEigenmodes(fs6.Lambda.lambda, fs6.Lambda.U);

% For testing, create dummy data:
fprintf('Creating test mesh...\n');
nVerts = 1000;
theta = linspace(0, 2*pi, nVerts);
V = [cos(theta)', sin(theta)', zeros(nVerts, 1)];
F = delaunay(V(:,1), V(:,2));
ec.setMeshFromVerticesFaces(V, F);

% Dummy spectral decomposition
Lambda = linspace(0, 1, 50)';
Modes = randn(nVerts, length(Lambda));
ec.setEigenmodes(Lambda, Modes);

%% Activate Trajectory Brush
fprintf('\n=== Activating Trajectory Brush ===\n');
fprintf('This will:\n');
fprintf('  - Hide the green Seed point annotation\n');
fprintf('  - Show a yellow Line ROI with two endpoints\n');
fprintf('  - You can drag the endpoints to set source and target\n\n');

ec.Manifold.BrushToolbar.ActiveBrush = 'trajectory';

fprintf('Yellow Line ROI is now visible.\n');
fprintf('Drag the line endpoints to set your source and target vertices.\n');
fprintf('Press any key when ready to animate...\n');
pause;

%% Start Trajectory Animation
fprintf('\n=== Starting Trajectory Animation ===\n');
fprintf('This will:\n');
fprintf('  - Compute shortest path between line endpoints\n');
fprintf('  - ACCUMULATE SpectralBrush at each path vertex\n');
fprintf('  - Draw cyan lines showing the traced path\n\n');

% Animate with 0.05 second intervals
ec.startTrajectoryAnimation(0.05);

fprintf('Animation started!\n');
fprintf('Watch:\n');
fprintf('  - Surface color ACCUMULATES along the path\n');
fprintf('  - Cyan lines trace the shortest path trajectory\n');
fprintf('  - Yellow line shows source->target connection\n\n');

%% Controls
fprintf('\n=== Interactive Controls ===\n');
fprintf('Stop animation:          ec.stopTrajectoryAnimation()\n');
fprintf('Move line endpoints:     Drag yellow line in viewer\n');
fprintf('Re-run animation:        ec.startTrajectoryAnimation(0.05)\n');
fprintf('Switch to other brush:   Click toolbar buttons\n');
fprintf('Return to trajectory:    ec.Manifold.BrushToolbar.ActiveBrush = ''trajectory''\n');

