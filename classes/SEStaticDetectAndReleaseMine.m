
classdef SEStaticDetectAndReleaseMine < SEStaticTetheredMine
    properties
        detectionRange = 10   % detection radius in XY plane
        surfaced = false      % true if released and surfaced
    end

    methods
        function obj = SEStaticDetectAndReleaseMine(pos0, anchor0, tetherLen0, detectRange, varargin)
            if nargin < 1 || isempty(pos0), pos0 = [0,0,-10]; end
            if nargin < 2 || isempty(anchor0), anchor0 = pos0; end
            if nargin < 3 || isempty(tetherLen0), tetherLen0 = 2; end
            if nargin < 4 || isempty(detectRange), detectRange = 10; end

            obj@SEStaticTetheredMine(pos0, anchor0, tetherLen0, varargin{:});
            obj.detectionRange = detectRange;
            obj.surfaced = false;
        end

        function update(obj, dt, force, ships)
            if nargin < 4, ships = []; end
            if nargin < 3 || isempty(force), force = [0,0,0]; end
            if nargin < 2 || isempty(dt), dt = 1; end

            % If tether intact, check for ship detection (horizontal distance)
            if obj.tethered && ~isempty(ships)
                % ships expected Nx2 or Nx3, take first two cols
                if size(ships,2) < 2
                    error('ships must be Nx2 or Nx3 of [x,y(,z)] positions');
                end
                mineXY = [obj.pos_x, obj.pos_y];
                diffs = ships(:,1:2) - mineXY;
                d2 = sum(diffs.^2, 2);
                if any(d2 <= obj.detectionRange^2)
                    % break tether and float to surface
                    obj.tethered = false;
                    obj.surfaced = true;
                    obj.pos_z = 0;
                    obj.vel(3) = 0;
                end
            end

            % After release (or if already not tethered), behave as free static mine
            if ~obj.tethered
                % use same integration as tethered but without tether constraint
                f = zeros(1,3);
                f(1:min(3,numel(force))) = force(:).';
                a = f / obj.mass;
                obj.vel = obj.vel + a * dt;

                newpos = [obj.pos_x, obj.pos_y, obj.pos_z] + obj.vel * dt;

                % keep on/above surface
                if newpos(3) < 0
                    newpos(3) = 0;
                    obj.vel(3) = 0;
                end

                obj.pos_x = newpos(1);
                obj.pos_y = newpos(2);
                obj.pos_z = newpos(3);

                obj.updateDisplay();
            else
                % still tethered: reuse tethered update behaviour
                update@SEStaticTetheredMine(obj, dt, force, ships);
            end
        end
    end
end