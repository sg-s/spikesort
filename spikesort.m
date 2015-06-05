% spikesort.m
% Allows you to view, manipulate and sort spikes from experiments conducted by Kontroller. specifically meant to sort spikes from Drosophila ORNs
% spikesort was written by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% part of the spikesort package
% https://github.com/sg-s/spikesort
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function [] = spikesort()
h = GitHash(mfilename('fullpath'));
versionname = strcat('spikesort for Kontroller (Build-',h(1:6),')');

% check dependencies 
p=path;
if isempty(strfind(p,'srinivas.gs_mtools'))
    error('Needs srinivas.gs_mtools, available here: https://github.com/sg-s/srinivas.gs_mtools')
end
if verLessThan('matlab', '8.0.1')
    error('Need MATLAB 2014b to run')
end

% check the signal processing toolbox version
if verLessThan('signal','6.22')
    error('Need Signal Processing toolbox version 6.22 or higher')
end

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

% UI
fs = 14; % font size

% handles
valve_channel = [];
load_waitbar = [];
h_scatter1 = [];
h_scatter2 = [];

if isunix
    % add support for xattr-based tagging
    PATH = getenv('PATH');
    setenv('PATH', [PATH strcat(':',fileparts(which('spikesort')))]);
end

% make the master figure, and the axes to plot the voltage traces
fig = figure('position',[50 50 1200 700], 'Toolbar','figure','Menubar','none','Name',versionname,'NumberTitle','off','IntegerHandle','off','WindowButtonDownFcn',@mousecallback,'WindowScrollWheelFcn',@scroll,'CloseRequestFcn',@closess);
temp =  findall(gcf,'Type','uitoggletool','-or','Type','uipushtool');
% modify buttons for raster and firing rate 
r = load('r.mat');
f = load('f.mat');
temp(15).CData = r.r;
temp(15).ClickedCallback = @raster_plot;
temp(15).TooltipString = 'Generate Raster Plot';

temp(14).CData = f.f;
temp(14).ClickedCallback = @firing_rate_plot;
temp(14).TooltipString = 'Generate Firing Rates';
clear r f
delete(temp([1:7 11 12]))
clear temp
% callback for export figs
menubuttons = findall(gcf,'Type','uitoggletool','-or','Type','uipushtool');
set(menubuttons(4),'ClickedCallback',@ExportFigs,'Enable','off')

ax = axes('parent',fig,'Position',[0.07 0.05 0.87 0.29]); hold on
jump_back = uicontrol(fig,'units','normalized','Position',[0 .04 .04 .50],'Style', 'pushbutton', 'String', '<','callback',@jump);
jump_fwd = uicontrol(fig,'units','normalized','Position',[.96 .04 .04 .50],'Style', 'pushbutton', 'String', '>','callback',@jump);
ax2 = axes('parent',fig,'Position',[0.07 0.37 0.87 0.18]); hold on
linkaxes([ax2,ax],'x')

% make all the panels

% datapanel (allows you to choose what to plot where)
datapanel = uipanel('Title','Data','Position',[.8 .57 .16 .4]);
uicontrol(datapanel,'units','normalized','Position',[.02 .9 .510 .10],'Style', 'text', 'String', 'Control Signal','FontSize',fs,'FontWeight','bold');
valve_channel = uicontrol(datapanel,'units','normalized','Position',[.03 .68 .910 .25],'Style', 'listbox', 'String', '','FontSize',fs,'FontWeight','bold','Callback',@plot_valve,'Min',0,'Max',2);
uicontrol(datapanel,'units','normalized','Position',[.01 .56 .510 .10],'Style', 'text', 'String', 'Stimulus','FontSize',fs,'FontWeight','bold');
stim_channel = uicontrol(datapanel,'units','normalized','Position',[.03 .38 .910 .20],'Style', 'listbox', 'String', '','FontSize',fs,'FontWeight','bold','Callback',@plot_stim);

uicontrol(datapanel,'units','normalized','Position',[.01 .25 .610 .10],'Style', 'text', 'String', 'Response','FontSize',fs,'FontWeight','bold');
resp_channel = uicontrol(datapanel,'units','normalized','Position',[.01 .01 .910 .25],'Style', 'listbox', 'String', '','FontSize',fs,'FontWeight','bold');


% file I/O
uicontrol(fig,'units','normalized','Position',[.10 .92 .07 .07],'Style', 'pushbutton', 'String', 'Load File','FontSize',fs,'FontWeight','bold','callback',@loadfilecallback);
uicontrol(fig,'units','normalized','Position',[.05 .93 .03 .05],'Style', 'pushbutton', 'String', '<','FontSize',fs,'FontWeight','bold','callback',@loadfilecallback);
uicontrol(fig,'units','normalized','Position',[.19 .93 .03 .05],'Style', 'pushbutton', 'String', '>','FontSize',fs,'FontWeight','bold','callback',@loadfilecallback);

% paradigms and trials
datachooserpanel = uipanel('Title','Paradigms and Trials','Position',[.03 .75 .25 .16]);
paradigm_chooser = uicontrol(datachooserpanel,'units','normalized','Position',[.25 .75 .5 .20],'Style', 'popupmenu', 'String', 'Choose Paradigm','callback',@choose_paradigm_callback,'Enable','off');
next_paradigm = uicontrol(datachooserpanel,'units','normalized','Position',[.75 .65 .15 .33],'Style', 'pushbutton', 'String', '>','callback',@choose_paradigm_callback,'Enable','off');
prev_paradigm = uicontrol(datachooserpanel,'units','normalized','Position',[.05 .65 .15 .33],'Style', 'pushbutton', 'String', '<','callback',@choose_paradigm_callback,'Enable','off');

