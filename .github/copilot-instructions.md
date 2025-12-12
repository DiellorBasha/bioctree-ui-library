# Copilot Instructions for bioctree-ui-library

## Project Overview
Library of custom UI components built with D3.js and Observable Plot for integration with MATLAB. Components are MATLAB classes that embed HTML/CSS/JavaScript to create interactive visualizations using the `matlab.ui.componentcontainer.ComponentContainer` pattern.

The library provides two types of component architectures:
- **Controllers** (`controllers/@ComponentName/`) - Interactive components with bidirectional data flow, events, and callbacks
- **Views** (`views/@ViewName/`) - Read-only data visualization components with one-way data flow

## Quick Start: Creating New Components

### Using Templates (Recommended)

The library includes template scaffolding for rapid component creation:

```matlab
% Create an Observable Plot view (one-way data flow)
createComponentTemplate("MyChart", "library", "observable-plot", "type", "view")

% Create a D3 interactive component (bidirectional with events)
createComponentTemplate("MyBrush", "library", "d3", "type", "component")

% Create a custom component
createComponentTemplate("MyViz", "library", "custom", "type", "component")

% Create with automatic test file generation
createComponentTemplate("DensityChart", "library", "observable-plot", "type", "view", "testData", "../data/faithful.tsv")
```

**Template Arguments:**
- `library` - JavaScript library to use:
  - `'observable-plot'` - Observable Plot v0.6.17 (UMD) + D3.js
  - `'d3'` - D3.js v5.9.2 only
  - `'custom'` - Basic structure, bring your own libraries
- `type` - Component category:
  - `'view'` - One-way data flow, no events, saved in `views/`
  - `'component'` - Bidirectional, events/callbacks, saved in `components/`
- `testData` - (Optional) Path to test data file (e.g., `'../data/faithful.tsv'`)
  - Generates test files in `tests/html/` and `tests/matlab/`
  - Automatically adds data loading code for CSV, TSV, and JSON formats
  - Creates multiple test cases with different configurations

**What Templates Provide:**
- ✅ Correct directory structure (`web/`, `web/vendor/`)
- ✅ MATLAB class with proper patterns (VIEW or COMPONENT)
- ✅ HTML/JS/CSS files with placeholders
- ✅ Library files automatically copied to `web/vendor/`
- ✅ README with library version documentation
- ✅ Retry logic for container dimensions
- ✅ Event patterns (D3 v5 or Observable Plot)
- ✅ Test files (HTML and MATLAB) when testData is specified

**After Template Creation:**
1. Navigate to the created directory
2. Implement visualization logic in `web/render.js`
3. Add properties to `ComponentName.m`
4. Update README with usage examples
5. If testData was provided, customize test files in `tests/matlab/` and `tests/html/`
6. If testData was not provided, manually create test files using the template patterns

### Template Locations
- `utils/templates/observable-plot/` - Observable Plot view templates
  - `index.html`, `main.js`, `render.js`, `styles.css` - Component files
  - `test.html`, `test.m` - Test file templates
- `utils/templates/d3/` - D3.js component templates
  - `index.html`, `main.js`, `render.js`, `styles.css` - Component files
  - `test.html`, `test.m` - Test file templates
- `utils/createComponentTemplate.m` - Template generation function

### Test File Templates
Test templates are automatically generated when the `testData` parameter is provided:

**HTML Test Template (`tests/html/test_ComponentName.html`):**
- Loads libraries from `../../lib/observable-plot/` or `../../lib/d3/`
- Loads component files from `../../views/@ComponentName/web/` or `../../controllers/@ComponentName/web/`
- Creates multiple test containers with different configurations
- Includes automatic data loading (d3.csv, d3.tsv, d3.json based on file extension)
- Mock htmlComponent for standalone testing

**MATLAB Test Template (`tests/matlab/test_ComponentName.m`):**
- Path setup using `fileparts(mfilename('fullpath'))`
- Automatic data loading (readtable with appropriate delimiters)
- Multiple test sections: Basic, styling, dynamic updates, empty data
- Uses uifigure with positioned views/components
- Comprehensive fprintf output for test progress

## Architecture

### Component Structure
Each controller follows a standardized structure in `controllers/@ComponentName/`:

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

## Views vs Components

### Views (`views/@ViewName/`)
Views are **read-only data visualization components** with simplified architecture:

