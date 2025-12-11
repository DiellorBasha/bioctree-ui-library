classdef d3Brush < matlab.ui.componentcontainer.ComponentContainer
    % D3Brush - Interactive brush component using D3.js with snapping
    % Version: 1.0.0
    % Based on https://observablehq.com/@d3/brush-snapping
    
    properties
        % Public properties that users can set
        Min (1,1) double {mustBeFinite, mustBeReal} = 0            % Minimum value of the range
        Max (1,1) double {mustBeFinite, mustBeReal} = 100          % Maximum value of the range
        SnapInterval (1,1) double {mustBeFinite, mustBeReal, mustBePositive} = 5   % Snap interval
    end
    
    properties (Dependent)
        Value   % Current selection [start, stop]
    end
    
    properties (Access = private)
        Value_ (1,2) double {mustBeFinite, mustBeReal} = [20 60]  % Internal value storage
    end
    
    properties (Access = private, Transient, NonCopyable)
        % Internal components
        HTMLComponent matlab.ui.control.HTML
    end
    
    events (HasCallbackProperty, NotifyAccess = protected)
        % Event triggered when brush selection is changing (during drag)
        ValueChanging
        % Event triggered when brush selection changes (on release)
        ValueChanged
        % Event triggered when brush interaction starts
        BrushStarted
        % Event triggered when brush interaction ends
        BrushEnded
    end
    
    properties (Access = private)
        % Throttle timer for BrushMoving events
        ThrottleTimer
        PendingSelection
    end
    
    methods
        % Getter for Value (dependent property)
        function val = get.Value(comp)
            val = comp.Value_;
        end
        
        % Setter for Value with validation
        function set.Value(comp, val)
            % Validate input
            if numel(val) ~= 2
                error('d3Brush:InvalidValue', 'Value must be a 1x2 array [start, stop]');
            end
            
            % Sort to ensure start <= stop
            val = sort(val);
            
            % Clamp to Min/Max range
            val(1) = max(comp.Min, val(1));
            val(2) = min(comp.Max, val(2));
            
            % Store new value
            comp.Value_ = val;
            
            % Trigger update to sync with JavaScript
            if ~isempty(comp.HTMLComponent) && isvalid(comp.HTMLComponent)
                comp.update();
            end
        end
    end
    
    methods (Access = protected)
        function setup(comp)
            % Create the HTML component that fills the container
            comp.HTMLComponent = uihtml(comp);
            
            % Use relative path for HTMLSource (required for toolbox packaging)
            comp.HTMLComponent.HTMLSource = 'd3Brush.html';
            
            % Use normalized units to ensure proper resizing in containers
            comp.HTMLComponent.Units = 'normalized';
            comp.HTMLComponent.Position = [0 0 1 1];
            
            % Set up event listener for HTML events from JavaScript
            comp.HTMLComponent.HTMLEventReceivedFcn = @(src, event) comp.handleBrushEvent(event);
            
            % Initialize throttle timer for handling rapid brush movement
            comp.ThrottleTimer = timer(...
                'ExecutionMode', 'singleShot', ...
                'StartDelay', 0.05, ...  % 50ms throttle
                'TimerFcn', @(~,~) comp.processPendingSelection());
            
            % Send initial data to JavaScript after HTML loads
            comp.update();
        end
        
        function update(comp)
            % Update the HTML component data with current property values
            % This method is called automatically when properties change
            
            if isempty(comp.HTMLComponent) || ~isvalid(comp.HTMLComponent)
                return;
            end
            
            % Prepare data structure for JavaScript
            brushData = struct();
            brushData.min = comp.Min;
            brushData.max = comp.Max;
            brushData.snapInterval = comp.SnapInterval;
            brushData.initialSelection = comp.Value_;
            
            % Send data to JavaScript (triggers DataChanged event in HTML)
            comp.HTMLComponent.Data = brushData;
        end
        
        function handleBrushEvent(comp, event)
            % Handle events received from JavaScript via CustomEvent
            eventName = event.HTMLEventName;
            
            try
                % Decode the JSON data from the CustomEvent detail
                eventData = jsondecode(event.HTMLEventData);
            catch ME
                warning('d3Brush:InvalidJSON', 'Failed to decode event data: %s', ME.message);
                return;
            end
            
            switch eventName
                case 'BrushStarted'
                    % Notify that brush interaction started
                    notify(comp, 'BrushStarted');
                    
                case 'BrushMoving'
                    % Throttle rapid brush movement events
                    if isfield(eventData, 'selection') && ~isempty(eventData.selection)
                        comp.PendingSelection = eventData.selection;
                        
                        % Restart throttle timer
                        if strcmp(comp.ThrottleTimer.Running, 'on')
                            stop(comp.ThrottleTimer);
                        end
                        start(comp.ThrottleTimer);
                    end
                    
                case 'ValueChanged'
                    if isfield(eventData, 'selection') && ~isempty(eventData.selection)
                        % Update Value property (on brush release)
                        oldValue = comp.Value_;
                        comp.Value_ = eventData.selection;
                        
                        % Create event data with previous and new values
                        evtData = matlab.ui.eventdata.ValueChangedData(oldValue, comp.Value_);
                        
                        % Notify listeners
                        notify(comp, 'ValueChanged', evtData);
                        notify(comp, 'BrushEnded');
                    else
                        % Brush was cleared
                        oldValue = comp.Value_;
                        comp.Value_ = [comp.Min comp.Max];  % Reset to full range
                        
                        evtData = matlab.ui.eventdata.ValueChangedData(oldValue, comp.Value_);
                        notify(comp, 'ValueChanged', evtData);
                        notify(comp, 'BrushEnded');
                    end
            end
        end
        
        function processPendingSelection(comp)
            % Process throttled brush movement
            if ~isempty(comp.PendingSelection)
                oldValue = comp.Value_;
                comp.Value_ = comp.PendingSelection;
                
                % Create event data for ValueChanging
                evtData = matlab.ui.eventdata.ValueChangedData(oldValue, comp.Value_);
                
                % Notify ValueChanging (not ValueChanged - that's for release)
                notify(comp, 'ValueChanging', evtData);
                
                comp.PendingSelection = [];
            end
        end
        
        function delete(comp)
            % Clean up timer on component deletion
            if ~isempty(comp.ThrottleTimer) && isvalid(comp.ThrottleTimer)
                stop(comp.ThrottleTimer);
                delete(comp.ThrottleTimer);
            end
        end
    end
end
