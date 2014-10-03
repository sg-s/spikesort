%% Odorant onset-time detection
% We need to extract odor onset times to be used as references for neuron
% firings. The way I calculated the odor onset time (i.e. the time the
% odorant hits the PID, in other words the PID signal just starts to rise
% from baseline level) is explained below:
%% Odor onset detection algorithm
% 
% # Smooth data with a sliding box average in order to decrease fluctuations
% # Calculate the derivative of the smoothed data
% # Smooth the derivative as well
% # Find the points in the derivative data which are greater than a
% fixed multiple of the standard deviation of the derivative noise (i.e.
% derivative of the base PID signal). 
% # Select points only in the expected window. Basically take points
% between valve turn on and off with a fixed delay. (delay is due to the 9
% cm distancebetween the valve and PID suction inlet)
% # find the earliest one within the detected points and look at the data
% in the PID signal if that seem reasonable.
% # In order to find the optimal detection parameters (i.e. smoothing 
% window sizes and standard deviation comparison threshold) scan a bunch of
% values and find the the parameter set which gives the less variance in
% the time detection. Since the valve is turned oin at the same time for
% all different doses of the odorant the detected time should be same for
% all doses.othing should be detected, however since the odor delivery line
% is contaminated there is a slight increase in the PID signal and the 
% algorithm sets the smoothing window sizes to hundred in order to detect
% the time of these increases
% 
%% An example of odorant onset time detection as previously described
% Smoothing window sizes are 1-1 (data-derivative) therefore the
% calculation is done the raw data. The standard deviation comparison
% threshold is 3. This means the algorithm will detect points with 
% a derivative three times larger than the standard deviation of the
% derivative noise (the derivative of the PID baseline)
clc;
t_txt = '2014_06_02_csf2_ab3_2_EA_1';
savefigure = 1;
timel = (1:length(PID))*deltat;
percent_mat = [{'0%'} {'20%'} {'40%'} {'60%'} {'80%'} {'100%'}];
wsd =  [1 3 5 7 10 20 25 50];
thr = [1 2 3 4 5 7 10];
meanton = zeros(length(wsd),4);
stdton = zeros(length(wsd),4);
stim_on = 5;
xlimm = [stim_on-.5 stim_on+1];
ylimm = [0 1];
%%
% see how it works
if 1
for thrind = 4
    stdthreshold = thr(thrind);
    for lind = 3
%         for thrind = 1:length(thr)
%     stdthreshold = thr(thrind);
%     for lind = 1:length(wsd)
        winsdata = wsd(lind);
        txt = ['_w' num2str(winsdata) '_st' num2str(stdthreshold)];
        hpoint_std = zeros(6,5);
        [c, r] = getrc_subplot(size(ORN,1));
        for dil=1:size(ORN,1)
                %%
                figure('units','normalized','outerposition',[0 0 .9 .9]);
                for trial=1:5
                    subplot(2,3,trial)
                    std_noise = std(box_ave(PID(dil,trial,1:9000),winsdata));
                    mean_noise = mean(box_ave(PID(dil,trial,1:9000),winsdata));
                    indm = find(box_ave(PID(dil,trial,:),winsdata)>(mean_noise+stdthreshold*std_noise));
                    indm(indm<stim_on*10000)=[];
                    indm(indm>stim_on*10000+2000)=[];
                    if isempty(indm)
                        indm = stim_on+600;
                    end
                    hpoint_std(dil,trial)= min(indm);
                    plot(timel,squeeze(PID(dil,trial,:)),timel(min(indm)),PID(dil,trial,min(indm)),'*r')
                    xlim(xlimm)
                    title(['Trial # ' num2str(trial)])
                    if trial ==4
                        xlabel('time (sec)')
                        ylabel('PID (V)')
                    end
                end
                subplot(2,3,6)
                text(.1,.7,'\fontsize{16}Detected Onset-Time')
                text(.1,.6,['\fontsize{16}dilution = ' num2str(dil)])
                text(.1,.5,['\fontsize{16}windsize =' num2str(winsdata)])
                text(.1,.4,['\fontsize{16}std thresh = ' num2str(stdthreshold)])
        end
    end
        t_hpoint = hpoint_std/10;
        t_hpoint(:,6) = mean(t_hpoint(:,1:5),2);
        t_hpoint(:,7) = std(t_hpoint(:,1:5),0,2);
        %%
        % The following figure shows the onset times as a function of the
        % applied doses. Our goal is to find a set of parameters which
        % detecs onset times with the least variance.
        figure('units','normalized','outerposition',[0 0 .6 .7]);
        errorbar((1:size(ORN,1)),t_hpoint(:,6),t_hpoint(:,7),'ko','MarkerSize',7)
        xlabel('dose %')
        title(['Detected Onset-Times for Windsize =' num2str(winsdata) ', std thresh = ' num2str(stdthreshold)])
        grid on
        ylabel('odor onset time (ms)')
        eval(['t_hpoint' txt '=t_hpoint;']);
