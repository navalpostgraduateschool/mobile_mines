classdef SEStaticMine < SEMine
    properties
        dx = 0;
        dy = 0;
        dz = 0;
        mass = 1;
        vel = [0,0,0];
        
    end
    
    methods
        function obj = SEStaticMine(varargin)
            % pass everything to the base class
            obj@SEMine(varargin{:});
            obj.marker = 'o';
        end
  
        function update(obj, dt, force, ships)
            % SMCC TODO: update position based on force and time step.   

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

            if obj.isAlive()
                % 1. ENVIRONMENT IMPACT (Continuous Drift)
                % 'force' is the [u, v, 0] vector from SEEnvironment
                % We multiply by dt to ensure drift is proportional to time
                obj.pos_x = obj.pos_x + force(1) * dt;
                obj.pos_y = obj.pos_y + force(2) * dt;
            end
            
            
            f = zeros(1,3);
            f(1:min(3,numel(force))) = force(:).';

            a = f / obj.mass;
            obj.vel = obj.vel + a*dt;

            newPos = [obj.pos_x obj.pos_y obj.pos_z] + obj.vel*dt;

            obj.pos_x = newPos(1);
            obj.pos_y = newPos(2);
            obj.pos_z = newPos(3);

            % Update position based on force and time step. This is a simple physics update: F = m*a => a = F/m, and then we update velocity and position.
            update@SEMine(obj, dt, force, ships);
        end

    end
end
