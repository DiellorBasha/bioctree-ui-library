classdef (Abstract) SignalModel < handle
    properties (SetObservable)
        Type char
        Parameters struct
        Weight (1,1) double = 1.0   % for superposition
    end

    methods (Abstract)
        x = evaluate(obj, N, manifold)
    end
end
