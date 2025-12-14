classdef (Abstract) FlowbiteComponentBase < matlab.ui.componentcontainer.ComponentContainer
    % FlowbiteComponentBase - Abstract base class for Flowbite-based UI components
    %
    % This class codifies the MATLAB–HTML contract for Flowbite components,
    % ensuring correct layout, sizing, event handling, and asset resolution.
    %
    % Purpose:
    %   - Enforce correct ComponentContainer sizing behavior
    %   - Handle HTML asset resolution consistently
    %   - Standardize MATLAB ↔ JavaScript data flow
    %   - Provide unified event routing (JS → MATLAB)
    %   - Enable grid layout participation automatically
    %
    % Subclass Responsibilities:
    %   - Implement getJSData() to return state for JavaScript
    %   - Implement handleEvent() to process JavaScript events
    %   - Define component-specific properties and events
    %   - Create web/ folder with index.html, render.js, etc.
    %
    % Example Subclass:
    %   classdef FlowbiteButton < FlowbiteComponentBase
    %       properties
    %           Label = "Click me"
    %       end
    %       methods (Access = protected)
    %           function data = getJSData(comp)
    %               data.label = char(comp.Label);
    %           end
    %           function handleEvent(comp, name, payload)
    %               switch name
    %                   case "ButtonClicked"
    %                       notify(comp, "ButtonClicked");
    %               end
    %           end
    %       end
    %   end
    
    properties (Access = protected, Transient, NonCopyable)
        % HTML - The uihtml component (owned by base class)
        HTML matlab.ui.control.HTML
    end
    
    methods (Access = protected)
        function setup(comp)
            % setup - Initialize HTML component with correct lifecycle
            %
            % This method:
            %   - Creates uihtml component
            %   - Resolves HTML source path (subclass-specific)
            %   - Wires event handler
            %   - Performs initial sync
            %
            % Subclasses should NOT override this method.
            
            % Create HTML component (owned by ComponentContainer)
            comp.HTML = uihtml(comp);
            
            % Resolve HTML source (subclass-specific path)
            comp.HTML.HTMLSource = comp.resolveHTML();
            
            % Wire unified event handler
            comp.HTML.HTMLEventReceivedFcn = @(src, evt) comp.dispatchEvent(evt);
            
            % Perform initial sync
            comp.update();
        end
        
        function update(comp)
            % update - Synchronize MATLAB state to JavaScript
            %
            % This method:
            %   - ALWAYS propagates size to HTML component (resize handling)
            %   - Syncs component-specific data via getJSData()
            %
            % Subclasses should NOT override this method.
            % Instead, implement getJSData() to provide state.
            
            % Defensive check
            if isempty(comp.HTML) || ~isvalid(comp.HTML)
                return
            end
            
            % CRITICAL: Always propagate size (ComponentContainer contract)
            % This ensures:
            %   - Grid layouts control sizing
            %   - Resize events propagate correctly
            %   - No manual Position override
            comp.HTML.Position = [1 1 comp.Position(3:4)];
            
            % Sync component-specific state to JavaScript
            comp.HTML.Data = comp.getJSData();
        end
    end
    
    methods (Access = protected, Abstract)
        % getJSData - Provide component state for JavaScript
        %
        % Subclasses must implement this to return a struct
        % containing all properties needed by the JavaScript renderer.
        %
        % Example:
        %   function data = getJSData(comp)
        %       data.label = char(comp.Label);
        %       data.variant = char(comp.Variant);
        %       data.disabled = comp.Disabled;
        %   end
        %
        % Returns:
        %   data - Struct with fields accessible in JavaScript via htmlComponent.Data
        data = getJSData(comp)
        
        % handleEvent - Process events from JavaScript
        %
        % Subclasses must implement this to handle component-specific events.
        %
        % Parameters:
        %   name    - Event name (string before colon in HTMLEventName)
        %   payload - Decoded JSON data (struct/array/empty)
        %
        % Example:
        %   function handleEvent(comp, name, payload)
        %       switch name
        %           case "ButtonClicked"
        %               comp.ClickCount = payload.clickCount;
        %               notify(comp, "ButtonClicked");
        %           case "ValueChanged"
        %               comp.Value = payload.value;
        %               notify(comp, "ValueChanged");
        %       end
        %   end
        handleEvent(comp, name, payload)
    end
    
    methods (Access = protected)
        function dispatchEvent(comp, evt)
            % dispatchEvent - Route JavaScript events to handleEvent()
            %
            % This method:
            %   - Parses event name and JSON payload
            %   - Calls subclass handleEvent() with clean parameters
            %   - Handles errors defensively
            %
            % Event Format (JavaScript):
            %   htmlComponent.sendEventToMATLAB('EventName:' + JSON.stringify(data))
            %
            % Subclasses should NOT override this method.
            
            try
                % Parse event name and data (format: "EventName:{json}")
                % Split only on first colon to preserve JSON timestamps/colons
                colonIdx = strfind(evt.HTMLEventName, ':');
                
                if isempty(colonIdx)
                    % No payload, just event name
                    eventName = evt.HTMLEventName;
                    payload = [];
                else
                    % Extract event name and JSON payload
                    eventName = extractBefore(evt.HTMLEventName, colonIdx(1));
                    jsonStr = extractAfter(evt.HTMLEventName, colonIdx(1));
                    
                    % Decode JSON (empty string → empty array)
                    if isempty(jsonStr) || strcmp(jsonStr, "")
                        payload = [];
                    else
                        payload = jsondecode(jsonStr);
                    end
                end
                
                % Delegate to subclass event handler
                comp.handleEvent(eventName, payload);
                
            catch ME
                % Log error but don't crash component
                warning('%s:EventError', class(comp), ...
                    'Error handling event "%s": %s', evt.HTMLEventName, ME.message);
            end
        end
        
        function htmlPath = resolveHTML(comp)
            % resolveHTML - Resolve path to component's index.html
            %
            % This method:
            %   - Works in development and packaged scenarios
            %   - Follows standard structure: @ComponentName/web/index.html
            %
            % Subclasses should NOT override this method.
            %
            % Returns:
            %   htmlPath - Absolute path to web/index.html
            
            % Get the class file path
            classFile = which(class(comp));
            classDir = fileparts(classFile);
            
            % Standard structure: @ComponentName/web/index.html
            htmlPath = fullfile(classDir, 'web', 'index.html');
            
            % Defensive check
            if ~isfile(htmlPath)
                error('%s:HTMLNotFound', class(comp), ...
                    'HTML file not found: %s\nExpected structure: @%s/web/index.html', ...
                    htmlPath, class(comp));
            end
        end
    end
    
    methods (Access = protected)
        function autoLayoutInGrid(comp)
            % autoLayoutInGrid - Automatically participate in grid layouts
            %
            % This method can be called by subclasses in their constructor
            % to automatically set Layout.Row and Layout.Column if unset.
            %
            % Example (in subclass constructor):
            %   comp.autoLayoutInGrid();
            %
            % Optional feature - subclasses decide whether to use it.
            
            if isa(comp.Parent, 'matlab.ui.container.GridLayout')
                % Auto-assign to first row/column if not explicitly set
                if isempty(comp.Layout.Row)
                    comp.Layout.Row = 1;
                end
                if isempty(comp.Layout.Column)
                    comp.Layout.Column = 1;
                end
            end
        end
    end
end
