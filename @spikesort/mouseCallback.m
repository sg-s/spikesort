
function mouseCallback(s,~,~)
p = get(s.handles.ax1,'CurrentPoint');
p = p(1,1:2);
modify(s,p)
