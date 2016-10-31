% spikesort plugin
% plugin_type = 'read-data';
% data_extension = 'kontroller';
% 
function s = readData_kontroller(s,src,event)

% load the data requested
m = matfile([s.path_name s.file_name]);
this_data = m.data(1,s.this_paradigm);
s.raw_voltage = this_data.voltage(s.this_trial,:);