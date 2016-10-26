% callback when main window is closed

function close(s,~,~)


% close everything and save everything
s.saveData;

delete(s.handles.main_fig)
clear('s')

