# Copilot Instructions for bioctree-ui-library

## Project Overview
Library of custom UI components built with D3.js for integration with MATLAB. Components are MATLAB classes that embed HTML/CSS/JavaScript to create interactive visualizations using the `matlab.ui.componentcontainer.ComponentContainer` pattern.

## Architecture

### Component Structure
Each component follows a standardized structure in `components/@ComponentName/`:

```
@ComponentName/
├── ComponentName.m         # MATLAB class (authoritative API)
├── README.md              # Component documentation
├── web/                   # Web assets (entry point for uihtml)
│   ├── index.html         # HTML entry point
│   ├── main.js            # Bootstrap/lifecycle controller
│   ├── render.js          # Visualization rendering logic
│   ├── styles.css         # Component-specific styles
│   └── vendor/            # Vendored dependencies
│       ├── d3.v5.9.2.min.js
│       └── tailwind.min.css
└── assets/                # Optional (icons, SVGs, resources)
```

**Example:** `@d3Brush/` contains:
```
@d3Brush/
├── d3Brush.m              # MATLAB ComponentContainer class
├── README.md              # Usage documentation
└── web/
    ├── index.html         # Entry point (loaded by uihtml)
    ├── main.js            # Component bootstrap & lifecycle
    ├── render.js          # D3 brush rendering logic
    ├── styles.css         # Brush-specific styles
    └── vendor/
        └── d3.v5.9.2.min.js
```

**File Responsibilities:**
- **`ComponentName.m`**: MATLAB class extending `ComponentContainer`, defines properties, events, and MATLAB-side API
- **`web/index.html`**: HTML entry point loaded by `uihtml()`, includes script/style references
- **`web/main.js`**: Bootstrap logic, `setup()` function, MATLAB communication, lifecycle management
- **`web/render.js`**: Pure visualization logic (D3, Canvas, WebGL), no lifecycle code
- **`web/styles.css`**: Component-specific CSS (Tailwind build or custom styles)
- **`web/vendor/`**: Encapsulated dependencies with explicit versions

**Why This Structure?**
- **Standard entry points** (`index.html`, `main.js`) follow web conventions
- **Clean separation**: Bootstrap (main.js) vs rendering (render.js) vs styles (styles.css)
- **Encapsulated dependencies**: Each component bundles its own versions in `web/vendor/`
- **Path resolution**: Relative paths from `web/index.html` work naturally
- **Scalability**: Easy to add shaders, workers, or assets without cluttering root

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
1. **HTMLSource must use static method for path resolution**
   ```matlab
   % In setup() method:
   comp.HTMLComponent.HTMLSource = ComponentName.resolveHTMLSource();
   
   % Add static method for path resolution:
   methods (Access = private, Static)
       function htmlPath = resolveHTMLSource()
           classFile = mfilename('fullpath');
           classDir = fileparts(classFile);
           htmlPath = fullfile(classDir, 'web', 'index.html');
       end
   end
   ```
   This approach works in both development and packaged toolbox scenarios.

2. **HTML component Position must be explicitly set** - Set position relative to ComponentContainer
   ```matlab
   % In setup() - initial positioning
   comp.HTMLComponent = uihtml(comp);
   comp.HTMLComponent.Position = [1 1 comp.Position(3:4)];  % [x y width height]
   
   % In update() - maintain sizing when properties change
   comp.HTMLComponent.Position = [1 1 comp.Position(3:4)];
   ```
   
   The Position is relative to the ComponentContainer:
   - `[1 1 ...]` - positioned at (1,1) within container
   - `comp.Position(3:4)` - width and height match container dimensions

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
Controller files (`web/main.js`) must define `setup(htmlComponent)` function called by MATLAB:
```javascript
function setup(htmlComponent) {
    var data = htmlComponent.Data;
    renderComponent(data, htmlComponent);
    
    htmlComponent.addEventListener("DataChanged", function(event) {
        renderComponent(htmlComponent.Data, htmlComponent);
    });
}
```

Rendering logic (`web/render.js`) contains pure visualization functions:
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
Each component maintains its own `web/vendor/` directory for encapsulated dependencies:
```
components/@ComponentName/
├── ComponentName.m
├── README.md                # Must document dependency versions
└── web/
    ├── index.html
    ├── main.js
    ├── render.js
    ├── styles.css
    └── vendor/
        └── d3.v5.9.2.min.js    # Component-specific D3 version
```

**Why Component-Level Vendoring?**
- Prevents version conflicts between components
- Explicit dependency tracking per component
- Safe component-by-component upgrades
- Follows web component best practices

### Relative Paths in HTML
HTML files reference scripts and styles with relative paths from `web/` directory:
```html
<script src="vendor/d3.v5.9.2.min.js"></script>
<link rel="stylesheet" href="styles.css">
<script src="render.js"></script>
<script src="main.js"></script>
```

### Dependency Versioning
**Critical:** Always use explicit version numbers in filenames and paths.

**D3.js Version Management:**
- Each component bundles its own D3 version in `web/vendor/` directory
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
- Each component bundles its specific D3 version in `web/vendor/` directory
- Root `manifest.json` tracks all component dependencies and versions
- When updating D3.js, test all components for breaking changes
- Document version compatibility in component README.md

## Adding New Components

1. Create `components/@ComponentName/` folder
2. Create MATLAB class extending `ComponentContainer`:
   - Define public properties
   - Implement `setup()` and `update()` methods
   - Create `HTMLComponent` pointing to `web/index.html`
3. Create `web/` directory structure
4. Create `web/index.html` (template only, no inline scripts)
5. Create `web/styles.css` for component-specific styles
6. Create `web/main.js` with `setup()` function
7. Create `web/render.js` with visualization logic
8. **Create `web/vendor/` directory and copy required D3 version**
9. **Create `README.md` documenting exact dependency versions**
10. Ensure `index.html` references all files with correct relative paths
11. **Update root `manifest.json` with new component entry**

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
