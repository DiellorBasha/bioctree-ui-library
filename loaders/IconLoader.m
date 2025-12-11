classdef IconLoader
    %ICONLOADER Load Tabler SVG icons and return as strings
    %   Usage:
    %       svg = IconLoader.get("player-play");
    %       htmlComponent.Data.playIcon = svg;

    methods (Static)
        function svg = get(name)
            % Get folder of this class
            classFolder = fileparts(mfilename('fullpath'));
            iconFolder = fullfile(classFolder, "lib", "icons", "tabler");

            % Construct filename
            file = fullfile(iconFolder, name + ".svg");

            if ~isfile(file)
                error("IconLoader:IconMissing", ...
                    "SVG icon not found: %s", file);
            end

            % Read SVG file as text
            svg = fileread(file);
        end

        function svg = getInline(name, classes)
            % Load and inject Tailwind classes into SVG tag
            svg = IconLoader.get(name);

            % Insert class attribute directly after <svg ...
            svg = regexprep(svg, '<svg([^>]*)>', ...
                ['<svg$1 class="' classes '">'], 'once');
        end
    end
end
