% spikesort plugin
% plugin_type = 'read-data';
% data_extension = 'kontroller';
% 
function s = readData_kontroller(s,src,event)

% read the voltage trace for the current file
m = matfile([s.path_name s.file_name]);
this_data = m.data(1,s.this_paradigm);
s.raw_voltage = this_data.voltage(s.this_trial,:);


% read the stimulus trace for the current file for the current trial 
