output_folder = '.';
iterations = 100;
epsilon = 0;
m = 8;
quiet = false;
gmms = gmmTrain('/u/cs401/speechdata/Training', iterations, epsilon, m, quiet);
gmmClassifyFunction('/u/cs401/speechdata/Testing', output_folder, gmms, ...
                    '/u/cs401/speechdata/Testing/TestingIDs1-15.txt', ...
                    quiet);
