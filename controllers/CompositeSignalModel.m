classdef CompositeSignalModel < handle
    % CompositeSignalModel
    % Holds and combines multiple signal models

    properties (SetObservable)
        Signals = {}   % cell array of SignalModel objects
    end

    % ============================================================
    % Signal management
    % ============================================================
    methods

        function addSignal(obj, signal)
            arguments
                obj
                signal SignalModel
            end
            obj.Signals{end+1} = signal;
        end

        function removeSignal(obj, idx)
            obj.Signals(idx) = [];
        end

        function clear(obj)
            obj.Signals = {};
        end
    end

    % ============================================================
    % Evaluation
    % ============================================================
    methods

        function x = evaluate(obj, N, context)
            % Evaluate composite signal
            %
            % N       : number of vertices
            % context : struct (e.g. manifold, seed, etc.)

            x = zeros(N,1);

            for i = 1:numel(obj.Signals)
                s = obj.Signals{i};
                xi = s.evaluate(N, context);
                x = x + s.Weight * xi;
            end
        end
    end
end
