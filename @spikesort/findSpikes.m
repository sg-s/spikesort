% findSpikes.m
% part of the spikesort package
% 
% created by Srinivas Gorur-Shandilya at 8:58 , 20 November 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
function findSpikes(s,~,~)

pref = s.pref;
if s.filter_trace
	V = s.filtered_voltage;
else
	V = s.raw_voltage;
end

if get(s.handles.prom_auto_control,'Value')
	%guess some nice value
	mpp = nanstd(V)/2;
else
	mpp = get(s.handles.spike_prom_slider,'Value');
end

mpd = pref.minimum_peak_distance;
mpw = pref.minimum_peak_width;
v_cutoff = pref.V_cutoff;


% find peaks and remove spikes beyond v_cutoff
if pref.invert_V
    [~,loc] = findpeaks(-V,'MinPeakProminence',mpp,'MinPeakDistance',mpd,'MinPeakWidth',mpw);
    loc(V(loc) < -abs(v_cutoff)) = [];
else
    [~,loc] = findpeaks(V,'MinPeakProminence',mpp,'MinPeakDistance',mpd,'MinPeakWidth',mpw);
    loc(V(loc) > abs(v_cutoff)) = [];
end


if pref.ssDebug
	cprintf('green','\n[INFO]')
    cprintf('text',[' found ' oval(length(loc)) ' spikes'])
end

s.loc = loc;
