classdef SEParticleEmitter < SEBase
    % SEParticleEmitter manages a transient visual particle effect for detonations.
    
    properties
        num_particles = 30; % Number of particles per explosion
        pos_x;
        pos_y;
        vel_x;
        vel_y;
        lifespan;
        max_lifespan = 6; % How many frames the explosion lasts
        
        graphic_h; % Handle for the scatter plot
        axes_h;
        env_force = [0, 0]; % [dx, dy] Hook for external ocean currents
        
        is_active = false; % Tracks if the emitter is currently rendering
    end
    
    methods
        function obj = SEParticleEmitter(axes_handle, num_parts)
            % 1. Initialization
            if nargin > 1 && ~isempty(num_parts)
                obj.num_particles = num_parts;
            end
            
            % Preallocate the coordinate and physics arrays
            obj.pos_x = nan(obj.num_particles, 1);
            obj.pos_y = nan(obj.num_particles, 1);
            obj.vel_x = nan(obj.num_particles, 1);
            obj.vel_y = nan(obj.num_particles, 1);
            obj.lifespan = zeros(obj.num_particles, 1);
            
            if nargin > 0 && ishandle(axes_handle)
                obj.initDisplay(axes_handle);
            end
        end
        
        function initDisplay(obj, axes_handle)
            obj.axes_h = axes_handle;
            
            % Use low-level 'line' instead of 'scatter' so it doesn't wipe the screen
            obj.graphic_h = line('Parent', obj.axes_h, ...
                'XData', obj.pos_x, ...
                'YData', obj.pos_y, ...
                'LineStyle', 'none', ...
                'Marker', 'o', ...
                'MarkerFaceColor', [1 0.5 0], ...
                'MarkerEdgeColor', 'r', ...
                'MarkerSize', 5, ...
                'Visible', 'off');
        end
        
        function setEnvironmentalForce(obj, forceVector)
            % Hook for external environment forces (e.g., ocean current)
            if numel(forceVector) == 2
                obj.env_force = forceVector;
            end
        end
        
        function trigger(obj, start_x, start_y, initialVelocity)
            % 2. Interface to start the explosion
            obj.is_active = true;
            
            % Recycle particles: reset to the epicenter
            obj.pos_x(:) = start_x;
            obj.pos_y(:) = start_y;
            obj.lifespan(:) = obj.max_lifespan;
            
            % Base radial speed for the circular explosion
            base_speed = 0.02 + rand(obj.num_particles, 1) * 0.05;
            
            % Generate angles in a full 360-degree circle
            angles = rand(obj.num_particles, 1) * 2 * pi;
            
            % Calculate base outward (circular) velocities
            vel_x_radial = cos(angles) .* base_speed;
            vel_y_radial = sin(angles) .* base_speed;
            
            % Apply the "wind" or momentum effect based on the incoming velocity
            if nargin > 3 && ~isempty(initialVelocity)
                % Scale down the incoming velocity to use as a drift push
                % (Adjust the 0.03 multiplier to make the wind stronger or weaker)
                wind_x = initialVelocity(1) * 0.03; 
                wind_y = initialVelocity(2) * 0.03;
                
                % Combine the circular explosion with the directional wind
                obj.vel_x = vel_x_radial + wind_x;
                obj.vel_y = vel_y_radial + wind_y;
            else
                % Perfect circle if no velocity is provided
                obj.vel_x = vel_x_radial;
                obj.vel_y = vel_y_radial;
            end
            
            % Show the graphics
            set(obj.graphic_h, 'Visible', 'on');
            obj.updateDisplay();
        end
        
        function update(obj)
            % 3. Lifecycle Update
            if ~obj.is_active
                return;
            end
            
            % Identify which particles are still "alive"
            alive = obj.lifespan > 0;
            
            if ~any(alive)
                % If all particles are dead, hide the graphic and sleep
                obj.is_active = false;
                set(obj.graphic_h, 'Visible', 'off');
                return;
            end
            
            % Apply environmental forces (currents) to velocities
            obj.vel_x(alive) = obj.vel_x(alive) + obj.env_force(1);
            obj.vel_y(alive) = obj.vel_y(alive) + obj.env_force(2);
            
            % Apply velocities to positions
            obj.pos_x(alive) = obj.pos_x(alive) + obj.vel_x(alive);
            obj.pos_y(alive) = obj.pos_y(alive) + obj.vel_y(alive);
            
            % Decay lifespan
            obj.lifespan(alive) = obj.lifespan(alive) - 1;
            
            obj.updateDisplay();
        end
        
        function updateDisplay(obj)
            if ishandle(obj.graphic_h) && obj.is_active
                alive = obj.lifespan > 0;
                % Update scatter plot with only living particles
                set(obj.graphic_h, 'XData', obj.pos_x(alive), 'YData', obj.pos_y(alive));
            end
        end
        
        function [pass, details] = verify(obj)
            % 4. Verification Contract implementation
            obj.logStatus('Executing SEParticleEmitter verification...');
            pass = true;
            details = struct('className', class(obj), 'pass', true, 'summary', '', 'metrics', struct());
            
            % Test 1: Instantiation logic
            if isempty(obj.pos_x) || length(obj.pos_x) ~= obj.num_particles
                pass = false;
                details.summary = 'Failed to initialize particle arrays.';
                obj.logError(details.summary);
                return;
            end
            
            % Test 2: Trigger state and lifespan application
            obj.trigger(5, 5, [1, 0]);
            if ~obj.is_active || obj.lifespan(1) ~= obj.max_lifespan
                pass = false;
                details.summary = 'Trigger method failed to set active state or lifespans.';
                obj.logError(details.summary);
                return;
            end
            
            % Test 3: Environmental hook and decay update
            obj.setEnvironmentalForce([0.1, -0.1]);
            old_x = obj.pos_x(1);
            obj.update();
            if obj.pos_x(1) == old_x || obj.lifespan(1) == obj.max_lifespan
                pass = false;
                details.summary = 'Update method failed to alter positions or decay lifespan.';
                obj.logError(details.summary);
                return;
            end
            
            details.summary = 'SEParticleEmitter verification passed.';
            obj.logStatus(details.summary);
        end
        
        function delete(obj)
            % Clean up graphics when object is destroyed
            if ishandle(obj.graphic_h)
                delete(obj.graphic_h);
            end
        end
    end
end