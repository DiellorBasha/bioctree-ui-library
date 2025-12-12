# d3Brush Component

An interactive brush component for selecting ranges on a continuous scale with snapping support. Based on the [D3 Brush Snapping example](https://observablehq.com/@d3/brush-snapping).

## Overview

The `d3Brush` component provides a visual interface for selecting a numeric range with automatic snapping to specified intervals. It's ideal for filtering data, selecting time ranges, or any scenario requiring bounded numeric input with visual feedback.

## Installation

The d3Brush component is included in the bioctree UI Library. Ensure the component directory is on your MATLAB path:

```matlab
addpath(genpath('path/to/bioctree-ui-library/components'));
```

## Basic Usage

### Simple Example

```matlab
% Create a figure
fig = uifigure('Position', [100 100 600 300]);

% Create brush component
brush = d3Brush(fig, 'Position', [50 50 500 200]);

% Access current selection
disp(brush.Value);  % [20 60] (default)
```

### With Callbacks

```matlab
% Create figure and brush
fig = uifigure('Position', [100 100 600 300]);
brush = d3Brush(fig, 'Position', [50 50 500 200]);

% Set up event callbacks
brush.ValueChangedFcn = @(src, event) fprintf('Selection: [%.1f, %.1f]\n', ...
    event.Value(1), event.Value(2));

brush.BrushStartedFcn = @(src, event) disp('Brush started');
brush.BrushEndedFcn = @(src, event) disp('Brush ended');
```

## Properties

### Min
- **Type:** `double` (scalar)
- **Default:** `0`
- **Description:** Minimum value of the range

```matlab
brush.Min = -50;
```

### Max
- **Type:** `double` (scalar)
- **Default:** `100`
- **Description:** Maximum value of the range

```matlab
brush.Max = 200;
```

### SnapInterval
- **Type:** `double` (scalar, positive)
- **Default:** `5`
- **Description:** Interval to which brush handles snap

The brush handles will automatically snap to the nearest multiple of this value.

```matlab
brush.SnapInterval = 10;  % Snap to multiples of 10
```

### Value
- **Type:** `double` (1x2 array)
- **Default:** `[20 60]`
- **Description:** Current brush selection `[start, stop]`

The Value property is automatically:
- **Sorted:** `[80, 40]` becomes `[40, 80]`
- **Clamped:** Values are constrained to `[Min, Max]` range

```matlab
% Set value
brush.Value = [30, 70];

% Read value
currentSelection = brush.Value;

% Automatically sorted
brush.Value = [90, 10];
disp(brush.Value);  % [10 90]

% Automatically clamped
brush.Min = 0;
brush.Max = 100;
brush.Value = [-10, 120];
disp(brush.Value);  % [0 100]
```

## Events

### ValueChanging
Fires continuously during brush dragging (throttled to ~50ms intervals).

**Event Data:**
- `Value` - Current selection `[start, stop]`
- `PreviousValue` - Previous selection

```matlab
brush.ValueChangingFcn = @(src, event) fprintf('Changing: [%.1f, %.1f]\n', ...
    event.Value(1), event.Value(2));
```

### ValueChanged
Fires when brush interaction completes (on mouse release).

**Event Data:**
- `Value` - Final selection `[start, stop]`
- `PreviousValue` - Previous selection

```matlab
brush.ValueChangedFcn = @(src, event) fprintf('Changed: [%.1f, %.1f]\n', ...
    event.Value(1), event.Value(2));
```

### BrushStarted
Fires when brush interaction begins.

```matlab
brush.BrushStartedFcn = @(src, event) disp('Started dragging');
```

### BrushEnded
Fires when brush interaction ends.

```matlab
brush.BrushEndedFcn = @(src, event) disp('Finished dragging');
```

## Advanced Examples

### Custom Range with Fine Snapping

```matlab
fig = uifigure('Position', [100 100 600 300], 'Name', 'Temperature Range');
brush = d3Brush(fig, 'Position', [50 50 500 200]);

% Configure for temperature range
brush.Min = -20;
brush.Max = 40;
brush.SnapInterval = 0.5;  % Snap to 0.5°C
brush.Value = [18, 25];    % Room temperature range

% Display selection
brush.ValueChangedFcn = @(src, event) fprintf('Temperature range: %.1f°C to %.1f°C\n', ...
    event.Value(1), event.Value(2));
```

### Multiple Brushes for Data Filtering

```matlab
fig = uifigure('Position', [100 100 600 500], 'Name', 'Multi-Range Filter');

% Age range brush
ageBrush = d3Brush(fig, 'Position', [50 350 500 100]);
ageBrush.Min = 0;
ageBrush.Max = 100;
ageBrush.SnapInterval = 1;
ageBrush.Value = [25, 65];

% Income range brush
incomeBrush = d3Brush(fig, 'Position', [50 150 500 100]);
incomeBrush.Min = 0;
incomeBrush.Max = 200000;
incomeBrush.SnapInterval = 5000;
incomeBrush.Value = [30000, 100000];

% Combined filter callback
filterData = @(~, ~) fprintf('Age: [%d, %d], Income: [$%d, $%d]\n', ...
    round(ageBrush.Value), round(incomeBrush.Value));

ageBrush.ValueChangedFcn = filterData;
incomeBrush.ValueChangedFcn = filterData;
```

### Interactive Configuration

```matlab
fig = uifigure('Position', [100 100 600 400], 'Name', 'Interactive Brush');

% Create brush
brush = d3Brush(fig, 'Position', [50 200 500 150]);

% Create controls
minField = uieditfield(fig, 'numeric', 'Position', [150 160 100 22], ...
    'Value', 0, 'ValueChangedFcn', @(src, ~) set(brush, 'Min', src.Value));
maxField = uieditfield(fig, 'numeric', 'Position', [150 120 100 22], ...
    'Value', 100, 'ValueChangedFcn', @(src, ~) set(brush, 'Max', src.Value));
snapField = uieditfield(fig, 'numeric', 'Position', [150 80 100 22], ...
    'Value', 5, 'ValueChangedFcn', @(src, ~) set(brush, 'SnapInterval', src.Value));

uilabel(fig, 'Position', [50 160 90 22], 'Text', 'Min:');
uilabel(fig, 'Position', [50 120 90 22], 'Text', 'Max:');
uilabel(fig, 'Position', [50 80 90 22], 'Text', 'Snap Interval:');

% Display current selection
valueLabel = uilabel(fig, 'Position', [50 40 500 22], ...
    'Text', sprintf('Selection: [%.1f, %.1f]', brush.Value(1), brush.Value(2)));

brush.ValueChangedFcn = @(src, event) set(valueLabel, 'Text', ...
    sprintf('Selection: [%.1f, %.1f]', event.Value(1), event.Value(2)));
```

### Programmatic Animation

```matlab
fig = uifigure('Position', [100 100 600 300]);
brush = d3Brush(fig, 'Position', [50 50 500 200]);

% Animate the brush selection
ranges = [10, 30; 20, 60; 40, 80; 60, 90; 30, 70];

for i = 1:size(ranges, 1)
    pause(1);
    brush.Value = ranges(i, :);
    fprintf('Selection updated to: [%.1f, %.1f]\n', brush.Value(1), brush.Value(2));
end
```

## Error Handling

The component validates all inputs and provides clear error messages:

```matlab
brush = d3Brush(uifigure);

% Invalid value size
try
    brush.Value = 50;  % Single value instead of [start, stop]
catch ME
    disp(ME.identifier);  % 'd3Brush:InvalidValue'
end

% Values are automatically corrected
brush.Value = [80, 20];      % Reversed - automatically sorted
disp(brush.Value);           % [20 80]

brush.Value = [-10, 120];    % Out of range - automatically clamped
disp(brush.Value);           % [0 100]
```

## Performance Considerations

### Event Throttling

The `ValueChanging` event is throttled to ~50ms intervals to prevent performance issues during rapid dragging. This provides smooth visual feedback while keeping MATLAB responsive.

### Update Frequency

For applications requiring high-frequency updates, consider using only the `ValueChanged` event:

```matlab
% Only fires on release - more efficient
brush.ValueChangedFcn = @(src, event) processData(event.Value);
```

## Browser Compatibility

The d3Brush component uses D3.js v5.9.2 and is compatible with:

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)

