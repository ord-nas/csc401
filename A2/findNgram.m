function found = findNgram(ngram, ref)
    found = false;
    n = length(ngram);
    
    % Iterate over each reference sentence.
    for i=1:length(ref)
        eng = ref{i};
        % Now iterate over the n-grams in the reference. Skip SENTSTART/SENTEND tokens.
        for j=2:length(eng)-n
            % Now iterate over the reference n-gram and the translation n-gram in lock-step,
            % and check if they are equal.
            equal = true;
            for k=0:n-1
                if ~strcmp(ngram{1+k}, eng{j+k})
                    equal = false;
                    break;
                end
            end
            
            % If we made it through the entire n-gram, yay!
            if equal
                found = true;
                return;
            end
        end
    end
end
