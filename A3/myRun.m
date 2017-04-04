tic; % Time how long this script takes to run

dir_test = '/u/cs401/speechdata/Testing';
dir_phonemes = 'initial_phoneme_models';

% First add BNT to our path
addpath(genpath('/u/cs401/A3_ASR/code/FullBNT-1.0.7'));
warning('off', 'MATLAB:nargchk:deprecated'); % For strsplit

% Now extract all the testing data
test_data = struct();
data_files = dir([dir_test, filesep, '*.phn']);
for f=1:length(data_files)
    filename = data_files(f).name;
    filepath = [dir_test, filesep, filename];
    [pathstr, name, ext] = fileparts(filepath);
    % Read in both the .phn lines and the .mfcc samples
    phoneme_lines = textread(filepath, '%s', 'delimiter', '\n');
    mfcc_data = dlmread([pathstr, filesep, name, '.mfcc']);
    N = size(mfcc_data, 1);
    for i=1:length(phoneme_lines)
        % Parse the phoneme line
        words = strsplit(' ', phoneme_lines{i});
        assert(length(words) == 3);
        start = str2num(words{1});
        assert(length(start) == 1);
        finish = str2num(words{2});
        assert(length(finish) == 1);
        p = words{3};
        if strcmp(p, 'h#')
            p = 'sil';
        end
        assert(length(p) > 0);
        % Convert start and end times to mfcc sample indices.
        % Strategy: first, we interpret the ranges in .phn as open on the
        % right. I.e. 0 7808 #h means that h# is present in the samples
        % [0, 7808). Then we take all mfcc frames where *at least one*
        % sample in the range [0, 7808) appears inside the frame.
        start = start / 128 + 1;
        finish = finish / 128;
        assert(start == fix(start));
        assert(finish == fix(finish));
        finish = min(finish, N);
        % If this phone sequence is empty, skip it
        if finish < start
            continue
        end
        % Now add this sequence
        next_index = 1;
        if isfield(test_data, p)
            next_index = 1 + length(test_data.(p));
        end
        test_data.(p){next_index} = mfcc_data(start:finish,:)';
        %fprintf('%s/%s.mfcc(%d:%d,:) -> %s\n', speaker, name, start, finish, p);
    end
end

% Now load the train phone HMMs
hmm_files = dir([dir_phonemes, filesep, '*.mat']);
hmms = struct();
for h=1:length(hmm_files)
    filename = hmm_files(h).name;
    filepath = [dir_phonemes, filesep, filename];
    [pathstr, phone_name, ext] = fileparts(filepath);
    load(filepath, 'HMM', '-mat');
    hmms.(phone_name) = HMM;
end

actual_phones = fieldnames(test_data);
all_phones = fieldnames(hmms);

disp('ALL TEST DATA');
disp(actual_phones);
disp('ALL MODELS');
disp(all_phones);

confusion = zeros(length(all_phones));

for i=1:length(all_phones)
    aphone = all_phones{i};
    % Skip this phone if it's not in the test data
    if ~isfield(test_data, aphone)
        continue
    end
    for j=1:length(test_data.(aphone))
        seq = test_data.(aphone){j};
        best_LL = -inf;
        best_phone = 0;
        for k=1:length(all_phones)
            pphone = all_phones{k};
            hmm = hmms.(pphone);
            LL = loglikHMM(hmm, seq);
            if LL > best_LL
                best_LL = LL;
                best_index = k;
            end
        end
        fprintf('Actual %s, predicted %s\n', aphone, all_phones{best_index});
        confusion(i,best_index) = confusion(i,best_index) + 1;
    end
end

disp(confusion);

toc; % Print elapsed time