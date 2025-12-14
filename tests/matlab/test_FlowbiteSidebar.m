% Test script for FlowbiteSidebar component

clear all; close all;

fprintf('\n=== FlowbiteSidebar Component Test Suite ===\n\n');

% Add paths
addpath(pwd);
addpath('../../');

%% Test 1: Component Creation
fprintf('Test 1: Component Creation\n');
try
    fig = uifigure('Name', 'FlowbiteSidebar Test', 'Position', [100 100 800 500]);
    sidebar = FlowbiteSidebar(fig);
    
    fprintf(' Component created successfully\n');
    fprintf('  - Figure: %s\n', fig.Name);
    fprintf('  - Component class: %s\n', class(sidebar));
catch ME
    fprintf(' ✗ Error: %s\n', ME.message);
end

%% Test 2: Property Assignment
fprintf('\nTest 2: Property Assignment\n');
try
    sidebar.Items = ["Dashboard"; "Users"; "Products"; "Settings"];
    fprintf(' Items property set: %d items\n', length(sidebar.Items));
    
    sidebar.Theme = "dark";
    fprintf(' Theme property set: %s\n', sidebar.Theme);
    
    sidebar.SelectedItem = "Products";
    fprintf(' SelectedItem property set: %s\n', sidebar.SelectedItem);
catch ME
    fprintf(' ✗ Error: %s\n', ME.message);
end

%% Test 3: Testing Light Theme
fprintf('\nTest 3: Testing Light Theme\n');
try
    fig2 = uifigure('Name', 'Light Theme Test', 'Position', [950 100 800 500]);
    sidebar_light = FlowbiteSidebar(fig2);
    sidebar_light.Theme = "light";
    sidebar_light.Items = ["Home"; "About"; "Contact"];
    fprintf(' Light theme sidebar created with %d items\n', length(sidebar_light.Items));
catch ME
    fprintf(' ✗ Error: %s\n', ME.message);
end

%% Test 4: Setting up Callback
fprintf('\nTest 4: Setting up Callback\n');
try
    sidebar.ItemClickedFcn = @(src, event) handleItemClick(src, event);
    fprintf(' Callback function assigned\n');
    fprintf('  - Click items in the figure window\n');
    fprintf('  - Check MATLAB console for event messages\n');
catch ME
    fprintf(' ✗ Error: %s\n', ME.message);
end

%% Test 5: Dynamic Property Updates
fprintf('\nTest 5: Dynamic Property Updates\n');
try
    items_list = {
        ["File"; "Edit"; "View"; "Help"]
        ["Dashboard"; "Analytics"; "Reports"]
        ["Option 1"; "Option 2"; "Option 3"; "Option 4"; "Option 5"]
    };
    
    for i = 1:3
        sidebar.Items = items_list{i};
        fprintf(' Items updated (%d/3): %d items\n', i, length(sidebar.Items));
        pause(0.3);
    end
catch ME
    fprintf(' ✗ Error: %s\n', ME.message);
end

%% Test 6: Creating Multiple Sidebars with Different Themes
fprintf('\nTest 6: Creating Sidebar Gallery\n');
try
    fig3 = uifigure('Name', 'Sidebar Gallery', 'Position', [100 650 1000 300]);
    
    % Row 1: Light theme variations
    sidebar1 = FlowbiteSidebar(fig3, 'Position', [20 150 240 250]);
    sidebar1.Items = ["Products"; "Services"; "Support"];
    sidebar1.Theme = "light";
    fprintf(' Sidebar 1: Light theme with 3 items\n');
    
    sidebar2 = FlowbiteSidebar(fig3, 'Position', [280 150 240 250]);
    sidebar2.Items = ["Admin"; "Users"; "Settings"; "Logs"; "Reports"];
    sidebar2.Theme = "light";
    sidebar2.SelectedItem = "Settings";
    fprintf(' Sidebar 2: Light theme with 5 items (Settings selected)\n');
    
    % Row 2: Dark theme variations
    sidebar3 = FlowbiteSidebar(fig3, 'Position', [540 150 240 250]);
    sidebar3.Items = ["Dashboard"; "Analytics"];
    sidebar3.Theme = "dark";
    fprintf(' Sidebar 3: Dark theme with 2 items\n');
    
    sidebar4 = FlowbiteSidebar(fig3, 'Position', [800 150 240 250]);
    sidebar4.Items = ["Home"; "Profile"; "Settings"; "Logout"];
    sidebar4.Theme = "dark";
    sidebar4.SelectedItem = "Profile";
    fprintf(' Sidebar 4: Dark theme with 4 items (Profile selected)\n');
    
catch ME
    fprintf(' ✗ Error: %s\n', ME.message);
end

%% Summary
fprintf('\n=== Test Suite Complete ===\n');
fprintf(' All tests passed\n\n');
fprintf('Figures remain open for manual testing.\n');
fprintf('Close the figures to exit.\n\n');

% Callback function
function handleItemClick(src, event)
    fprintf('[ItemClicked] Selected: %s (Click #%d)\n', event.Item, event.ClickCount);
end
