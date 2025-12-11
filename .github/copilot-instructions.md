# Copilot Instructions for bioctree-ui-library

## Project Overview
Library of custom UI components built with D3.js for integration with MATLAB. Components are MATLAB classes that embed HTML/CSS/JavaScript to create interactive visualizations using the `matlab.ui.componentcontainer.ComponentContainer` pattern.

## Architecture

### Component Structure
Each component follows a standardized file naming pattern in `components/@ComponentName/`:
- `ComponentName.m` - MATLAB class extending `matlab.ui.componentcontainer.ComponentContainer`
- `ComponentName.html` - HTML container template (shadow DOM equivalent)
- `ComponentName.css` - Component-specific styles
- `ComponentName.js` - Controller script (lifecycle, MATLAB communication, event dispatching)
- `ComponentName.render.js` - Pure rendering logic (D3 visualization, no lifecycle)
- `ComponentName.utils.js` - (Optional) Reusable utility functions
- `vendor/` - Component-specific vendored dependencies

**Example:** `@d3Brush/` contains:
```
@d3Brush/
├── d3Brush.m              # MATLAB class
├── d3Brush.html           # Template
├── d3Brush.css            # Styles
├── d3Brush.js             # Controller (setup, lifecycle)
├── d3Brush.render.js      # D3 rendering logic
└── vendor/
    └── d3.v5.9.2.min.js   # Vendored dependency
```

**File Responsibilities:**
- **Controller (`ComponentName.js`)**: Manages `setup()` function, receives MATLAB Data updates, dispatches CustomEvents to MATLAB, handles lifecycle
- **Renderer (`ComponentName.render.js`)**: Pure D3 visualization logic - creates SVG, draws elements, handles D3 events (start, brush, end)
- **Utilities (`ComponentName.utils.js`)**: Optional helpers like `snappedRange()`, `pixelToValue()`, `clamp()`, tick formatters

**Why This Pattern?**
- Clean separation of concerns (lifecycle vs rendering)
- Easier debugging (isolate rendering issues from communication issues)
- Path resolution is straightforward: `fullfile(folder, 'ComponentName.html')`
- Follows web component best practices

### MATLAB-JavaScript Communication Pattern
Components use `matlab.ui.control.HTML` for bidirectional communication:

**MATLAB → JavaScript:** Via `HTMLComponent.Data` property
```matlab
brushData = struct();
brushData.min = comp.Min;
brushData.max = comp.Max;
comp.HTMLComponent.Data = brushData;
```

**JavaScript → MATLAB:** Via CustomEvent dispatching
```javascript
htmlComponent.dispatchEvent(new CustomEvent('ValueChanged', {
    detail: JSON.stringify({ selection: [20, 60] })
}));
```

**MATLAB Event Handling:**
```matlab
comp.HTMLComponent.HTMLEventReceivedFcn = @(src, event) comp.handleBrushEvent(event);
% Access data via: jsondecode(event.HTMLEventData)
```

### Required MATLAB Methods
All components must implement:
- `setup(comp)` - Create HTML component with relative path, set normalized units, call `update()` at end
- `update(comp)` - Sync properties to `HTMLComponent.Data`, avoid manual positioning
- Event handler method (e.g., `handleBrushEvent`) - Parse `event.HTMLEventData` with `jsondecode()` in try-catch
- `delete(comp)` - Clean up timers and resources

### Critical Implementation Rules
1. **HTMLSource must use relative paths** - Never use `fullfile(fileparts(mfilename('fullpath')))` as this breaks toolbox packaging and App Designer
   ```matlab
   comp.HTMLComponent.HTMLSource = 'ComponentName.html';  % Correct - matches class name
   ```

2. **HTML components auto-fill their container** - Don't set Units or Position manually
   ```matlab
   % Incorrect - Units/Position not supported on HTML components
   % comp.HTMLComponent.Units = 'normalized';
   % comp.HTMLComponent.Position = [0 0 1 1];
   
   % Correct - HTML component automatically fills the ComponentContainer
   comp.HTMLComponent = uihtml(comp);
   comp.HTMLComponent.HTMLSource = 'ComponentName.html';
   ```

3. **Property validation** - Use dependent properties with setters for complex validation
   ```matlab
   properties (Dependent)
       Value
   end
   properties (Access = private)
       Value_ (1,2) double = [20 60]
   end
   methods
       function set.Value(comp, val)
           val = sort(val);
           val = [max(comp.Min, val(1)), min(comp.Max, val(2))];
           comp.Value_ = val;
           comp.update();  % Sync to JS
       end
   end
   ```

