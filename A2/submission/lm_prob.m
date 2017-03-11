function logProb = lm_prob(sentence, LM, type, delta, vocabSize)
%
%  lm_prob
% 
%  This function computes the LOG probability of a sentence, given a 
%  language model and whether or not to apply add-delta smoothing
%
%  INPUTS:
%
%       sentence  : (string) The sentence whose probability we wish
%                            to compute
%       LM        : (variable) the LM structure (not the filename)
%       type      : (string) either '' (default) or 'smooth' for add-delta smoothing
%       delta     : (float) smoothing parameter where 0<delta<=1 
%       vocabSize : (integer) the number of words in the vocabulary
%
% Template (c) 2011 Frank Rudzicz

  logProb = 0;

  % some rudimentary parameter checking
  if (nargin < 2)
    disp( 'lm_prob takes at least 2 parameters');
    return;
  elseif nargin == 2
    type = '';
    delta = 0;
    vocabSize = 0;
  end
  if (isempty(type))
    delta = 0;
    vocabSize = 0;
  elseif strcmp(type, 'smooth')
    if (nargin < 5)  
      disp( 'lm_prob: if you specify smoothing, you need all 5 parameters');
      return;
    end
    if (delta <= 0) or (delta > 1.0)
      disp( 'lm_prob: you must specify 0 < delta <= 1.0');
      return;
    end
  else
    disp( 'type must be either '''' or ''smooth''' );
    return;
  end

  words = strsplit(' ', sentence);

  % TODO: the student implements the following
  % Iterate over all bigrams (i, i+1)
  for i=1:length(words)-1
      w1 = asFieldname(words(i));
      w2 = asFieldname(words(i+1));
      % Let's separately compute the numerator and denominator for our maximum
      % likelihood estimate.
      numerator = delta;
      if isfield(LM.bi, w1) && isfield(LM.bi.(w1), w2)
          numerator = numerator + LM.bi.(w1).(w2);
      end
      % Check if we've ever seen the ith word. If not, then even add-delta smoothing
      % cannot save us! The log probability for this sentence is -Inf.
      if ~isfield(LM.uni, w1)
          logProb = -Inf;
          return;
      end
      denominator = LM.uni.(w1) + (delta * vocabSize);
      % If we get here, the denominator is guarunteed to be non-zero, so we can
      % proceed without fear of division by zero.
      logProb = logProb + log2(numerator/denominator);
  end
return