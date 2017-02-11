import re
import sys
import itertools
    
def get_tweet_test(csv_line):
    m = re.match(r'^"[^,]*","[^,]*","[^,]*","[^,]*","[^,]*","(.*)"$', csv_line)
    assert m
    return m.group(1)

# Remove html tags
def twtt1(tweet):
    # We use a slightly more complex regular expression than the one
    # provided in the handout so that we can handle cases where there is a
    # greater-than sign inside of an html attribute (which should not be
    # treated as the end of the html tag). For example:
    # <img onclick="alert('5 > 4');"/>
    #                        ^
    #                        This is *not* the end of the tag
    pattern = r"""<([^'>"]|"[^"]*"|'[^']*')+>"""
    return ''.join(re.split(pattern, tweet))

# Decode html character code
def twtt2(tweet):
    while True:
        m = re.search(r"&#([0-9]{2,3});", tweet)
        if not m:
            break
        num = int(m.group(1))
        assert 32 <= num <= 127
        tweet = tweet[:m.start()] + chr(num) + tweet[m.end():]
    return tweet

# Remove tokens which begin with www or http
def twtt3(tweet):
    # We are going to try to roughly match Twitter's behaviour when looking for
    # URLs. Twitter actually looks for more than just a simple http or www to
    # identify URLs, but since the assignment specifically asks us to just look
    # for tokens starting http or www, we'll do that. However, we still need to
    # determine what counts as a token. In particular, what counts as the
    # *start* of a URL token, and what counts as the *end* of a URL token? This
    # is where we will take inspiration from Twitter's actual behaviour.
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
    #                      to be the *last* chracter of the URL
    print re.split(pattern, tweet)
    return ''.join(re.split(pattern, tweet))

# Remove @ from Twitter user names and # from hash tags.
def twtt4(tweet):
    handle_pattern = r"(^|[^A-Za-z0-9_!@#$%&*])@([A-Za-z0-9_])"
    # (^|[^A-Za-z0-9_!@#$%&*])
    #                      Immediately preceeding the twitter handle, there can
    #                      be either the start of the tweet, or any character
    #                      *except* for a few special ones. We use a capturing
    #                      group so that re.split will keep this character.
    # @
    #                      Then comes the @ symbol itslef.
    # ([A-Za-z0-9_])
    #                      The following characters are the only ones allowed
    #                      to be in a twitter handle, so must directly follow
    #                      the @ symbol. Again, we use a capturing group to
    #                      keep these characters, we only want to throw away
    #                      the @ symbol.
    print re.split(handle_pattern, tweet)
    tweet = ''.join(re.split(handle_pattern, tweet))

    # Hashtag is similar, but a wider range of characters are allowed to appear
    # before the hashtag.
    hashtag_pattern = r"(^|[^A-Za-z0-9_&])#([A-Za-z0-9_])"
    # (^|[^A-Za-z0-9_&])
    #                      Immediately preceeding the hashtag, there can
    #                      be either the start of the tweet, or any character
    #                      *except* for a few special ones. We use a capturing
    #                      group so that re.split will keep this character.
    # #
    #                      Then comes the # symbol itself.
    # ([A-Za-z0-9_])
    #                      The following characters are the only ones allowed
    #                      to be in a twitter hashtag, so must directly follow
    #                      the # symbol. Again, we use a capturing group to
    #                      keep these characters, we only want to throw away
    #                      the # symbol.
    print re.split(hashtag_pattern, tweet)
    tweet = ''.join(re.split(hashtag_pattern, tweet))

    return tweet