## Technical Details

### Dependencies

- **D3.js Version:** 5.9.2 (bundled in `vendor/`)
- **Event Model:** D3 v5 (uses `d3.event` global)

!!! warning "D3 Version Lock"
    Do not upgrade D3.js without updating event handlers. D3 v6+ uses a different event API that is incompatible with the current implementation.

### Component Files

```
@d3Brush/
├── d3Brush.m              # MATLAB class
├── d3Brush.html           # HTML template
├── d3Brush.css            # Component styles
├── d3Brush.js             # Controller (lifecycle)
├── d3Brush.render.js      # Renderer (D3 visualization)
└── vendor/
    └── d3.v5.9.2.min.js   # Bundled D3.js
```

## Testing

### Automated Tests

Run the MATLAB test suite:

```matlab
runtests('test_d3Brush')
```

### Manual Testing

Use the interactive test script:

```matlab
% Open and run sections individually
edit('manual_test_d3Brush.m')
```

See [Testing Guide](../development/testing.md) for more details.

## Troubleshooting

### Component Not Rendering

**Problem:** Brush doesn't appear in the figure.

**Solutions:**
1. Verify component is on MATLAB path: `which d3Brush`
2. Check HTML file exists: `dir('components/@d3Brush/d3Brush.html')`
3. Ensure figure is visible: `fig.Visible = 'on'`

### Events Not Firing

**Problem:** Callbacks aren't being triggered.

**Solutions:**
1. Verify callback syntax: `@(src, event) yourFunction(event.Value)`
2. Check JavaScript console in debug mode (F12 in browser preview)
3. Ensure component is fully loaded before interacting

### Snapping Not Working

**Problem:** Brush doesn't snap to intervals.

**Solutions:**
1. Check `SnapInterval` is positive: `brush.SnapInterval > 0`
2. Verify interval is reasonable for range: `(Max - Min) / SnapInterval > 1`
3. Try larger snap interval for visual confirmation

## API Reference

For complete API documentation, see:
- [MATLAB API Reference](../api/matlab.md#d3brush)
- [JavaScript API Reference](../api/javascript.md#d3brush)

## Examples Repository

More examples available in:
- `tests/matlab/manual_test_d3Brush.m` - 9 interactive test scenarios
- `examples/` - Additional use cases

## Related Components

- More components coming soon!

## Support

- [GitHub Issues](https://github.com/DiellorBasha/bioctree-ui-library/issues)
- [Component README](https://github.com/DiellorBasha/bioctree-ui-library/tree/main/components/@d3Brush)
