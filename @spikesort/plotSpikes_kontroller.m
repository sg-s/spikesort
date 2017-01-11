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
		
	% compatbility layer with legacy code
	m = matfile([s.path_name s.file_name]);
	pref = s.pref;
	spikes = m.spikes; 
	SamplingRate = 1/s.pref.deltat;   
	time = s.time;
	ControlParadigm = m.ControlParadigm;


	if pref.show_r2
	    figure('outerposition',[0 0 1200 800],'PaperUnits','points','PaperSize',[1200 800]); hold on
	    sp(1)=subplot(2,4,1:3); hold on
	    sp(2)=subplot(2,4,5:7); hold on
	    sp(3)=subplot(2,4,4); hold on
	    sp(4)=subplot(2,4,8); hold on
	else
	    figure('outerposition',[0 0 1000 800],'PaperUnits','points','PaperSize',[1000 800]); hold on
	    sp(1)=subplot(2,1,1); hold on
	    sp(2)=subplot(2,1,2); hold on
	end
	ylabel(sp(1),'Firing Rate (Hz)')
	title(sp(1),'A neuron')
	title(sp(2),'B neuron')
	ylabel(sp(2),'Firing Rate (Hz)')
	xlabel(sp(2),'Time (s)')

	haz_data = [];
	for i = 1:length(spikes)
	    if length(spikes(i).A) > 1
	        haz_data = [haz_data i];
	    end
	end
	if length(haz_data) == 1
	    c = [0 0 0];
	else
	    c = parula(length(haz_data));
	end
	L = {};
	f_waitbar = waitbar(0.1, 'Computing Firing rates...');
	for i = 1:length(haz_data)
	    l(i) = plot(sp(1),NaN,NaN,'Color',c(i,:));
	    waitbar((i-1)/length(spikes),f_waitbar);
	    if length(spikes(haz_data(i)).A) > 1

	        % do A
	        time = (1:length(spikes(haz_data(i)).A))/SamplingRate;
	        [fA,tA] = spiketimes2f(spikes(haz_data(i)).A,time,pref.firing_rate_dt,pref.firing_rate_window_size);
	        tA = tA(:);
	        % remove trials with no spikes
	        fA(:,sum(fA) == 0) = [];

	    
	        % censor fA when we ignore some data
	        if isfield(spikes,'use_trace_fragment')
	            if any(sum(spikes(haz_data(i)).use_trace_fragment') < length(spikes(haz_data(i)).A))
	                % there is excluded data somewhere
	                for j = 1:width(spikes(haz_data(i)).use_trace_fragment)
	                    try
	                        fA(spikes(haz_data(i)).use_trace_fragment(j,1:10:end),j) = NaN;
	                    catch
	                    end
	                end
	            end
	        end

	        if width(fA) > 1
	            if pref.show_firing_rate_trials
	                for j = 1:width(fA)
	                    l(i) = plot(sp(1),tA,fA(:,j),'Color',c(i,:));
	                end
	            else
	               l(i) = plot(sp(1),tA,nanmean(fA,2),'Color',c(i,:));
	            end
	            if pref.show_firing_rate_r2
	                hash = dataHash(fA);
	                cached_data = (cache(hash));
	                if isempty(cached_data)
	                    r2 = rsquare(fA);
	                else
	                    r2 = cached_data;
	                    cache(hash,r2);
	                end
	                axes(sp(3))
	                imagescnan(r2)
	                caxis([0 1])
	                colorbar
	                axis image
	                axis off
	                
	            end
	        else
	            try
	               l(i) = plot(sp(1),tA,(fA),'Color',c(i,:));
	            catch
	                % no data, ignore.
	            end
	        end
	        

	        % do B    
	        time = (1:length(spikes(haz_data(i)).B))/SamplingRate;
	        [fB,tB] = spiketimes2f(spikes(haz_data(i)).B,time);
	        tB = tB(:);
	        % remove trials with no spikes
	        fB(:,sum(fB) == 0) = [];

	        if width(fB) > 1
	            if pref.show_firing_rate_trials
	                for j = 1:width(fB)
	                    l(i) = plot(sp(2),tA,fB(:,j),'Color',c(i,:));
	                end
	            else
	               l(i) = plot(sp(2),tB,nanmean(fB,2),'Color',c(i,:));
	            end
	            if pref.show_firing_rate_r2
	                hash = dataHash(fB);
	                cached_data = (cache(hash));
	                if isempty(cached_data)
	                    r2 = rsquare(fB);
	                else
	                    r2 = cached_data;
	                    cache(hash,r2);
	                end
	                axes(sp(4))
	                imagescnan(r2)
	                caxis([0 1])
	                colorbar
	                axis image
	                axis off
	            end
	        else
	            try
	               l(i) = plot(sp(2),tB,(fB),'Color',c(i,:));
	            catch
	            end
	        end


	        L = [L strrep(ControlParadigm(haz_data(i)).Name,'_','-')];
	        
	    end
	end

	legend(l,L)
	close(f_waitbar)
	linkaxes(sp(1:2))
	prettyFig('font_units','points');
else
	error('Unknown plot_type')
end

