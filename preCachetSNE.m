function [] = preCachetSNE()

if license('test', 'Distrib_Computing_Toolbox')
	if ~length(gcp('nocreate'))
	else
		delete(gcp)
	end
	p = parpool(1);
	f = parfeval(p,@preCachetSNE_engine,0);
	return
else
	preCachetSNE_engine;
	return
end