trial_chooser = uicontrol(datachooserpanel,'units','normalized','Position',[.25 .27 .5 .20],'Style', 'popupmenu', 'String', 'Choose Trial','callback',@choose_trial_callback,'Enable','off');
next_trial = uicontrol(datachooserpanel,'units','normalized','Position',[.75 .15 .15 .33],'Style', 'pushbutton', 'String', '>','callback',@choose_trial_callback,'Enable','off');
prev_trial = uicontrol(datachooserpanel,'units','normalized','Position',[.05 .15 .15 .33],'Style', 'pushbutton', 'String', '<','callback',@choose_trial_callback,'Enable','off');

% dimension reduction and clustering panels
dimredpanel = uipanel('Title','Dimensionality Reduction','Position',[.29 .92 .21 .07]);
% find the available methods
look_here = mfilename('fullpath');
look_here=look_here(1:max(strfind(look_here,oss))); % this is where we should look for methods
avail_methods=dir(strcat(look_here,'ssdm_*.m'));
avail_methods={avail_methods.name};
for oi = 1:length(avail_methods)
    temp = avail_methods{oi};
    avail_methods{oi} = temp(6:end-2);
end
clear oi
method_control = uicontrol(dimredpanel,'Style','popupmenu','String',avail_methods,'units','normalized','Position',[.02 .6 .9 .2],'Callback',@reduce_dimensions_callback,'Enable','off');

% find the available methods for clustering
look_here = mfilename('fullpath');
look_here=look_here(1:max(strfind(look_here,oss))); % this is where we should look for methods
avail_methods=dir(strcat(look_here,'sscm_*.m'));
avail_methods={avail_methods.name};
for oi = 1:length(avail_methods)
    temp = avail_methods{oi};
    avail_methods{oi} = temp(6:end-2);
end
clear oi
cluster_panel = uipanel('Title','Clustering','Position',[.51 .92 .21 .07]);
cluster_control = uicontrol(cluster_panel,'Style','popupmenu','String',avail_methods,'units','normalized','Position',[.02 .6 .9 .2],'Callback',@find_cluster,'Enable','off');

% spike find parameters
find_spike_panel = uipanel('Title','Spike Detection','Position',[.29 .73 .21 .17]);
uicontrol(find_spike_panel,'Style','text','String','MinPeakProminence','units','normalized','Position',[0 .73 .8 .2],'Callback',@plot_resp)
mpp_control = uicontrol(find_spike_panel,'Style','edit','String','.03','units','normalized','Position',[.77 .75 .2 .2],'Callback',@plot_resp);
uicontrol(find_spike_panel,'Style','text','String','MinPeakWidth','units','normalized','Position',[0 .53 .8 .2])
mpw_control = uicontrol(find_spike_panel,'Style','edit','String','15','units','normalized','Position',[.77 .55 .2 .2],'Callback',@plot_resp);
uicontrol(find_spike_panel,'Style','text','String','MinPeakDistance','units','normalized','Position',[0 .33 .8 .2])
mpd_control = uicontrol(find_spike_panel,'Style','edit','String','10','units','normalized','Position',[.77 .35 .2 .2],'Callback',@plot_resp);
uicontrol(find_spike_panel,'Style','text','String','-V Cutoff','units','normalized','Position',[0 .13 .8 .2])
minV_control = uicontrol(find_spike_panel,'Style','edit','String','-1','units','normalized','Position',[.77 .15 .2 .2],'Callback',@plot_resp);

% metadata panel
metadata_panel = uipanel('Title','Metadata','Position',[.29 .57 .21 .15]);
metadata_text_control = uicontrol(metadata_panel,'Style','edit','String','','units','normalized','Position',[.03 .3 .94 .7],'Callback',@update_metadata,'Enable','off','Max',5,'Min',1,'HorizontalAlignment','left');
metadata_summary_control = uicontrol(metadata_panel,'Style','pushbutton','String','Generate Summary','units','normalized','Position',[.03 .035 .45 .2],'Callback',@generate_summary);

% disable tagging on non unix systems
if ispc
else
    uicontrol(metadata_panel,'Style','edit','String','Add Tag...','units','normalized','Position',[.5 .035 .45 .2],'Callback',@add_tag);
end

% other options
options_panel = uipanel('Title','Options','Position',[.51 .60 .16 .30]);
template_match_control = uicontrol(options_panel,'Style','checkbox','String','-Template','units','normalized','Position',[.01 6/7 .4 1/7],'Callback',@TemplateMatch,'Value',1);
template_width_control = uicontrol(options_panel,'Style','slider','units','normalized','Position',[.35 5/7+.004 .6 1/7],'Callback',@TemplateMatch,'Value',50,'Min',5,'Max',200);
try    % R2013b and older
   addlistener(template_width_control,'ActionEvent',@TemplateMatch);
catch  % R2014a and newer
   addlistener(template_width_control,'ContinuousValueChange',@TemplateMatch);
end
uicontrol(options_panel,'Style','text','units','normalized','Position',[.01 5/7 .3 1/7],'String','width:');
template_match_slider = uicontrol(options_panel,'Style','slider','units','normalized','Position',[.35 4/7+.04 .6 1/7],'Callback',@TemplateMatch,'Value',2,'Min',-1,'Max',5);
try    % R2013b and older
   addlistener(template_match_slider,'ActionEvent',@TemplateMatch);
catch  % R2014a and newer
   addlistener(template_match_slider,'ContinuousValueChange',@TemplateMatch);
end


uicontrol(options_panel,'Style','text','units','normalized','Position',[.01 4/7+.04 .3 1/7],'String','amount:');
flip_V_control = uicontrol(options_panel,'Style','checkbox','String','Find spikes in -V','units','normalized','Position',[.01 4/7-.04 .8 1/8],'Value',1);
smart_scroll_control = uicontrol(options_panel,'Style','checkbox','String','Smart Scroll','units','normalized','Position',[.01 3/7 .8 1/8],'Value',0);
plot_control_control = uicontrol(options_panel,'Style','checkbox','String','Plot Control','units','normalized','Position',[.01 2/7 .8 1/8],'Value',0);
r2_plot_control = uicontrol(options_panel,'Style','checkbox','String','Show reproducibility','units','normalized','Position',[.01 1/7 .8 1/7]);


