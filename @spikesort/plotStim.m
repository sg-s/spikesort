

function [] = plotStim(s,~,~)

% unpack some data
data = s.current_data.data;
ControlParadigm = s.current_data.ControlParadigm;

% plot the stimulus and other things in handles.ax2
n = structureElementLength(data); 
miny = Inf; maxy = -Inf;
if n(s.this_paradigm)
    plotwhat = get(s.handles.stim_channel,'String');
    nchannels = length(get(s.handles.stim_channel,'Value'));
    plot_these = get(s.handles.stim_channel,'Value');
    c = jet(nchannels);
    if nchannels == 1
        c = [0 0 0];
    end
    for i = 1:nchannels
        
        if plot_these(i) > length(fieldnames(data))
            temp = ControlParadigm(s.this_paradigm).Outputs(plot_these(i) - length(fieldnames(data)),:);
        else
            plotthis = plotwhat{plot_these(i)};
            eval(strcat('temp=data(s.this_paradigm).',plotthis,';'));
            temp = temp(s.this_trial,:);
        end
        time = s.pref.deltat*(1:length(temp));

        set(s.handles.ax2_data,'XData',time,'YData',temp,'Color',c(i,:),'Parent',s.handles.ax2);
        miny = min([miny min(temp)]);
        maxy = max([maxy max(temp)]);
    end
end

% rescale the Y axis appropriately
if ~isinf(sum(abs([maxy miny])))
    if maxy > miny
        set(s.handles.ax2,'YLim',[miny maxy+.1*(maxy-miny)]);
    end
end

% plot the control signals using thick lines
if n(s.this_paradigm)
    plotwhat = get(s.handles.valve_channel,'String');
    nchannels = length(get(s.handles.valve_channel,'Value'));
    plot_these = get(s.handles.valve_channel,'Value');
    c = jet(nchannels);
    if nchannels == 1
        c = [0 0 0];
    end

    ymax = get(s.handles.ax2,'YLim');
    ymin = ymax(1); ymax = ymax(2); 
    y0 = (ymax- .1*(ymax-ymin));
    dy = (ymax-y0)/nchannels;
    thisy = ymax;

    % first try to erase all the old stuff
    for i = 1:10
        set(s.handles.ax2_control_signals(i),'XData',NaN,'YData',NaN);
    end

    for i = 1:nchannels
        temp = ControlParadigm(s.this_paradigm).Outputs(plot_these(i),:);
        if s.pref.plot_control
            % plot the control signal directly
            time = pref.deltat*(1:length(temp));
            set(s.handles.ax2_data,'XData',time,'YData',temp,'LineWidth',1); hold on;
            try
                set(s.handles.ax2,'YLim',[min(temp) max(temp)]);
            catch
            end
        else
            temp(temp>0)=1;
            time = pref.deltat*(1:length(temp));
            thisy = thisy - dy;
            temp = temp*thisy;
            temp(temp==0) = NaN;
            set(s.handles.ax2_control_signals(i),'XData',time,'YData',temp,'Color',c(i,:),'LineWidth',5,'Parent',s.handles.ax2); hold on;
        end
    end
end
    
