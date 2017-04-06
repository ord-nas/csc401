% First add BNT to our path
addpath(genpath('/u/cs401/A3_ASR/code/FullBNT-1.0.7'));
warning('off', 'MATLAB:nargchk:deprecated'); % For strsplit

% Now invoke the training function
dir_train = '/u/cs401/speechdata/Training';
dir_output = '.';
skip_if_exists = false;
M = 8;
Q = 3;
data_fraction = 1.0;
dims = 1;
myTrainFunction(dir_train, dir_output, skip_if_exists, M, Q, data_fraction, ...
                dims);
