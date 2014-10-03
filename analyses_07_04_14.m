%% PID and Neuron Responses
% Natural mimmicking stimulus was created by oscillationg MFC air flow with
% 0.2 Hz and the valves were swicthed on and off randomly with a
% correlation length of 50 ms. The stimulus is reproducible qualitatively
% but the values decrease from trial to trial becasue of the adapting
% MFC's.
clc;
clear
load('2014_07_04_EA_nat_stim_2_CSF_1_ab2_1_3_all_11.mat')
xlimm = [29 42];
figure('units','normalized','outerposition',[0 0 .7 .9]); 
subplot(4,1,1)
semilogy(time,pid)
ylabel('PID (V)')
title('PID values of ab2 recordings')
xlim(xlimm)
set(gca,'xtick',[])
set(gca,'xticklabel',[])
subplot(4,1,2)
raster_experiment(tsA)
title('Raster of ab2A neuron')
ylabel('trials')
axis tight
set(gca,'xtick',[])
set(gca,'xticklabel',[])
xlim(xlimm)
% daspect([.4,1,1])
subplot(4,1,3)
raster_experiment(tsB,'r')
title('Raster of ab2B neuron')
ylabel('trials')
% xlabel('sec')
axis tight
set(gca,'xtick',[])
set(gca,'xticklabel',[])
xlim(xlimm)
subplot(4,1,4)
plot(time(1:10:end),fA)
% title('Spike rate of ab2A neuron')
ylabel('Spike Rate ab2A (1/sec)')
xlabel('sec')
axis tight
xlim(xlimm)
% daspect([.4,1,1])
%% ab3 sensilla
% 
clc;
clear
load('2014_07_04_EA_nat_stim_2_CSF_1_ab2_1_3_all_11.mat')
xlimm = [29, 42];
figure('units','normalized','outerposition',[0 0 .4 .9]); 
subplot(11,1,[1 3])
semilogy(time,pid)
ylabel('PID (V)')
title('PID values of ab2 recordings')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
xlim(xlimm)
subplot(11,1,4)
raster_experiment(tsA)
title('Raster of ab2A neuron')
ylabel('trials')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
axis tight
xlim(xlimm)
% daspect([.4,1,1])
subplot(11,1,5)
raster_experiment(tsB,'r')
title('Raster of ab2B neuron')
ylabel('trials')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
% xlabel('sec')
axis tight
xlim(xlimm)
% daspect([.4,1,1])
subplot(11,1,[6 8])
plot(time(1:10:end),fA)
% title('Spike rate of ab3A neuron')
ylabel('Spike Rate ab2A (1/sec)')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
% xlabel('sec')
axis tight
xlim(xlimm)
% daspect([.4,1,1])
subplot(11,1,[9 11])
plot(time(1:10:end),fB)
% title('Spike rate of ab3B neuron')
ylabel('Spike Rate ab2B (1/sec)')
xlabel('sec')
axis tight
xlim(xlimm)
% tightfig;
% daspect([.4,1,1])

%% stimulus neuron statistics
% the stimulus tends to decrease from trial to tril but conserves the
% shape.
base_mean =  mean(mean(pid(:,1:45000),2));
ave_std = mean(std(pid(:,1:45000),0,2));

%%
% lets take a close look. Focus on a whiff and compare log-pid values and firing rates. look at individual trials first then average
figure('units','normalized','outerposition',[0 0 .7 .9]);
for i = 1:4
subplot(2,2,i); plot(time(1:10:end),fA(:,i)./max(fA(:,i)),'k',time,(log(data(2).PID(i,:))-mean(log(data(2).PID(i,1:45000))))./...
    max((log(data(2).PID(i,:))-mean(log(data(2).PID(i,1:45000))))),'r');
ylim([-.1,1.1])
xlim([31,36])
title(['trial: ' num2str(i)])
xlabel('sec')
if i ==1
    legend('ab2A','log-PID')
end
end
figure('units','normalized','outerposition',[0 0 .7 .9]);
plot(time(1:10:end),fA_ave./max(fA_ave),'k',time,(log(pid_ave)-mean(log(pid_ave(1:45000))))./max((log(pid_ave)-...
    mean(log(pid_ave(1:45000))))),'r');
ylabel('Normalized')
title('PID values & ab2A spike rates')
xlabel('sec')
legend('ab2A','log-PID')
xlim([31 36])
%% 
% pay attention to the whiffs around 32 and 32.5 seconds. Even though the third whiff is less than the first 
% two the response is higher. The width of the whiff seems to be important. The more the neuron is exposed to
% the odorant, the more it fires.

