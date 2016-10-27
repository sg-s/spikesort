% plots the response

function [] = plotResp(s,src,~)

% clear some old stuff
set(s.handles.ax1_ignored_data,'XData',NaN,'YData',NaN);
set(s.handles.ax1_all_spikes,'XData',NaN,'YData',NaN);
set(s.handles.ax1_B_spikes,'XData',NaN,'YData',NaN);
set(s.handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
set(s.handles.ax1_spike_marker,'XData',NaN,'YData',NaN);

s.R = []; % this holds the dimensionality reduced data
s.filtered_voltage = []; % holds the current trace that is shown on screen
s.raw_voltage = [];
s.LFP = [];
s.V_snippets = [];% matrix of snippets around spike peaks
s.time = []; % vector of timestamps
s.loc = []; % holds current spike times
s.use_this_fragment = [];

s.A = [];
s.B = [];
s.N = [];

% unpack some stuff
data = s.current_data.data;
if isfield(s.current_data,'spikes')
    spikes = s.current_data.spikes;
else
    spikes = [];
end


plotwhat = get(s.handles.resp_channel,'String');
plotthis = plotwhat{get(s.handles.resp_channel,'Value')};
temp = data(s.this_paradigm).(plotthis);
temp = temp(s.this_trial,:);
s.time = s.pref.deltat*(1:length(temp));

s.raw_voltage = temp;

% check if we have chosen to discard this
if isfield(spikes,'discard')
    try spikes(s.this_paradigm).discard(s.this_trial);
        if spikes(s.this_paradigm).discard(s.this_trial) == 1
            % set the control
            set(s.handles.discard_control,'Value',1);
            set(s.handles.ax1_data,'XData',s.time,'YData',s.raw_voltage,'Color','k','Parent',s.handles.ax1);
            return
        else

            set(s.handles.discard_control,'Value',0);
        end
    catch
        set(s.handles.discard_control,'Value',0);
    end
end



if get(s.handles.filtermode,'Value') == 1
    if s.pref.ssDebug 
        cprintf('green','\n[INFO]')
        cprintf('text',' filtering trace...')
    end
    tic
    lc = 1/s.pref.band_pass(1);
    lc = floor(lc/s.pref.deltat);
    hc = 1/s.pref.band_pass(2);
    hc = floor(hc/s.pref.deltat);
    if s.pref.useFastBandPass
        [s.filtered_voltage,s.LFP] = fastBandPass(s.raw_voltage,lc,hc);
        error('this case is not usable yet. need to clean up trace...')
    else
        [s.filtered_voltage,s.LFP] = bandPass(s.raw_voltage,lc,hc);
    end
    t = toc;
    if s.pref.ssDebug 
        fprintf([' DONE in ' oval(t) ' sec'])
    end
end 


% if strcmp(get(s.handles.remove_artifacts_menu,'Checked'),'on')
%     this_control = ControlParadigm(s.this_paradigm).Outputs;
%     V = removeArtifactsUsingTemplate(V,this_control,pref);
% end

set(s.handles.ax1_data,'XData',s.time,'YData',s.filtered_voltage,'Color','k','Parent',s.handles.ax1); 

% check if we are discarding part of the trace
% s.use_this_fragment = 1+0*s.filtered_voltage;
% if isfield(spikes,'use_trace_fragment')
%     error('not coded! error 81')
%     if length(spikes) < s.this_paradigm
%     else
%         if ~isempty(spikes(s.this_paradigm).use_trace_fragment)
%             if width(spikes(s.this_paradigm).use_trace_fragment) < s.this_trial
%             else
%                 ignored_fragments = ~spikes(s.this_paradigm).use_trace_fragment(s.this_trial,:);
%                 set(s.handles.ax1_ignored_data,'XData',s.time(ignored_fragments),'YData',V(ignored_fragments),'Color',[.5 .5 .5],'Parent',s.handles.ax1);
%                 if s.pref.ssDebug
%                     disp('Ignoring part of the trace')
%                 end
%             end
%         end
%     end
% end


% V_censored = V;
% if any(ignored_fragments)
%     V_censored(ignored_fragments) = NaN;
% end

% do we have to find spikes too?
find_spikes = false;
if get(s.handles.findmode,'Value') == 1

    % do we already have sorted spikes?
    if length(spikes) < s.this_paradigm
        % no spikes
        find_spikes = true;
    else
        % maybe we already have spikes? check
        if s.this_trial <= width(spikes(s.this_paradigm).A) 
            % check...
            if max(spikes(s.this_paradigm).A(s.this_trial,:)) || max(spikes(s.this_paradigm).B(s.this_trial,:))
                % yes, have spikes
                if s.pref.ssDebug 
                    cprintf('green','\n[INFO]')
                    cprintf('text',' Spikes already found in this trial.')
                end
                A = find(spikes(s.this_paradigm).A(s.this_trial,:));
                try
                    B = find(spikes(s.this_paradigm).B(s.this_trial,:));
                catch
                    if s.pref.ssDebug 
                        cprintf('red','\n[WARN]')
                        cprintf('text',' B spikes missing.')
                    end
                    B = [];
                end
                s.loc = [A B];
                s.A = A;
                s.B = B; % be careful in the order of this assignation 
            else
                % no spikes here, need to find them
                find_spikes = true;
            end
        else
            % no spikes
            find_spikes = true;
        end
    end

else
    if s.pref.ssDebug 
        cprintf('green','\n[INFO]')
        cprintf('text',' No need to find spikes')
    end
    set(s.handles.ax1,'YLim',[min(s.filtered_voltage) max(s.filtered_voltage)]);
    set(s.handles.method_control,'Enable','off')
end

if find_spikes
    if s.pref.ssDebug 
        cprintf('green','\n[INFO]')
        cprintf('text',' Finding spikes...')
    end
    tic;
    s.loc = findSpikes(s.filtered_voltage); 
    t = toc;
    if s.pref.ssDebug 
        fprintf([' DONE in ' oval(t) ' sec'])
    end
    set(s.handles.method_control,'Enable','on')
end

% fix the axis
if all(get(s.handles.ax1,'XLim') == [0 1])
    set(s.handles.ax1,'XLim',[min(s.time) max(s.time)]);
end
