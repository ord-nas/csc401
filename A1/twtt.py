import re
import sys
import itertools
import HTMLParser

import NLPlib

# Parse the comma-separated-values line and pull out the tweet and the
# polarity. Return a tuple of (tweet, polarity)
def extract_tweet_and_polarity(csv_line):
    # Note: we can't simple split on commas because commas can appear in tweets!
    m = re.match(r'^"([^,]*)","[^,]*","[^,]*","[^,]*","[^,]*","(.*)"$', csv_line)
    assert m
    return (m.group(2), int(m.group(1)))

# Remove html tags
def twtt1(tweet):
    # We use a slightly more complex regular expression than the one
    # provided in the handout so that we can handle cases where there is a
    # greater-than sign inside of an html attribute (which should not be
    # treated as the end of the html tag). For example:
    # <img onclick="alert('5 > 4');"/>
    #                        ^
    #                        This is *not* the end of the tag
    pattern = r"""<(?:[^>'"]|"[^"]*"|'[^']*')+>"""
    # Pattern is as follows:
    # <                    Match start of HTML tag
    # (?:                  Then match one or more of the following (in a
    #                      non-capturing group so that re.split won't keep it):
    # [^>'"]                   A character that *isn't* the end of the HTML
    #                          tag, and also *isn't* the beginning of a quoted
    #                          attribute
    # |                        OR
    # "[^"]*"                  An attribute surrounded by double quotes
    # |                        OR
    # '[^']*'                  An attribute surrounded by single quotes
    # )+                   (end of group ... match one or more of these)
    # >                    Finally, match the end of the tag
    return ''.join(re.split(pattern, tweet))

# Decode html character code
def twtt2(tweet):
    global html_parser
    # I had trouble just using python's built-in HTML unescape method on the
    # entire string; weird unicode errors. But if I just run it on pieces that
    # look like html escape sequences, seems fine.
    while True:
        m = re.search(r"(&[#A-Za-z0-9]+;)", tweet)
        if not m:
            break
        #print "ORIGINAL:", m.group(1)
        replacement = str(html_parser.unescape(m.group(1)))
        #print "REP:", replacement
        tweet = tweet[:m.start()] + replacement + tweet[m.end():]
    return tweet

# Remove tokens which begin with www or http
def twtt3(tweet):
    # Twitter actually looks for more than just a simple http or www to identify
    # URLs, but since the assignment specifically asks us to just look for
    # tokens starting http or www, we'll do that. However, we still need to
    # determine what counts as a token. In particular, what counts as the
    # *start* of a URL token, and what counts as the *end* of a URL token? To
    # answer this, we are going to try to roughly match Twitter's actual
    # behaviour - in other words, when Twitter creates a hyperlink in a tweet,
    # how does it determine wher the URL begins and ends?
    pattern = r"""\b(?:http|www)[^\s`^(){}<>\"]*[^\s`^(){}<>\".,!?\[\]~@$%&*|:;'"]"""
    # Pattern is as follows:
    # \b
    #                      Token must start on a word boundary
    # (?:http|www)
    #                      Then http or www (we put it in a non-capturing group
    #                      so that re.split won't keep it)
    # [^\s`^(){}<>\"]*
    #                      A URL can contain most characters except spaces and
    #                      a few special characters
    # [^\s`^(){}<>\".,!?\[\]~@$%&*|:;'"]
    #                      There are additional restrictions on what is allowed
    #                      to be the *last* chracter of the URL - for example,
    #                      if your tweet is "I love http://site.com!", the
    #                      exclamation point will not be considered part of the
    #                      URL, even though exclamation points are allowed at
    #                      other places in the URL.
    return ''.join(re.split(pattern, tweet, flags=re.IGNORECASE))

