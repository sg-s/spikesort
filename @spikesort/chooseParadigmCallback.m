
function chooseParadigmCallback(s,src,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

% unpack some stuff
data = s.current_data.data;

paradigms_with_data = find(structureElementLength(data)); 
if src == s.handles.paradigm_chooser
    s.this_paradigm = paradigms_with_data(get(s.handles.paradigm_chooser,'Value'));
elseif src == s.handles.next_paradigm
    if max(paradigms_with_data) > s.this_paradigm 
        s.this_paradigm = paradigms_with_data(find(paradigms_with_data == s.this_paradigm)+1);
        set(s.handles.paradigm_chooser,'Value',find(paradigms_with_data == s.this_paradigm));
    end
elseif src == s.handles.prev_paradigm
    if s.this_paradigm > paradigms_with_data(1)
        s.this_paradigm = paradigms_with_data(find(paradigms_with_data == s.this_paradigm)-1);
        set(s.handles.paradigm_chooser,'Value',find(paradigms_with_data == s.this_paradigm));
    end
else
    error('unknown source of callback 109. probably being incorrectly being called by something.')
end

n = structureElementLength(data);
n = n(s.this_paradigm);
temp  ={};
for i = 1:n
    temp{i} = strcat('Trial-',mat2str(i));
end
set(s.handles.trial_chooser,'String',temp);
if src == s.handles.prev_paradigm
    set(s.handles.trial_chooser,'Value',n);
    s.this_trial = n;
else
    set(s.handles.trial_chooser,'Value',1);
    s.this_trial = 1;
end

% update the plots
s.plotStim;
s.plotResp(@chooseParadigmCallback);

% update Discard control
s.updateDiscardControl;
       

