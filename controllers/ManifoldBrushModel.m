classdef ManifoldBrushModel < handle
    % ManifoldBrushModel
    % Owns exactly one ManifoldBrush

    properties (SetObservable)
        Brush = []  % Will hold a ManifoldBrush subclass instance
    end

    methods
        function w = evaluate(obj, varargin)
            % Evaluate manifold brush
            % Passes through any parameters (e.g., seed) to brush
            
            if isempty(obj.Brush)
                error('ManifoldBrushModel:NoBrush', ...
                    'No brush is set');
            end
            
            w = obj.Brush.evaluate(varargin{:});
        end
    end
end
