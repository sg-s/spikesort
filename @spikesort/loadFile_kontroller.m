% spikesort plugin
% plugin_type = 'load-file';
% data_extension = 'kontroller';
% 
function s = loadFile_kontroller(s,~,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

% read the file
m = matfile([s.path_name s.file_name]);

% get the output channel names
s.output_channel_names = m.OutputChannelNames;

% read sampling rate
s.sampling_rate = m.SamplingRate;


% update the paradigm names in the paradigm chooser 
temp = m.ControlParadigm;
temp = {temp.Name};

% only show those control paradigms that have any data in them
paradigms_with_data = find(structureElementLength(m.data));
s.handles.paradigm_chooser.String = temp;

% populate some fields for the UX
set(s.handles.valve_channel,'String',s.output_channel_names)

% update stimulus listbox with all input channel names
fl = fieldnames(m.data);

% also add all the control signals
set(s.handles.stim_channel,'String',[fl(:); s.output_channel_names(:)]);


% update response listbox with all the input channel names
set(s.handles.resp_channel,'String',fl);


% go to the first trial and paradigm with data
s.this_trial = 1;
s.this_paradigm  = paradigms_with_data(1);
s.handles.paradigm_chooser.Value = paradigms_with_data(1);


