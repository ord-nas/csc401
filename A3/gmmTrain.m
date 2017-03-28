function gmms = gmmTrain( dir_train, max_iter, epsilon, M )
% gmmTain
%
%  inputs:  dir_train  : a string pointing to the high-level
%                        directory containing each speaker directory
%           max_iter   : maximum number of training iterations (integer)
%           epsilon    : minimum improvement for iteration (float)
%           M          : number of Gaussians/mixture (integer)
%
%  output:  gmms       : a 1xN cell array. The i^th element is a structure
%                        with this structure:
%                            gmm.name    : string - the name of the speaker
%                            gmm.weights : 1xM vector of GMM weights
%                            gmm.means   : DxM matrix of means (each column 
%                                          is a vector
%                            gmm.cov     : DxDxM matrix of covariances. 
%                                          (:,:,i) is for i^th mixture

speakers = dir(dir_train);
counter = 1;
for s=1:length(speakers)
    if strcmp(speakers(s).name, '.') || strcmp(speakers(s).name, '..')
        continue
    end
    name = speakers(s).name;
    all_data = [];
    data_files = dir([dir_train, filesep, name, filesep, '*.txt']);
    for f=1:length(data_files)
        data = dlmread('/u/cs401/speechdata/Training/FCJF0/SA1.mfcc');
        all_data = [all_data; data];
    end
    % fprintf('Speaker %s has data that is %d by %d\n', name, size(all_data, 1), size(all_data, 2));
    gmm = gmmEM(all_data, max_iter, epsilon, M);
    gmm.name = name;
    gmms{counter} = gmm;
    counter = counter + 1;
end
return
