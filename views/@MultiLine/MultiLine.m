classdef MultiLine < matlab.ui.componentcontainer.ComponentContainer
    % MultiLine - Multiple line chart visualization using Observable Plot
    % Version: 1.0.0
    %
    % A read-only visualization view that displays multiple line series using
    % Observable Plot. Groups tidy data into series using the z channel to show
    % trends for different categories (e.g., unemployment by division).
    %
    % This is a VIEW component (read-only, one-way data flow):
    %   - No events
    %   - No callbacks
    %   - No bidirectional communication
    %   - Pure data visualization
    %
    % View Structure:
    %   - MultiLine.m: MATLAB class (this file)
    %   - web/index.html: HTML entry point (UMD pattern)
    %   - web/main.js: Simplified bootstrap (DataChanged only)
    %   - web/render.js: Observable Plot v0.6.17 visualization
    %   - web/styles.css: View-specific styles
    %   - web/vendor/d3.min.js: D3.js (UMD build)
    %   - web/vendor/plot.min.js: Observable Plot v0.6.17 (UMD build)
    %
    % Data Structure:
    %   The Data property should be a table or struct array with columns:
    %   - date: x-axis values (dates, numbers, etc.)
    %   - unemployment: y-axis values (numeric)
    %   - division: grouping variable (categories for different lines)
    
    properties
        % Data table with date, unemployment, and division columns
        Data = []
    end
    
    properties (Access = private, Transient, NonCopyable)
        % Internal HTML component for rendering
        HTMLComponent matlab.ui.control.HTML
    end
    
    methods (Access = protected)
        function setup(comp)
            % Create HTML component and set source
            comp.HTMLComponent = uihtml(comp);
            comp.HTMLComponent.HTMLSource = MultiLine.resolveHTMLSource();
            comp.HTMLComponent.Position = [1 1 comp.Position(3:4)];
            
            % Initial update
            comp.update();
        end
        
        function update(comp)
            % Sync MATLAB properties to JavaScript
            
            % Prepare data structure for JavaScript
            viewData = struct();
            
            % Convert MATLAB table to struct array for JSON serialization
            if istable(comp.Data)
                viewData.data = table2struct(comp.Data, 'ToScalar', true);
                % If empty, use empty cell
                if isempty(viewData.data)
                    viewData.data = [];
                end
            else
                viewData.data = comp.Data;
            end
            
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
