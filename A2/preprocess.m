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
  
  % commas, colons and semicolons, parentheses, dashes between parentheses, mathematical operators (e.g., +, -, <, >, =), and quotation marks

  % perform language-agnostic changes
  % TODO: your code here
  %    e.g., outSentence = regexprep( outSentence, 'TODO', 'TODO');
  outSentence = regexprep( outSentence, '([,:;()+<>=*/"])', ' $1 ');
%   outSentence = regexprep( outSentence, ':', ' : ');
%   outSentence = regexprep( outSentence, ';', ' ; ');
%   outSentence = regexprep( outSentence, '(', ' ( ');
%   outSentence = regexprep( outSentence, ')', ' ) ');
%   outSentence = regexprep( outSentence, '+', ' + ');
%   outSentence = regexprep( outSentence, '<', ' < ');
%   outSentence = regexprep( outSentence, '>', ' > ');
%   outSentence = regexprep( outSentence, '=', ' = ');
%   outSentence = regexprep( outSentence, '*', ' * ');
%   outSentence = regexprep( outSentence, '/', ' / ');
%   outSentence = regexprep( outSentence, '"', ' " ');
  
  % NOTE: does not properly handle nested parens
  outSentence = regexprep( outSentence, '(\([^)]*[^0-9)]\s*)-(\s*[^0-9])', '$1 - $2');
  
  outSentence = regexprep( outSentence, '([.?!]+)(\s*"?\s*SENTEND$)', ' $1 $2');

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

