clc,
data_temp = data;
ldata = length(data_temp(3).voltage(1,:));
    figure('units','normalized','outerposition',[0 0 .9 .9]);
    subplot(3,3,1)
    create_Spikes_figure((1:ldata)/SamplingRate,data_temp(2).voltage,'0V')
    subplot(3,3,2)
    create_Spikes_figure((1:ldata)/SamplingRate,data_temp(3).voltage,'1V')
        subplot(3,3,3)
    create_Spikes_figure((1:ldata)/SamplingRate,data_temp(4).voltage,'2V')
        subplot(3,3,4)
    create_Spikes_figure((1:ldata)/SamplingRate,data_temp(5).voltage,'3V')
        subplot(3,3,5)
    create_Spikes_figure((1:ldata)/SamplingRate,data_temp(6).voltage,'4V')
        subplot(3,3,6)
    create_Spikes_figure((1:ldata)/SamplingRate,data_temp(7).voltage,'5V')
        subplot(3,3,7)
    create_Spikes_figure((1:ldata)/SamplingRate,data_temp(8).voltage,'6V')
        subplot(3,3,8)
    create_Spikes_figure((1:ldata)/SamplingRate,data_temp(9).voltage,'7V')
        subplot(3,3,9)
    create_Spikes_figure((1:ldata)/SamplingRate,data_temp(10).voltage,'8V')
    
%     ave_volt = zeros(6,ldata);
%     for i = 2:7
%     ave_volt(i-1,:) = mean(data_temp(i).voltage,1);
%     end
%     figure('units','normalized','outerposition',[0 0 .9 .9]);
%     create_Spikes_figure((1:ldata)/SamplingRate,ave_volt,'1 Pentanol Dose')
%     
%     figure('units','normalized','outerposition',[0 0 .9 .9]);
%     plot((1:ldata)/SamplingRate,ave_volt)
%     title('CS 1-Pentanol Voltage Averages')
%     xlabel('time (sec)')
%     legend('0%','20%','40%','60%','80%','100%')
%     ylim([-.05 .02])
    
    
    figure('units','normalized','outerposition',[0 0 .9 .9]);
    subplot(2,3,1)
    create_Spikes_figure1((1:ldata)/SamplingRate,data_temp(2).PID,'0%',.15,[.15 1.5])
    subplot(2,3,2)
    create_Spikes_figure1((1:ldata)/SamplingRate,data_temp(3).PID,'20%',.15,[.15 1.5])
        subplot(2,3,3)
    create_Spikes_figure1((1:ldata)/SamplingRate,data_temp(4).PID,'40%',.15,[.15 1.5])
        subplot(2,3,4)
    create_Spikes_figure1((1:ldata)/SamplingRate,data_temp(5).PID,'60%',.15,[.15 1.5])
        subplot(2,3,5)
    create_Spikes_figure1((1:ldata)/SamplingRate,data_temp(6).PID,'80%',.15,[.15 1.5])
        subplot(2,3,6)
    create_Spikes_figure1((1:ldata)/SamplingRate,data_temp(7).PID,'100%',.15,[.15 1.5])

    
  % plot voltage and pid together
  percent_mat = [{'0%'} {'20%'} {'40%'} {'60%'} {'80%'} {'100%'}];
  
    figure('units','normalized','outerposition',[0 0 .9 .9]);
    for i = 1:size(ORN,1)
    subplot(4,4,2*i-1)
    create_Spikes_figure((1:ldata)/SamplingRate,data_temp(i+1).voltage,['dil-' num2str(i)])
    subplot(4,4,2*i)
    create_Spikes_figure1((1:ldata)/SamplingRate,data_temp(i+1).PID,'PID',.15,[0 6])
    end
  
  
  
  
  
%     figure('units','normalized','outerposition',[0 0 .9 .9]);
%     subplot(2,3,1)
%     create_Spikes_figure2((1:ldata)/SamplingRate,data_temp(2),'0%',.15,[.15 1.5])
%     subplot(2,3,2)
%     create_Spikes_figure2((1:ldata)/SamplingRate,data_temp(3),'20%',.15,[.15 1.5])
%         subplot(2,3,3)
%     create_Spikes_figure2((1:ldata)/SamplingRate,data_temp(4),'40%',.15,[.15 1.5])
%         subplot(2,3,4)
%     create_Spikes_figure2((1:ldata)/SamplingRate,data_temp(5),'60%',.15,[.15 1.5])
%         subplot(2,3,5)
%     create_Spikes_figure2((1:ldata)/SamplingRate,data_temp(6),'80%',.15,[.15 1.5])
%         subplot(2,3,6)
%     create_Spikes_figure2((1:ldata)/SamplingRate,data_temp(7),'100%',.15,[.15 1.5])