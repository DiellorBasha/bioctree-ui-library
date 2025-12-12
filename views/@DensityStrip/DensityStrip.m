classdef DensityStrip < matlab.ui.componentcontainer.ComponentContainer
    % DensityStrip - One-dimensional density visualization view
    % Version: 2.0.0
    % Based on https://observablehq.com/@observablehq/plot-one-dimensional-density
    %
    % This is a VIEW component (read-only, one-way data flow):
    %   - No events
    %   - No callbacks
    %   - No bidirectional communication
    %   - Pure data visualization
    %
    % View Structure:
    %   - DensityStrip.m: MATLAB class (this file)
    %   - web/index.html: HTML entry point (UMD pattern)
    %   - web/main.js: Simplified bootstrap (DataChanged only)
    %   - web/render.js: Observable Plot v0.6.17 density visualization
    %   - web/styles.css: View-specific styles
    %   - web/vendor/d3.min.js: D3.js (UMD build)
    %   - web/vendor/plot.min.js: Observable Plot v0.6.17 (UMD build)
    
    properties
        % Data to visualize - 1D numeric array
        Data (:,1) double {mustBeFinite, mustBeReal} = []
        
        % Display properties
        Bandwidth (1,1) double {mustBePositive} = 10  % KDE bandwidth for smoothing
        Color string = "steelblue"  % Stroke color for density contours
        ShowDots (1,1) logical = true  % Show individual data points
        ShowContours (1,1) logical = true  % Show density contour bands
        Thresholds (1,1) double {mustBePositive, mustBeInteger} = 4  % Number of contour levels
    end
    
    properties (Access = private, Transient, NonCopyable)
        % Internal components
        HTMLComponent matlab.ui.control.HTML
    end
    
    methods (Access = protected)
        function setup(comp)
            % If using default size, fill the parent container instead
            if comp.Position(3) == 100 && comp.Position(4) == 100
                % Get parent container size
                parentPos = comp.Parent.Position;
                % Fill parent with small margins
                comp.Position = [10 10 parentPos(3)-20 parentPos(4)-20];
            end
            
            % Create the HTML component that fills the container
            comp.HTMLComponent = uihtml(comp);
            
            % Set HTML component position to fill the ComponentContainer
            comp.HTMLComponent.Position = [1 1 comp.Position(3:4)];
            
            % Use static method to resolve path to web/index.html
            comp.HTMLComponent.HTMLSource = DensityStrip.resolveHTMLSource();
            
            % NOTE: No HTMLEventReceivedFcn for views - one-way data flow only
            
            % Send initial data to JavaScript
            comp.update();
        end
        
        function update(comp)
            % Update the HTML component data with current property values
            % This is the ONLY communication channel for views (MATLAB → JS)
            
            if isempty(comp.HTMLComponent) || ~isvalid(comp.HTMLComponent)
                return;
            end
            
            % Update HTML component position to match container size
            comp.HTMLComponent.Position = [1 1 comp.Position(3:4)];
            
            % Prepare data structure for JavaScript
            viewData = struct();
            viewData.data = comp.Data;
            viewData.bandwidth = comp.Bandwidth;
            viewData.color = comp.Color;
            viewData.showDots = comp.ShowDots;
            viewData.showContours = comp.ShowContours;
            viewData.thresholds = comp.Thresholds;
            
            % Send data to JavaScript (triggers DataChanged event in HTML)
            comp.HTMLComponent.Data = viewData;
        end
    end
    
    methods (Access = private, Static)
        function htmlPath = resolveHTMLSource()
            % Resolve the absolute path to web/index.html
            % This works in both development and packaged toolbox scenarios
            classFile = mfilename('fullpath');
            classDir = fileparts(classFile);
            htmlPath = fullfile(classDir, 'web', 'index.html');
        end
    end
end
