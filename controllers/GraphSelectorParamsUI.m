classdef GraphSelectorParamsUI < matlab.ui.componentcontainer.ComponentContainer
    % GraphSelectorParamsUI
    %
    % Concrete parameter UI for GraphBrush

    properties
        Selector GraphBrush
    end

    properties (Access = private, Transient, NonCopyable)
        Grid matlab.ui.container.GridLayout
        ModeDropDown matlab.ui.control.DropDown
        KHopsField matlab.ui.control.NumericEditField
        DistanceField matlab.ui.control.NumericEditField
    end

    %% =========================
    % Component lifecycle
    % =========================

    methods (Access = protected)

        function setup(comp)

            comp.Grid = uigridlayout(comp);
            comp.Grid.RowHeight    = {'fit','fit','fit','1x'};
            comp.Grid.ColumnWidth = {'fit','1x'};

            % Mode
            uilabel(comp.Grid, 'Text','Mode:', ...
                'Layout',[1 1]);

            comp.ModeDropDown = uidropdown(comp.Grid);
            comp.ModeDropDown.Items = {'KNeighbors','Distance','Component'};
            comp.ModeDropDown.Value = 'KNeighbors';
            comp.ModeDropDown.Layout.Row = 1;
            comp.ModeDropDown.Layout.Column = 2;
            comp.ModeDropDown.ValueChangedFcn = ...
                @(~,~)comp.onParamsChanged();

            % K hops
            uilabel(comp.Grid, 'Text','K Hops:', ...
                'Layout',[2 1]);

            comp.KHopsField = uieditfield(comp.Grid,'numeric');
            comp.KHopsField.Limits = [1 Inf];
            comp.KHopsField.Value = 5;
            comp.KHopsField.Layout.Row = 2;
            comp.KHopsField.Layout.Column = 2;
            comp.KHopsField.ValueChangedFcn = ...
                @(~,~)comp.onParamsChanged();

            % Distance
            uilabel(comp.Grid, 'Text','Distance:', ...
                'Layout',[3 1]);

            comp.DistanceField = uieditfield(comp.Grid,'numeric');
            comp.DistanceField.Limits = [0 Inf];
            comp.DistanceField.Value = 10;
            comp.DistanceField.Layout.Row = 3;
            comp.DistanceField.Layout.Column = 2;
            comp.DistanceField.ValueChangedFcn = ...
                @(~,~)comp.onParamsChanged();

            comp.updateEnableState();
        end

        function update(~)
            % REQUIRED by ComponentContainer
            % No dynamic redraw needed for this UI
        end
    end

    %% =========================
    % Internal logic
    % =========================

    methods (Access = private)

        function onParamsChanged(comp)

            if isempty(comp.Selector) || ~isvalid(comp.Selector)
                return;
            end

            comp.Selector.SelectionMode = comp.ModeDropDown.Value;

            switch comp.ModeDropDown.Value
                case 'KNeighbors'
                    comp.Selector.K = comp.KHopsField.Value;
                case 'Distance'
                    comp.Selector.DistanceThreshold = ...
                        comp.DistanceField.Value;
                case 'Component'
                    % no parameters
            end

            comp.updateEnableState();
        end

        function updateEnableState(comp)

            switch comp.ModeDropDown.Value
                case 'KNeighbors'
                    comp.KHopsField.Enable = 'on';
                    comp.DistanceField.Enable = 'off';
                case 'Distance'
                    comp.KHopsField.Enable = 'off';
                    comp.DistanceField.Enable = 'on';
                case 'Component'
                    comp.KHopsField.Enable = 'off';
                    comp.DistanceField.Enable = 'off';
            end
        end
    end
end
