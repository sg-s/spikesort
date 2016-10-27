

function scroll(s,~,event)

% unpack some data
V = s.filtered_voltage;
loc = s.loc;
time = s.time;

xlimits = get(s.handles.ax1,'XLim');
xrange = (xlimits(2) - xlimits(1));
scroll_amount = event.VerticalScrollCount;
if s.pref.smart_scroll
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
    n_spikes_in_view = length(loc(loc>(xlimits(1)/s.pref.deltat) & loc<(xlimits(2)/s.pref.deltat)));
    if scroll_amount > 0
        try
            newlim(1) = min([max(time) (xlimits(1)+.2*xrange)]);
            newlim(2) = loc(find(loc > newlim(1)/s.pref.deltat,1,'first') + n_spikes_in_view)*s.pref.deltat;
        catch
        end
    else
        try
            newlim(2) = max([min(time)+xrange (xlimits(2)-.2*xrange)]);
            newlim(1) = loc(find(loc < newlim(2)/s.pref.deltat,1,'last') - n_spikes_in_view)*s.pref.deltat;
        catch
        end
    end
end

try
    set(s.handles.ax1,'Xlim',newlim)
catch
end

xlim = get(s.handles.ax1,'XLim');
if xlim(1) < min(time)
    xlim(1) = min(time);
end
if xlim(2) > max(time)
    xlim(2) = max(time);
end
xlim(2) = (floor(xlim(2)/s.pref.deltat))*s.pref.deltat;
xlim(1) = (floor(xlim(1)/s.pref.deltat))*s.pref.deltat;
ylim(2) = max(V(find(time==xlim(1)):find(time==xlim(2))));
ylim(1) = min(V(find(time==xlim(1)):find(time==xlim(2))));
yr = 2*std(V(find(time==xlim(1)):find(time==xlim(2))));
if yr==0
    set(s.handles.ax1,'YLim',[ylim(1)-1 ylim(2)+1]);
else
    set(s.handles.ax1,'YLim',[ylim(1)-yr ylim(2)+yr]);
end