firing_rate_trial_control = uicontrol(options_panel,'Style','checkbox','String','per-trial firing rate','units','normalized','Position',[.01 0/7 .8 1/7]);






% manual override panel
manualpanel = uibuttongroup(fig,'Title','Manual Override','Position',[.68 .60 .11 .28]);
mode_new_A = uicontrol(manualpanel,'Position',[5 5 100 20], 'Style', 'radiobutton', 'String', '+A','FontSize',fs);
mode_new_B = uicontrol(manualpanel,'Position',[5 35 100 20], 'Style', 'radiobutton', 'String', '+B','FontSize',fs);
mode_delete = uicontrol(manualpanel,'Position',[5 65 100 20], 'Style', 'radiobutton', 'String', '-X','FontSize',fs);
mode_A2B = uicontrol(manualpanel,'Position',[5 95 100 20], 'Style', 'radiobutton', 'String', 'A->B','FontSize',fs);
mode_B2A = uicontrol(manualpanel,'Position',[5 125 100 20], 'Style', 'radiobutton', 'String', 'B->A','FontSize',fs);
uicontrol(manualpanel,'Position',[15 150 100 30],'Style','pushbutton','String','Mark All in View','Callback',@mark_all_callback);

% various toggle switches and pushbuttons
filtermode = uicontrol(fig,'units','normalized','Position',[.03 .69 .12 .05],'Style','togglebutton','String','Filter','Value',1,'Callback',@plot_resp,'Enable','off');
findmode = uicontrol(fig,'units','normalized','Position',[.16 .69 .12 .05],'Style','togglebutton','String','Find Spikes','Value',1,'Callback',@plot_resp,'Enable','off');

redo_control = uicontrol(fig,'units','normalized','Position',[.03 .64 .12 .05],'Style','pushbutton','String','Redo','Value',0,'Callback',@redo,'Enable','off');
autosort_control = uicontrol(fig,'units','normalized','Position',[.16 .64 .12 .05],'Style','togglebutton','String','Autosort','Value',0,'Enable','off');

