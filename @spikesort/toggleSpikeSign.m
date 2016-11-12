function [] =  toggleSpikeSign(s,~,~)

if get(s.handles.spike_sign_control,'Value')
	set(s.handles.spike_sign_control,'String','Finding +ve spikes')
	s.pref.invert_V = false;
else
	set(s.handles.prom_auto_control,'String','Finding -ve spikes')
	s.pref.invert_V = true;
end

s.findSpikes;
