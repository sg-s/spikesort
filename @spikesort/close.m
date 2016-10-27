% callback when main window is closed

function close(s,~,~)

delete(s.handles.main_fig)
delete(s)
