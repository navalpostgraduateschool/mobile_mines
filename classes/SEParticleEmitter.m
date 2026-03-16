classdef SEParticleEmitter < SEBase
    % SEParticleEmitter manages a transient visual particle effect for detonations.
    
    properties
        num_particles = 30; % Number of particles per explosion
        pos; % Nx3 matrix for [x, y, z] positions
        vel; % Nx3 matrix for [x, y, z] velocities
        lifespan;
        max_lifespan = 100; % <-- CHANGED: Increase this to 20 or 30 for a longer effect
        
        graphic_h; % Handle for the scatter plot
        axes_h;
        environment; % Placeholder for the future environment class
        
        is_active = false; % Tracks if the emitter is currently rendering
    end
    
    methods
        function obj = SEParticleEmitter(axes_handle, num_parts)
            % 1. Initialization
            if nargin > 1 && ~isempty(num_parts)
                % FIXED: Force scalar integer
                obj.num_particles = round(double(num_parts(1)));
            end
            
            % Preallocate the coordinate and physics arrays as Nx3 matrices
            obj.pos = nan(obj.num_particles, 3);
            obj.vel = nan(obj.num_particles, 3);
            obj.lifespan = zeros(obj.num_particles, 1);
            
            if nargin > 0 && ishandle(axes_handle)
                obj.initDisplay(axes_handle);
            end
        end
        
        function initDisplay(obj, axes_handle)
            obj.axes_h = axes_handle;
            
            % Use low-level 'line' instead of 'scatter' so it doesn't wipe the screen
            % Note: 'line' supports ZData out of the box
            obj.graphic_h = line('Parent', obj.axes_h, ...
                'XData', obj.pos(:, 1), ...
                'YData', obj.pos(:, 2), ...
                'ZData', obj.pos(:, 3), ...
                'LineStyle', 'none', ...
                'Marker', 'o', ...
                'MarkerFaceColor', [1 0.5 0], ...
                'MarkerEdgeColor', 'r', ...
                'MarkerSize', 5, ...
                'Visible', 'off');
        end
        
        function forceAtPos = getEnvironmentForce(obj, position)
            % Returns the environment forces applied at position.
            if ~isempty(obj.environment)
                % If the engine passed down the environment class, use it!
                forceAtPos = obj.environment.getForceAtPosition(position);
            else
                % Fallback if it hasn't been linked yet
                persistent warned
                if isempty(warned)
                    obj.logWarning('SEParticleEmitter.environment is empty. Falling back to default force.');
                    warned = true;
                end
                forceAtPos = [1, 1, 0]; 
            end
        end
        
        function trigger(obj, start_pos, initialVelocity)
            % 2. Interface to start the explosion
            obj.is_active = true;
            
            % Ensure start_pos is a 1x3 vector (pad Z with 0 if needed)
            if length(start_pos) == 2
                start_pos = [start_pos(1), start_pos(2), 0];
            end
            
            % Recycle particles: reset to the epicenter
            obj.pos = repmat(start_pos, obj.num_particles, 1);
            obj.lifespan(:) = obj.max_lifespan;
            
            % CHANGED: Lowered the base radial speed to tighten the 3D explosion radius
            base_speed = 1.0 + rand(obj.num_particles, 1) * 2.0;
            
            % Generate angles in a full 360-degree circle (XY Plane)
            angles = rand(obj.num_particles, 1) * 2 * pi;
            
            % Calculate base outward velocities in 3D
            obj.vel(:, 1) = cos(angles) .* base_speed;
            obj.vel(:, 2) = sin(angles) .* base_speed;
            obj.vel(:, 3) = (rand(obj.num_particles, 1) - 0.5) .* base_speed; % Slight 3D spray
            
            % Apply the momentum effect based on the incoming velocity
            if nargin >= 3 && ~isempty(initialVelocity)
                % Pad initialVelocity to 1x3 if needed
                if length(initialVelocity) == 2
                    initialVelocity = [initialVelocity(1), initialVelocity(2), 0];
                end
                
                % Combine the circular explosion with the directional momentum
                obj.vel(:, 1) = obj.vel(:, 1) + (initialVelocity(1) * 2.0);
                obj.vel(:, 2) = obj.vel(:, 2) + (initialVelocity(2) * 2.0);
                obj.vel(:, 3) = obj.vel(:, 3) + (initialVelocity(3) * 2.0);
            end
            
            % Show the graphics
            set(obj.graphic_h, 'Visible', 'on');
            obj.updateDisplay();
        end
        
        function update(obj, dt)
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
            
            % Query the environment force at the explosion epicenter
            first_alive_idx = find(alive, 1);
            envForce = obj.getEnvironmentForce(obj.pos(first_alive_idx, :));
            
            % Apply environmental forces to velocities over time (dt)
            obj.vel(alive, 1) = obj.vel(alive, 1) + (envForce(1) * dt);
            obj.vel(alive, 2) = obj.vel(alive, 2) + (envForce(2) * dt);
            obj.vel(alive, 3) = obj.vel(alive, 3) + (envForce(3) * dt);
            
            % Heavily damp updates in the z-plane below 0 (i.e. sea level)
            below_sea = alive & (obj.pos(:, 3) < 0);
            obj.vel(below_sea, 3) = obj.vel(below_sea, 3) * 0.1;
            
            % Apply velocities to positions over time (dt)
            obj.pos(alive, :) = obj.pos(alive, :) + (obj.vel(alive, :) * dt);
            
            % Decay lifespan
            obj.lifespan(alive) = obj.lifespan(alive) - 1;
            
            obj.updateDisplay();
        end
        
        function updateDisplay(obj)
            if ishandle(obj.graphic_h) && obj.is_active
                alive = obj.lifespan > 0;
                % Update scatter plot with only living particles
                set(obj.graphic_h, ...
                    'XData', obj.pos(alive, 1), ...
                    'YData', obj.pos(alive, 2), ...
                    'ZData', obj.pos(alive, 3));
            end
        end
        
        function [pass, details] = verify(obj)
            % 4. Verification Contract implementation
            obj.logStatus('Executing SEParticleEmitter verification...');
            pass = true;
            details = struct('className', class(obj), 'pass', true, 'summary', '', 'metrics', struct());
            
            % Test 1: Instantiation logic (Check Nx3 Matrix)
            if isempty(obj.pos) || size(obj.pos, 1) ~= obj.num_particles || size(obj.pos, 2) ~= 3
                pass = false;
                details.summary = 'Failed to initialize 3D particle arrays.';
                obj.logError(details.summary);
                return;
            end
            
            % Test 2: Trigger state and lifespan application
            obj.trigger([5, 5, 0], [1, 0, 0]);
            if ~obj.is_active || obj.lifespan(1) ~= obj.max_lifespan
                pass = false;
                details.summary = 'Trigger method failed to set active state or lifespans.';
                obj.logError(details.summary);
                return;
            end
            
            % Test 3: Environmental hook and decay update with dt
            old_x = obj.pos(1, 1);
            obj.update(0.1); % Pass a dummy dt of 0.1 seconds
            if obj.pos(1, 1) == old_x || obj.lifespan(1) == obj.max_lifespan
                pass = false;
                details.summary = 'Update method failed to alter positions using dt or decay lifespan.';
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