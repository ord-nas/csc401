function [SE IE DE LEV_DIST] = Levenshtein(hypothesis,annotation_dir)
% Input:
%	hypothesis: The path to file containing the the recognition hypotheses
%	annotation_dir: The path to directory containing the annotations
%			(Ex. the Testing dir containing all the *.txt files)
% Outputs:
%	SE: proportion of substitution errors over all the hypotheses
%	IE: proportion of insertion errors over all the hypotheses
%	DE: proportion of deletion errors over all the hypotheses
%	LEV_DIST: proportion of overall error in all hypotheses

  % First parse the hypothesis file
  lines = textread(hypothesis, '%s', 'delimiter', '\n');
  N = length(lines);
  for i=1:N
      words = strsplit(' ', lines{i});
      assert(length(words) > 2);
      % Ignore the start/stop indices at the beginning of the line
      words = words(3:end);
      % Strip punctuation from the beginning and end of each word
      for w=1:length(words)
          words{w} = regexprep(words{w}, '^[,:;()+<>=*/"!?.]', '');
          words{w} = regexprep(words{w}, '[,:;()+<>=*/"!?.]$', '');
          words{w} = lower(words{w});
      end
      predicted{i} = words;
  end
  
  % Next parse the actual transcriptions
  for i=1:N
      file = [annotation_dir, filesep, 'unkn_', num2str(i), '.txt'];
      lines = textread(file, '%s', 'delimiter', '\n');
      words = strsplit(' ', lines{1});
      % Ignore the start/stop indices at the beginning of the line
      words = words(3:end);
      % Strip punctuation from the beginning and end of each word
      for w=1:length(words)
          words{w} = regexprep(words{w}, '^[,:;()+<>=*/"!?.]', '');
          words{w} = regexprep(words{w}, '[,:;()+<>=*/"!?.]$', '');
          words{w} = lower(words{w});
      end
      actual{i} = words;
  end
  
  % Initialize counters
  SE = 0;
  IE = 0;
  DE = 0;
  ref_words = 0;
  
  % Now do the actual distance computation
  for i=1:N
      [sub, ins, del] = getLevenshteinDistance(actual{i}, predicted{i});
      SE = SE + sub;
      IE = IE + ins;
      DE = DE + del;
      ref_words = ref_words + length(actual{i});
      fprintf('Reference : %s\n', join(actual{i}, ' '));
      fprintf('Hypothesis: %s\n', join(predicted{i}, ' '));
      fprintf('  sub = %d, ins = %d, del = %d\n', sub, ins, del);
  end
  
  % Now find the final proportions
  SE = SE / ref_words;
  IE = IE / ref_words;
  DE = DE / ref_words;
  LEV_DIST = SE + IE + DE;
end

function output = join(cells, joiner)
  output = cells{1};
  for i=2:length(cells)
      output = [output, joiner, cells{i}];
  end
end