%%
% focus on another area
figure('units','normalized','outerposition',[0 0 .7 .9]);
plot(time(1:10:end),fA_ave./max(fA_ave),'k',time,(log(pid_ave)-mean(log(pid_ave(1:45000))))./max((log(pid_ave)-...
    mean(log(pid_ave(1:45000))))),'r');
ylabel('Normalized')
title('PID values & ab2A spike rates')
xlabel('sec')
legend('ab2A','log-PID')
xlim([27 31])
% Similarly the first whiff around 27.5 is longer than the second one
% although the amplitudes are similar, neuron responds more to the longer
% one. Similar phenomenon fro multi whiffs around 30 seconds. 

%% ab3 sensilla
% 
clc;
clear
load('2014_07_04_EA_nat_stim_2_CSF_1_ab3_2_1_all_11.mat')
xlimm = [41.5, 45];
figure('units','normalized','outerposition',[0 0 .4 .9]); 
subplot(11,1,[1 3])
semilogy(time,pid)
ylabel('PID (V)')
title('PID values of ab3 recordings')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
xlim(xlimm)
subplot(11,1,4)
raster_experiment(tsA)
title('Raster of ab3A neuron')
ylabel('trials')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
axis tight
xlim(xlimm)
% daspect([.4,1,1])
subplot(11,1,5)
raster_experiment(tsB,'r')
title('Raster of ab3B neuron')
ylabel('trials')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
% xlabel('sec')
axis tight
xlim(xlimm)
% daspect([.4,1,1])
subplot(11,1,[6 8])
plot(time(1:10:end),fA)
% title('Spike rate of ab3A neuron')
ylabel('Spike Rate ab3A (1/sec)')
set(gca,'xtick',[])
set(gca,'xticklabel',[])
% xlabel('sec')
axis tight
xlim(xlimm)
% daspect([.4,1,1])
subplot(11,1,[9 11])
plot(time(1:10:end),fB)
% title('Spike rate of ab3B neuron')
ylabel('Spike Rate ab3B (1/sec)')
xlabel('sec')
axis tight
xlim(xlimm)
% tightfig;
% daspect([.4,1,1])
%% stimulus neuron statistics
% the stimulus tends to decrease from trial to tril but conserves the
% shape.
base_mean =  mean(mean(pid(:,1:45000),2));
ave_std = mean(std(pid(:,1:45000),0,2));

%%
% lets take a close look. Focus on a whiff and compare log-pid values and firing rates. look at individual trials first then average
figure('units','normalized','outerposition',[0 0 .7 .9]);
for i = 1:4
subplot(2,2,i); plot(time(1:10:end),fA(:,i)./max(fA(:,i)),'k',time,(log(data(2).PID(i,:))-mean(log(data(2).PID(i,1:45000))))./...
    max((log(data(2).PID(i,:))-mean(log(data(2).PID(i,1:45000))))),'r');
ylim([-.1,1.1])
xlim([31,36])
title(['trial: ' num2str(i)])
xlabel('sec')
if i ==1
    legend('ab3A','log-PID')
end
end
figure('units','normalized','outerposition',[0 0 .7 .9]);
plot(time(1:10:end),fA_ave./max(fA_ave),'k',time,(log(pid_ave)-mean(log(pid_ave(1:45000))))./max((log(pid_ave)-...
    mean(log(pid_ave(1:45000))))),'r');
ylabel('Normalized')
title('PID values & ab2A spike rates')
xlabel('sec')
legend('ab3A','log-PID')
xlim([31 36])
%% 
% pay attention to the whiffs around 32 and 32.5 seconds. Even though the third whiff is less than the first 
% two the response is higher. The width of the whiff seems to be important. The more the neuron is exposed to
% the odorant, the more it fires.

%%
% focus on another area
figure('units','normalized','outerposition',[0 0 .7 .9]);
plot(time(1:10:end),fA_ave./max(fA_ave),'k',time,(log(pid_ave)-mean(log(pid_ave(1:45000))))./max((log(pid_ave)-...
    mean(log(pid_ave(1:45000))))),'r');
ylabel('Normalized')
title('PID values & ab3A spike rates')
xlabel('sec')
legend('ab3A','log-PID')
xlim([27 31])
% Similarly the first whiff around 27.5 is longer than the second one
% although the amplitudes are similar, neuron responds more to the longer
% one. Similar phenomenon fro multi whiffs around 30 seconds. 

