% spikesort plugin
% plugin_type = 'save-data';
% data_extension = 'kontroller';
% 

function [] = saveData_kontroller(s,~,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

% early escape
if isempty([s.A(:); s.B(:); s.N(:)])
    return
end

if isempty(s.time) 
    return
end

% figure out if there is a spikes variable already
m = matfile([s.path_name s.file_name]);
if any(strcmp('spikes',who(m)))
    load([s.path_name s.file_name],'-mat','spikes')
else
    load([s.path_name s.file_name],'-mat','data')
    % create it, and make an entry for ever single one in data
    nparadigms = length(m.data);
    for i = 1:nparadigms
        spikes(i).A = sparse(0*data(i).voltage);
        spikes(i).B = sparse(0*data(i).voltage);
        spikes(i).N = sparse(0*data(i).voltage);
        spikes(i).amplitudes_A = (0*data(i).voltage);
        spikes(i).amplitudes_B = (0*data(i).voltage);
    end
    clear data
end

spikes(s.this_paradigm).A(s.this_trial,:) = sparse(1,length(s.time)); 
spikes(s.this_paradigm).A(s.this_trial,s.A) = 1;     
spikes(s.this_paradigm).B(s.this_trial,:) = sparse(1,length(s.time));
spikes(s.this_paradigm).B(s.this_trial,s.B) = 1;
spikes(s.this_paradigm).N(s.this_trial,:) = sparse(1,length(s.time));
spikes(s.this_paradigm).N(s.this_trial,s.N) = 1;

spikes(s.this_paradigm).amplitudes_A(s.this_trial,:) = sparse(1,length(s.time));
spikes(s.this_paradigm).amplitudes_B(s.this_trial,:) = sparse(1,length(s.time));

save([s.path_name s.file_name],'-append','spikes')

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',['Data saved!'])
end
