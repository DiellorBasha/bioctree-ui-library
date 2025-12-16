# ManifoldBrushToolbar

Vertical toolbar component for selecting brush tools in manifold visualization applications.

## Overview

ManifoldBrushToolbar is a MATLAB `ComponentContainer` that displays a vertical toolbar with selectable brush tools. It integrates with `ManifoldBrushContext` to manage brush selection state and coordinates with other UI components.

## Features

- **D3.js SVG rendering** - Smooth, interactive tool buttons
- **Tabler icon support** - Clean, modern SVG icons
- **Active state tracking** - Visual feedback for selected tool
- **Event-driven architecture** - Emits `BrushSelected` event on tool click
- **Context integration** - Updates `ManifoldBrushContext.BrushModel` automatically

## Architecture

```
@ManifoldBrushToolbar/
├── ManifoldBrushToolbar.m    # MATLAB ComponentContainer class
├── README.md
└── web/
    ├── index.html             # HTML entry point
    ├── main.js                # Bootstrap and lifecycle
    ├── render.js              # D3.js toolbar rendering
    ├── styles.css             # Dark theme styling
    └── vendor/
        ├── d3.v5.9.2.min.js   # D3.js library
        └── icons/
            ├── point.svg      # Delta brush icon
            ├── graph.svg      # Graph brush icon
            └── wave-sine.svg  # Spectral brush icon
```

## Usage

### Basic Setup

```matlab
% Create figure and context
fig = uifigure('Position', [100 100 800 600]);
context = ManifoldBrushContext();
context.Manifold = myManifold;

% Create toolbar
toolbar = ManifoldBrushToolbar(fig, 'Context', context);
toolbar.Position = [10 10 60 400];
```

### With Event Callback

```matlab
toolbar = ManifoldBrushToolbar(fig, 'Context', context);

% Listen for brush selection
addlistener(toolbar, 'BrushSelected', @(src, event) ...
    fprintf('Selected brush: %s\n', event.BrushType));
```

### Integration with ManifoldController

```matlab
% ManifoldController automatically creates and manages toolbar
controller = ManifoldController(fig);
controller.initializeFromManifold(manifold);

% Toolbar is accessible via controller.Toolbar_
controller.Toolbar_.Position = [10 10 60 500];
```

## Properties

### Public Properties

- **`Context`** (`ManifoldBrushContext`) - State management context
  - Required for brush creation and synchronization
  - Toolbar updates `Context.BrushModel` on tool selection

- **`BrushRegistry`** (cell array of structs) - Tool definitions
  - Each struct contains: `id`, `icon`, `label`, `factory`
  - Loaded from `ManifoldBrushRegistry()` by default
  - Customize by setting after construction

- **`ActiveBrush`** (string) - Currently selected brush ID
  - Valid values: `'delta'`, `'graph'`, `'spectral'`
  - Updates automatically on tool click
  - Triggers visual active state in toolbar

## Events

### `BrushSelected`

Fired when user clicks a tool button.

**Event Data:**
- `BrushType` (string) - ID of selected brush (`'delta'`, `'graph'`, `'spectral'`)

**Example:**
```matlab
addlistener(toolbar, 'BrushSelected', @(src, event) ...
    fprintf('User selected %s brush\n', event.BrushType));
```

## Methods

### Public Methods

*None* - Toolbar is fully automatic via property changes and event handlers

### Protected Methods (Lifecycle)

- **`setup(comp)`** - Initialize HTML component and event handlers
- **`update(comp)`** - Sync toolbar data to JavaScript on property changes

### Private Methods

- **`onBrushClick(comp, event)`** - Handle tool click events from JavaScript
  - Parses `event.HTMLEventData` to get clicked tool ID
  - Creates brush instance from registry factory
  - Updates `Context.BrushModel` with new brush
  - Emits `BrushSelected` event

## Data Flow

### MATLAB → JavaScript

1. User sets `toolbar.Context` or `toolbar.ActiveBrush`
2. `update()` method packages data into struct:
   ```matlab
   toolbarData.tools = [
       struct('id', 'delta', 'icon', 'point.svg', 'label', 'Delta Brush', 'active', true),
       struct('id', 'graph', 'icon', 'graph.svg', 'label', 'Graph Brush', 'active', false),
       ...
   ];
   ```
