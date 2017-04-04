function [SE IE DE] = getLevenshteinDistance(ref, hyp)
  SE = 0;
  IE = 0;
  DE = 0;

  n = length(ref);
  m = length(hyp);
  dist = zeros(n, m);
  backtrace = zeros(n, m); % 1 -> delete
                           % 2 -> insert
                           % 3 -> substitution/no-error
  for i=1:n
      for j=1:m
          del = getDist(dist, i-1, j) + 1;
          if strcmp(ref{i}, hyp{j})
              sub = getDist(dist, i-1, j-1);
          else
              sub = getDist(dist, i-1, j-1) + 1;
          end
          ins = getDist(dist, i, j-1) + 1;
          dist(i, j) = min([del, sub, ins]);
          if dist(i, j) == del
              backtrace(i, j) = 1;
          elseif dist(i, j) == ins
              backtrace(i, j) = 2;
          else
              backtrace(i, j) = 3;
          end
      end
  end
  
  % Follow backtrace
  i = n;
  j = m;
  while i > 0 || j > 0
      error = getBacktrace(backtrace, i, j);
      if error == 1
          DE = DE + 1;
          i = i - 1;
      elseif error == 2
          IE = IE + 1;
          j = j - 1;
      else 
          if ~strcmp(ref{i}, hyp{j})
              SE = SE + 1;
          end
          i = i - 1;
          j = j - 1;
      end
  end
end

% Helper function to index into the distance matrix R, which handles the
% boundary conditions of i == 0 and/or j == 0
function d = getDist(R, i, j)
  if i == 0 || j == 0
      d = i + j;
  else
      d = R(i, j);
  end
end

% Helper function to index into the backtrace matrix B, which handles the
% boundary conditions of i == 0 and/or j == 0
function error = getBacktrace(B, i, j)
  if i == 0
      error = 2; % insertion error
  elseif j == 0
      error = 1; % deletion error
  else
      error = B(i, j);
  end
end
