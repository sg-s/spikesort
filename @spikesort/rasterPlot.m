function rasterPlot(s,~,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

figure('outerposition',[0 0 1000 500],'PaperUnits','points','PaperSize',[1000 500]); hold on
yoffset = 0;
ytick = 0;
L = {};

% unpack data
spikes = s.current_data.spikes;
ControlParadigm = s.current_data.ControlParadigm;

for i = 1:length(spikes)
    if length(spikes(i).A) > 1
        raster2(spikes(i).A,spikes(i).B,yoffset);
        yoffset = yoffset + width(spikes(i).A)*2 + 1;
        ytick = [ytick yoffset];
        L = [L strrep(ControlParadigm(i).Name,'_','-')];
        
    end
end
set(gca,'YTick',ytick(1:end-1)+diff(ytick)/2,'YTickLabel',L,'box','on')
xlabel('Time (s)')


