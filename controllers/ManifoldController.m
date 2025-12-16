classdef ManifoldController < matlab.ui.componentcontainer.ComponentContainer
    % ManifoldController
    %
    % A minimal, high-performance component that hosts a viewer3d
    % and renders a surface manifold.
    %
    % Responsibilities:
    %   - Render a triangulated surface
    %   - Expose the viewer3d object
    %   - Maintain a Seed vertex index
    %   - Synchronize Seed <-> annotation position
    %
    % This component does NOT:
    %   - Perform file I/O
    %   - Apply spectral kernels
    %   - Interpret Seed semantics beyond geometry

    %% =========================
    %  Public API
    %  =========================

    properties (SetObservable)
        % Current seed vertex index (1-based)
        Seed (1,1) double = 1
        
        % Visualization mode controlling surface colors
        VisualizationMode char {mustBeMember(VisualizationMode, ...
            {'Brush','Eigenmode','Signal','Custom'})} = 'Custom'
    end
    
    properties
        % Bct Manifold object (contains geometry and spectral data)
        Manifold
        
        % Manifold brush model
        ManifoldBrushModel_
        
        % Triangulation representing the manifold (UI object)
        Triangulation = []
        
        % Colormap model for brush visualization
        ColormapModel ColormapModel
    end

    properties (SetAccess = protected)
        % Expose the viewer publicly (read-only)
        Viewer images.ui.graphics3d.Viewer3D
        
        % Manifold brush toolbar (read-only access)
        BrushToolbar ManifoldBrushToolbar
    end

    %% =========================
    %  Private UI state
    %  =========================

    properties (Access = private, Transient, NonCopyable)
        GridLayout   matlab.ui.container.GridLayout
        SurfaceObj  images.ui.graphics3d.Surface

        % Canonical seed annotation
        SeedAnnotation images.ui.graphics.roi.Point
        
        % Context for brush components
        BrushContext ManifoldBrushContext
    end

events
    SeedChanged
