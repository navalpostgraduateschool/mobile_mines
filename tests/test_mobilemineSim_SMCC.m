function test_mobilemineSim_SMCC()
% test_mobilemineSim_SMCC
% Headless driver for verifyMineDetectionRanges.mlapp


    % Here is some boiler plate code that can be reused by others as helpful
    app = [];
    logger = [];

    try
        thisFile = mfilename('fullpath');
        testsFolder = fileparts(thisFile);
        projectRoot = fileparts(testsFolder);

        oldFolder = pwd;
        cleanupObj = onCleanup(@() cd(oldFolder)); %#ok<NASGU>
        cd(projectRoot);

        mm_pathsetup();

        logger = Logger.getInstance();        
        
        % Students can update here - this is specific to detection ranges
        logger.log('INFO', 'Starting mobilemineSim_SMCC headless test.');

        app = mobilemineSim_SMCC();
        drawnow;


        % Disable output to a text handle in the app (if it was enabled)
            % Comment out #1 to have headless show up on GUI
            % Comment out #2 to have headless show up on Commanand Window
        %logger.setTextHandle([]); %#1
        logger.setTextHandle(app.ConsoleTextArea); %#2
        logger.setLogToFile(false);

        logger.log('INFO', 'App launched successfully.');

     % --- Test "tethered" mine type ---
        logger.log('INFO', '--- Verifying tethered mines ---');
        app.setMine_Type("Tethered");
        logger.log('INFO', 'Current Mine Type is %s.', app.getMine_Type());
        [didPassTethered, resultsTethered] = app.runVerification();

        if didPassTethered
            logger.log('INFO', 'Tethered mine verification PASSED.');
        else
            logger.log('ERROR', 'Tethered mine verification FAILED.');
        end
        if isstruct(resultsTethered) && isfield(resultsTethered, 'summary')
            logger.log('INFO', 'Summary: %s', resultsTethered.summary);
        end
        
        % --- Test "detect_release" mine type ---
        logger.log('INFO', '--- Verifying detect_release mines ---');
        app.setMine_Type("Detect_Release");
        logger.log('INFO', 'Current Mine Type is %s.', app.getMine_Type());
        [didPassDetect, resultsDetect] = app.runVerification();

        if didPassDetect
            logger.log('INFO', 'Detect_release mine verification PASSED.');
        else
            logger.log('ERROR', 'Detect_release mine verification FAILED.');
        end
        if isstruct(resultsDetect) && isfield(resultsDetect, 'summary')
            logger.log('INFO', 'Summary: %s', resultsDetect.summary);
        end
        
        % --- Final Test Summary ---
        if didPassTethered && didPassDetect
            logger.log('INFO', 'All headless tests PASSED.');
        else
            logger.log('ERROR', 'One or more headless tests FAILED.');
        end


    catch ME
        if ~isempty(logger)
            logger.log('ERROR', 'Headless test crashed: %s', ME.message);
        else
            fprintf(2, 'Headless test crashed: %s\n', ME.message);
        end
        rethrow(ME);
    end


    % Optionally delete the app when done.
    % if ~isempty(app) && isvalid(app)
    %     delete(app);
    % end

    if ~isempty(logger)
        logger.log('INFO', 'Headless test complete.');
    end
end