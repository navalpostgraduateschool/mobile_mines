function test_verifyParticleEmitter()
% test_verifyParticleEmitter
%
% Headless driver for verifyParticleEmitter.mlapp

    % Boilerplate setup
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
        
        logger.log('INFO', 'Starting verifyParticleEmitter headless test.');

        % Instantiate the app
        app = verifyParticleEmitter();
        drawnow;

        % Disable output to a text handle in the app so we can read the console
        logger.setTextHandle([]);
        logger.setLogToFile(false);

        logger.log('INFO', 'App launched successfully.');

        % Programmatically adjust the sliders
        app.setParticleCount(150);
        app.setInitialSpeed(5);
        app.setInitialDirection(45);

        logger.log('INFO', 'Triggering 3D explosion demo via headless script...');
        app.triggerDemo();

        logger.log('INFO', 'Executing verification contract...');
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

    % Cleanup
    if ~isempty(app) && isvalid(app)
        delete(app);
    end

    if ~isempty(logger)
        logger.log('INFO', 'Headless test complete.');
    end
end