function LM = lm_train(dataDir, language, fn_LM)
%
%  lm_train
% 
%  This function reads data from dataDir, computes unigram and bigram counts,
%  and writes the result to fn_LM
%
%  INPUTS:
%
%       dataDir     : (directory name) The top-level directory containing 
%                                      data from which to train or decode
%                                      e.g., '/u/cs401/A2_SMT/data/Toy/'
%       language    : (string) either 'e' for English or 'f' for French
%       fn_LM       : (filename) the location to save the language model,
%                                once trained
%  OUTPUT:
%
%       LM          : (variable) a specialized language model structure  
%
%  The file fn_LM must contain the data structure called 'LM', 
%  which is a structure having two fields: 'uni' and 'bi', each of which holds
%  sub-structures which incorporate unigram or bigram COUNTS,
%
%       e.g., LM.uni.word = 5       % the word 'word' appears 5 times
%             LM.bi.word.bird = 2   % the bigram 'word bird' appears twice
% 
% Template (c) 2011 Frank Rudzicz

global CSC401_A2_DEFNS

LM=struct();
LM.uni = struct();
LM.bi = struct();

SENTSTARTMARK = 'SENTSTART'; 
SENTENDMARK = 'SENTEND';

DD = dir( [ dataDir, filesep, '*', language] );

disp([ dataDir, filesep, '.*', language] );

for iFile=1:length(DD)

  lines = textread([dataDir, filesep, DD(iFile).name], '%s','delimiter','\n');

  for l=1:length(lines)

    processedLine =  preprocess(lines{l}, language);
    words = strsplit(' ', processedLine );
    
    % TODO: THE STUDENT IMPLEMENTS THE FOLLOWING
    
    % Unigram counts
    for i=1:length(words)
        w = char(words(i));       
        if ~isfield(LM.uni, w)
            LM.uni.(w) = 0;
        end
        LM.uni.(w) = LM.uni.(w) + 1;
    end
    
    % Bigram counts
    for i=1:length(words)-1
        w1 = char(words(i));
        w2 = char(words(i+1));
        if ~isfield(LM.bi, w1)
            LM.bi.(w1) = struct();
        end
        if ~isfield(LM.bi.(w1), w2)
            LM.bi.(w1).(w2) = 0;
        end
        LM.bi.(w1).(w2) = LM.bi.(w1).(w2) + 1;
    end

    % TODO: THE STUDENT IMPLEMENTED THE PRECEDING
  end
end

save( fn_LM, 'LM', '-mat'); 