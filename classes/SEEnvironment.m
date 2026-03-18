classdef SEEnvironment < SEBase
    properties
        boundary = [0 0 6 9]; % [x, y, width, height]
        speed = 2;
        direction = 0;
        mode = "Constant"; 
        noiseLevel = 0.2; % How chaotic the stochastic mode is        
    end

    properties(SetAccess=protected)
        isEnabled = true;
    end

    methods
        function obj = SEEnvironment(bounds, spd, dir, md)
            if nargin > 0 && ~isempty(bounds), obj.boundary = bounds; end
            if nargin > 1, obj.speed = spd; end
            if nargin > 2, obj.direction = dir; end
            if nargin > 3, obj.mode = strtrim(string(md)); end
        end

        function setEnabled(obj, val)
            obj.isEnabled = val;
        end

        function setBoundaryBox(obj, val)
            obj.boundary = val;
        end

        function setSpeed(obj, val)
            obj.speed = val;
        end
        function setDirection(obj, val)
            obj.direction = val;
        end

        function setHeading(obj, val)
            obj.setDirection(val);
        end

        function setMode(obj, val)
            obj.mode = val;
        end
        function setNoiseLevel(obj, val)
            obj.noiseLevel = val;
        end

        % Alias for getForceAtPosition.
        % Can remove once SE4003 WI 26 completes.
        function F = forceAt(obj, varargin)
            F = obj.getForceAtPosition(varargin{:});
        end

        function F = getForceAtPosition(obj, position)
            F = [0 0 0];
            if obj.isEnabled
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

        function spec = getCompassSpec(obj)
            % Returns a compact drawing spec for a fixed-size compass/vector overlay.
            % This stays UI-agnostic: it only returns numbers/labels/state.

            spec = struct();
            spec.isVisible = obj.isEnabled;

            % Fixed overlay placement and size
            spec.anchorX = 5.25;
            spec.anchorY = 1.25;
            spec.radius  = 0.5;

            % Compass ring
            theta = linspace(0, 2*pi, 100);
            spec.ringX = spec.anchorX + spec.radius * cos(theta);
            spec.ringY = spec.anchorY + spec.radius * sin(theta);

            % Cardinal labels
            spec.labels = {
                'N', spec.anchorX,                  spec.anchorY + spec.radius + 0.2;
                'S', spec.anchorX,                  spec.anchorY - spec.radius - 0.2;
                'E', spec.anchorX + spec.radius + 0.2, spec.anchorY;
                'W', spec.anchorX - spec.radius - 0.2, spec.anchorY
                };

            % Fixed-length display arrow based on direction only
            spec.U = spec.radius * cosd(obj.direction);
            spec.V = spec.radius * sind(obj.direction);

            % Optional metadata if you want to show text later
            spec.speed = obj.speed;
            spec.direction = obj.direction;
            spec.mode = obj.mode;
        end

        function [passed, report] = verifyPhysics(obj)
            % Verification method for the Ocean extension
            passed = true;
            report = "Ocean physics verified: Gradient scaling operational.";
            
            % Logic check: In Gradient mode, force at bottom boundary must be zero
            testPos = [obj.boundary(1), obj.boundary(2), 0];
            F = obj.forceAt(testPos);
            if any(F ~= 0)
                passed = false;
                report = "Physics Error: Non-zero force detected at bottom boundary.";
            end
        end 
    end
end