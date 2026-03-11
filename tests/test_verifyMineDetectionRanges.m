function test_verifyMineDetectionRanges()
% test_verifyMineDetectionRanges
%
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
        logger.log('INFO', 'Starting verifyMineDetectionRanges headless test.');

        app = verifyMineDetectionRanges();
        drawnow;


        % Disable output to a text handle in the app (if it was enabled)
        logger.setTextHandle([]);
        logger.setLogToFile(false);

        logger.log('INFO', 'App launched successfully.');

        app.setDetectionRange(10);
        app.setDetectionRange(25);
        app.setDetectionRange(40);

        logger.log('INFO', 'Current detection range is %.1f units.', ...
            app.getDetectionRange());

        [didPass, results] = app.runVerification();

        if didPass
            logger.log('INFO', 'Headless test PASSED.');
        else
            logger.log('ERROR', 'Headless test FAILED.');
        end

        if isstruct(results) && isfield(results, 'summary')
            logger.log('INFO', 'Verification summary:\n%s', results.summary);
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