sine_control = uicontrol(fig,'units','normalized','Position',[.03 .59 .12 .05],'Style','togglebutton','String',' Kill Ringing','Value',0,'Callback',@plot_resp,'Enable','off');
discard_control = uicontrol(fig,'units','normalized','Position',[.16 .59 .12 .05],'Style','togglebutton','String',' Discard','Value',0,'Callback',@discard,'Enable','off');


    function add_tag(src,~)
        tag = get(src,'String');
        temp = whos('FileName');
        if ~isempty(FileName) && strcmp(temp.class,'char')
            % tag the file as done
            es=strcat('unix(',char(39),'tagfile.py "', tag,'"', PathName,FileName,char(39),');');
            es = strrep(es,'"/','" /');
            eval(es);
        end
    end

    function update_metadata(src,~)
        metadata.spikesort_comment = get(src,'String');
        save(strcat(PathName,FileName),'metadata','-append')
    end

    function TemplateMatch(src,event)
        plot_resp;
    end

    
    function raster_plot(~,~)
        figure('outerposition',[0 0 1000 500],'PaperUnits','points','PaperSize',[1000 500]); hold on
        yoffset = 0;
        ytick=0;
        L ={};
        for i = 1:length(spikes)
            if length(spikes(i).A) > 1
                raster2(full(spikes(i).A),spikes(i).B,yoffset);
                yoffset = yoffset + width(spikes(i).A)*2 + 1;
                ytick = [ytick yoffset];
                L = [L strrep(ControlParadigm(i).Name,'_','-')];
                
            end
        end
        set(gca,'YTick',ytick(1:end-1)+diff(ytick)/2,'YTickLabel',L,'box','on')
        xlabel('Time (s)')
        console('Made a raster plot.')
    
        
    end

    function firing_rate_plot(~,~)
        if get(r2_plot_control,'Value')
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
                % cache data to speed up
                hash = DataHash(full(spikes(haz_data(i)).A));
                if isempty(cache(hash))
                    [fA,tA] = spiketimes2f(spikes(haz_data(i)).A,time);
                    % remove trials with no spikes
                    fA(:,sum(fA) == 0) = [];
                    cache(hash,fA);
                else
                    fA = cache(hash);
                    tA = (1:length(fA))*1e-3;
                end
                if width(fA) > 1
                    if get(firing_rate_trial_control,'Value')
                        for j = 1:width(fA)
                            l(i) = plot(sp(1),tA,fA(:,j),'Color',c(i,:));
                        end
                    else
                	   l(i) = plot(sp(1),tA,mean2(fA),'Color',c(i,:));
                    end
                    if get(r2_plot_control,'Value')
                        hash = DataHash(fA);
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
                % cache data to speed up
                hash = DataHash(full(spikes(haz_data(i)).B));
                if isempty(cache(hash))
                    [fB,tB] = spiketimes2f(spikes(haz_data(i)).B,time);
                    % remove trials with no spikes
                    fB(:,sum(fB) == 0) = [];
                    cache(hash,fB);
                else
                    fB = cache(hash);
                    tB = (1:length(fB))*1e-3;
                end
                if width(fB) > 1
                    if get(firing_rate_trial_control,'Value')
                        for j = 1:width(fB)
                            l(i) = plot(sp(2),tA,fB(:,j),'Color',c(i,:));
                        end
                    else
                	   l(i) = plot(sp(2),tB,mean2(fB),'Color',c(i,:));
                    end
                    if get(r2_plot_control,'Value')
                        hash = DataHash(fB);
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
        PrettyFig;
        console('Made a firing rate plot.')
    end


    function mark_all_callback(~,~)
        % get view
        xmin = get(ax,'XLim');
        xmin = xmin/deltat;
        xmax = xmin(2); xmin=xmin(1);

        % get mode
        if get(mode_B2A,'Value')
            % add to A spikes
            spikes(ThisControlParadigm).A(ThisTrial,loc(loc>xmin & loc<xmax))  = 1;
            % remove b spikes
            spikes(ThisControlParadigm).B(ThisTrial,loc(loc>xmin & loc<xmax))  = 0;
            console('Marked all in view as A');

        elseif get(mode_A2B,'Value')
            % add to B spikes
            spikes(ThisControlParadigm).B(ThisTrial,loc(loc>xmin & loc<xmax))  = 1;
            % remove A spikes
            spikes(ThisControlParadigm).A(ThisTrial,loc(loc>xmin & loc<xmax))  = 0;
            console('Marked all in view as B');
        elseif get(mode_delete,'Value')
            spikes(ThisControlParadigm).A(ThisTrial,loc(loc>xmin & loc<xmax))  = 0;
            spikes(ThisControlParadigm).B(ThisTrial,loc(loc>xmin & loc<xmax))  = 0;
            console('Removed all spikes in view');
        end

        % update plot
        plot_resp; 

    end


    function closess(~,~)
        % save everything
        try
            if ~isempty(PathName) && ~isempty(FileName) 
                if ischar(PathName) && ischar(FileName)
                    save(strcat(PathName,FileName),'spikes','-append')
                    console('Saving file...');
                end
            end
        catch
        end

        temp = whos('FileName');
        % if isunix && ~isempty(FileName) && strcmp(temp.class,'char')
        %     % tag the file as done
        %     es=strcat('unix(',char(39),'tagfile.py "Complete" ', PathName,FileName,char(39),');');
        %     es = strrep(es,'"/','" /');
        %     eval(es);
        %     console('Tagging file with XATTR.');
        % end
        delete(fig)

    end

    function jump(src,~)
        % get the digital channels
        digital_channels = get(valve_channel,'Value');

        % find out where we are
        xl= floor(get(ax,'XLim')/deltat);
        

        if src == jump_fwd
            next_on = Inf;

            % find the next digital channel switch in any channel
            for i = 1:length(digital_channels)
                this_channel = ControlParadigm(ThisControlParadigm).Outputs(digital_channels(i),:);
                [ons] = ComputeOnsOffs(this_channel);
                ons(ons<xl(2)) = [];
                next_on = min([next_on(:); ons(:)]);
            end
            if ~isinf(next_on)
                set(ax,'Xlim',[time(next_on) time(next_on+diff(xl))]);
            end
        elseif src == jump_back
            prev_on = -Inf;

            % find the prev digital channel switch in any channel
            for i = 1:length(digital_channels)
                this_channel = ControlParadigm(ThisControlParadigm).Outputs(digital_channels(i),:);
                [ons] = ComputeOnsOffs(this_channel);
                ons(ons>xl(1)-1) = [];
                prev_on = max([prev_on(:); ons(:)]);
            end
            if ~isinf(-prev_on)
                set(ax,'Xlim',[time(prev_on) time(prev_on+diff(xl))]);
            end
        else
            error('Unknown source of call to jump');
        end
    end

    function scroll(~,event)
        xlimits = get(ax,'XLim');
        xrange = (xlimits(2) - xlimits(1));
        scroll_amount = event.VerticalScrollCount;
        if ~get(smart_scroll_control,'Value')
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
            n_spikes_in_view = length(loc(loc>(xlimits(1)/deltat) & loc<(xlimits(2)/deltat)));
            if scroll_amount > 0
                try
                    newlim(1) = min([max(time) (xlimits(1)+.2*xrange)]);
                    newlim(2) = loc(find(loc > newlim(1)/deltat,1,'first') + n_spikes_in_view)*deltat;
                catch
                end
            else
                try
                    newlim(2) = max([min(time)+xrange (xlimits(2)-.2*xrange)]);
                    newlim(1) = loc(find(loc < newlim(2)/deltat,1,'last') - n_spikes_in_view)*deltat;
                catch
                end
            end
        end
        
        try
            set(ax,'Xlim',newlim)
        catch
        end

        xlim = get(ax,'XLim');
        if xlim(1) < min(time)
            xlim(1) = min(time);
        end
        if xlim(2) > max(time)
            xlim(2) = max(time);
        end
        xlim(2) = (floor(xlim(2)/deltat))*deltat;
        xlim(1) = (floor(xlim(1)/deltat))*deltat;
        ylim(2) = max(V(find(time==xlim(1)):find(time==xlim(2))));
        ylim(1) = min(V(find(time==xlim(1)):find(time==xlim(2))));
        yr = 2*std(V(find(time==xlim(1)):find(time==xlim(2))));
        if yr==0
            set(ax,'YLim',[ylim(1)-1 ylim(2)+1]);
        else
            set(ax,'YLim',[ylim(1)-yr ylim(2)+yr]);
        end

    end

    function discard(~,~)
        if get(discard_control,'Value') == 0
            % reset discard
            if isfield(spikes,'discard')
                spikes(ThisControlParadigm).discard(ThisTrial) = 0;
            end
        else
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
            save(strcat(PathName,FileName),'spikes','-append')
            
        end
        

        % update screen
        plot_resp;
    end

    function redo(~,~)
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

        % update the plot
        plot_resp;

        % save the clear
        save(strcat(PathName,FileName),'spikes','-append')

    end

    function loadfilecallback(src,~)
        if strcmp(src.String,'Load File')
            [FileName,PathName] = uigetfile('.mat');
            if ~FileName
                return
            end
        elseif strcmp(src.String,'<')
            if isempty(FileName)
                return
            else
                % first save what we had before
                save(strcat(PathName,FileName),'spikes','-append')

                allfiles = dir(strcat(PathName,'*.mat'));
                if any(find(strcmp('cached.mat',{allfiles.name})))
                    allfiles(find(strcmp('cached.mat',{allfiles.name}))) = [];
                end
                thisfile = find(strcmp(FileName,{allfiles.name}))-1;
                if thisfile < 1
                    return
                end
                FileName = allfiles(thisfile).name;
            end
        else
            if isempty(FileName)
                return
            else
                % first save what we had before
                save(strcat(PathName,FileName),'spikes','-append')
                
                allfiles = dir(strcat(PathName,'*.mat'));
                if any(find(strcmp('cached.mat',{allfiles.name})))
                    allfiles(find(strcmp('cached.mat',{allfiles.name}))) = [];
                end
                thisfile = find(strcmp(FileName,{allfiles.name}))+1;
                if thisfile > length(allfiles)
                    return
                end
                FileName = allfiles(thisfile).name;
            end
        end

        % reset some pushbuttons and other things
        set(discard_control,'Value',0)
        deltat = 1e-4;
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

        console(strcat('Loading file:',PathName,'/',FileName))
        load_waitbar = waitbar(0.2, 'Loading data...');
        temp=load(strcat(PathName,FileName));
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

        

        waitbar(0.3,load_waitbar,'Updating listboxes...')
		% update control signal listboxes with OutputChannelNames
		set(valve_channel,'String',OutputChannelNames)

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
		n = Kontroller_ntrials(data); 

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
        digital_channels = find(digital_channels);
        set(valve_channel,'Value',digital_channels);


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
                    
                    % temp = mdot(abs(data(i).voltage));
                    % temp(temp>(mean(temp) + std(temp))) = 1;
                    % temp(temp<1)= 0;
                    % [ons,offs] = ComputeOnsOffs(temp);
                    % % get widths right
                    % ons(offs-ons==0) = ons(offs-ons==0) - 1;
                    % offs(offs-ons==1) = offs(offs-ons==1) + 1;
                    % ons = ons-2; offs = offs+2;
                    % for j = 1:length(ons)
                    %     temp(ons(j):offs(j)) = 1;
                    % end

                    % data(i).voltage(:,logical(temp)) = 0;

                    % suppress signals for 25 samples after any valve turns on or off
                    % this is a hack
                    
                    % this code is going to be phased out, as template match is so much better. 

                    % if get(kill_valve_noise_control,'Value')
                    %     for j = 1:length(digital_channels)
                    %         [ons,offs] = ComputeOnsOffs(ControlParadigm(i).Outputs(digital_channels(j),:));
                    %         if length(ons) == length(offs)
                    %             for k = 1:length(ons)
                    %                 data(i).voltage(:,ons(k):ons(k)+35) = NaN;
                    %                 data(i).voltage(:,offs(k):offs(k)+25) = NaN;
                    %             end
                    %         end
                    %     end
                    % end 




                end
            end

        end

        set(fig,'Name',strcat(versionname,'--',FileName))

        % enable all controls
        waitbar(.7,load_waitbar,'Enabling UI...')
        set(sine_control,'Enable','on');
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
        set(menubuttons(4),'Enable','on')
        set(metadata_text_control,'Enable','on')

        % check for amplitudes 
        waitbar(.7,load_waitbar,'Checking to see amplitude data exists...')
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
                            deltat = 1e-4; % hack, will be removed in future releases
                            spikes(i).amplitudes_A(j,find(A))  =  ssdm_1DAmplitudes(V,deltat,find(A));
                            B = spikes(i).B(j,:);
                            spikes(i).amplitudes_B(j,find(B))  =  ssdm_1DAmplitudes(V,deltat,find(B));
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

        % clean up
        close(load_waitbar)

        plot_stim;
        plot_resp;
    end

    function ExportFigs(~,~)
        % cache current state
        c.ax2 = ax2;
        c.ax = ax;
        c.ThisControlParadigm = ThisControlParadigm;
        c.ThisTrial = ThisTrial;

        % export all figs
        for i = 1:length(spikes)
            for j = 1:width(spikes(i).A)
                if length(spikes(i).A(j,:)) > 1
                    % haz data
                    figure('outerposition',[0 0 1200 700],'PaperUnits','points','PaperSize',[1200 700]); hold on
                    ax2 = subplot(2,1,1); hold on
                    ax = subplot(2,1,2); hold on
                    ThisControlParadigm = i;
                    ThisTrial = j;
                    plot_stim;
                    plot_resp;
                    title(ax2,strrep(FileName,'_','-'));
                    tstr = strcat(ControlParadigm(ThisControlParadigm).Name,'_Trial:',mat2str(ThisTrial));
                    tstr = strrep(tstr,'_','-');
                    title(ax,tstr)
                    xlabel(ax,'Time (s)')

                    
                    %set(gcf,'renderer','painters')
                    tstr = strcat(FileName,'_',tstr,'.fig');
                    tstr = strrep(tstr,'_','-');
                    % print(gcf,tstr,'-depsc2','-opengl')
                   

                    savefig(gcf,tstr);
                    delete(gcf);


                end
            end
        end
        % return to state
        ax2 = c.ax2;
        ax = c.ax;
        ThisControlParadigm = c.ThisControlParadigm;
        ThisTrial = c.ThisTrial;
        clear c
    end

    function choose_paradigm_callback(src,~)
        cla(ax); cla(ax2)
        paradigms_with_data = find(Kontroller_ntrials(data)); 
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

        n = Kontroller_ntrials(data);
        n = n(ThisControlParadigm);
        temp  ={};
        for i = 1:n
            temp{i} = strcat('Trial-',mat2str(i));
        end
        set(trial_chooser,'String',temp);
        set(trial_chooser,'Value',1);
        ThisTrial = 1;
        
        % update the plots
        plot_stim;
        plot_resp;
               
    end

    function choose_trial_callback(src,~)
        cla(ax); cla(ax2)
        n = Kontroller_ntrials(data); 
        if length(n) < ThisControlParadigm
            return
        else
            n = n(ThisControlParadigm);
        end
        if src == trial_chooser
            ThisTrial = get(trial_chooser,'Value');
            % update the plots
            plot_stim;
            plot_resp;
        elseif src== next_trial
            if ThisTrial < n
                ThisTrial = ThisTrial +1;
                set(trial_chooser,'Value',ThisTrial);
                % update the plots
                plot_stim;
                plot_resp;
            else
                % fake a call
                choose_paradigm_callback(next_paradigm);
            end
        elseif src == prev_trial
            if ThisTrial > 1
                ThisTrial = ThisTrial  - 1;
                set(trial_chooser,'Value',ThisTrial);
                % update the plots
                plot_stim;
                plot_resp;
            else
                % fake a call
                choose_paradigm_callback(prev_paradigm);
                % go to the last trial--fake another call
                n = Kontroller_ntrials(data); 
                n = n(ThisControlParadigm);
                if n
                    set(trial_chooser,'Value',n);
                    choose_trial_callback(trial_chooser);
                end
            end
        else
            error('unknown source of callback 173. probably being incorrectly being called by something.')
        end    

    end


    function plot_stim(~,~)
        % plot the stimulus
        n = Kontroller_ntrials(data); 
        cla(ax2)
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
                time = deltat*(1:length(temp));
                plot(ax2,time,temp,'Color',c(i,:)); hold on;
                miny  =min([miny min(temp)]);
                maxy  =max([maxy max(temp)]);
            end
        end

        % rescale the Y axis appropriately
        if ~isinf(sum(abs([maxy miny])))
            if maxy > miny
                set(ax2,'YLim',[miny maxy+.1*(maxy-miny)]);
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
            ymin = ymax(1); ymax = ymax(2); 
            y0 = (ymax- .1*(ymax-ymin));
            dy = (ymax-y0)/nchannels;
            thisy = ymax;

            for i = 1:nchannels
                temp=ControlParadigm(ThisControlParadigm).Outputs(plot_these(i),:);
                if get(plot_control_control,'Value')
                	% plot the control signal directly
                	time = deltat*(1:length(temp));
                	cla(ax2);
                	plot(ax2,time,temp,'LineWidth',1); hold on;
                	set(ax2,'YLim',[min(temp) max(temp)]);
                else
	                temp(temp>0)=1;
	                time = deltat*(1:length(temp));
	                thisy = thisy - dy;
	                temp = temp*thisy;
	                temp(temp==0) = NaN;
	                plot(ax2,time,temp,'Color',c(i,:),'LineWidth',5); hold on;
	            end
            end
        end

    end


    function plot_resp(~,~)
        % plot the response
        clear time V Vf % flush old variables 
        n = Kontroller_ntrials(data); 
        cla(ax)
        hold(ax,'on')
        if n(ThisControlParadigm)
            plotwhat = get(resp_channel,'String');
            plotthis = plotwhat{get(resp_channel,'Value')};
            eval(strcat('temp=data(ThisControlParadigm).',plotthis,';'));
            temp = temp(ThisTrial,:);
            time = deltat*(1:length(temp));
        else
            return    
        end

        % check if we have chosen to discard this
        if isfield(spikes,'discard')
            try spikes(ThisControlParadigm).discard(ThisTrial);
                if spikes(ThisControlParadigm).discard(ThisTrial) == 1
                    % set the control
                    set(discard_control,'Value',1);
                    plot(ax,time,temp,'k')
                    return
                else

                    set(discard_control,'Value',0);
                end
            catch
                set(discard_control,'Value',0);
            end
        end

        if get(filtermode,'Value') == 1
            console('Need to filter data...')
            [V,Vf] = filter_trace(temp);
        else
            V = temp;
        end 


        if get(sine_control,'Value') ==1
            % need to suppress some periodic noise, probably from an electrical fault
            z = min([length(time) 5e4]); % 5 seconds of data
            time = time(:); V = V(:);
            temp = fit(time(1:z),V(1:z),'sin1');
            [num,den] = iirnotch(temp.b1/length(time),.01*(temp.b1/length(time)));
            V = V - temp(time);
        end


        if get(template_match_control,'Value')
            % template match
            plotwhat = get(valve_channel,'String');
            nchannels = length(get(valve_channel,'Value'));
            plot_these = get(valve_channel,'Value');
            if length(plot_these) > 1
                plot_these = plot_these(1);
            end
            control_signal = ControlParadigm(ThisControlParadigm).Outputs(plot_these,:);

            % find ons and offs and build templates
            transitions = find(diff(control_signal));

            before = round(str2double(get(template_width_control,'String')));
            if isnan(before)
                before = 50;
            end
            after = before;
            
            
            
            if isempty(transitions)
            else
                % trim some edge cases
                transitions(find(transitions+after>(length(V)-1))) = [];
                transitions(find(transitions-before<1)) = [];


                Template = zeros(before+after+1,1);
                w = zeros(length(transitions),1);
                dv = zeros(length(transitions),1);
                for i = 1:length(transitions)
                    snippet = V(transitions(i)-before:transitions(i)+after);
                    % scale snippet
                    w(i) = control_signal(transitions(i)-1) - control_signal(transitions(i)+1);
                    dv(i) = max(snippet(before-10:before+10)) - min(snippet(before-10:before+10));
                    if w(i) < 0
                        dv(i) = -dv(i);
                    end
                    Template = Template + snippet'*w(i);

                end
                %Template = Template/(sum(w));
                Template = Template/length(transitions);
                

                % subtract templates from trace
                sf = get(template_match_slider,'Value');
                for i = 1:length(transitions)
                    w = control_signal(transitions(i)-1) - control_signal(transitions(i)+1);
                    V(transitions(i)-before:transitions(i)+after) = V(transitions(i)-before:transitions(i)+after) - Template'*w/sf;

                end
            end
        end

        plot(ax,time,V,'k'); 

        % do we have to find spikes too?
        if get(findmode,'Value') == 1
            console('need to find spikes...')
            loc=find_spikes(V);

            % do we already have sorted spikes?
            if length(spikes) < ThisControlParadigm
                % no spikes
                console('no spikes...')
                loc = find_spikes(V);
                if get(autosort_control,'Value') == 1
                    % sort spikes and show them
                    console('Autosorting spikes...')
                    [A,B] = autosort;
                    h_scatter1 = scatter(ax,time(A),V(A),'r');
                    h_scatter2 = scatter(ax,time(B),V(B),'b');
                else
                    console('Not autosorting spikes')
                    h_scatter1 = scatter(ax,time(loc),V(loc));
                end
            else
                console('spikes is at least this paradigm long')
                % maybe?
                if ThisTrial <= width(spikes(ThisControlParadigm).A) 
                    console('spike matrix is suff. wide.')
                    % check...
                    if max(spikes(ThisControlParadigm).A(ThisTrial,:))
                        % yes, have spikes
                        console('Have spikes. showing them. ')
                        A = find(spikes(ThisControlParadigm).A(ThisTrial,:));
                        B = find(spikes(ThisControlParadigm).B(ThisTrial,:));
                        h_scatter1 = scatter(ax,time(A),V(A),'r');
                        h_scatter2 = scatter(ax,time(B),V(B),'b');
                    else
                        console('no spikes case 397')
                        if get(autosort_control,'Value') == 1
                            % sort spikes and show them
                            [A,B] = autosort;
                            h_scatter1 = scatter(ax,time(A),V(A),'r');
                            h_scatter2 = scatter(ax,time(B),V(B),'b');
                        else
                            console('No need to autosort')
                            % no need to autosort
                            h_scatter1 = scatter(ax,time(loc),V(loc));
                        end
                    end
                else
                    % no spikes
                    console('spikes exists, but not for this trial')
                    if get(autosort_control,'Value') == 1
                        % sort spikes and show them
                        [A,B] = autosort;
                        h_scatter1 = scatter(ax,time(A),V(A),'r');
                        h_scatter2 = scatter(ax,time(B),V(B),'b');
                    else
                        console('No need to autosort')
                        % no need to autosort
                        h_scatter1 = scatter(ax,time(loc),V(loc));
                    end
                end
            end


            % now rescale the Y axes so that only the interesting bit is retained
            % if ~isempty(loc)
            %     try
            %         set(ax,'YLim',[1.1*min(V(loc)) -min(V(loc))]);
            %     catch
            %         keyboard
            %     end
            % else
            %     set(ax,'YLim',[min(V) max(V)]);
            % end
            
            xlim = get(ax,'XLim');
            if xlim(1) < min(time)
                xlim(1) = min(time);
            end
            if xlim(2) > max(time)
                xlim(2) = max(time);
            end
            xlim(2) = (floor(xlim(2)/deltat))*deltat;
            xlim(1) = (floor(xlim(1)/deltat))*deltat;
            try
                ylim(2) = max(V(find(time==xlim(1)):find(time==xlim(2))));
            catch
                beep
                keyboard
            end
            ylim(1) = min(V(find(time==xlim(1)):find(time==xlim(2))));
            yr = 2*std(V(find(time==xlim(1)):find(time==xlim(2))));
            if yr==0
                set(ax,'YLim',[ylim(1)-1 ylim(2)+1]);
            else
                set(ax,'YLim',[ylim(1)-yr ylim(2)+yr]);
            end


        else
            set(ax,'YLim',[min(V) max(V)]);
            console('No need to find spikes...')
            set(method_control,'Enable','off')
        end


        xl = get(ax,'XLim');
        if xl(2) ==1
            set(ax,'XLim',[min(time) max(time)]);
            % we spoof this because we want to distinguish this case from when the user zooms
            set(ax,'XLimMode','auto')

        end

        % unless the X-limits have been manually changed, fix them
        if strcmp(get(ax,'XLimMode'),'auto')
            set(ax,'XLim',[min(time) max(time)]);
            % we spoof this because we want to distinguish this case from when the user zooms
            set(ax,'XLimMode','auto')
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

    function loc = find_spikes(V)
        % get param
        mpp = str2double(get(mpp_control,'String'));
        mpd = str2double(get(mpd_control,'String'));
        mpw = str2double(get(mpw_control,'String'));
        minV = str2double(get(minV_control,'String'));
        % find local minima 

        if get(flip_V_control,'Value')
            [~,loc] = findpeaks(-V,'MinPeakProminence',mpp,'MinPeakDistance',mpd,'MinPeakWidth',mpw);
        else
            [~,loc] = findpeaks(V,'MinPeakProminence',mpp,'MinPeakDistance',mpd,'MinPeakWidth',mpw);
        end
        % remove spikes below min V
        loc(V(loc) < minV) = [];
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
        methodname = get(method_control,'String');
        methodname = strcat('ssdm_',methodname{method});
        req_arg = arginnames(methodname); % find out what arguments the external method needs
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

    function [A,B] = find_cluster(~,~)
        % cluster based on the method
        methodname = get(cluster_control,'String');
        method = get(cluster_control,'Value');
        methodname = strcat('sscm_',methodname{method});
        req_arg = arginnames(methodname); % find out what arguments the external method needs
        % start constructing the eval string
        es = strcat('[A,B]=',methodname,'(');
        for ri =  1:length(req_arg)
            es = strcat(es,req_arg{ri},',');
        end
        clear ri
        es = es(1:end-1);
        es = strcat(es,');');
        try
            eval(es);
        catch exc
            ms = strkat(methodname, ' ran into an error: ', exc.message);
            msgbox(ms,'spikesort');
            return
        end
        clear es
        
        

        % mark them
        delete(h_scatter1)
        delete(h_scatter2)
        h_scatter1 = scatter(ax,time(A),V(A),'r');
        h_scatter2 = scatter(ax,time(B),V(B),'b');

        % save them
        try
            spikes(ThisControlParadigm).A(ThisTrial,:) = sparse(1,length(time));
            spikes(ThisControlParadigm).amplitudes_A(ThisTrial,:) = sparse(1,length(time));
            spikes(ThisControlParadigm).B(ThisTrial,:) = sparse(1,length(time));
            spikes(ThisControlParadigm).amplitudes_B(ThisTrial,:) = sparse(1,length(time));
        catch
            spikes(ThisControlParadigm).A= sparse(ThisTrial,length(time));
            spikes(ThisControlParadigm).B= sparse(ThisTrial,length(time));
            spikes(ThisControlParadigm).amplitudes_A = sparse(ThisTrial,length(time));
            spikes(ThisControlParadigm).amplitudes_B = sparse(ThisTrial,length(time));

        end
        spikes(ThisControlParadigm).A(ThisTrial,A) = 1;
        
        spikes(ThisControlParadigm).B(ThisTrial,B) = 1;

        % also save spike amplitudes
        spikes(ThisControlParadigm).amplitudes_A(ThisTrial,A)  =  ssdm_1DAmplitudes(V,deltat,A,flip_V_control);
        spikes(ThisControlParadigm).amplitudes_B(ThisTrial,B)  =  ssdm_1DAmplitudes(V,deltat,B,flip_V_control);

        % save them
        save(strcat(PathName,FileName),'spikes','-append')

    end


    function mousecallback(~,~)
        p=get(ax,'CurrentPoint');
        p=p(1,1:2);
        modify(p)
    end

    function modify(p)
        % check that the point is within the axes
        ylimits = get(ax,'YLim');
        if p(2) > ylimits(2) || p(2) < ylimits(1)
            console('Rejecting point: Y exceeded')
            return
        end
        xlimits = get(ax,'XLim');
        if p(1) > xlimits(2) || p(1) < xlimits(1)
            console('Rejecting point: X exceeded')
            return
        end

        p(1) = p(1)/deltat;
        xrange = (xlimits(2) - xlimits(1))/deltat;
        yrange = ylimits(2) - ylimits(1);
        % get the width over which to search for spikes dynamically from the zoom factor
        s = floor((.005*xrange));
        if get(mode_new_A,'Value')==1
            % snip out a small waveform around the point
            if get(flip_V_control,'Value')
                [~,loc] = min(V(floor(p(1)-s:p(1)+s)));
            else
                [~,loc] = max(V(floor(p(1)-s:p(1)+s)));
            end
            spikes(ThisControlParadigm).A(ThisTrial,-s+loc+floor(p(1))) = 1;
            A = find(spikes(ThisControlParadigm).A(ThisTrial,:));
            spikes(ThisControlParadigm).amplitudes_A(ThisTrial,A)  =  ssdm_1DAmplitudes(V,deltat,A,flip_V_control);
        elseif get(mode_new_B,'Value')==1
            % snip out a small waveform around the point
            if get(flip_V_control,'Value')
                [~,loc] = min(V(floor(p(1)-s:p(1)+s)));
            else
                [~,loc] = max(V(floor(p(1)-s:p(1)+s)));
            end
            spikes(ThisControlParadigm).B(ThisTrial,-s+loc+floor(p(1))) = 1;
            B = find(spikes(ThisControlParadigm).B(ThisTrial,:));
            spikes(ThisControlParadigm).amplitudes_B(ThisTrial,B)  =  ssdm_1DAmplitudes(V,deltat,B,flip_V_control);
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
                A = find(spikes(ThisControlParadigm).A(ThisTrial,:));
                spikes(ThisControlParadigm).amplitudes_A(ThisTrial,A)  =  ssdm_1DAmplitudes(V,deltat,A,flip_V_control);
            else
                [~,closest_spike] = min(dB);
                spikes(ThisControlParadigm).B(ThisTrial,Bspiketimes(closest_spike)) = 0;
                B = find(spikes(ThisControlParadigm).B(ThisTrial,:));
                spikes(ThisControlParadigm).amplitudes_B(ThisTrial,B)  =  ssdm_1DAmplitudes(V,deltat,B,flip_V_control);
            end
        elseif get(mode_A2B,'Value')==1 
            % find the closest A spike
            Aspiketimes = find(spikes(ThisControlParadigm).A(ThisTrial,:));
            dA= (((Aspiketimes-p(1))/(xrange)).^2  + ((V(Aspiketimes) - p(2))/(5*yrange)).^2);
            [~,closest_spike] = min(dA);
            spikes(ThisControlParadigm).A(ThisTrial,Aspiketimes(closest_spike)) = 0;
            spikes(ThisControlParadigm).B(ThisTrial,Aspiketimes(closest_spike)) = 1;
            A = find(spikes(ThisControlParadigm).A(ThisTrial,:));
            spikes(ThisControlParadigm).amplitudes_A(ThisTrial,A)  =  ssdm_1DAmplitudes(V,deltat,A,flip_V_control);
            B = find(spikes(ThisControlParadigm).B(ThisTrial,:));
            spikes(ThisControlParadigm).amplitudes_B(ThisTrial,B)  =  ssdm_1DAmplitudes(V,deltat,B,flip_V_control);

        elseif get(mode_B2A,'Value')==1
            % find the closest B spike
            Bspiketimes = find(spikes(ThisControlParadigm).B(ThisTrial,:));
            dB= (((Bspiketimes-p(1))/(xrange)).^2  + ((V(Bspiketimes) - p(2))/(5*yrange)).^2);
            [~,closest_spike] = min(dB);
            spikes(ThisControlParadigm).A(ThisTrial,Bspiketimes(closest_spike)) = 1;
            spikes(ThisControlParadigm).B(ThisTrial,Bspiketimes(closest_spike)) = 0;
            A = find(spikes(ThisControlParadigm).A(ThisTrial,:));
            spikes(ThisControlParadigm).amplitudes_A(ThisTrial,A)  =  ssdm_1DAmplitudes(V,deltat,A,flip_V_control);
            B = find(spikes(ThisControlParadigm).B(ThisTrial,:));
            spikes(ThisControlParadigm).amplitudes_B(ThisTrial,B)  =  ssdm_1DAmplitudes(V,deltat,B,flip_V_control);
        end

        % update plot
        plot_resp;

 
    end


    function generate_summary(~,~)
        allfiles = dir(strcat(PathName,'*.mat'));
        if any(find(strcmp('cached.mat',{allfiles.name})))
            allfiles(find(strcmp('cached.mat',{allfiles.name}))) = [];
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



end


