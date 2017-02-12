
def parse_individual_sentences(tweet):
    def separate_word_and_pos(atom):
        parts = atom.split("/")
        # In general, our token may itself contain / characters, so there may be
        # more than two items in the "parts" list. The last item is always the
        # POS, and the rest form the word. We return a tuple of (word, POS):
        return ("/".join(parts[:-1]), parts[-1])
    # Return a list of lists of tuples.
    # output[i][j][0] represents the word in the ith sentence, jth token.
    # output[i][j][1] represents the POS in the ith sentence, jth token.
    return [map(separate_word_and_pos, line.split()) for line in tweet.split("\n")]

def parse(tweet):
    # Same as parse_individual_sentences, but all the sentences are combined
    # into a flat list of tokens.
    return sum(parse_individual_sentences(tweet), [])

def average(values):
    if not values:
        return 0 # No values; avoid division by zero
    else:
        # Otherwise compute average
        return float(sum(values)) / len(values)

def feat1(tweet):
    global first_person
    return sum([1 for (tok, pos) in parse(tweet) if tok in first_person])

def feat2(tweet):
    global second_person
    return sum([1 for (tok, pos) in parse(tweet) if tok in second_person])

def feat3(tweet):
    global third_person
    return sum([1 for (tok, pos) in parse(tweet) if tok in third_person])

def feat4(tweet):
    return sum([1 for (tok, pos) in parse(tweet) if pos == "CC"])

def feat5(tweet):
    return sum([1 for (tok, pos) in parse(tweet) if pos in ["VBD", "VBN"]])

def feat6(tweet):
    # First just count the single-word indicators of future
    count = sum([1 for (tok, pos) in parse(tweet) if tok in ["'ll", "will", "gonna"]])
    # Now count the going+to+VB form.
    # Need to treat sentences separately (since the entire three-word form must
    # all appear in the same sentence)
    for sentence in parse_individual_sentences(tweet):
        # Iterate over each possible three-word sequence
        for i in xrange(0, len(sentence)-2):
            if (sentence[i][0] == "going" and
                sentence[i+1][0] == "to" and
                sentence[i+2][1] == "VB"):
                count += 1
    return count

def feat7(tweet):
    # We choose to count commas that are part of double punctuation
    # (e.g. ..., ). Also, double commas count twice (e.g. ,, counts as two
    # commas).
    return sum([tok.count(",") for (tok, pos) in parse(tweet)])

def feat8(tweet):
    # Similar to above, we count these even if they are part of double
    # punctuation.
    return sum([tok.count(":") + tok.count(";") for (tok, pos) in parse(tweet)])

def feat9(tweet):
    # Similar to above, we count these even if they are part of double
    # punctuation (or hyphenated words).
    return sum([tok.count("-") for (tok, pos) in parse(tweet)])

def feat10(tweet):
    # Similar to above, we count these even if they are part of double
    # punctuation. We only count () parentheses (not square brackets [] or angle
    # brackets <>).
    return sum([tok.count("(") + tok.count(")") for (tok, pos) in parse(tweet)])

def feat11(tweet):
    # We will say that an ellipses is a *single* token consisting of *3 or more*
    # periods.
    return sum([1 for (tok, pos) in parse(tweet)
                if len(tok) >= 3 and all([c == "." for c in tok])])

def feat12(tweet):
    return sum([1 for (tok, pos) in parse(tweet) if pos in ["NN", "NNS"]])

def feat13(tweet):
    return sum([1 for (tok, pos) in parse(tweet) if pos in ["NNP", "NNPS"]])

def feat14(tweet):
    return sum([1 for (tok, pos) in parse(tweet) if pos in ["RB", "RBR", "RBS"]])

def feat15(tweet):
    return sum([1 for (tok, pos) in parse(tweet) if pos in ["WDT", "WP", "WP$", "WRB"]])

def feat16(tweet):
    global slang
    return sum([1 for (tok, pos) in parse(tweet) if tok in slang])

def feat17(tweet):
    return sum([1 for (tok, pos) in parse(tweet) if len(tok) >= 2 and tok.isupper()])

def feat18(tweet):
    sentence_lengths = [len(s) for s in parse_individual_sentences(tweet)]
    return average(sentence_lengths)

def feat19(tweet):
    # Punctuation tokens have non-alphabetic POS, so we can filter them out
    # using .isalpha()
    token_lengths = [len(tok) for (tok, pos) in parse(tweet) if tok.isalpha()]
    return average(token_lengths)

def feat20(tweet):
    return len(parse_individual_sentences(tweet))

def read_word_list(filename):
    with open(filename, "r") as f:
        return [line.strip().lower() for line in f.readlines() if line.strip() != ""]
        
def main(args):
    global first_person, second_person, third_person, slang
    
    if len(args) not in [3, 4]:
        print "Usage: python buildarff.py input_file.twt output_file.arff [num_data_points]"
        return

    input_file = args[1]
    output_file = args[2]
    num_data_points = args[3] if len(args) == 4 else None

    # Read word lists
    first_person = read_word_list("First-person")
    second_person = read_word_list("Second-person")
    third_person = read_word_list("Third-person")
    slang = read_word_list("Slang")
            
if __name__ == "__main__":
    main(sys.argv)
