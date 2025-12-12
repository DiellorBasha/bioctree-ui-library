classdef ComponentLoader
    methods(Static)
        function path = resolve(componentName, fileName)
            % Returns absolute path to asset inside @component folder
            base = fileparts(mfilename('fullpath'));
            compDir = fullfile(base, "..", "controllers", "@" + componentName);

            path = fullfile(compDir, fileName);

            if ~isfile(path)
                error("ComponentLoader:FileNotFound", ...
                    "Asset %s not found in component %s", fileName, componentName);
            end
        end

        function html = inlineHTML(componentName)
            % Loads HTML file and inlines CSS + JS dependencies
            htmlPath = bct.ui.ComponentLoader.resolve(componentName, componentName + ".html");
            html = fileread(htmlPath);

            % Inline shared CSS
            sharedCSS = fileread(fullfile(fileparts(htmlPath), "..", "..", "lib", "shared.css"));
            html = strrep(html, "<link rel='stylesheet' href='shared.css'>", "<style>" + sharedCSS + "</style>");

            % Inline shared JS
            sharedJS = fileread(fullfile(fileparts(htmlPath), "..", "..", "lib", "shared.js"));
            html = strrep(html, "<script src='shared.js'></script>", "<script>" + sharedJS + "</script>");
        end
    end
end
