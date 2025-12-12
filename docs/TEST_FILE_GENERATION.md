# Test File Generation Feature

## Overview
The template system now automatically generates test files for newly created components when the `testData` parameter is provided.

## Usage

### Basic Syntax
```matlab
createComponentTemplate(name, "library", libraryType, "type", componentType, "testData", dataPath)
```

### Examples

#### Observable Plot View with Test Data
```matlab
createComponentTemplate("DensityChart", ...
    "library", "observable-plot", ...
    "type", "view", ...
    "testData", "../data/faithful.tsv")
```

#### D3 Component with Test Data
```matlab
createComponentTemplate("InteractiveBrush", ...
    "library", "d3", ...
    "type", "component", ...
    "testData", "../data/traffic.csv")
```

## Generated Files

### Component/View Structure
```
views/@DensityChart/           (or controllers/@ComponentName/)
├── DensityChart.m            # MATLAB class
├── README.md                 # Documentation
└── web/
    ├── index.html
    ├── main.js
    ├── render.js
    ├── styles.css
    └── vendor/
        ├── d3.min.js
        └── plot.min.js
```

### Test Files
```
tests/
├── html/
│   └── test_DensityChart.html    # Browser-based test
└── matlab/
    └── test_DensityChart.m       # MATLAB test suite
```

## Test File Features

### HTML Test File (`tests/html/test_ComponentName.html`)
- **Library Loading**: Automatically includes correct library scripts
  - Observable Plot: `d3.min.js` + `plot.min.js`
  - D3: `d3.v5.9.2.min.js`
- **Component Loading**: Loads component files from relative paths
- **Data Loading**: Automatic data loading code based on file extension
  - CSV: `d3.csv('../data/file.csv', d3.autoType)`
  - TSV: `d3.tsv('../data/file.tsv', d3.autoType)`
  - JSON: `d3.json('../data/file.json')`
- **Test Containers**: Multiple test sections with different configurations
- **Mock htmlComponent**: For standalone browser testing

### MATLAB Test File (`tests/matlab/test_ComponentName.m`)
- **Path Setup**: Automatic path resolution using `fileparts(mfilename('fullpath'))`
- **Data Loading**: Appropriate readtable calls based on file extension
  - CSV: `readtable(dataPath)`
  - TSV: `readtable(dataPath, 'FileType', 'text', 'Delimiter', '\t')`
- **Test Sections**: 4 comprehensive test cases
  1. Basic visualization
  2. Custom styling
  3. Dynamic property updates
  4. Empty data handling
- **Figure Management**: Each test in separate uifigure
- **Progress Output**: fprintf statements for test progress

## Supported Data Formats

### CSV Files
```matlab
createComponentTemplate("MyView", ...
    "library", "observable-plot", ...
    "type", "view", ...
    "testData", "../data/mydata.csv")
```
- **HTML**: `d3.csv('../data/mydata.csv', d3.autoType)`
- **MATLAB**: `readtable(dataPath)`

### TSV Files
```matlab
createComponentTemplate("MyView", ...
    "library", "observable-plot", ...
    "type", "view", ...
    "testData", "../data/faithful.tsv")
```
- **HTML**: `d3.tsv('../data/faithful.tsv', d3.autoType)`
- **MATLAB**: `readtable(dataPath, 'FileType', 'text', 'Delimiter', '\t')`

### JSON Files
```matlab
createComponentTemplate("MyView", ...
    "library", "observable-plot", ...
    "type", "view", ...
    "testData", "../data/config.json")
```
- **HTML**: `d3.json('../data/config.json')`
- **MATLAB**: Manual implementation required (TODO in template)

## Template Placeholders

The test file templates use the following placeholders:
- `{{COMPONENT_NAME}}` - Component name (e.g., "DensityChart")
- `{{COMPONENT_PATH}}` - Relative path (e.g., "views/@DensityChart")
- `{{CONTAINER_CLASS}}` - CSS class (e.g., "densitychart-container")
- `{{RENDER_FUNCTION}}` - Function name (e.g., "renderDensityChart")
- `{{LIBRARY_SCRIPTS}}` - Library script tags
- `{{COMPONENT_TYPE}}` - "view" or "component"
- `{{COMPONENT_TYPE_UPPER}}` - "VIEW" or "COMPONENT"
- `{{LIBRARY_DESCRIPTION}}` - Library version info

## Workflow

### 1. Create Component with Tests
```matlab
createComponentTemplate("MyChart", ...
    "library", "observable-plot", ...
    "type", "view", ...
    "testData", "../data/mydata.csv")
```

### 2. Implement Visualization
Edit `views/@MyChart/web/render.js`:
```javascript
function renderMyChart(data, htmlComponent) {
    const plot = Plot.plot({
        // Your Observable Plot configuration
        marks: [
            Plot.dot(data.data, {x: "x", y: "y"})
        ]
    });
    
    const container = document.querySelector('.mychart-container');
    container.innerHTML = '';
    container.appendChild(plot);
}
```

### 3. Test in Browser
1. Open `tests/html/test_MyChart.html` in browser
2. Open browser console to see logs
3. Verify visualization renders correctly

### 4. Test in MATLAB
```matlab
cd tests/matlab
test_MyChart
```

### 5. Customize Tests
- Modify test configurations in `tests/html/test_MyChart.html`
- Add more test cases in `tests/matlab/test_MyChart.m`
- Update mock data structures as needed

## Benefits

1. **Time Savings**: No manual test file creation
2. **Consistency**: All tests follow same structure
3. **Best Practices**: Tests include proper path resolution and data loading
4. **Rapid Prototyping**: Start testing immediately after generation
5. **Documentation**: Tests serve as usage examples

## Example: Complete Workflow

```matlab
% 1. Create component with test data
createComponentTemplate("ScatterView", ...
    "library", "observable-plot", ...
    "type", "view", ...
    "testData", "../data/iris.csv")

% Output:
% Template created:
%   Name: ScatterView
%   Type: view (one-way data flow)
%   Library: observable-plot
%   Test data: ../data/iris.csv
%
% Test files:
%   tests/html/test_ScatterView.html
%   tests/matlab/test_ScatterView.m

% 2. Implement visualization
% Edit: views/@ScatterView/web/render.js

% 3. Test in browser
% Open: tests/html/test_ScatterView.html

% 4. Test in MATLAB
cd tests/matlab
test_ScatterView

% 5. All tests pass! Component ready to use.
```

## Notes

- Test data path is relative to `tests/html/` and `tests/matlab/` directories
- Use `../data/` prefix to reference files in root `data/` directory
- Test files include TODOs for customization points
- HTML tests use mock htmlComponent for standalone testing
- MATLAB tests use actual component instances in uifigures
