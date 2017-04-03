dir_train = '/u/cs401/speechdata/Training';

% First add BNT to our path
addpath(genpath('/u/cs401/A3_ASR/code/FullBNT-1.0.7'));
warning('off', 'MATLAB:nargchk:deprecated'); % For strsplit

phonemes = struct();
speakers = dir(dir_train);
counter = 1;
for s=1:length(speakers)
    if strcmp(speakers(s).name, '.') || strcmp(speakers(s).name, '..')
        % dir gives us '.' and '..' directory entries, which we don't want
        continue
    end
    speaker = speakers(s).name;
    all_data = [];
    data_files = dir([dir_train, filesep, speaker, filesep, '*.phn']);
    for f=1:length(data_files)
        filename = data_files(f).name;
        filepath = [dir_train, filesep, speaker, filesep, filename];
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
            % Now add this sequence
            next_index = 1;
            if isfield(phonemes, p)
                next_index = 1 + length(phonemes.(p));
            end
            phonemes.(p){next_index} = mfcc_data(start:finish,:);
            %fprintf('%s/%s.mfcc(%d:%d,:) -> %s\n', speaker, name, start, finish, p);
        end
    end
end
