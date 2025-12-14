%% FlowbiteButton Syntax Check
% Quick test to verify FlowbiteButton.m has no syntax errors

clear all; clc;

fprintf('Testing FlowbiteButton class syntax...\n\n');

try
    % Check class definition syntax
    info = ?FlowbiteButton;
    
    fprintf('✓ Class definition: OK\n');
    fprintf('  - Name: %s\n', info.Name);
    fprintf('  - Superclass: %s\n', info.SuperclassList.Name);
    
    % Check properties
    fprintf('\n✓ Properties defined:\n');
    propNames = {info.PropertyList.Name};
    for i = 1:length(propNames)
        fprintf('  - %s\n', propNames{i});
    end
    
    % Check events
    fprintf('\n✓ Events defined:\n');
    if ~isempty(info.EventList)
        eventNames = {info.EventList.Name};
        for i = 1:length(eventNames)
            fprintf('  - %s\n', eventNames{i});
        end
    end
    
    % Check methods
    fprintf('\n✓ Methods defined:\n');
    methodNames = {info.MethodList.Name};
    for i = 1:length(methodNames)
        if ~startsWith(methodNames{i}, 'get.') && ~startsWith(methodNames{i}, 'set.')
            fprintf('  - %s\n', methodNames{i});
        end
    end
    
    fprintf('\n✅ ALL SYNTAX CHECKS PASSED!\n');
    
catch ME
    fprintf('\n❌ SYNTAX ERROR:\n');
    fprintf('  Error ID: %s\n', ME.identifier);
    fprintf('  Message: %s\n', ME.message);
    fprintf('\n  Stack:\n');
    for i = 1:length(ME.stack)
        fprintf('    %s (line %d)\n', ME.stack(i).file, ME.stack(i).line);
    end
end
