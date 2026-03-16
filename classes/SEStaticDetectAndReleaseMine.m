classdef SEStaticDetectAndReleaseMine < SEStaticTetheredMine

    properties
        surfaced = false
    end

    methods

        function obj = SEStaticDetectAndReleaseMine(pos0, anchor0, tetherLen0, detectRange, varargin)

            if nargin < 1 || isempty(pos0)
                pos0 = [0,0,-10];
            end

            if nargin < 2 || isempty(anchor0)
                anchor0 = pos0;
            end

            if nargin < 3 || isempty(tetherLen0)
                tetherLen0 = 2;
            end

            if nargin < 4 || isempty(detectRange)
                detectRange = 2;
            end

            obj@SEStaticTetheredMine(pos0, anchor0, tetherLen0, varargin{:});

            % Use inherited detection property from SEMine
            obj.detectRange = detectRange;
            obj.surfaced = false;
        end


        function riseToSurface(obj)
            obj.surfaced = true;
            obj.pos_z = 0;

            if numel(obj.vel) >= 3
                obj.vel(3) = 0;
            end
        end


        function update(obj, dt, force, ships)

            if nargin < 4
                ships = [];
            end

            if nargin < 3 || isempty(force)
                force = [0,0,0];
            end

            if nargin < 2 || isempty(dt)
                dt = 1;
            end

            if ~obj.isAlive()
                return;
            end

            % If tether intact, check for ship detection in XY plane
            if obj.tethered && ~isempty(ships)

                if size(ships,2) < 2
                    error('ships must be Nx2 or Nx3 of [x,y(,z)] positions');
                end

                mineXY = [obj.pos_x, obj.pos_y];
                diffs = ships(:,1:2) - mineXY;
                d2 = sum(diffs.^2, 2);

                if any(d2 <= obj.detectRange^2)
                    obj.releaseTether();
                    obj.riseToSurface();
                end
            end

            % If still tethered, use parent tethered behavior
            if obj.tethered
                update@SEStaticTetheredMine(obj, dt, force, ships);
                return;
            end

            % After release, drift freely under environmental force
            f = zeros(1,3);
            f(1:min(3,numel(force))) = force(:).';

            a = f / obj.mass;
            obj.vel = obj.vel + a * dt;

            newPos = [obj.pos_x, obj.pos_y, obj.pos_z] + obj.vel * dt;

            % Keep mine at the surface after release
            if newPos(3) < 0
                newPos(3) = 0;
                obj.vel(3) = 0;
            end

            obj.pos_x = newPos(1);
            obj.pos_y = newPos(2);
            obj.pos_z = newPos(3);

            obj.updateDisplay();
        end


        function [pass, details] = verify(obj)

            pass = true;
            details = struct();
            details.className = class(obj);
            details.timestamp = datestr(now);
            details.metrics = struct();
            details.notes = '';

            obj.logStatus('[VERIFY] Starting detect-and-release verification');

            % Reset to known state
            obj.tethered = true;
            obj.surfaced = false;
            obj.vel = [0 0 0];
            obj.pos_x = 0;
            obj.pos_y = 0;
            obj.pos_z = -10;
            obj.anchor = [0 0 -10];

            % Test 1: ship far away -> should remain tethered
            ships = [100 100 0];
            obj.update(0.1, [0 0 0], ships);

            details.metrics.remainedTetheredWithFarShip = obj.tethered;

            if obj.tethered
                obj.logStatus('[PASS] Mine remained tethered when ship was far away');
            else
                obj.logError('[FAIL] Mine released too early');
                pass = false;
            end

            % Test 2: ship inside detect range -> should release
            ships = [obj.pos_x + 1, obj.pos_y, 0];
            obj.update(0.1, [0 0 0], ships);

            details.metrics.releasedWhenShipDetected = ~obj.tethered;
            details.metrics.surfacedAfterRelease = obj.surfaced;

            if ~obj.tethered
                obj.logStatus('[PASS] Mine released tether when ship entered detect range');
            else
                obj.logError('[FAIL] Mine did not release when ship entered detect range');
                pass = false;
            end

            if obj.surfaced
                obj.logStatus('[PASS] Mine transitioned to surfaced state');
            else
                obj.logError('[FAIL] Mine did not transition to surfaced state');
                pass = false;
            end

            if pass
                details.summary = 'Detect-and-release verification passed';
                obj.logStatus('[VERIFY] Detect-and-release verification passed');
            else
                details.summary = 'Detect-and-release verification failed';
                obj.logError('[VERIFY] Detect-and-release verification failed');
            end

            details.pass = pass;
        end
    end
end