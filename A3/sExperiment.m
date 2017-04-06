reps = 30;
M = 3;
quiet = true;
train_dir = '/u/cs401/speechdata/Training';
test_dir = '/u/cs401/speechdata/Testing';
label_file = '/u/cs401/speechdata/Testing/TestingIDs1-15.txt';

gmms = gmmTrain(train_dir, 100, 0, M, quiet);

% First find the set of speakers that we need to keep, because they are
% actually in the test set.
keep = struct();
lines = textread(label_file, '%s', 'delimiter', '\n');
% Ignore the header line
lines = lines(2:end);
% Grab the correct answers
for i=1:length(lines)
    words = strsplit(lines{i}, ' *: *', ...
                     'DelimiterType', 'RegularExpression');
    keep.(words{2}) = true;
end

% Now separate the set of all speakers into keepers and non-keepers
n_keepers = 0;
n_disposables = 0;
for i=1:length(gmms)
    if isfield(keep, gmms{i}.name)
        n_keepers = n_keepers + 1;
        keepers{n_keepers} = gmms{i};
    else
        n_disposables = n_disposables + 1;
        disposables{n_disposables} = gmms{i};
    end
end

for s=15:30
    total_accuracy = 0;
    for i=1:reps
        % Select a random s-sized subset of the speaker data. It must contain
        % all the keepers, and then some subset of the disposables.
        subset = keepers;
        index = randperm(length(disposables));
        num_disposables_required = s - length(subset);
        for j=1:num_disposables_required
            subset{length(subset)+1} = disposables{index(j)};
        end
        accuracy = gmmClassify(...
            test_dir, 'temp', subset, label_file, quiet);
        total_accuracy = total_accuracy + accuracy;
    end
    average_accuracy = total_accuracy / reps;
    fprintf('S = %d, accuracy = %f\n', s, average_accuracy);
end


% Results:
% >> sExperiment
% S = 15, accuracy = 0.933333
% S = 16, accuracy = 0.924444
% S = 17, accuracy = 0.920000
% S = 18, accuracy = 0.917778
% S = 19, accuracy = 0.913333
% S = 20, accuracy = 0.917778
% S = 21, accuracy = 0.908889
% S = 22, accuracy = 0.904444
% S = 23, accuracy = 0.902222
% S = 24, accuracy = 0.891111
% S = 25, accuracy = 0.895556
% S = 26, accuracy = 0.884444
% S = 27, accuracy = 0.888889
% S = 28, accuracy = 0.871111
% S = 29, accuracy = 0.871111
% S = 30, accuracy = 0.866667
