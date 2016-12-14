% plots the stimulus in the secondary plot

function [] = plotStim(s,~,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

set(s.handles.ax2_data,'XData',s.time,'YData',s.stimulus,'Color','k');
