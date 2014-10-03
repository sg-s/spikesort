

figure;
plot(Exp_516_12.pid_maxA(1:5,:),Exp_516_12.sr_maxA(1:5,:),'k*',Exp_516_12.pid_maxA(6,:),Exp_516_12.sr_maxA(6,:),'r*')
xlabel('pid amp (V)')
ylabel('max spk rate (Hz)')

hold on
plot(Exp_59_13.pid_maxA(1:5,:),Exp_59_13.sr_maxA(1:5,:),'b*',Exp_59_13.pid_maxA(6,:),Exp_59_13.sr_maxA(6,:),'g*')

figure;
errorbarxy(Exp_59_13.pid_maxA(6,:), Exp_59_13.sr_maxA(6,:),Exp_59_13.pid_maxA(7,:), Exp_59_13.sr_maxA(7,:),{'ko-', 'k', 'k'})
hold on
errorbarxy(Exp_59_12.pid_maxA(6,:), Exp_59_12.sr_maxA(6,:),Exp_59_12.pid_maxA(7,:), Exp_59_12.sr_maxA(7,:),{'r*-', 'r', 'r'})
hold on
errorbarxy(Exp_516_21.pid_max(6,:), Exp_516_21.sr_max(6,:),Exp_516_21.pid_max(7,:), Exp_516_21.sr_max(7,:),{'bo-', 'b', 'b'})
hold on
errorbarxy(Exp_516_12.pid_max(6,:), Exp_516_12.sr_max(6,:),Exp_516_12.pid_max(7,:), Exp_516_12.sr_max(7,:),{'g*-', 'g', 'g'})
xlabel('pid amp (V)')
ylabel('max spk rate (Hz)')
legend('ab3a-1','ab3a-1','ab3a-2','ab3a-3')