% spikesort plugin
% plugin_type = 'plot-spikes';
% data_extension = 'kontroller';
% 
function s = plotSpikes_kontroller(s,plot_type)



if strcmp(plot_type,'raster')

	figure('outerposition',[0 0 1000 500],'PaperUnits','points','PaperSize',[1000 500]); hold on
	yoffset = 0;
	ytick = 0;
	L = {};

	% read data
	m = matfile([s.path_name s.file_name]);
	spikes = m.spikes;
	ControlParadigm = m.ControlParadigm;

	for i = 1:length(spikes)
	    if length(spikes(i).A) > 1
	        raster2(spikes(i).A,spikes(i).B,'yoffset',yoffset,'deltat',s.pref.deltat);
	        yoffset = yoffset + width(spikes(i).A)*2 + 1;
	        ytick = [ytick yoffset];
	        L = [L strrep(ControlParadigm(i).Name,'_','-')];
	        
	    end
	end
	set(gca,'YTick',ytick(1:end-1)+diff(ytick)/2,'YTickLabel',L,'box','on','XLim',[0 max(cellfun(@length,{ControlParadigm.Outputs}))*s.pref.deltat])
	xlabel('Time (s)')
	prettyFig('plw',1);
	


elseif strcmp(plot_type,'firing_rate')
	error('not coded')
else
	error('Unknown plot_type')
end

