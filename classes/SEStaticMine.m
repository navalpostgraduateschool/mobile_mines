classdef SEStaticMine < SEMine
    properties
        dx = 0;
        dy = 0;
        dz = 0;
    end
    
    methods
        function obj = SEStaticMine(varargin)
            % pass everything to the base class
            obj@SEMine(varargin{:});
            obj.marker = 'o';
        end

        function update(obj, dt, force, ships)
            if obj.isAlive()
                % 1. ENVIRONMENT IMPACT (Continuous Drift)
                % 'force' is the [u, v, 0] vector from SEEnvironment
                % We multiply by dt to ensure drift is proportional to time
                obj.pos_x = obj.pos_x + force(1) * dt;
                obj.pos_y = obj.pos_y + force(2) * dt;
            end
            
            % Update position based on force and time step.            
            update@SEMine(obj, dt, force, ships);
        end
    end
end