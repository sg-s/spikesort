% spikesort.m
% Allows you to view, manipulate and sort spikes from experiments conducted by Kontroller. specifically meant to sort spikes from Drosophila ORNs
% spikesort was written by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% part of the spikesort package
% https://github.com/sg-s/spikesort
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function [] = spikesort()

% check dependencies 
dependencies = {'prettyFig','manualCluster','computeOnsOffs','dataHash','gitHash','argInNames','cache','bandPass','oss','raster2','sem','rsquare','spiketimes2f','tsne','fast_tsne'};
for si = 1:length(dependencies)
    err_message = ['spikesort needs ' dependencies{si} ' to run, which was not found. Read the docs. to make sure you have installed all dependencies.'];
    assert(exist(dependencies{si},'file')==2,err_message)
end

if verLessThan('matlab', '8.0.1')
    error('Need MATLAB 2014b or better to run')
end

% check the signal processing toolbox version
if verLessThan('signal','6.22')
    error('Need Signal Processing toolbox version 6.22 or higher')
end

% get git build_number for all toolboxes
toolboxes = {'srinivas.gs_mtools','spikesort','t-sne','bhtsne'};
build_numbers = checkDeps(toolboxes);
versionname = strcat('spikesort for Kontroller (Build-',oval(build_numbers(2)),')'); 

% load preferences
pref = readPref;

% add src folder to path
addpath([fileparts(which(mfilename)) oss 'src'])

% generate placeholder variables
ControlParadigm = [];
data = [];
SamplingRate = [];
OutputChannelNames = [];
metadata = [];
timestamps = [];
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
file_name = [];
path_name = [];

% handles
handles.valve_channel = [];
handles.load_waitbar = [];
handles.h_scatter1 = [];
handles.h_scatter2 = [];
handles.main_fig = [];

%               ##     ##    ###    ##    ## ########    ##     ## #### 
%               ###   ###   ## ##   ##   ##  ##          ##     ##  ##  
%               #### ####  ##   ##  ##  ##   ##          ##     ##  ##  
%               ## ### ## ##     ## #####    ######      ##     ##  ##  
%               ##     ## ######### ##  ##   ##          ##     ##  ##  
%               ##     ## ##     ## ##   ##  ##          ##     ##  ##  
%               ##     ## ##     ## ##    ## ########     #######  #### 


% make the master figure, and the axes to plot the voltage traces
handles.main_fig = figure('position',[50 50 1200 700], 'Toolbar','figure','Menubar','none','Name',versionname,'NumberTitle','off','IntegerHandle','off','WindowButtonDownFcn',@mousecallback,'WindowScrollWheelFcn',@scroll,'CloseRequestFcn',@closess);
temp =  findall(handles.main_fig,'Type','uitoggletool','-or','Type','uipushtool');

% make plots menu
handles.menu1 = uimenu('Label','Make Plots...');
uimenu(handles.menu1,'Label','Raster','Callback',@rasterPlot);
uimenu(handles.menu1,'Label','Firing Rate','Callback',@firingRatePlot);

% pre-processing
handles.menu2 = uimenu('Label','Tools');
uimenu(handles.menu2,'Label','Template Match','Callback',@matchTemplate);
handles.remove_artifacts_menu = uimenu(handles.menu2,'Label','Remove Artifacts','Callback',@removeArtifacts,'Checked',pref.remove_artifacts);
uimenu(handles.menu2,'Label','Reload preferences','Callback',@reloadPreferences,'Separator','on');
uimenu(handles.menu2,'Label','Reset zoom','Callback',@resetZoom);


delete(temp([1:8 11:15]))


% make the two axes
handles.ax1 = axes('parent',handles.main_fig,'Position',[0.07 0.05 0.87 0.29]); hold on
jump_back = uicontrol(handles.main_fig,'units','normalized','Position',[0 .04 .04 .50],'Style', 'pushbutton', 'String', '<','callback',@jump);
jump_fwd = uicontrol(handles.main_fig,'units','normalized','Position',[.96 .04 .04 .50],'Style', 'pushbutton', 'String', '>','callback',@jump);
handles.ax2 = axes('parent',handles.main_fig,'Position',[0.07 0.37 0.87 0.18]); hold on
linkaxes([handles.ax2,handles.ax1],'x')

% make dummy plots on these axes, for placeholders later on
handles.ax1_data = plot(handles.ax1,NaN,NaN);
handles.ax1_spike_marker = plot(handles.ax1,NaN,NaN);
handles.ax1_A_spikes = plot(handles.ax1,NaN,NaN);
handles.ax1_B_spikes = plot(handles.ax1,NaN,NaN);
handles.ax1_all_spikes = plot(handles.ax1,NaN,NaN);
handles.ax1_ignored_data = plot(handles.ax1,NaN,NaN);

% now some for ax1
handles.ax2_data = plot(handles.ax2,NaN,NaN);
for si = 1:10
    handles.ax2_control_signals(si) = plot(handles.ax2,NaN,NaN);
end


% make all the panels

% datapanel (allows you to choose what to plot where)
datapanel = uipanel('Title','Data','Position',[.8 .57 .16 .4]);
uicontrol(datapanel,'units','normalized','Position',[.02 .9 .510 .10],'Style', 'text', 'String', 'Control Signal','FontSize',pref.fs,'FontWeight',pref.fw);
handles.valve_channel = uicontrol(datapanel,'units','normalized','Position',[.03 .68 .910 .25],'Style', 'listbox', 'String', '','FontSize',pref.fs,'FontWeight',pref.fw,'Callback',@plotValve,'Min',0,'Max',2);
uicontrol(datapanel,'units','normalized','Position',[.01 .56 .510 .10],'Style', 'text', 'String', 'Stimulus','FontSize',pref.fs,'FontWeight',pref.fw);
stim_channel = uicontrol(datapanel,'units','normalized','Position',[.03 .38 .910 .20],'Style', 'listbox', 'String', '','FontSize',pref.fs,'FontWeight',pref.fw,'Callback',@plotStim);

uicontrol(datapanel,'units','normalized','Position',[.01 .25 .610 .10],'Style', 'text', 'String', 'Response','FontSize',pref.fs,'FontWeight',pref.fw);
resp_channel = uicontrol(datapanel,'units','normalized','Position',[.01 .01 .910 .25],'Style', 'listbox', 'String', '','FontSize',pref.fs,'FontWeight',pref.fw);


% file I/O
uicontrol(handles.main_fig,'units','normalized','Position',[.10 .92 .07 .07],'Style', 'pushbutton', 'String', 'Load File','FontSize',pref.fs,'FontWeight',pref.fw,'callback',@loadFileCallback);
uicontrol(handles.main_fig,'units','normalized','Position',[.05 .93 .03 .05],'Style', 'pushbutton', 'String', '<','FontSize',pref.fs,'FontWeight',pref.fw,'callback',@loadFileCallback);
uicontrol(handles.main_fig,'units','normalized','Position',[.19 .93 .03 .05],'Style', 'pushbutton', 'String', '>','FontSize',pref.fs,'FontWeight',pref.fw,'callback',@loadFileCallback);

% paradigms and trials
datachooserpanel = uipanel('Title','Paradigms and Trials','Position',[.03 .75 .25 .16]);
paradigm_chooser = uicontrol(datachooserpanel,'units','normalized','Position',[.25 .75 .5 .20],'Style', 'popupmenu', 'String', 'Choose Paradigm','callback',@chooseParadigmCallback,'Enable','off');
next_paradigm = uicontrol(datachooserpanel,'units','normalized','Position',[.75 .65 .15 .33],'Style', 'pushbutton', 'String', '>','callback',@chooseParadigmCallback,'Enable','off');
prev_paradigm = uicontrol(datachooserpanel,'units','normalized','Position',[.05 .65 .15 .33],'Style', 'pushbutton', 'String', '<','callback',@chooseParadigmCallback,'Enable','off');

