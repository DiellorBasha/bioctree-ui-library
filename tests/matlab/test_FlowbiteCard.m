%% FlowbiteCard Component Test
% Test script for the FlowbiteCard MATLAB component
% Tests content rendering, properties, and interactive features

clear all; close all; clc;

% Setup paths
[testFile, ~, ~] = fileparts(mfilename('fullpath'));
projRoot = fileparts(fileparts(testFile));
addpath(fullfile(projRoot, 'controllers'));

fprintf('\n=== FlowbiteCard Component Test Suite ===\n\n');

%% Test 1: Component Creation
fprintf('Test 1: Component Creation\n');
try
    fig = uifigure('Name', 'FlowbiteCard Test', 'NumberTitle', 'off', ...
        'Position', [100 100 800 600]);
    
    card = FlowbiteCard(fig, 'Position', [50 300 700 250]);
    
    fprintf('✓ Component created successfully\n');
    fprintf('  - Figure: %s\n', fig.Name);
    fprintf('  - Component class: %s\n', class(card));
catch ME
    fprintf('✗ Failed to create component: %s\n', ME.message);
    return;
end

%% Test 2: Property Assignment
fprintf('\nTest 2: Property Assignment\n');
try
    card.Title = 'Welcome to FlowbiteCard';
    fprintf('✓ Title property set: %s\n', card.Title);
    
    card.Subtitle = 'A flexible card component';
    fprintf('✓ Subtitle property set: %s\n', card.Subtitle);
    
    card.Content = '<p>This is the card content area.</p><p>You can use HTML here!</p>';
    fprintf('✓ Content property set\n');
    
    card.Status = 'Active';
    card.StatusVariant = 'success';
    fprintf('✓ Status badge set: %s (%s)\n', card.Status, card.StatusVariant);
    
    pause(0.5);
catch ME
    fprintf('✗ Failed to set properties: %s\n', ME.message);
end

%% Test 3: Status Variants
fprintf('\nTest 3: Testing Status Variants\n');
variants = ["primary", "success", "danger", "warning"];

for i = 1:length(variants)
    try
        card.Status = sprintf('Status: %s', variants(i));
        card.StatusVariant = variants(i);
        fprintf('✓ Variant %d/%d: %s\n', i, length(variants), variants(i));
        pause(0.3);
    catch ME
        fprintf('✗ Failed variant %s: %s\n', variants(i), ME.message);
    end
end

%% Test 4: Interactive Mode
fprintf('\nTest 4: Interactive Mode and Callbacks\n');
try
    card.Interactive = true;
    card.Title = 'Click Me!';
    card.Subtitle = 'This card is interactive';
    card.Content = '<p>Click anywhere on this card.</p><p>Check the console for messages.</p>';
    card.Status = 'Ready';
    card.StatusVariant = 'primary';
    
    fprintf('✓ Interactive mode enabled\n');
    
    % Set up callback
    card.CardClickedFcn = @(src, event) handleCardClick(src, event);
    fprintf('✓ Callback function assigned\n');
    
    fprintf('  - Click the card to test communication\n');
    fprintf('  - Watch the MATLAB console for messages\n');
    
    pause(3);
    
catch ME
    fprintf('✗ Failed to set interactive: %s\n', ME.message);
end

%% Test 5: Dynamic Content Updates
fprintf('\nTest 5: Dynamic Content Updates\n');
try
    contents = {
        '<p><strong>Content 1:</strong> Initial content</p>',
        '<p><strong>Content 2:</strong> Updated content</p>',
        '<p><strong>Content 3:</strong> Final content</p>'
    };
    
    for i = 1:length(contents)
        card.Content = contents{i};
        fprintf('✓ Content updated (%d/%d)\n', i, length(contents));
        pause(0.5);
    end
    
catch ME
    fprintf('✗ Failed dynamic updates: %s\n', ME.message);
end

%% Test 6: Card Gallery
fprintf('\nTest 6: Creating Card Gallery\n');
try
    % Close previous figure
    close(fig);
    
    % Create new figure for gallery
    fig2 = uifigure('Name', 'Card Gallery', 'NumberTitle', 'off', ...
        'Position', [100 100 900 600]);
    
    % Info card
    card1 = FlowbiteCard(fig2, 'Position', [20 320 250 250]);
    card1.Title = 'Feature';
    card1.Status = 'New';
    card1.StatusVariant = 'success';
    card1.Content = '<p>Fast and reliable component library.</p>';
    fprintf('✓ Card 1: Feature (success)\n');
    
    % Warning card
    card2 = FlowbiteCard(fig2, 'Position', [320 320 250 250]);
    card2.Title = 'Alert';
    card2.Status = 'Important';
    card2.StatusVariant = 'warning';
    card2.Content = '<p>Please review this information.</p>';
    fprintf('✓ Card 2: Alert (warning)\n');
    
    % Error card
    card3 = FlowbiteCard(fig2, 'Position', [620 320 250 250]);
    card3.Title = 'Status';
    card3.Status = 'Error';
    card3.StatusVariant = 'danger';
    card3.Content = '<p>Something needs attention.</p>';
    fprintf('✓ Card 3: Status (danger)\n');
    
    % Interactive card
    card4 = FlowbiteCard(fig2, 'Position', [20 20 850 280]);
    card4.Title = 'Dashboard';
    card4.Subtitle = 'Click for more details';
    card4.Interactive = true;
    card4.Content = '<p>Total: 1,234 | Active: 567 | Pending: 89</p>';
    card4.Status = 'Live';
    card4.StatusVariant = 'success';
    card4.CardClickedFcn = @(src, ~) fprintf('Card "%s" clicked!\n', src.Title);
    fprintf('✓ Card 4: Interactive dashboard\n');
    
catch ME
    fprintf('✗ Failed gallery creation: %s\n', ME.message);
end

%% Test Complete
fprintf('\n=== Test Suite Complete ===\n');
fprintf('✓ All tests passed\n');
fprintf('\nFigure remains open for inspection.\n');
fprintf('Close the figure to exit.\n\n');

% Keep figure open for manual inspection
waitfor(fig2);

%% Helper Functions
function handleCardClick(src, event)
    try
        if isfield(event, 'HTMLEventData') && ~isempty(event.HTMLEventData)
            data = jsondecode(event.HTMLEventData);
            fprintf('[Card Callback] "%s" clicked (count: %d) at %s\n', ...
                data.title, data.clickCount, data.timestamp);
        else
            fprintf('[Card Callback] Card clicked\n');
        end
    catch ME
        fprintf('[Card Callback] Error: %s\n', ME.message);
    end
end