3. `HTMLComponent.Data = toolbarData` triggers JavaScript `DataChanged` event
4. `renderToolbar()` updates SVG with D3.js

### JavaScript → MATLAB

1. User clicks tool button in SVG
2. D3 click handler dispatches `CustomEvent('ToolClicked')` with tool ID
3. MATLAB receives `HTMLEventReceivedFcn` callback
4. `onBrushClick()` creates brush and updates context
5. `BrushSelected` event notifies listeners

## Styling

Toolbar uses dark theme consistent with MATLAB App Designer:

- **Background:** `#1e1e1e`
- **Tool button:** `#2a2a2a` with `#444` border
- **Hover state:** `#333` background, `#666` border
- **Active state:** `#3b82f6` (blue) background, `#60a5fa` border, 2px stroke

Icons have 0.8 opacity by default, 1.0 when active.

## Brush Registry

### Default Registry

`ManifoldBrushRegistry()` returns:

```matlab
{
  struct('id', 'delta', 'icon', 'point.svg', 'label', 'Delta Brush', 'factory', @(m) DeltaBrush(m)),
  struct('id', 'graph', 'icon', 'graph.svg', 'label', 'Graph Brush', 'factory', @(m) GraphBrush(m)),
  struct('id', 'spectral', 'icon', 'wave-sine.svg', 'label', 'Spectral Brush', 'factory', @(m) SpectralBrush(m))
}
```

### Custom Registry

```matlab
toolbar.BrushRegistry = {
    struct('id', 'custom', ...
           'icon', 'my-icon.svg', ...
           'label', 'My Brush', ...
           'factory', @(m) MyCustomBrush(m))
};
```

## Dependencies

### MATLAB Classes
- `ManifoldBrushContext` - State management
- `DeltaBrush`, `GraphBrush`, `SpectralBrush` - Brush implementations
- `ManifoldBrushRegistry` - Tool definitions
- `bct.Manifold` - Geometry data

### JavaScript Libraries
- **D3.js v5.9.2** - SVG rendering and interaction
- Uses D3 v5 event model (`d3.event` global)

### Icons
- Tabler Icons (SVG format) in `web/vendor/icons/`
- Customizable by replacing SVG files

## Critical Implementation Details

### HTMLSource Resolution

Uses static method for robust path resolution:

```matlab
methods (Access = private, Static)
    function htmlPath = resolveHTMLSource()
        classFile = mfilename('fullpath');
        classDir = fileparts(classFile);
        htmlPath = fullfile(classDir, 'web', 'index.html');
    end
end
```

### HTML Component Positioning

Explicitly set in `setup()`:

```matlab
comp.HTMLComponent.Position = [1 1 comp.Position(3:4)];
```

### D3.js Event Handling

Uses D3 v5 pattern with `d3.event` global:

```javascript
.on('click', function(d) {
    htmlComponent.dispatchEvent(new CustomEvent('ToolClicked', {
        detail: JSON.stringify({ id: d.id })
    }));
});
```

## Testing

### Browser Test

Open `tests/html/test_ManifoldBrushToolbar.html` to test:
- Icon rendering
- Click interactions
- Active state updates
- Event dispatching

### MATLAB Test

```matlab
% tests/matlab/test_ManifoldBrushToolbar.m
fig = uifigure('Position', [100 100 200 400]);
context = ManifoldBrushContext();
% ... set up manifold in context

toolbar = ManifoldBrushToolbar(fig, 'Context', context);
toolbar.Position = [10 10 60 380];

% Test event handling
addlistener(toolbar, 'BrushSelected', @(src, event) ...
    fprintf('Brush changed to: %s\n', event.BrushType));
```

## Version History

- **v1.0** - Initial release
  - D3.js v5.9.2 integration
  - Tabler icon support
  - Context-driven brush selection

## Critical Dependency Information

- **D3.js Version:** 5.9.2 (Do not upgrade without updating event handlers)
- **Event Model:** D3 v5 (uses `d3.event` global)
- **Icon Source:** Tabler Icons (SVG)
