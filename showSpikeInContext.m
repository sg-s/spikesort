% showSpikeInContext
% 
% created by Srinivas Gorur-Shandilya at 1:04 , 11 September 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function showSpikeInContext(data,idx,this_pt)

cla(data.ax)
t = 1e-4*(1:length(data.V));
plot(data.ax,t,data.V,'k')
set(data.ax,'XLim',[data.loc(this_pt)*1e-4 - .2 data.loc(this_pt)*1e-4 + .2]);
yy = get(data.ax,'YLim');
plot(data.ax,[data.loc(this_pt) data.loc(this_pt)]*1e-4,yy,'r')

% plot A and B
plot(data.ax,data.loc(idx == 1)*1e-4,data.V(data.loc(idx == 1)),'ro')
plot(data.ax,data.loc(idx == 2)*1e-4,data.V(data.loc(idx == 2)),'bo')
plot(data.ax,data.loc(idx == 3)*1e-4,data.V(data.loc(idx == 3)),'kx')