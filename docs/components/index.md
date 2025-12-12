# Components Overview

The bioctree UI Library provides a collection of interactive components designed for MATLAB integration with D3.js visualizations.

## Available Components

### d3Brush

An interactive brush component for range selection with snapping support.

**Key Features:**
- Adjustable min/max range
- Configurable snap intervals
- Real-time value updates
- Multiple event types
- Smooth D3 animations

[View Full Documentation →](d3brush.md){ .md-button }

---

## Coming Soon

More components are in development. Check back for updates!

## Component Architecture

All components follow a standardized architecture:

```
@ComponentName/
├── ComponentName.m          # MATLAB class
├── ComponentName.html       # HTML template
├── ComponentName.css        # Styles
├── ComponentName.js         # Controller (lifecycle)
├── ComponentName.render.js  # Renderer (visualization)
├── ComponentName.utils.js   # Optional utilities
├── vendor/                  # Component dependencies
│   └── d3.v5.9.2.min.js
└── README.md               # Component documentation
```

### File Responsibilities

| File | Purpose |
|------|---------|
| **`.m`** | MATLAB class extending `ComponentContainer`, handles property management and events |
| **`.html`** | HTML template, loads scripts and defines structure |
| **`.css`** | Component-specific styles |
| **`.js`** | Controller - manages lifecycle, data flow, MATLAB communication |
| **`.render.js`** | Renderer - pure D3.js visualization logic |
| **`.utils.js`** | Optional helpers and utility functions |
| **`vendor/`** | Bundled dependencies with explicit version numbers |

## Communication Pattern

Components use bidirectional communication between MATLAB and JavaScript:

### MATLAB → JavaScript
```matlab
% Update component data
comp.HTMLComponent.Data = struct('min', 0, 'max', 100);
```

### JavaScript → MATLAB
```javascript
// Dispatch custom event to MATLAB
htmlComponent.dispatchEvent(new CustomEvent('ValueChanged', {
    detail: JSON.stringify({ selection: [20, 60] })
}));
```

## Common Properties

Most components share these standard properties:

| Property | Type | Description |
|----------|------|-------------|
| `Position` | `[x y width height]` | Component position in parent |
| `Visible` | `on \| off` | Visibility state |
| `Enable` | `on \| off` | Enable/disable interaction |

## Events

Components typically support these event types:

| Event | When Fired |
|-------|------------|
| `ValueChanging` | During interaction (throttled) |
| `ValueChanged` | On interaction completion |
| Component-specific | E.g., `BrushStarted`, `BrushEnded` |

## Creating Custom Components

Want to create your own component? See our [Component Structure Guide](../development/component-structure.md) for detailed instructions.
