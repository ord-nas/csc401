function gmms = gmmTrain( dir_train, max_iter, epsilon, M, quiet, train_other )
% gmmTain
%
%  inputs:  dir_train  : a string pointing to the high-level
%                        directory containing each speaker directory
%           max_iter   : maximum number of training iterations (integer)
%           epsilon    : minimum improvement for iteration (float)
%           M          : number of Gaussians/mixture (integer)
%           quiet      : optional boolean to suppress output
%           train_other: optional boolean to train a "none of the above" model
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
    train_other = false;
elseif nargin < 6
    train_other = false;
end

speakers = dir(dir_train);
counter = 1;
all_speaker_data = [];
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
    [gmm, L] = gmmEM(all_data, max_iter, epsilon, M);
    if ~quiet
        fprintf('    Final log likelihood: %f\n', L);
    end
    gmm.name = name;
    gmms{counter} = gmm;
    counter = counter + 1;
    if train_other
        all_speaker_data = [all_speaker_data; all_data];
    end
end

if train_other
    if ~quiet
        fprintf('Training "other" model with data of size %d x %d\n', ...
                size(all_speaker_data, 1), size(all_speaker_data, 2));
    end
    [gmm, L] = gmmEM(all_speaker_data, max_iter, epsilon, M);
    if ~quiet
        fprintf('    Final log likelihood: %f\n', L);
    end
    gmm.name = 'OTHER';
    gmms{counter} = gmm;
    counter = counter + 1;
end