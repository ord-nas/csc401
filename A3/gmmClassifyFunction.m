function accuracy = gmmClassifyFunction(dir_test, dir_output, gmms, label_file, quiet)
  correct_classifications = 0;
  max_possible_correct = 0;
  accuracy = 0;
  answers = struct();
  if nargin >= 4 && ~isempty(label_file)
      lines = textread(label_file, '%s', 'delimiter', '\n');
      % Ignore the header line
      lines = lines(2:end);
      % Grab the correct answers
      for i=1:length(lines)
          words = strsplit(':', lines{i});
          sample_name = ['unkn_', regexprep(words{1}, ' ', '')];
          answers.(sample_name) = regexprep(words{2}, ' ', '');
      end
  end
  
  if nargin < 5
      quiet = false;
  end
    
  % Make the output directory if it doesn't alreay exist
  if ~exist(dir_output,'dir')
      mkdir(dir_output);
  end
    
  % Get the set of examples from the test directory
  data_files = dir([dir_test, filesep, '*.mfcc']);
  
  for f=1:length(data_files)
      fullname = data_files(f).name;
      fullpath = [dir_test, filesep, fullname];
      [pathstr, name, ext] = fileparts(fullname);
      data = dlmread(fullpath);
      if ~quiet
          fprintf('Analyzing file %s ...\n', fullname);
      end
      
      N = size(data, 1); % Number data points
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
      output = [dir_output, filesep, name, '.lik'];
      fileID = fopen(output, 'w');
      if ~quiet
          fprintf('Most likely speakers, sorted descending:\n');
      end
      for i=1:min(5, length(L))
          tee(fileID, quiet, '%s,%f\n', gmms{I(i)}.name, sorted_L(i));
      end
      fclose(fileID);
      
      % If we know the correct answer for this example, check if we got it
      % right!
      if isfield(answers, name)
          max_possible_correct = max_possible_correct + 1;
          guess = gmms{I(1)}.name;
          actual = answers.(name);
          if strcmp(guess, actual)
              correct_classifications = correct_classifications + 1;
          end
      end
  end
  
  if ~quiet
      fprintf('Overall classification results: %d out of %d\n', ...
              correct_classifications, max_possible_correct);
  end
  
  if max_possible_correct > 0
      accuracy = correct_classifications / max_possible_correct;
  end
end

% Write both to stdout and to the given file.
function tee(fileID, quiet, varargin)
  fprintf(fileID, varargin{:});
  if ~quiet
      fprintf(varargin{:});
  end
end
