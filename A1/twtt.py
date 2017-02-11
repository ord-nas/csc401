import re
import sys
    
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
    #                      Then comes the # symbol itslef.
    # ([A-Za-z0-9_])
    #                      The following characters are the only ones allowed
    #                      to be in a twitter hashtag, so must directly follow
    #                      the # symbol. Again, we use a capturing group to
    #                      keep these characters, we only want to throw away
    #                      the # symbol.
    print re.split(hashtag_pattern, tweet)
    tweet = ''.join(re.split(hashtag_pattern, tweet))

    return tweet

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