%%
%average pid values and firing rates and plot together
clear;
clc;
ab2 = load('2014_07_04_EA_nat_stim_2_CSF_1_ab2_1_3_all_11.mat');
ab3 = load('2014_07_04_EA_nat_stim_2_CSF_1_ab3_2_1_all_11.mat');
figure('units','normalized','outerposition',[0 0 .7 .9]);
time = ab2.time;
f2a = ab2.fA_ave;
f3a = ab3.fA_ave;
pid2 = ab2.pid_ave;
pid3 = ab3.pid_ave;
plot(time(1:10:end),f2a./max(f2a),'k',time,(log(pid2)-mean(log(pid2(1:45000))))./max((log(pid2)-...
    mean(log(pid2(1:45000))))),'g--');
hold on
plot(time(1:10:end),f3a./max(f3a),'r',time,(log(pid3)-mean(log(pid3(1:45000))))./max((log(pid3)-...
    mean(log(pid3(1:45000))))),'b--');
hold off
ylabel('Normalized Mean')
title('PID values & Spike rates')
xlim([29 42])
xlabel('sec')
legend('ab2A','log-PID ab2A','ab3A','log-PID ab3A')
% now normalize first and than average
f2am = ab2.fA;
f3am = ab3.fA;
pid2m = ab2.pid;
pid3m = ab3.pid;
f2amn = zeros(size(f2am));
f3amn = zeros(size(f3am));
pid2mn = zeros(size(pid2m));
pid3mn = zeros(size(pid3m));
for i = 1:size(pid2m,1)
    f2amn(:,i) = f2am(:,i)./max(f2am(:,i));
    pid2mn(i,:)= (log(pid2m(i,:))-mean(log(pid2m(i,1:45000))))./max((log(pid2m(i,:))-...
    mean(log(pid2m(i,1:45000)))));
end
for i = 1:size(pid3m,1)
    f3amn(:,i) = f3am(:,i)./max(f3am(:,i));
    pid3mn(i,:)= (log(pid3m(i,:))-mean(log(pid3m(i,1:45000))))./max((log(pid3m(i,:))-...
    mean(log(pid3m(i,1:45000)))));
end
f2amn_ave = mean(f2amn,2);
f3amn_ave = mean(f3amn,2);
pid3mn_ave = mean(pid3mn,1);
pid2mn_ave = mean(pid2mn,1);
figure('units','normalized','outerposition',[0 0 .7 .9]);
plot(time(1:10:end),f2amn_ave,'k',time,pid2mn_ave,'g--');
hold on
plot(time(1:10:end),f3amn_ave,'r',time,pid3mn_ave,'b--');
hold off
ylabel('Mean Normalized')
title('PID values & Spike rates')
xlim([29 42])
xlabel('sec')
legend('ab2A','log-PID ab2A','ab3A','log-PID ab3A')

% plot individual curves
figure('units','normalized','outerposition',[0 0 .7 .9]);
for i = 1:6
subplot(3,2,i); 
plot(time(1:10:end),f2amn(:,i),'k',time,pid2mn(i,:),'g--');
hold on
plot(time(1:10:end),f3amn(:,i),'r',time,pid3mn(i,:),'b--');
hold off
ylim([-.1,1.1])
xlim([31,36])
title(['trial: ' num2str(i)])
xlabel('sec')
if i ==1
    legend('ab2A','log-PID ab2A','ab3A','log-PID ab3A')
end
end
%%
% look at autocorrelation fcuntions
acf_pid2 = autocorr(pid2,100000);
acf_pid3 = autocorr(pid3,100000);
acf_f3a = autocorr(f3a,10000);
acf_f2a = autocorr(f2a,10000);
semilogx(time(1:10:100001),[acf_f2a,acf_f3a],time(1:100001),[acf_pid2',acf_pid2'])
title('autocorrelation')
xlabel('sec')
ylabel('ACF')
legend('ab2','ab3','pid2','pid3')

%%
% histograms
[h_pid2, x_pid2] = hist(pid2(1:10:end),100);
[h_pid3, x_pid3] = hist(pid3(1:10:end),100);
[h_f2a, x_f2a] = hist(f2a,100);
[h_f3a, x_f3a] = hist(f3a,100);
loglog((x_pid2-min(x_pid2))/max((x_pid2-min(x_pid2))),h_pid2,(x_pid3-min(x_pid3))/max((x_pid3-min(x_pid3))),h_pid3,(x_f2a-min(x_f2a))/max((x_f2a-min(x_f2a))),h_f2a,(x_f3a-min(x_f3a))/max((x_f3a-min(x_f3a))),h_f3a)
title('histograms')
xlabel('normalized value')
ylabel('frequency')
legend('pid2','pid3','ab2','ab3')
