function test_verifyOceanEnvironment()
    % Headless driver
    app = [];
    logger = [];

    try
        mm_pathsetup(); % Ensure paths are loaded
        logger = Logger.getInstance();        
        logger.log('INFO', 'Starting Ocean Environment headless test.');

        % Initialize the GUI
        app = verifyOceanUserInterface(); 
        drawnow;

        %set environment speed
        app.setEnvSpeed(2);
        app.setEnvMode("Gradient");
        drawnow;
        pause(1);

        % Set up headless state
        logger.setTextHandle([]);
        logger.log('INFO', 'App launched. Coordinating verification...');

        % Trigger the verification logic
        [didPass, results] = app.runVerification();

        
        if didPass
            logger.log('INFO', 'Ocean Verification PASSED.');
            logger.log('INFO', 'Physics verified. Starting visual simulation')
            %set the mine layout and fleet behavior
            app.FleetBehaviorDropDown.Value = 'Kamikaze';
            app.MinefieldLayoutDropDown.Value = 'uniform';
            %add numbers to the sim
            app.simEngine.setNumMines(10);
            app.simEngine.setNumShips(5);

            %start the sim
            app.simEngine.run(1);
            logger.log('INFO', 'Simulation is running');
            for i = 1:50
                drawnow;
                pause(0.2);
            end
            logger.log('INFO', 'Visual test complete');
        
        else
            logger.log('ERROR', 'Ocean Verification FAILED.');
        end

    catch ME
        fprintf(2, 'Headless test crashed: %s\n', ME.message);
    end
end