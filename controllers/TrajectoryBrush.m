classdef TrajectoryBrush < ManifoldBrush
    % TrajectoryBrush
    %
    % Computes shortest path between source (Seed) and target vertex,
    % then applies a base brush (default: SpectralBrush) at each point
    % along the trajectory.
    %
    % Usage:
    %   brush = TrajectoryBrush(manifold);
    %   brush.Target = 100;  % Set target vertex
    %   brush.KernelModel = kernelModel;  % Required for SpectralBrush
    %   w = brush.evaluate(seed);  % Computes path from seed to target

    properties (SetAccess = protected)
        Type char = 'Trajectory'
    end

    properties (SetObservable)
        Target (1,1) double = 1      % Target vertex index
        BaseBrush                    % Brush to apply along trajectory (default: SpectralBrush, set in constructor)
        KernelModel KernelModel      % Kernel for SpectralBrush
        CurrentPathIndex (1,1) double = 1  % Current position in path (for animation)
    end

    properties (Access = private)
        MeshGraph                    % Cached MATLAB graph representation
        CurrentPath (:,1) double     % Current shortest path
    end

    methods
        function obj = TrajectoryBrush(manifold)
            % Constructor requires Manifold
            obj@ManifoldBrush(manifold);
            
            % Default base brush = SpectralBrush
            obj.BaseBrush = SpectralBrush(manifold);
            
            % Don't build graph yet - wait until getPath() is called
            % This allows brush to be created even if graph building fails
        end
        
        function set.KernelModel(obj, kernelModel)
            % When KernelModel is set, pass it to BaseBrush if it's SpectralBrush
            obj.KernelModel = kernelModel;
            if isa(obj.BaseBrush, 'SpectralBrush')
                obj.BaseBrush.KernelModel = kernelModel;
            end
        end
        
        function set.Target(obj, target)
            % Validate target is within valid range
            if ~isempty(obj.Manifold)
                nVerts = size(obj.Manifold.Vertices, 1);
                if target < 1 || target > nVerts
                    error('TrajectoryBrush:InvalidTarget', ...
                        'Target must be between 1 and %d', nVerts);
                end
            end
            obj.Target = target;
        end
        
        function path = getPath(obj, source)
            % Compute shortest path from source to target
            % Returns: path - Vector of vertex indices along shortest path
            
            if isempty(obj.MeshGraph)
                obj.buildMeshGraph();
            end
            
            if nargin < 2
                error('TrajectoryBrush:NoSource', 'Source vertex required');
            end
            
            % Compute shortest path using graph
            [path, ~] = shortestpath(obj.MeshGraph, source, obj.Target);
            
            % Cache the path
            obj.CurrentPath = path(:);
        end
        
        function w = evaluateAtPathIndex(obj, pathIndex)
            % Evaluate brush at a specific index along the current path
            % Usage: w = evaluateAtPathIndex(pathIndex)
            
            if isempty(obj.CurrentPath)
                error('TrajectoryBrush:NoPath', ...
                    'Path must be computed first using getPath()');
            end
            
            if pathIndex < 1 || pathIndex > length(obj.CurrentPath)
                error('TrajectoryBrush:InvalidPathIndex', ...
                    'Path index must be between 1 and %d', length(obj.CurrentPath));
            end
            
            % Get vertex at this path position
            vertex = obj.CurrentPath(pathIndex);
            
            % Evaluate base brush at this vertex
            w = obj.BaseBrush.evaluate(vertex);
            
            % Update current index
            obj.CurrentPathIndex = pathIndex;
        end
        
        function w = evaluateFullTrajectory(obj, source)
            % Evaluate brush for entire trajectory (sum over all path points)
            % Usage: w = evaluateFullTrajectory(source)
            
            path = obj.getPath(source);
            nVerts = size(obj.Manifold.Vertices, 1);
            w = zeros(nVerts, 1);
            
            % Sum contributions from all path points
            for i = 1:length(path)
                w = w + obj.evaluateAtPathIndex(i);
            end
            
            % Normalize
            m = max(abs(w));
            if m > 0
                w = w ./ m;
            end
        end
    end

    methods (Access = protected)
        function w = evaluateCore(obj, varargin)
            % Evaluate trajectory brush
            % Usage: w = evaluateCore(source)
            
            % Guard clauses
            if isempty(obj.BaseBrush)
                error('TrajectoryBrush:NoBaseBrush', 'BaseBrush must be set');
            end
            
            if isempty(obj.Manifold)
                error('TrajectoryBrush:NoManifold', 'Manifold must be set');
            end
            
            % Get source vertex
            if nargin < 2
                error('TrajectoryBrush:NoSource', 'Source vertex required');
            end
            source = varargin{1};
            
            % Compute and evaluate full trajectory
            w = obj.evaluateFullTrajectory(source);
        end
        
        function buildMeshGraph(obj)
            % Build MATLAB graph representation of mesh
            
            if isempty(obj.Manifold)
                error('TrajectoryBrush:NoManifold', 'Manifold must be set');
            end
            
            try
                % Try using bct.io.convert if available
                obj.MeshGraph = bct.io.convert.manifoldToMatlabGraph(obj.Manifold, 'Weighted', true);
            catch ME
                % Fallback: build graph manually from faces
                fprintf('[TrajectoryBrush] Building graph manually: %s\n', ME.message);
                obj.buildGraphFromFaces();
            end
        end
        
        function buildGraphFromFaces(obj)
            % Fallback: Build graph directly from manifold faces
            
            F = obj.Manifold.Faces;
            V = obj.Manifold.Vertices;
            
            % Extract edges from faces
            edges = [F(:,1) F(:,2); F(:,2) F(:,3); F(:,3) F(:,1)];
            edges = unique(sort(edges, 2), 'rows');
            
            % Compute edge lengths (Euclidean distance)
            nEdges = size(edges, 1);
            weights = zeros(nEdges, 1);
            for i = 1:nEdges
                v1 = edges(i, 1);
                v2 = edges(i, 2);
                weights(i) = norm(V(v1, :) - V(v2, :));
            end
            
            % Create graph
            obj.MeshGraph = graph(edges(:,1), edges(:,2), weights);
        end
    end
end
