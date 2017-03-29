reps = 30;
for m=1:8
    quiet = true;
    output_folder = ['Results_', int2str(m)];
    total_accuracy = 0;
    for i=1:reps
        gmms = gmmTrain('/u/cs401/speechdata/Training', 100, 0, m, quiet);
        accuracy = gmmClassify('/u/cs401/speechdata/Testing', output_folder, gmms, ...
                           '/u/cs401/speechdata/Testing/TestingIDs1-15.txt', ...
                           quiet);
        total_accuracy = total_accuracy + accuracy;
    end
    average_accuracy = total_accuracy / reps;
    fprintf('M = %d, accuracy = %f\n', m, average_accuracy);
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
