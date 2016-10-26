% makes the spikesort GUI

function [s] = makeGUI(s)



% make the master figure, and the axes to plot the voltage traces
handles.main_fig = figure('position',[50 50 1200 700], 'Toolbar','figure','Menubar','none','Name',s.version_name,'NumberTitle','off','IntegerHandle','off','WindowButtonDownFcn',@mousecallback,'WindowScrollWheelFcn',@s.scroll,'CloseRequestFcn',@s.close);
temp =  findall(handles.main_fig,'Type','uitoggletool','-or','Type','uipushtool');

% make plots menu
handles.menu1 = uimenu('Label','Make Plots...');
uimenu(handles.menu1,'Label','Raster','Callback',@s.rasterPlot);
uimenu(handles.menu1,'Label','Firing Rate','Callback',@s.firingRatePlot);

% pre-processing
handles.menu2 = uimenu('Label','Tools');
uimenu(handles.menu2,'Label','Template Match','Callback',@s.matchTemplate);
handles.remove_artifacts_menu = uimenu(handles.menu2,'Label','Remove Artifacts','Callback',@removeArtifacts,'Checked',s.pref.remove_artifacts);
uimenu(handles.menu2,'Label','Reload preferences','Callback',@s.reloadPreferences,'Separator','on');
uimenu(handles.menu2,'Label','Reset zoom','Callback',@s.resetZoom);
delete(temp([1:8 11:15]))


% make the two axes
handles.ax1 = axes('parent',handles.main_fig,'Position',[0.07 0.05 0.87 0.29]); hold on
handles.jump_back = uicontrol(handles.main_fig,'units','normalized','Position',[0 .04 .04 .50],'Style', 'pushbutton', 'String', '<','callback',@s.jump);
handles.jump_fwd = uicontrol(handles.main_fig,'units','normalized','Position',[.96 .04 .04 .50],'Style', 'pushbutton', 'String', '>','callback',@s.jump);
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
handles.datapanel = uipanel('Title','Data','Position',[.8 .57 .16 .4]);
uicontrol(handles.datapanel,'units','normalized','Position',[.02 .9 .510 .10],'Style', 'text', 'String', 'Control Signal','FontSize',s.pref.fs,'FontWeight',s.pref.fw);
handles.valve_channel = uicontrol(handles.datapanel,'units','normalized','Position',[.03 .68 .910 .25],'Style', 'listbox', 'String', '','FontSize',s.pref.fs,'FontWeight',s.pref.fw,'Callback',@plotValve,'Min',0,'Max',2);
uicontrol(handles.datapanel,'units','normalized','Position',[.01 .56 .510 .10],'Style', 'text', 'String', 'Stimulus','FontSize',s.pref.fs,'FontWeight',s.pref.fw);
handles.stim_channel = uicontrol(handles.datapanel,'units','normalized','Position',[.03 .38 .910 .20],'Style', 'listbox', 'String', '','FontSize',s.pref.fs,'FontWeight',s.pref.fw,'Callback',@s.plotStim);

uicontrol(handles.datapanel,'units','normalized','Position',[.01 .25 .610 .10],'Style', 'text', 'String', 'Response','FontSize',s.pref.fs,'FontWeight',s.pref.fw);
handles.resp_channel = uicontrol(handles.datapanel,'units','normalized','Position',[.01 .01 .910 .25],'Style', 'listbox', 'String', '','FontSize',s.pref.fs,'FontWeight',s.pref.fw);


% file I/O
uicontrol(handles.main_fig,'units','normalized','Position',[.10 .92 .07 .07],'Style', 'pushbutton', 'String', 'Load File','FontSize',s.pref.fs,'FontWeight',s.pref.fw,'callback',@s.loadFile);
uicontrol(handles.main_fig,'units','normalized','Position',[.05 .93 .03 .05],'Style', 'pushbutton', 'String', '<','FontSize',s.pref.fs,'FontWeight',s.pref.fw,'callback',@s.loadFile);
uicontrol(handles.main_fig,'units','normalized','Position',[.19 .93 .03 .05],'Style', 'pushbutton', 'String', '>','FontSize',s.pref.fs,'FontWeight',s.pref.fw,'callback',@s.loadFile);

% paradigms and trials
handles.datachooserpanel = uipanel('Title','Paradigms and Trials','Position',[.03 .75 .25 .16]);
handles.paradigm_chooser = uicontrol(handles.datachooserpanel,'units','normalized','Position',[.25 .75 .5 .20],'Style', 'popupmenu', 'String', 'Choose Paradigm','callback',@s.chooseParadigmCallback,'Enable','off');
handles.next_paradigm = uicontrol(handles.datachooserpanel,'units','normalized','Position',[.75 .65 .15 .33],'Style', 'pushbutton', 'String', '>','callback',@s.chooseParadigmCallback,'Enable','off');
handles.prev_paradigm = uicontrol(handles.datachooserpanel,'units','normalized','Position',[.05 .65 .15 .33],'Style', 'pushbutton', 'String', '<','callback',@s.chooseParadigmCallback,'Enable','off');

handles.trial_chooser = uicontrol(handles.datachooserpanel,'units','normalized','Position',[.25 .27 .5 .20],'Style', 'popupmenu', 'String', 'Choose Trial','callback',@s.chooseTrialCallback,'Enable','off');
handles.next_trial = uicontrol(handles.datachooserpanel,'units','normalized','Position',[.75 .15 .15 .33],'Style', 'pushbutton', 'String', '>','callback',@s.chooseTrialCallback,'Enable','off');
handles.prev_trial = uicontrol(handles.datachooserpanel,'units','normalized','Position',[.05 .15 .15 .33],'Style', 'pushbutton', 'String', '<','callback',@s.chooseTrialCallback,'Enable','off');

