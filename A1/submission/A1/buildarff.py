import re
import sys
import os

word_lists_dir = "/u/cs401/Wordlists" # alternatively, "" if running
                                      # on home computer.

arff_header = """@relation tweet_polarity

@attribute first_person numeric
@attribute second_person numeric
@attribute third_person numeric
@attribute coordinating_conjuctions numeric
@attribute past_tense numeric
@attribute future_tense numeric
@attribute commas numeric
@attribute colons numeric
@attribute dashes numeric
@attribute parens numeric
@attribute ellipses numeric
@attribute common_nouns numeric
@attribute proper_nouns numeric
@attribute adverbs numeric
@attribute wh_words numeric
@attribute slag numeric
@attribute uppercase numeric
@attribute sentence_length numeric
@attribute token_length numeric
@attribute num_sentences numeric
@attribute class {0, 4}

@data
"""

def parse_individual_sentences(tweet, keep_case=False):
    def separate_word_and_pos(atom):
        parts = atom.split("/")
        # In general, our token may itself contain / characters, so there may be
        # more than two items in the "parts" list. The last item is always the
        # POS, and the rest form the word. We return a tuple of (word, POS):
        word = "/".join(parts[:-1])
        if not keep_case:
            word = word.lower()
        pos = parts[-1]
        return (word, pos)
    # Return a list of lists of tuples.
    # output[i][j][0] represents the word in the ith sentence, jth token.
    # output[i][j][1] represents the POS in the ith sentence, jth token.
    return [map(separate_word_and_pos, line.split()) for line in tweet.split("\n") if line]

def parse(tweet, keep_case=False):
    # Same as parse_individual_sentences, but all the sentences are combined
    # into a flat list of tokens.
    return sum(parse_individual_sentences(tweet, keep_case), [])

def average(values):
    if not values:
        return 0 # No values; avoid division by zero
    else:
        # Otherwise compute average
        return float(sum(values)) / len(values)

# First person pronouns
def feat1(tweet):
    global first_person
    return sum(1 for (tok, pos) in parse(tweet) if tok in first_person)

# Second person pronouns
def feat2(tweet):
    global second_person
    return sum(1 for (tok, pos) in parse(tweet) if tok in second_person)

# Third person pronouns
def feat3(tweet):
    global third_person
    return sum(1 for (tok, pos) in parse(tweet) if tok in third_person)

# Coordinating conjunctions
def feat4(tweet):
    return sum(1 for (tok, pos) in parse(tweet) if pos == "CC")

# Past-tense verbs
# TODO: in the second tutorial, makes it seem like we need to do something
# different here ...
def feat5(tweet):
    return sum(1 for (tok, pos) in parse(tweet) if pos in ["VBD", "VBN"])

# Future-tense verbs
def feat6(tweet):
    # First just count the single-word indicators of future
    count = sum(1 for (tok, pos) in parse(tweet) if tok in ["'ll", "will", "gonna"])
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

# Commas
def feat7(tweet):
    # We choose to count commas that are part of double punctuation
    # (e.g. ..., ). Also, double commas count twice (e.g. ,, counts as two
    # commas).
    return sum(tok.count(",") for (tok, pos) in parse(tweet))

# Colons and semi-colons
def feat8(tweet):
    # Similar to above, we count these even if they are part of double
    # punctuation.
    return sum(tok.count(":") + tok.count(";") for (tok, pos) in parse(tweet))

# Dashes
def feat9(tweet):
    # Similar to above, we count these even if they are part of double
    # punctuation (or hyphenated words).
    return sum(tok.count("-") for (tok, pos) in parse(tweet))

# Parentheses
def feat10(tweet):
    # Similar to above, we count these even if they are part of double
    # punctuation. We only count () parentheses (not square brackets [] or angle
    # brackets <>).
    return sum(tok.count("(") + tok.count(")") for (tok, pos) in parse(tweet))

