classdef DeltaSignal < SignalModel
    methods
        function obj = DeltaSignal()
            obj.Type = 'Delta';
            obj.Parameters = struct();
        end

        function x = evaluate(obj, N, manifold)
            x = zeros(N,1);
            if ~isempty(manifold.Seed)
                x(manifold.Seed) = 1;
            end
        end
    end
end
