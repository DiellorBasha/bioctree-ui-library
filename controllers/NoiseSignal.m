classdef NoiseSignal < SignalModel
    methods
        function obj = NoiseSignal()
            obj.Type = 'Noise';
            obj.Parameters = struct('sigma',1,'mean',0);
        end

        function x = evaluate(obj, N, ~)
            p = obj.Parameters;
            x = p.mean + p.sigma * randn(N,1);
        end
    end
end
