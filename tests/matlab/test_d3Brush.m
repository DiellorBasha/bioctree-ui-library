function tests = test_d3Brush()
    % TEST_D3BRUSH - Test suite for d3Brush component
    % Run this test suite with: runtests('test_d3Brush')
    % Or run interactively for manual verification
    
    tests = functiontests(localfunctions);
end

%% Setup and Teardown Functions

function setupOnce(testCase)
    % Add component to path if needed
    componentPath = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'controllers');
    if ~contains(path, componentPath)
        addpath(genpath(componentPath));
        testCase.TestData.pathAdded = true;
    else
        testCase.TestData.pathAdded = false;
    end
end

function teardownOnce(testCase)
    % Remove path if we added it
    if testCase.TestData.pathAdded
        componentPath = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'controllers');
        rmpath(genpath(componentPath));
    end
end

function setup(testCase)
    % Create a figure for each test
    testCase.TestData.fig = uifigure('Position', [100 100 600 300], ...
                                     'Name', 'Test Figure', ...
                                     'Visible', 'off');  % Keep invisible for automated tests
end

function teardown(testCase)
    % Clean up figure after each test
    if isvalid(testCase.TestData.fig)
        close(testCase.TestData.fig);
    end
end

%% Test Functions

function testComponentCreation(testCase)
    % Test that component can be created successfully
    fig = testCase.TestData.fig;
    
    brush = d3Brush(fig);
    
    % Verify component was created
    verifyClass(testCase, brush, 'd3Brush');
    verifyTrue(testCase, isvalid(brush));
    
    % Verify default properties
    verifyEqual(testCase, brush.Min, 0);
    verifyEqual(testCase, brush.Max, 100);
    verifyEqual(testCase, brush.SnapInterval, 5);
    verifyEqual(testCase, brush.Value, [20 60]);
end

function testComponentWithPosition(testCase)
    % Test component creation with position specified
    fig = testCase.TestData.fig;
    
    brush = d3Brush(fig, 'Position', [50 50 500 200]);
    
    verifyClass(testCase, brush, 'd3Brush');
    verifyTrue(testCase, isvalid(brush));
end

function testMinMaxProperties(testCase)
    % Test Min and Max property setting
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    % Set new Min and Max
    brush.Min = -50;
    brush.Max = 200;
    
    verifyEqual(testCase, brush.Min, -50);
    verifyEqual(testCase, brush.Max, 200);
end

function testSnapIntervalProperty(testCase)
    % Test SnapInterval property
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    % Set new snap interval
    brush.SnapInterval = 10;
    verifyEqual(testCase, brush.SnapInterval, 10);
    
    % Test small interval
    brush.SnapInterval = 0.5;
    verifyEqual(testCase, brush.SnapInterval, 0.5);
end

function testValuePropertySetting(testCase)
    % Test Value property with valid input
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    % Set valid value
    brush.Value = [30, 70];
    verifyEqual(testCase, brush.Value, [30, 70]);
end

function testValuePropertySorting(testCase)
    % Test that Value property automatically sorts [start, stop]
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    % Set reversed values - should be automatically sorted
    brush.Value = [80, 40];
    verifyEqual(testCase, brush.Value, [40, 80]);
end

function testValuePropertyClamping(testCase)
    % Test that Value property clamps to Min/Max range
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    brush.Min = 0;
    brush.Max = 100;
    
    % Try to set value outside range
    brush.Value = [-10, 120];
    
    % Should be clamped to [0, 100]
    verifyEqual(testCase, brush.Value, [0, 100]);
end

function testValuePropertyPartialClamping(testCase)
    % Test clamping when only one value is out of range
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    brush.Min = 0;
    brush.Max = 100;
    
    % One value out of range
    brush.Value = [-5, 50];
    verifyEqual(testCase, brush.Value, [0, 50]);
    
    brush.Value = [50, 150];
    verifyEqual(testCase, brush.Value, [50, 100]);
end

