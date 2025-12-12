# Testing Guide

Comprehensive testing ensures component reliability and makes development easier. The bioctree UI Library uses a two-tier testing strategy.

## Testing Strategy

### 1. Browser Tests (HTML/JavaScript)

Test rendering and interaction independently of MATLAB.

**Location:** `tests/html/`

**Purpose:**
- Fast iteration during development
- Visual debugging with browser DevTools
- Test D3.js rendering logic
- Validate event dispatching

### 2. MATLAB Tests (Integration)

Test full component integration with MATLAB.

**Location:** `tests/matlab/`

**Purpose:**
- Property validation
- MATLAB-JavaScript communication
- Event handling
- Lifecycle management
- Automated regression testing

## Running Tests

### Browser Tests

1. Open test file in browser:
```bash
cd tests/html
# Open test_d3_brush.html in your browser
```

2. Check console for results:
```
[Test 1] ✓ Component renders successfully
[Test 2] ✓ Initial selection is correct
[Test 3] ✓ Events dispatch properly
...
```

### MATLAB Automated Tests

Run all tests:
```matlab
runtests('test_d3Brush')
```

Run with detailed output:
```matlab
results = runtests('test_d3Brush', 'OutputDetail', 'Detailed')
```

Run specific test:
```matlab
runtests('test_d3Brush', 'ProcedureName', 'testValuePropertySorting')
```

### MATLAB Manual Tests

Interactive visual testing:
```matlab
% Open manual test script
edit('manual_test_d3Brush.m')

% Run sections individually with Ctrl+Enter
```

## Writing Browser Tests

### Test Template

```html
<!DOCTYPE html>
<html>
<head>
    <title>Test Component</title>
    <link rel="stylesheet" href="../../components/@ComponentName/ComponentName.css">
    <script src="test-utils.js"></script>
</head>
<body>
    <h1>Component Tests</h1>
    <div class="component-container"></div>
    
    <script src="../../components/@ComponentName/vendor/d3.v5.9.2.min.js"></script>
    <script src="../../components/@ComponentName/ComponentName.render.js"></script>
    <script src="../../components/@ComponentName/ComponentName.js"></script>
    
    <script>
        // Create mock htmlComponent
        var mockComponent = new MockHTMLComponent();
        
        // Test 1: Component renders
        console.log('[Test 1] Testing component render...');
        mockComponent.Data = {
            min: 0,
            max: 100,
            snapInterval: 5,
            initialSelection: [20, 60]
        };
        
        try {
            setup(mockComponent);
            console.log('[Test 1] ✓ Component renders successfully');
        } catch (error) {
            console.error('[Test 1] ✗ Failed:', error);
        }
        
        // Test 2: Event dispatching
        console.log('[Test 2] Testing event dispatch...');
        var eventReceived = false;
        mockComponent.addEventListener('ValueChanged', function(e) {
            eventReceived = true;
            console.log('[Test 2] Event data:', JSON.parse(e.detail));
        });
        
        // Trigger interaction...
        setTimeout(function() {
            if (eventReceived) {
                console.log('[Test 2] ✓ Events dispatch correctly');
            } else {
                console.error('[Test 2] ✗ No event received');
            }
        }, 1000);
    </script>
</body>
</html>
```

### Mock Utilities

Use `test-utils.js` for mocking MATLAB's `htmlComponent`:

```javascript
class MockHTMLComponent {
    constructor() {
        this.Data = {};
        this.listeners = {};
    }
    
    addEventListener(event, callback) {
        if (!this.listeners[event]) {
            this.listeners[event] = [];
        }
        this.listeners[event].push(callback);
    }
    
    dispatchEvent(event) {
        var eventType = event.type;
        if (this.listeners[eventType]) {
            this.listeners[eventType].forEach(cb => cb(event));
        }
        console.log('[MockHTMLComponent] Event dispatched:', eventType, event.detail);
    }
}
```

## Writing MATLAB Tests

### Automated Test Template

```matlab
function tests = test_ComponentName()
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    % Add component to path
    componentPath = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'components');
    addpath(genpath(componentPath));
end

function setup(testCase)
    % Create figure for each test
    testCase.TestData.fig = uifigure('Visible', 'off');
end

function teardown(testCase)
    % Clean up after each test
    if isvalid(testCase.TestData.fig)
        close(testCase.TestData.fig);
    end
end

function testPropertySetting(testCase)
    fig = testCase.TestData.fig;
    comp = ComponentName(fig);
    
    % Test property
    comp.SomeProperty = 42;
    verifyEqual(testCase, comp.SomeProperty, 42);
end

function testPropertyValidation(testCase)
    fig = testCase.TestData.fig;
    comp = ComponentName(fig);
    
    % Test invalid input throws error
    verifyError(testCase, @() set(comp, 'SomeProperty', 'invalid'), ...
        'ComponentName:InvalidValue');
end
```

### Manual Test Template

