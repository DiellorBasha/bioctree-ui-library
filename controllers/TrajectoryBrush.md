# TrajectoryBrush

## Overview

TrajectoryBrush computes the shortest path between a source vertex (Seed) and a target vertex on a manifold mesh, then applies a base brush (default: SpectralBrush) at each point along the trajectory. This enables path-based manifold analysis and animation of brush effects along geodesic paths.

## Architecture

### Brush Composition
- **Base Brush**: SpectralBrush (default) applied at each path point
- **Path Computation**: Uses MATLAB's `shortestpath()` on weighted mesh graph
- **Graph Representation**: Euclidean edge lengths via `bct.io.convert.manifoldToMatlabGraph()`

### Properties

- `Target` (SetObservable): Target vertex index for trajectory endpoint
- `BaseBrush`: Brush to apply along trajectory (default: SpectralBrush)
- `KernelModel`: Kernel configuration passed to SpectralBrush
- `CurrentPathIndex`: Current position in path during animation
- `Type`: 'Trajectory' (read-only)

### Key Methods

#### Evaluation Methods
```matlab
% Compute path from source to target
path = brush.getPath(source);

% Evaluate brush at specific path index
w = brush.evaluateAtPathIndex(pathIndex);

% Evaluate full trajectory (sum over all path points)
w = brush.evaluateFullTrajectory(source);

% Standard evaluate (calls evaluateFullTrajectory)
w = brush.evaluate(source);
```

#### Path Computation
```matlab
% Get shortest path using mesh graph
[path, dist] = shortestpath(meshGraph, source, target);
```

## Integration with ManifoldController

### Target Property
ManifoldController extends properties to include:
```matlab
properties (SetObservable)
    Seed (1,1) double = 1       % Source vertex
    Target (1,1) double = 1     % Target vertex for trajectories
end
```

### Annotation Support
- **Green annotation**: Source (Seed) - always visible for brush mode
- **Red annotation**: Target - visible only when TrajectoryBrush is active

### Animation System
```matlab
% Start trajectory animation
controller.startTrajectoryAnimation(updateInterval);

% Stop animation
controller.stopTrajectoryAnimation();

% Internal: Animate along path
controller.animateTrajectory(pathIndices, updateInterval);
```

#### Animation Implementation
- Uses MATLAB `timer` object with fixed rate execution
- Timer callback updates Seed to next path vertex
- Calls `evaluateAtPathIndex()` for each step
- Updates visualization via BrushContext.Field

## Usage Example

### Basic Setup
```matlab
% Create manifold with spectral decomposition
manifold = bct.Manifold(meshStruct);
manifold.dual = struct('lambda', Lambda, 'U', Modes);

% Create TrajectoryBrush
brush = TrajectoryBrush(manifold);
brush.Target = 500;
brush.KernelModel = kernelModel;  % For SpectralBrush

% Evaluate trajectory
w = brush.evaluate(source);  % Returns summed field over entire path
```

### With ManifoldController
```matlab
% Create controller
controller = ManifoldController(parent);
controller.initializeFromManifold(manifold);

% Select trajectory brush from toolbar (or programmatically)
controller.BrushToolbar.ActiveBrush = 'trajectory';

% Set endpoints
controller.Seed = 1;      % Source (green annotation)
controller.Target = 500;  % Target (red annotation)

% Animate
controller.startTrajectoryAnimation(0.1);  % 0.1 sec per step
```

### With EigenmodeController
```matlab
% Create EigenmodeController
emc = EigenmodeController(parent);
emc.initializeFromManifold(manifold);
emc.setEigenmodes(Lambda, Modes);

% Select trajectory brush
emc.Manifold.BrushToolbar.ActiveBrush = 'trajectory';

% Configure trajectory
emc.Manifold.Seed = 1;
emc.setTrajectoryTarget(500);

% Animate
emc.startTrajectoryAnimation(0.05);  % Faster animation

% Stop when done
emc.stopTrajectoryAnimation();
```

## Technical Details

### Graph Construction
```matlab
% Convert manifold to weighted MATLAB graph
meshGraph = bct.io.convert.manifoldToMatlabGraph(manifold, 'Weighted', true);

% Graph uses Euclidean edge lengths as weights
summary(meshGraph.Edges.Weight);
```

### Path Computation
```matlab
% Compute shortest path (Dijkstra's algorithm)
[path, dist] = shortestpath(meshGraph, source, target);

% path: Vector of vertex indices along shortest path
% dist: Total path length
```

