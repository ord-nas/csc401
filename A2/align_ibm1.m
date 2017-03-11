function AM = align_ibm1(trainDir, numSentences, maxIter, fn_AM)
%
%  align_ibm1
% 
%  This function implements the training of the IBM-1 word alignment algorithm. 
%  We assume that we are implementing P(foreign|english)
%
%  INPUTS:
%
%       dataDir      : (directory name) The top-level directory containing 
%                                       data from which to train or decode
%                                       e.g., '/u/cs401/A2_SMT/data/Toy/'
%       numSentences : (integer) The maximum number of training sentences to
%                                consider. 
%       maxIter      : (integer) The maximum number of iterations of the EM 
%                                algorithm.
%       fn_AM        : (filename) the location to save the alignment model,
%                                 once trained.
%
%  OUTPUT:
%       AM           : (variable) a specialized alignment model structure
%
%
%  The file fn_AM must contain the data structure called 'AM', which is a 
%  structure of structures where AM.(english_word).(foreign_word) is the
%  computed expectation that foreign_word is produced by english_word
%
%       e.g., LM.house.maison = 0.5       % TODO
% 
% Template (c) 2011 Jackie C.K. Cheung and Frank Rudzicz
  
  global CSC401_A2_DEFNS
  
  AM = struct();
  
  % Read in the training data
  [eng, fre] = read_hansard(trainDir, numSentences);

  % Initialize AM uniformly 
  AM = initialize(eng, fre);

  % Iterate between E and M steps
  for iter=1:maxIter,
    fprintf('Iteration: %d\n', iter);
    AM = em_step(AM, eng, fre);
  end

  % Save the alignment model
  save( fn_AM, 'AM', '-mat'); 

  end





% --------------------------------------------------------------------------------
% 
%  Support functions
%
% --------------------------------------------------------------------------------

function [eng, fre] = read_hansard(mydir, numSentences)
%
% Read 'numSentences' parallel sentences from texts in the 'dir' directory.
%
% Important: Be sure to preprocess those texts!
%
% Remember that the i^th line in fubar.e corresponds to the i^th line in fubar.f
% You can decide what form variables 'eng' and 'fre' take, although it may be easiest
% if both 'eng' and 'fre' are cell-arrays of cell-arrays, where the i^th element of 
% 'eng', for example, is a cell-array of words that you can produce with
%
%         eng{i} = strsplit(' ', preprocess(english_sentence, 'e'));
%
  eng = cell(1,numSentences);
  fre = cell(1,numSentences);
  
  engFiles = dir( [ mydir, filesep, '*e'] );
  
  counter = 1;
  
  for iFile=1:length(engFiles)
      disp(iFile); % TODO REMOVE ME
      engName = engFiles(iFile).name;
      freName = [engName(1:end-1), 'f'];
      engLines = textread([mydir, filesep, engName], '%s','delimiter','\n');
      freLines = textread([mydir, filesep, freName], '%s','delimiter','\n');
      
      for l=1:length(engLines)
          eng{counter} = strsplit(' ', preprocess(engLines{l}, 'e'));
          fre{counter} = strsplit(' ', preprocess(freLines{l}, 'f'));
          counter = counter + 1;
          if counter > numSentences
              return
          end
      end
  end
end


function AM = initialize(eng, fre)
%
% Initialize alignment model uniformly.
% Only set non-zero probabilities where word pairs appear in corresponding sentences.
%
    AM = {}; % AM.(english_word).(foreign_word)
    
    % Now iterate over pairs of sentences:
    for i=1:length(eng)
        E = eng{i};
        F = fre{i};
        for j=2:length(E)-1 % Skip SENTSTART and SENTEND
            eWord = asFieldname(E(j));
            for k=2:length(F)-1 % Skip SENTSTART and SENTEND
                fWord = asFieldname(F(k));
                % First just put a placeholder value in the alignment model
                AM.(eWord).(fWord) = 1.0;
            end
        end
    end
    
    % Now go over the alignment model and actually compute the correct
    % probabilities
    engVocab=fieldnames(AM);
    for i=1:length(engVocab)
        eWord = asFieldname(engVocab(i));
        freMatches = fieldnames(AM.(eWord));
        for j=1:length(freMatches)
            fWord = asFieldname(freMatches(j));
            % Unifromly assign probability to each french word that
            % potentially matches the given english word
            AM.(eWord).(fWord) = 1.0 / length(freMatches);
        end
    end
    
    % Known probabilities
    AM.SENTSTART.SENTSTART = 1.0;
    AM.SENTEND.SENTEND = 1.0;
end

function t = em_step(t, eng, fre)
    tcount = struct();
    total = struct();
    for i=1:length(eng)
        E = eng{i}(2:end-1); % Skip SENTSTART/SENTEND
        F = fre{i}(2:end-1); % Skip SENTSTART/SENTEND
        [uniqueF, ~, mapping] = unique(F);
        countsF = hist(mapping, length(uniqueF));
        [uniqueE, ~, mapping] = unique(E);
        countsE = hist(mapping, length(uniqueE));
        for j=1:length(uniqueF)
            f = asFieldname(uniqueF(j));
            denominator = 0;
            for k=1:length(uniqueE)
                e = asFieldname(uniqueE(k));
                denominator = denominator + t.(e).(f) * countsF(j);
            end
            for k=1:length(uniqueE)
                e = asFieldname(uniqueE(k));
                % update tcount
                prev = 0;
                if isfield(tcount, e) && isfield(tcount.(e), f)
                    prev = tcount.(e).(f);
                end
                tcount.(e).(f) = prev + t.(e).(f) * countsF(j) * countsE(k) / denominator;
                
                % update total
                prev = 0;
                if isfield(total, e)
                    prev = total.(e);
                end
                total.(e) = prev + t.(e).(f) * countsF(j) * countsE(k) / denominator;
            end
        end
    end
    engVocab = fieldnames(t);
    for i=1:length(engVocab)
        e = asFieldname(engVocab(i));
        if strcmp(e, 'SENTSTART') || strcmp(e, 'SENTEND')
            continue
        end
        freMatches = fieldnames(t.(e));
        for j=1:length(freMatches)
            f = asFieldname(freMatches(j));
            t.(e).(f) = tcount.(e).(f) / total.(e);
        end
    end
end


