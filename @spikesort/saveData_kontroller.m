% spikesort plugin
% plugin_type = 'save-data';
% data_extension = 'kontroller';
% 

function [] = saveData_kontroller(s,~,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

if isempty(s.current_data)
	return
end

% unpack
spikes = s.current_data.spikes;

if isempty(s.time) 
	return
end

spikes(s.this_paradigm).A(s.this_trial,:) = sparse(1,length(s.time));      
spikes(s.this_paradigm).B(s.this_trial,:) = sparse(1,length(s.time));
spikes(s.this_paradigm).N(s.this_trial,:) = sparse(1,length(s.time));
spikes(s.this_paradigm).amplitudes_A(s.this_trial,:) = sparse(1,length(s.time));
spikes(s.this_paradigm).amplitudes_B(s.this_trial,:) = sparse(1,length(s.time));
spikes(s.this_paradigm).A(s.this_trial,s.A) = 1;
spikes(s.this_paradigm).B(s.this_trial,s.B) = 1;
spikes(s.this_paradigm).N(s.this_trial,s.N) = 1;


% get the A and B amplitudes
keyboard

% repack
s.current_data.spikes = spikes;

try
    if ~isempty(s.path_name) && ~isempty(s.file_name) 

        if ischar(s.path_name) && ischar(s.file_name)
            save(strcat(s.path_name,s.file_name),'spikes','-append')
        end
    end
catch
    warning('Error saving data!')
end
