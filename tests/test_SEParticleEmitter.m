% test_SEParticleEmitter.m
% Standalone test script with an interactive GUI for 3D verification

clear; close all; clc;

% 1. Setup the testing environment figure
fig = figure('Name', 'Particle Emitter 3D Verification Sandbox', 'Color', 'w', 'Position', [100, 100, 600, 500]);

% Create the axes for the visual demo (Added ZLim for 3D)
ax = axes('Parent', fig, 'Position', [0.1, 0.25, 0.8, 0.65], 'XLim', [0 10], 'YLim', [0 10], 'ZLim', [-2 5]);

% CHANGED: Force the plot into a 3D isometric view so we can see the Z-axis
view(ax, 3); 
hold(ax, 'on');
grid(ax, 'on');
title(ax, 'SEParticleEmitter 3D Test Sandbox');

% 2. Add the Verify Button
btn_verify = uicontrol('Parent', fig, ...
    'Style', 'pushbutton', ...
    'String', 'Run Verification & Demo', ...
    'Position', [200, 30, 200, 50], ...
    'FontSize', 12, ...
    'FontWeight', 'bold', ...
    'Callback', @runVerificationCallback);

% Save the axes handle
setappdata(fig, 'TestAxes', ax);

% -------------------------------------------------------------------------
% Callback Function
% -------------------------------------------------------------------------
function runVerificationCallback(src, ~)
    fig = src.Parent;
    ax = getappdata(fig, 'TestAxes');
    cla(ax);
    
    fprintf('--- Starting 3D Verification Contract ---\n');
    emitter = SEParticleEmitter(ax, 50);
    
    % Execute the internal verification contract
    [pass, details] = emitter.verify();
    
    if pass
        fprintf('Verification PASSED.\n');
        uiwait(msgbox('SEParticleEmitter Verification PASSED. Click OK to see the 3D visual demonstration.', 'Verification Success', 'help'));
        
        fprintf('Running 3D visual demonstration...\n');
        
        % CHANGED: Removed the old setEnvironmentalForce call.
        % CHANGED: Trigger with 1x3 vectors [x, y, z]
        emitter.trigger([5, 5, 0], [2, 2, 0]); 
        
        % CHANGED: Animation loop now uses a delta-time (dt) of 0.1
        dt = 0.1;
        while emitter.is_active
            emitter.update(dt);
            pause(0.05); % Visual frame delay so you can watch it happen
        end
        fprintf('Demonstration complete.\n\n');
        
    else
        fprintf('Verification FAILED: %s\n', details.summary);
        errordlg(sprintf('Verification FAILED:\n%s', details.summary), 'Verification Failed');
    end
    
    delete(emitter);
end