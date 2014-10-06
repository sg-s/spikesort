% spikesort.m
% Allows you to view, manipulate and sort spikes from experiments conducted by Kontroller. specifically meant to sort spikes from Drosophila ORNs
% spikesort was written by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function [] = ssort()
versionname = 'spikesort for Kontroller b(14.10.06)';

if ~strcmp(version('-release'),'2014b')
    error('Need MATLAB 2014b to run')
end

disp(versionname)

% support for Kontroller
ControlParadigm = [];
data = [];
SamplingRate = [];
OutputChannelNames = [];
metadata = [];
timestamps = [];

% core variables and parameters
deltat = 1e-4;
ThisControlParadigm = 1;
ThisTrial = 1;
temp = [];
spikes.A = 0;
spikes.B = 0;
spikes.artifacts = 0;
R = 0; % this holds the dimensionality reduced data
V = 0; % holds the current trace
Vf = 0; % filtered V
V_snippets = [];
time = 0;
loc =0; % holds current spike times
FileName = [];
PathName = [];


% handles
valve_channel = [];
load_waitbar = [];
h_scatter1 = [];
h_scatter2 = [];
h_scatter3 = [];

% make the master figure, and the axes to plot the voltage traces
fig = figure('position',[50 50 1200 700], 'Toolbar','figure','Menubar','none','Name',versionname,'NumberTitle','off','IntegerHandle','off');
ax = axes('parent',fig,'Position',[0.05 0.05 0.91 0.29]);
ax2 = axes('parent',fig,'Position',[0.05 0.37 0.91 0.18]);
linkaxes([ax2,ax],'x')

% make all the panels

% datapanel (allows you to choose what to plot where)
datapanel = uipanel('Title','Data','Position',[.8 .57 .16 .4]);
uicontrol(datapanel,'units','normalized','Position',[.02 .9 .510 .10],'Style', 'text', 'String', 'Control Signal','FontSize',10,'FontWeight','bold');
valve_channel = uicontrol(datapanel,'units','normalized','Position',[.03 .68 .910 .25],'Style', 'listbox', 'String', '','FontSize',10,'FontWeight','bold','Callback',@plot_valve,'Min',0,'Max',2);
uicontrol(datapanel,'units','normalized','Position',[.01 .56 .510 .10],'Style', 'text', 'String', 'Stimulus','FontSize',10,'FontWeight','bold');
stim_channel = uicontrol(datapanel,'units','normalized','Position',[.03 .38 .910 .20],'Style', 'listbox', 'String', '','FontSize',10,'FontWeight','bold');

uicontrol(datapanel,'units','normalized','Position',[.01 .25 .610 .10],'Style', 'text', 'String', 'Response','FontSize',10,'FontWeight','bold');
resp_channel = uicontrol(datapanel,'units','normalized','Position',[.01 .01 .910 .25],'Style', 'listbox', 'String', '','FontSize',10,'FontWeight','bold');


% file I/O
loadfile = uicontrol(fig,'units','normalized','Position',[.03 .9 .08 .07],'Style', 'pushbutton', 'String', 'Load File','FontSize',10,'FontWeight','bold','callback',@loadfilecallback);

% paradigms and trials
datachooserpanel = uipanel('Title','Paradigms and Trials','Position',[.03 .72 .25 .16]);
paradigm_chooser = uicontrol(datachooserpanel,'units','normalized','Position',[.25 .75 .5 .20],'Style', 'popupmenu', 'String', 'Choose Paradigm','callback',@choose_paradigm_callback);
next_paradigm = uicontrol(datachooserpanel,'units','normalized','Position',[.75 .65 .15 .33],'Style', 'pushbutton', 'String', '>','callback',@choose_paradigm_callback);
prev_paradigm = uicontrol(datachooserpanel,'units','normalized','Position',[.05 .65 .15 .33],'Style', 'pushbutton', 'String', '<','callback',@choose_paradigm_callback);

trial_chooser = uicontrol(datachooserpanel,'units','normalized','Position',[.25 .27 .5 .20],'Style', 'popupmenu', 'String', 'Choose Trial','callback',@choose_trial_callback);
next_trial = uicontrol(datachooserpanel,'units','normalized','Position',[.75 .15 .15 .33],'Style', 'pushbutton', 'String', '>','callback',@choose_trial_callback);
prev_trial = uicontrol(datachooserpanel,'units','normalized','Position',[.05 .15 .15 .33],'Style', 'pushbutton', 'String', '<','callback',@choose_trial_callback);

