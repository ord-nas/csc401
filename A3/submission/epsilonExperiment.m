epsilons = [10000, 5000, 1000, 500, 100, 50, 10, 5, 1, 0.5, 0.1, 0.05, 0.01, 0.005, 0.001, 0];
reps = 30;
quiet = true;
output_folder = ['Results_', int2str(m)];
total_accuracy = zeros(1, length(epsilons));
total_iters = zeros(1, length(epsilons));
for i=1:reps
    [gmms_array, iters] = gmmTrainMultiEp('/u/cs401/speechdata/Training', 100, epsilons, m, quiet);
    for j=1:length(epsilons)
        for k=1:length(gmms_array)
            gmms{k} = gmms_array{k}{j};
        end
        accuracy = gmmClassifyFunction('/u/cs401/speechdata/Testing', output_folder, gmms, ...
                                       '/u/cs401/speechdata/Testing/TestingIDs1-15.txt', ...
                                       quiet);
        total_accuracy(j) = total_accuracy(j) + accuracy;
        total_iters(j) = total_iters(j) + iters(j);
    end
end
average_accuracy = total_accuracy / reps;
average_iters = total_iters / reps;
for j=1:length(epsilons)
    fprintf('epsilon = %f, accuracy = %f, iters = %d\n', epsilons(j), ...
            average_accuracy(j), average_iters(j));
end

% Results:
% >> epsilonExperiment;
% epsilon = 10000.000000, accuracy = 0.953333, iters = 90
% epsilon = 5000.000000, accuracy = 0.971111, iters = 120
% epsilon = 1000.000000, accuracy = 0.977778, iters = 1.502333e+02
% epsilon = 500.000000, accuracy = 0.986667, iters = 1.820667e+02
% epsilon = 100.000000, accuracy = 0.997778, iters = 2.784667e+02
% epsilon = 50.000000, accuracy = 0.997778, iters = 3.623667e+02
% epsilon = 10.000000, accuracy = 0.997778, iters = 629
% epsilon = 5.000000, accuracy = 0.997778, iters = 7.695333e+02
% epsilon = 1.000000, accuracy = 0.997778, iters = 1.141633e+03
% epsilon = 0.500000, accuracy = 0.997778, iters = 1.330133e+03
% epsilon = 0.100000, accuracy = 0.993333, iters = 1.712700e+03
% epsilon = 0.050000, accuracy = 0.993333, iters = 1.863667e+03
% epsilon = 0.010000, accuracy = 0.993333, iters = 2.131800e+03
% epsilon = 0.005000, accuracy = 0.993333, iters = 2.228867e+03
% epsilon = 0.001000, accuracy = 0.993333, iters = 2.408467e+03
% epsilon = 0.000000, accuracy = 0.993333, iters = 2.977167e+03 