4. **Event throttling** - Use timers to throttle rapid JS events (e.g., brush dragging)
   ```matlab
   comp.ThrottleTimer = timer('ExecutionMode', 'singleShot', 'StartDelay', 0.05);
   ```

5. **Standard event pattern** - Follow MATLAB UI conventions:
   - `ValueChanging` - During interaction (throttled)
   - `ValueChanged` - On release/completion
   - Component-specific events (e.g., `BrushStarted`, `BrushEnded`)

### JavaScript Setup Pattern
Controller files (`ComponentName.js`) must define `setup(htmlComponent)` function called by MATLAB:
```javascript
function setup(htmlComponent) {
    var data = htmlComponent.Data;
    renderComponent(data, htmlComponent);
    
    htmlComponent.addEventListener("DataChanged", function(event) {
        renderComponent(htmlComponent.Data, htmlComponent);
    });
}
```

Rendering logic (`ComponentName.render.js`) contains pure visualization functions:
```javascript
function renderComponent(data, htmlComponent) {
    // Pure D3 rendering - no lifecycle management
    // Creates SVG, draws elements, handles D3 events
}
```

## File Organization

### Asset Structure
- `lib/d3/` - Shared D3.js library versions (explicitly versioned)
- `lib/tailwind/` - Tailwind CSS (if needed)
- `lib/assets/` - Shared resources (currently empty)
- `assets/icons/` - SVG/image assets
- `assets/shared.css` - Global styles for all components
- `assets/shared.js` - Shared JavaScript utilities for all components
- `manifest.json` - Component dependency manifest and version tracking

### Component Vendor Dependencies
Each component maintains its own `vendor/` directory for encapsulated dependencies:
```
components/@ComponentName/
├── ComponentName.m
├── component_name.html
├── component_name.css
├── component_name_rendering.js
├── vendor/
│   └── d3.v5.9.2.min.js    # Component-specific D3 version
└── README.md                # Must document dependency versions
```

**Why Component-Level Vendoring?**
- Prevents version conflicts between components
- Explicit dependency tracking per component
- Safe component-by-component upgrades
- Follows web component best practices

### Relative Paths in HTML
HTML files reference D3 and assets with relative paths from component directory:
```html
<script src="vendor/d3.v5.9.2.min.js"></script>
<link rel="stylesheet" href="ComponentName.css">
<script src="ComponentName.render.js"></script>
<script src="ComponentName.js"></script>
```

### Dependency Versioning
**Critical:** Always use explicit version numbers in filenames and paths.

**D3.js Version Management:**
- Each component bundles its own D3 version in `vendor/` directory
- Filename MUST include version: `d3.v5.9.2.min.js` (never `d3.min.js`)
- Component README MUST document exact D3 version and event model
- Update `manifest.json` when adding or upgrading dependencies

**Why explicit versioning matters:**
- D3 v5 uses `d3.event` global (event handlers: `function() { var event = d3.event; }`)
- D3 v6+ passes event as parameter (event handlers: `function(event) { }`)
- Wrong version = silent failures in event handling
- Version in filename prevents accidental upgrades

**Example version lock in component README:**
```markdown
## Critical Dependency Information
- **D3.js Version:** 5.9.2 (Do not upgrade without updating event handlers)
- **Event Model:** D3 v5 (uses d3.event global)
```

## Development Conventions

### Naming Conventions
- **MATLAB class:** PascalCase matching folder name (`d3Brush.m` in `@d3Brush/`)
- **HTML/CSS/JS files:** PascalCase matching component name:
  - `d3Brush.html` - Template
  - `d3Brush.css` - Styles
  - `d3Brush.js` - Controller
  - `d3Brush.render.js` - Renderer
  - `d3Brush.utils.js` - (Optional) Utilities
- **Component folder:** `@PascalCaseName` (e.g., `@d3Brush`)

**Why standardized naming?**
- Clean path resolution: `fullfile(folder, 'ComponentName.html')`
- Easy to identify file purpose at a glance
- Consistent with MATLAB's class file requirements
- Simplifies autoloading and packaging

### Event Flow
1. **BrushStarted** - User interaction begins (notify only)
2. **ValueChanging** - Active dragging (throttled updates, ~50ms)
3. **ValueChanged** + **BrushEnded** - Interaction complete (notify both)

Note: Follow MATLAB's standard event pattern where `ValueChanging` fires during interaction and `ValueChanged` fires on completion.

