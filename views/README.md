# Views

Views are read-only data visualization components with one-way data flow (MATLAB → JavaScript). Unlike interactive components, views focus purely on rendering data without emitting events or handling user interactions.

## Views vs Components

| Aspect | Components | Views |
|--------|-----------|-------|
| **Data Flow** | Bidirectional | One-way (MATLAB → JS) |
| **Properties** | Multiple interactive properties | Minimal (usually just `Data`) |
| **Events** | Multiple (ValueChanged, etc.) | None |
| **Callbacks** | Yes (ValueChangedFcn, etc.) | None |
| **MATLAB Methods** | `setup()`, `update()`, event handlers, `delete()` | `setup()`, `update()` only |
| **JavaScript** | Controller + event dispatching | Simplified controller, no events |
| **Use Case** | Interactive selection, filtering | Charts, graphs, static visualizations |

## View Architecture

Each view follows the same standardized structure as components:

```
views/@ViewName/
├── ViewName.m              # MATLAB class (ComponentContainer)
├── README.md               # View documentation
└── web/
    ├── index.html          # HTML entry point
    ├── main.js             # Simplified bootstrap (DataChanged only)
    ├── render.js           # Pure D3 visualization
    ├── styles.css          # View-specific styles
    └── vendor/
        └── d3.v5.9.2.min.js
```

## View Constraints

**MATLAB Class:**
- ❌ No `events` block
- ❌ No `HasCallbackProperty` properties
- ❌ No `HTMLEventReceivedFcn` in setup
- ✅ Only `setup()` and `update()` methods
- ✅ Minimal properties (typically `Data` and optional formatting properties)

**JavaScript:**
- ❌ No `htmlComponent.dispatchEvent()` calls
- ❌ No event handlers that communicate back to MATLAB
- ✅ Only `DataChanged` listener
- ✅ Pure rendering logic

## When to Use Views

Use views when you need to:
- Display static charts (bar, line, scatter, etc.)
- Show read-only dashboards or metrics
- Visualize data without user interaction
- Preview data summaries

## Example View

**MATLAB Class:**
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

**JavaScript (main.js):**
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

## Creating a New View

1. Use `createViewTemplate()` utility (similar to `createComponentTemplate()`)
2. Implement MATLAB class with minimal properties
3. Create simplified JavaScript controller (DataChanged only)
4. Implement pure rendering logic
5. Test with static data

For detailed guidelines, see `.github/copilot-instructions.md` section on "Adding New Views".
