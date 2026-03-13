classdef SEEnvironment < SEBase
    % Dummy environment class waiting for the Environment Team
    
    properties
        % Hardcoded 3D ocean current [x, y, z] for the entire map
        globalForce = [-2.0, 0, 0]; 
    end
    
    methods
        function obj = SEEnvironment()
            % Constructor
        end
        
        function forceAtPos = getForceAtPosition(obj, position)
            % Ignore the position and just return the constant global force
            forceAtPos = obj.globalForce;
        end
        
        function [pass, details] = verify(obj)
            % Standard verification contract
            pass = true;
            details = struct('className', class(obj), 'pass', true, 'summary', 'Dummy environment verified.', 'metrics', struct());
            obj.logStatus(details.summary);
        end
    end
end