% dimension reduction and clustering panels
dimredpanel = uipanel('Title','Dimensionality Reduction','Position',[.29 .92 .21 .07]);
method_control = uicontrol(dimredpanel,'Style','popupmenu','String',{'1D Amplitudes','2D Amp+LFP','PCA'},'units','normalized','Position',[.02 .8 .9 .2],'Callback',@reduce_dimensions_callback,'Enable','off');
cluster_panel = uipanel('Title','Clustering','Position',[.51 .92 .21 .07]);
cluster_control = uicontrol(cluster_panel,'Style','popupmenu','String',{'Gaussian Fit','Manual','Density Peaks'},'units','normalized','Position',[.02 .8 .9 .2],'Callback',@find_cluster);

% manual override panel
manualpanel = uibuttongroup(fig,'Title','Manual Override','Position',[.29 .66 .11 .24]);
mode_new_A = uicontrol(manualpanel,'Position',[5 5 100 20], 'Style', 'radiobutton', 'String', '+A','FontSize',12);
mode_new_B = uicontrol(manualpanel,'Position',[5 35 100 20], 'Style', 'radiobutton', 'String', '+B','FontSize',12);
mode_delete = uicontrol(manualpanel,'Position',[5 65 100 20], 'Style', 'radiobutton', 'String', '-X','FontSize',12);
mode_A2B = uicontrol(manualpanel,'Position',[5 95 100 20], 'Style', 'radiobutton', 'String', 'A->B','FontSize',12);
mode_B2A = uicontrol(manualpanel,'Position',[5 125 100 20], 'Style', 'radiobutton', 'String', 'B->A','FontSize',12);
modify_control = uicontrol(fig,'units','normalized','Position',[.29 .60 .1 .05],'Style','pushbutton','String','Modify','Value',0,'Callback',@modify_callback);


% filter toggle switch
filtermode = uicontrol(fig,'units','normalized','Position',[.035 .65 .1 .05],'Style','togglebutton','String','Filter','Value',1,'Callback',@plot_resp);
findmode = uicontrol(fig,'units','normalized','Position',[.135 .65 .1 .05],'Style','togglebutton','String','Find Spikes','Value',1,'Callback',@plot_resp);

