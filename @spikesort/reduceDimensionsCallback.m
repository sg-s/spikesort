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

% unpack
pref = s.pref;
loc = s.loc;

% cut out the snippets 
s.R = [];
V_snippets = NaN(pref.t_before+pref.t_after,length(loc));
if loc(1) < pref.t_before+1
    loc(1) = [];
    V_snippets(:,1) = []; 
end
if loc(end) + pref.t_after+1 > length(s.filtered_voltage)
    loc(end) = [];
    V_snippets(:,end) = [];
end
for i = 1:length(loc)
    V_snippets(:,i) = s.filtered_voltage(loc(i)-pref.t_before+1:loc(i)+pref.t_after);
end

s.V_snippets = V_snippets;

method(s);
 