### Base Brush Evaluation
At each path vertex:
```matlab
% SpectralBrush evaluation at vertex i
w_i = U * g(lambda) * U' * delta_i

% where:
%   U: Spectral basis (eigenvectors)
%   lambda: Eigenvalues
%   g: Kernel function (from KernelModel)
%   delta_i: Kronecker delta at vertex i
```

### Full Trajectory Evaluation
```matlab
% Sum contributions from all path points
w_total = sum_{i in path} w_i

% Normalize
w = w_total / max(abs(w_total))
```

## Animation Architecture

### Timer-Based Animation
```matlab
% Create timer
timer = timer(...
    'ExecutionMode', 'fixedRate', ...
    'Period', updateInterval, ...
    'TasksToExecute', length(path), ...
    'TimerFcn', @trajectoryTimerCallback);

% Timer callback
function trajectoryTimerCallback(pathIndices)
    currentIdx = currentIdx + 1;
    
    % Update seed to current path position
    Seed = pathIndices(currentIdx);
    
    % Evaluate brush at this position
    w = brush.evaluateAtPathIndex(currentIdx);
    
    % Update visualization
    BrushContext.Field = w;
end
```

### Synchronization
- Seed property triggers `onSeedChanged()` listener
- Listener updates annotation position
- BrushContext.Field triggers `FieldChanged` event
- FieldChanged triggers `updateBrushVisualization()`
- Surface colors update via colormap

## UI Components

### Toolbar Icon
- **Icon**: `arrow-guide.svg`
- **Label**: Trajectory Brush
- **Position**: After divider, fourth brush

### Annotations
- **Seed (Source)**: Green point at source vertex
- **Target**: Red point at target vertex (only visible for trajectory)

### Visibility Rules
```matlab
% In ManifoldController.onBrushChanged()
if isa(brush, 'TrajectoryBrush')
    setTargetAnnotationVisible(true);   % Show red target
else
    setTargetAnnotationVisible(false);  % Hide for other brushes
end
```

## Performance Considerations

### Path Caching
- Computed path stored in `CurrentPath` property
- Recomputed only when source or target changes
- Animation uses cached path

### Graph Caching
- Mesh graph built once in constructor
- Stored in private `MeshGraph` property
- Rebuilds only if manifold changes

### Animation Performance
- Default interval: 0.1 seconds (10 Hz)
- Faster: 0.05 seconds (20 Hz) for smooth animation
- Slower: 0.2 seconds (5 Hz) for careful inspection

## Future Enhancements

### Planned Features
1. **Alternative Base Brushes**: Support GraphBrush, DeltaBrush along path
2. **Path Visualization**: Draw path line on surface
3. **Geodesic Paths**: Use actual geodesic distance instead of graph shortest path
4. **Path Recording**: Save animated trajectory as signal sequence
5. **Bidirectional Animation**: Reverse animation from target to source
6. **Path Accumulation**: Accumulate brush effects over entire animation

### UI Enhancements
1. Target selection via point annotation interaction
2. Animation controls (play/pause/stop buttons)
3. Animation speed slider
4. Path preview before animation
5. Loop animation option

## Troubleshooting

### No Path Found
```matlab
warning('No path found from Seed to Target');
% Possible causes:
%   - Disconnected mesh components
%   - Invalid vertex indices
%   - Empty mesh graph
```

### Animation Not Starting
```matlab
% Verify TrajectoryBrush is active
class(controller.BrushContext.BrushModel.Brush)
% Should return: 'TrajectoryBrush'

% Check path exists
brush = controller.BrushContext.BrushModel.Brush;
path = brush.getPath(controller.Seed);
length(path)  % Should be > 0
```

### Target Annotation Not Visible
```matlab
% Manually show target annotation
controller.setTargetAnnotationVisible(true);

% Verify target is valid
controller.Target
nVerts = size(controller.Manifold.Vertices, 1);
% Target should be between 1 and nVerts
```

## Testing

See `tests/matlab/test_trajectory_brush.m` for comprehensive test script.

Key test scenarios:
1. Basic trajectory computation
2. Animation with various intervals
3. Source/target changes during animation
4. Integration with EigenmodeController
5. Tab switching behavior

## References

- [MATLAB shortestpath](https://www.mathworks.com/help/matlab/ref/graph.shortestpath.html)
- [SpectralBrush Documentation](SpectralBrush.md)
- [ManifoldController Documentation](ManifoldController.md)
- [EigenmodeController Documentation](EigenmodeController.md)
