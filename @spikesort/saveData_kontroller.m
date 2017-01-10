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
    nparadigms = length(data);
    for i = 1:nparadigms
        temp = data(i).voltage*0;
        temp(isnan(temp)) = 0;
        spikes(i).A = sparse(logical(0*temp));
        spikes(i).B = sparse(logical(0*temp));
        spikes(i).N = sparse(logical(0*temp));
        spikes(i).amplitudes_A = (0*temp);
        spikes(i).amplitudes_B = (0*temp);
    end
    clear data
end

spikes(s.this_paradigm).A(s.this_trial,:) = 0;
spikes(s.this_paradigm).B(s.this_trial,:) = 0;
spikes(s.this_paradigm).N(s.this_trial,:) = 0;

spikes(s.this_paradigm).B(s.this_trial,s.B) = 1;
spikes(s.this_paradigm).A(s.this_trial,s.A) = 1; 
spikes(s.this_paradigm).N(s.this_trial,s.N) = 1;

spikes(s.this_paradigm).amplitudes_A(s.this_trial,s.A) = s.A_amplitude;
spikes(s.this_paradigm).amplitudes_B(s.this_trial,s.B) = s.B_amplitude;

save([s.path_name s.file_name],'-append','spikes')

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',['Data saved!'])
end
