classdef PatchSignal < SignalModel
    methods
        function obj = PatchSignal()
            obj.Type = 'Patch';
            obj.Parameters = struct('radius',5);
        end

        function x = evaluate(obj, N, manifold)
            x = zeros(N,1);
            if isempty(manifold.Seed), return; end

            d = manifold.computeGeodesicDistance(manifold.Seed);
            x(d <= obj.Parameters.radius) = 1;
        end
    end
end
