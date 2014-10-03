function spikesort_format_convert(filename)
clc;
load([filename '.mat']);

    if 0
        CPrc = recombine_cparad(ControlParadigm);
        data_temp = recombine_data(data);
        data_orig = data;
        data = data_temp;
        CP_orig = ControlParadigm;
        ControlParadigm = CPrc;
    end
    
    nofrecparad = length(data); % total number of paradigms including start & end
    % inp_names = fieldnames(data);   % get input channel names
    flag = 0; % record formatted data
    if nofrecparad==1
        [noftrial, ldata] = size(data(1).voltage);
        if ldata<=SamplingRate
            display('None of the paradigms are recorded. This data includes only the "start" condition')
            display(['Skipping ' char(file_names(k)) ' ......' ])
            flag = 1; %do not record it
        end
    elseif nofrecparad>1
        
        % check is the paradigm is recorded or empty
        for i = 1:length(data)
            if isempty(data(i).voltage)
                fldnms = fieldnames(data(1));
                for fldnm = 1:length(fldnms)
                    data(1).(fldnms{fldnm})=zeros(1,SamplingRate);
                end
            end
        end
        
        if length(ControlParadigm)~=length(data)
            if size(data(nofrecparad).voltage,2)==size(ControlParadigm(nofrecparad).Outputs,2)
                % then the paradigm is recorded
                ORN = zeros([length(data)-1,size(data(nofrecparad).voltage)]);
                PID = zeros([length(data)-1,size(data(nofrecparad).voltage)]);
                stimsignal = zeros([length(data)-1,size(data(nofrecparad).voltage)]);
                valvesignal = zeros([length(data)-1,size(data(nofrecparad).voltage)]);
                for i=2:length(data); 
                    for trial = 1: size(data(i).voltage,1)
                    valvesignal(i-1,trial,:) = ControlParadigm(i).Outputs(4,:); 
                    ORN(i-1,trial,:) = data(i).voltage(trial,:);
                    PID(i-1,trial,:) = data(i).PID(trial,:);
                    stimsignal(i-1,trial,:) = data(i).PID(trial,:);
                    end
                end
            else
                display('Paradigm is not recorded')
                flag = 1; %do not record it
            end
        else
            if size(data(nofrecparad).voltage,2)==size(ControlParadigm(nofrecparad).Outputs,2)
            % then the paradigm is recorded
                ORN = zeros([length(data)-2,size(data(nofrecparad-1).voltage)]);
                PID = zeros([length(data)-2,size(data(nofrecparad-1).voltage)]);
                stimsignal = zeros([length(data)-2,size(data(nofrecparad-1).voltage)]);
                valvesignal = zeros([length(data)-2,size(data(nofrecparad-1).voltage)]);
                for i=2:length(data)-1; 
                    for trial = 1: size(data(i).voltage,1)
                    valvesignal(i-1,trial,:) = ControlParadigm(i).Outputs(4,:); 
                    ORN(i-1,trial,:) = data(i).voltage(trial,:);
                    PID(i-1,trial,:) = data(i).PID(trial,:);
                    stimsignal(i-1,trial,:) = data(i).PID(trial,:);
                    end
                end
            else
                display('Paradigm is not recorded')
                flag = 1; %do not record it
            end
        end
    end
    
    deltat=1/SamplingRate;

    if flag==0
        save([filename '_fmt.mat']);
    end
    clear all




