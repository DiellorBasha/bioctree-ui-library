classdef ManifoldBrushToolbar < matlab.ui.componentcontainer.ComponentContainer
    % ManifoldBrushToolbar
    %
    % Configurable toolbar for selecting manifold brush tools.
    % Supports both vertical and horizontal orientations.
    %
    % Responsibilities:
    %   - Display brush tool icons
    %   - Allow one active brush selection
    %   - Emit BrushSelected events
    %   - Bind to ManifoldBrushContext
    %
    % Does NOT:
    %   - Configure brush parameters
    %   - Evaluate brushes
    %   - Render the manifold
    %
    % Usage:
    %   toolbar = ManifoldBrushToolbar(parent);
    %   toolbar.Orientation = 'Horizontal';  % or 'Vertical' (default)

    properties (SetObservable)
        Context ManifoldBrushContext
        ActiveBrush char = 'spectral'  % Default brush ID
        Orientation char {mustBeMember(Orientation, {'Vertical', 'Horizontal'})} = 'Vertical'
    end
    
    properties (Access = public)
        ValueChangedFcn  % Callback when brush selection changes
    end

    properties (Access = private, Transient, NonCopyable)
        Grid matlab.ui.container.GridLayout
        HTMLComponent matlab.ui.control.HTML
        BrushRegistry cell
    end

    events
        BrushSelected
    end

    methods (Access = protected)

        function setup(comp)
            % Root grid for toolbar - manages HTML component layout
            comp.Grid = uigridlayout(comp);
            comp.Grid.RowHeight = {'1x'};
            comp.Grid.ColumnWidth = {'1x'};
            comp.Grid.Padding = [0 0 0 0];
            comp.Grid.RowSpacing = 0;
            comp.Grid.ColumnSpacing = 0;
            
            % HTML component fills the grid cell
            comp.HTMLComponent = uihtml(comp.Grid);
            comp.HTMLComponent.Layout.Row = 1;
            comp.HTMLComponent.Layout.Column = 1;
            comp.HTMLComponent.HTMLSource = ManifoldBrushToolbar.resolveHTMLSource();
            
            % Set up event listener for HTML events from JavaScript
            comp.HTMLComponent.HTMLEventReceivedFcn = @(src, event) comp.handleToolbarEvent(event);

            % Load brush registry
            comp.BrushRegistry = ManifoldBrushToolbar.ManifoldBrushRegistry();
            
            % Add listener for ActiveBrush changes
            addlistener(comp, 'ActiveBrush', 'PostSet', @(~,~)comp.update());
            
            % Add listener for Orientation changes
            addlistener(comp, 'Orientation', 'PostSet', @(~,~)comp.update());

            % Initial render
            comp.update();
        end

        function update(comp)
            % Update HTML component data only (no position management)
            if ~isempty(comp.HTMLComponent) && isvalid(comp.HTMLComponent)
                % Prepare data for JavaScript
                numTools = length(comp.BrushRegistry);
                tools = struct('id', {}, 'label', {}, 'icon', {}, 'active', {});
                
                for i = 1:numTools
                    brushDef = comp.BrushRegistry{i};
                    tools(i).id = brushDef.id;
                    tools(i).label = brushDef.label;
                    tools(i).icon = brushDef.icon;
                    tools(i).active = strcmp(brushDef.id, comp.ActiveBrush);
                end

                toolbarData = struct();
                toolbarData.tools = tools;
                toolbarData.orientation = lower(comp.Orientation);  % 'vertical' or 'horizontal'
                
                fprintf('[ManifoldBrushToolbar] Sending orientation: %s\n', toolbarData.orientation);

                comp.HTMLComponent.Data = toolbarData;
            end
        end
    end

    methods (Access = private)
        
        function handleToolbarEvent(comp, event)
            % Handle events received from JavaScript via sendEventToMATLAB
            
            eventName = event.HTMLEventName;
            
            % Handle ToolClicked event
            if strcmp(eventName, 'ToolClicked')
                % Access event data sent from JavaScript
                if ~isempty(event.HTMLEventData)
                    payload = event.HTMLEventData;
                    comp.handleToolClick(payload);
                end
            end
        end

        function handleToolClick(comp, payload)
            % Handle brush selection from JavaScript
            
            if isempty(payload) || ~isfield(payload, 'id')
                return;
            end
            
            try
                brushId = payload.id;

                % Find brush in registry
                brushInfo = [];
                for i = 1:length(comp.BrushRegistry)
                    if strcmp(comp.BrushRegistry{i}.id, brushId)
                        brushInfo = comp.BrushRegistry{i};
                        break;
                    end
                end
                
                if isempty(brushInfo)
                    warning('ManifoldBrushToolbar:InvalidBrush', 'Brush ID not found: %s', brushId);
                    return;
                end

                comp.ActiveBrush = brushId;

                % Create brush instance and update context
                if ~isempty(comp.Context)
                    manifold = comp.Context.Manifold;

                    if ~isempty(manifold)
                        newBrush = brushInfo.factory(manifold);

                        if isempty(comp.Context.BrushModel)
                            comp.Context.BrushModel = ManifoldBrushModel();
                        end

                        comp.Context.BrushModel.Brush = newBrush;
                    end
                end

                % Notify listeners
                notify(comp, 'BrushSelected');
                
                % Execute callback if set
                if ~isempty(comp.ValueChangedFcn)
                    comp.executeCallback(comp.ValueChangedFcn);
                end

                % Update UI (triggers re-render with new active state)
                comp.update();

            catch ME
                warning('ManifoldBrushToolbar:ClickError', 'Error handling tool click: %s', ME.message);
            end
        end
    end

    methods (Access = private, Static)
        function htmlPath = resolveHTMLSource()
            classFile = mfilename('fullpath');
            classDir = fileparts(classFile);
            htmlPath = fullfile(classDir, 'web', 'index.html');
        end
        
        function registry = ManifoldBrushRegistry()
            % MANIFOLDBRUSHREGISTRY Returns brush tool definitions for toolbar
            %
            % Returns:
            %   registry - Cell array of structs with fields:
            %     id - Unique identifier (string)
            %     icon - Icon filename in vendor/icons/ (string)
            %     label - Display name (string)
            %     factory - Function handle that creates brush: @(manifold) BrushType(manifold)
            
            registry = {
                struct('id', 'delta', ...
                       'icon', 'point.svg', ...
                       'label', 'Delta Brush', ...
                       'factory', @(manifold) DeltaBrush(manifold));
                
                struct('id', 'graph', ...
                       'icon', 'topology-star-3.svg', ...
                       'label', 'Graph Brush', ...
                       'factory', @(manifold) createGraphBrush(manifold));
                
                struct('id', 'spectral', ...
                       'icon', 'prism-light.svg', ...
                       'label', 'Spectral Brush', ...
                       'factory', @(manifold) SpectralBrush(manifold));
            };
            
            function brush = createGraphBrush(manifold)
                brush = GraphBrush();
                brush.Manifold = manifold;
            end
        end
    end
end