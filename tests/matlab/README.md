# MATLAB Tests for d3Brush Component

This directory contains MATLAB test files for the d3Brush component.

## Test Files

### 1. `test_d3Brush.m` - Automated Unit Tests
Comprehensive unit test suite using MATLAB's testing framework.

**Run all tests:**
```matlab
runtests('test_d3Brush')
```

**Run with detailed output:**
```matlab
results = runtests('test_d3Brush', 'OutputDetail', 'Detailed')
```

**Run specific test:**
```matlab
runtests('test_d3Brush', 'ProcedureName', 'testValuePropertySorting')
```

**Tests included:**
- Component creation and initialization
- Property validation (Min, Max, SnapInterval, Value)
- Value sorting and clamping
- Error handling for invalid inputs
- Callback function registration
- Multiple components in one figure
- Component deletion and cleanup
- Dynamic property updates

### 2. `manual_test_d3Brush.m` - Interactive Manual Tests
Interactive script with visual tests for manual verification.

**Usage:**
Open the file in MATLAB and run sections individually using `Ctrl+Enter` (or `Cmd+Enter` on Mac).

**Test sections:**
1. **Basic Component Creation** - Default brush with standard settings
2. **Custom Range and Snap Interval** - Custom configuration
3. **Event Callbacks** - Verify all event types fire correctly
4. **Programmatic Value Changes** - Animated value updates
5. **Multiple Brushes** - Two independent brushes in one figure
6. **Property Validation** - Test sorting, clamping, and error handling
7. **Dynamic Range Updates** - Changing Min/Max with active selection
8. **Stress Test** - Rapid programmatic updates
9. **UI Integration** - Brush combined with standard MATLAB UI components

## Prerequisites

- MATLAB R2020b or later (required for `ComponentContainer` support)
- Component directory must be on MATLAB path
- For automated tests: MATLAB Testing Framework

## Adding Tests to Path

The automated test suite automatically adds the component directory to the path. For manual testing, add the components directory:

```matlab
addpath(genpath(fullfile(fileparts(pwd), 'components')));
```

## Test Coverage

Current test coverage includes:

**Component Lifecycle:**
- ✅ Creation and initialization
- ✅ Setup and configuration
- ✅ Deletion and cleanup

**Property Management:**
- ✅ Min, Max, SnapInterval properties
- ✅ Value property (dependent)
- ✅ Value sorting (auto-sort [start, stop])
- ✅ Value clamping (to Min/Max range)
- ✅ Invalid input validation

**Event System:**
- ✅ ValueChanging (throttled during drag)
- ✅ ValueChanged (on release)
- ✅ BrushStarted (on drag start)
- ✅ BrushEnded (on drag end)
- ✅ Callback registration

**Integration:**
- ✅ Multiple components in one figure
- ✅ Integration with standard MATLAB UI components
- ✅ Dynamic property updates
- ✅ Programmatic value changes

**Limitations:**
- ⚠️ JavaScript event dispatching cannot be fully tested in automated tests (requires browser environment)
- ⚠️ Visual appearance requires manual verification
- ⚠️ D3.js rendering logic tested separately in `tests/html/`

## Running Tests in CI/CD

For automated testing in CI/CD pipelines:

```matlab
% Run tests and generate results
results = runtests('test_d3Brush');

% Check if all tests passed
if all([results.Passed])
    exit(0);  % Success
else
    exit(1);  % Failure
end
```

## Debugging Failed Tests

To debug a specific test:

```matlab
% Run test with debugger
dbstop if error
runtests('test_d3Brush', 'ProcedureName', 'testValuePropertyClamping')
```

## Known Issues

1. **Event Callbacks in Automated Tests**: Callbacks set via `ValueChangedFcn` cannot be triggered in automated tests because the JavaScript side is not running. These tests only verify that callbacks can be set without error.

2. **Visual Verification Required**: Some aspects (rendering, styling, interaction smoothness) require manual testing using `manual_test_d3Brush.m`.

## Contributing

When adding new features to d3Brush:

1. Add corresponding unit tests to `test_d3Brush.m`
2. Add interactive verification to `manual_test_d3Brush.m`
3. Ensure all existing tests pass
4. Document any new test requirements in this README

## Related Documentation

- Component implementation: `controllers/@d3Brush/d3Brush.m`
- HTML/JavaScript tests: `tests/html/test_d3_brush.html`
- Component README: `controllers/@d3Brush/README.md`
- Development guidelines: `.github/copilot-instructions.md`
