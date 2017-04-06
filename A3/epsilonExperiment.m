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
% >> mExperiment
% M = 1, accuracy = 0.933333
% M = 2, accuracy = 0.926667
% M = 3, accuracy = 0.893333
% M = 4, accuracy = 0.948889
% M = 5, accuracy = 0.962222
% M = 6, accuracy = 0.986667
% M = 7, accuracy = 0.991111
% M = 8, accuracy = 0.997778
% >> mExperiment
% M = 1, accuracy = 0.933333
% M = 2, accuracy = 0.911111
% M = 3, accuracy = 0.868889
% M = 4, accuracy = 0.960000
% M = 5, accuracy = 0.955556
% M = 6, accuracy = 0.975556
% M = 7, accuracy = 0.995556
% M = 8, accuracy = 0.997778
% >> mExperiment
% M = 9, accuracy = 0.993333
% M = 10, accuracy = 0.993333
% M = 11, accuracy = 0.997778
% M = 12, accuracy = 1.000000
% >> mExperiment
% M = 12, accuracy = 1.000000