function testValuePropertyInvalidInput(testCase)
    % Test that invalid Value input throws error
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    % Single value should throw error
    verifyError(testCase, @() set(brush, 'Value', 50), 'd3Brush:InvalidValue');
    
    % Three values should throw error
    verifyError(testCase, @() set(brush, 'Value', [10 20 30]), 'd3Brush:InvalidValue');
end

function testValueChangedCallback(testCase)
    % Test ValueChanged callback is triggered
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    % Set up callback flag
    testCase.TestData.callbackFired = false;
    
    brush.ValueChangedFcn = @(src, event) callbackHandler(testCase);
    
    % Trigger callback by changing Value
    brush.Value = [25, 75];
    
    % Note: Callback won't fire in automated tests because JavaScript isn't running
    % This test verifies the callback can be set without error
    verifyClass(testCase, brush.ValueChangedFcn, 'function_handle');
end

function testValueChangingCallback(testCase)
    % Test ValueChanging callback can be set
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    brush.ValueChangingFcn = @(src, event) disp('Value changing');
    
    verifyClass(testCase, brush.ValueChangingFcn, 'function_handle');
end

function testBrushStartedCallback(testCase)
    % Test BrushStarted callback can be set
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    brush.BrushStartedFcn = @(src, event) disp('Brush started');
    
    verifyClass(testCase, brush.BrushStartedFcn, 'function_handle');
end

function testBrushEndedCallback(testCase)
    % Test BrushEnded callback can be set
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    brush.BrushEndedFcn = @(src, event) disp('Brush ended');
    
    verifyClass(testCase, brush.BrushEndedFcn, 'function_handle');
end

function testHTMLComponentCreation(testCase)
    % Test that internal HTML component is created
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    % Access private property for testing (using struct trick)
    s = struct(brush);
    
    verifyTrue(testCase, isprop(s, 'HTMLComponent') || isfield(s, 'HTMLComponent'));
end

function testMultipleComponentsInFigure(testCase)
    % Test creating multiple brush components in same figure
    fig = testCase.TestData.fig;
    
    brush1 = d3Brush(fig, 'Position', [10 150 280 100]);
    brush2 = d3Brush(fig, 'Position', [310 150 280 100]);
    
    verifyTrue(testCase, isvalid(brush1));
    verifyTrue(testCase, isvalid(brush2));
    
    % Set different values
    brush1.Value = [10, 40];
    brush2.Value = [60, 90];
    
    verifyEqual(testCase, brush1.Value, [10, 40]);
    verifyEqual(testCase, brush2.Value, [60, 90]);
end

function testComponentDeletion(testCase)
    % Test component cleanup on deletion
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    verifyTrue(testCase, isvalid(brush));
    
    % Delete component by deleting the figure (triggers component cleanup)
    close(fig);
    
    % Component should be invalid after figure closes
    verifyFalse(testCase, isvalid(brush));
    
    % Create a new figure for subsequent tests
    testCase.TestData.fig = uifigure('Position', [100 100 600 300], ...
                                     'Name', 'Test Figure', ...
                                     'Visible', 'off');
end

function testDynamicPropertyUpdates(testCase)
    % Test updating multiple properties in sequence
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    % Update multiple properties
    brush.Min = 10;
    brush.Max = 90;
    brush.SnapInterval = 2;
    brush.Value = [30, 60];
    
    verifyEqual(testCase, brush.Min, 10);
    verifyEqual(testCase, brush.Max, 90);
    verifyEqual(testCase, brush.SnapInterval, 2);
    verifyEqual(testCase, brush.Value, [30, 60]);
end

function testValueAdjustmentAfterRangeChange(testCase)
    % Test that Value adjusts when Min/Max range changes
    fig = testCase.TestData.fig;
    brush = d3Brush(fig);
    
    % Set initial value
    brush.Value = [20, 80];
    
    % Reduce Max - value should be clamped
    brush.Max = 50;
    
    % When we read Value, it should still be within the old range
    % But when we set it again, it will clamp
    brush.Value = brush.Value;  % Trigger setter
    
    verifyLessThanOrEqual(testCase, brush.Value(2), 50);
end

%% Helper Functions

function callbackHandler(testCase)
    % Helper function to flag callback execution
    testCase.TestData.callbackFired = true;
end
