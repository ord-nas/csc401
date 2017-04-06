function [gmm, L] = gmmEM( data, max_iter, epsilon, M )
% gmmEM
%
%  inputs:  data       : matrix of training data
%           max_iter   : maximum number of training iterations (integer)
%           epsilon    : minimum improvement for iteration (float)
%           M          : number of Gaussians/mixture (integer)
%
%  output:  gmm        : A structure:
%                            gmm.weights : 1xM vector of GMM weights
%                            gmm.means   : DxM matrix of means (each column 
%                                          is a vector
%                            gmm.cov     : DxDxM matrix of covariances. 
%                                          (:,:,i) is for i^th mixture

  N = size(data, 1); % Number training examples
  d = size(data, 2); % Number of dimensions

  % Initialize parameters
  gmm = struct();
  gmm.weights = ones(1, M) ./ M;
  gmm.means = data(randi(N, 1, M),:)';%rand(d, M);
  
  gmm.cov = ones(d, M);
  
  % Do EM algorithm
  previous_L = -Inf;
  for iter=1:max_iter
      [gmm, L] = em_step(gmm, data);
      % Detect convergence
      if L - previous_L < epsilon
          break
      end
      previous_L = L;
  end

  % Expand covariances to full matrix form
  short_form_cov = gmm.cov;
  gmm.cov = zeros(d,d,M);
  for m=1:M
      gmm.cov(:,:,m) = diag(short_form_cov(:, m));
  end
end
  
  
function [gmm, L] = em_step(gmm, data)
  N = size(data, 1); % Number training examples
  d = size(data, 2); % Number of dimensions

  % Expectation
  constant_b_term = -(sum(gmm.means.^2 ./ gmm.cov ./ 2, 1) + ...
                      (d./2.*log(2.*pi)) + ...
                      (1./2.*sum(log(gmm.cov), 1)));
  variable_b_term = -((1./2 .* (data.^2) * (gmm.cov.^-1)) - ...
                      (data * (gmm.means ./ gmm.cov)));
  log_b = bsxfun(@plus, constant_b_term, variable_b_term);
  wb_product = bsxfun(@plus, log(gmm.weights), log_b);
  log_p = bsxfun(@minus, wb_product, logsumexp(wb_product, 2));
  p = exp(log_p);
  
  L = sum(logsumexp(wb_product, 2));
  
  % Maximization
  sum_p = sum(p, 1);
  gmm.weights = sum_p ./ N;
  gmm.means = bsxfun(@rdivide, data' * p, sum_p);
  gmm.cov = bsxfun(@rdivide, (data.^2)' * p, sum_p) - ...
            (gmm.means.^2);
  
end
