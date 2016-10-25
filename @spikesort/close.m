% callback when main window is closed

function [] = close(s,~,~)


% close everything and save everything
try
    if ~isempty(s.path_name) && ~isempty(s.file_name) 
        if ischar(s.path_name) && ischar(s.file_name)
            save(strcat(s.path_name,s.file_name),'spikes','-append')
        end
    end
catch
    warning('Error saving data!')
end

delete(s.handles.main_fig)
clear('s')

