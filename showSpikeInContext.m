% showSpikeInContext
% 
% created by Srinivas Gorur-Shandilya at 1:04 , 11 September 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function showSpikeInContext(data,idx,this_pt)

handles = data.handles;

t = 1e-4*(1:length(data.V));
set(handles.ax1_data,'XData',t,'YData',data.V,'k')
set(handles.ax1,'XLim',[data.loc(this_pt)*1e-4 - .2 data.loc(this_pt)*1e-4 + .2]);
yy = get(handles.ax1,'YLim');
set(handles.ax1_spike_marker,'XData',[data.loc(this_pt) data.loc(this_pt)]*1e-4,'YData',yy,'Color','r')

% plot A and B
set(handles.ax1_A_spikes,'XData',data.loc(idx == 1)*1e-4,'YData',data.V(data.loc(idx == 1)),'Color','r','LineStyle','none','Marker','o');
set(handles.ax1_B_spikes,'XData',data.loc(idx == 2)*1e-4,'YData',data.V(data.loc(idx == 2)),'Color','b','LineStyle','none','Marker','o');
set(handles.ax1_all_spikes,'XData',data.loc(idx == 3)*1e-4,'YData',data.V(data.loc(idx == 3)),'Color','k','LineStyle','none','Marker','x');
