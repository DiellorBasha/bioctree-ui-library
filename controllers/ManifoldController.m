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
        
        % Target vertex for trajectory brushes (1-based)
        Target (1,1) double = 1
        
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
        
        % Target annotation for trajectory brushes (legacy, replaced by TrajectoryLine)
        TargetAnnotation images.ui.graphics.roi.Point
        
        % Line ROI for trajectory brush (connects source and target)
        TrajectoryLine images.roi.Line
        
        % Array of line objects showing the traced path during animation
        PathLines
        
        % Accumulated field for trajectory visualization
        AccumulatedField (:,1) double
        
        % Animation timer for trajectory brushes
        TrajectoryTimer timer
    end
    
    properties (Access = public)
        % Context for brush components (public for EigenmodeController access)
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
            
            % Root grid - two rows: viewer (top) and toolbar (bottom)
            comp.GridLayout = uigridlayout(comp);
            comp.GridLayout.RowHeight = {'1x', 60};  % Viewer expands, 60px toolbar
            comp.GridLayout.ColumnWidth = {'1x'};
            
            fprintf('[ManifoldController] Creating BrushContext\n');
            comp.BrushContext = ManifoldBrushContext();
            
            fprintf('[ManifoldController] Creating BrushToolbar\n');
            comp.BrushToolbar = ManifoldBrushToolbar(comp.GridLayout, 'Context', comp.BrushContext);
            comp.BrushToolbar.Orientation = 'Horizontal';
            comp.BrushToolbar.Layout.Row = 2;
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
            comp.Viewer.Layout.Column = 1;

            % Sensible default camera
            comp.Viewer.Mode.Default.CameraVector = [-1 -1 1];
            
            % Set scale bar and spatial units
            comp.Viewer.ScaleBar = 'on';
            comp.Viewer.SpatialUnits = 'mm';

            % Listen for interactive annotation events
            addlistener(comp.Viewer, 'AnnotationAdded', ...
                @(~,evt)comp.onAnnotationEvent(evt));

            addlistener(comp.Viewer, 'AnnotationMoved', ...
                @(~,evt)comp.onAnnotationEvent(evt));
            
            % Listen to BrushContext events (standard pattern)
            addlistener(comp.BrushContext, 'BrushChanged', ...
                @(~,~)comp.onBrushChanged());
            
            addlistener(comp.BrushContext, 'FieldChanged', ...
                @(~,~) comp.updateBrushVisualization());
            
            % Also update visualization when Seed changes
            addlistener(comp, 'Seed', 'PostSet', ...
                @(~,~)comp.onSeedChanged());
            
            % Update visualization when Target changes
            addlistener(comp, 'Target', 'PostSet', ...
                @(~,~)comp.onTargetChanged());
            
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

        function setSeedAnnotationVisible(comp, visible)
            % Show or hide the seed annotation
            % visible: logical true/false
            
            if isempty(comp.SeedAnnotation) || ~isvalid(comp.SeedAnnotation)
                return;
            end
            
            if visible
                comp.SeedAnnotation.Visible = 'on';
            else
                comp.SeedAnnotation.Visible = 'off';
            end
        end

        function setTargetAnnotationVisible(comp, visible)
            % Show or hide the target annotation
            % visible: logical true/false
            
            if isempty(comp.TargetAnnotation) || ~isvalid(comp.TargetAnnotation)
                return;
            end
            
            if visible
                comp.TargetAnnotation.Visible = 'on';
            else
                comp.TargetAnnotation.Visible = 'off';
            end
        end

        function startTrajectoryAnimation(comp, updateInterval)
            % Start animating trajectory brush from Seed to Target
            % updateInterval: Time between path steps in seconds (default 0.1)
            
            if nargin < 2
                updateInterval = 0.1;
            end
            
            % Verify TrajectoryBrush is active
            if isempty(comp.BrushContext.BrushModel) || ...
               isempty(comp.BrushContext.BrushModel.Brush) || ...
               ~isa(comp.BrushContext.BrushModel.Brush, 'TrajectoryBrush')
                warning('ManifoldController:NoTrajectoryBrush', ...
                    'TrajectoryBrush must be active to animate trajectory');
                return;
            end
            
            brush = comp.BrushContext.BrushModel.Brush;
            
            % Get source and target from Line ROI endpoints
            [sourceVert, targetVert] = comp.getLineEndpointVertices();
            
            if isempty(sourceVert) || isempty(targetVert)
                warning('ManifoldController:NoEndpoints', ...
                    'Line endpoints not set. Move the line annotation endpoints.');
                return;
            end
            
            % Compute path from source to target
            path = brush.getPath(sourceVert);
            
            if isempty(path)
                warning('ManifoldController:NoPath', ...
                    'No path found from source to target');
                return;
            end
            
            fprintf('[ManifoldController] Starting trajectory animation: %d steps\n', length(path));
            
            % Initialize accumulated field and clear old path lines
            comp.clearPathLines();
            nVerts = size(comp.Triangulation.Points, 1);
            comp.AccumulatedField = zeros(nVerts, 1);
            
            % Start animation
            comp.animateTrajectory(path, updateInterval);
        end

        function animateTrajectory(comp, pathIndices, updateInterval)
            % Animate trajectory brush along a path
            % pathIndices: Vector of vertex indices to traverse
            % updateInterval: Time between updates in seconds (default 0.1)
            
            if nargin < 3
                updateInterval = 0.1;
            end
            
            % Stop any existing animation
            comp.stopTrajectoryAnimation();
            
            % Create timer for animation
            comp.TrajectoryTimer = timer(...
                'ExecutionMode', 'fixedRate', ...
                'Period', updateInterval, ...
                'TasksToExecute', length(pathIndices), ...
                'TimerFcn', @(~,~) comp.trajectoryTimerCallback(pathIndices));
            
            % Store current index in timer UserData
            comp.TrajectoryTimer.UserData = struct('currentIndex', 0, 'pathIndices', pathIndices);
            
            start(comp.TrajectoryTimer);
        end

        function stopTrajectoryAnimation(comp)
            % Stop trajectory animation if running
            
            if ~isempty(comp.TrajectoryTimer) && isvalid(comp.TrajectoryTimer)
                stop(comp.TrajectoryTimer);
                delete(comp.TrajectoryTimer);
                comp.TrajectoryTimer = [];
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
            
            % Update brush context with manifold
            fprintf('[ManifoldController] Updating BrushContext with Manifold\n');
            comp.BrushContext.Manifold = comp.Manifold;

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
            
            % Update brush context with manifold
            fprintf('[ManifoldController] Updating BrushContext with Manifold\n');
            comp.BrushContext.Manifold = comp.Manifold;

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
            % Remove the surface and annotations

            if ~isempty(comp.SurfaceObj) && isvalid(comp.SurfaceObj)
                delete(comp.SurfaceObj);
            end

            if ~isempty(comp.SeedAnnotation) && isvalid(comp.SeedAnnotation)
                delete(comp.SeedAnnotation);
            end
            
            if ~isempty(comp.TargetAnnotation) && isvalid(comp.TargetAnnotation)
                delete(comp.TargetAnnotation);
            end
            
            if ~isempty(comp.TrajectoryLine) && isvalid(comp.TrajectoryLine)
                delete(comp.TrajectoryLine);
            end
            
            comp.clearPathLines();
            comp.stopTrajectoryAnimation();

            comp.SurfaceObj = [];
            comp.SeedAnnotation = [];
            comp.TargetAnnotation = [];
            comp.TrajectoryLine = [];
            comp.Triangulation = [];
            comp.Seed = 1;
            comp.Target = 1;
        end
    end

    %% =========================
    %  Internal logic
    %  =========================

    methods (Access = private)

        function initializeTrajectoryLine(comp)
            % Create or show Line ROI for trajectory brush
            
            fprintf('[ManifoldController] initializeTrajectoryLine called\n');
            
            if isempty(comp.Triangulation)
                fprintf('[ManifoldController] No triangulation, cannot create line\n');
                return;
            end
            
            V = comp.Triangulation.Points;
            nVerts = size(V, 1);
            
            fprintf('[ManifoldController] Creating line with %d vertices available\n', nVerts);
            
            % Pick two random vertices for initial line
            rng(42);  % Reproducible random selection
            sourceVert = randi(nVerts);
            targetVert = randi(nVerts);
            while targetVert == sourceVert
                targetVert = randi(nVerts);
            end
            
            sourcePos = V(sourceVert, :);
            targetPos = V(targetVert, :);
            
            fprintf('[ManifoldController] Line endpoints: vertex %d -> vertex %d\n', sourceVert, targetVert);
            
            if isempty(comp.TrajectoryLine) || ~isvalid(comp.TrajectoryLine)
                % Create new Line annotation
                fprintf('[ManifoldController] Creating new Line annotation\n');
                
                comp.TrajectoryLine = images.ui.graphics.roi.Line(...
                    'Position', [sourcePos; targetPos], ...
                    'Color', 'yellow', ...
                    'Label', 'Trajectory');
                
                % Add to viewer's Annotations property
                if isempty(comp.Viewer.Annotations)
                    comp.Viewer.Annotations = comp.TrajectoryLine;
                else
                    comp.Viewer.Annotations = [comp.Viewer.Annotations; comp.TrajectoryLine];
                end
                
                fprintf('[ManifoldController] Line annotation added to viewer\n');
                fprintf('[ManifoldController] Trajectory Line created. Drag endpoints to set source/target.\n');
            else
                % Show existing line
                fprintf('[ManifoldController] Showing existing Line ROI\n');
                comp.TrajectoryLine.Visible = 'on';
            end
            
            % Update brush with initial endpoints
            comp.updateTrajectoryEndpoints();
        end

        function hideTrajectoryLine(comp)
            % Remove Line annotation when trajectory brush is not active
            
            if ~isempty(comp.TrajectoryLine) && isvalid(comp.TrajectoryLine)
                % Remove from viewer annotations
                annotations = comp.Viewer.Annotations;
                if ~isempty(annotations)
                    idx = annotations == comp.TrajectoryLine;
                    comp.Viewer.Annotations = annotations(~idx);
                end
                delete(comp.TrajectoryLine);
                comp.TrajectoryLine = [];
            end
            
            % Clear path lines
            comp.clearPathLines();
        end

        function onTrajectoryLineMoved(comp, ~)
            % Called when user moves the trajectory line endpoints
            
            comp.updateTrajectoryEndpoints();
        end

        function updateTrajectoryEndpoints(comp)
            % Update brush source and target from line endpoints
            
            [sourceVert, targetVert] = comp.getLineEndpointVertices();
            
            if isempty(sourceVert) || isempty(targetVert)
                return;
            end
            
            % Update Seed and Target properties
            comp.Seed = sourceVert;
            comp.Target = targetVert;
            
            % Update TrajectoryBrush if active
            if ~isempty(comp.BrushContext.BrushModel) && ...
               ~isempty(comp.BrushContext.BrushModel.Brush) && ...
               isa(comp.BrushContext.BrushModel.Brush, 'TrajectoryBrush')
                
                brush = comp.BrushContext.BrushModel.Brush;
                brush.Target = targetVert;
                
                fprintf('[ManifoldController] Trajectory endpoints updated: Source=%d, Target=%d\n', ...
                    sourceVert, targetVert);
            end
        end

        function [sourceVert, targetVert] = getLineEndpointVertices(comp)
            % Find nearest vertices to line endpoints
            
            sourceVert = [];
            targetVert = [];
            
            if isempty(comp.TrajectoryLine) || ~isvalid(comp.TrajectoryLine)
                return;
            end
            
            if isempty(comp.Triangulation)
                return;
            end
            
            % Get line endpoints
            linePos = comp.TrajectoryLine.Position;  % 2x3 matrix [start; end]
            sourcePos = linePos(1, :);
            targetPos = linePos(2, :);
            
            % Find nearest vertices
            V = comp.Triangulation.Points;
            
            distSource = sum((V - sourcePos).^2, 2);
            [~, sourceVert] = min(distSource);
            
            distTarget = sum((V - targetPos).^2, 2);
            [~, targetVert] = min(distTarget);
        end

        function addPathLine(comp, vert1, vert2)
            % Add a Line annotation between two vertices in the path
            
            if isempty(comp.Triangulation)
                return;
            end
            
            V = comp.Triangulation.Points;
            pos1 = V(vert1, :);
            pos2 = V(vert2, :);
            
            % Create line annotation between vertices
            pathLine = images.ui.graphics.roi.Line(...
                'Position', [pos1; pos2], ...
                'Color', 'cyan');
            
            % Add to viewer's Annotations
            comp.Viewer.Annotations = [comp.Viewer.Annotations; pathLine];
            
            % Store in PathLines array
            if isempty(comp.PathLines)
                comp.PathLines = pathLine;
            else
                comp.PathLines(end+1) = pathLine;
            end
        end

        function clearPathLines(comp)
            % Remove all path line annotations
            
            if ~isempty(comp.PathLines)
                % Remove from viewer annotations
                annotations = comp.Viewer.Annotations;
                for i = 1:length(comp.PathLines)
                    if isvalid(comp.PathLines(i))
                        % Remove from annotations array
                        idx = annotations == comp.PathLines(i);
                        annotations = annotations(~idx);
                        delete(comp.PathLines(i));
                    end
                end
                comp.Viewer.Annotations = annotations;
                comp.PathLines = [];
            end
        end

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
                    'Position', pos, ...
                    'Color', 'green');
            else
                % Programmatic move (does not fire AnnotationMoved)
                comp.SeedAnnotation.Position = pos;
            end
        end

        function syncAnnotationToTarget(comp)
            % Ensure a point annotation exists at the Target vertex

            if isempty(comp.Triangulation)
                return
            end

            V = comp.Triangulation.Points;

            if comp.Target < 1 || comp.Target > size(V,1)
                return
            end

            pos = V(comp.Target, :);

            if isempty(comp.TargetAnnotation) || ~isvalid(comp.TargetAnnotation)
                comp.TargetAnnotation = images.ui.graphics.roi.Point( ...
                    'Parent', comp.Viewer, ...
                    'Position', pos, ...
                    'Color', 'red');
            else
                % Programmatic move (does not fire AnnotationMoved)
                comp.TargetAnnotation.Position = pos;
            end
        end

        function trajectoryTimerCallback(comp, pathIndices)
            % Timer callback for trajectory animation with accumulation
            
            if isempty(comp.TrajectoryTimer) || ~isvalid(comp.TrajectoryTimer)
                return;
            end
            
            % Get current state
            userData = comp.TrajectoryTimer.UserData;
            currentIdx = userData.currentIndex + 1;
            
            if currentIdx > length(pathIndices)
                comp.stopTrajectoryAnimation();
                fprintf('[ManifoldController] Trajectory animation complete\n');
                return;
            end
            
            % Current vertex in path
            currentVert = pathIndices(currentIdx);
            
            % Evaluate SpectralBrush at current position
            if ~isempty(comp.BrushContext) && ...
               ~isempty(comp.BrushContext.BrushModel) && ...
               isa(comp.BrushContext.BrushModel.Brush, 'TrajectoryBrush')
                
                brush = comp.BrushContext.BrushModel.Brush;
                w = brush.BaseBrush.evaluate(currentVert);
                
                % ACCUMULATE the brush field (summation)
                comp.AccumulatedField = comp.AccumulatedField + w;
                
                % Update visualization with accumulated field
                comp.BrushContext.Field = comp.AccumulatedField;
                notify(comp.BrushContext, 'FieldChanged');
            end
            
            % Add Line annotation between current and previous vertex
            if currentIdx > 1
                prevVert = pathIndices(currentIdx - 1);
                comp.addPathLine(prevVert, currentVert);
            end
            
            % Update timer state
            userData.currentIndex = currentIdx;
            comp.TrajectoryTimer.UserData = userData;
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
            
            % Sync seed annotation position
            comp.syncAnnotationToSeed();
            
            % Re-evaluate and visualize brush at new seed
            comp.updateBrushVisualization();
        end

        function onTargetChanged(comp)
            % React to target changes - re-evaluate trajectory if active
            fprintf('[ManifoldController] Target changed to: %d\n', comp.Target);
            
            % Sync target annotation position
            comp.syncAnnotationToTarget();
            
            % If TrajectoryBrush is active, update its target
            if ~isempty(comp.BrushContext.BrushModel) && ...
               ~isempty(comp.BrushContext.BrushModel.Brush) && ...
               isa(comp.BrushContext.BrushModel.Brush, 'TrajectoryBrush')
                
                comp.BrushContext.BrushModel.Brush.Target = comp.Target;
                comp.updateBrushVisualization();
            end
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
                
                % Configure TrajectoryBrush if needed
                if isa(comp.BrushContext.BrushModel.Brush, 'TrajectoryBrush')
                    brush = comp.BrushContext.BrushModel.Brush;
                    
                    % Pass KernelModel from context if available
                    if ~isempty(comp.BrushContext.KernelModel)
                        brush.KernelModel = comp.BrushContext.KernelModel;
                    end
                    
                    % Hide point annotations, show line annotation
                    comp.setSeedAnnotationVisible(false);
                    comp.setTargetAnnotationVisible(false);
                    comp.initializeTrajectoryLine();
                else
                    % Show seed annotation, hide trajectory UI
                    comp.setSeedAnnotationVisible(true);
                    comp.setTargetAnnotationVisible(false);
                    comp.hideTrajectoryLine();
                end
                
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