def twtt5(tweet):
    abbrev_file = "abbrev.english"
    non_terminal_abbrev_file = "non_terminal_abbrev.english"
    with open(abbrev_file, "r") as f:
        abbrevs = [line.strip() for line in f.readlines()]
    print abbrevs
    with open(non_terminal_abbrev_file, "r") as f:
        non_terminal_abbrevs = [line.strip() for line in f.readlines()]
    print non_terminal_abbrevs

    # Returns None if not, otherwise returns the abbrev
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
                # # If it's a non-terminal abbrev (i.e. one that doesn't normally
                # # occur at the end of sentence), ignore it.
                # if tweet[i-len(a)+1:i+1] in non_terminal_abbrevs:
                #     return False # Non-terminal abbrev
                return tweet[i-len(a)+1:i+1] # Found a terminal abbrev!
        return None # None of the abbrevs matched
    # x = map(lambda i: is_end_of_abbrev(tweet, i), xrange(len(tweet)))
    # return x
    # import itertools
    # return map(lambda b: b[1], itertools.groupby(enumerate(tweet), key=lambda a: x[a[0]]))    
    
    def is_decimal_place(tweet, i):
        return (tweet[i] == "." and
                i > 0 and
                tweet[i-1].isdigit() and
                i + 1 < len(tweet) and
                tweet[i+1].isdigit())

    def is_acronym(tweet, i):
        # First find the boundaries of this token
        start = i
        while start > 0 and (tweet[start-1].isalpha() or tweet[start-1] == "."):
            start -= 1
        end = i
        while end+1 < len(tweet) and (tweet[end+1].isalpha() or tweet[end+1] == "."):
            end += 1
        tok = tweet[start:end+1]
        for (index, c) in enumerate(tok):
            # If it's an acronym, the even characters are letters and the odd
            # characters are .
            if index % 2 == 0 and not c.isalpha():
                return False
            if index % 2 == 1 and c != ".":
                return False
        # If we make it through the check, it's an acronym
        return True
    # x = map(lambda i: is_acronym(tweet, i), xrange(len(tweet)))
    # return x

    def is_punctuation(c):
        return c in ".?!" # Only punctuation we care about for sentence endings
    
    def is_eos_punctuation(tweet, i):
        if not is_punctuation(tweet[i]):
            return False
        abbrev = get_abbrev(tweet, i)
        if abbrev:
            # If it's a non-terminal abbreviation, then this is not eos.
            if abbrev in non_terminal_abbrevs:
                return False
            # Otherwise, check if the next non-whitespace character is uppercase
            # or not.
            for j in xrange(i+1, len(tweet)):
                if tweet[j].isspace():
                    continue # Skip whitespace
                return tweet[j].isupper()
            # If we get here, we hit the end of the string. So this is indeed
            # the end of sentence.
            return True
        if is_decimal_place(tweet, i):
            return False
        if is_acronym(tweet, i):
            return False
        return True

    # Takes the text, and partitions it based on split_conditions.
    # split_conditions is an iterable that is as long as text. Whenever there is a
    # boundary between nonequal elements in split_conditions, that will result
    # in a split in the test. For example:
    #    text             = "Hello there"
    #    split_conditions = "aabbbccccdd"
    #    output           = ["He", "llo", " the", "re"]
    def split_on(text, split_conditions):
        joined = zip(text, split_conditions)
        groups = itertools.groupby(joined, key=lambda x: x[1])
        groups = [''.join([x[0] for x in g]) for (k, g) in groups]
        return groups
            
    # Create an array telling us which characters are end-of-sentence
    # punctuation. To start out with, none are.
    eos = [is_eos_punctuation(tweet, i) for i in xrange(len(tweet))]
    print tweet
    print ''.join(["^" if e else " " for e in eos])

    # Now let's split the tweet based on eos punctuation
    splits = split_on(tweet, eos)

    # Okay, now a sentence is defined to be: a string terminated by *one or
    # more* eos punctuation symbols, *possibly separated by whitespace*. That
    # is, the following is only one sentence:
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

def main(args):
    if len(args) != 4:
        print "Usage: python twtt.py input_file.csv student_number output_file.twt"
        return

    input_file = args[1]
    student_number = args[2]
    output_file = args[3]

    with open(input_file, "r") as f:
        for line in f:
            tweet = get_tweet_text(line)
            # Apply each of the preprocessing transformations
            tweet = twtt1(tweet)
            tweet = twtt2(tweet)
            tweet = twtt3(tweet)

if __name__ == "__main__":
    main(sys.argv)
