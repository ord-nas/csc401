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
  
  %gmm.cov = rand(d, M) * 10; % Start with a big variance so that our
  %                           % likelihoods don't vanish
  gmm.cov = ones(d, M);
  %gmm.cov = zeros(d,d,M);
  %for m=1:M
  %    gmm.cov(:,:,m) = diag(rand(1,d));
  %end

  % Do EM algorithm
  previous_L = -Inf;
  for iter=1:max_iter
      %disp('WEIGHTS');
      %disp(gmm.weights);
      %disp('MEANS');
      %disp(gmm.means);
      %disp('COV');
      %disp(gmm.cov);
      [gmm, L] = em_step(gmm, data);
      %disp(L);
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
  %disp('LOG_B');
  %disp(log_b);
  %size(b);

  % Straight-forward loopy implementation
  % (used to debug vectorized version)
  %log_b2 = zeros(N, 8);
  %for n=1:N
  %    for m=1:8
  %        s = 0;
  %        for i=1:d
  %            term = (data(n, i) - gmm.means(i, m)).^2 ./ ...
  %                   (2.* gmm.cov(i, m));
  %            s = s + term;
  %        end
  %        p = 1;
  %        for i=1:d
  %            term = gmm.cov(i, m);
  %            p = p * term;
  %        end
  %        log_b2(n, m) = -s - (d./2.*log(2.*pi)) - (1/2*log(p));
  %    end
  %end
  %b2 = exp(log_b2);
  
  %log_b(1:5,1:5)
  %log_b2(1:5,1:5)
  %maximum_diff = max(max(abs(log_b2 - log_b)))
  %b = exp(log_b);
  %b(1:5,1:5)
  wb_product = bsxfun(@plus, log(gmm.weights), log_b);
  log_p = bsxfun(@minus, wb_product, logsumexp(wb_product, 2));
  p = exp(log_p);
  %disp('LOG_P');
  %disp(log_p);
  
  L = sum(logsumexp(wb_product, 2));
  %L_ref = sum(logsumexp_ref(wb_product, 2))
  %diff = abs(L - L_ref)
  
  % Straight-forward loopy implementation
  %L2 = 0;
  %for n=1:N
  %    s = 0;
  %    for m=1:8
  %        s = s + gmm.weights(1,m) * b2(n, m);
  %    end
  %    L2 = L2 + log(s);
  %end
  %L2
  
  
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
  sum_p = sum(p, 1);
  gmm.weights = sum_p ./ N;
  gmm.means = bsxfun(@rdivide, data' * p, sum_p);
  gmm.cov = bsxfun(@rdivide, (data.^2)' * p, sum_p) - ...
            (gmm.means.^2);
  
  % Straight-forward loopy implementation
  %weights = zeros(1, 8);
  %for i=1:8
  %    s = 0;
  %    for t=1:N
  %        s = s + p(t, i);
  %    end
  %    weights(1, i) = s / N;
  %end
  %means = zeros(d, 8);
  %for i=1:8
  %    s = 0;
  %    for t=1:N
  %        s = s + p(t, i);
  %    end
  %    for j=1:d
  %        x = 0;
  %        for t=1:N
  %            x = x +  p(t, i) * data(t, j);
  %        end
  %        means(j, i) = x / s;
  %    end
  %end
  %cov = zeros(d, 8);
  %for i=1:8
  %    s = 0;
  %    for t=1:N
  %        s = s + p(t, i);
  %    end
  %    for j=1:d
  %        x = 0;
  %        for t=1:N
  %            x = x + p(t, i) * (data(t, j).^2);
  %        end
  %        cov(j, i) = x / s - (means(j, i).^2);
  %    end
  %end
  
  %disp('WEIGHTS');
  %disp(gmm.weights);
  %disp(weights);
  %max_diff = max(max(abs(gmm.weights - weights)))
  
  %disp('MEANS');
  %disp(gmm.means(1:5,1:5));
  %disp(means(1:5,1:5));
  %max_diff = max(max(abs(gmm.means - means)))
  
  %disp('COV');
  %disp(gmm.cov(1:5,1:5));
  %disp(cov(1:5,1:5));
  %max_diff = max(max(abs(gmm.cov - cov)))
  %aweffawefawfawefawef;
  
  %p is nxm
  %data is nxd
  %we want dxm
  
end
