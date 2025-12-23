classdef Viewer < matlab.ui.componentcontainer.ComponentContainer
    % Viewer
    %
    % Minimal MATLAB ComponentContainer wrapper around a three.js uihtml viewer.
    % - No data passing
    % - No callbacks
    % - Loads web/index.html which loads fsaverage.glb internally (same as browser test)
    %
    % Intended usage (grid-layout driven sizing):
    %   fig  = uifigure('Position',[100 100 1200 800]);
    %   grid = uigridlayout(fig,[1 1]);
    %   grid.RowHeight    = {'1x'};
    %   grid.ColumnWidth  = {'1x'};
    %   v = Manifold3(grid);
    %   v.Layout.Row = 1; v.Layout.Column = 1;

    properties (Access = private, Transient, NonCopyable)
        HTMLComponent matlab.ui.control.HTML
    end

    methods (Access = protected)
        function setup(comp)
            % Create the HTML component as a child of this container.
            comp.HTMLComponent = uihtml(comp);

            % Point to the local index.html for this component.
            comp.HTMLComponent.HTMLSource = Manifold3.resolveHTMLSource();

            % Let the parent (e.g., uigridlayout) control sizing.
            % We will size the uihtml to fill this container in update().
            comp.update();
        end

        function update(comp)
            if isempty(comp.HTMLComponent) || ~isvalid(comp.HTMLComponent)
                return;
            end

            % Fill the ComponentContainer client area.
            % ComponentContainer Position is in pixels; in a uigridlayout the grid sets it.
            w = comp.Position(3);
            h = comp.Position(4);

            % Guard against transient 0-size states.
            if w < 2 || h < 2
                return;
            end

            comp.HTMLComponent.Position = [1 1 w h];
        end
    end

    methods (Access = private, Static)
        function htmlPath = resolveHTMLSource()
            % Resolve the absolute path to web/index.html
            % Works in both development and packaged toolbox scenarios.
            classFile = mfilename('fullpath');
            classDir  = fileparts(classFile);
            htmlPath  = fullfile(classDir, 'web', 'index.html');
        end
    end
end