trial_chooser = uicontrol(datachooserpanel,'units','normalized','Position',[.25 .27 .5 .20],'Style', 'popupmenu', 'String', 'Choose Trial','callback',@chooseTrialCallback,'Enable','off');
next_trial = uicontrol(datachooserpanel,'units','normalized','Position',[.75 .15 .15 .33],'Style', 'pushbutton', 'String', '>','callback',@chooseTrialCallback,'Enable','off');
prev_trial = uicontrol(datachooserpanel,'units','normalized','Position',[.05 .15 .15 .33],'Style', 'pushbutton', 'String', '<','callback',@chooseTrialCallback,'Enable','off');

% dimension reduction and clustering panels
dimredpanel = uipanel('Title','Dimensionality Reduction','Position',[.25 .92 .17 .07]);
% find the available methods
look_here = [fileparts(mfilename('fullpath')) oss 'src' oss];
 % this is where we should look for methods
avail_methods=dir(strcat(look_here,'ssdm_*.m'));
avail_methods={avail_methods.name};
for oi = 1:length(avail_methods)
    temp = avail_methods{oi};
    avail_methods{oi} = temp(6:end-2);
end
clear oi; 
method_control = uicontrol(dimredpanel,'Style','popupmenu','String',avail_methods,'units','normalized','Position',[.02 .6 .9 .2],'Callback',@reduceDimensionsCallback,'Enable','off');

% find the available methods for clustering

avail_methods=dir(strcat(look_here,'sscm_*.m'));
avail_methods={avail_methods.name};
for oi = 1:length(avail_methods)
    temp = avail_methods{oi};
    avail_methods{oi} = temp(6:end-2);
end
clear oi
cluster_panel = uipanel('Title','Clustering','Position',[.43 .92 .17 .07]);
cluster_control = uicontrol(cluster_panel,'Style','popupmenu','String',avail_methods,'units','normalized','Position',[.02 .6 .9 .2],'Callback',@findCluster,'Enable','off');


% metadata panel
metadata_panel = uipanel('Title','Metadata','Position',[.29 .57 .21 .15]);
metadata_text_control = uicontrol(metadata_panel,'Style','edit','String','','units','normalized','Position',[.03 .3 .94 .7],'Callback',@updateMetadata,'Enable','off','Max',5,'Min',1,'HorizontalAlignment','left');
uicontrol(metadata_panel,'Style','pushbutton','String','Generate Summary','units','normalized','Position',[.03 .035 .45 .2],'Callback',@generateSummary);

% disable tagging on non unix systems
if ispc
else
    tag_control = uicontrol(metadata_panel,'Style','edit','String','+Tag, or -Tag','units','normalized','Position',[.5 .035 .45 .2],'Callback',@addTag);

    % modify environment to get paths for non-matlab code right
    path1 = getenv('PATH');
    if isempty(strfind(path1,':/usr/local/bin'))
        path1 = [path1 ':/usr/local/bin'];
    end
    if isempty(strfind(path1,[':' fileparts(which('fast_tsne'))]))
        path1 = [path1 ':' fileparts(which('fast_tsne'))];
    end
    
    setenv('PATH', path1);

end

% manual override panel
manualpanel = uibuttongroup(handles.main_fig,'Title','Manual Override','Position',[.68 .56 .11 .34]);
uicontrol(manualpanel,'units','normalized','Position',[.1 7/8 .8 1/9],'Style','pushbutton','String','Mark All in View','Callback',@markAllCallback);
mode_new_A = uicontrol(manualpanel,'units','normalized','Position',[.1 6/8 .8 1/9], 'Style', 'radiobutton', 'String', '+A','FontSize',pref.fs);
mode_new_B = uicontrol(manualpanel,'units','normalized','Position',[.1 5/8 .8 1/9], 'Style', 'radiobutton', 'String', '+B','FontSize',pref.fs);
mode_delete = uicontrol(manualpanel,'units','normalized','Position',[.1 4/8 .8 1/9], 'Style', 'radiobutton', 'String', '-X','FontSize',pref.fs);
mode_A2B = uicontrol(manualpanel,'units','normalized','Position',[.1 3/8 .8 1/9], 'Style', 'radiobutton', 'String', 'A->B','FontSize',pref.fs);
mode_B2A = uicontrol(manualpanel,'units','normalized','Position',[.1 2/8 .8 1/9], 'Style', 'radiobutton', 'String', 'B->A','FontSize',pref.fs);
uicontrol(manualpanel,'units','normalized','Position',[.1 1/8 .8 1/9],'Style','pushbutton','String','Discard View','Callback',@modifyTraceDiscard);
uicontrol(manualpanel,'units','normalized','Position',[.1 0/8 .8 1/9],'Style','pushbutton','String','Retain View','Callback',@modifyTraceDiscard);


% various toggle switches and pushbuttons
filtermode = uicontrol(handles.main_fig,'units','normalized','Position',[.03 .69 .12 .05],'Style','togglebutton','String','Filter','Value',1,'Callback',@plotResp,'Enable','off');
findmode = uicontrol(handles.main_fig,'units','normalized','Position',[.16 .69 .12 .05],'Style','togglebutton','String','Find Spikes','Value',1,'Callback',@plotResp,'Enable','off');

redo_control = uicontrol(handles.main_fig,'units','normalized','Position',[.03 .64 .12 .05],'Style','pushbutton','String','Redo','Value',0,'Callback',@redo,'Enable','off');
autosort_control = uicontrol(handles.main_fig,'units','normalized','Position',[.16 .64 .12 .05],'Style','togglebutton','String','Autosort','Value',0,'Enable','off','Callback',@autosortCallback);

handles.sine_control = uicontrol(handles.main_fig,'units','normalized','Position',[.03 .59 .12 .05],'Style','togglebutton','String',' Kill Ringing','Value',0,'Callback',@plotResp,'Enable','off');
discard_control = uicontrol(handles.main_fig,'units','normalized','Position',[.16 .59 .12 .05],'Style','togglebutton','String',' Discard','Value',0,'Callback',@discard,'Enable','off');


