if 0
    spktA21 = squeeze(tSPKA(2,1,:));
    spktA21(find(spktA21==0))=[];
    figure;plot(spktA21,'*')
    spkA21 = spiketime2spk(spktA21',5/deltat);
    errorbar_raster(spktA21*deltat, 1*ones(length(spktA21),1),0.5*ones(length(spktA21),1), 'k');
    hold on
    line([thitpointmat(2,1)/1000 thitpointmat(2,1)/1000],[.5 1.5],'lineWidth' ,2,'Color','r')
    line([thitpointmat(2,1)/900 thitpointmat(2,1)/900],[.5 1.5],'lineWidth' ,2,'Color','g')
    hold off
    
    [f,ftx] = amp_pwrspec1(data(1,4).voltage(1,:),(1:25000)/SamplingRate);
    
    
end
%% RASTER
% raster plot and onset times
if 1
    clc;
        t_txt = '2014_06_02_CSF_2_ab3_2_EA_1';
        savefigure = 1;
        xscltxt = '_focus';
        xlimm = [5 5.2];
%         xlimm = [0 5];
        t_txt = [t_txt xscltxt];
        figure('units','normalized','outerposition',[0 0 .7 .9]); 
        hold on;
        h = 8*(5+1);
        thitpointmat = t_hpoint;
        stimon = 1;
        area([0 stimon stimon (stimon+0.5) (stimon+0.5) 10], [0 0 h h 0 0], 'faceColor', [.85 .85 .85], 'edgeColor', [.85 .85 .85])
        nn=1;
        delay_timeA = zeros(size(ORN,1),5,5); % dil, trial, spk1:spk5
        
        for i = 1:size(ORN,1)
            for t = 1:5
                timesp = squeeze(tSPKA(i,t,:));
                timesp(timesp==0)=[];
                errorbar_raster(timesp*deltat, nn*ones(length(timesp),1),0.5*ones(length(timesp),1), 'k');
                line([thitpointmat(i,t)/1000 thitpointmat(i,t)/1000],[nn-.5 nn+.5],'lineWidth' ,2,'Color','r')
%                 line([thitpointmat(2,1)/900 thitpointmat(2,1)/900],[.5 1.5],'lineWidth' ,2,'Color','g')
                ttempa = timesp(find(timesp> (thitpointmat(i,t))*10));
                if length(ttempa)>=5
                    delay_timeA(i,t,:)=(ttempa(1:5)- thitpointmat(i,t)*10)/10;
                    line([ttempa(1) ttempa(1)]/10000,[nn-.5 nn+.5],'lineWidth' ,.5,'Color','g')
                end

                nn=nn+1;

            end
            nn=nn+3;
        end
        ylim([0 nn-2])
        xlim(xlimm)
        title(['Or22a - ' t_txt], 'Interpret', 'None')
        xlabel('time (sec)')
        hold off
        if savefigure
            figname=['Or22a ' t_txt];saveas(gcf,figname,'fig');set(gcf,'PaperPositionMode','auto');print(gcf,'-djpeg','-r300',figname);
        end
        
        figure('units','normalized','outerposition',[0 0 .7 .9]); 
        hold on;
        h = 8*(5+1);
        stimon = 1;
        area([0 stimon stimon (stimon+0.5) (stimon+0.5) 10], [0 0 h h 0 0], 'faceColor', [.85 .85 .85], 'edgeColor', [.85 .85 .85])
        nn=1;
        delay_timeB = zeros(6,5,5); % dil, trial, spk1:spk5
        for i = 1:size(ORN,1)
            for t = 1:5
                timesp = squeeze(tSPKB(i,t,:));
                timesp(timesp==0)=[];
                errorbar_raster(timesp*deltat, nn*ones(length(timesp),1),0.5*ones(length(timesp),1), 'k');
                line([thitpointmat(i,t)/1000 thitpointmat(i,t)/1000],[nn-.5 nn+.5],'lineWidth' ,2,'Color','r')
%                 line([thitpointmat(2,1)/900 thitpointmat(2,1)/900],[.5 1.5],'lineWidth' ,2,'Color','g')
                nn=nn+1;
                ttemp = timesp(find(timesp> (thitpointmat(i,t)/1000)));
                if length(ttemp)>=5
                    line([ttemp(1) ttemp(1)]/10000,[nn-.5 nn+.5],'lineWidth' ,.5,'Color','g')
                    delay_timeB(i,t,:)=ttemp(1:5)- thitpointmat(i,t)/1000;
                end


            end
            nn=nn+3;
        end
        ylim([0 nn-2])
        xlim(xlimm)
        title(['Or85b - ' t_txt], 'Interpret', 'None')
        xlabel('time (sec)')
        hold off
        if savefigure
            figname=['Or85b ' t_txt];saveas(gcf,figname,'fig');set(gcf,'PaperPositionMode','auto');print(gcf,'-djpeg','-r300',figname);
        end
        clc;
end

%% SPIKE RATES
% spike rates with PID
if 0
  
   
        t_txt = '2014_04_11_csm1_ab3_1_meth_but_2';
        savefigure = 1;
        xscltxt = '_focus';
        xlimm = [0 5];
%         t_txt = [t_txt xscltxt];
        
         % now plot all together
        figure('units','normalized','outerposition',[0 0 .9 .9]);
        for dil=1:6
                subplot(2,3,dil)
                plot(timesr,msrA(dil,:)','.k')
                mmsr = msrA(dil,:);
                basemsr = mean(msrA(dil,1:900));
                hold on
                mpid = mean(squeeze(PID(dil,:,:)),1);
                basepid = mean(mpid(1:9000));
                plot(timel, (mpid-basepid)/max(mpid-basepid)*max(mmsr-basemsr)+basemsr,'r')
                hold off
                xlim(xlimm)
%                 ylim([0 3.5])
                title(['\fontsize{16}dose = ' percent_mat{dil}])
                if dil == 4
                    xlabel('time (sec)')
                    ylabel('spike rate (1/s)')
                elseif dil == 1
                    legend('SR', 'rs PID')
                end
        end
    if savefigure
        figname=['Spike Rates & PID Curves' t_txt];saveas(gcf,figname,'fig');set(gcf,'PaperPositionMode','auto');print(gcf,'-djpeg','-r300',figname);
    end
    
    
end

%% DOSE RespOnse
% spike rates with PID
if 0
    clc    
    t_txt = '2014_04_11_csm1_ab3_1_meth_but_2';
        savefigure = 1;
        xscltxt = '_focus';
        xlimm = [0 5];
%         t_txt = [t_txt xscltxt];


    mspkcount = mean(SPKcountA,2);
    espkcount = std(SPKcountA,0,2);
    dosex = [0,20,40,60,80,100];
    figure('units','normalized','outerposition',[0 0 .7 .9]);
    errorbar(dosex,mspkcount,espkcount)
    xlabel('odor %')
    ylabel('total spikes during stimulus')
%     xlim(xlimm)
%     ylim([0 3.5])
    title(['Dose Response : ' t_txt ],'Interpret','None')
end
    if savefigure
        figname=['Total Spike Count vs Dose ' t_txt];saveas(gcf,figname,'fig');set(gcf,'PaperPositionMode','auto');print(gcf,'-djpeg','-r300',figname);
    end
    
    
    
    
    
    %% SPIKE RATES Comparison
% spike rates with PID
if 0
  
   
        t_txt = '2014_04_11_csm1_ab3_1_meth_but';
        savefigure = 0;
        xlimm = [0 5];
        
         % now plot all together
        figure('units','normalized','outerposition',[0 0 .9 .9]);
        for dil=1:6
                subplot(2,3,dil)
                plot(Exp1.timesr,Exp1.msrA(dil,:)','.k',Exp2.timesr,Exp2.msrA(dil,:)','.r')
%                 mmsr = Exp1.msrA(dil,:);
%                 basemsr = mean(Exp1.msrA(dil,1:900));
%                 hold on
%                 mpid = mean(squeeze(Exp1.PID(dil,:,:)),1);
%                 basepid = mean(Exp1.mpid(1:9000));
%                 plot(Exp1.timel, (mpid-basepid)/max(mpid-basepid)*max(mmsr-basemsr)+basemsr,'r')
%                 hold off
                xlim(xlimm)
%                 ylim([0 3.5])
                title(['\fontsize{16}dose = ' Exp1.percent_mat{dil}])
                if dil == 4
                    xlabel('time (sec)')
                    ylabel('spike rate (1/s)')
                elseif dil == 1
                    legend('Exp1', 'Exp2')
                end
        end
    if savefigure
        figname=['Spike Rates & PID Curves' t_txt];saveas(gcf,figname,'fig');set(gcf,'PaperPositionMode','auto');print(gcf,'-djpeg','-r300',figname);
    end
    
    
end

%% DOSE RespOnse
% spike rates with PID
if 0
    clc    
    t_txt = '2014_04_11_csm1_ab3_1_meth_but';
        savefigure = 1;
        xscltxt = '_focus';
        xlimm = [0 5];
%         t_txt = [t_txt xscltxt];


    mspkcount = mean(Exp1.SPKcountA,2);
    espkcount = std(Exp1.SPKcountA,0,2);
    dosex = [0,20,40,60,80,100];
    figure('units','normalized','outerposition',[0 0 .7 .9]);
    errorbar(dosex,mspkcount,espkcount,'*k')
    hold on
    
    mspkcount = mean(Exp2.SPKcountA,2);
    espkcount = std(Exp2.SPKcountA,0,2);
    errorbar(dosex,mspkcount,espkcount,'*r')
    xlabel('odor %')
    ylabel('total spikes during stimulus')

        hleg1=legend('Exp-1','Exp-2');
        set(hleg1,'Location','NorthWest')
        set(hleg1,'Interpreter','none')
    title(['Dose Response : ' t_txt ],'Interpret','None')
end
    if savefigure
        figname=['Total Spike Count vs Dose Compare ' t_txt];saveas(gcf,figname,'fig');set(gcf,'PaperPositionMode','auto');print(gcf,'-djpeg','-r300',figname);
    end
    
    
    %%
    %% Spike delay times after the odor onset Comparison
% The delay time is estimated as the time difference between the time of 
% the first spike right after the odor onset and odor onset time

    figure('units','normalized','outerposition',[0 0 .6 .7]); hold on;
    nop = 1;
    dosemat = [0,20,40,60,80,100];
    savefigure=0;
    clc;
    for i = 1:6
%     errorbar([0,20,40,60,80,100],1000*mean(mean(delay_timeA(1:6,2:5,1:nop),3),2),1000*std(std(delay_timeA(1:6,2:5,1:nop),0,3),0,2),'k*--');
    if i ==1
        errorbar(dosemat(i),mean(squeeze(Exp1.delay_timeA(i,2:5,1:nop))),std(squeeze(Exp1.delay_timeA(i,2:5,1:nop))),'k*')
        errorbar(dosemat(i),mean(squeeze(Exp2.delay_timeA(i,2:5,1:nop))),std(squeeze(Exp2.delay_timeA(i,2:5,1:nop))),'r*')
    else
        errorbar(dosemat(i),mean(squeeze(Exp1.delay_timeA(i,:,1:nop))),std(squeeze(Exp1.delay_timeA(i,:,1:nop))),'k*')
        errorbar(dosemat(i),mean(squeeze(Exp2.delay_timeA(i,:,1:nop))),std(squeeze(Exp2.delay_timeA(i,:,1:nop))),'r*')
    end
    end
    xlabel('dose %')
    ylabel('Delay (msec)')
    title('(ab3A) Or22a - Methyl Butyrate - First Spike After Odor Onset - Comparison')
    xlim([-10 110])
    hleg1=legend('Exp-1','Exp-2');
    set(hleg1,'Location','NorthWest')
    set(hleg1,'Interpreter','none')
    hold off
    if savefigure
        figname=['Delay time Compare ' t_txt];saveas(gcf,figname,'fig');set(gcf,'PaperPositionMode','auto');print(gcf,'-djpeg','-r300',figname);
    end