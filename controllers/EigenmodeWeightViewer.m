classdef EigenmodeWeightViewer < matlab.ui.componentcontainer.ComponentContainer
    % EigenmodeWeightViewer
    %
    % Visualizes how a spectral kernel weights Laplacian eigenvalues:
    %
    %   w_k = g(lambda_k)
    %
    % This component:
    %   - listens to a KernelModel
    %   - plots kernel weights vs spectral coordinate
    %   - does NOT involve eigenfunctions
    %
    % ============================================================

    % ============================================================
    % Public API
    % ============================================================
    properties (SetObservable)
        Model KernelModel
    end

    % ============================================================
    % Visualization Options
    % ============================================================
    properties
        AxisCoordinates char {mustBeMember(AxisCoordinates, ...
            {'Eigenvalue','Wavenumber','Wavelength'})} = 'Eigenvalue'

        AxisScaleMode char {mustBeMember(AxisScaleMode, ...
            {'linear','log','power'})} = 'linear'

        PowerExponent (1,1) double = 1.0

        ShowRug   (1,1) logical = true
        ShowTitle (1,1) logical = false

        SpatialUnit char = 'mm'
    end

    % ============================================================
    % UI Components
    % ============================================================
    properties (Access = private, Transient, NonCopyable)
        GridLayout    matlab.ui.container.GridLayout
        ControlLayout matlab.ui.container.GridLayout
        UIAxes        matlab.ui.control.UIAxes

        AxisCoordDropDown matlab.ui.control.DropDown
        AxisScaleDropDown matlab.ui.control.DropDown
    end

    % ============================================================
    % Listeners
    % ============================================================
    properties (Access = private)
        ModelListeners event.listener = event.listener.empty
    end

    % ============================================================
    % Lifecycle
    % ============================================================
    methods (Access = protected)

        function setup(comp)

            % Root layout
            comp.GridLayout = uigridlayout(comp);
            comp.GridLayout.RowHeight   = {'fit','1x'};
            comp.GridLayout.ColumnWidth = {'1x'};

            % --------------------------------------------------
            % Control bar
            % --------------------------------------------------
            comp.ControlLayout = uigridlayout(comp.GridLayout);
            comp.ControlLayout.Layout.Row = 1;
            comp.ControlLayout.RowHeight   = {'fit'};
            comp.ControlLayout.ColumnWidth = {'fit','fit','1x'};
            comp.ControlLayout.Padding = [6 4 6 4];

            % Axis coordinates selector
            comp.AxisCoordDropDown = uidropdown(comp.ControlLayout);
            comp.AxisCoordDropDown.Items = ...
                {'Eigenvalue','Wavenumber','Wavelength'};
            comp.AxisCoordDropDown.Layout.Column = 1;
            comp.AxisCoordDropDown.ValueChangedFcn = ...
                @(~,~)comp.onControlsChanged();

            % Axis scale selector
            comp.AxisScaleDropDown = uidropdown(comp.ControlLayout);
            comp.AxisScaleDropDown.Items = {'linear','log','power'};
            comp.AxisScaleDropDown.Layout.Column = 2;
            comp.AxisScaleDropDown.ValueChangedFcn = ...
                @(~,~)comp.onControlsChanged();

            % --------------------------------------------------
            % Axes
            % --------------------------------------------------
            comp.UIAxes = uiaxes(comp.GridLayout);
            comp.UIAxes.Layout.Row = 2;
            comp.UIAxes.YAxisLocation = 'right';

            comp.UIAxes.Box = 'on';
            comp.UIAxes.XGrid = 'off';
            comp.UIAxes.YGrid = 'off';
            comp.UIAxes.TickDir = 'out';
        end

        function update(comp)

            if isempty(comp.Model) || isempty(comp.Model.Axis)
                cla(comp.UIAxes);
                return;
            end

            lambda = comp.Model.Axis(:);
            w      = comp.Model.KernelFunction(lambda);

            % --------------------------------------------------
            % Spectral coordinate transform
            % --------------------------------------------------
            switch comp.AxisCoordinates
                case 'Eigenvalue'
                    coord = lambda;
                    coordLabel = '\lambda';

                case 'Wavenumber'
                    coord = sqrt(lambda);
                    coordLabel = ['k (' comp.SpatialUnit '^{-1})'];

                case 'Wavelength'
                    coord = 2*pi ./ sqrt(lambda);
                    coordLabel = ['Wavelength (' comp.SpatialUnit ')'];
            end

            % --------------------------------------------------
            % Axis scaling
            % --------------------------------------------------
            switch comp.AxisScaleMode
                case 'linear'
                    x = coord;
                case 'log'
                    x = log10(coord);
                    coordLabel = ['log_{10}(' coordLabel ')'];
                case 'power'
                    x = coord .^ comp.PowerExponent;
                    coordLabel = [coordLabel '^{' num2str(comp.PowerExponent) '}'];
            end

            % --------------------------------------------------
            % Plot
            % --------------------------------------------------
            cla(comp.UIAxes);
            hold(comp.UIAxes,'on');

            plot(comp.UIAxes, x, w, 'o-', ...
                'LineWidth',1.5, 'MarkerSize',4);

            if comp.ShowRug
                plot(comp.UIAxes, x, zeros(size(x)), '|', ...
                    'Color',[0.4 0.4 0.4]);
            end

            hold(comp.UIAxes,'off');

            xlabel(comp.UIAxes, coordLabel);
            ylabel(comp.UIAxes, 'g(\lambda)');

            axis(comp.UIAxes,'tight');
            xlim(comp.UIAxes,'padded');
            ylim(comp.UIAxes,'padded');

            if comp.ShowTitle
                title(comp.UIAxes, ...
                    sprintf('Eigenmode Weights — %s', ...
                        comp.Model.KernelType), ...
                    'Interpreter','none');
            else
                title(comp.UIAxes,'');
            end
        end
    end

    % ============================================================
    % Model binding
    % ============================================================
    methods
        function set.Model(comp, model)

            delete(comp.ModelListeners);
            comp.ModelListeners = event.listener.empty;
            comp.Model = model;

            if isempty(model), return; end

            props = {'KernelFunction','Parameters','KernelType','Axis'};
            for i = 1:numel(props)
                comp.ModelListeners(end+1) = ...
                    addlistener(model, props{i}, 'PostSet', ...
                        @(~,~)comp.update());
            end

            comp.update();
        end
    end

    % ============================================================
    % UI callbacks
    % ============================================================
    methods (Access = private)
        function onControlsChanged(comp)
            comp.AxisCoordinates = comp.AxisCoordDropDown.Value;
            comp.AxisScaleMode   = comp.AxisScaleDropDown.Value;
            comp.update();
        end
    end
end
