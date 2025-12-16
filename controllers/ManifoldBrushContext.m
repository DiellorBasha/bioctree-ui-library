classdef ManifoldBrushContext < handle
    % ManifoldBrushContext
    %
    % Shared interaction state for manifold brushing.
    %
    % Responsibilities:
    %   - Hold manifold + seed
    %   - Hold active brush model
    %   - Compute brush field on change
    %   - Emit events for rendering / UI
    %
    % Does NOT:
    %   - Render anything
    %   - Own UI components
    %   - Implement brush logic

    %% =========================
    % Public state
    % =========================

    properties (SetObservable)
        Manifold                    % bct.Manifold
        Seed (1,1) double = 1       % Vertex index
        BrushModel ManifoldBrushModel  % ManifoldBrushModel instance
        Field                       % Nx1 brush signal
    end

    %% =========================
    % Events
    % =========================

    events
        SeedChanged
        BrushChanged
        FieldChanged
        ManifoldChanged
    end

    %% =========================
    % Lifecycle
    % =========================

    methods
        function obj = ManifoldBrushContext(varargin)
            % Optional constructor:
            %   ctx = ManifoldBrushContext(manifold)

            if nargin >= 1
                obj.Manifold = varargin{1};
            end

            % Attach listeners
            addlistener(obj, 'Seed', 'PostSet', ...
                @(~,~)obj.onSeedChanged());

            addlistener(obj, 'BrushModel', 'PostSet', ...
                @(~,~)obj.onBrushChanged());

            addlistener(obj, 'Manifold', 'PostSet', ...
                @(~,~)obj.onManifoldChanged());
        end
    end

    %% =========================
    % Internal reactions
    % =========================

    methods (Access = private)

        function onSeedChanged(obj)
            notify(obj,'SeedChanged');
            obj.recompute();
        end

        function onBrushChanged(obj)
            notify(obj,'BrushChanged');
            obj.recompute();
        end

        function onManifoldChanged(obj)
            notify(obj,'ManifoldChanged');

            % Propagate manifold into brush if needed
            if ~isempty(obj.BrushModel) && ...
               ~isempty(obj.BrushModel.Brush)

                obj.BrushModel.Brush.Manifold = obj.Manifold;
            end

            obj.recompute();
        end
    end

    %% =========================
    % Core computation
    % =========================

    methods
        function recompute(obj)
            % Recompute brush field if possible

            if isempty(obj.BrushModel) || isempty(obj.BrushModel.Brush)
                return;
            end

            if isempty(obj.Manifold)
                return;
            end

            try
                w = obj.BrushModel.evaluate(obj.Seed);
            catch ME
                warning('ManifoldBrushContext:EvaluationFailed', ...
                    '%s', ME.message);
                return;
            end

            obj.Field = w;
            notify(obj,'FieldChanged');
        end
    end
end
