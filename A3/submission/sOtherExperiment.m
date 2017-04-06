reps = 30;
M = 8;
quiet = true;
train_other = true;
train_dir = '/u/cs401/speechdata/Training';
test_dir = '/u/cs401/speechdata/Testing';
label_file = '/u/cs401/speechdata/Testing/TestingIDs1-15.txt';

gmms = gmmTrain(train_dir, 100, 0, M, quiet, train_other);

% Create list of speakers
counter = 1;
for i=1:length(gmms)
    if ~strcmp(gmms{i}.name, 'OTHER')
        speakers{counter} = gmms{i};
        counter = counter + 1;
    else
        other_model = gmms{i};
    end
end

for s=15:30
    total_accuracy = 0;
    for i=1:reps
        % Select a random s-sized subset of the speaker data.
        index = randperm(length(speakers));
        clear subset;
        for j=1:s
            subset{j} = speakers{index(j)};
            if ~quiet
                fprintf('SELECTED SPEAKER: %s\n', subset{j}.name);
            end
        end
        subset{j+1} = other_model;
        accuracy = gmmClassifyFunction(...
            test_dir, 'temp', subset, label_file, quiet);
        total_accuracy = total_accuracy + accuracy;
    end
    average_accuracy = total_accuracy / reps;
    fprintf('S = %d, accuracy = %f\n', s, average_accuracy);
end


% Results:
% >> sOtherExperiment
% S = 15, accuracy = 0.800000
% S = 16, accuracy = 0.791111
% S = 17, accuracy = 0.817778
% S = 18, accuracy = 0.804444
% S = 19, accuracy = 0.802222
% S = 20, accuracy = 0.820000
% S = 21, accuracy = 0.853333
% S = 22, accuracy = 0.860000
% S = 23, accuracy = 0.860000
% S = 24, accuracy = 0.884444
% S = 25, accuracy = 0.915556
% S = 26, accuracy = 0.911111
% S = 27, accuracy = 0.951111
% S = 28, accuracy = 0.953333
% S = 29, accuracy = 0.971111
% S = 30, accuracy = 1.000000