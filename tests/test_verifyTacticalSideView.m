%% test_tactical_view_display.m
% Smoke test for:
% 1) Tactical View Display creation
% 2) View Change button behavior
%
% Expected output:
%   Testing Display: PASS/FAIL
%   Testing View Change: PASS/FAIL

clear; clc;

app = [];
displayPass = false;
viewPass = false;

try
    % Create the app
    % app = mobilemineSim_sp_2025_TacticalSideView();
    app = mobilemineSim();
    drawnow;
    pause(0.5);

    %% -------------------------------
    % Test 1: Tactical View Display
    %% -------------------------------
    fprintf('Testing Display ... ');

    try
        % Checking:
        % - SideViewAxes exists
        % - it is a valid graphics object
        % - it has something drawn in it after startup
        if ~isempty(app.SideViewAxes) && ...
           isvalid(app.SideViewAxes) && ...
           isgraphics(app.SideViewAxes)

            drawnow;
            pause(0.25);

            % A renderer-created display should leave children
            if ~isempty(app.SideViewAxes.Children)
                displayPass = true;
            end
        end

        if displayPass
            fprintf('PASS\n');
        else
            fprintf('FAIL\n');
        end

    catch ME
        fprintf('FAIL\n');
        fprintf('  Display test error: %s\n', ME.message);
    end

    %% -------------------------------
    % Test 2: View Change button
    %% -------------------------------
    fprintf('Testing View Change ... ');

    try
        drawnow;
        pause(0.25);

        % Capture current view
        oldView = view(app.SideViewAxes);

        % Trigger the button callback exactly as the UI would
        cb = app.ViewChangeButton.ButtonPushedFcn;

        if isa(cb, 'function_handle')
            cb(app.ViewChangeButton, []);
        else
            error('ViewChangeButton has no valid callback assigned.');
        end

        drawnow;
        pause(0.25);

        % Capture updated camera/view
        newView = view(app.SideViewAxes);

        % PASS if the view actually changed
        if ~isequal(oldView, newView)
            viewPass = true;
        end

        if viewPass
            fprintf('PASS\n');
        else
            fprintf('FAIL\n');
        end

    catch ME
        fprintf('FAIL\n');
        fprintf('  View Change test error: %s\n', ME.message);
    end

catch ME
    fprintf('App launch failed: %s\n', ME.message);
end

%% Summary
fprintf('\n----- Test Summary -----\n');
fprintf('Testing Display: %s\n', passfail(displayPass));
fprintf('Testing View Change: %s\n', passfail(viewPass));

%% Cleanup
try
    if ~isempty(app) && isvalid(app)
      %   delete(app);
    end
catch
end

%% Local helper
function out = passfail(tf)
if tf
    out = 'PASS';
else
    out = 'FAIL';
end
end