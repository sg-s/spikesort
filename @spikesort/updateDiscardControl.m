function updateDiscardControl(s,~,~)

% unpack data
spikes = s.current_data.spikes;

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
