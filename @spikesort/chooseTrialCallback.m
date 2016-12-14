function chooseTrialCallback(s,src,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

% unpack some stuff
data = s.current_data.data;


n = structureElementLength(data); 
if length(n) < s.this_paradigm
    return
else
    n = n(s.this_paradigm);
end
if src == s.handles.trial_chooser
    s.this_trial = get(s.handles.trial_chooser,'Value');
    % update the plots
    s.plotStim;
    s.plotResp(@chooseTrialCallback);
elseif src == s.handles.next_trial
    if s.this_trial < n
        s.this_trial = s.this_trial + 1;
        set(s.handles.trial_chooser,'Value',s.this_trial);
        % update the plots
        s.plotStim;
        s.plotResp(@chooseTrialCallback);
    else
        % fake a call
        s.chooseParadigmCallback(s.handles.next_paradigm);
    end
elseif src == s.handles.prev_trial
    if s.this_trial > 1
        s.this_trial = s.this_trial  - 1;
        set(s.handles.trial_chooser,'Value',s.this_trial);
        % update the plots
        s.plotStim;
        s.plotResp(@chooseTrialCallback);
    else
        % fake a call
        s.chooseParadigmCallback(s.handles.prev_paradigm);
    end
else
    error('unknown source of callback 173. probably being incorrectly being called by something.')
end    

% update Discard control
s.updateDiscardControl;

