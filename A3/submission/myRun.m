% First add BNT to our path
addpath(genpath('/u/cs401/A3_ASR/code/FullBNT-1.0.7'));
warning('off', 'MATLAB:nargchk:deprecated'); % For strsplit

dir_test = '/u/cs401/speechdata/Testing';
dir_phonemes = '.';
dims = 14;

myRunFunction(dir_test, dir_phonemes, dims);
