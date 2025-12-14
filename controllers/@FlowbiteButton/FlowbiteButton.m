classdef FlowbiteButton < FlowbiteComponentBase
    % FlowbiteButton - Interactive button component using Flowbite + Tailwind CSS
    %
    % This component integrates Flowbite (a Tailwind CSS component library)
    % into a MATLAB ComponentContainer for interactive button controls.
    %
    % Example:
    %   fig = uifigure('Position', [100 100 600 200]);
    %   btn = FlowbiteButton(fig, 'Position', [50 50 500 100]);
    %   btn.Label = 'Click Me!';
    %   btn.Variant = 'primary';
    %   btn.ButtonClickedFcn = @(src, event) disp(event);
    
    properties
        % Label - Text displayed on the button
        Label = "Click me"; 
        
        % Variant - Color variant: 'primary', 'success', 'danger', 'warning', 'secondary'
        Variant = "primary";
    end
    
    properties
        % ButtonClickedFcn - Callback when button is clicked
        ButtonClickedFcn = []
    end
    
    events
        % ButtonClicked - Event fired when button is clicked
        ButtonClicked
    end
    
    properties (Access = private)
        % ClickCount - Internal counter for button clicks
        ClickCount = 0
    end
    
    methods (Access = protected)
        function data = getJSData(comp)
            % getJSData - Provide component state for JavaScript
            %
            % Returns struct with properties needed by render.js
            
            data = struct();
            data.label = char(comp.Label);
            data.variant = char(comp.Variant);
            data.clickCount = comp.ClickCount;
        end
        
        function handleEvent(comp, name, payload)
            % handleEvent - Process events from JavaScript
            %
            % Handles:
            %   - ButtonClicked: User clicked the button
            
            switch name
                case "ButtonClicked"
                    % Update internal state
                    comp.ClickCount = payload.clickCount;
                    
                    % Fire MATLAB event
                    notify(comp, 'ButtonClicked');
                    
                    % Execute callback if defined
                    if ~isempty(comp.ButtonClickedFcn)
                        comp.ButtonClickedFcn(comp, payload);
                    end
                    
                    % Log click
                    fprintf('[FlowbiteButton] Button clicked (count: %d)\n', comp.ClickCount);
            end
        end
    end
end