```matlab
%% Test Section 1: Basic Functionality
% Description of what this section tests

fig = uifigure('Position', [100 100 600 300]);
comp = ComponentName(fig, 'Position', [50 50 500 200]);

% Configure component
comp.SomeProperty = someValue;

% Add callback
comp.SomeEventFcn = @(src, event) fprintf('Event fired: %s\n', event.Type);

fprintf('Test Section 1: Try interacting with the component\n');

%% Test Section 2: Edge Cases
% Test specific edge cases

% ... more tests
```

## Test Coverage Checklist

### Component Creation
- [ ] Creates without errors
- [ ] Creates with position specified
- [ ] Creates with initial property values
- [ ] Multiple components in one figure

### Property Management
- [ ] Default values are correct
- [ ] Properties can be set individually
- [ ] Properties can be set during construction
- [ ] Invalid inputs throw appropriate errors
- [ ] Property validation works correctly
- [ ] Dependent properties compute correctly

### Property Validation
- [ ] Type validation (numeric, string, etc.)
- [ ] Size validation (scalar, array, etc.)
- [ ] Range validation (min/max)
- [ ] Custom validation rules

### Events
- [ ] Callbacks can be registered
- [ ] Callbacks fire at correct times
- [ ] Event data is correct
- [ ] Multiple callbacks can be registered
- [ ] Callbacks can be changed
- [ ] Callbacks can be cleared

### Lifecycle
- [ ] Component initializes correctly
- [ ] Component updates when properties change
- [ ] Component cleans up on deletion
- [ ] No memory leaks (timers, listeners)

### Integration
- [ ] Works in regular figures
- [ ] Works in App Designer
- [ ] Works with other MATLAB UI components
- [ ] Multiple instances don't interfere

### Edge Cases
- [ ] Empty/null inputs
- [ ] Extreme values (very large/small)
- [ ] Rapid property changes
- [ ] Rapid user interactions
- [ ] Component deletion during interaction

## Debugging Tests

### Browser Console

Open browser DevTools (F12) to:
- View console logs
- Inspect DOM elements
- Debug JavaScript
- Monitor network requests
- Check for errors

### MATLAB Debugger

```matlab
% Set breakpoint on error
dbstop if error

% Run specific test
runtests('test_d3Brush', 'ProcedureName', 'testValuePropertyClamping')

% Step through code
dbstep
dbcont
```

### Common Issues

**Test fails but component works manually:**
- Check test setup (figure visibility, timing)
- Verify test expectations are correct
- Add pause() if timing-dependent

**Component works in tests but not in App Designer:**
- Verify relative paths (not absolute)
- Check component cleanup
- Test in actual App Designer environment

**Events not firing in tests:**
- Remember: JavaScript events won't fire in automated tests
- Use manual tests for interaction verification
- Mock event data for unit tests

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup MATLAB
        uses: matlab-actions/setup-matlab@v1
        
      - name: Run MATLAB Tests
        uses: matlab-actions/run-tests@v1
        with:
          test-results-junit: test-results.xml
          
      - name: Publish Test Results
        uses: EnricoMi/publish-unit-test-result-action@v1
        if: always()
        with:
          files: test-results.xml
```

### Test Script for CI

```matlab
% run_tests.m
try
    results = runtests('test_d3Brush');
    
    % Display summary
    fprintf('\n=== TEST SUMMARY ===\n');
    fprintf('Passed: %d\n', sum([results.Passed]));
    fprintf('Failed: %d\n', sum([results.Failed]));
    fprintf('Total: %d\n', length(results));
    
    % Exit with appropriate code
    if all([results.Passed])
        exit(0);
    else
        exit(1);
    end
catch ME
    fprintf('Error running tests: %s\n', ME.message);
    exit(1);
end
```

## Performance Testing

### Stress Testing

```matlab
% Test rapid updates
tic;
for i = 1:100
    comp.Value = [randi([0, 50]), randi([51, 100])];
    pause(0.01);
end
elapsedTime = toc;

fprintf('100 updates in %.2f seconds\n', elapsedTime);
fprintf('Average: %.2f ms per update\n', (elapsedTime/100)*1000);
```

### Memory Testing

```matlab
% Check for memory leaks
before = memory;

for i = 1:100
    fig = uifigure('Visible', 'off');
    comp = d3Brush(fig);
    close(fig);
end

after = memory;
fprintf('Memory increase: %.2f MB\n', (after.MemUsedMATLAB - before.MemUsedMATLAB) / 1e6);
```

## Best Practices

**✓ Do:**
- Test both success and failure cases
- Use descriptive test names
- Keep tests independent
- Clean up resources (figures, timers)
- Test edge cases
- Document expected behavior

**✗ Don't:**
- Depend on test execution order
- Leave figures open after tests
- Skip error case testing
- Hardcode paths
- Forget to test cleanup

## Next Steps

- [Component Structure](component-structure.md) - Build testable components
- [Contributing Guide](contributing.md) - Submit your tests
- [Versioning](versioning.md) - Test across versions
