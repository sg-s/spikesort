function updateDiscardControl(s,~,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

% unpack data
try
    spikes = s.current_data.spikes;
catch
    set(s.handles.discard_control,'Value',0,'String','Discard','FontWeight','normal')
    return
end

if isfield(spikes,'discard')
    discard_this = false;
    try
        discard_this = spikes(s.this_paradigm).discard(s.this_trial);
    catch
    end
    if discard_this
        set(s.handles.discard_control,'Value',1,'String','Discarded!','FontWeight','bold')
    else
        set(s.handles.discard_control,'Value',0,'String','Discard','FontWeight','normal')
    end
else
    % nothing has been discarded
    set(s.handles.discard_control,'Value',0,'String','Discard','FontWeight','normal')
end