**Purpose:**
- Display data without user interaction
- One-way data flow (MATLAB → JavaScript only)
- Pure visualization rendering

**Structure:** Same as components
```
views/@ViewName/
├── ViewName.m              # MATLAB class
├── README.md
└── web/
    ├── index.html
    ├── main.js            # Simplified: only DataChanged listener
    ├── render.js          # Pure rendering, no event dispatching
    ├── styles.css
    └── vendor/
```

**Key Differences from Components:**

| Aspect | Components | Views |
|--------|-----------|-------|
| **Data Flow** | Bidirectional | One-way (MATLAB → JS) |
| **Properties** | Multiple interactive properties | Minimal (usually just `Data`) |
| **Events** | Multiple (ValueChanged, etc.) | None |
| **Callbacks** | Yes (ValueChangedFcn, etc.) | None |
| **MATLAB Methods** | `setup()`, `update()`, event handlers, `delete()` | `setup()`, `update()` only |
| **JavaScript** | Controller + event dispatching | Simplified controller, no events |
| **Use Case** | Interactive selection, filtering | Charts, graphs, static visualizations |

**View Constraints:**
1. ❌ **No events** - No `events` block in MATLAB class
2. ❌ **No callbacks** - No `HasCallbackProperty` properties
3. ❌ **No event dispatching** - JavaScript should not call `htmlComponent.dispatchEvent()`
4. ❌ **No event handlers** - No `HTMLEventReceivedFcn` in setup
5. ✅ **Simplified update** - Only pushes data via `HTMLComponent.Data`
6. ✅ **Pure rendering** - JavaScript only visualizes data

**Example View Structure:**
```matlab
classdef BarChartView < matlab.ui.componentcontainer.ComponentContainer
    properties
        Data (:,2) double = []  % [categories, values]
        Title string = ""
    end
    
    methods (Access = protected)
        function setup(comp)
            comp.HTMLComponent = uihtml(comp);
            comp.HTMLComponent.HTMLSource = BarChartView.resolveHTMLSource();
            comp.update();
        end
        
        function update(comp)
            viewData = struct();
            viewData.data = comp.Data;
            viewData.title = comp.Title;
            comp.HTMLComponent.Data = viewData;
        end
    end
    
    methods (Access = private, Static)
        function htmlPath = resolveHTMLSource()
            classFile = mfilename('fullpath');
            classDir = fileparts(classFile);
            htmlPath = fullfile(classDir, 'web', 'index.html');
        end
    end
end
```

**Example View JavaScript (main.js):**
```javascript
function setup(htmlComponent) {
    // Initial render
    renderView(htmlComponent.Data);
    
    // Update on data changes (one-way only)
    htmlComponent.addEventListener("DataChanged", function(event) {
        renderView(htmlComponent.Data);
    });
}
```

**When to Use Views:**
- Static charts (bar, line, scatter plots)
- Dashboards with read-only metrics
- Data previews and summaries
- Any visualization without user interaction

**When to Use Components:**
- Brushing and selection tools
- Interactive filters
- Editable visualizations
- Any UI requiring callbacks

## File Organization

### Asset Structure
- `lib/d3/` - Shared D3.js library versions (explicitly versioned, v5.9.2)
- `lib/observable-plot/` - Observable Plot v0.6.17 UMD build + D3.js dependency
- `lib/tailwind/` - Tailwind CSS (if needed)
- `lib/assets/` - Shared resources (currently empty)
- `assets/icons/` - SVG/image assets
- `assets/shared.css` - Global styles for all components
- `assets/shared.js` - Shared JavaScript utilities for all components
- `manifest.json` - Component dependency manifest and version tracking
- `utils/templates/` - Component templates for scaffolding
  - `utils/templates/observable-plot/` - Observable Plot view templates
  - `utils/templates/d3/` - D3 component templates
- `utils/createComponentTemplate.m` - Template generation function

### Component Vendor Dependencies
Each component maintains its own `web/vendor/` directory for encapsulated dependencies:
```
controllers/@ComponentName/
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

**Observable Plot for Views:**
- Views may use Observable Plot instead of D3.js for specialized visualizations
- Observable Plot provides high-level declarative API via `Plot.plot()`
- Example: DensityStrip uses `Plot.density()` for density bands
- Version: Observable Plot v0.6.17 UMD build (plot.min.js) bundled in view's `web/vendor/`
- Observable Plot internally uses D3 but provides simpler API
- Use `createComponentTemplate("MyView", "library", "observable-plot", "type", "view")` to scaffold

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

### Method 1: Using Templates (Recommended)

Use `createComponentTemplate()` to quickly scaffold new components:

**Observable Plot View Example:**
```matlab
% Create a view for density plots
createComponentTemplate("DensityPlot", "library", "observable-plot", "type", "view")