# Remove @ from Twitter user names and # from hash tags.
def twtt4(tweet):
    # The most complicated aspect of this is: how do we know when an @ or #
    # symbol is part of a username/hashtag, instead of just regular text?
    # Examples which are NOT usernames or hashtags:
    #      name@gmail.com
    #      @@words
    #      $@whatever
    #      #1
    #      &#stuff
    # Examples which ARE usernames or hashtags:
    #      (@name)
    #      ...#hashtag
    #      #1a
    #      :@you
    # So the problem is not entirely straighforward.
    handle_pattern = r"(^|[^A-Za-z0-9_!@#$%&*])@([A-Za-z0-9_])"
    # Pattern breakdown:
    # (^|[^A-Za-z0-9_!@#$%&*])
    #                      Immediately preceeding the twitter handle, there can
    #                      be either the start of the tweet, or any character
    #                      *except* for a few special ones. We use a capturing
    #                      group so that re.split will keep this character.
    # @
    #                      Then comes the @ symbol itself.
    # ([A-Za-z0-9_])
    #                      The following characters are the only ones allowed
    #                      to be in a twitter handle, so must directly follow
    #                      the @ symbol. Again, we use a capturing group to
    #                      keep these characters, we only want to throw away
    #                      the @ symbol.
    tweet = ''.join(re.split(handle_pattern, tweet))

    # Hashtag is similar, but a wider range of characters are allowed to appear
    # before the hashtag. Further, although numbers and underscores may be
    # included in a hashtag, hashtags need to include *at least* one number. So
    # the following are not hashtags: #1 or #_ or #12345_6789
    hashtag_pattern = r"(^|[^A-Za-z0-9_&])#([0-9_]*)([A-Za-z])"
    # Pattern breakdown:
    # (^|[^A-Za-z0-9_&])
    #                      Immediately preceeding the hashtag, there can
    #                      be either the start of the tweet, or any character
    #                      *except* for a few special ones. We use a capturing
    #                      group so that re.split will keep this character.
    # #
    #                      Then comes the # symbol itself.
    # ([0-9_]*)
    #                      Hashtags may begin with any number of digits or
    #                      underscores. Again, we use a capturing group to keep
    #                      these characters, we only want to throw away the #
    #                      symbol.
    # ([A-Za-z])
    #                      A hashtag is required to contain at least one letter
    #                      somewhere.
    tweet = ''.join(re.split(hashtag_pattern, tweet))

    return tweet

