% Headless test script for the SEStaticDetectAndReleaseMine class


clear;
clc;

% Add the current directory to the path to ensure all class files are found
addpath(pwd);

% Initialize the logger to ensure messages are displayed in the console
Logger.getInstance();

fprintf('Starting headless test for SEStaticDetectAndReleaseMine...\n\n');

pass_count = 0;
fail_count = 0;
total_tests = 2;

% --- Test Case 1: Ship is far away, mine should remain tethered ---
fprintf('--- Running Test Case 1: Ship Outside Detection Range ---\n');

try
    % 1. Reset to a known state by creating a new instance
    % Default values are pos=[0,0,-10], anchor=[0,0,-10], detectRange=2
    mine = SEStaticDetectAndReleaseMine();
    fprintf('  [SETUP] Instantiated mine at position (%.1f, %.1f, %.1f) with detection range %.1f.\n', ...
            mine.pos_x, mine.pos_y, mine.pos_z, mine.detectRange);

    % 2. Define a ship far outside the detection range
    ship_pos_far = [100, 100, 0];
    fprintf('  [ACTION] Updating mine state with a ship at position (%.1f, %.1f).\n', ...
            ship_pos_far(1), ship_pos_far(2));

    % 3. Call the update method
    mine.update(0.1, [0, 0, 0], ship_pos_far);

    % 4. Assert the expected outcome
    if mine.tethered && ~mine.surfaced
        fprintf('  [PASS] Mine remained tethered and did not surface, as expected.\n\n');
        pass_count = pass_count + 1;
    else
        fprintf('  [FAIL] Mine state changed unexpectedly. Tethered: %s, Surfaced: %s.\n\n', ...
                mat2str(mine.tethered), mat2str(mine.surfaced));
        fail_count = fail_count + 1;
    end
catch ME
    fprintf('  [ERROR] Test Case 1 failed with an error: %s\n\n', ME.message);
    fail_count = fail_count + 1;
end


% --- Test Case 2: Ship is close, mine should release and surface ---
fprintf('--- Running Test Case 2: Ship Inside Detection Range ---\n');
try
    % 1. Reset to a known state
    mine = SEStaticDetectAndReleaseMine();
    fprintf('  [SETUP] Instantiated mine at position (%.1f, %.1f, %.1f) with detection range %.1f.\n', ...
            mine.pos_x, mine.pos_y, mine.pos_z, mine.detectRange);

    % 2. Define a ship inside the detection range
    ship_pos_close = [mine.pos_x + 1, mine.pos_y, 0]; % distance is 1, which is < detectRange of 2
    fprintf('  [ACTION] Updating mine state with a ship at position (%.1f, %.1f).\n', ...
            ship_pos_close(1), ship_pos_close(2));

    % 3. Call the update method
    mine.update(0.1, [0, 0, 0], ship_pos_close);

    % 4. Assert the expected outcome
    if ~mine.tethered && mine.surfaced
        fprintf('  [PASS] Mine released tether and surfaced, as expected.\n\n');
        pass_count = pass_count + 1;
    else
        fprintf('  [FAIL] Mine did not release or surface correctly. Tethered: %s, Surfaced: %s.\n\n', ...
                mat2str(mine.tethered), mat2str(mine.surfaced));
        fail_count = fail_count + 1;
    end
catch ME
    fprintf('  [ERROR] Test Case 2 failed with an error: %s\n\n', ME.message);
    fail_count = fail_count + 1;
end

% --- Final Summary ---
fprintf('-------------------- TEST SUMMARY --------------------\n');
fprintf('  Total Tests: %d\n', total_tests);
fprintf('  Passed: %d\n', pass_count);
fprintf('  Failed: %d\n', fail_count);
fprintf('------------------------------------------------------\n\n');

if fail_count == 0
    fprintf('Overall Result: ALL TESTS PASSED\n');
else
    fprintf('Overall Result: SOME TESTS FAILED\n');
end

fprintf('\nExternal headless test finished.\n');

