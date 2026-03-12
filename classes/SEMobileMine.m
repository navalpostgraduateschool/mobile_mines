classdef SEMobileMine < SEMine
    properties
        dx = 0.5;
        dy = 0.5;
        dz = 0;
    end
    
    methods
        function obj = SEMobileMine(varargin)
            % pass everything to the base class
            obj@SEMine(varargin{:});
            obj.marker = 'pentagram';
        end


        function updatePosition(obj, dt, force)
            % 1. NORMAL MOTION (10% chance random jitter)
            if rand(1) <= 0.1
                obj.pos_x = obj.pos_x + (rand(1) - 0.5) * obj.dx;
                obj.pos_y = obj.pos_y + (rand(1) - 0.5) * obj.dy;
            end
            
            % 2. ENVIRONMENT IMPACT (Continuous Drift)
            % 'force' is the [u, v, 0] vector from SEEnvironment
            % We multiply by dt to ensure drift is proportional to time
            obj.pos_x = obj.pos_x + force(1) * dt;
            obj.pos_y = obj.pos_y + force(2) * dt;
        end
        
        function update(obj, dt, force, ships)
            if obj.isAlive()
                obj.updatePosition(dt, force);
                update@SEMine(obj, dt, force, ships);
            end
        end
    end
end
