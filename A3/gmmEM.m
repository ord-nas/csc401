function gmm = gmmEM( data, max_iter, epsilon, M )
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
  gmm.cov = rand(d, M) * 100; % Start with a big variance so that our
                              % likelihoods don't vanish
  %gmm.cov = zeros(d,d,M);
  %for m=1:M
  %    gmm.cov(:,:,m) = diag(rand(1,d));
  %end

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

end
  
  
function [gmm, L] = em_step(gmm, data)
  N = size(data, 1); % Number training examples
  d = size(data, 2); % Number of dimensions

  % Expectation
  constant_b_term = -(sum(gmm.means.^2 ./ gmm.cov.^2 ./ 2, 1) + ...
                      (d./2.*log(2.*pi)) + ...
                      (1./2.*sum(log(gmm.cov.^2), 1)));
  variable_b_term = -((1./2 .* (data.^2) * (gmm.cov.^-2)) - ...
                      (data * (gmm.means .* (gmm.cov.^-2))));
  log_b = bsxfun(@plus, constant_b_term, variable_b_term);
  %size(b);

  % Straight-forward loopy implementation
  % (used to debug vectorized version)
  %log_b2 = zeros(N, 8);
  %for n=1:N
  %    for m=1:8
  %        s = 0;
  %        for i=1:d
  %            term = (data(n, i) - gmm.means(i, m)).^2 ./ ...
  %                   (2.* gmm.cov(i, m).^2);
  %            s = s + term;
  %        end
  %        p = 1;
  %        for i=1:d
  %            term = gmm.cov(i, m).^2;
  %            p = p * term;
  %        end
  %        log_b2(n, m) = -s - (d./2.*log(2.*pi)) - (1/2*log(p));
  %    end
  %end
  
  %log_b(1:5,1:5)
  %log_b2(1:5,1:5)
  %maximum_diff = max(max(abs(log_b2 - log_b)))
  %b = exp(log_b);
  %b(1:5,1:5)
  wb_product = bsxfun(@plus, log(gmm.weights), log_b);
  log_p = bsxfun(@minus, wb_product, logsumexp(wb_product, 2));
  %p = exp(log_p);
  
  log_L = sum(logsumexp(wb_product, 2))
  
  % Straight-forward loopy implementation
  %log_L2 = 0;
  %for n=1:N
  %    s = 0;
  %    for m=1:8
  %        s = s + gmm.weights(1,m) * b(n, m);
  %    end
  %    log_L2 = log_L2 + log(s);
  %end
  %log_L2
  
  
  %bsxfun(@rdivide, ...
  %               bsxfun(@times, gmm.weights, b), ...
  %               (b * gmm.weights'));
  %size(p)

  % Straight-foward loopy implmentation
  % (used to debug vectorized version)
  %p2 = zeros(N, 8);
  %for n=1:N
  %    for m=1:8
  %        s = 0;
  %        for k=1:8
  %            s = s + (gmm.weights(1,k) * b(n, k));
  %        end
  %        p2(n, m) = gmm.weights(1,m) * b(n, m) / s;
  %    end
  %end
  
  %p(1:5,1:5)
  %p2(1:5,1:5)
  %maximum_diff = max(max(abs(p2 - p)))
  
  % b is going to be NxM
  % data is Nxd
  % cov is dxM
  
  % Maximization
  
  
end
