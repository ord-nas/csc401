function gmmClassify(dir_test, dir_output, gmms)
  % Make the output directory if it doesn't alreay exist
  mkdir(dir_output);
    
  % Get the set of examples from the test directory
  data_files = dir([dir_test, filesep, '*.mfcc']);
  
  for f=1:length(data_files)
      fullname = data_files(f).name;
      fullpath = [dir_test, filesep, fullname];
      data = dlmread(fullpath);
      fprintf('Analyzing file %s ...\n', fullname);
      
      N = size(data, 1); % Number training examples
      d = size(data, 2); % Number of dimensions

      % Compute likelihood for each of the gmms
      L = zeros(1, length(gmms));
      for g=1:length(gmms)
          gmm = gmms{g};
          M = length(gmm.weights);
          
          % Extract just the diagonal entries of the covariance matrix
          cov = zeros(d, M);
          for m=1:M
              cov(:,m) = diag(gmm.cov(:,:,m));
          end

          % Now do the actual log-likelihood calculation, and store the
          % resuls in the L array
          constant_b_term = -(sum(gmm.means.^2 ./ cov ./ 2, 1) + ...
                              (d./2.*log(2.*pi)) + ...
                              (1./2.*sum(log(cov), 1)));
          variable_b_term = -((1./2 .* (data.^2) * (cov.^-1)) - ...
                              (data * (gmm.means ./ cov)));
          log_b = bsxfun(@plus, constant_b_term, variable_b_term);
          wb_product = bsxfun(@plus, log(gmm.weights), log_b);
          L(g) = sum(logsumexp(wb_product, 2));
      end
      
      % Sort the L array to find the best models
      [sorted_L,I] = sort(L, 'descend');

      % Report the 5 best models
      [pathstr, name, ext] = fileparts(fullname);
      output = [dir_output, filesep, name, '.lik'];
      fileID = fopen(output, 'w');
      tee(fileID, 'Most likely speakers, sorted descending:\n');
      for i=1:min(5, length(L))
          tee(fileID, '%d. %s, with log liklihood %f\n', ...
              i, gmms{I(i)}.name, sorted_L(i));
      end
      fclose(fileID);
  end
end

% Write both to stdout and to the given file.
function tee(fileID, varargin)
  fprintf(fileID, varargin{:});
  fprintf(varargin{:});
end
