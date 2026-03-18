classdef SEStaticTetheredMine < SEStaticMine

    properties
        anchor = [0,0,-10]
        tetherLength = 2
        tethered = true
        
    end

    methods

        function obj = SEStaticTetheredMine(pos0, anchor0, tetherLen0, varargin)

            if nargin < 1 || isempty(pos0)
                pos0 = [0,0, -10];
            end

            if nargin < 2 || isempty(anchor0)
                anchor0 = pos0;
            end

            if nargin < 3 || isempty(tetherLen0)
                tetherLen0 = 2;
            end

            x = pos0(1);
            y = pos0(2);

            if numel(pos0) >= 3
                z = pos0(3);
            else
                z = -10;
            end

            obj@SEStaticMine(x,y,varargin{:});       
            obj.pos_z = z;

            obj.anchor = anchor0(:).';
            obj.tetherLength = tetherLen0;
            obj.tethered = true;
            obj.vel = [0,0,0];

        end

        % Overridden setPosition method to update the anchor
        function didSet = setPosition(obj, x, y, z)
            % Set the mine's position by calling the superclass method
            if nargin < 4
                didSet = setPosition@SEMine(obj, x, y);
            else
                didSet = setPosition@SEMine(obj, x, y, z);
            end
            
            % After setting the position, update the anchor to this position.
            if didSet
                obj.anchor = obj.getPosition();
            end
        end

        function releaseTether(obj)

            if obj.tethered
                obj.tethered = false;
                obj.logStatus('Mine released from tether');
            end

        end



        function [pass, details] = verify(obj)

            pass = true;
            details = struct();
            details.className = class(obj);
            details.timestamp = datestr(now);
            details.metrics = struct();
            details.notes = '';

            obj.logStatus('[VERIFY] Starting tether verification');

            % Reset to known state
            obj.tethered = true;
            obj.vel = [0 0 0];
            obj.pos_x = 0;
            obj.pos_y = 0;
            obj.pos_z = -10;
            obj.anchor = [0 0 -10];
            obj.tetherLength = 2;

            for k = 1:30
                obj.update(0.1, [5 0 0], []);
            end

            dist = norm(obj.getPosition() - obj.anchor);
            details.metrics.distanceFromAnchor = dist;
            details.metrics.tetherLength = obj.tetherLength;

            if dist <= obj.tetherLength + 1e-6
                obj.logStatus('[PASS] Mine remained within tether length');
                details.summary = 'Tether verification passed';
            else
                obj.logError('[FAIL] Mine exceeded tether length');
                details.summary = 'Tether verification failed';
                pass = false;
            end

            details.pass = pass;
        end


        function update(obj, dt, force, ships)

            if nargin < 4
                ships = [];
            end

            if nargin < 3 || isempty(force)
                force = [0 0 0];
            end

            if nargin < 2 || isempty(dt)
                dt = 1;
            end

            if ~obj.isAlive()
                return
            end

            f = zeros(1,3);
            f(1:min(3,numel(force))) = force(:).';

            a = f / obj.mass;
            obj.vel = obj.vel + a*dt;

            newPos = [obj.pos_x obj.pos_y obj.pos_z] + obj.vel*dt;

            if obj.tethered

                tetherVec = newPos - obj.anchor;
                dist = norm(tetherVec);

                if dist > obj.tetherLength && dist > 0

                    tetherUnit = tetherVec / dist;

                    newPos = obj.anchor + tetherUnit * obj.tetherLength;

                    vRadial = dot(obj.vel,tetherUnit)*tetherUnit;
                    obj.vel = obj.vel - vRadial;

                end
            end

            obj.pos_x = newPos(1);
            obj.pos_y = newPos(2);
            obj.pos_z = newPos(3);

            % Corrected call to the grandparent's update method for display
            update@SEMine(obj,dt,force,ships);

        end

    end
end
