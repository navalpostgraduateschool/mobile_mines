eng1 = SESimulatorEngine();
fprintf(1,'Test 1 - passed\n');
boundary_box = [ 0 0 4 5];
eng2 = SESimulatorEngine(boundary_box);
fprintf(1,'Test 2 - passed\n');

axes_handle = gca;
eng3 = SESimulatorEngine(boundary_box, axes_handle);
fprintf(1,'Test 3 - passed\n');

eng3.setNumShips(4);
fprintf(1,'Test setNumShips(4) - passed\n');

eng3.setNumMines(5);
fprintf(1,'Test setNumMines(5) - passed\n');