% This creates:
% views/@DensityPlot/
%   ├── DensityPlot.m (VIEW pattern, no events)
%   ├── README.md
%   └── web/
%       ├── index.html
%       ├── main.js (DataChanged listener only)
%       ├── render.js (Observable Plot visualization)
%       ├── styles.css
%       └── vendor/
%           ├── d3.min.js (copied from lib/observable-plot/)
%           └── plot.min.js (copied from lib/observable-plot/)
```

**D3 Component Example:**
```matlab
% Create an interactive component with D3
createComponentTemplate("RangeSelector", "library", "d3", "type", "component")

% This creates:
% controllers/@RangeSelector/
%   ├── RangeSelector.m (COMPONENT pattern with events)
%   ├── README.md
%   └── web/
%       ├── index.html
%       ├── main.js (bidirectional communication)
%       ├── render.js (D3 v5 with event dispatching)
%       ├── styles.css
%       └── vendor/
%           └── d3.v5.9.2.min.js (copied from lib/d3/)
```

**Implementation Steps:**
1. Run `createComponentTemplate()` with appropriate arguments
2. Open `web/render.js` and implement visualization logic:
   - For Observable Plot: Use `Plot.plot()` with marks
   - For D3: Use D3 v5 patterns (access events via `d3.event`)
3. Update `ComponentName.m`:
   - Add properties with validation
   - Update `update()` method to send properties to JavaScript
   - For components: Add event handlers and callbacks
4. Test in browser first (`tests/html/test_ComponentName.html`)
5. Test in MATLAB (`tests/matlab/test_ComponentName.m`)
6. Update README with usage examples

### Method 2: Manual Creation

If templates don't fit your needs, follow the standard structure:

1. Create `controllers/@ComponentName/` or `views/@ViewName/` folder
2. Create MATLAB class extending `ComponentContainer`:
   - Define public properties
   - Implement `setup()` and `update()` methods
   - Create `HTMLComponent` pointing to `web/index.html`
3. Create `web/` directory structure
4. Create `web/index.html` (template only, no inline scripts)
5. Create `web/styles.css` for component-specific styles
6. Create `web/main.js` with `setup()` function
7. Create `web/render.js` with visualization logic
8. **Create `web/vendor/` directory and copy required libraries**
9. **Create `README.md` documenting exact dependency versions**
10. Ensure `index.html` references all files with correct relative paths
11. **Update root `manifest.json` with new component entry**

## Adding New Views

### Using Templates (Recommended)

```matlab
% Create an Observable Plot view
createComponentTemplate("ScatterView", "library", "observable-plot", "type", "view")
```

### Manual Creation (if needed)

1. Create `views/@ViewName/` folder
2. Create MATLAB class extending `ComponentContainer`:
   - Define minimal public properties (usually just `Data` and optional `Title`)
   - **Do NOT add `events` block**
   - **Do NOT add callback properties**
   - Implement `setup()` and `update()` methods only
   - **Do NOT set `HTMLEventReceivedFcn`** in setup
3. Create `web/` directory structure
4. Create `web/index.html` (template only, no inline scripts)
5. Create `web/styles.css` for view-specific styles
6. Create `web/main.js` with simplified `setup()` function (DataChanged listener only)
7. Create `web/render.js` with pure visualization logic (no event dispatching)
8. **Create `web/vendor/` directory and copy required libraries**
9. **Create `README.md` documenting exact dependency versions**
10. Ensure `index.html` references all files with correct relative paths
11. **Update root `manifest.json` with new view entry**

**Critical View Constraints:**
- ❌ No `events` block in MATLAB class
- ❌ No `HasCallbackProperty` properties
- ❌ No `htmlComponent.dispatchEvent()` calls in JavaScript
- ❌ No `HTMLEventReceivedFcn` in setup method
- ✅ Only `setup()` and `update()` methods
- ✅ Only `Data` property synchronization via `HTMLComponent.Data`

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
