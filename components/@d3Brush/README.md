# d3Brush Component

## Overview
Interactive brush component with snap-to-interval functionality for range selection. Built with D3.js for integration with MATLAB's `ComponentContainer` framework.

## Version Information
- **Component Version:** 1.0.0
- **D3.js Version:** 5.9.2 (Critical - do not change)
- **MATLAB Version:** R2020b or later
- **Event Model:** D3 v5

## Critical Dependency Information

### ⚠️ D3.js Version Lock
This component **MUST** use D3.js version 5.9.2. It is bundled in `vendor/d3.v5.9.2.min.js`.

**Why the version lock?**
- D3 v5 uses the `d3.event` global variable for event handling
- D3 v6+ passes `event` as a parameter to callbacks
- This is a **breaking API change** that causes silent failures

### Event Handling Patterns

**D3 v5 (Current):**
```javascript
function brushed() {
    var event = d3.event;  // Access global d3.event
    if (event.sourceEvent) {
        // Handle event
    }
}
```

**D3 v6+ (NOT Compatible):**
```javascript
function brushed(event) {  // event passed as parameter
    if (event.sourceEvent) {
        // Handle event
    }
}
```

### ⛔ Migration Warning
**DO NOT upgrade to D3 v6+ without:**
1. Updating all event handler signatures in `d3_brush_rendering.js`
2. Changing from `var event = d3.event;` to function parameters
3. Testing all three event handlers: `brushStarted()`, `brushed()`, `brushEnded()`
4. Updating this README with new version information
5. Updating `manifest.json` at repository root

## Component Files

### Core Files
- `d3Brush.m` - MATLAB class extending `ComponentContainer`
- `d3Brush.html` - HTML container template
- `d3Brush.css` - Component-specific styles
- `d3Brush.js` - Controller (lifecycle & MATLAB communication)
- `d3Brush.render.js` - Pure rendering logic (D3 visualization)

### Dependencies
- `vendor/d3.v5.9.2.min.js` - Bundled D3 library (component-specific)

## Usage

### MATLAB Example
```matlab
% Create figure
fig = uifigure('Position', [100 100 600 300]);

% Create brush component
brush = d3Brush(fig, 'Position', [10 10 580 280]);

% Set properties
brush.Min = 0;
brush.Max = 100;
brush.SnapInterval = 5;
brush.Value = [20 60];

% Add event listener
brush.ValueChangedFcn = @(src, event) disp(event.Value);
```

## Properties

### Public Properties
- `Min` (double) - Minimum value of range (default: 0)
- `Max` (double) - Maximum value of range (default: 100)
- `SnapInterval` (double) - Snap interval (0 = no snapping, default: 1)
- `Value` (1x2 double) - Current selection [start, end] (default: [20 60])

### Events
- `ValueChanging` - Fires during brush drag (throttled to ~50ms)
- `ValueChanged` - Fires when brush interaction completes
- `BrushStarted` - Fires when user starts dragging
- `BrushEnded` - Fires when user releases brush

## Architecture

### MATLAB-JavaScript Communication
Uses `matlab.ui.control.HTML` component for bidirectional communication:

**MATLAB → JavaScript:**
```matlab
brushData.min = comp.Min;
brushData.max = comp.Max;
comp.HTMLComponent.Data = brushData;  % Triggers DataChanged event in JS
```

**JavaScript → MATLAB:**
```javascript
htmlComponent.dispatchEvent(new CustomEvent('ValueChanged', {
    detail: JSON.stringify({ selection: [20, 60] })
}));
```

## Testing

### Browser Tests
Located in `../../tests/html/test_d3_brush.html`

Run by opening the HTML file directly in a browser for isolated UI testing.

### MATLAB Tests
Located in `../../tests/matlab/` (TBD)

## Known Issues
None currently. Component is production-ready as of version 1.0.0.

## Development Notes

### Adding Features
1. Update MATLAB class version number
2. Update this README
3. Add browser tests for new functionality
4. Update MATLAB integration tests

### Debugging
- Use browser console for JavaScript debugging
- Component includes detailed console logging
- MATLAB debugging: Use breakpoints in class methods

## License
Part of bioctree-ui-library. See root LICENSE file.

## References
- [MATLAB ComponentContainer Documentation](https://www.mathworks.com/help/matlab/creating_guis/develop-classes-of-ui-component-objects.html)
- [D3.js v5 Documentation](https://github.com/d3/d3/blob/v5.9.2/API.md)
- [D3 v5 to v6 Migration Guide](https://observablehq.com/@d3/d3v6-migration-guide)
