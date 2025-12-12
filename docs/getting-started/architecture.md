# Architecture

Understanding the bioctree UI Library architecture will help you use components effectively and create your own.

## Overview

The library bridges MATLAB's computational power with D3.js's visualization capabilities through a bidirectional communication pattern.

```
┌─────────────────────────────────────────────────────────┐
│                      MATLAB Layer                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │ ComponentContainer (d3Brush.m)                    │  │
│  │  • Property Management                            │  │
│  │  • Event Handling                                 │  │
│  │  • Data Synchronization                           │  │
│  └─────────────┬─────────────────────────────────────┘  │
│                │ HTMLComponent.Data                      │
│                ├─────────────────────────────────────▶   │
│                │ CustomEvent                             │
│                ◀─────────────────────────────────────┤   │
└────────────────┼─────────────────────────────────────┼───┘
                 │                                     │
┌────────────────┼─────────────────────────────────────┼───┐
│                │       JavaScript Layer              │   │
│  ┌─────────────▼─────────────────────────────────────▼─┐ │
│  │ Controller (d3Brush.js)                             │ │
│  │  • Lifecycle Management                             │ │
│  │  • Data Reception                                   │ │
│  │  • Event Dispatching                                │ │
│  └─────────────┬───────────────────────────────────────┘ │
│                │ renderBrush(data)                       │
│  ┌─────────────▼───────────────────────────────────────┐ │
│  │ Renderer (d3Brush.render.js)                        │ │
│  │  • D3.js Visualization                              │ │
│  │  • SVG Creation                                     │ │
│  │  • Interaction Handling                             │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Component Structure

Each component follows a standardized file structure:

```
@ComponentName/
├── ComponentName.m          # MATLAB class
├── ComponentName.html       # HTML template
├── ComponentName.css        # Styles
├── ComponentName.js         # Controller
├── ComponentName.render.js  # Renderer
├── ComponentName.utils.js   # Optional utilities
├── vendor/                  # Bundled dependencies
│   └── d3.v5.9.2.min.js
└── README.md               # Documentation
```

### File Responsibilities

#### 1. MATLAB Class (`ComponentName.m`)

Extends `matlab.ui.componentcontainer.ComponentContainer` and handles:

- **Property Management**: Public properties with validation
- **Lifecycle Methods**: `setup()`, `update()`, `delete()`
- **Event Handling**: Receives CustomEvents from JavaScript
- **Data Synchronization**: Updates `HTMLComponent.Data` structure

**Example:**
```matlab
classdef d3Brush < matlab.ui.componentcontainer.ComponentContainer
    properties
        Min = 0
        Max = 100
        Value = [20 60]
    end
    
    methods (Access = protected)
        function setup(comp)
            comp.HTMLComponent = uihtml(comp);
            comp.HTMLComponent.HTMLSource = 'd3Brush.html';
            comp.HTMLComponent.HTMLEventReceivedFcn = @(src, event) ...
                comp.handleBrushEvent(event);
            comp.update();
        end
        
        function update(comp)
            comp.HTMLComponent.Data = struct(...
                'min', comp.Min, ...
                'max', comp.Max, ...
                'initialSelection', comp.Value);
        end
    end
end
```

#### 2. HTML Template (`ComponentName.html`)

Loads scripts and defines the container structure:

```html
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="ComponentName.css">
    <script src="vendor/d3.v5.9.2.min.js"></script>
</head>
<body>
    <div class="component-container"></div>
    <script src="ComponentName.render.js"></script>
    <script src="ComponentName.js"></script>
</body>
</html>
```

#### 3. Controller (`ComponentName.js`)

Manages lifecycle and MATLAB communication:

```javascript
function setup(htmlComponent) {
    // Initial render
    var data = htmlComponent.Data;
    renderComponent(data, htmlComponent);
    
    // Listen for data changes from MATLAB
    htmlComponent.addEventListener("DataChanged", function(event) {
        renderComponent(htmlComponent.Data, htmlComponent);
    });
}
```

#### 4. Renderer (`ComponentName.render.js`)

Pure D3.js visualization logic:

```javascript
function renderComponent(data, htmlComponent) {
    // Clear previous render
    d3.select("svg").remove();
    
    // Create visualization
    var svg = d3.select('.component-container')
        .append('svg');
    
    // Add D3 interactions
    // ...
    
    // Dispatch events back to MATLAB
    htmlComponent.dispatchEvent(new CustomEvent('ValueChanged', {
        detail: JSON.stringify({ selection: [start, end] })
    }));
}
```

## Communication Flow

### MATLAB → JavaScript

When a property changes in MATLAB:

1. MATLAB property setter triggers `update()`
2. `update()` packages data into a structure
3. Assigns to `HTMLComponent.Data`
4. JavaScript `DataChanged` event fires
5. Controller calls renderer with new data

**Example:**
```matlab
% In MATLAB
brush.Max = 200;  % Property change

% Triggers internally:
function update(comp)
    comp.HTMLComponent.Data = struct('max', comp.Max, ...);
