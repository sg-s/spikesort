% plots the response

function [] = plotResp(s,src,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

% when the raw voltage is set, we filter it (if need be), and display it
if s.filter_trace
    if s.verbosity
        cprintf('green','\n[INFO]')
        cprintf('text',' filtering trace...')
    end

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

else
    % do nothing
end  

s.time = s.pref.deltat*(1:length(s.raw_voltage));

% and display it
if s.filter_trace
    set(s.handles.ax1_data,'XData',s.time,'YData',s.filtered_voltage,'Color','k','Parent',s.handles.ax1);
else
    set(s.handles.ax1_data,'XData',s.time,'YData',s.raw_voltage,'Color','k','Parent',s.handles.ax1);
end

% fix the axis
if all(get(s.handles.ax1,'XLim') == [0 1])
    set(s.handles.ax1,'XLim',[min(s.time) max(s.time)]);
end


