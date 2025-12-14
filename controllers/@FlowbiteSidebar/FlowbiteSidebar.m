classdef FlowbiteSidebar < FlowbiteComponentBase
    % FlowbiteSidebar - A Flowbite-styled sidebar navigation component
    %
    % This component provides a collapsible sidebar with navigation items.
    % It supports click events, item selection, and dynamic content updates.
    %
    % Properties:
    %   Items - Cell array of menu item names
    %   Collapsed - Logical flag for sidebar collapse state
    %   SelectedItem - Currently selected menu item
    %   Theme - 'light' or 'dark' theme
    %   ItemClickedFcn - Callback function when item is clicked
    %
    % Events:
    %   ItemClicked - Triggered when user clicks a menu item
    %
    % Example:
    %   fig = uifigure('Position', [100 100 800 500]);
    %   items = {'Dashboard', 'Users', 'Settings', 'Help'};
    %   sidebar = FlowbiteSidebar(fig, 'Items', items);
    %   sidebar.ItemClickedFcn = @(src, event) disp(['Clicked: ' event.Item]);
    
    properties
        Items (:,1) string = ["Dashboard"; "Users"; "Settings"; "Help"]
        Collapsed logical = false
        SelectedItem (1,1) string = "Dashboard"
        Theme (1,1) string = "light"
        ItemClickedFcn function_handle = function_handle.empty
    end
    
    properties (Access = private)
        ClickCount = 0
    end
    
    events
        ItemClicked
    end
    
    methods (Access = protected)
        function data = getJSData(comp)
            % getJSData - Provide component state for JavaScript
            
            data = struct();
            data.items = comp.Items;
            data.collapsed = comp.Collapsed;
            data.selectedItem = comp.SelectedItem;
            data.theme = comp.Theme;
        end
        
        function handleEvent(comp, name, payload)
            % handleEvent - Process events from JavaScript
            
            switch name
                case "ItemClicked"
                    % Update selected item
                    comp.SelectedItem = string(payload.item);
                    comp.ClickCount = comp.ClickCount + 1;
                    
                    % Fire MATLAB event
                    notify(comp, 'ItemClicked');
                    
                    % Call callback if defined
                    if ~isempty(comp.ItemClickedFcn)
                        comp.ItemClickedFcn(comp, payload);
                    end
                    
                    % Console output for debugging
                    fprintf('[FlowbiteSidebar] Item clicked: %s (click #%d)\n', ...
                        comp.SelectedItem, comp.ClickCount);
            end
        end
    end
end