# Break tweet into sentences, and put each sentence on its own line.
def twtt5(tweet):
    global abbrevs, non_terminal_abbrevs

    # First, a bunch of helper functions:

    # Check if character i in the given tweet is the end of an abbreviation.
    # If so, returns the abbreviation. If not, returns None.
    def get_abbrev(tweet, i):
        # Look for each abbreviation in turn.
        for a in abbrevs:
            if i < len(a) - 1:
                continue # This abbrev doesn't even fit to the left of i
            if tweet[i-len(a)+1:i+1] == a:
                # Potentially found an abbrev! First check that the letter
                # immediately before the apprev is non-alphabetic
                if i-len(a)+1 > 0 and tweet[i-len(a)].isalpha():
                    # Oops, not an abbreviation!
                    continue
                # Okay we have an abbreviation!
                return tweet[i-len(a)+1:i+1]
        return None # None of the abbrevs matched

    # Check if character i in the given tweet is a decimal point.
    def is_decimal_place(tweet, i):
        # We only deal with the simple case where characters on both sides of
        # the decimal point are numbers.
        return (tweet[i] == "." and
                i > 0 and
                tweet[i-1].isdigit() and
                i + 1 < len(tweet) and
                tweet[i+1].isdigit())

    # Check if character i in the given tweet is inside an acronym.
    def is_acronym(tweet, i):
        # For our purposes, an acronym is a sequence of alternating letters and
        # periods, at least four characters long in total. For example: U.S. or
        # F.D.A.
        # First find the boundaries of this token.
        start = i
        while start > 0 and (tweet[start-1].isalpha() or tweet[start-1] == "."):
            start -= 1
        end = i
        while end+1 < len(tweet) and (tweet[end+1].isalpha() or tweet[end+1] == "."):
            end += 1
        tok = tweet[start:end+1]
        if len(tok) < 4:
            return False # Acronym must be at least 4 characters long (including
                         # periods)
        for (index, c) in enumerate(tok):
            # If it's an acronym, the even characters are letters and the odd
            # characters are .
            if index % 2 == 0 and not c.isalpha():
                return False
            if index % 2 == 1 and c != ".":
                return False
        # If we make it through the check, it's an acronym
        return True

    # Check if the given character is a potential end-of-sentence punctuation
    def is_punctuation(c):
        return c in ".?!"

    # Check if character i in the given tweet is an end-of-sentence punctuation.
    def is_eos_punctuation(tweet, i):
        if tweet[i] in '")' and i > 0 and is_eos_punctuation(tweet, i-1):
            return True # Quotation marks or closing parens following
                        # end-of-sentence punctuation should also be considered
                        # end-of-sentence. This handles cases like: [He said "I
                        # like it." (And she agreed!)]
        if not is_punctuation(tweet[i]):
            return False
        # Check if this is a period in the middle of an acronym - that means
        # it's deinitely not the end of a sentence.
        is_ac = is_acronym(tweet, i)
        if is_ac:
            if i+1 < len(tweet) and (tweet[i+1].isalpha() or tweet[i+1] == "."):
                return False # Middle of acronym, not end of sentence
        # Check if this is the period in an abbreviation
        abbrev = get_abbrev(tweet, i)
        if abbrev and abbrev in non_terminal_abbrevs:
            # We define a non-terminal abbreviation to be one which generally
            # cannot end sentences, and is usually followed by proper nouns. For
            # example, "Mr." If it's a non-terminal abbreviation, then this is
            # not eos.
            return False
        if abbrev or is_ac:
            # Otherwise, if we have an abbreviation or the end of an acronym,
            # check if the next non-whitespace character is uppercase or not.
            for j in xrange(i+1, len(tweet)):
                if tweet[j].isspace():
                    continue # Skip whitespace
                return tweet[j].isupper()
            # If we get here, we hit the end of the string. So this is indeed
            # the end of sentence.
            return True
        if is_decimal_place(tweet, i):
            return False # periods can also be decimal points! These are not end
                         # of sentence markers
        # If we make it through all those special cases, then we think we really
        # have found the end of the sentence
        return True

    # Helper function which takes the text, and partitions it based on
    # split_conditions. split_conditions is an iterable that is as long as
    # text. Whenever there is a boundary between nonequal elements in
    # split_conditions, that will result in a split in the text. For example:
    #    text             = "Hello there"
    #    split_conditions = "aabbbccccdd"
    #    output           = ["He", "llo", " the", "re"]
    def split_on(text, split_conditions):
        joined = zip(text, split_conditions)
        groups = itertools.groupby(joined, key=lambda x: x[1])
        groups = [''.join([x[0] for x in g]) for (k, g) in groups]
        return groups

    # Okay, now that we have our helper functions, let's actually do this:

    # Create an array telling us which characters are end-of-sentence
    # punctuation.
    eos = [is_eos_punctuation(tweet, i) for i in xrange(len(tweet))]

    # Now let's split the tweet based on eos punctuation
    splits = split_on(tweet, eos)

    # Okay, now a sentence is defined to be: a string terminated by *one or
    # more* eos punctuation symbols, *possibly separated by whitespace*. That
    # is, the following is only one sentence:
    # "Argh, why?!?!"
    # Or even:
    # "Man I hate Mondays . . ."
    # (Ellipsis separated by spaces doesn't get treated as multiple empty
    # sentences)
    # So let's break into sentences:
    sentences = []
    current_sentence = ""
    for s in splits:
        # Punctuation and whitespace always get attached to the preceeding
        # sentence.
        if is_punctuation(s[0]) or s.strip() == "":
            current_sentence += s
        else:
            # Otherwise, this starts a new sentence
            if current_sentence:
                # Push the current sentence onto the list
                sentences.append(current_sentence)
            current_sentence = s
    # At the end, push the last sentence onto the list
    sentences.append(current_sentence)

    # Strip extra whitespace off the beginning and end of sentences, and
    # separate using newlines.
    return "\n".join([s.strip() for s in sentences])

