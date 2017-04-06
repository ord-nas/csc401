function [gmms_array, total_iters] = gmmTrainMultiEp( dir_train, max_iter, epsilon, M, quiet )
% gmmTain
%
%  inputs:  dir_train  : a string pointing to the high-level
%                        directory containing each speaker directory
%           max_iter   : maximum number of training iterations (integer)
%           epsilon    : minimum improvement for iteration (float)
%           M          : number of Gaussians/mixture (integer)
%           quiet      : optional boolean to suppress output
%
%  output:  gmms       : a 1xN cell array. The i^th element is a structure
%                        with this structure:
%                            gmm.name    : string - the name of the speaker
%                            gmm.weights : 1xM vector of GMM weights
%                            gmm.means   : DxM matrix of means (each column 
%                                          is a vector
%                            gmm.cov     : DxDxM matrix of covariances. 
%                                          (:,:,i) is for i^th mixture

if nargin < 5
    quiet = false;
end

total_iters = zeros(1, length(epsilon));
speakers = dir(dir_train);
counter = 1;
for s=1:length(speakers)
    if strcmp(speakers(s).name, '.') || strcmp(speakers(s).name, '..')
        % dir gives us '.' and '..' directory entries, which we don't want
        continue
    end
    name = speakers(s).name;
    all_data = [];
    data_files = dir([dir_train, filesep, name, filesep, '*.mfcc']);
    for f=1:length(data_files)
        filename = data_files(f).name;
        filepath = [dir_train, filesep, name, filesep, filename];
        data = dlmread(filepath);
        all_data = [all_data; data];
    end
    if ~quiet
        fprintf('Training model for speaker %s with data of size %d x %d\n', ...
                name, size(all_data, 1), size(all_data, 2));
    end
    [gmms, Ls, iters] = gmmEMMultiEp(all_data, max_iter, epsilon, M);
    for i=1:length(epsilon)
        if ~quiet
            fprintf('    Final log likelihood ep=%f: %f\n', epsilon(i), ...
                    Ls{i});
        end
        gmms{i}.name = name;
        total_iters(i) = total_iters(i) + iters{i};
    end
    gmms_array{counter} = gmms;
    
    counter = counter + 1;
end
