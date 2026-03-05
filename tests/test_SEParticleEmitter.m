% test_SEParticleEmitter.m
% Standalone test script with an interactive GUI for verification

clear; close all; clc;

% 1. Setup the testing environment figure
fig = figure('Name', 'Particle Emitter Verification Sandbox', 'Color', 'w', 'Position', [100, 100, 600, 500]);

% Create the axes for the visual demo (leaving room at the bottom for the button)
ax = axes('Parent', fig, 'Position', [0.1, 0.25, 0.8, 0.65], 'XLim', [0 10], 'YLim', [0 10]);
hold(ax, 'on');
grid(ax, 'on');
title(ax, 'SEParticleEmitter Test Sandbox');

% 2. Add the Verify Button (Satisfies GUI Engineer Requirement)
btn_verify = uicontrol('Parent', fig, ...
    'Style', 'pushbutton', ...
    'String', 'Run Verification & Demo', ...
    'Position', [200, 30, 200, 50], ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'Callback', @runVerificationCallback); % Maps to the function below

% Save the axes handle in the figure's appdata so the callback can access it
setappdata(fig, 'TestAxes', ax);

% -------------------------------------------------------------------------
% Callback Function: Executes when the button is clicked
% -------------------------------------------------------------------------
function runVerificationCallback(src, ~)
    % Get the figure and axes
    fig = src.Parent;
    ax = getappdata(fig, 'TestAxes');
    
    % Clear previous particles if any
    cla(ax);
    
    fprintf('--- Starting Verification Contract ---\n');
    
    % Instantiate the emitter
    emitter = SEParticleEmitter(ax, 50);
    
    % Execute the verification contract
    [pass, details] = emitter.verify();
    
    % Provide GUI feedback based on the result
    if pass
        fprintf('Verification PASSED.\n');
        
        % CHANGED: Added 'uiwait' so the animation doesn't play until you click OK
        uiwait(msgbox('SEParticleEmitter Verification PASSED. Click OK to see the visual demonstration.', 'Verification Success', 'help'));
        
        % Run a quick visual demonstration to show the physics
        fprintf('Running visual demonstration...\n');
        
        % Set a strong current and a directional velocity for the demo
        emitter.setEnvironmentalForce([-0.05, -0.05]); 
        emitter.trigger(5, 5, [2, 2]); 
        
        while emitter.is_active
            emitter.update();
            % CHANGED: Increased the pause from 0.05 to 0.15 to dramatically slow down the visual frames
            pause(0.15); 
        end
        fprintf('Demonstration complete.\n\n');
        
    else
        fprintf('Verification FAILED: %s\n', details.summary);
        errordlg(sprintf('Verification FAILED:\n%s', details.summary), 'Verification Failed');
    end
    
    % Clean up the test object to prevent memory leaks
    delete(emitter);
end