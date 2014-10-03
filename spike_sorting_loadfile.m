function [V filein_name file_path svalve] = spike_sorting_loadfile(dataformat)
% modified by Srinivas to include data about the stimulus on and off times.
% last edit at 9:43 , 29 April 2011.
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
            error('OOps! I havent coded for this case. What is missing is some code to extract the on and off times of the stimulus')
            
        else
            V = F.ORN;
            if isfield(F, 'stimsignal') % more forgiving code
                Stim = F.stimsignal;
            elseif isfield(F, 'stim_signal')
                Stim = F.stim_signal;
            end        
            % normalise and digitise signal
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
            waitbar(1,hw, 'DONE')
            close(hw)
        end
    else
        V = [];
    end
    
elseif dataformat==2 %% axoscope
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
    [file_path] = uigetdir(pwd);
    s = regexp(file_path, '\/', 'split');
    filein_name = s{end};
    if file_path~=0
        files = dir([file_path '/*.asc']);
        num_files = size(files,1);
        V = zeros(num_files, 1, 1);
        for i=1:num_files
            filetoload = [file_path '/' files(i).name];
            file = fopen(filetoload, 'rt');
            l = 1;
            W = 1;
            t = 0;
            k = 0;
            while l==1
                Vtemp = fgetl(file);
                if Vtemp==-1; l=0;
                elseif any(strfind(Vtemp,'Wave')); W = 1;
                    k = k+1;
                elseif any(strfind(Vtemp,'Digital')); W = 0;
                elseif any(strfind(Vtemp,'Sample rate')) && W==1
                    s = regexp(Vtemp, '\s', 'split');
                    deltat = 1/str2num(s{end});
                elseif ~any(strfind(Vtemp,';')) && W==1
                    t = t+1;
                    s = regexp(Vtemp, '\s', 'split');
                    V(i,k,t) = str2num(s{2});
                    tem = fscanf(file, '%f %f\n', [2 11/deltat]);
                    V(i,k,t+1:t+length(tem)) = tem(2,:)';                   
                end               
            end
            fclose(file)
        end
        file_path = [file_path '/'];
    else
        V = [];
    end
end

end