function raster_experiment(spiketime,color)
% generates the raster from the spike time file spiketime. spike time is a
% 3-d matrix whose fisrt dimension is number of experiments, sconds
% dimension is number of trials and third dimension is the spike times. the
% sampling rate is assumed to be 10000 Hz

switch nargin
    case 1
        color = 'k';
    case 0
        disp('spiketimes?')
        help raster_experiment
end
        hold on;
        n_exp = size(spiketime,1);
        n_trial = size(spiketime,2);
        nn=1;
            
        for i = 1:n_exp
            for t = 1:n_trial
                timesp = squeeze(spiketime(i,t,:));
                timesp(timesp==0)=[];
                timesp=[timesp';timesp'];
                linemat = ones(size(timesp));
                linemat(1,:) = nn+.5;
                linemat(2,:) = nn-.5;
                line(timesp/10000,linemat,'lineWidth' ,2,'Color',color)
                nn=nn+1;

            end
            nn=nn+3;
        end
        ylim([0 nn-2])
        hold off
