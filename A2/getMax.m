function maximums = getMax(s, k)
    maximums = struct();
    names = fieldnames(s);
    values = zeros(1, length(names));
    for i=1:length(names)
        values(i) = s.(names{i});
    end
    [~, mapping] = sort(values, 'descend');
    for i=1:k
        index = mapping(i);
        maximums.(names{index}) = values(index);
    end
end