%% begin subfunctions
% all subfunctions here are listed alphabetically

    function autosortCallback(~,~)
        if autosort_control.Value == 1
            autosort_control.FontWeight = 'bold';
            autosort_control.String = 'AUTOSORT ON';
        else
            autosort_control.FontWeight = 'normal';
            autosort_control.String = 'Autosort Off';
        end
    end

    function addTag(src,~)
        % matlab wrapper for tag, which adds BSD tags to the file we are working on. *nix only. 
        tag = get(src,'String');
        temp = whos('file_name');
        if ~isempty(file_name) && strcmp(temp.class,'char')
            % tag the file with the given tag
            clear es
            es{1} = 'tag -a ';
            es{2} = tag;
            es{3} = strcat(path_name,file_name);
            try
                unix(strjoin(es));
            catch
            end
        end
    end

    function [A,B,N] = autosort()
        % automatically sorts data, if possible. 
        reduceDimensionsCallback;
        [A,B,N]=findCluster;

    end

    function [] = matchTemplate(~,~)
        % template match
        nchannels = length(get(handles.valve_channel,'Value'));
        plot_these = get(handles.valve_channel,'Value');
        control_signal = ControlParadigm(ThisControlParadigm).Outputs(plot_these,:);

        if size(control_signal,2) > size(control_signal,1)
            control_signal = control_signal';
        end

        % make the template object
        template.control_signal_channels = plot_these;

        figure, hold on
        for i = 1:width(control_signal)
            temp = control_signal(:,i);
            % find ons and offs and build templates
            on_transitions = find(diff(temp)==1);
            off_transitions = find(diff(temp)==-1);

            after = round(pref.template_width);
            if isnan(after) || after < 11
                after = 50;
            end

            if isempty(on_transitions)
            else
                % trim some edge cases
                on_transitions(find(on_transitions+after>(length(V)-1))) = [];
                off_transitions(find(off_transitions+after>(length(V)-1))) = [];

                on_template = zeros(after+1,length(on_transitions));
                off_template = zeros(after+1,length(on_transitions));
                for ti = 1:length(on_transitions)
                    snippet = V(on_transitions(ti):on_transitions(ti)+after);
                    snippet = snippet - snippet(1);
                    on_template(:,ti) = snippet;

                    snippet = V(off_transitions(ti):off_transitions(ti)+after);
                    snippet = snippet - snippet(1);
                    off_template(:,ti) = snippet(:);
                end
                off_template = (mean(off_template,2));
                on_template = (mean(on_template,2));

                subplot(width(control_signal),2,2*(i-1)+1);
                plot(on_template)
                title('On Template')

                subplot(width(control_signal),2,2*(i-1)+2);
                plot(off_template)
                title('Off Template')

                template(i).on_template = on_template;
                template(i).off_template = off_template;

            end

            save('template.mat','template');    
        end
    end


    function [] = removeArtifacts(~,~)
        if strcmp(get(handles.remove_artifacts_menu,'Checked'),'off')
            set(handles.remove_artifacts_menu,'Checked','on');
        else
            set(handles.remove_artifacts_menu,'Checked','off');
        end
        plotResp;
    end


    function chooseParadigmCallback(src,~)
        % callback that is run when we pick a new paradigm, either through the buttons or the drop down menu
        paradigms_with_data = find(structureElementLength(data)); 
        if src == paradigm_chooser
            ThisControlParadigm = paradigms_with_data(get(paradigm_chooser,'Value'));
        elseif src== next_paradigm
            if max(paradigms_with_data) > ThisControlParadigm 
                ThisControlParadigm = paradigms_with_data(find(paradigms_with_data == ThisControlParadigm)+1);
                set(paradigm_chooser,'Value',find(paradigms_with_data == ThisControlParadigm));
            end
        elseif src == prev_paradigm
            if ThisControlParadigm > paradigms_with_data(1)
                ThisControlParadigm = paradigms_with_data(find(paradigms_with_data == ThisControlParadigm)-1);
                set(paradigm_chooser,'Value',find(paradigms_with_data == ThisControlParadigm));
            end
        else
            error('unknown source of callback 109. probably being incorrectly being called by something.')
        end

        n = structureElementLength(data);
        n = n(ThisControlParadigm);
        temp  ={};
        for i = 1:n
            temp{i} = strcat('Trial-',mat2str(i));
        end
        set(trial_chooser,'String',temp);
        if src == prev_paradigm
            set(trial_chooser,'Value',n);
            ThisTrial = n;
        else
            set(trial_chooser,'Value',1);
            ThisTrial = 1;
        end
        
        % update the plots
        plotStim;
        plotResp(@chooseParadigmCallback);

        % update Discard control
        updateDiscardControl;
               
    end

    function chooseTrialCallback(src,~)
        n = structureElementLength(data); 
        if length(n) < ThisControlParadigm
            return
        else
            n = n(ThisControlParadigm);
        end
        if src == trial_chooser
            ThisTrial = get(trial_chooser,'Value');
            % update the plots
            plotStim;
            plotResp(@chooseTrialCallback);
        elseif src== next_trial
            if ThisTrial < n
                ThisTrial = ThisTrial +1;
                set(trial_chooser,'Value',ThisTrial);
                % update the plots
                plotStim;
                plotResp(@chooseTrialCallback);
            else
                % fake a call
                chooseParadigmCallback(next_paradigm);
            end
        elseif src == prev_trial
            if ThisTrial > 1
                ThisTrial = ThisTrial  - 1;
                set(trial_chooser,'Value',ThisTrial);
                % update the plots
                plotStim;
                plotResp(@chooseTrialCallback);
            else
                % fake a call
                chooseParadigmCallback(prev_paradigm);
            end
        else
            error('unknown source of callback 173. probably being incorrectly being called by something.')
        end    

        % update Discard control
        updateDiscardControl;

    end

    function closess(~,~)
        % close everything and save everything
        try
            if ~isempty(path_name) && ~isempty(file_name) 
                if ischar(path_name) && ischar(file_name)
                    save(strcat(path_name,file_name),'spikes','-append')
                end
            end
        catch
            warning('Error saving data!')
        end

        delete(handles.main_fig)

    end

    function discard(~,~)


        if get(discard_control,'Value') == 0
            % reset discard
            if isfield(spikes,'discard')
                spikes(ThisControlParadigm).discard(ThisTrial) = 0;
            end
            set(discard_control,'String','Discard','FontWeight','normal')
        else
            set(discard_control,'String','Discarded!','FontWeight','bold')
            
            % need to reset spikes
            if length(spikes) >= ThisControlParadigm
                if width(spikes(ThisControlParadigm).A) >= ThisTrial
                    spikes(ThisControlParadigm).A(ThisTrial,:) = 0;
                    spikes(ThisControlParadigm).B(ThisTrial,:) = 0;
                    spikes(ThisControlParadigm).amplitudes_A(ThisTrial,:) = 0;
                    spikes(ThisControlParadigm).amplitudes_B(ThisTrial,:) = 0;

                else
                    % all cool
                end
            else
                % should have no problem
            end   

            % mark as discarded
            spikes(ThisControlParadigm).discard(ThisTrial) = 1;
            save(strcat(path_name,file_name),'spikes','-append')
            
        end
        

        % update screen
        plotResp;
    end

    function reloadPreferences(~,~)
        pref = readPref;
    end


    function [A,B,N] = findCluster(~,~)
        % cluster based on the method
        methodname = get(cluster_control,'String');
        method = get(cluster_control,'Value');
        methodname = strcat('sscm_',methodname{method});
        req_arg = argInNames(methodname); % find out what arguments the external method needs
        % start constructing the eval string
        es = strcat('[A,B,N]=',methodname,'(');
        for ri =  1:length(req_arg)
            es = strcat(es,req_arg{ri},',');
        end
        clear ri
        es = es(1:end-1);
        es = strcat(es,');');
        try
            eval(es);
        catch exc
            ms = strcat(methodname, ' ran into an error: ', exc.message);
            msgbox(ms,'spikesort');
            disp('The full stack is:')
            for ei = 1:length(exc.stack)
                disp(exc.stack(ei))
            end
            return
        end
        clear es
        
        % try to remove doublets
        if pref.remove_doublets
            [A,B]=removeDoublets(A,B);
        end

        % mark them
        set(handles.ax1_A_spikes,'XData',time(A),'YData',V(A),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','r','LineStyle','none');
        set(handles.ax1_B_spikes,'XData',time(B),'YData',V(B),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','b','LineStyle','none');
        set(handles.ax1_all_spikes,'XData',NaN,'YData',NaN);

        % remove noise spikes from the loc vector
        loc = setdiff(loc,N);

        % save them
        try
            spikes(ThisControlParadigm).A(ThisTrial,:) = sparse(1,length(time));      
            spikes(ThisControlParadigm).B(ThisTrial,:) = sparse(1,length(time));
            spikes(ThisControlParadigm).N(ThisTrial,:) = sparse(1,length(time));
            spikes(ThisControlParadigm).amplitudes_A(ThisTrial,:) = sparse(1,length(time));
            spikes(ThisControlParadigm).amplitudes_B(ThisTrial,:) = sparse(1,length(time));
        catch
            spikes(ThisControlParadigm).A = sparse(ThisTrial,length(time));
            spikes(ThisControlParadigm).B = sparse(ThisTrial,length(time));
            spikes(ThisControlParadigm).N = sparse(ThisTrial,length(time));
            spikes(ThisControlParadigm).amplitudes_A = sparse(ThisTrial,length(time));
            spikes(ThisControlParadigm).amplitudes_B = sparse(ThisTrial,length(time));

        end
        spikes(ThisControlParadigm).A(ThisTrial,A) = 1;
        spikes(ThisControlParadigm).B(ThisTrial,B) = 1;
        spikes(ThisControlParadigm).N(ThisTrial,N) = 1;

        % also save spike amplitudes
        try
            spikes(ThisControlParadigm).amplitudes_A(ThisTrial,A)  =  ssdm_1DAmplitudes(V,A);
        catch
        end
        try
            spikes(ThisControlParadigm).amplitudes_B(ThisTrial,B)  =  ssdm_1DAmplitudes(V,B);
        catch
        end

        % save them
        save(strcat(path_name,file_name),'spikes','-append')

    end



    function firingRatePlot(~,~)
        if pref.show_r2
            figure('outerposition',[0 0 1200 800],'PaperUnits','points','PaperSize',[1200 800]); hold on
            sp(1)=subplot(2,4,1:3); hold on
            sp(2)=subplot(2,4,5:7); hold on
            sp(3)=subplot(2,4,4); hold on
            sp(4)=subplot(2,4,8); hold on
        else
            figure('outerposition',[0 0 1000 800],'PaperUnits','points','PaperSize',[1000 800]); hold on
            sp(1)=subplot(2,1,1); hold on
            sp(2)=subplot(2,1,2); hold on
        end
        ylabel(sp(1),'Firing Rate (Hz)')
        title(sp(1),'A neuron')
        title(sp(2),'B neuron')
        ylabel(sp(2),'Firing Rate (Hz)')
        xlabel(sp(2),'Time (s)')
        
        haz_data = [];
        for i = 1:length(spikes)
            if length(spikes(i).A) > 1
                haz_data = [haz_data i];
            end
        end
        if length(haz_data) == 1
            c = [0 0 0];
        else
            c = parula(length(haz_data));
        end
        L = {};
        f_waitbar = waitbar(0.1, 'Computing Firing rates...');
        for i = 1:length(haz_data)
            l(i) = plot(sp(1),NaN,NaN,'Color',c(i,:));
            waitbar((i-1)/length(spikes),f_waitbar);
            if length(spikes(haz_data(i)).A) > 1

                % do A
                time = (1:length(spikes(haz_data(i)).A))/SamplingRate;
                [fA,tA] = spiketimes2f(spikes(haz_data(i)).A,time,pref.firing_rate_dt,pref.firing_rate_window_size);
                tA = tA(:);
                % remove trials with no spikes
                fA(:,sum(fA) == 0) = [];

            
                % censor fA when we ignore some data
                if isfield(spikes,'use_trace_fragment')
                    if any(sum(spikes(haz_data(i)).use_trace_fragment') < length(spikes(haz_data(i)).A))
                        % there is excluded data somewhere
                        for j = 1:width(spikes(haz_data(i)).use_trace_fragment)
                            try
                                fA(spikes(haz_data(i)).use_trace_fragment(j,1:10:end),j) = NaN;
                            catch
                            end
                        end
                    end
                end

                if width(fA) > 1
                    if pref.show_firing_rate_trials
                        for j = 1:width(fA)
                            l(i) = plot(sp(1),tA,fA(:,j),'Color',c(i,:));
                        end
                    else
                       l(i) = plot(sp(1),tA,nanmean(fA,2),'Color',c(i,:));
                    end
                    if pref.show_firing_rate_r2
                        hash = dataHash(fA);
                        cached_data = (cache(hash));
                        if isempty(cached_data)
                            r2 = rsquare(fA);
                        else
                            r2 = cached_data;
                            cache(hash,r2);
                        end
                        axes(sp(3))
                        imagescnan(r2)
                        caxis([0 1])
                        colorbar
                        axis image
                        axis off
                        
                    end
                else
                    try
                       l(i) = plot(sp(1),tA,(fA),'Color',c(i,:));
                    catch
                        % no data, ignore.
                    end
                end
                

                % do B    
                time = (1:length(spikes(haz_data(i)).B))/SamplingRate;
                [fB,tB] = spiketimes2f(spikes(haz_data(i)).B,time);
                tB = tB(:);
                % remove trials with no spikes
                fB(:,sum(fB) == 0) = [];

                if width(fB) > 1
                    if pref.show_firing_rate_trials
                        for j = 1:width(fB)
                            l(i) = plot(sp(2),tA,fB(:,j),'Color',c(i,:));
                        end
                    else
                       l(i) = plot(sp(2),tB,nanmean(fB,2),'Color',c(i,:));
                    end
                    if pref.show_firing_rate_r2
                        hash = dataHash(fB);
                        cached_data = (cache(hash));
                        if isempty(cached_data)
                            r2 = rsquare(fB);
                        else
                            r2 = cached_data;
                            cache(hash,r2);
                        end
                        axes(sp(4))
                        imagescnan(r2)
                        caxis([0 1])
                        colorbar
                        axis image
                        axis off
                    end
                else
                    try
                       l(i) = plot(sp(2),tB,(fB),'Color',c(i,:));
                    catch
                    end
                end


                L = [L strrep(ControlParadigm(haz_data(i)).Name,'_','-')];
                
            end
        end
        
        legend(l,L)
        close(f_waitbar)
        linkaxes(sp(1:2))
        prettyFig('font_units','points');
        console('Made a firing rate plot.')
    end

    function generateSummary(~,~)
        allfiles = dir(strcat(path_name,'*.mat'));
        if any(find(strcmp('cached.mat',{allfiles.name})))
            allfiles(find(strcmp('cached.mat',{allfiles.name}))) = [];
        end
        if any(find(strcmp('cached_log.mat',{allfiles.name})))
            allfiles(find(strcmp('cached_log.mat',{allfiles.name}))) = [];
        end
        summary_string = '';
        fileID = fopen('summary.log','w');
        for i = 1:length(allfiles)
            summary_string = strcat(summary_string,'\n', allfiles(i).name);
            temp = load(allfiles(i).name,'metadata');
            metadata = temp.metadata;
            if size(metadata.spikesort_comment,1) > 1
                metadata.spikesort_comment = metadata.spikesort_comment(1,:);
            end    
            if isfield(metadata,'spikesort_comment')
                summary_string = strcat(summary_string,'\t\t', metadata.spikesort_comment);
            else
                % no comment on this file
                summary_string = strcat(summary_string,'\t\t', 'no comment');
            end

        end
        
        fprintf(fileID,summary_string);
        fclose(fileID);
    end

    function jump(src,~)
        % get the digital channels
        digital_channels = get(handles.valve_channel,'Value');

        % find out where we are
        xl= floor(get(handles.ax1,'XLim')/pref.deltat);
        

        if src == jump_fwd
            next_on = Inf;

            % find the next digital channel switch in any channel
            for i = 1:length(digital_channels)
                this_channel = ControlParadigm(ThisControlParadigm).Outputs(digital_channels(i),:);
                [ons] = computeOnsOffs(this_channel);
                ons(ons<xl(2)) = [];
                next_on = min([next_on(:); ons(:)]);
            end
            if ~isinf(next_on)
                set(handles.ax1,'Xlim',[time(next_on) time(next_on+diff(xl))]);
            end
        elseif src == jump_back
            prev_on = -Inf;

            % find the prev digital channel switch in any channel
            for i = 1:length(digital_channels)
                this_channel = ControlParadigm(ThisControlParadigm).Outputs(digital_channels(i),:);
                [ons] = computeOnsOffs(this_channel);
                ons(ons>xl(1)-1) = [];
                prev_on = max([prev_on(:); ons(:)]);
            end
            if ~isinf(-prev_on)
                set(handles.ax1,'Xlim',[time(prev_on) time(prev_on+diff(xl))]);
            end
        else
            error('Unknown source of call to jump');
        end
    end
    
    function loadFileCallback(src,~)
        if strcmp(get(src,'String'),'Load File')
            [file_name,path_name] = uigetfile('.mat');
            if ~file_name
                return
            end
        elseif strcmp(get(src,'String'),'<')
            if isempty(file_name)
                return
            else
                % first save what we had before
                save(strcat(path_name,file_name),'spikes','-append')

                allfiles = dir(strcat(path_name,'*.mat'));
                thisfile = find(strcmp(file_name,{allfiles.name}))-1;
                if thisfile < 1
                    file_name = allfiles(end).name;
                else
                    file_name = allfiles(thisfile).name;    
                end
                
            end
        else
            if isempty(file_name)
                return
            else
                % first save what we had before
                save(strcat(path_name,file_name),'spikes','-append')
                
                allfiles = dir(strcat(path_name,'*.mat'));
                thisfile = find(strcmp(file_name,{allfiles.name}))+1;
                if thisfile > length(allfiles)
                    file_name = allfiles(1).name;
                else
                    file_name = allfiles(thisfile).name;
                end
                
            end
        end

        % reset some pushbuttons and other things
        set(discard_control,'Value',0)
        ThisControlParadigm = 1;
        ThisTrial = 1;
        temp = [];
        clear spikes
        spikes.A = 0;
        spikes.B = 0;
        spikes.artifacts = 0;
        R = 0; % this holds the dimensionality reduced data
        V = 0; % holds the current trace
        Vf = 0; % filtered V
        V_snippets = [];
        time = 0;
        loc =0; % holds current spike times

        console(strcat('Loading file:',path_name,'/',file_name))
        
        temp=load(strcat(path_name,file_name));
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
            set(stim_channel,'String',[fl(:); OutputChannelNames(:)]);

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

            waitbar(0.4,handles.load_waitbar,'Guessing control signals...')
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
            set(handles.valve_channel,'Value',digital_channels);


            waitbar(0.5,handles.load_waitbar,'Guessing stimulus and response...')
            temp = find(strcmp('PID', fl));
            if ~isempty(temp)
                set(stim_channel,'Value',temp);
            end
            temp = find(strcmp('voltage', fl));
            if ~isempty(temp)
                set(resp_channel,'Value',temp);

            end

            set(handles.main_fig,'Name',strcat(versionname,'--',file_name))

            % enable all controls
            waitbar(.7,handles.load_waitbar,'Enabling UI...')
            set(handles.sine_control,'Enable','on');
            set(autosort_control,'Enable','on');
            set(redo_control,'Enable','on');
            set(findmode,'Enable','on');
            set(filtermode,'Enable','on');
            set(cluster_control,'Enable','on');
            set(prev_trial,'Enable','on');
            set(next_trial,'Enable','on');
            set(prev_paradigm,'Enable','on');
            set(next_paradigm,'Enable','on');
            set(trial_chooser,'Enable','on');
            set(paradigm_chooser,'Enable','on');
            set(discard_control,'Enable','on');
            set(metadata_text_control,'Enable','on')

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
                set(metadata_text_control,'String',metadata.spikesort_comment)
            catch
                set(metadata_text_control,'String','')
            end

            % check to see if this file is tagged. 
            if isunix
                clear es
                es{1} = 'tag -l ';
                es{2} = strcat(path_name,file_name);
                [~,temp] = unix(strjoin(es));
                set(tag_control,'String',temp(strfind(temp,'.mat')+5:end-1));
            end

            % clean up
            close(handles.load_waitbar)

            plotStim;
            plotResp(@loadFileCallback);
        catch err
            if strcmp(get(src,'String'),'>')
                loadFileCallback(src)
            elseif strcmp(get(src,'String'),'<')
                loadFileCallback(src)
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



    function resetZoom(~,~)
        set(handles.ax1,'XLim',[min(time) max(time)]);

        temp = sort(V);
        handles.ax1.YLim(1) = mean(temp(1:floor(length(temp)*.05)))*3;
        temp = sort(V,'descend');
        handles.ax1.YLim(2) = mean(temp(1:floor(length(temp)*.05)))*3;

    end


    function markAllCallback(~,~)
        % get view
        xmin = get(handles.ax1,'XLim');
        xmin = xmin/pref.deltat;
        xmax = xmin(2); xmin=xmin(1);

        % get mode
        if get(mode_B2A,'Value')
            % add to A spikes
            spikes(ThisControlParadigm).A(ThisTrial,loc(loc>xmin & loc<xmax))  = 1;
            % remove b spikes
            spikes(ThisControlParadigm).B(ThisTrial,loc(loc>xmin & loc<xmax))  = 0;

        elseif get(mode_A2B,'Value')
            % add to B spikes
            spikes(ThisControlParadigm).B(ThisTrial,loc(loc>xmin & loc<xmax))  = 1;
            % remove A spikes
            spikes(ThisControlParadigm).A(ThisTrial,loc(loc>xmin & loc<xmax))  = 0;
        elseif get(mode_delete,'Value')
            spikes(ThisControlParadigm).A(ThisTrial,loc(loc>xmin & loc<xmax))  = 0;
            spikes(ThisControlParadigm).B(ThisTrial,loc(loc>xmin & loc<xmax))  = 0;
            spikes(ThisControlParadigm).N(ThisTrial,loc(loc>xmin & loc<xmax))  = 1;
        end

        % update plot
        plotResp(@markAllCallback); 

    end

    function modify(p)
        % check that the point is within the axes
        ylimits = get(handles.ax1,'YLim');
        if p(2) > ylimits(2) || p(2) < ylimits(1)
            console('Rejecting point: Y exceeded')
            return
        end
        xlimits = get(handles.ax1,'XLim');
        if p(1) > xlimits(2) || p(1) < xlimits(1)
            console('Rejecting point: X exceeded')
            return
        end

        p(1) = p(1)/pref.deltat;
        xrange = (xlimits(2) - xlimits(1))/pref.deltat;
        yrange = ylimits(2) - ylimits(1);
        % get the width over which to search for spikes dynamically from the zoom factor
        s = floor((.005*xrange));
        if get(mode_new_A,'Value')==1
            % snip out a small waveform around the point
            if pref.invert_V
                [~,loc] = min(V(floor(p(1)-s:p(1)+s)));
            else
                [~,loc] = max(V(floor(p(1)-s:p(1)+s)));
            end
            spikes(ThisControlParadigm).A(ThisTrial,-s+loc+floor(p(1))) = 1;
            A = find(spikes(ThisControlParadigm).A(ThisTrial,:));
            spikes(ThisControlParadigm).amplitudes_A(ThisTrial,A)  =  ssdm_1DAmplitudes(V,A);
        elseif get(mode_new_B,'Value')==1
            % snip out a small waveform around the point
            if pref.invert_V
                [~,loc] = min(V(floor(p(1)-s:p(1)+s)));
            else
                [~,loc] = max(V(floor(p(1)-s:p(1)+s)));
            end
            spikes(ThisControlParadigm).B(ThisTrial,-s+loc+floor(p(1))) = 1;
            B = find(spikes(ThisControlParadigm).B(ThisTrial,:));
            spikes(ThisControlParadigm).amplitudes_B(ThisTrial,B)  =  ssdm_1DAmplitudes(V,B);
        elseif get(mode_delete,'Value')==1
            % find the closest spike
            Aspiketimes = find(spikes(ThisControlParadigm).A(ThisTrial,:));
            Bspiketimes = find(spikes(ThisControlParadigm).B(ThisTrial,:));

            dA= (((Aspiketimes-p(1))/(xrange)).^2  + ((V(Aspiketimes) - p(2))/(5*yrange)).^2);
            dB= (((Bspiketimes-p(1))/(xrange)).^2  + ((V(Bspiketimes) - p(2))/(5*yrange)).^2);
            dist_to_A = min(dA);
            dist_to_B = min(dB);
            if dist_to_A < dist_to_B
                [~,closest_spike] = min(dA);
                spikes(ThisControlParadigm).A(ThisTrial,Aspiketimes(closest_spike)) = 0;
                spikes(ThisControlParadigm).N(ThisTrial,Aspiketimes(closest_spike)) = 1;
                A = find(spikes(ThisControlParadigm).A(ThisTrial,:));
                spikes(ThisControlParadigm).amplitudes_A(ThisTrial,A)  =  ssdm_1DAmplitudes(V,A);
            else
                [~,closest_spike] = min(dB);
                spikes(ThisControlParadigm).B(ThisTrial,Bspiketimes(closest_spike)) = 0;
                spikes(ThisControlParadigm).N(ThisTrial,Aspiketimes(closest_spike)) = 1;
                B = find(spikes(ThisControlParadigm).B(ThisTrial,:));
                spikes(ThisControlParadigm).amplitudes_B(ThisTrial,B)  =  ssdm_1DAmplitudes(V,B);
            end
        elseif get(mode_A2B,'Value')==1 
            % find the closest A spike
            Aspiketimes = find(spikes(ThisControlParadigm).A(ThisTrial,:));
            dA= (((Aspiketimes-p(1))/(xrange)).^2  + ((V(Aspiketimes) - p(2))/(5*yrange)).^2);
            [~,closest_spike] = min(dA);
            spikes(ThisControlParadigm).A(ThisTrial,Aspiketimes(closest_spike)) = 0;
            spikes(ThisControlParadigm).B(ThisTrial,Aspiketimes(closest_spike)) = 1;
            A = find(spikes(ThisControlParadigm).A(ThisTrial,:));
            spikes(ThisControlParadigm).amplitudes_A(ThisTrial,A)  =  ssdm_1DAmplitudes(V,A);
            B = find(spikes(ThisControlParadigm).B(ThisTrial,:));
            spikes(ThisControlParadigm).amplitudes_B(ThisTrial,B)  =  ssdm_1DAmplitudes(V,B);

        elseif get(mode_B2A,'Value')==1
            % find the closest B spike
            Bspiketimes = find(spikes(ThisControlParadigm).B(ThisTrial,:));
            dB= (((Bspiketimes-p(1))/(xrange)).^2  + ((V(Bspiketimes) - p(2))/(5*yrange)).^2);
            [~,closest_spike] = min(dB);
            spikes(ThisControlParadigm).A(ThisTrial,Bspiketimes(closest_spike)) = 1;
            spikes(ThisControlParadigm).B(ThisTrial,Bspiketimes(closest_spike)) = 0;
            A = find(spikes(ThisControlParadigm).A(ThisTrial,:));
            spikes(ThisControlParadigm).amplitudes_A(ThisTrial,A)  =  ssdm_1DAmplitudes(V,A);
            B = find(spikes(ThisControlParadigm).B(ThisTrial,:));
            spikes(ThisControlParadigm).amplitudes_B(ThisTrial,B)  =  ssdm_1DAmplitudes(V,B);
        end

        % update plot
        plotResp(@modify);

    end

    function modifyTraceDiscard(src,~)
        % first get the viewport
        xl = get(handles.ax1,'XLim');
        xl = floor(xl/pref.deltat);
        if xl(1) < 1
            xl(1) = 1;
        end
        if xl(2) > length(V)
            xl(2) = length(V);
        end

        % check if we already have some discard information stored in spikes
        if length(spikes) < ThisControlParadigm
            spikes(ThisControlParadigm).use_trace_fragment = ones(1,length(V));
        else
            if isfield(spikes,'use_trace_fragment')
                if width(spikes(ThisControlParadigm).use_trace_fragment) < ThisTrial
                    spikes(ThisControlParadigm).use_trace_fragment(ThisTrial,:) = ones(1,length(V));
                else
                    
                end
            else
                spikes(ThisControlParadigm).use_trace_fragment(ThisTrial,:) = ones(1,length(V));
            end
        end


        if strcmp(get(src,'String'),'Discard View')
            spikes(ThisControlParadigm).use_trace_fragment(ThisTrial,xl(1):xl(2)) = 0;
            % disp('Discarding view for trial #')
            % disp(ThisTrial)
            % disp('Discarding data from:')
            % disp(xl*pref.deltat)
        elseif strcmp(get(src,'String'),'Retain View')
            spikes(ThisControlParadigm).use_trace_fragment(ThisTrial,xl(1):xl(2)) = 1;
        else
            error('modifyTraceDiscard ran into an error because I was called by a function that I did not expect. I am meant to be called only by the discard view or the retain view pushbuttons.')
        end

        plotResp(@modifyTraceDiscard);
    end

    function mousecallback(~,~)
        p = get(handles.ax1,'CurrentPoint');
        p = p(1,1:2);
        modify(p)
    end

    function plotResp(src,~)
        % clear some old stuff
        set(handles.ax1_ignored_data,'XData',NaN,'YData',NaN);
        set(handles.ax1_all_spikes,'XData',NaN,'YData',NaN);
        set(handles.ax1_B_spikes,'XData',NaN,'YData',NaN);
        set(handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
        set(handles.ax1_spike_marker,'XData',NaN,'YData',NaN);

        % plot the response
        clear time V Vf % flush old variables 
        n = structureElementLength(data); 
        
        if n(ThisControlParadigm)
            plotwhat = get(resp_channel,'String');
            plotthis = plotwhat{get(resp_channel,'Value')};
            eval(strcat('temp=data(ThisControlParadigm).',plotthis,';'));
            temp = temp(ThisTrial,:);
            time = pref.deltat*(1:length(temp));
        else
            return    
        end

        % check if we have chosen to discard this
        if isfield(spikes,'discard')
            try spikes(ThisControlParadigm).discard(ThisTrial);
                if spikes(ThisControlParadigm).discard(ThisTrial) == 1
                    % set the control
                    set(discard_control,'Value',1);
                    set(handles.ax1_data,'XData',time,'YData',temp,'Color','k','Parent',handles.ax1);
                    return
                else

                    set(discard_control,'Value',0);
                end
            catch
                set(discard_control,'Value',0);
            end
        end

        V = temp;

        if get(filtermode,'Value') == 1
            if pref.ssDebug 
                disp('plotResp 1251: filtering trace...')
            end
            lc = 1/pref.band_pass(1);
            lc = floor(lc/pref.deltat);
            hc = 1/pref.band_pass(2);
            hc = floor(hc/pref.deltat);
            if pref.useFastBandPass
                [V,Vf] = fastBandPass(V,lc,hc);
            else
                [V,Vf] = bandPass(V,lc,hc);
            end
        end 

        if strcmp(get(handles.remove_artifacts_menu,'Checked'),'on')
            this_control = ControlParadigm(ThisControlParadigm).Outputs;
            V = removeArtifactsUsingTemplate(V,this_control,pref);
        end

        set(handles.ax1_data,'XData',time,'YData',V,'Color','k','Parent',handles.ax1); 

        % check if we are discarding part of the trace
        ignored_fragments = 0*V;
        if isfield(spikes,'use_trace_fragment')
            if length(spikes) < ThisControlParadigm
            else
                if ~isempty(spikes(ThisControlParadigm).use_trace_fragment)
                    if width(spikes(ThisControlParadigm).use_trace_fragment) < ThisTrial
                    else
                        ignored_fragments = ~spikes(ThisControlParadigm).use_trace_fragment(ThisTrial,:);
                        set(handles.ax1_ignored_data,'XData',time(ignored_fragments),'YData',V(ignored_fragments),'Color',[.5 .5 .5],'Parent',handles.ax1);
                        if pref.ssDebug
                            disp('Ignoring part of the trace')
                        end
                    end
                end
            end
        end


        if get(handles.sine_control,'Value')
            % operate in 1 second blocks
            % for z = round(1/(pref.deltat)):round(1/(pref.deltat)):length(V)
            %     textbar(z,length(V))
            %     a = max([z - round(1/(pref.deltat)) 1]);
            %     temp = V(a:z);
            %     s = std(temp);
            %     % rm_this = temp>2*s | temp < -2*s;
            %     x = (1:length(temp))';
            %     ff = fit(x(:),temp(:),'sin1');
            %     V(a:z) = V(a:z) - ff(x)';

            % end
            % set(handles.ax1_data,'XData',time,'YData',V,'Color','k','Parent',handles.ax1); 
        end

        % do we have to find spikes too?
        V_censored = V;
        if any(ignored_fragments)
            V_censored(ignored_fragments) = NaN;
        end
        if get(findmode,'Value') == 1
        
            if pref.ssDebug
                disp('plotResp 1304: invoking findSpikes...')
            end
            loc = findSpikes(V_censored); 
            set(method_control,'Enable','on')

            % do we already have sorted spikes?
            if length(spikes) < ThisControlParadigm
                % no spikes
      

                loc = findSpikes(V_censored); % disp('pref.ssDebug-1284')
                set(method_control,'Enable','on')
                if get(autosort_control,'Value') == 1
                    % sort spikes and show them
                   
                    [A,B] = autosort;
                    set(handles.ax1_A_spikes,'XData',time(A),'YData',V(A),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','r','LineStyle','none');
                    set(handles.ax1_B_spikes,'XData',time(B),'YData',V(B),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','b','LineStyle','none');
                else
                    set(handles.ax1_all_spikes,'XData',time(loc),'YData',V(loc),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','m','LineStyle','none');
                    set(handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
                    set(handles.ax1_B_spikes,'XData',NaN,'YData',NaN);

                end
            else
           
                % maybe?
                if ThisTrial <= width(spikes(ThisControlParadigm).A) 
              
                    % check...
                    if max(spikes(ThisControlParadigm).A(ThisTrial,:))
                        % yes, have spikes
              
                        A = find(spikes(ThisControlParadigm).A(ThisTrial,:));
                        try
                            B = find(spikes(ThisControlParadigm).B(ThisTrial,:));
                        catch
                            warning('B spikes missing for this trial...')
                            B = [];
                        end
                        loc = [A B];
                        set(handles.ax1_A_spikes,'XData',time(A),'YData',V(A),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','r','LineStyle','none');
                        set(handles.ax1_B_spikes,'XData',time(B),'YData',V(B),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','b','LineStyle','none');
                    else
    
                        if get(autosort_control,'Value') == 1
                            % sort spikes and show them
                            [A,B] = autosort;
                            set(handles.ax1_A_spikes,'XData',time(A),'YData',V(A),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','r','LineStyle','none');
                            set(handles.ax1_B_spikes,'XData',time(B),'YData',V(B),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','b','LineStyle','none');
                        else
                            console('No need to autosort')
                            % no need to autosort, just show the identified peaks
                            set(handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
                            set(handles.ax1_B_spikes,'XData',NaN,'YData',NaN);
                            set(handles.ax1_all_spikes,'XData',time(loc),'YData',V(loc),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','m','LineStyle','none');
                        end
                    end
                else
                    % no spikes
                    if get(autosort_control,'Value') == 1
                        % sort spikes and show them
                        [A,B] = autosort;
                        set(handles.ax1_A_spikes,'XData',time(A),'YData',V(A),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','r','LineStyle','none');
                            set(handles.ax1_B_spikes,'XData',time(B),'YData',V(B),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','b','LineStyle','none');
                    else
                        % no need to autosort, no spikes to show
                        set(handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
                            set(handles.ax1_B_spikes,'XData',NaN,'YData',NaN);
                            set(handles.ax1_all_spikes,'XData',time(loc),'YData',V(loc),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','m','LineStyle','none');
                    end
                end
            end


            xlim = get(handles.ax1,'XLim');
            
            if xlim(1) < min(time)
                xlim(1) = min(time);
            end
            if xlim(2) > max(time)
                xlim(1) = min(time);
                xlim(2) = max(time);
            end
            xlim(2) = (floor(xlim(2)/pref.deltat))*pref.deltat;
            xlim(1) = (floor(xlim(1)/pref.deltat))*pref.deltat;
            
            ylim(2) = max(V(find(time==xlim(1)):find(time==xlim(2))));
            ylim(1) = min(V(find(time==xlim(1)):find(time==xlim(2))));
            yr = 2*nanstd(V(find(time==xlim(1)):find(time==xlim(2))));

            if (isnan(yr)) || any(isnan(xlim)) || any(isnan(ylim))

                xlim(2) = time(find(isnan(V),1,'first')-1);
                xlim(1) = pref.deltat;
                ylim(2) = max(V(1:find(isnan(V),1,'first')-1));
                ylim(1) = min(V(1:find(isnan(V),1,'first')-1));
                yr = 2*std(V(find(time==xlim(1)):find(time==xlim(2))));
            else

                if yr==0
                    set(handles.ax1,'YLim',[ylim(1)-1 ylim(2)+1]);
                else
                    set(handles.ax1,'YLim',[ylim(1)-yr ylim(2)+yr]);
                end
            end

        else
            % ('No need to find spikes...')
            set(handles.ax1,'YLim',[min(V) max(V)]);
            set(method_control,'Enable','off')
        end

        % this exception exists because XLimits weirdly go to [0 1] and "manual" even though I don't set them. 
        xl  =get(handles.ax1,'XLim');
        if xl(2) == 1
            set(handles.ax1,'XLim',[min(time) max(time)]);
            set(handles.ax1,'XLimMode','auto')
        else
            % unless the X-limits have been manually changed, fix them
            if strcmp(get(handles.ax1,'XLimMode'),'auto')
                set(handles.ax1,'XLim',[min(time) max(time)]);
                % we spoof this because we want to distinguish this case from when the user zooms
                set(handles.ax1,'XLimMode','auto')
            end
        end
    end

    function plotStim(~,~)
        % plot the stimulus and other things in handles.ax2
        n = structureElementLength(data); 
        miny = Inf; maxy = -Inf;
        if n(ThisControlParadigm)
            plotwhat = get(stim_channel,'String');
            nchannels = length(get(stim_channel,'Value'));
            plot_these = get(stim_channel,'Value');
            c = jet(nchannels);
            if nchannels == 1
                c = [0 0 0];
            end
            for i = 1:nchannels
                
                if plot_these(i) > length(fieldnames(data))
                    temp= ControlParadigm(ThisControlParadigm).Outputs(plot_these(i) - length(fieldnames(data)),:);
                else
                    plotthis = plotwhat{plot_these(i)};
                    eval(strcat('temp=data(ThisControlParadigm).',plotthis,';'));
                    temp = temp(ThisTrial,:);
                end
                time = pref.deltat*(1:length(temp));

                set(handles.ax2_data,'XData',time,'YData',temp,'Color',c(i,:),'Parent',handles.ax2);
                miny  =min([miny min(temp)]);
                maxy  =max([maxy max(temp)]);
            end
        end

        % rescale the Y axis appropriately
        if ~isinf(sum(abs([maxy miny])))
            if maxy > miny
                set(handles.ax2,'YLim',[miny maxy+.1*(maxy-miny)]);
            end
        end

        % plot the control signals using thick lines
        if n(ThisControlParadigm)
            plotwhat = get(handles.valve_channel,'String');
            nchannels = length(get(handles.valve_channel,'Value'));
            plot_these = get(handles.valve_channel,'Value');
            c = jet(nchannels);
            if nchannels == 1
                c = [0 0 0];
            end

            ymax = get(handles.ax2,'YLim');
            ymin = ymax(1); ymax = ymax(2); 
            y0 = (ymax- .1*(ymax-ymin));
            dy = (ymax-y0)/nchannels;
            thisy = ymax;

            % first try to erase all the old stuff
            for i = 1:10
                set(handles.ax2_control_signals(i),'XData',NaN,'YData',NaN);
            end

            for i = 1:nchannels
                temp=ControlParadigm(ThisControlParadigm).Outputs(plot_these(i),:);
                if pref.plot_control
                    % plot the control signal directly
                    time = pref.deltat*(1:length(temp));
                    set(handles.ax2_data,'XData',time,'YData',temp,'LineWidth',1); hold on;
                    try
                        set(handles.ax2,'YLim',[min(temp) max(temp)]);
                    catch
                    end
                else
                    temp(temp>0)=1;
                    time = pref.deltat*(1:length(temp));
                    thisy = thisy - dy;
                    temp = temp*thisy;
                    temp(temp==0) = NaN;
                    set(handles.ax2_control_signals(i),'XData',time,'YData',temp,'Color',c(i,:),'LineWidth',5,'Parent',handles.ax2); hold on;
                end
            end
        end
        
    end

    function plotValve(~,~)
        % get the channels to plot
        handles.valve_channels = get(handles.valve_channel,'Value');
        c = jet(length(handles.valve_channels));
        for i = 1:length(handles.valve_channels)
            this_valve = ControlParadigm(ThisControlParadigm).Outputs(handles.valve_channels(i),:);
        end
        plotStim;
    end

    function rasterPlot(~,~)
        figure('outerposition',[0 0 1000 500],'PaperUnits','points','PaperSize',[1000 500]); hold on
        yoffset = 0;
        ytick=0;
        L ={};
        for i = 1:length(spikes)
            if length(spikes(i).A) > 1
                raster2(spikes(i).A,spikes(i).B,yoffset);
                yoffset = yoffset + width(spikes(i).A)*2 + 1;
                ytick = [ytick yoffset];
                L = [L strrep(ControlParadigm(i).Name,'_','-')];
                
            end
        end
        set(gca,'YTick',ytick(1:end-1)+diff(ytick)/2,'YTickLabel',L,'box','on')
        xlabel('Time (s)')
        console('Made a raster plot.')
    
    end

    function redo(~,~)
        % need to reset spikes
        if length(spikes) >= ThisControlParadigm
            if width(spikes(ThisControlParadigm).A) >= ThisTrial
                spikes(ThisControlParadigm).A(ThisTrial,:) = 0;
                spikes(ThisControlParadigm).B(ThisTrial,:) = 0;
                spikes(ThisControlParadigm).amplitudes_A(ThisTrial,:) = 0;
                spikes(ThisControlParadigm).amplitudes_B(ThisTrial,:) = 0;
                spikes(ThisControlParadigm).use_trace_fragment(ThisTrial,:) = 1;
            else
                % all cool
            end
        else
            % should have no problem
        end       

        % update the plot
        plotResp;

        % save the clear
        save(strcat(path_name,file_name),'spikes','-append')

    end

    function [R,V_snippets] = reduceDimensions(method)

        % take snippets for each putative spike
        R = [];
        V_snippets = NaN(pref.t_before+pref.t_after,length(loc));
        if loc(1) < pref.t_before+1
            loc(1) = [];
            V_snippets(:,1) = []; 
        end
        if loc(end) + pref.t_after+1 > length(V)
            loc(end) = [];
            V_snippets(:,end) = [];
        end
        for i = 1:length(loc)
            V_snippets(:,i) = V(loc(i)-pref.t_before+1:loc(i)+pref.t_after);
        end

        if pref.ssDebug
            disp('These many V_snippets:')
            disp(length(V_snippets))
        end

        % update the spike markings
        set(handles.ax1_all_spikes,'XData',time(loc),'YData',V(loc),'Marker','o','MarkerSize',pref.marker_size,'Parent',handles.ax1,'MarkerEdgeColor','g','LineStyle','none');

        % now do different things based on the method chosen
        methodname = get(method_control,'String');
        methodname = strcat('ssdm_',methodname{method});
        req_arg = argInNames(methodname); % find out what arguments the external method needs
        % start constructing the eval string
        es = strcat('R=',methodname,'(');
        for ri =  1:length(req_arg)
            es = strcat(es,req_arg{ri},',');
        end
        clear ri
        es = es(1:end-1);
        es = strcat(es,');');
        try
            eval(es);
        catch exc
            disp(exc.stack(1))
            ms = strcat(methodname, ' ran into an error: ', exc.message,'. Look at the command window for more details.');
            msgbox(ms,'spikesort');
            return
        end
        clear es
    end

    function reduceDimensionsCallback(~,~)
        method=(get(method_control,'Value'));
        [R,V_snippets] = reduceDimensions(method);
    end

    function [A,B] = removeDoublets(A,B)
        % remove B doublets and assign one of them to A
        % get the refractory time 
        B2A_cand = B(diff(B) < pref.doublet_distance);
        B2A_alt = B(find(diff(B) < pref.doublet_distance)+1);
        B2A = NaN*B2A_cand;
        
        % for each candidate, find the one in the pair that is further away from adjacent A spikes
        for i = 1:length(B2A_cand)
            if min(abs(B2A_cand(i)-A)) < min(abs(B2A_alt(i)-A))
                % candidate closer to A spike
                B2A(i) = B2A_cand(i);
            else
                % alternate closer to A spike
                B2A(i) = B2A_alt(i);
            end
        end

        if pref.ssDebug
            disp('B2A doublet resolution. #spikes swapped:')
            disp(length(B2A))
        end
        % swap 
        A = sort(unique([A B2A]));
        B = setdiff(B,B2A);

        % remove A doublets and assign one of them to B
        A2B_cand = A(diff(A) < pref.doublet_distance);
        A2B_alt = A(find(diff(A) < pref.doublet_distance)+1);

        % don't undo what we just did
        temp = ismember(A2B_alt,unique([B2A_cand B2A_alt])) | ismember(A2B_cand,unique([B2A_cand B2A_alt]));
        A2B_cand(temp) = [];
        A2B_alt(temp) = [];
        
        % for each candidate, find the one in the pair that is further away from adjacent B spikes
        for i = 1:length(A2B_cand)
            if min(abs(A2B_cand(i)-B)) < min(abs(A2B_alt(i)-B))
                % candidate closer to B spike
            else
                % alternate closer to B spike
                A2B_cand(i) = A2B_alt(i);
            end
        end

        % swap 
        B = sort(unique([B A2B_cand]));
        A = setdiff(A,A2B_cand);

        if pref.ssDebug
            disp('A2B doublet resolution. #spikes swapped:')
            disp(length(A2B_cand))
        end
    end

    function scroll(~,event)
        xlimits = get(handles.ax1,'XLim');
        xrange = (xlimits(2) - xlimits(1));
        scroll_amount = event.VerticalScrollCount;
        if pref.smart_scroll
            if scroll_amount < 0
                if xlimits(1) <= min(time)
                    return
                else
                    newlim(1) = max([min(time) (xlimits(1)-.2*xrange)]);
                    newlim(2) = newlim(1)+xrange;
                end
            else
                if xlimits(2) >= max(time)
                    return
                else
                    newlim(2) = min([max(time) (xlimits(2)+.2*xrange)]);
                    newlim(1) = newlim(2)-xrange;
                end
            end
        else
            % find number of spikes in view
            n_spikes_in_view = length(loc(loc>(xlimits(1)/pref.deltat) & loc<(xlimits(2)/pref.deltat)));
            if scroll_amount > 0
                try
                    newlim(1) = min([max(time) (xlimits(1)+.2*xrange)]);
                    newlim(2) = loc(find(loc > newlim(1)/pref.deltat,1,'first') + n_spikes_in_view)*pref.deltat;
                catch
                end
            else
                try
                    newlim(2) = max([min(time)+xrange (xlimits(2)-.2*xrange)]);
                    newlim(1) = loc(find(loc < newlim(2)/pref.deltat,1,'last') - n_spikes_in_view)*pref.deltat;
                catch
                end
            end
        end
        
        try
            set(handles.ax1,'Xlim',newlim)
        catch
        end

        xlim = get(handles.ax1,'XLim');
        if xlim(1) < min(time)
            xlim(1) = min(time);
        end
        if xlim(2) > max(time)
            xlim(2) = max(time);
        end
        xlim(2) = (floor(xlim(2)/pref.deltat))*pref.deltat;
        xlim(1) = (floor(xlim(1)/pref.deltat))*pref.deltat;
        ylim(2) = max(V(find(time==xlim(1)):find(time==xlim(2))));
        ylim(1) = min(V(find(time==xlim(1)):find(time==xlim(2))));
        yr = 2*std(V(find(time==xlim(1)):find(time==xlim(2))));
        if yr==0
            set(handles.ax1,'YLim',[ylim(1)-1 ylim(2)+1]);
        else
            set(handles.ax1,'YLim',[ylim(1)-yr ylim(2)+yr]);
        end

    end

    function templateMatch(~,~)
        plotResp(@templateMatch);
    end

    function updateMetadata(src,~)
        metadata.spikesort_comment = get(src,'String');
        save(strcat(path_name,file_name),'metadata','-append')
    end

    function updateDiscardControl(~,~)
        if isfield(spikes,'discard')
            discard_this = false;
            try
                discard_this = spikes(ThisControlParadigm).discard(ThisTrial);
            catch
            end
            if discard_this
                set(discard_control,'Value',1,'String','Discarded!','FontWeight','bold')
            else
                set(discard_control,'Value',0,'String','Discard','FontWeight','normal')
            end
        else
            % nothing has been discarded
            set(discard_control,'Value',0,'String','Discard','FontWeight','normal')
        end
    end



end