%         ylim([1050 1080])
    if savefigure
        figname=['Onset Times ' t_txt];saveas(gcf,figname,'fig');set(gcf,'PaperPositionMode','auto');print(gcf,'-djpeg','-r300',figname);
    end
        
        
        
        
        %%
        % now plot all together
        figure('units','normalized','outerposition',[0 0 .9 .9]);
        for dil=1:size(ORN,1)
                subplot(c,r,dil)
                hold on
                base = 0;
                for trial=1:5
                    std_noise = std(box_ave(PID(dil,trial,1:9000),winsdata));
                    mean_noise = mean(box_ave(PID(dil,trial,1:9000),winsdata));
                    indm = find(box_ave(PID(dil,trial,:),winsdata)>(mean_noise+stdthreshold*std_noise));
                    indm(indm<stim_on*10000)=[];
                    indm(indm>stim_on*10000+2000)=[];
                    if isempty(indm)
                        indm = stim_on+600;
                    end
                    hpoint_std(dil,trial)= min(indm);
                    plot(timel,squeeze(PID(dil,trial,:))+base,timel(min(indm)),PID(dil,trial,min(indm)) + base,'*r')
                    base = base + .3*max(squeeze(PID(dil,trial,:)));
                end
                xlim([4.5 6])
%                 ylim([0 3.5])
                title(['\fontsize{16}dose = ' num2str(dil)])
                if dil == c*(r-1)+1
                    xlabel('time (sec)')
                    ylabel('PID (V)')
                end
       end
    if savefigure
        figname=['Onset Times on PID Curves' t_txt];saveas(gcf,figname,'fig');set(gcf,'PaperPositionMode','auto');print(gcf,'-djpeg','-r300',figname);
    end
    
    
     %%
        % now plot all together normalized PIDs
        figure('units','normalized','outerposition',[0 0 .9 .9]);
        for dil=1:size(ORN,1)
                subplot(c,r,dil)
                hold on
                base = 0;
                for trial=1:5
                    std_noise = std(box_ave(PID(dil,trial,1:9000),winsdata));
                    mean_noise = mean(box_ave(PID(dil,trial,1:9000),winsdata));
                    indm = find(box_ave(PID(dil,trial,:),winsdata)>(mean_noise+stdthreshold*std_noise));
                    indm(indm<stim_on*10000)=[];
                    indm(indm>stim_on*10000+2000)=[];
                    if isempty(indm)
                        indm = stim_on+600;
                    end
                    hpoint_std(dil,trial)= min(indm);
                    baseval = mean(box_ave(PID(dil,trial,1:9000),winsdata));
                    maxval = max(PID(dil,trial,stim_on*10000+1:(stim_on+1)*10000+1));
                    norm_curve = (squeeze(PID(dil,trial,:))-baseval)/(maxval-baseval);
                    plot(timel,norm_curve+base,timel(min(indm)),norm_curve(min(indm)) + base,'*r')
                    base = base + 1.1;
                end
                xlim([4.5 6])
%                 ylim([0 3.5])
                title(['\fontsize{16}dose = ' num2str(dil)])
                if dil == c*(r-1)+1
                    xlabel('time (sec)')
                    ylabel('normalized PID (V)')
                end
       end
    if savefigure
        figname=['Onset Times on Normalized PID Curves' t_txt];saveas(gcf,figname,'fig');set(gcf,'PaperPositionMode','auto');print(gcf,'-djpeg','-r300',figname);
    end
end
end
