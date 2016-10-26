function addTag(s,src,~)
% matlab wrapper for tag, which adds BSD tags to the file we are working on. *nix only. 
tag = get(src,'String');

if ~isempty(s.file_name) 
    % tag the file with the given tag
    clear es
    es{1} = 'tag -a ';
    es{2} = tag;
    es{3} = strcat(s.path_name,s.file_name);
    try
        unix(strjoin(es));
    catch
    end
end
