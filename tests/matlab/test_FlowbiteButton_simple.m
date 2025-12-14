%% Simple FlowbiteButton Test
% Very basic test to isolate the problem

clear all; close all; clc;

% Setup paths correctly
[testFile, ~, ~] = fileparts(mfilename('fullpath'));
projRoot = fileparts(fileparts(testFile));
addpath(fullfile(projRoot, 'controllers'));

fprintf('Project root: %s\n', projRoot);
fprintf('Searching for FlowbiteButton...\n\n');

fprintf('Test 1: Component instantiation\n');

try
    fig = uifigure('Position', [100 100 600 200]);
    fprintf('✓ Figure created\n');
    
    % Try to create component without figure
    btn = FlowbiteButton();
    fprintf('✓ Component created (no figure)\n');
    
catch ME
    fprintf('✗ Error: %s\n', ME.message);
    disp(ME);
end

fprintf('\nTest 2: Check HTML file path\n');

try
    % Test path resolution directly
    thisFile = which('FlowbiteButton');
    if ~isempty(thisFile)
        fprintf('✓ Class file found: %s\n', thisFile);
        classDir = fileparts(thisFile);
        fprintf('  Class dir: %s\n', classDir);
        htmlPath = fullfile(classDir, 'web', 'index.html');
        fprintf('  HTML path: %s\n', htmlPath);
        
        if isfile(htmlPath)
            fprintf('✓ HTML file exists\n');
        else
            fprintf('✗ HTML file NOT found\n');
        end
    else
        fprintf('✗ FlowbiteButton class file not found\n');
    end
    
catch ME
    fprintf('✗ Error: %s\n', ME.message);
end