# Tokenize tweet.
# Note, this will tokenize things like !) as single tokens. Example:
# I like it (a lot!)
#                 ^^ These two characters are a single token
# This is because of rule 6 in the handout - multiple punctuation should not be
# split.
def twtt7(tweet):
    # Helper funtion to tokenize a single line
    def tokenize(line):
        # In general, we are just splitting on word boundaries
        toks = [t for t in re.split("(\W+)", line) if t != ""]
        # But we also want special handling for clitics.  Let's look for
        # apostrophe tokens and make them into clitics as appropriate.
        i = 1
        while i < len(toks) - 1:
            if toks[i] != "'":
                # Not an apostrophe - skip
                i += 1
                continue
            # Look for whitespace on either side of the apostrophe:
            if toks[i-1][-1].isspace() or toks[i+1][0].isspace():
                # Apostrophe should not be combined with any characters - skip
                i += 1
                continue
            # Okay, now look for the special clitic n't
            if toks[i-1][-1] == "n" and toks[i+1] == "t":
                # Make n't into its own token
                toks = toks[:i-1] + [toks[i-1][:-1], "n't"] + toks[i+2:]
                i += 1
                continue
            # Okay, if the following token is alphabetic, combine the apostrophe
            # with the next token.
            if toks[i+1].isalpha():
                toks = toks[:i] + [toks[i] + toks[i+1]] + toks[i+2:]
                i +=1
                continue
            i += 1
        # Remove excess whitespace from tokens
        toks = [t.strip() for t in toks]
        # Remove empty tokens
        toks = [t for t in toks if t != ""]
        # Combine the tokens with spaces
        return " ".join(toks)

    # Tokenize each line
    lines = tweet.split("\n")
    return "\n".join(map(tokenize, lines))

# Tag tweet with parts of speech
def twtt8(tweet):
    global tagger

    # Helper function to tag a single line.
    def tag(line):
        toks = line.split()
        tags = tagger.tag(toks)
        return " ".join(["%s/%s" % (tok, tag) for (tok, tag) in zip(toks, tags)])

    # Tag each line
    lines = tweet.split("\n")
    return "\n".join(map(tag, lines))

# Append a polarity marker onto the front of tweet
def twtt9(tweet, polarity):
    return "<A=%d>\n%s" % (polarity, tweet)

def main(args):
    global tagger, html_parser, abbrevs, non_terminal_abbrevs

    if len(args) != 4:
        print "Usage: python twtt.py input_file.csv student_number output_file.twt"
        return

    input_file = args[1]
    student_number = int(args[2])
    output_file = args[3]

    # Initialize the tagger
    tagger = NLPlib.NLPlib()

    # Initialize the HTML parser
    html_parser = HTMLParser.HTMLParser()

    # Read the abbreviation lists
    abbrev_file = "abbrev.english"
    non_terminal_abbrev_file = "non_terminal_abbrev.english"
    with open(abbrev_file, "r") as f:
        abbrevs = [line.strip() for line in f.readlines()]
    with open(non_terminal_abbrev_file, "r") as f:
        non_terminal_abbrevs = [line.strip() for line in f.readlines()]

    # Count the number of lines in the input file - this determines whether we
    # should process the whole file, or select a subset of lines.
    with open(input_file, "r") as f:
        line_count = sum(1 for line in f)

    # Figure out which lines to read
    X = student_number % 80 if line_count > 10000 else 0
    A = 10000*X
    B = 800000 + 10000*X

    with open(input_file, "r") as in_file, \
         open(output_file, "w") as out_file:
        for (i, line) in enumerate(in_file):
            # Check if we should process this line
            if (A <= i < A + 10000) or (B <= i < B + 10000):
                # Apply each of the preprocessing transformations and write
                # result to .twtt file.
                (tweet, polarity) = extract_tweet_and_polarity(line)
                tweet = twtt1(tweet)
                tweet = twtt2(tweet)
                tweet = twtt3(tweet)
                tweet = twtt4(tweet)
                tweet = twtt5(tweet)
                tweet = twtt7(tweet)
                tweet = twtt8(tweet)
                tweet = twtt9(tweet, polarity)
                out_file.write(tweet + "\n")

if __name__ == "__main__":
    main(sys.argv)