redo_control = uicontrol(fig,'units','normalized','Position',[.035 .60 .1 .05],'Style','pushbutton','String','Redo','Value',0,'Callback',@redo);
autosort_control = uicontrol(fig,'units','normalized','Position',[.135 .60 .1 .05],'Style','togglebutton','String','Autosort','Value',0);



    function redo(~,~)
        % need to reset spikes
        if length(spikes) >= ThisControlParadigm
            if width(spikes(ThisControlParadigm).A) >= ThisTrial
                spikes(ThisControlParadigm).A(ThisTrial,:) = 0;
                spikes(ThisControlParadigm).B(ThisTrial,:) = 0;
            else
                % all cool
            end
        else
            % should have no problem
        end       

        % update the plot
        plot_resp;
    end

    function loadfilecallback(~,~)
        [FileName,PathName] = uigetfile('.mat');
        load_waitbar = waitbar(0.2, 'Loading data...');
        temp=load(strcat(PathName,FileName));
        ControlParadigm = temp.ControlParadigm;
		data = temp.data;
		SamplingRate = temp.SamplingRate;
		OutputChannelNames = temp.OutputChannelNames;
		metadata = temp.metadata;
		timestamps = temp.timestamps;
        spikes = temp.spikes;
		clear temp

        waitbar(0.3,load_waitbar,'Updating listboxes...')
		% update control signal listboxes with OutputChannelNames
		set(valve_channel,'String',OutputChannelNames)

        % update stimulus listbox with all input channel names
        fl = fieldnames(data);
        set(stim_channel,'String',fl);

        % update response listbox with all the input channel names
        set(resp_channel,'String',fl);

		% update paradigm chooser with the first paradigm
		set(paradigm_chooser,'String',{ControlParadigm.Name},'Value',1);
		ThisControlParadigm = 1;
		n = Kontroller_ntrials(data); n = n(ThisControlParadigm);
        if n
            temp  ={};
            for i = 1:n
                temp{i} = strcat('Trial-',mat2str(i));
            end
            set(trial_chooser,'String',temp);
            ThisTrial = 1;
		    set(trial_chooser,'String',temp);
            plot_stim;
            plot_resp;
        else
            set(trial_chooser,'String','No data');
            ThisTrial = NaN;
        end

        waitbar(0.4,load_waitbar,'Guessing control signals...')
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

        set(valve_channel,'Value',find(digital_channels));


        waitbar(0.5,load_waitbar,'Guessing stimulus and response...')
        temp = find(strcmp('PID', fl));
        if ~isempty(temp)
            set(stim_channel,'Value',temp);
        end
        temp = find(strcmp('voltage', fl));
        if ~isempty(temp)
            set(resp_channel,'Value',temp);
            waitbar(.6,load_waitbar,'Finding artifacts in trace...')
            n = Kontroller_ntrials(data);
            for i = 1:length(data)
                if n(i)
                    temp = mdot(abs(data(i).voltage));
                    temp(temp>(mean(temp) + std(temp))) = 1;
                    temp(temp<1)= 0;
                    [ons,offs] = ComputeOnsOffs(temp);
                    % get widths right
                    ons(offs-ons==0) = ons(offs-ons==0) - 1;
                    offs(offs-ons==1) = offs(offs-ons==1) + 1;
                    ons = ons-2; offs = offs+2;
                    for j = 1:length(ons)
                        temp(ons(j):offs(j)) = 1;
                    end

                    data(i).voltage(:,logical(temp)) = 0;

                    % also suppress signals for 25 samples after any valve turns on
                    % this is a hack
                    temp = ComputeOnsOffs(ControlParadigm(i).Outputs(5,:));
                    data(i).voltage(:,temp:temp+25) = 0;
                    temp = ComputeOnsOffs(ControlParadigm(i).Outputs(6,:));
                    data(i).voltage(:,temp:temp+25) = 0;

                    

                end
            end

        end

        set(fig,'Name',strcat(versionname,'--',FileName))

    

        % clean up
        close(load_waitbar)
    end


    function choose_paradigm_callback(src,~)
        n = Kontroller_ntrials(data); 
        if src == paradigm_chooser
            ThisControlParadigm = get(paradigm_chooser,'Value');
        elseif src== next_paradigm
            if length(data) > ThisControlParadigm 
                ThisControlParadigm = ThisControlParadigm + 1;
                set(paradigm_chooser,'Value',ThisControlParadigm);
            end
        elseif src == prev_paradigm
            if ThisControlParadigm > 1
                ThisControlParadigm = ThisControlParadigm - 1;
                set(paradigm_chooser,'Value',ThisControlParadigm);
            end
        else
            error('unknown source of callback 109. probably being incorrectly being called by something.')
        end
        n = n(ThisControlParadigm);
        if n
            temp  ={};
            for i = 1:n
                temp{i} = strcat('Trial-',mat2str(i));
            end
            set(trial_chooser,'String',temp);
            set(trial_chooser,'Value',1);
            ThisTrial = 1;
        else
            set(trial_chooser,'String','No data');
            ThisTrial = NaN;
        end
        % update the plots
        plot_stim;
        plot_resp;
               
    end

    function choose_trial_callback(src,~)
        n = Kontroller_ntrials(data); 
        n = n(ThisControlParadigm);
        if src == trial_chooser
            ThisTrial = get(trial_chooser,'Value');
            disp('Moving directly to trial:')
            disp(ThisTrial)
        elseif src== next_trial
            if ThisTrial < n
                ThisTrial = ThisTrial +1;
                set(trial_chooser,'Value',ThisTrial);
                disp('Next trial')
            else
                % fake a call
                choose_paradigm_callback(next_paradigm);
            end
        elseif src == prev_trial
            if ThisTrial > 1
                ThisTrial = ThisTrial  - 1;
                set(trial_chooser,'Value',ThisTrial);
                disp('Previous trial')
            else
                % fake a call
                choose_paradigm_callback(prev_paradigm);
            end
        else
            error('unknown source of callback 173. probably being incorrectly being called by something.')
        end


        % update the plots
        plot_stim;
        plot_resp;
               
    end



    function plot_stim(~,~)
        % plot the stimulus
        n = Kontroller_ntrials(data); 
        cla(ax2)
        if n(ThisControlParadigm)
            plotwhat = get(stim_channel,'String');
            nchannels = length(get(stim_channel,'Value'));
            plot_these = get(stim_channel,'Value');
            c = jet(nchannels);
            if nchannels == 1
                c = [0 0 0];
            end
            for i = 1:nchannels
                plotthis = plotwhat{plot_these(i)};
                eval(strcat('temp=data(ThisControlParadigm).',plotthis,';'));
                temp = temp(ThisTrial,:);
                time = deltat*(1:length(temp));
                plot(ax2,time,temp,'Color',c(i,:)); hold on;
            end
        end


        % plot the control signals using thick lines
        if n(ThisControlParadigm)
            plotwhat = get(valve_channel,'String');
            nchannels = length(get(valve_channel,'Value'));
            plot_these = get(valve_channel,'Value');
            c = jet(nchannels);
            if nchannels == 1
                c = [0 0 0];
            end

            ymax = get(ax2,'YLim');
            ymin = ymax(1); ymax = ymax(2); dy = (ymax- .9*(ymax-ymin))/nchannels;
            thisy = ymax;

            for i = 1:nchannels
                temp=ControlParadigm(ThisControlParadigm).Outputs(plot_these(i),:);
                time = deltat*(1:length(temp));
                thisy = thisy - dy;
                temp = temp*thisy;
                temp(temp==0) = NaN;
                plot(ax2,time,temp,'Color',c(i,:),'LineWidth',5); hold on;
            end
        end

    end


    function plot_resp(~,~)
        % plot the response
        n = Kontroller_ntrials(data); 
        cla(ax)
        hold(ax,'on')
        if n(ThisControlParadigm)
            plotwhat = get(resp_channel,'String');
            plotthis = plotwhat{get(resp_channel,'Value')};
            eval(strcat('temp=data(ThisControlParadigm).',plotthis,';'));
            temp = temp(ThisTrial,:);
            time = deltat*(1:length(temp));
            
        end


        if get(filtermode,'Value') == 1
            disp('Need to filter data...')
            [V,Vf] = filter_trace(temp);
            

            % do we have to find spikes too?
            if get(findmode,'Value') == 1
                disp('need to find spikes...')
                loc=find_spikes(V);
                plot(ax,time,V,'k'); 
                % do we already have sorted spikes?
                if length(spikes) < ThisControlParadigm
                    % no spikes
                    disp('no spikes...')
                    loc = find_spikes(V);
                    if get(autosort_control,'Value') == 1
                        % sort spikes and show them
                        disp('Autosorting spikes...')
                        [A,B] = autosort;
                        h_scatter1 = scatter(ax,time(A),V(A),'r');
                        h_scatter2 = scatter(ax,time(B),V(B),'b');
                    else
                        disp('Not autosorting spikes')
                        h_scatter1 = scatter(ax,time(loc),V(loc));
                    end
                else
                    disp('spikes is at least this paradigm long')
                    % maybe?
                    if ThisTrial <= width(spikes(ThisControlParadigm).A) 
                        disp('spike matrix is suff. wide.')
                        % check...
                        if max(spikes(ThisControlParadigm).A(ThisTrial,:))
                            % yes, have spikes
                            disp('Have spikes. showing them. ')
                            A = find(spikes(ThisControlParadigm).A(ThisTrial,:));
                            B = find(spikes(ThisControlParadigm).B(ThisTrial,:));
                            h_scatter1 = scatter(ax,time(A),V(A),'r');
                            h_scatter2 = scatter(ax,time(B),V(B),'b');
                        else
                            disp('no spikes case 397')
                            if get(autosort_control,'Value') == 1
                                % sort spikes and show them
                                [A,B] = autosort;
                                h_scatter1 = scatter(ax,time(A),V(A),'r');
                                h_scatter2 = scatter(ax,time(B),V(B),'b');
                            else
                                disp('No need to autosort')
                                % no need to autosort
                                h_scatter1 = scatter(ax,time(loc),V(loc));
                            end
                        end
                    else
                        % no spikes
                        disp('spikes exists, but not for this trial')
                        if get(autosort_control,'Value') == 1
                            % sort spikes and show them
                            [A,B] = autosort;
                            h_scatter1 = scatter(ax,time(A),V(A),'r');
                            h_scatter2 = scatter(ax,time(B),V(B),'b');
                        else
                            disp('No need to autosort')
                            % no need to autosort
                            h_scatter1 = scatter(ax,time(loc),V(loc));
                        end
                    end
                end


                % now rescale the Y axes so that only the interesting bit is retained
                set(ax,'YLim',[1.1*min(V(loc)) -min(V(loc))]);


            else
                disp('No need to find spikes...')
                set(method_control,'Enable','off')
                plot(ax,time,V,'k'); 
            end
        else
            disp('Plotting data as is...')
            plot(ax,time,temp,'k');
        end

        
    end

    function [A,B] = autosort()
        reduce_dimensions_callback;
        [A,B]=find_cluster;

    end

    function plot_valve(~,~)
    	% get the channels to plot
    	valve_channels = get(valve_channel,'Value');
    	c = jet(length(valve_channels));
    	for i = 1:length(valve_channels)
    		this_valve = ControlParadigm(ThisControlParadigm).Outputs(valve_channels(i),:);
    	end
	end

    function [V, Vf] = filter_trace(V)
        Vf = filtfilt(ones(1,100)/100,1,V);
        V = V - Vf;
    end

    function loc = find_spikes(V)
        % find local minima 
        [~,loc] = findpeaks(-V,'MinPeakProminence',.03,'MinPeakDistance',10);

        set(method_control,'Enable','on')

    end

    function reduce_dimensions_callback(~,~)
        method=(get(method_control,'Value'));
        [R,V_snippets] = reduce_dimensions(method);
    end

    function [R,V_snippets] = reduce_dimensions(method)

        % take snippets for each putative spike
        t_before = 20;
        t_after = 25; % assumes dt = 1e-4
        V_snippets = NaN(t_before+t_after,length(loc));
        for i = 2:length(loc)-1
            V_snippets(:,i) = V(loc(i)-t_before+1:loc(i)+t_after);
        end
        loc(1) = []; V_snippets(:,1) = []; 
        loc(end) = []; V_snippets(:,end) = [];

        % remove noise and artifacts
        temp = find(max(V_snippets)>.15);
        V_snippets(:,temp) = [];
        loc(temp) = [];

        % update the spike markings
        delete(h_scatter1)
        h_scatter1 = scatter(ax,time(loc),V(loc));


        % now do different things based on the method chosen
        switch method
        case 1
            % find total spike amplitude for each
            spike_amplitude = zeros*loc;
            for i = 1:length(loc)
                spike_amplitude(i) = max(V_snippets(1:20,i)) - V(loc(i));
            end
            R = spike_amplitude;
            % only allow certain clustering 
            set(cluster_control,'String',{'Gaussian Fit'})

        

        case 2
            % find total spike amplitude for each
            spike_amplitude = zeros*loc;
            for i = 1:length(loc)
                spike_amplitude(i) = max(V_snippets(1:20,i)) - V(loc(i));
            end
            R = [spike_amplitude; Vf(loc)];
            save('R.mat','R','V_snippets')
            % only allow certain clustering 
            set(cluster_control,'String',{'Manual'})
        end
    end

    function [A,B] = find_cluster(~,~)
        % cluster based on the method
        cluster_methods = get(cluster_control,'String');
        this_cluster_method = get(cluster_control,'Value');
        this_cluster_method = cluster_methods{this_cluster_method};
        switch this_cluster_method
            case 'Gaussian Fit'
                [y,x] = hist(R,floor(length(R)/30));
                temp = fit(x(:),y(:),'gauss2');
                g1=temp.a1.*exp(-((x-temp.b1)./temp.c1).^2);
                g2=temp.a2.*exp(-((x-temp.b2)./temp.c2).^2);
                if temp.b1 > temp.b2
                    disp('456')
                    keyboard
                else
                    cutoff=find((g1-g2)>0,1,'last');
                    cutoff = x(cutoff);

                end

                % mark as A or B
                B = loc(R<cutoff);
                A = loc(R>=cutoff);
            case 'Manual'
                C = ManualCluster(R,V_snippets);
                B = loc(C==2);
                A = loc(C==1);

        end

        % mark them
        delete(h_scatter1)
        delete(h_scatter2)
        h_scatter1 = scatter(ax,time(A),V(A),'r');
        h_scatter2 = scatter(ax,time(B),V(B),'b');

        % save them
        spikes(ThisControlParadigm).A(ThisTrial,:) = sparse(1,length(time));
        spikes(ThisControlParadigm).A(ThisTrial,A) = 1;
        spikes(ThisControlParadigm).B(ThisTrial,:) = sparse(1,length(time));
        spikes(ThisControlParadigm).B(ThisTrial,B) = 1;

        % save them
        save(strcat(PathName,FileName),'spikes','-append')

    end




end