end

    %% =========================
    %  Constructor
    %  =========================
    
    methods
        function comp = ManifoldController(parent)
            % Constructor - accepts parent container only
            % Usage:
            %   mc = ManifoldController(parent);
            %   mc.initializeFromManifold(manifold);
            
            comp@matlab.ui.componentcontainer.ComponentContainer(parent);
        end
    end

    %% =========================
    %  Component lifecycle
    %  =========================

    methods (Access = protected)

        function setup(comp)
            fprintf('[ManifoldController] Setup started\n');
            
            % Root grid - two columns: toolbar (narrow) and viewer (wide)
            comp.GridLayout = uigridlayout(comp);
            comp.GridLayout.RowHeight = {'1x'};
            comp.GridLayout.ColumnWidth = {60, '1x'};  % 60px toolbar, rest for viewer
            
            fprintf('[ManifoldController] Creating BrushContext\n');
            comp.BrushContext = ManifoldBrushContext();
            
            fprintf('[ManifoldController] Creating BrushToolbar\n');
            comp.BrushToolbar = ManifoldBrushToolbar(comp.GridLayout, 'Context', comp.BrushContext);
            comp.BrushToolbar.Layout.Row = 1;
            comp.BrushToolbar.Layout.Column = 1;
            
            fprintf('[ManifoldController] Creating viewer3d\n');
            % Create viewer3d directly in grid layout
            comp.Viewer = viewer3d( ...
                comp.GridLayout, ...
                "BackgroundColor", [0 0 0], ...
                "BackgroundGradient", "off", ...
                "RenderingQuality", "high");
            
            % Set viewer layout position
            comp.Viewer.Layout.Row = 1;
            comp.Viewer.Layout.Column = 2;

            % Sensible default camera
            comp.Viewer.Mode.Default.CameraVector = [-1 -1 1];

            % Listen for interactive annotation events
            addlistener(comp.Viewer, 'AnnotationAdded', ...
                @(~,evt)comp.onAnnotationEvent(evt));

            addlistener(comp.Viewer, 'AnnotationMoved', ...
                @(~,evt)comp.onAnnotationEvent(evt));
            
            % Listen to BrushContext for brush changes (correct topology)
            % Controller reacts to context changes, not individual brushes
            addlistener(comp.BrushContext, 'BrushModel', 'PostSet', ...
                @(~,~)comp.onBrushChanged());
            
            % Also update visualization when Seed changes
            addlistener(comp, 'Seed', 'PostSet', ...
                @(~,~)comp.onSeedChanged());
            
            % Initialize colormap model
            if isempty(comp.ColormapModel)
                comp.ColormapModel = ColormapModel();
                comp.ColormapModel.Name = 'redblue';
            end
            
            % Add listeners for colormap changes
            addlistener(comp.ColormapModel, 'Name', 'PostSet', ...
                @(~,~) comp.updateBrushVisualization());
            addlistener(comp.ColormapModel, 'Symmetric', 'PostSet', ...
                @(~,~) comp.updateBrushVisualization());
            addlistener(comp.ColormapModel, 'Resolution', 'PostSet', ...
                @(~,~) comp.updateBrushVisualization());
            
            fprintf('[ManifoldController] Setup complete\n');
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
        
        function setSurfaceColor(comp, RGB)
            % Set the color of the surface mesh
            % RGB: Nx3 matrix of RGB values [0,1]
            % Automatically sets VisualizationMode to 'Custom'
            
            if isempty(comp.SurfaceObj) || ~isvalid(comp.SurfaceObj)
                warning('ManifoldController:NoSurface', 'No surface object to color');
                return;
            end
            
            comp.SurfaceObj.Color = RGB;
        end
        
        function setBrushToolbarVisible(comp, visible)
            % Show or hide the brush toolbar
            % visible: logical true/false
            
            if isempty(comp.BrushToolbar) || ~isvalid(comp.BrushToolbar)
                return;
            end
            
            if visible
                comp.BrushToolbar.Visible = 'on';
            else
                comp.BrushToolbar.Visible = 'off';
            end
        end
        
        function initializeFromManifold(comp, manifold)
            % Initialize controller with a Manifold object
            % This is the recommended way to set up the controller after construction
            %
            % Usage:
            %   mc = ManifoldController(parent);
            %   mc.initializeFromManifold(fs6.Manifold);
            
            arguments
                comp
                manifold (1,1) bct.Manifold
            end
            
            comp.Manifold = manifold;
            comp.Triangulation = triangulation( ...
                double(manifold.Faces), ...
                manifold.Vertices);
            
            comp.Seed = 1;
            
            % Update brush context with manifold
            fprintf('[ManifoldController] Updating BrushContext with Manifold\n');
            comp.BrushContext.Manifold = manifold;
            
            % Explicitly trigger update and sync
            comp.update();
            comp.syncAnnotationToSeed();
        end

        function setMeshFromVerticesFaces(comp, V, F)
            % Set manifold mesh from vertices and faces
            % Can be called with Manifold object or (V, F) matrices

            if nargin == 2 && isa(V, 'Manifold')
                % Called with Manifold object
                comp.Manifold = V;
                V = comp.Manifold.Vertices;
                F = comp.Manifold.Faces;
            else
                % Called with (V, F) matrices
                % Create Manifold from V, F
                meshStruct = struct('Vertices', V, 'Faces', F);
                comp.Manifold = bct.Manifold(meshStruct);
            end

            comp.Triangulation = triangulation(double(F), V);

            % Initialize seed
            comp.Seed = 1;

            % Render and sync annotation
            comp.update();
            comp.syncAnnotationToSeed();
        end

        function setMeshFromTriangulation(comp, tri)
            % Set manifold mesh directly from a triangulation

            arguments
                comp
                tri (1,1) triangulation
            end

            comp.Triangulation = tri;
            
            % Create Manifold from triangulation
            meshStruct = struct('Vertices', tri.Points, 'Faces', tri.ConnectivityList);
            comp.Manifold = bct.Manifold(meshStruct);

            % Initialize seed
            comp.Seed = 1;

            % Render and sync annotation
            comp.update();
            comp.syncAnnotationToSeed();
        end
        
        function setEigenmodes(comp, lambda, modes)
            % Set spectral basis on Manifold
            if isempty(comp.Manifold)
                error('ManifoldController:NoManifold', ...
                    'Manifold must be set before setting eigenmodes');
            end
            
            % Create Lambda object (dual to Manifold)
            if isempty(comp.Manifold.dual)
                comp.Manifold.dual = Lambda();
            end
            comp.Manifold.dual.lambda = lambda;
            comp.Manifold.dual.U = modes;
            
            % Automatically refresh manifold brush to use new spectral basis
            comp.refreshManifoldBrush();
        end
        
        function refreshManifoldBrush(comp)
            % Refresh manifold brush UI after eigenmodes are set
            % This updates the KernelModel axis and re-initializes the brush
            if ~isempty(comp.ManifoldBrushUI_)
                comp.ManifoldBrushUI_.initialize();
            end
        end

        function clearMesh(comp)
            % Remove the surface and seed annotation

            if ~isempty(comp.SurfaceObj) && isvalid(comp.SurfaceObj)
                delete(comp.SurfaceObj);
            end

            if ~isempty(comp.SeedAnnotation) && isvalid(comp.SeedAnnotation)
                delete(comp.SeedAnnotation);
            end

            comp.SurfaceObj    = [];
            comp.SeedAnnotation = [];
            comp.Triangulation = [];
            comp.Seed = 1;
        end
    end

    %% =========================
    %  Internal logic
    %  =========================

    methods (Access = private)

        function syncAnnotationToSeed(comp)
            % Ensure a point annotation exists at the Seed vertex

            if isempty(comp.Triangulation)
                return
            end

            V = comp.Triangulation.Points;

            if comp.Seed < 1 || comp.Seed > size(V,1)
                return
            end

            pos = V(comp.Seed, :);

            if isempty(comp.SeedAnnotation) || ~isvalid(comp.SeedAnnotation)
                comp.SeedAnnotation = images.ui.graphics.roi.Point( ...
                    'Parent', comp.Viewer, ...
                    'Position', pos);
            else
                % Programmatic move (does not fire AnnotationMoved)
                comp.SeedAnnotation.Position = pos;
            end
        end

        function onAnnotationEvent(comp, evt)
            % Handle AnnotationAdded / AnnotationMoved events
            % Map annotation geometry -> Seed vertex

            if isempty(comp.Triangulation)
                return
            end

            roi = evt.Annotation;
            pos = roi.Position;

            % Defensive checks
            if ~isnumeric(pos) || size(pos,2) ~= 3
                return
            end

            % Handle line annotations by centroid
            if size(pos,1) > 1
                pos = mean(pos, 1);
            end

            pos = double(pos);

            vidx = nearestNeighbor(comp.Triangulation, pos);

            if comp.Seed ~= vidx
                comp.Seed = vidx;
                notify(comp, 'SeedChanged');
            end

            comp.SeedAnnotation = roi;
        end
        
        function onSeedChanged(comp)
            % React to seed changes - re-evaluate brush at new location
            fprintf('[ManifoldController] Seed changed to: %d\n', comp.Seed);
            
            % Update brush context seed
            comp.BrushContext.Seed = comp.Seed;
            
            % Re-evaluate and visualize brush at new seed
            comp.updateBrushVisualization();
        end
        
        function onBrushChanged(comp)
            % React to brush changes in the context
            % Controller doesn't care which brush - just responds uniformly
            
            fprintf('[ManifoldController] Brush changed in context\n');
            
            % Update visualization when brush changes
            if ~isempty(comp.BrushContext.BrushModel) && ...
               ~isempty(comp.BrushContext.BrushModel.Brush)
                fprintf('[ManifoldController] New brush active: %s\n', ...
                    class(comp.BrushContext.BrushModel.Brush));
                
                % Update brush visualization on the surface
                comp.updateBrushVisualization();
            end
        end
        
        function updateBrushVisualization(comp)
            % Update surface coloring based on current brush evaluation
            % Only applies colors when VisualizationMode is 'Brush'
            
            if isempty(comp.SurfaceObj) || ~isvalid(comp.SurfaceObj)
                return;
            end
            
            % Only update if in Brush mode
            if ~strcmp(comp.VisualizationMode, 'Brush')
                return;
            end
            
            if isempty(comp.BrushContext.Field)
                fprintf('[ManifoldController] No brush field to visualize\n');
                return;
            end
            
            % Get evaluated field from context
            w = comp.BrushContext.Field;
            
            % Normalize weights
            if max(abs(w)) > 0
                w = w ./ max(abs(w));
            end
            
            % Apply colormap
            RGB = comp.applyColormap(w);
            
            % Update surface color
            comp.SurfaceObj.Color = RGB;
            
            fprintf('[ManifoldController] Brush visualization updated\n');
        end
        
        function RGB = applyColormap(comp, w)
            % Apply colormap to normalized weights using ColormapModel
            
            % Use ColormapModel.apply() for direct conversion
            RGB = comp.ColormapModel.apply(w);
        end
    end
end