### D3.js Integration
- Use D3 v7 patterns (selection-based, no jQuery)
- Clear previous renders: `d3.select("svg").remove()` before redraw
- Implement responsive sizing using container `getBoundingClientRect()`
- Follow Observable D3 examples for reference (e.g., brush snapping)

### Component Versioning
- Each component tracks its own version in the MATLAB class file header
- Each component bundles its specific D3 version in `vendor/` directory
- Root `manifest.json` tracks all component dependencies and versions
- When updating D3.js, test all components for breaking changes
- Document version compatibility in component README.md

## Adding New Components

1. Create `components/@ComponentName/` folder
2. Create MATLAB class extending `ComponentContainer`:
   - Define public properties
   - Implement `setup()` and `update()` methods
   - Create `HTMLComponent` pointing to HTML file
3. Create HTML file (template only, no inline scripts)
4. Create CSS file for component-specific styles
5. Create controller JS file (`ComponentName.js`) with `setup()` function
6. Create rendering JS file (`ComponentName.render.js`) with visualization logic
7. **Create `vendor/` directory and copy required D3 version**
8. **Create `README.md` documenting exact dependency versions**
9. Ensure HTML references all files with correct relative paths
10. **Update root `manifest.json` with new component entry**

## Testing Workflow

### Two-Tier Testing Strategy

**1. UI Testing (Browser Console)**
Test HTML, D3.js rendering, and styling independently:
- Open component HTML file in browser
- Use browser console to test JavaScript functions
- Validate D3 rendering, interactions, and CSS styles
- Test with mock data structures matching MATLAB's `HTMLComponent.Data` format

**Browser Test Location:** `tests/html/test_ComponentName.html`

Test utilities available in `tests/html/test-utils.js`:
- `MockHTMLComponent` - Simulates MATLAB's htmlComponent
- `TestLogger` - Event and message logging
- `TestValidators` - Validation helpers (SVG exists, data validity, etc.)
- `TestDataGenerator` - Generate valid/invalid test data
- `PerformanceTester` - Measure render times and event throughput

**2. Integration Testing (MATLAB)**
Use MATLAB's native testing framework for component integration:
```matlab
% Manual testing in MATLAB
fig = uifigure('Position', [100 100 600 300]);
brush = d3Brush(fig, 'Position', [10 10 580 280]);
brush.Min = 0;
brush.Max = 100;
brush.SnapInterval = 5;
brush.ValueChangedFcn = @(src, event) disp(event.Value);
```

For automated tests, use MATLAB's test batteries to verify:
- Property synchronization between MATLAB and JavaScript
- Event dispatching and handling
- Component lifecycle (setup, update, resize)

## Critical Implementation Details

### Property Changes
Always trigger `update()` by setting `Position` or directly modifying `Data`:
```matlab
comp.HTMLComponent.Data = brushData; % Triggers DataChanged event in JS
```

### Event Data Structure
JavaScript events must use `JSON.stringify()` in CustomEvent detail:
```javascript
detail: JSON.stringify({ selection: [start, end] })
```
MATLAB decodes with `jsondecode(event.HTMLEventData)`.

### Console Logging
Use prefixed console logs for debugging: `console.log('[ComponentName] message')`

## Deployment

Components are distributed in two formats:

1. **MATLAB Toolbox** - Packaged for MATLAB App Designer integration
   - Components extend `matlab.ui.componentcontainer.ComponentContainer`
   - Installed via MATLAB's Add-On Manager
   - Full MATLAB-JavaScript bidirectional communication

2. **Standalone D3.js Library** - Pure JavaScript component library
   - Independent of MATLAB for web applications
   - Components work as standard D3.js modules
   - Use same rendering logic from `*_rendering.js` files

## Dependencies
- MATLAB R2020b+ (for `ComponentContainer` support, MATLAB toolbox only)
- D3.js v7 (included in `lib/d3/`)
- No build process - direct file loading in MATLAB or browser

## Reference Documentation
- [Customize Extensible UI Component Properties](https://www.mathworks.com/help/matlab/creating_guis/customize-extensible-ui-component-properties.html)
- [Develop Classes of UI Component Objects](https://www.mathworks.com/help/matlab/creating_guis/develop-classes-of-ui-component-objects.html)
- [Debug HTML Content in Apps](https://www.mathworks.com/help/matlab/creating_guis/debug-html-content-in-apps.html)
- [GUI with Embedded HTML Content in App Designer](https://www.mathworks.com/help/matlab/creating_guis/gui-with-embedded-html-content-in-app-designer.html)
