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
logger = [];

try
    % 3-14-2026: Resolved changing project root, 
    % switching to temporary address, 
    % running the project path setup before launching app.
    thisFile = mfilename('fullpath');
    testsFolder = fileparts(thisFile);
    projectRoot = fileparts(testsFolder);

    oldFolder = pwd;
    cleanupObj = onCleanup(@() cd(oldFolder)); %#ok<NASGU>
    cd(projectRoot);

    mm_pathsetup();

    % 3-14-2026: Initialize a shared logger 
    logger = Logger.getInstance();
    logger.log('INFO', 'Starting verifyTacticalSideView smoke test.');

    % Create the app
    app = verifyTacticalSideView();
    drawnow;
    pause(0.5);

    % 3-14-2026: Disable UI/file logger outputs after launch so the test runs headless
    logger.setTextHandle([]);
    logger.setLogToFile(false);
    logger.log('INFO', 'App launched successfully.');

    %% -------------------------------
    % Test 1: Tactical View Display
    %% -------------------------------
    fprintf('Testing Display ... ');
    % 3-14-2026: Tried matching console status to the logger
    logger.log('INFO', 'Testing Display ...');

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

            % 3-14-2026: Use allchild so the test detects renderer content more reliably.
            if ~isempty(allchild(app.SideViewAxes))
                displayPass = true;
            end
        end

        if displayPass
            fprintf('PASS\n');
            % 3-14-2026: Log pass/fail result to match example
            logger.log('INFO', 'Testing Display: PASS');
        else
            fprintf('FAIL\n');
            % 3-14-2026: Log pass/fail result to match example
            logger.log('ERROR', 'Testing Display: FAIL');
        end

    catch ME
        fprintf('FAIL\n');
        fprintf('  Display test error: %s\n', ME.message);
        logger.log('ERROR', 'Display test error: %s', ME.message);
    end

    %% -------------------------------
    % Test 2: View Change dropdown
    %% -------------------------------
    fprintf('Testing View Change ... ');
    logger.log('INFO', 'Testing View Change ...');

    try
        drawnow;
        pause(0.25);

        % Capture current view
        oldView = view(app.SideViewAxes);

        % 3-14-2026: Captures camera state in the renderer changes camera properties
        oldCameraPosition = app.SideViewAxes.CameraPosition;
        oldCameraTarget   = app.SideViewAxes.CameraTarget;
        oldCameraUpVector = app.SideViewAxes.CameraUpVector;

        % 3-14-2026: Adjusted to use ViewDropDown.
        items = app.ViewDropDown.Items;
        currentValue = app.ViewDropDown.Value;

        % 3-14-2026: Normalized dropdown item indexing.
        if isstring(items)
            items = cellstr(items);
        end

        % 3-14-2026: Move to the next dropdown option.
        idx = find(strcmp(items, currentValue), 1);
        if isempty(idx)
            idx = 1;
        end
        newIdx = mod(idx, numel(items)) + 1;
        app.ViewDropDown.Value = items{newIdx};

        % 3-14-2026: Replicate dropdown callback from GUI.
        cb = app.ViewDropDown.ValueChangedFcn;

        if isa(cb, 'function_handle')
            cb(app.ViewDropDown, []);
        else
            error('ViewDropDown has no valid callback assigned.');
        end

        drawnow;
        pause(0.25);

        % Capture updated camera/view
        newView = view(app.SideViewAxes);
        % 3-14-2026: Capture updated camera state.
        newCameraPosition = app.SideViewAxes.CameraPosition;
        newCameraTarget   = app.SideViewAxes.CameraTarget;
        newCameraUpVector = app.SideViewAxes.CameraUpVector;

        % PASS if the view actually changed
        % 3-14-2026: Accept either a view() change or a camera-property change.
        if ~isequal(oldView, newView) || ...
           ~isequal(oldCameraPosition, newCameraPosition) || ...
           ~isequal(oldCameraTarget, newCameraTarget) || ...
           ~isequal(oldCameraUpVector, newCameraUpVector)
            viewPass = true;
        end

        if viewPass
            fprintf('PASS\n');
            % 3-14-2026: Log pass/fail results
            logger.log('INFO', 'Testing View Change: PASS');
        else
            fprintf('FAIL\n');
            % 3-14-2026: Log pass/fail results
            logger.log('ERROR', 'Testing View Change: FAIL');
        end

    catch ME
        fprintf('FAIL\n');
        fprintf('  View Change test error: %s\n', ME.message);
        logger.log('ERROR', 'View Change test error: %s', ME.message);
    end

catch ME
    % 3-14-2026: Route launch/setup failures through the logger first
    if ~isempty(logger)
        logger.log('ERROR', 'Smoke test crashed: %s', ME.message);
    end
    fprintf('App launch failed: %s\n', ME.message);
end

%% Summary
fprintf('\n----- Test Summary -----\n');
fprintf('Testing Display: %s\n', passfail(displayPass));
fprintf('Testing View Change: %s\n', passfail(viewPass));

% 3-14-2026: Add summary logging so this test conforms to the example
if ~isempty(logger)
    logger.log('INFO', 'Verification summary:\nTesting Display: %s\nTesting View Change: %s', ...
        passfail(displayPass), passfail(viewPass));
end

%% Cleanup
try
    if ~isempty(app) && isvalid(app)
      %   delete(app);
    end
catch
end

if ~isempty(logger)
    logger.log('INFO', 'Headless test complete.');
end

%% Local helper
function out = passfail(tf)
if tf
    out = 'PASS';
else
    out = 'FAIL';
end
end