function out = asFieldname(in)
    in = char(in); % convert to char array
    out = in(1:min(63, length(in))); % truncate to 63 chars
end