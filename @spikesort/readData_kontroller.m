% spikesort plugin
% plugin_type = 'read-data';
% data_extension = 'kontroller';
% 
function s = readData_kontroller(s,src,event)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

if isempty(s.this_paradigm) || isempty(s.this_trial)
	return
end

% enable everything; we'll disable things later
s.handles.prev_trial.Enable = 'on';
s.handles.next_trial.Enable = 'on';
s.handles.next_paradigm.Enable = 'on';
s.handles.prev_paradigm.Enable = 'on';
s.handles.paradigm_chooser.Enable = 'on';
s.handles.trial_chooser.Enable = 'on';

% read the voltage trace for the current file
m = matfile([s.path_name s.file_name]);
this_data = m.data(1,s.this_paradigm);
s.raw_voltage = this_data.voltage(s.this_trial,:);


% read the stimulus trace for the current file for the current trial 
s.stimulus = this_data.PID(s.this_trial,:);

% is this already sorted? 
if any(strcmp('spikes',who(m)))
	this_spikes = m.spikes(1,s.this_paradigm);
	s.A = find(this_spikes.A(s.this_trial,:));
	s.B = find(this_spikes.B(s.this_trial,:));
	s.N = find(this_spikes.N(s.this_trial,:));
end

% update the trial chooser with the number of trials we have in this paradigm 
ntrials = size(this_data.voltage,1);
trial_text = {};
for i = 1:ntrials
	trial_text{i} = ['Trial ' oval(i)];
end
s.handles.trial_chooser.String = trial_text;

% update the paradigm chooser so that the name reflects the paradigm we are in
s.handles.paradigm_chooser.Value = s.this_paradigm;

s.handles.trial_chooser.Value = s.this_trial;

% disable some buttons as needed
if s.this_trial == ntrials
	s.handles.next_trial.Enable = 'off';
elseif s.this_trial == 1
	s.handles.prev_trial.Enable = 'off';
end

% read the number of paradigms we have
nparadigms = length(m.data);

if s.this_paradigm == nparadigms
	s.handles.next_paradigm.Enable = 'off';
elseif s.this_paradigm == 1
	s.handles.prev_paradigm.Enable = 'off';
end





