# Quick Start

Get up and running with the bioctree UI Library in 5 minutes.

## Your First Component

Let's create a simple interactive brush component:

```matlab
% 1. Create a figure
fig = uifigure('Position', [100 100 600 300], 'Name', 'My First Brush');

% 2. Create a d3Brush component
brush = d3Brush(fig, 'Position', [50 50 500 200]);

% 3. Configure properties
brush.Min = 0;
brush.Max = 100;
brush.SnapInterval = 5;
brush.Value = [20, 60];

% 4. Add a callback
brush.ValueChangedFcn = @(src, event) fprintf('Selection: [%.1f, %.1f]\n', ...
    event.Value(1), event.Value(2));
```

That's it! Drag the brush handles to see it in action.

## Understanding the Code

### Step 1: Create a Figure

```matlab
fig = uifigure('Position', [100 100 600 300], 'Name', 'My First Brush');
```

- Use `uifigure` (not `figure`) for App Designer compatibility
- Position: `[x y width height]` in pixels
- Name appears in the window title bar

### Step 2: Create the Component

```matlab
brush = d3Brush(fig, 'Position', [50 50 500 200]);
```

- First argument: parent figure
- Position: `[x y width height]` relative to parent
- Component automatically fills its bounding box

### Step 3: Configure Properties

```matlab
brush.Min = 0;              % Minimum value
brush.Max = 100;            % Maximum value
brush.SnapInterval = 5;     % Snap to multiples of 5
brush.Value = [20, 60];     % Initial selection
```

Properties can be set individually or during construction:

```matlab
brush = d3Brush(fig, ...
    'Position', [50 50 500 200], ...
    'Min', 0, ...
    'Max', 100, ...
    'SnapInterval', 5, ...
    'Value', [20, 60]);
```

### Step 4: Add Callbacks

```matlab
brush.ValueChangedFcn = @(src, event) fprintf('Selection: [%.1f, %.1f]\n', ...
    event.Value(1), event.Value(2));
```

- Callback receives `src` (component) and `event` (event data)
- Access new value: `event.Value`
- Access previous value: `event.PreviousValue`

## Interactive Example

Try this complete example:

```matlab
% Create the UI
fig = uifigure('Position', [100 100 600 400], 'Name', 'Interactive Example');

% Create brush
brush = d3Brush(fig, 'Position', [50 250 500 120]);
brush.Min = 0;
brush.Max = 100;
brush.SnapInterval = 1;
brush.Value = [25, 75];

% Create display label
label = uilabel(fig, 'Position', [50 200 500 30], ...
    'Text', sprintf('Current Selection: [%.0f, %.0f]', brush.Value(1), brush.Value(2)), ...
    'FontSize', 14, ...
    'FontWeight', 'bold');

% Create status label
statusLabel = uilabel(fig, 'Position', [50 160 500 30], ...
    'Text', 'Drag the brush handles', ...
    'FontSize', 12);

% Update display on value change
brush.ValueChangedFcn = @(src, event) updateDisplay(label, statusLabel, event);

function updateDisplay(label, statusLabel, event)
    label.Text = sprintf('Current Selection: [%.0f, %.0f]', ...
        event.Value(1), event.Value(2));
    statusLabel.Text = sprintf('Range: %.0f units (from %.0f to %.0f)', ...
        event.Value(2) - event.Value(1), event.Value(1), event.Value(2));
end
```

## Common Patterns

### Read Current Value

```matlab
currentSelection = brush.Value;
startValue = currentSelection(1);
endValue = currentSelection(2);
```

### Update Programmatically

```matlab
% Set new selection
brush.Value = [30, 70];

% Animate selection
for i = 1:10
    brush.Value = [i*5, 100-i*5];
    pause(0.1);
end
```

### Multiple Events

```matlab
% Track all interaction stages
brush.BrushStartedFcn = @(src, ~) disp('Started');
brush.ValueChangingFcn = @(src, event) fprintf('Dragging: [%.1f, %.1f]\n', ...
    event.Value(1), event.Value(2));
brush.ValueChangedFcn = @(src, event) fprintf('Final: [%.1f, %.1f]\n', ...
    event.Value(1), event.Value(2));
brush.BrushEndedFcn = @(src, ~) disp('Ended');
```

### Error Handling

```matlab
% Values are automatically validated
brush.Value = [80, 20];      % Reversed → automatically sorted to [20, 80]
brush.Value = [-10, 120];    % Out of range → clamped to [0, 100]

% Invalid inputs throw errors
try
    brush.Value = 50;        % Single value instead of [start, stop]
catch ME
    disp(['Error: ' ME.message]);
end
```

## Multiple Components

Create multiple brushes in one figure:

```matlab
fig = uifigure('Position', [100 100 600 500], 'Name', 'Multiple Brushes');

% Top brush - Age range
ageBrush = d3Brush(fig, 'Position', [50 350 500 100]);
ageBrush.Min = 0;
ageBrush.Max = 100;
ageBrush.Value = [25, 65];

uilabel(fig, 'Position', [50 460 200 20], 'Text', 'Age Range:', ...
    'FontWeight', 'bold');

% Bottom brush - Income range
incomeBrush = d3Brush(fig, 'Position', [50 150 500 100]);
incomeBrush.Min = 0;
incomeBrush.Max = 200000;
incomeBrush.SnapInterval = 5000;
incomeBrush.Value = [30000, 100000];

uilabel(fig, 'Position', [50 260 200 20], 'Text', 'Income Range:', ...
    'FontWeight', 'bold');

% Combined output
output = uilabel(fig, 'Position', [50 80 500 40], ...
    'Text', 'Adjust the brushes above', ...
    'FontSize', 12);

updateOutput = @(~, ~) set(output, 'Text', sprintf(...
    'Age: %.0f-%.0f years, Income: $%,d-$%,d', ...
    ageBrush.Value(1), ageBrush.Value(2), ...
    round(incomeBrush.Value(1)), round(incomeBrush.Value(2))));

ageBrush.ValueChangedFcn = updateOutput;
incomeBrush.ValueChangedFcn = updateOutput;
```

## App Designer Integration

Use components in App Designer:

1. Add a Panel to your app
2. Create the component in `startupFcn`:

```matlab
function startupFcn(app)
    % Create d3Brush in Panel
    app.Brush = d3Brush(app.Panel, 'Position', [10 10 580 200]);
    app.Brush.Min = 0;
    app.Brush.Max = 100;
    app.Brush.ValueChangedFcn = @(src, event) app.brushValueChanged(event);
end

function brushValueChanged(app, event)
    % Handle brush value changes
    app.SelectionLabel.Text = sprintf('[%.1f, %.1f]', ...
        event.Value(1), event.Value(2));
end
```

## Next Steps

Now that you understand the basics:

- [Architecture Overview](architecture.md) - Learn how components work
- [d3Brush Documentation](../components/d3brush.md) - Explore all features
- [Advanced Examples](../examples/advanced-features.md) - Complex use cases
- [Development Guide](../development/contributing.md) - Create your own components

## Quick Reference

### Properties
- `Min` - Minimum value (default: 0)
- `Max` - Maximum value (default: 100)
- `SnapInterval` - Snap increment (default: 5)
- `Value` - Current selection `[start, stop]` (default: [20, 60])

### Events
- `BrushStarted` - Interaction begins
- `ValueChanging` - During drag (throttled)
- `ValueChanged` - On release
- `BrushEnded` - Interaction ends

### Methods
- Read: `value = brush.Value`
- Write: `brush.Value = [20, 60]`

Ready to build? Start with the [examples](../examples/basic-usage.md)!
