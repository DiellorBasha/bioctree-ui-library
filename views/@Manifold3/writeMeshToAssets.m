% Assumes you already have:
% mesh.Vertices  (N x 3 double)
% mesh.Faces     (M x 3 int32 or double; MATLAB 1-based)

% 1) Target path (adjust to your repo location as needed)
outPath = fullfile(pwd, 'web', 'assets', 'fsaverage.json');

% If you're running this from outside the web folder, use an absolute repo path:
% outPath = fullfile("C:\CodingProjects\bioctree-ui-library\views\@Manifold3\web", ...
%                    "assets", "fsaverage.json");

% 2) Ensure output folder exists
outDir = fileparts(outPath);
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% 3) Build JSON-friendly struct
asset = struct();
asset.vertices = double(mesh.Vertices);   % keep as N x 3
asset.faces    = double(mesh.Faces);      % keep as M x 3, 1-based (do NOT subtract 1)

% Optional: add per-vertex colors (example: constant gray)
% asset.vertexColors = repmat([0.8 0.8 0.8], size(mesh.Vertices,1), 1);

% 4) Encode + write
jsonText = jsonencode(asset);

% jsonencode produces compact JSON; that's fine. If you want pretty printing:
% jsonText = prettyJson(jsonText); % (helper below)

fid = fopen(outPath, 'w');
assert(fid > 0, "Could not open file for writing: %s", outPath);
cleanup = onCleanup(@() fclose(fid));
fwrite(fid, jsonText, 'char');

fprintf("Wrote: %s\n", outPath);
fprintf("Vertices: %d | Faces: %d\n", size(mesh.Vertices,1), size(mesh.Faces,1));
