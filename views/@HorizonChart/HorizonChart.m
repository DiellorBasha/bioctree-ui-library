classdef HorizonChart < matlab.ui.componentcontainer.ComponentContainer
    % HorizonChart - Horizon chart visualization view
    % Version: 1.0.0
    % Based on Observable Plot horizon chart pattern
    %
    % This is a VIEW component (read-only, one-way data flow):
    %   - No events
    %   - No callbacks
    %   - No bidirectional communication
    %   - Pure data visualization
    %
    % View Structure:
    %   - HorizonChart.m: MATLAB class (this file)
    %   - web/index.html: HTML entry point (UMD pattern)
    %   - web/main.js: Simplified bootstrap (DataChanged only)
    %   - web/render.js: Observable Plot v0.6.17 horizon chart rendering
    %   - web/styles.css: View-specific styles
    %   - web/vendor/d3.min.js: D3.js (UMD build)
    %   - web/vendor/plot.min.js: Observable Plot v0.6.17 (UMD build)
    
    properties
        % Data to visualize - table with columns: name, date, value
        Data table = table()
        
        % Display properties
        Bands (1,1) double {mustBePositive, mustBeInteger} = 3  % Number of horizon bands
        Step (1,1) double {mustBePositive} = 500  % Value per band (auto-calculated if 0)
        ColorScheme string = "Greens"  % Observable Plot color scheme
        ShowLegend (1,1) logical = true  % Show color legend
    end
    
    properties (Access = private, Transient, NonCopyable)
        % Internal HTML component for rendering
        HTMLComponent matlab.ui.control.HTML
    end
    
    methods (Access = protected)
        function setup(comp)
            % Create HTML component and set source
            comp.HTMLComponent = uihtml(comp);
            comp.HTMLComponent.HTMLSource = HorizonChart.resolveHTMLSource();
            comp.HTMLComponent.Position = [1 1 comp.Position(3:4)];
            
            % Initial update
            comp.update();
        end
        
        function update(comp)
            % Sync MATLAB properties to JavaScript
            
            % Prepare data structure for JavaScript
            viewData = struct();
            
            % Convert table to struct array for JavaScript
            if ~isempty(comp.Data) && height(comp.Data) > 0
                viewData.data = table2struct(comp.Data, 'ToScalar', false);
            else
                viewData.data = [];
            end
            
            viewData.bands = comp.Bands;
            viewData.step = comp.Step;
            viewData.colorScheme = comp.ColorScheme;
            viewData.showLegend = comp.ShowLegend;
            
            % Send data to JavaScript (triggers DataChanged event in HTML)
            comp.HTMLComponent.Data = viewData;
            
            % Update positioning
            comp.HTMLComponent.Position = [1 1 comp.Position(3:4)];
        end
    end
    
    methods (Access = private, Static)
        function htmlPath = resolveHTMLSource()
            % Resolve path to index.html (works in dev and packaged toolbox)
            classFile = mfilename('fullpath');
            classDir = fileparts(classFile);
            htmlPath = fullfile(classDir, 'web', 'index.html');
        end
    end
end
