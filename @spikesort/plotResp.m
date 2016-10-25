% plots the response

function [] = plotResp(s,src,~)

% clear some old stuff
set(s.handles.ax1_ignored_data,'XData',NaN,'YData',NaN);
set(s.handles.ax1_all_spikes,'XData',NaN,'YData',NaN);
set(s.handles.ax1_B_spikes,'XData',NaN,'YData',NaN);
set(s.handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
set(s.handles.ax1_spike_marker,'XData',NaN,'YData',NaN);
s.V = [];
s.Vf = [];
s.time = [];

% unpack some stuff
data = s.current_data.data;
ControlParadigm = s.current_data.ControlParadigm;
spikes = s.current_data.spikes;

n = structureElementLength(data); 

if n(s.this_paradigm)
    plotwhat = get(s.handles.resp_channel,'String');
    plotthis = plotwhat{get(s.handles.resp_channel,'Value')};
    eval(strcat('temp=data(s.this_paradigm).',plotthis,';'));
    temp = temp(s.this_trial,:);
    time = s.pref.deltat*(1:length(temp));
else
    return    
end

% check if we have chosen to discard this
if isfield(spikes,'discard')
    try spikes(s.this_paradigm).discard(s.this_trial);
        if spikes(s.this_paradigm).discard(s.this_trial) == 1
            % set the control
            set(s.handles.discard_control,'Value',1);
            set(s.handles.ax1_data,'XData',time,'YData',temp,'Color','k','Parent',s.handles.ax1);
            return
        else

            set(s.handles.discard_control,'Value',0);
        end
    catch
        set(s.handles.discard_control,'Value',0);
    end
end

V = temp;

if get(s.handles.filtermode,'Value') == 1
    if s.pref.ssDebug 
        disp('plotResp 1251: filtering trace...')
    end
    lc = 1/s.pref.band_pass(1);
    lc = floor(lc/s.pref.deltat);
    hc = 1/s.pref.band_pass(2);
    hc = floor(hc/s.pref.deltat);
    if s.pref.useFastBandPass
        [V,Vf] = fastBandPass(V,lc,hc);
    else
        [V,Vf] = bandPass(V,lc,hc);
    end
end 

% if strcmp(get(s.handles.remove_artifacts_menu,'Checked'),'on')
%     this_control = ControlParadigm(s.this_paradigm).Outputs;
%     V = removeArtifactsUsingTemplate(V,this_control,pref);
% end

set(s.handles.ax1_data,'XData',time,'YData',V,'Color','k','Parent',s.handles.ax1); 

% check if we are discarding part of the trace
ignored_fragments = 0*V;
if isfield(spikes,'use_trace_fragment')
    if length(spikes) < s.this_paradigm
    else
        if ~isempty(spikes(s.this_paradigm).use_trace_fragment)
            if width(spikes(s.this_paradigm).use_trace_fragment) < s.this_trial
            else
                ignored_fragments = ~spikes(s.this_paradigm).use_trace_fragment(s.this_trial,:);
                set(s.handles.ax1_ignored_data,'XData',time(ignored_fragments),'YData',V(ignored_fragments),'Color',[.5 .5 .5],'Parent',s.handles.ax1);
                if s.pref.ssDebug
                    disp('Ignoring part of the trace')
                end
            end
        end
    end
end


% do we have to find spikes too?
V_censored = V;
if any(ignored_fragments)
    V_censored(ignored_fragments) = NaN;
end
if get(s.handles.findmode,'Value') == 1

    if s.pref.ssDebug
        disp('plotResp 1304: invoking findSpikes...')
    end
    loc = findSpikes(V_censored); 
    set(s.handles.method_control,'Enable','on')

    % do we already have sorted spikes?
    if length(spikes) < s.this_paradigm
        % no spikes


        loc = findSpikes(V_censored); 
        set(s.handles.method_control,'Enable','on')
        if get(s.handles.autosort_control,'Value') == 1
            % sort spikes and show them
           
            [A,B] = autosort;
            set(s.handles.ax1_A_spikes,'XData',time(A),'YData',V(A),'Marker','o','MarkerSize',s.pref.marker_size,'Parent',s.handles.ax1,'MarkerEdgeColor','r','LineStyle','none');
            set(s.handles.ax1_B_spikes,'XData',time(B),'YData',V(B),'Marker','o','MarkerSize',s.pref.marker_size,'Parent',s.handles.ax1,'MarkerEdgeColor','b','LineStyle','none');
        else
            set(s.handles.ax1_all_spikes,'XData',time(loc),'YData',V(loc),'Marker','o','MarkerSize',s.pref.marker_size,'Parent',s.handles.ax1,'MarkerEdgeColor','m','LineStyle','none');
            set(s.handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
            set(s.handles.ax1_B_spikes,'XData',NaN,'YData',NaN);

        end
    else
   
        % maybe?
        if s.this_trial <= width(spikes(s.this_paradigm).A) 
      
            % check...
            if max(spikes(s.this_paradigm).A(s.this_trial,:))
                % yes, have spikes
      
                A = find(spikes(s.this_paradigm).A(s.this_trial,:));
                try
                    B = find(spikes(s.this_paradigm).B(s.this_trial,:));
                catch
                    warning('B spikes missing for this trial...')
                    B = [];
                end
                loc = [A B];
                set(s.handles.ax1_A_spikes,'XData',time(A),'YData',V(A),'Marker','o','MarkerSize',s.pref.marker_size,'Parent',s.handles.ax1,'MarkerEdgeColor','r','LineStyle','none');
                set(s.handles.ax1_B_spikes,'XData',time(B),'YData',V(B),'Marker','o','MarkerSize',s.pref.marker_size,'Parent',s.handles.ax1,'MarkerEdgeColor','b','LineStyle','none');
            else

                if get(autosort_control,'Value') == 1
                    % sort spikes and show them
                    [A,B] = autosort;
                    set(s.handles.ax1_A_spikes,'XData',time(A),'YData',V(A),'Marker','o','MarkerSize',s.pref.marker_size,'Parent',s.handles.ax1,'MarkerEdgeColor','r','LineStyle','none');
                    set(s.handles.ax1_B_spikes,'XData',time(B),'YData',V(B),'Marker','o','MarkerSize',s.pref.marker_size,'Parent',s.handles.ax1,'MarkerEdgeColor','b','LineStyle','none');
                else
                    
                    % no need to autosort, just show the identified peaks
                    set(s.handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
                    set(s.handles.ax1_B_spikes,'XData',NaN,'YData',NaN);
                    set(s.handles.ax1_all_spikes,'XData',time(loc),'YData',V(loc),'Marker','o','MarkerSize',s.pref.marker_size,'Parent',s.handles.ax1,'MarkerEdgeColor','m','LineStyle','none');
                end
            end
        else
            % no spikes
            if get(s.handles.autosort_control,'Value') == 1
                % sort spikes and show them
                [A,B] = autosort;
                set(s.handles.ax1_A_spikes,'XData',time(A),'YData',V(A),'Marker','o','MarkerSize',s.pref.marker_size,'Parent',s.handles.ax1,'MarkerEdgeColor','r','LineStyle','none');
                    set(s.handles.ax1_B_spikes,'XData',time(B),'YData',V(B),'Marker','o','MarkerSize',s.pref.marker_size,'Parent',s.handles.ax1,'MarkerEdgeColor','b','LineStyle','none');
            else
                % no need to autosort, no spikes to show
                set(s.handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
                    set(s.handles.ax1_B_spikes,'XData',NaN,'YData',NaN);
                    set(s.handles.ax1_all_spikes,'XData',time(loc),'YData',V(loc),'Marker','o','MarkerSize',s.pref.marker_size,'Parent',s.handles.ax1,'MarkerEdgeColor','m','LineStyle','none');
            end
        end
    end


    xlim = get(s.handles.ax1,'XLim');
    
    if xlim(1) < min(time)
        xlim(1) = min(time);
    end
    if xlim(2) > max(time)
        xlim(1) = min(time);
        xlim(2) = max(time);
    end
    xlim(2) = (floor(xlim(2)/s.pref.deltat))*s.pref.deltat;
    xlim(1) = (floor(xlim(1)/s.pref.deltat))*s.pref.deltat;
    
    ylim(2) = max(V(find(time==xlim(1)):find(time==xlim(2))));
    ylim(1) = min(V(find(time==xlim(1)):find(time==xlim(2))));
    yr = 2*nanstd(V(find(time==xlim(1)):find(time==xlim(2))));

    if (isnan(yr)) || any(isnan(xlim)) || any(isnan(ylim))

        xlim(2) = time(find(isnan(V),1,'first')-1);
        xlim(1) = s.pref.deltat;
        ylim(2) = max(V(1:find(isnan(V),1,'first')-1));
        ylim(1) = min(V(1:find(isnan(V),1,'first')-1));
        yr = 2*std(V(find(time==xlim(1)):find(time==xlim(2))));
    else

        if yr==0
            set(s.handles.ax1,'YLim',[ylim(1)-1 ylim(2)+1]);
        else
            set(s.handles.ax1,'YLim',[ylim(1)-yr ylim(2)+yr]);
        end
    end

else
    % ('No need to find spikes...')
    set(s.handles.ax1,'YLim',[min(V) max(V)]);
    set(s.handles.method_control,'Enable','off')
end

% this exception exists because XLimits weirdly go to [0 1] and "manual" even though I don't set them. 
xl  =get(s.handles.ax1,'XLim');
if xl(2) == 1
    set(s.handles.ax1,'XLim',[min(time) max(time)]);
    set(s.handles.ax1,'XLimMode','auto')
else
    % unless the X-limits have been manually changed, fix them
    if strcmp(get(s.handles.ax1,'XLimMode'),'auto')
        set(s.handles.ax1,'XLim',[min(time) max(time)]);
        % we spoof this because we want to distinguish this case from when the user zooms
        set(s.handles.ax1,'XLimMode','auto')
    end
end
end