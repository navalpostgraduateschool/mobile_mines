% SEStaticTetheredMine_headless_test.m
% Headless test script for the SEStaticTetheredMine class.
% This script runs without a GUI and prints results to the console.

% It is good practice to clear the workspace and command window.
clear;
clc;
fprintf('Starting headless test for SEStaticTetheredMine...\n\n');

% --- Test 1: Test the built-in verify() method ---
% The class comes with its own verification method, which is a great place to start.
fprintf('--- Running Test 1: Calling the built-in verify() method ---\n');
try
    % Instantiate the mine
    mine_for_verify = SEStaticTetheredMine([0,0,-10], [0,0,-10], 2);

    % The verify() method logs output to the console via the Logger class
    % and returns a pass/fail status.
    [pass, details] = mine_for_verify.verify();

    fprintf('\nBuilt-in verify() method finished.\n');
    fprintf('Result: %s\n', details.summary);
    fprintf('Distance from anchor after test: %.4f (Tether Length: %.1f)\n', details.metrics.distanceFromAnchor, details.metrics.tetherLength);

    if pass
        fprintf('--- Test 1 PASSED ---\n\n');
    else
        fprintf('--- Test 1 FAILED ---\n\n');
    end

catch ME
    fprintf('--- Test 1 FAILED with an error: %s ---\n', ME.message);
    fprintf('Error details: %s\n\n', ME.getReport());
end


% --- Test 2: Test the releaseTether() functionality ---
fprintf('--- Running Test 2: Testing releaseTether() and subsequent movement ---\n');
try
    % Setup
    pos0 = [0, 0, -10];
    anchor0 = [0, 0, -10];
    tetherLen0 = 5;
    mine_for_release = SEStaticTetheredMine(pos0, anchor0, tetherLen0);
    fprintf('Initial state: tethered = %s\n', mat2str(mine_for_release.tethered));

    % Action 1: Release the tether
    mine_for_release.releaseTether();
    fprintf('After calling releaseTether(): tethered = %s\n', mat2str(mine_for_release.tethered));

    % Verification 1
    assert(~mine_for_release.tethered, 'The tethered property should be false after release.');
    fprintf('[PASS] Tether released successfully.\n');

    % Action 2: Apply a force and update position to see if it moves past the tether length
    force = [20, 0, 0]; % A significant force
    dt = 0.1;
    fprintf('Applying a force to the released mine for several steps...\n');
    for i = 1:50 % 5 seconds of simulation time
        mine_for_release.update(dt, force, []);
    end

    final_pos = mine_for_release.getPosition();
    dist_from_anchor = norm(final_pos - mine_for_release.anchor);

    fprintf('Final position: [%.2f, %.2f, %.2f]\n', final_pos(1), final_pos(2), final_pos(3));
    fprintf('Distance from anchor: %.4f (Original Tether Length: %.1f)\n', dist_from_anchor, tetherLen0);

    % Verification 2
    assert(dist_from_anchor > tetherLen0, 'Mine should have moved beyond the original tether length.');
    fprintf('[PASS] Mine moved freely beyond tether length after release.\n');

    fprintf('--- Test 2 PASSED ---\n\n');

catch ME
    fprintf('--- Test 2 FAILED with an error: %s ---\n', ME.message);
    fprintf('Error details: %s\n\n', ME.getReport());
end


% --- Test 3: Test the overridden setPosition() method ---
% This test verifies that when a mine's position is set, its anchor is also updated.
fprintf('--- Running Test 3: Testing the overridden setPosition() method ---\n');
try
    % Setup
    mine_for_setpos = SEStaticTetheredMine([0,0,0], [0,0,0], 10);
    fprintf('Initial anchor position: [%.2f, %.2f, %.2f]\n', mine_for_setpos.anchor);

    % Action
    new_pos = [10, 20, -5];
    mine_for_setpos.setPosition(new_pos(1), new_pos(2), new_pos(3));
    fprintf('Called setPosition with new coordinates: [%d, %d, %d]\n', new_pos(1), new_pos(2), new_pos(3));

    % Verification
    final_anchor = mine_for_setpos.anchor;
    final_pos = mine_for_setpos.getPosition();

    fprintf('Final position: [%.2f, %.2f, %.2f]\n', final_pos(1), final_pos(2), final_pos(3));
    fprintf('Final anchor position: [%.2f, %.2f, %.2f]\n', final_anchor(1), final_anchor(2), final_anchor(3));

    assert(all(final_anchor == new_pos), 'The anchor should be updated to the new position.');

    fprintf('[PASS] setPosition correctly updated the anchor.\n');
    fprintf('--- Test 3 PASSED ---\n\n');

catch ME
    fprintf('--- Test 3 FAILED with an error: %s ---\n', ME.message);
    fprintf('Error details: %s\n\n', ME.getReport());
end

fprintf('All headless tests for SEStaticTetheredMine completed.\n');

