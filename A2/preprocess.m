function outSentence = preprocess( inSentence, language )
%
%  preprocess
%
%  This function preprocesses the input text according to language-specific rules.
%  Specifically, we separate contractions according to the source language, convert
%  all tokens to lower-case, and separate end-of-sentence punctuation 
%
%  INPUTS:
%       inSentence     : (string) the original sentence to be processed 
%                                 (e.g., a line from the Hansard)
%       language       : (string) either 'e' (English) or 'f' (French) 
%                                 according to the language of inSentence
%
%  OUTPUT:
%       outSentence    : (string) the modified sentence
%
%  Template (c) 2011 Frank Rudzicz 

  global CSC401_A2_DEFNS
  
  % first, convert the input sentence to lower-case and add sentence marks 
  inSentence = [CSC401_A2_DEFNS.SENTSTART ' ' lower( inSentence ) ' ' CSC401_A2_DEFNS.SENTEND];

  % initialize outSentence
  outSentence = inSentence;

  % perform language-agnostic changes

  % Separate a bunch of special characters
  outSentence = regexprep( outSentence, '([,:;()+<>=*/"])', ' $1 ');
  
  % Handle dashes inside parens. This code correctly handles nested
  % parentheses (although that's almost certainly overkill).
  overall = ''; % Our post-processed sentence, so far
  currentParenGroup = '';
  parenLevel = 0;
  for i=1:length(outSentence)
      if outSentence(i) == '('
          parenLevel = parenLevel + 1;
      elseif outSentence(i) == ')'
          parenLevel = parenLevel - 1;
          % If we just left a parenthesized statement ...
          if parenLevel == 0
              % Then take the parenthesized group of words, separate hyphens,
              % concatenate it onto the overall result.
              overall = [overall, regexprep( currentParenGroup, '-', ' - ')];
              currentParenGroup = '';
          elseif parenLevel == -1
              % Ignore unmatched parens
              parenLevel = 0;
          end
      end
      % Now attach the current character to the end of the appropriate
      % string.
      if parenLevel > 0
          % If we're inside parentheses, add to currentParenGroup
          currentParenGroup = [ currentParenGroup outSentence(i) ];
      else
          % Otherwise, we can directly add to the overall result
          overall = [ overall outSentence(i) ];
      end
  end
  % Handle unclosed parens
  overall = [overall, regexprep( currentParenGroup, '-', ' - ')];
  outSentence = overall;

  % Handle the subtraction operator ... assume that a dash must be directly
  % between two numerical characters to be considered subtraction.
  outSentence = regexprep( outSentence, '([0-9])-([0-9])', '$1 - $2');
  
  % Handle end-of-sentence punctuation
  % End-of-sentence punctuation is one (or more) of [.?!]
  % We also allow this punctuation to be followed by close brackets or close
  % quotes, in the case that the sentence ends with a quotation or a
  % parenthesized phrase.
  outSentence = regexprep( outSentence, '([.?!]+)([")\s]*SENTEND$)', ' $1 $2');

  switch language
   case 'e'
    % Separate clitics from words
    outSentence = regexprep( outSentence, '([a-z])''', '$1 ''');
    
    % Special handling for the n't clitic
    outSentence = regexprep( outSentence, 'n ''t\>', ' n''t');

   case 'f'
    % Handle l' and e-muet
    outSentence = regexprep( outSentence, '\<([cdjlmnst])''([a-z])', '$1'' $2');
    
    % But don't separate d'abord, d'accord, d'ailleurs, d'habitude
    outSentence = regexprep( outSentence, '\<d'' (abord|accord|ailleurs|habitude)\>', 'd''$1');
    
    % Handle qu'
    outSentence = regexprep( outSentence, '\<qu''([a-z])', 'qu'' $1');
    
    % Handle puisque or lorsque contractions
    outSentence = regexprep( outSentence, '\<(puisqu|lorsqu)''(il|on)\>', '$1'' $2');
  end
  
  % trim whitespaces down 
  outSentence = regexprep( outSentence, '\s+', ' '); 

  % change unpleasant characters to codes that can be keys in dictionaries
  outSentence = convertSymbols( outSentence );

