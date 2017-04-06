% In order to keep everything consistent, we're going to use the strsplit in
% BNT, even though this part of the assignment doesn't actually use BNT.
addpath(genpath('/u/cs401/A3_ASR/code/FullBNT-1.0.7'));
warning('off', 'MATLAB:nargchk:deprecated'); % For strsplit

output_folder = '.';
iterations = 100;
epsilon = 0;
m = 8;
quiet = false;
gmms = gmmTrain('/u/cs401/speechdata/Training', iterations, epsilon, m, quiet);
gmmClassifyFunction('/u/cs401/speechdata/Testing', output_folder, gmms, ...
                    '/u/cs401/speechdata/Testing/TestingIDs1-15.txt', ...
                    quiet);