end
```

```javascript
// In JavaScript
htmlComponent.addEventListener("DataChanged", function(event) {
    var data = htmlComponent.Data;  // Receives: {max: 200, ...}
    renderComponent(data, htmlComponent);
});
```

### JavaScript → MATLAB

When user interacts with visualization:

1. D3 event handler fires
2. Controller dispatches CustomEvent
3. Event includes JSON-serialized data
4. MATLAB `HTMLEventReceivedFcn` receives event
5. MATLAB parses JSON and updates properties
6. MATLAB notifies event listeners

**Example:**
```javascript
// In JavaScript
function brushed() {
    var selection = [start, end];
    htmlComponent.dispatchEvent(new CustomEvent('ValueChanged', {
        detail: JSON.stringify({ selection: selection })
    }));
}
```

```matlab
% In MATLAB
function handleBrushEvent(comp, event)
    eventData = jsondecode(event.HTMLEventData);
    comp.Value_ = eventData.selection;
    notify(comp, 'ValueChanged', evtData);
end
```

## Dependency Management

### Component-Level Vendoring

Each component bundles its own dependencies in a `vendor/` directory:

```
@d3Brush/
└── vendor/
    └── d3.v5.9.2.min.js
```

**Benefits:**
- No version conflicts between components
- Explicit version control
- Independent component updates
- Self-contained distribution

### Version Manifest

Root `manifest.json` tracks all component dependencies:

```json
{
  "components": {
    "d3Brush": {
      "version": "1.0.0",
      "dependencies": {
        "d3": "5.9.2"
      }
    }
  }
}
```

## Event System

### Event Types

Components typically implement:

| Event | Timing | Throttled | Use Case |
|-------|--------|-----------|----------|
| `[Action]Started` | Interaction begins | No | Track when user starts |
| `ValueChanging` | During interaction | Yes (~50ms) | Real-time feedback |
| `ValueChanged` | Interaction completes | No | Final value processing |
| `[Action]Ended` | Interaction ends | No | Cleanup/finalization |

### Event Throttling

Rapid events (like dragging) are throttled using MATLAB timers:

```matlab
properties (Access = private)
    ThrottleTimer
    PendingSelection
end

methods
    function setup(comp)
        comp.ThrottleTimer = timer(...
            'ExecutionMode', 'singleShot', ...
            'StartDelay', 0.05, ...  % 50ms throttle
            'TimerFcn', @(~,~) comp.processPending());
    end
    
    function handleBrushEvent(comp, event)
        if strcmp(event.HTMLEventName, 'BrushMoving')
            comp.PendingSelection = eventData.selection;
            if strcmp(comp.ThrottleTimer.Running, 'on')
                stop(comp.ThrottleTimer);
            end
            start(comp.ThrottleTimer);
        end
    end
end
```

## Property Patterns

### Dependent Properties

Use dependent properties for computed or validated values:

```matlab
properties (Dependent)
    Value  % Computed from Value_
end

properties (Access = private)
    Value_ (1,2) double = [20 60]  % Internal storage
end

methods
    function val = get.Value(comp)
        val = comp.Value_;
    end
    
    function set.Value(comp, val)
        % Validate and transform
        val = sort(val);  % Ensure start <= stop
        val = [max(comp.Min, val(1)), min(comp.Max, val(2))];  % Clamp
        comp.Value_ = val;
        comp.update();  % Sync to JavaScript
    end
end
```

### Validation

Use property validation attributes:

```matlab
properties
    Min (1,1) double {mustBeFinite, mustBeReal} = 0
    Max (1,1) double {mustBeFinite, mustBeReal} = 100
    SnapInterval (1,1) double {mustBeFinite, mustBeReal, mustBePositive} = 5
end
```

## Lifecycle

### Component Lifecycle Stages

1. **Construction** - `d3Brush(parent, ...)` creates instance
2. **Setup** - `setup()` creates HTML component, loads files
3. **Initial Update** - `update()` sends initial data to JavaScript
4. **Active** - Bidirectional communication, event handling
5. **Deletion** - `delete()` cleans up timers and resources

### Best Practices

**✓ Do:**
- Call `update()` at the end of `setup()`
- Clean up timers in `delete()`
- Use relative paths for `HTMLSource`
- Validate all property inputs
- Throttle rapid events

**✗ Don't:**
- Set `Units` or `Position` on HTML components (not supported)
- Use absolute paths (breaks toolbox packaging)
- Skip validation (leads to JS errors)
- Forget to clean up resources

## Testing Architecture

### Two-Tier Testing

1. **Browser Tests** (`tests/html/`)
   - Test JavaScript/D3 rendering independently
   - Mock MATLAB's `htmlComponent` interface
   - Fast iteration, visual debugging

2. **MATLAB Tests** (`tests/matlab/`)
   - Integration testing with full stack
   - Property validation
   - Event handling
   - Lifecycle management

## Extensibility

### Creating New Components

Follow the established patterns:

1. Create `@ComponentName/` directory
2. Implement MATLAB class extending `ComponentContainer`
3. Create HTML template (no inline scripts)
4. Separate controller (lifecycle) from renderer (visualization)
5. Bundle component-specific dependencies in `vendor/`
6. Update `manifest.json`
7. Create tests (both HTML and MATLAB)
8. Document in `docs/components/`

See [Component Structure Guide](../development/component-structure.md) for detailed instructions.

## Next Steps

- [Component Structure Guide](../development/component-structure.md) - Build components
- [Testing Guide](../development/testing.md) - Write tests
- [Versioning Guide](../development/versioning.md) - Manage dependencies
