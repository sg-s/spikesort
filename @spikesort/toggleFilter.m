function [] = toggleFilter(s,~,~)

if get(s.handles.filtermode,'Value')
	set(s.handles.filtermode,'String','Filter is ON')
	s.filter_trace = true;
	return
else
	set(s.handles.filtermode,'String','Filter is OFF')
	s.filter_trace = false;
	return
end

