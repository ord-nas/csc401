function bestHyp = decodeAstar( french, LM, AM, lmtype, delta, vocabSize )
%
%  decodeAstar
%
%
%  This function returns an approximation of an english sentence given a
%  french sentence, a language model of english, and the alignment model
%
%  INPUTS:
%
%       french    : (string) a preprocessed french sentence
%       LM        : a language model of english as defined in lm_train.m      
%       AM        : an alignment model of french given english as defined
%       in align_ibm1.m  
%       lmtype    : (string) either '' (default) or 'smooth' for
%       add-delta smoothing 
%       delta     : (float) smoothing parameter where 0<delta<=1 
%       vocabSize : (integer) the number of words in the vocabulary
%
% 
% (c) 2011 Frank Rudzicz (feel free to modify this)

global CSC401_A2_DEFNS

N        = 5;    % the maximum number of translations for each word in
                 % the sentence
MAXTRANS = 128; % the maximum number of greedy transformations we perform 
NUMSWAPS = 2;    % the number of random re-orderings of the words


% some rudimentary parameter checking
if (nargin < 4)
  disp( 'lm_prob takes at least 4 parameters');
  return;
elseif nargin == 4
  lmtype = '';
  delta = 0;
  vocabSize = length(fieldnames(LM.uni));
end
if (isempty(lmtype))
  delta = 0;
  vocabSize = length(fieldnames(LM.uni));
elseif strcmp(lmtype, 'smooth')
  if (nargin < 6)  
    disp( ['lm_prob: if you specify smoothing, you need all 5' ...
	   ' parameters']);
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

% We assume that the english sentence has as many words as the french
% sentence 

frenchWords  = strsplit(' ', french );
frenchWords  = frenchWords(2:end-1); % strip of SENTSTART/SENTEND
englishWords = cell(N, length(frenchWords));
scores       = zeros(N, length(frenchWords));

% get english vocabulary, minus start and end tags
SS = AM.( CSC401_A2_DEFNS.SENTSTART );
SE = AM.( CSC401_A2_DEFNS.SENTEND );
AM = rmfield(AM, CSC401_A2_DEFNS.SENTSTART );
AM = rmfield(AM, CSC401_A2_DEFNS.SENTEND );
VE = fieldnames(AM);
AM.(CSC401_A2_DEFNS.SENTSTART ) = SS;
AM.(CSC401_A2_DEFNS.SENTEND ) = SE;

MX = 0;
for iew=1:length(VE)
  if isfield(LM.uni, VE{iew}),
    MX = MX+ LM.uni.( VE{iew} );
  end
end
%disp(MX);

tmpScoresEngGivenFre = zeros(length(VE), 1);
tmpScoresFreGivenEng = zeros(length(VE), 1);

% determine the best N translations for each french word on a
% word-by-word basis 
for ifw=1:length(frenchWords)
  for iew=1:length(VE)
    if (isfield(AM, VE{iew}) && isfield(LM.uni, VE{iew}) && isfield(AM.(VE{iew}), (frenchWords{ifw})))
      tmpScoresEngGivenFre(iew) = log2(AM.(VE{iew}).(frenchWords{ifw}))+log2( ...
	  LM.uni.(VE{iew})) - log2(MX );
      tmpScoresFreGivenEng(iew) = log2(AM.(VE{iew}).(frenchWords{ifw}));
    else
      tmpScoresEngGivenFre(iew) = -Inf;
      tmpScoresFreGivenEng(iew) = -Inf;
    end
  end

  [b,ind] = sort(tmpScoresEngGivenFre, 'descend');
  scores(:,ifw) = tmpScoresFreGivenEng(ind(1:N));
  englishWords(:,ifw) = VE(ind(1:N));
  % disp('start');
  % disp(b(1:N));
  % disp(scores);
  % disp('end');
end
%disp(scores);
%disp(size(scores));
%disp(englishWords);

% indices 
wordInd = ones(1, length(frenchWords));
order   = 1:length(frenchWords);

% initial best guess
bestHyp = ['SENTSTART ' cell2string(englishWords(1,order)) ' SENTEND'];
p_bestHyp = lm_prob( bestHyp, LM, lmtype, delta, vocabSize ) + ...
    sum(scores(1,order));

%disp(scores(1,order));
%disp(bestHyp);
%disp(p_bestHyp);

iter = 1;
while (iter < MAXTRANS )

  % pick a new collection of words
  for ifw=1:length(frenchWords)
    wordInd( ifw ) = ceil(N.*rand(1));
  end

  % pick a new order for the words
  order = 1:length(frenchWords);
  for i=1:NUMSWAPS
    r = ceil((length(frenchWords)-1).*rand(1));
    
    tmp        = order( r );
    order(r)   = order( r+1 );
    order(r+1) = tmp;

  end

  % evaluate
  %  newHyp = cell2string(diag(englishWords(wordInd,order)));
  eng_words_mat = englishWords(wordInd,order);
  newHyp = ['SENTSTART ' cell2string(eng_words_mat(1:length(eng_words_mat)+1:end)) ' SENTEND'];
  
  p_newHyp = lm_prob( newHyp, LM, lmtype, delta, vocabSize )+ ...
      sum(diag(scores(wordInd,order)));
  %disp(wordInd);
  %disp(order);
  %disp(eng_words_mat);
  %disp(newHyp);
  %disp(newHyp);
  %disp(p_newHyp);
  %disp(lm_prob( newHyp, LM, lmtype, delta, vocabSize ));
  %disp(scores(wordInd,order));

  if p_newHyp > p_bestHyp
    p_bestHyp = p_newHyp;
    bestHyp = newHyp;
  end

  iter = iter + 1;
end

% disp(p_bestHyp);
% disp(bestHyp);


return


function eSen = cell2string( c )
  eSen = '';
  for i=1:length(c)
    eSen = [eSen, c{i}, ' '];
  end
  eSen = eSen(1:(end-1));
  return
