# TrajectoryBrush - Line ROI Workflow

## Quick Start with Line ROI

```matlab
f = uifigure('Position',[100 100 1200 800]);
root = uigridlayout(f);
root.RowHeight = {'1x'};
root.ColumnWidth = {'1x'};

ec = EigenmodeController(root);
ec.Layout.Row = 1;
ec.Layout.Column = 1;

% Load your mesh
ec.setMeshFromVerticesFaces(fs6.Manifold.Vertices, fs6.Manifold.Faces);
ec.setEigenmodes(fs6.Lambda.lambda, fs6.Lambda.U);

% Activate trajectory brush (shows yellow Line ROI)
ec.Manifold.BrushToolbar.ActiveBrush = 'trajectory';

% Drag the yellow line endpoints to set source and target

% Start animation (accumulates SpectralBrush + traces path with cyan lines)
ec.startTrajectoryAnimation(0.05);
```

## UI Behavior

### When Trajectory Brush is Selected:
- **Green Seed annotation** → Hidden
- **Yellow Line ROI** → Shown between two random vertices
- User can **drag line endpoints** to set source and target
- Line endpoint changes automatically update the trajectory

### During Animation:
- **Surface colors** → Accumulated (summed) at each step, not replaced
- **Cyan lines** → Added between consecutive vertices showing the traced path
- **Yellow line** → Remains visible showing direct source-to-target connection

### Visual Elements:
- **Yellow Line** (thick): User-controlled trajectory endpoints
- **Cyan Lines** (thin): Animated path trace showing shortest path taken
- **Surface colors**: Accumulated SpectralBrush field along trajectory

## Key Differences from Point Annotation Workflow

| Aspect | Old (Point Annotations) | New (Line ROI) |
|--------|------------------------|----------------|
| **Source/Target** | Two separate green/red points | Single yellow line with two endpoints |
| **Setting Endpoints** | Programmatic (`Seed`, `Target` properties) | Interactive (drag line endpoints) |
| **Animation Effect** | Replaces field at each step | Accumulates (sums) field at each step |
| **Path Visualization** | None | Cyan lines trace the path |
| **UI Indicator** | Two colored points | One yellow line |

## Implementation Details

### Line ROI Initialization
```matlab
% In ManifoldController.initializeTrajectoryLine()
TrajectoryLine = images.ui.graphics.roi.Line(...
    'Parent', Viewer, ...
    'Position', [sourcePos; targetPos], ...  % 2x3 matrix
    'Color', 'yellow', ...
    'LineWidth', 3);
```

### Endpoint Tracking
```matlab
% Listeners on Line ROI
addlistener(TrajectoryLine, 'MovingROI', @onTrajectoryLineMoved);
addlistener(TrajectoryLine, 'ROIMoved', @onTrajectoryLineMoved);

% Endpoint positions
linePos = TrajectoryLine.Position;  % 2x3: [start; end]
sourcePos = linePos(1, :);  % First endpoint
targetPos = linePos(2, :);  % Second endpoint

% Find nearest vertices
[sourceVert, targetVert] = getLineEndpointVertices();
```

### Accumulative Animation
```matlab
% Initialize before animation
AccumulatedField = zeros(nVerts, 1);
clearPathLines();

% At each step
w = SpectralBrush.evaluate(currentVertex);
AccumulatedField = AccumulatedField + w;  % ACCUMULATE
BrushContext.Field = AccumulatedField;

% Add line between vertices
addPathLine(previousVertex, currentVertex);  % Cyan line
```

### Path Line Management
```matlab
% Each path segment creates a cyan line
pathLine = images.ui.graphics.roi.Line(...
    'Position', [pos1; pos2], ...
    'Color', 'cyan', ...
    'LineWidth', 2, ...
    'InteractionsAllowed', 'none');  % Non-interactive

% Stored in PathLines array
PathLines(end+1) = pathLine;

% Clear all path lines
clearPathLines();  % Delete all cyan lines
```

## Methods

### ManifoldController Methods
```matlab
% Line ROI management
initializeTrajectoryLine()      % Create yellow line with random endpoints
hideTrajectoryLine()            % Hide line when other brush selected
updateTrajectoryEndpoints()     % Update Seed/Target from line positions
getLineEndpointVertices()       % Find nearest vertices to line endpoints

% Path trace management
addPathLine(vert1, vert2)       % Add cyan line between vertices
clearPathLines()                % Remove all cyan path lines

% Animation
startTrajectoryAnimation(dt)    % Start with accumulation
stopTrajectoryAnimation()       % Stop and preserve accumulated field
```

### EigenmodeController Methods
```matlab
startTrajectoryAnimation(dt)    % Wrapper for ManifoldController method
stopTrajectoryAnimation()       % Wrapper for stop
```

## Animation Algorithm

```matlab
% 1. Get endpoints from Line ROI
[source, target] = getLineEndpointVertices();

% 2. Compute shortest path
path = shortestpath(meshGraph, source, target);

% 3. Initialize
AccumulatedField = zeros(nVerts, 1);
clearPathLines();

% 4. For each vertex in path:
for i = 1:length(path)
    % Evaluate SpectralBrush at current vertex
    w = SpectralBrush.evaluate(path(i));
    
    % ACCUMULATE (don't replace)
    AccumulatedField = AccumulatedField + w;
    
    % Update visualization
    BrushContext.Field = AccumulatedField;
    
    % Add cyan line from previous vertex
    if i > 1
        addPathLine(path(i-1), path(i));
    end
    
    pause(updateInterval);
end
```

## Visualization Layers

From back to front:
1. **Surface mesh** - Colored by accumulated SpectralBrush field
2. **Cyan path lines** - Trace showing shortest path taken
3. **Yellow line ROI** - User-controlled trajectory endpoints

## Tips

- **Drag endpoints** before starting animation to customize trajectory
- **Longer paths** create more accumulated field (more color saturation)
- **Cyan lines** persist after animation completes (shows full trajectory)
- **Clear path**: Stop animation, select different brush, then return to trajectory
- **Reproducible start**: Yellow line initializes with same random vertices (seed 42)

## Comparison with Other Brushes

| Brush | Annotation | Animation | Field Update |
|-------|-----------|-----------|--------------|
| Delta | Green point | None | Replace |
| Graph | Green point | None | Replace |
| Spectral | Green point | None | Replace |
| **Trajectory** | **Yellow line** | **Accumulate + trace** | **Accumulate** |