# Ellipses
def feat11(tweet):
    # We will say that an ellipses is a *single* token consisting of *3 or more*
    # periods.
    return sum(1 for (tok, pos) in parse(tweet)
               if len(tok) >= 3 and all(c == "." for c in tok))

# Common nouns
def feat12(tweet):
    return sum(1 for (tok, pos) in parse(tweet) if pos in ["NN", "NNS"])

# Proper nouns
def feat13(tweet):
    return sum(1 for (tok, pos) in parse(tweet) if pos in ["NNP", "NNPS"])

# Adverbs
def feat14(tweet):
    return sum(1 for (tok, pos) in parse(tweet) if pos in ["RB", "RBR", "RBS"])

# wh-words
def feat15(tweet):
    return sum(1 for (tok, pos) in parse(tweet) if pos in ["WDT", "WP", "WP$", "WRB"])

# Modern slang acronyms
def feat16(tweet):
    global slang
    return sum(1 for (tok, pos) in parse(tweet) if tok in slang)

# Words in all uppercase
def feat17(tweet):
    return sum(1 for (tok, pos) in parse(tweet, keep_case=True)
               if len(tok) >= 2 and tok.isupper())

# Average length of sentences
def feat18(tweet):
    sentence_lengths = [len(s) for s in parse_individual_sentences(tweet)]
    return average(sentence_lengths)

# Average length of tokens, excluding punctuation tokens
def feat19(tweet):
    # Punctuation tokens have non-alphabetic POS, so we can filter them out
    # using .isalpha()
    token_lengths = [len(tok) for (tok, pos) in parse(tweet) if pos.isalpha()]
    return average(token_lengths)

# Number of sentences
def feat20(tweet):
    return len(parse_individual_sentences(tweet))

def read_word_list(filename):
    path = os.path.join(word_lists_dir, filename)
    with open(path, "r") as f:
        return [line.strip().lower() for line in f.readlines() if line.strip() != ""]

def extract_features(tweet, polarity):
    # Get the feature-extracting functions
    feat_fns = [globals()["feat%d" % i] for i in xrange(1, 21)]
    # Return a comma-separated list of features + polarity
    features = [f(tweet) for f in feat_fns] + [polarity]
    return ",".join(map(str, features))

def main(args):
    global first_person, second_person, third_person, slang

    if len(args) not in [3, 4]:
        print "Usage: python buildarff.py input_file.twt output_file.arff [max_per_class]"
        return

    input_file = args[1]
    output_file = args[2]
    max_per_class = int(args[3]) if len(args) == 4 else float('inf')

    # Read word lists
    first_person = read_word_list("First-person")
    second_person = read_word_list("Second-person")
    third_person = read_word_list("Third-person")
    slang = read_word_list("Slang")

    with open(input_file, "r") as in_file, \
         open(output_file, "w") as out_file:
        # Header
        out_file.write(arff_header)

        # Extract features from tweets and write to arff file.
        class_counts = {}
        tweet = ""
        polarity = None
        for line in in_file:
            # Check for a marker indicating a new tweet ...
            m = re.match("^<A=([0-9]+)>\n$", line)
            if m:
                # Check that we haven't exceeded the maximum number of tweets of
                # this polarity
                if tweet and class_counts.get(polarity, 0) < max_per_class:
                    # Extract features from the current tweet and write to the
                    # arff file.
                    assert polarity is not None
                    arff_line = extract_features(tweet, polarity)
                    out_file.write(arff_line + "\n")
                    class_counts[polarity] = class_counts.get(polarity, 0) + 1
                # Prepare for the next tweet
                tweet = ""
                polarity = int(m.group(1))
            else:
                # Otherwise, add this line to current tweet
                tweet += line
        # At the end, process the last tweet if applicable
        if tweet and class_counts.get(polarity, 0) < max_per_class:
            # Extract features from the current tweet and write to the
            # arff file.
            assert polarity is not None
            arff_line = extract_features(tweet, polarity)
            out_file.write(arff_line + "\n")
            class_counts[polarity] = class_counts.get(polarity, 0) + 1


if __name__ == "__main__":
    main(sys.argv)