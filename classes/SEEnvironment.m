classdef SEEnvironment < handle
    properties
        boundary = [0 0 6 9]; % [x, y, width, height]
        speed = 0;
        direction = 0;
        mode = "Constant"; 
        noiseLevel = 0.2; % How chaotic the stochastic mode is
    end

    methods
        function obj = SEEnvironment(bounds, spd, dir, md)
            if nargin > 0 && ~isempty(bounds), obj.boundary = bounds; end
            if nargin > 1, obj.speed = spd; end
            if nargin > 2, obj.direction = dir; end
            if nargin > 3, obj.mode = strtrim(string(md)); end
        end

        function F = forceAt(obj, position)
            % 1. Calculate the base U and V vectors from Speed and Direction
            u = obj.speed * cosd(obj.direction)/10;
            v = obj.speed * sind(obj.direction)/10;

            % 2. Apply the specific environmental physics model
            switch lower(obj.mode)
                case "constant"
                    % Direct, uniform force across the entire map
                    F = [u, v, 0];

                case "stochastic"
                    % Add random Gaussian noise to simulate chaotic currents
                    noiseU = randn() * obj.noiseLevel * obj.speed;
                    noiseV = randn() * obj.noiseLevel * obj.speed;
                    F = [u + noiseU, v + noiseV, 0];

                case "gradient"
                    % Scale force based on Y position (0 at bottom, max at top)
                    ymin = obj.boundary(2);
                    ymax = obj.boundary(2) + obj.boundary(4);
                    yPos = position(2);

                    scale = (yPos - ymin) / (ymax - ymin);
                    scale = max(0, min(1, scale)); % Clamp between 0 and 1

                    F = [u * scale, v * scale, 0];

                otherwise
                    F = [u, v, 0];
            end
        end
    end
end