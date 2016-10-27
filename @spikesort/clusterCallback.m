% master dispatched when we want to cluster the data

function clusterCallback(s,~,~)


method = (get(s.handles.cluster_control,'Value'));
temp = get(s.handles.cluster_control,'String');
method = temp{method};
method = str2func(method);

method(s);
 
s.removeDoublets;
 
% also calculate the spike amplitudes 
s.current_data.spikes(s.this_paradigm).amplitudes_A(s.this_trial,s.A) = s.spikeAmplitudes(s.filtered_voltage,s.A);
s.current_data.spikes(s.this_paradigm).amplitudes_B(s.this_trial,s.B) = s.spikeAmplitudes(s.filtered_voltage,s.B);