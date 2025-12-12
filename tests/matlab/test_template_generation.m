% test_template_generation.m
% Test script for createComponentTemplate with test file generation

clear; clc;

% Add utils to path
addpath('utils');

% Test 1: Create Observable Plot view with test data
disp('Test 1: Observable Plot view with test data');
disp('=============================================');
createComponentTemplate("TestPlot", "library", "observable-plot", "type", "view", "testData", "../data/faithful.tsv");

disp(' ');
disp('Checking created files...');
assert(isfile('views/@TestPlot/TestPlot.m'), 'MATLAB class file not created');
assert(isfile('views/@TestPlot/README.md'), 'README not created');
assert(isfile('views/@TestPlot/web/index.html'), 'index.html not created');
assert(isfile('tests/html/test_TestPlot.html'), 'HTML test file not created');
assert(isfile('tests/matlab/test_TestPlot.m'), 'MATLAB test file not created');
disp('✓ All files created successfully!');

% Clean up
disp(' ');
disp('Cleaning up test files...');
rmdir('views/@TestPlot', 's');
delete('tests/html/test_TestPlot.html');
delete('tests/matlab/test_TestPlot.m');
disp('✓ Test complete!');
