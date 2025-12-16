classdef ColormapModel < handle

    properties (SetObservable)
        Name char = 'parula'
        Symmetric logical = false
        AutoLimits logical = true
        Lo double = 0
        Hi double = 1
        Resolution (1,1) double = 256
    end

    methods
        function RGB = apply(model, x)
            args = {'colormap', model.Name};

            if model.Symmetric
                args = [args, {'symmetric', true}];
            end

            if ~model.AutoLimits
                args = [args, {'lo', model.Lo, 'hi', model.Hi}];
            end

            RGB = bct.show.x2rgb(x, args{:});
        end

        function C = colormap(model)
            switch lower(model.Name)
                case 'parula',  C = parula(model.Resolution);
                case 'turbo',   C = turbo(model.Resolution);
                case 'jet',     C = jet(model.Resolution);
                case 'hot',     C = hot(model.Resolution);
                case 'redblue'
                    C = model.makeRedBlue();
                otherwise
                    C = parula(model.Resolution);
            end
        end
    end

    methods (Access = private)
        function C = makeRedBlue(model)
            m = model.Resolution;
            bottom = [0.230, 0.299, 0.754];
            middle = [1.000, 1.000, 1.000];
            top    = [0.706, 0.016, 0.150];

            C = zeros(m,3);
            for i = 1:3
                C(:,i) = interp1([1, ceil(m/2), m], ...
                    [bottom(i), middle(i), top(i)], 1:m);
            end
        end
    end
end
