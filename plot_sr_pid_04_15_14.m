%%
%
clc;
neuron_name = 'B';
eval(['srtemp = sr' neuron_name ';']);
srn = zeros(size(srtemp));
pidsn = zeros(size(srtemp,1),size(srtemp,2),size(PID,3));
xlimm = [4.5 8];
setczero = 1;
num_of_dil = 7;
c_odor = zeros(1,length(ControlParadigm)-1);
pid_max = zeros(7,length(ControlParadigm)-1); % 5 trials and average and stdev
pid_amp_max = zeros(7,length(ControlParadigm)-1); % 5 trials and average and stdev
sr_max = zeros(7,length(ControlParadigm)-1);
czeroval = .1;
c_odor(1) = 0;
    for i=2:length(ControlParadigm)-1
        c = strsplit(ControlParadigm(i).Name,'_');
        if length(c)>1
            if  strcmp(c(2),'pure');
                c_odor(i) = 100;
            else            
                c_odor(i) = str2double(c(3))/(str2double(c(3))+str2double(c(4)));
            end
            if setczero == 1
                if c_odor(i) ==0
                    c_odor(i) = czeroval;
                end
            end
        end
    end

%percent_mat = [{'0%'} {'20%'} {'40%'} {'60%'} {'80%'} {'100%'}];
        for i = 1:5
            pid_max(i,1) = mean(PID(1,i,1:9000));
            pid_amp_max(i,1) = 0;
            indm = find(timesr<5, 1, 'last' );
            sr_max(i,1) = mean(srtemp(1,i,1:indm));
        end
            pid_max(6,1) = mean(pid_max(1:5,1));
            sr_max(6,1) = mean(sr_max(1:5,1));
            pid_max(7,1) = std(pid_max(1:5,1));
            sr_max(7,1) = std(sr_max(1:5,1));
            pid_amp_max(6,1) = mean(pid_amp_max(1:5,1));
            pid_amp_max(7,1) = std(pid_amp_max(1:5,1));

    for dil = 2:length(ControlParadigm)-1
        figure('units','normalized','outerposition',[0 0 .9 .9]);
        for i = 1:5
            srn(dil,i,:) = ((srtemp(dil-1,i,:))-min(srtemp(dil-1,i,:)))/(max(srtemp(dil-1,i,:))-min(srtemp(dil-1,i,:)));
            pidsn(dil,i,:) = ((PID(dil-1,i,:))-min(PID(dil-1,i,:)))/(max(PID(dil-1,i,:))-min(PID(dil-1,i,:)));
            subplot(2,3,i)
            plot(timesr,squeeze(srn(dil,i,:)),(1:length(PID))*deltat,squeeze(pidsn(dil,i,:)));
            xlim(xlimm)
            pid_max(i,dil) = max(max(PID(dil-1,i,:)));
            sr_max(i,dil) = max(max(srtemp(dil-1,i,:)));
            pid_amp_max(i,dil) = pid_max(i,dil)-mean(PID(dil-1,i,1:9000));
        end
        subplot(2,3,6)
        plot(timesr,squeeze(mean(srn(dil,:,:),2)),(1:length(PID))*deltat,squeeze(mean(pidsn(dil,:,:),2)));legend('SR','PID')
        title([num2str(log(c_odor(dil)/100)) ' dil'])
        xlabel('time (sec)')
        xlim(xlimm)
            pid_max(6,dil) = mean(pid_max(1:5,dil));
            sr_max(6,dil) = mean(sr_max(1:5,dil));
            pid_max(7,dil) = std(pid_max(1:5,dil));
            sr_max(7,dil) = std(sr_max(1:5,dil));
            pid_amp_max(6,dil) = mean(pid_amp_max(1:5,dil));
            pid_amp_max(7,dil) = std(pid_amp_max(1:5,dil));
    end
    eval(['c_odor' neuron_name '= c_odor;']);
    eval(['sr_max' neuron_name '= sr_max;']);
    eval(['pid_max' neuron_name '= pid_max;']);
    eval(['pid_amp_max' neuron_name '= pid_amp_max;']);
    %
% figure('units','normalized','outerposition',[0 0 .6 .7]);
% for dil = 1:7
%     subplot(3,3,dil)
%     indm = find(squeeze(mean(pidsn(dil,:,:),2))==max(squeeze(mean(pidsn(dil,:,:),2))));
%     plot(squeeze(mean(pidsn(dil,:,1::),2)),squeeze(mean(srn(dil,:,1::),2)),'k',squeeze(mean(pidsn(dil,:,indm:end),2)),squeeze(mean(srn(dil,:,indm:end),2)),'r');
%     xlabel('pid')
%     ylabel('sr')
%     title([num2str(c_odor(dil)/100) ' dil'])
%     xlim([0 .002])
% end

%%
%
if 0
figure('units','normalized','outerposition',[0 0 .6 .7]);
[c, r] = getrc_subplot(7);

for dil = 1:7
    subplot(c,r,dil)
    plot(max(pidsn(dil,:,:)),squeeze(mean(srn(dil,:,:),2)),'k',squeeze(mean(pidsn(dil,:,indm:end),2)),squeeze(mean(srn(dil,:,indm:end),2)),'r');
    xlabel('pid')
    ylabel('sr')
    title([num2str(c_odor(dil)/100) ' dil'])
    xlim([0 .002])
end
end
        
%% plot max spike rate vs pid values
%
figure('units','normalized','outerposition',[0 0 .6 .7]);
plot(pid_amp_max(1:5,:),sr_max(1:5,:),'*');
hold on
errorbarxy(pid_amp_max(6,:),sr_max(6,:),pid_amp_max(7,:),sr_max(7,:),{'go', 'g', 'g'})
xlabel('pid amp (V)')
ylabel('max spk rate (Hz)')
%legend('ab3a-1','ab3a-1','ab3a-2','ab3a-3')



