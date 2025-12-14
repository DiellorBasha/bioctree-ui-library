classdef ManifoldController < matlab.ui.componentcontainer.ComponentContainer
    % ManifoldController
    %
    % A minimal, high-performance component that hosts a viewer3d
    % and renders a surface manifold. The viewer object is exposed
    % publicly so that other components can directly access:
    %
    %   - Viewer.Annotations
    %   - Viewer.CurrentObject
    %   - Camera, lighting, clipping planes, etc.
    %
    % This component does NOT:
    %   - Perform file I/O
    %   - Interpret annotations
    %   - Implement selection logic
    %
    % Those responsibilities belong to higher-level controllers.

    %% =========================
    %  Public API
    %  =========================

    properties
        % Triangulation representing the manifold
        % (assigned after construction)
        Triangulation = []
    end

    properties (SetAccess = protected)
        % Expose the viewer publicly (read-only)
        Viewer images.ui.graphics3d.Viewer3D
    end

    %% =========================
    %  Private UI state
    %  =========================

    properties (Access = private, Transient, NonCopyable)
        GridLayout   matlab.ui.container.GridLayout
        ViewerPanel matlab.ui.container.Panel
        SurfaceObj  images.ui.graphics3d.Surface
    end

    %% =========================
    %  Component lifecycle
    %  =========================

    methods (Access = protected)

        function setup(comp)
            % Root grid (single cell)
            comp.GridLayout = uigridlayout(comp);
            comp.GridLayout.RowHeight    = {'1x'};
            comp.GridLayout.ColumnWidth = {'1x'};

            % Panel to host viewer3d (required)
            comp.ViewerPanel = uipanel(comp.GridLayout);
            comp.ViewerPanel.Layout.Row    = 1;
            comp.ViewerPanel.Layout.Column = 1;

            % Create viewer3d
            comp.Viewer = viewer3d( ...
                comp.ViewerPanel, ...
                "BackgroundColor", [0 0 0], ...
                "BackgroundGradient", "off", ...
                "RenderingQuality", "high");

            % Sensible default camera
            comp.Viewer.Mode.Default.CameraVector = [-1 -1 1];
        end

        function update(comp)
            % Render or update surface when Triangulation changes

            if isempty(comp.Triangulation)
                return
            end

            if isempty(comp.SurfaceObj) || ~isvalid(comp.SurfaceObj)
                comp.SurfaceObj = images.ui.graphics3d.Surface( ...
                    comp.Viewer, ...
                    'Data', comp.Triangulation, ...
                    'Color', [0.8 0.8 0.8], ...
                    'Alpha', 1, ...
                    'Wireframe', false);
            else
                comp.SurfaceObj.Data = comp.Triangulation;
            end
        end
    end

    %% =========================
    %  Public methods
    %  =========================

    methods
        function setMeshFromVerticesFaces(comp, V, F)
            % Set manifold mesh from workspace data
            %
            % V : [N x 3] double
            % F : [M x 3] numeric (int32/double)

            arguments
                comp
                V (:,3) double
                F (:,3) {mustBeNumeric}
            end

            F = double(F);
            comp.Triangulation = triangulation(F, V);

            % Trigger render
            comp.update();
        end

        function setMeshFromTriangulation(comp, tri)
            % Set manifold mesh directly from a triangulation

            arguments
                comp
                tri (1,1) triangulation
            end

            comp.Triangulation = tri;
            comp.update();
        end

        function clearMesh(comp)
            % Remove the surface (viewer remains alive)

            if ~isempty(comp.SurfaceObj) && isvalid(comp.SurfaceObj)
                delete(comp.SurfaceObj);
            end

            comp.SurfaceObj = [];
            comp.Triangulation = [];
        end
    end
end
