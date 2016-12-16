% master dispatched when we want to reduce dimensions

function reduceDimensionsCallback(s,~,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

method = (get(s.handles.method_control,'Value'));
temp = get(s.handles.method_control,'String');
method = temp{method};
method = str2func(method);

s.handles.popup.Visible = 'on';
s.handles.popup.String = {'','','','Reducing dimenisons...'}
drawnow;

method(s);

s.handles.popup.Visible = 'off';
drawnow;
 