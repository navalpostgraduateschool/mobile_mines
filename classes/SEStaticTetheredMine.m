% Janene can you add the word "tethered" to the dropdown in the GUI? I did
% it on design view and it seemed to work
classdef SEStaticTetheredMine < SEStaticMine
    properties
        anchor
        tetherLength
        thethered = true
        emass = 1
        vel = [0,0,0]     % [vx,vy,vz]
    end

    methods
        function obj = SEStaticTetheredMine(pos0, anchor0, tetherLen0, varargin)
            % pos0: [x,y,z] or [x,y]
            if nargin < 1 || isempty(pos0), pos0 = [0,0,-10]; end
            if nargin < 2 || isempty(anchor0), anchor0 = pos0; end
            if nargin < 3 || isempty(tetherLen0), tetherLen0 = 5; end

            % call base with position x,y (base uses setPosition)
            if numel(pos0) >= 2
                x = pos0(1); y = pos0(2);
            else
                x = 0; y = 0;
            end
            if numel(pos0) >= 3
                z = pos0(3);
            else
                z = -10;
            end

            obj@SEStaticMine(x, y, varargin{:});
            obj.pos_z = z;

            obj.anchor = anchor0(:).';
            if numel(obj.anchor) == 2
                obj.anchor(3) = obj.pos_z;
            end
            obj.tetherLen = tetherLen0;
            obj.tethered = true;
        end

        function update(obj, dt, force, ships)
            % signature consistent with SEMine: update(obj, dt, force, ships)
            if nargin < 4, ships = []; end
            if nargin < 3 || isempty(force), force = [0,0,0]; end
            if nargin < 2 || isempty(dt), dt = 1; end

            % ensure 3-component force [Fx,Fy,Fz]
            f = zeros(1,3);
            f(1:min(3,numel(force))) = force(:).';

            % simple integrator: a = F/m; v += a*dt; pos += v*dt
            a = f / obj.mass;
            obj.vel = obj.vel + a * dt;

            % tentative new position (x,y,z)
            newpos = [obj.pos_x, obj.pos_y, obj.pos_z] + obj.vel * dt;

            if obj.tethered
                vvec = newpos - obj.anchor;
                dist = norm(vvec);
                if dist > obj.tetherLen && dist > 0
                    v_unit = vvec / dist;
                    % project onto tether sphere
                    newpos = obj.anchor + v_unit * obj.tetherLen;
                    % remove radial component of velocity
                    vr = dot(obj.vel, v_unit) * v_unit;
                    obj.vel = obj.vel - vr;
                end
            end

            % set position
            obj.pos_x = newpos(1);
            obj.pos_y = newpos(2);
            obj.pos_z = newpos(3);

            % update display (inherited SEMine.update normally handles this;
            % here we ensure display is updated)
            obj.updateDisplay();
        end
    end
end
