% master dispatched when we want to cluster the data

function clusterCallback(s,~,~)


method = (get(s.handles.cluster_control,'Value'));
temp = get(s.handles.cluster_control,'String');
method = temp{method};
method = str2func(method);

method(s);
 