function M = logsumexp(X, dim)
    max_vals = max(X, [], dim);
    difference = bsxfun(@minus, X, max_vals);
    M = max_vals + log(sum(exp(difference), dim));
end