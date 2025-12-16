function plotHeatKernel(tau, lambda)
% plotHeatKernel  Visualize the heat kernel using fplot
%
%   plotHeatKernel(tau)
%       Plots g(x) = exp(-tau * x) using fplot over its default interval.
%
%   plotHeatKernel(tau, lambda)
%       Plots g(lambda) = exp(-tau * lambda) using fplot over the
%       eigenvalue range [min(lambda), max(lambda)].
%
% INPUTS
%   tau     : Diffusion time / smoothing scale (scalar, > 0)
%   lambda  : (optional) Vector of Laplacian eigenvalues
%
% NOTES
%   - This function is intended for spectral kernel inspection
%   - No assumptions are made about mesh structure
%   - fplot is used in all cases (adaptive sampling)
%
% EXAMPLES
%   plotHeatKernel(0.02)
%   plotHeatKernel(0.02, fs6.Lambda.lambda)

arguments
    tau (1,1) double {mustBePositive}
    lambda (:,1) double {mustBeNonnegative} = []
end

figure('Color','w');
hold on;

% --------------------------------------------------
% Kernel definition
% --------------------------------------------------
g = @(x) exp(-tau .* x);

% --------------------------------------------------
% Plot using default or lambda-based interval
% --------------------------------------------------
if isempty(lambda)
    % Default fplot domain
    fplot(g, 'LineWidth', 2);
    xLabelStr = 'x (spectral coordinate)';
    xlimMode  = 'auto';
else
    % Eigenvalue-aware domain
    lamMin = min(lambda);
    lamMax = max(lambda);
    fplot(g, [lamMin lamMax], 'LineWidth', 2);
    xLabelStr = 'Eigenvalue  \lambda';
    xlim([lamMin lamMax]);
    xlimMode = 'manual';
end

% --------------------------------------------------
% Axes labeling
% --------------------------------------------------
xlabel(xLabelStr, 'FontSize', 12);
ylabel('g_\tau(\cdot)', 'FontSize', 12);
title('Heat Kernel (Spectral Domain)', 'FontSize', 14);

ylim([0 1.05]);
grid on;

% --------------------------------------------------
% Annotations
% --------------------------------------------------
annotation('textbox', ...
    [0.15 0.15 0.3 0.18], ...
    'String', { ...
        sprintf('\\tau = %.4g', tau), ...
        '', ...
        'g(\lambda) = exp(-\tau \lambda)', ...
        '', ...
        '\tau controls smoothing scale:', ...
        '• small \tau  → local smoothing', ...
        '• large \tau → global diffusion' ...
    }, ...
    'FitBoxToText','on', ...
    'BackgroundColor',[0.97 0.97 0.97]);

hold off;

end