% dimension reduction and clustering panels
handles.dimredpanel = uipanel('Title','Dimensionality Reduction','Position',[.25 .92 .17 .07]);
all_plugin_names = {s.installed_plugins.name};
dim_red_plugins = all_plugin_names(find(strcmp({s.installed_plugins.plugin_type},'dim-red')));

handles.method_control = uicontrol(handles.dimredpanel,'Style','popupmenu','String',dim_red_plugins,'units','normalized','Position',[.02 .6 .9 .2],'Callback',@s.reduceDimensionsCallback,'Enable','off','FontSize',20);

% find the available methods for clustering
all_plugin_names = {s.installed_plugins.name};
cluster_plugins = all_plugin_names(find(strcmp({s.installed_plugins.plugin_type},'cluster')));

handles.cluster_panel = uipanel('Title','Clustering','Position',[.43 .92 .17 .07]);
handles.cluster_control = uicontrol(handles.cluster_panel,'Style','popupmenu','String',cluster_plugins,'units','normalized','Position',[.02 .6 .9 .2],'Callback',@s.clusterCallback,'Enable','off','FontSize',20);


% metadata panel
handles.metadata_panel = uipanel('Title','Metadata','Position',[.29 .57 .21 .15]);
handles.metadata_text_control = uicontrol(handles.metadata_panel,'Style','edit','String','','units','normalized','Position',[.03 .3 .94 .7],'Callback',@s.updateMetadata,'Enable','off','Max',5,'Min',1,'HorizontalAlignment','left');
uicontrol(handles.metadata_panel,'Style','pushbutton','String','Generate Summary','units','normalized','Position',[.03 .035 .45 .2],'Callback',@s.generateSummary);


% manual override panel
handles.manualpanel = uibuttongroup(handles.main_fig,'Title','Manual Override','Position',[.68 .56 .11 .34]);
uicontrol(handles.manualpanel,'units','normalized','Position',[.1 7/8 .8 1/9],'Style','pushbutton','String','Mark All in View','Callback',@s.markAllCallback);
handles.mode_new_A = uicontrol(handles.manualpanel,'units','normalized','Position',[.1 6/8 .8 1/9], 'Style', 'radiobutton', 'String', '+A','FontSize',s.pref.fs);
handles.mode_new_B = uicontrol(handles.manualpanel,'units','normalized','Position',[.1 5/8 .8 1/9], 'Style', 'radiobutton', 'String', '+B','FontSize',s.pref.fs);
handles.mode_delete = uicontrol(handles.manualpanel,'units','normalized','Position',[.1 4/8 .8 1/9], 'Style', 'radiobutton', 'String', '-X','FontSize',s.pref.fs);
handles.mode_A2B = uicontrol(handles.manualpanel,'units','normalized','Position',[.1 3/8 .8 1/9], 'Style', 'radiobutton', 'String', 'A->B','FontSize',s.pref.fs);
handles.mode_B2A = uicontrol(handles.manualpanel,'units','normalized','Position',[.1 2/8 .8 1/9], 'Style', 'radiobutton', 'String', 'B->A','FontSize',s.pref.fs);
uicontrol(handles.manualpanel,'units','normalized','Position',[.1 1/8 .8 1/9],'Style','pushbutton','String','Discard View','Callback',@s.modifyTraceDiscard);
uicontrol(handles.manualpanel,'units','normalized','Position',[.1 0/8 .8 1/9],'Style','pushbutton','String','Retain View','Callback',@s.modifyTraceDiscard);


% various toggle switches and pushbuttons
handles.filtermode = uicontrol(handles.main_fig,'units','normalized','Position',[.03 .69 .12 .05],'Style','togglebutton','String','Filter','Value',1,'Callback',@s.plotResp,'Enable','off');
handles.findmode = uicontrol(handles.main_fig,'units','normalized','Position',[.16 .69 .12 .05],'Style','togglebutton','String','Find Spikes','Value',1,'Callback',@s.plotResp,'Enable','off');

handles.redo_control = uicontrol(handles.main_fig,'units','normalized','Position',[.03 .64 .12 .05],'Style','pushbutton','String','Redo','Value',0,'Callback',@s.redo,'Enable','off');
handles.autosort_control = uicontrol(handles.main_fig,'units','normalized','Position',[.16 .64 .12 .05],'Style','togglebutton','String','Autosort','Value',0,'Enable','off','Callback',@autosortCallback);

handles.sine_control = uicontrol(handles.main_fig,'units','normalized','Position',[.03 .59 .12 .05],'Style','togglebutton','String',' Kill Ringing','Value',0,'Callback',@s.plotResp,'Enable','off');
handles.discard_control = uicontrol(handles.main_fig,'units','normalized','Position',[.16 .59 .12 .05],'Style','togglebutton','String',' Discard','Value',0,'Callback',@s.discard,'Enable','off');


% disable tagging on non unix systems
if ispc
else
    handles.tag_control = uicontrol(handles.metadata_panel,'Style','edit','String','+Tag, or -Tag','units','normalized','Position',[.5 .035 .45 .2],'Callback',@s.addTag);

    % modify environment to get paths for non-matlab code right
    if ~ismac
        path1 = getenv('PATH');
        if isempty(strfind(path1,[pathsep '/usr/local/bin']))
            path1 = [path1 pathsep '/usr/local/bin'];
        end

        setenv('PATH', path1);
    end

end


s.handles = handles;