function [V filein_name file_path svalve pid] = spike_sorting_loadfile_b(dataformat)
% modified by Srinivas to include data about the stimulus on and off times.
% last edit at 9:43 , 29 April 2011.

% 2011_10_11 modified by Carlotta to load PID measurements. note that PID
% value are loaded only in mat file mode

if dataformat==1 %% matlab file
    [filein_name, file_path] = uigetfile('*.mat','Select the data file');
    if filein_name~=0
        hw = waitbar(0.2, 'Loading data...');
        F = load([file_path filein_name]);
        deltat = F.deltat;
        
        if ndims(F.ORN)==2
            numexp = 1;
            [numtrials L] = size(F.ORN);
            V(1,:,:) = F.ORN;
            if isfield(F, 'PID') % more forgiving code
                pid(1,:,:) = F.PID;
            else
                pid=[];
            end
        else
            V = F.ORN;
            if isfield(F, 'PID') % more forgiving code
                pid = F.PID;
            else 
                pid=[];
            end
        end
        if isfield(F, 'stimsignal') % more forgiving code
            Stim = F.stimsignal;
        elseif isfield(F, 'stim_signal')
            stim1(1,1,:)=F.stim_signal(1,1,:);
            Stim=repmat(stim1, [size(V,1),size(V,2),1]);
        end
        % normalise and digitise signal
        if isfield(F, 'valvesignal') % more forgiving code
            Stim = F.valvesignal;
%             sds = size(Stim);
%             svalve(sds(1),sds(2)).ton = [];
%             svalve(sds(1),sds(2)).toff = [];
%             for i = 1:sds(1)
%                 for j = 1:sds(2)
%                     svalve(i,j).ton = 1;  % in seconds
%                     svalve(i,j).toff = 1.5; % in seconds
%                 end
%             end
%         else
            Stim = round(Stim);
            Stim = Stim/max(max(max(Stim)));
            % end. this fixes a bug where stim signal was corrupted
            ss = size(Stim);
            so = size(V);
            dos = 1;
            if length(ss) ~= length(so)
                waitbar(0.8,hw,'WARNING:Data not correctly formatted. No Stim Signal!')
                dos = 0; % this flag prevents computation of Stim Signal

            elseif  max(ss(2:3) - so(2:3)) ~= 0
                waitbar(0,8,hw,'WARNING:Data not correctly formatted. No Stim Signal!')
                dos = 0; % this flag prevents computation of Stim Signal

            end
            if dos == 1
                dstim = diff(Stim,1,3);
                % find all the on times, all the offtimes and return those
                % instead of returning the whole Stim matrix
                waitbar(0.8,hw, 'Finding on and off times for stimuli...')
                sds = size(Stim);

                svalve(sds(1),sds(2)).ton = [];
                svalve(sds(1),sds(2)).toff = [];
                for i = 1:sds(1)
                    for j = 1:sds(2)
                        svalve(i,j).ton = find(dstim(i,j,:)>0)*deltat;  % in seconds
                        svalve(i,j).toff = find(dstim(i,j,:)<0)*deltat; % in seconds
                    end
                end
            else
                svalve = []; % couldn't find the stim signal
            end
        end
        waitbar(1,hw, 'DONE')
        close(hw)
    else
        V = [];
    end
    
elseif dataformat==2 %% axoscope
    pid=[];
    [file_path] = uigetdir;
    s = regexp(file_path, '\/', 'split');
    filein_name = s{end};
    if file_path~=0
        files = dir([file_path '/*.abf']);
        num_files = size(files,1);
        for i=1:num_files
            filetoload = [file_path '/' files(i).name];
            Vtemp = abfload(filetoload);
            V(1,i,:) = Vtemp(:,1);
        end
        file_path = [file_path '/'];
    else
        V = [];
    end
    
elseif dataformat==3 %% autospike

    [filein_name, file_path] = uigetfile('*.asc','Select the data file');
    if file_path~=0
        filetoload = [file_path '/' filein_name];
        [data deltat] = LoadAsciiData(filetoload);
        V = zeros(length(data), 1, 1000);
        for k = 1:length(data)
            tLen = length(data(k).Volts);
            V(k,1,1:tLen) = data(k).Volts/30000;
            svalve(k,1).ton = data(k).Stimulus(1);
            svalve(k,1).toff = data(k).Stimulus(2);
        end
%         file_path = [file_path '/'];
    else
        V = [];
    end
    pid = zeros(size(V));
end

end