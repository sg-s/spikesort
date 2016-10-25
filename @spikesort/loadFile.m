% this function loads files 

function [s] = loadFile(s,src,~)
        if strcmp(get(src,'String'),'Load File')
            [s.file_name,s.path_name,filter_index] = uigetfile({'*.mat';'*.kontroller'});
            if ~s.file_name
                return
            end
        elseif strcmp(get(src,'String'),'<')
            if isempty(s.file_name)
                return
            else
                % first save what we had before
                save(strcat(s.path_name,s.file_name),'spikes','-append')


                if filter_index == 1
                    allfiles = dir(strcat(s.path_name,'*.mat'));
                else
                    allfiles = dir(strcat(s.path_name,'*.kontroller'));
                end
                thisfile = find(strcmp(s.file_name,{allfiles.name}))-1;
                if thisfile < 1
                    s.file_name = allfiles(end).name;
                else
                    s.file_name = allfiles(thisfile).name;    
                end
                
            end
        else
            if isempty(s.file_name)
                return
            else
                % first save what we had before
                save(strcat(s.path_name,s.file_name),'spikes','-append')
                
                if filter_index == 1
                    allfiles = dir(strcat(s.path_name,'*.mat'));
                else
                    allfiles = dir(strcat(s.path_name,'*.kontroller'));
                end
                thisfile = find(strcmp(s.file_name,{allfiles.name}))+1;
                if thisfile > length(allfiles)
                    s.file_name = allfiles(1).name;
                else
                    s.file_name = allfiles(thisfile).name;
                end
                
            end
        end

        % reset some pushbuttons and other things
        set(handles.discard_control,'Value',0)
        ThisControlParadigm = 1;
        ThisTrial = 1;
        temp = [];
        clear spikes
        spikes.A = 0;
        spikes.B = 0;
        spikes.artifacts = 0;

        
        temp = load(strcat(s.path_name,s.file_name),'-mat');
        try
            try
                delete(handles.load_waitbar)
            catch
            end
            handles.load_waitbar = waitbar(0.2, 'Loading data...');
            ControlParadigm = temp.ControlParadigm;
            data = temp.data;
            SamplingRate = temp.SamplingRate;
            OutputChannelNames = temp.OutputChannelNames;
            try
              metadata = temp.metadata;
              timestamps = temp.timestamps;
            catch
            end
            if isfield(temp,'spikes')
                spikes = temp.spikes;
            end
            clear temp

            

            waitbar(0.3,handles.load_waitbar,'Updating listboxes...')
            % update control signal listboxes with OutputChannelNames
            set(handles.valve_channel,'String',OutputChannelNames)

            % update stimulus listbox with all input channel names
            fl = fieldnames(data);

            % also add all the control signals
            try
                set(stim_channel,'String',[fl(:); OutputChannelNames]);
            catch
                set(stim_channel,'String',[fl(:) OutputChannelNames]);
            end

            % update response listbox with all the input channel names
            set(resp_channel,'String',fl);

            % some sanity checks
            if length(data) > length(ControlParadigm)
                error('Something is wrong with this file: more data than control paradigms.')
            end

            % find out which paradigms have data 
            n = structureElementLength(data); 

            % only show the paradigms with data
            temp = {ControlParadigm.Name};
            set(paradigm_chooser,'String',temp(find(n)),'Value',1);


            % go to the first paradigm with data. 
            ThisControlParadigm = find(n);
            ThisControlParadigm = ThisControlParadigm(1);


            n = n(ThisControlParadigm);
            if n
                temp  ={};
                for i = 1:n
                    temp{i} = strcat('Trial-',mat2str(i));
                end
                set(trial_chooser,'String',temp);
                ThisTrial = 1;
                set(trial_chooser,'String',temp);
            else
                set(trial_chooser,'String','No data');
                ThisTrial = NaN;
            end

            waitbar(0.4,s.handles.load_waitbar,'Guessing control signals...')
            % automatically default to picking the digital signals as the control signals
            digital_channels = zeros(1,length(OutputChannelNames));
            for i = 1:length(ControlParadigm)
                for j = 1:width(ControlParadigm(i).Outputs)
                    uv = (unique(ControlParadigm(i).Outputs(j,:)));
                    if length(uv) == 2 && sum(uv) == 1
                        digital_channels(j) = 1;
                    end
                   
                end
            end
            digital_channels = find(digital_channels);
            set(s.handles.valve_channel,'Value',digital_channels);


            waitbar(0.5,handles.load_waitbar,'Guessing stimulus and response...')
            temp = find(strcmp('PID', fl));
            if ~isempty(temp)
                set(stim_channel,'Value',temp);
            end
            temp = find(strcmp('voltage', fl));
            if ~isempty(temp)
                set(resp_channel,'Value',temp);

            end

            set(s.handles.main_fig,'Name',strcat(versionname,'--',s.file_name))

            % enable all controls
            waitbar(.7,s.handles.load_waitbar,'Enabling UI...')
            set(s.handles.sine_control,'Enable','on');
            set(s.handles.autosort_control,'Enable','on');
            set(s.handles.redo_control,'Enable','on');
            set(s.handles.findmode,'Enable','on');
            set(s.handles.filtermode,'Enable','on');
            set(s.handles.cluster_control,'Enable','on');
            set(s.handles.prev_trial,'Enable','on');
            set(s.handles.next_trial,'Enable','on');
            set(s.handles.prev_paradigm,'Enable','on');
            set(s.handles.next_paradigm,'Enable','on');
            set(s.handles.trial_chooser,'Enable','on');
            set(s.handles.paradigm_chooser,'Enable','on');
            set(s.handles.discard_control,'Enable','on');
            set(s.handles.metadata_text_control,'Enable','on')

            % check for amplitudes 
            waitbar(.7,handles.load_waitbar,'Checking to see amplitude data exists...')
            % check if we have spike_amplitude data
            if length(spikes)
                for i = 1:length(spikes)
                    for j = 1:width(spikes(i).A)
                        haz_data = 0;
                        if length(spikes(i).A(j,:)) > 2 
                            if isfield(spikes,'discard')
                                if length(spikes(i).discard) < j
                                    haz_data = 1;
                                else
                                    if ~spikes(i).discard(j)
                                        haz_data = 1;
                                    end
                                end
                            else
                                haz_data = 1;
                            end
                        end
                        if haz_data
                            recompute = 0;
                            if isfield(spikes,'amplitudes_A')
                                if width(spikes(i).amplitudes_A) < j
                                    recompute = 1;
                                    spikes(i).amplitudes_A = [];
                                    spikes(i).amplitudes_B = [];
                                elseif length(spikes(i).amplitudes_A(j,:)) < length(spikes(i).A(j,:))
                                    spikes(i).amplitudes_A = [];
                                    spikes(i).amplitudes_B = [];
                                    recompute = 1;
                                    
                                end
                            end
                            if recompute
                                A = spikes(i).A(j,:);
                            
                                spikes(i).amplitudes_A(j,:) = sparse(1,length(A));
                                spikes(i).amplitudes_B(j,:) = sparse(1,length(A));
                                V = data(i).voltage(j,:);
                                spikes(i).amplitudes_A(j,find(A))  =  ssdm_1DAmplitudes(V,pref.deltat,find(A),pref.invert_V);
                                B = spikes(i).B(j,:);
                                spikes(i).amplitudes_B(j,find(B))  =  ssdm_1DAmplitudes(V,pref.deltat,find(B),pref.invert_V);
                            end
                        end

                    end
                end
            end

            % check to see if metadata exists
            try
                set(s.handles.metadata_text_control,'String',metadata.spikesort_comment)
            catch
                set(s.handles.metadata_text_control,'String','')
            end

            % check to see if this file is tagged. 
            if isunix
                clear es
                es{1} = 'tag -l ';
                es{2} = strcat(s.path_name,s.file_name);
                [~,temp] = unix(strjoin(es));
                set(tag_control,'String',temp(strfind(temp,'.mat')+5:end-1));
            end

            % clean up
            close(handles.load_waitbar)

            plotStim;
            plotResp(@s.loadFileCallback);
        catch err
            if strcmp(get(src,'String'),'>')
                s.loadFileCallback(src)
            elseif strcmp(get(src,'String'),'<')
                s.loadFileCallback(src)
            else
                warning('Something went wrong with loading the file. The error was:')
                disp(err)
                disp('The error was here:')
                for ei = 1:length(err.stack)
                    disp(err.stack(ei))
                end
            end

        end
    end