% time = (1:700000)/10000;
% spktimeA = squeeze(tSPKA);
% spktimeB = squeeze(tSPKB);
% fA = spiketimes2f(spktimeA,time);
% fB = spiketimes2f(spktimeB,time);
% pid_ave = mean(data(2).PID,1);
% fA_ave = mean(fA,2);
% fB_ave = mean(fB,2);
figure;
[c, r] = getrc_subplot(size(fA,2));
for i = 1:size(fA,2)
subplot(c,r,i); plot(time(1:10:end),fA(:,i)./max(fA(:,i)),time,(log(data(2).PID(i,:))-mean(log(data(2).PID(i,1:45000))))./max((log(data(2).PID(i,:))-mean(log(data(2).PID(i,1:45000))))));
ylim([-.1,1.1])
xlim([31,38])
title(['trial: ' num2str(i)])
xlabel('sec')
end
 figure; plot(time(1:10:end),fA_ave./max(fA_ave),time,(log(pid_ave)-mean(log(pid_ave(1:45000))))./max((log(pid_ave)-mean(log(pid_ave(1:45000))))));

if 1% for B neuron
    figure;
    [c, r] = getrc_subplot(size(fB,2));
    for i = 1:size(fB,2)
    subplot(c,r,i); plot(time(1:10:end),fB(:,i)./max(fA(:,i)),time,(log(data(2).PID(i,:))-mean(log(data(2).PID(i,1:45000))))./max((log(data(2).PID(i,:))-mean(log(data(2).PID(i,1:45000))))));
    ylim([-.1,1.1])
    xlim([31,38])
    title(['trial: ' num2str(i)])
    xlabel('sec')
    end
    figure; plot(time(1:10:end),fB_ave./max(fB_ave),time,(log(pid_ave)-mean(log(pid_ave(1:45000))))./max((log(pid_ave)-mean(log(pid_ave(1:45000))))));
end
figure;
time = ab3.time;
plot(time(1:10:end),ab2.fB_ave./max(ab2.fB_ave),'b',time,(log(ab2.pid_ave)-mean(log(ab2.pid_ave(1:45000))))./max((log(ab2.pid_ave)-mean(log(ab2.pid_ave(1:45000))))),'g');
plot(time(1:10:end),ab3.fB_ave./max(ab3.fB_ave),'k',time,(log(ab3.pid_ave)-mean(log(ab3.pid_ave(1:45000))))./max((log(ab3.pid_ave)-mean(log(ab3.pid_ave(1:45000))))),'k');