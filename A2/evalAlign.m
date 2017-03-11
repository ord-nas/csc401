%
% evalAlign
%
%  This is simply the script (not the function) that you use to perform your evaluations in 
%  Task 5. 

% some of your definitions
french          = '/u/cs401/A2_SMT/data/Hansard/Testing/Task5.f';
english_hansard = '/u/cs401/A2_SMT/data/Hansard/Testing/Task5.e';
english_google  = '/u/cs401/A2_SMT/data/Hansard/Testing/Task5.google.e';
fn_LME          = 'models/LM_e/v0.mat';
fn_LMF          = 'models/LM_f/v0.mat';
fn_AM           = 'models/AM/10000_sentences_10_iters.mat';
lm_type         = '';
delta           = 0;
vocabSize       = 0;
N               = 2; % Highest-order n-gram to use in BLEU score.

% Load pre-trained language models. This is task 2 which makes use of task 1
load(fn_LME, 'LM', '-mat');
LME = LM;
load(fn_LMF, 'LM', '-mat');
LMF = LM;

% Load alignment model of French, given English 
load(fn_AM, 'AM', '-mat');
AMFE = AM;

% Clear out some memory
clear LM;
clear AM;

french_lines = textread(french, '%s','delimiter','\n');
english_hansard_lines = textread(english_hansard, '%s','delimiter','\n');
english_google_lines = textread(english_google, '%s','delimiter','\n');

for i=1:length(french_lines)
    fre_raw = preprocess(french_lines{i}, 'f');
    fre = strsplit(' ', fre_raw);
    hansard_raw = preprocess(english_hansard_lines{i}, 'e');
    ref{1} = strsplit(' ', hansard_raw);
    google_raw = preprocess(english_google_lines{i}, 'e');
    ref{2} = strsplit(' ', google_raw);
    translation_raw = decode2(fre_raw, LME, AMFE, lm_type, delta, vocabSize);
    translation = strsplit(' ', translation_raw);
    
    fprintf('Original:%s\nHansard:%s\nGoogle:%s\nTranslation:%s\n\n', ...
	    fre_raw, hansard_raw, google_raw, translation_raw);

    % Compute BLEU scores
    
    % First compute the n-gram scores. As per Piazza, we are not implementing
    % capping.
    ngram_score = 1;
    for n=1:N
        % Iterate over all n-grams in translation. Skip SENTSTART/SENTEND tokens.
        matches = 0;
        for i=2:length(translation)-n
            % Now check if the n-gram exists in any of the refs.
            if findNgram(translation(i:i+n-1), ref)
                matches = matches + 1;
            end
        end
        
        num_ngrams = length(translation) - n - 1;
        score = matches / num_ngrams;
        fprintf('%d-gram score: %d / %d = %f\n', n, matches, num_ngrams, score);
        ngram_score = ngram_score * score;
    end
    
    % Now compute the brevity score. First find the reference sentence whose length
    % matches the candidate most closely.
    ref_length = length(ref{1}); % So far, this is the length that is closest to the
                                 % translation length.
    for i=2:length(ref)
        difference_sofar = abs(ref_length - length(translation));
        current_difference = abs(length(ref{i}) - length(translation));
        if current_difference < difference_sofar
            ref_length = length(ref{i});
        elseif current_difference == difference_sofar
            % If there is a tie in closeness, break it in favour of the shorter
            % sentence. This is more forgiving to our candidate translation, and
            % should result in higher BLEU scores.
            ref_length = min(ref_length, length(ref{i}));
        end
    end
    fprintf('Trans: %d, ref1: %d, ref2: %d, closest: %d\n', ...
            length(translation), length(ref{1}), length(ref{2}), ref_length);
    
    % Compute brevity and the brevity penalty, remembering to remove
    % SENTSTART/SENTEND from the length counts.
    brevity = (ref_length - 2) / (length(translation) - 2);
    penalty = 1;
    if brevity > 1
        penalty = exp(1-brevity);
    end
    fprintf('Brevity: %d / %d = %f, penalty: %f\n', ref_length-2, ...
            length(translation)-2, brevity, penalty);
    
    % Compute final BLEU score
    bleu = penalty * (ngram_score.^N);
    
    fprintf('Bleu: %f\n\n', bleu);
end
