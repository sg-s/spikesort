% makeTestReport.m
% makes test report for spikesort on validated and manually inspected data
% 
% created by Srinivas Gorur-Shandilya at 10:54 , 04 September 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.


% this code determines if this function is being called by publish() or not
calling_func = dbstack;
being_published = 0;
if ~isempty(calling_func)
	if find(strcmp('publish',{calling_func.name}))
		being_published = 1;
	end
end
tic

%% Tests and Performance Metrics
% In this document, we test how good spikesort is, and measure the error rate on some carefully annotated data. 

%% Test Data 1
% In this data, A and B neurons have very similar amplitudes, and the recording was performed in LFP mode (no low pass filter). Thus, spikes were detected in the positive peaks. This is what the actual data looks like:

load('/local-data/spikesort-validation/1/manually_inspected.mat')
t = 1e-4*(1:length(data(3).voltage));
V = filter_trace(data(3).voltage(1,:),100,10);
A = logical(spikes(3).A(1,:));
B = logical(spikes(3).B(1,:));

figure('outerposition',[0 0 1000 500],'PaperUnits','points','PaperSize',[1000 500]); hold on
plot(t,V,'k')
plot(t(A),V(A),'or')
plot(t(B),V(B),'ob')
set(gca,'XLim',[20 30])
xlabel('Time (s)')
ylabel('\DeltaV (10xmV)')
PrettyFig()

if being_published
	snapnow
	delete(gcf)
end

%%
% The large B spikes are coincident A and B spikes, and are counted as such. 

load('/local-data/spikesort-validation/1/best_pca.mat')
A_pca = logical(spikes(3).A(1,:));
B_pca = logical(spikes(3).B(1,:));

load('/local-data/spikesort-validation/1/best_tsne.mat')
A_tsne = logical(spikes(3).A(1,:));
B_tsne = logical(spikes(3).B(1,:));

%% Comparison of PCA and t-SNE
% In the following figure, we plot rasters of the manually inspected data, and compare it to the best PCA solution and the best t-SNE solution:

figure('outerposition',[0 0 1000 500],'PaperUnits','points','PaperSize',[1000 500]); hold on
raster2([A; A_pca; A_tsne])
set(gca,'YTick',[0.5 1.5 2.5],'YTickLabel',{'t-SNE','PCA','Reality'})
set(gca,'XLim',[35 40])
xlabel('Time (s)')
PrettyFig()

if being_published
	snapnow
	delete(gcf)
end

%%
% In this view, the best PCA solution has a few extra A spikes that should not be there.

%%
% In the next figure, we compare how PCA and t-SNE achieve dimensionality reduction on the same data. As can be seen, the clusters overlap significantly in PCA, while the clusters are well separated in t-SNE. The three main clusters correspond to noise, the B-neuron and the A-neuron. Smaller clusters correspond to simultaneous or otherwise co-mingled spikes. 
%
% <<dim-red.png>>
% 

%% Quantification of Errors: A spike
% We now quantify the errors made by each method on this dataset. 

correct_window = 2; 

A_loc = find(A);
test_loc = find(A_pca);
c = 0;
for i = 1:length(A_loc)
	this_spike = A_loc(i);
	% look for spikes
	if min(abs(test_loc - this_spike)) < correct_window
		[~,target]= min(abs(test_loc - this_spike));
		c = c+1;
		test_loc(target) = [];
	else
	end
end

%%
% The fraction of A spikes correctly identified by the PCA algorithm is:

disp(oval(c/length(A_loc)*100,3))

test_loc = find(A_tsne);
c = 0;
for i = 1:length(A_loc)
	this_spike = A_loc(i);
	% look for spikes
	if min(abs(test_loc - this_spike)) < correct_window
		[~,target]= min(abs(test_loc - this_spike));
		c = c+1;
		test_loc(target) = [];
	else
	end
end
%%
% The fraction of A spikes correctly identified by the t-SNE algorithm is:

disp(oval(c/length(A_loc)*100,3))



A_loc = find(A_pca);
test_loc = find(A);
c = 0;
for i = 1:length(A_loc)
	this_spike = A_loc(i);
	% look for spikes
	if min(abs(test_loc - this_spike)) < correct_window
		[~,target]= min(abs(test_loc - this_spike));
		c = c+1;
		test_loc(target) = [];
	else
	end
end
%%
% The fraction of A spikes reported by PCA that actually match to a A spikes is:
disp(oval(c/length(A_loc)*100,3))

A_loc = find(A_tsne);
test_loc = find(A);
c = 0;
for i = 1:length(A_loc)
	this_spike = A_loc(i);
	% look for spikes
	if min(abs(test_loc - this_spike)) < correct_window
		[~,target]= min(abs(test_loc - this_spike));
		c = c+1;
		test_loc(target) = [];
	else
	end
end
%%
% The fraction of A spikes reported by t-SNE that actually match to a A spikes is:
disp(oval(c/length(A_loc)*100,3))


%% Quantification of Errors: B spike
% We now quantify the errors made by each method on this dataset. 

correct_window = 2; 

B_loc = find(B);
test_loc = find(B_pca);
c = 0;
for i = 1:length(B_loc)
	this_spike = B_loc(i);
	% look for spikes
	if min(abs(test_loc - this_spike)) < correct_window
		[~,target]= min(abs(test_loc - this_spike));
		c = c+1;
		test_loc(target) = [];
	else
	end
end

%%
% The fraction of B spikes correctly identified by the PCA algorithm is:

disp(oval(c/length(B_loc)*100,3))

test_loc = find(B_tsne);
c = 0;
for i = 1:length(B_loc)
	this_spike = B_loc(i);
	% look for spikes
	if min(abs(test_loc - this_spike)) < correct_window
		[~,target]= min(abs(test_loc - this_spike));
		c = c+1;
		test_loc(target) = [];
	else
	end
end
%%
% The fraction of A spikes correctly identified by the t-SNE algorithm is:

disp(oval(c/length(B_loc)*100,3))



B_loc = find(B_pca);
test_loc = find(B);
c = 0;
for i = 1:length(B_loc)
	this_spike = B_loc(i);
	% look for spikes
	if min(abs(test_loc - this_spike)) < correct_window
		[~,target]= min(abs(test_loc - this_spike));
		c = c+1;
		test_loc(target) = [];
	else
	end
end
%%
% The fraction of B spikes reported by PCA that actually match to a B spikes is:
disp(oval(c/length(B_loc)*100,3))

B_loc = find(B_tsne);
test_loc = find(B);
c = 0;
for i = 1:length(B_loc)
	this_spike = B_loc(i);
	% look for spikes
	if min(abs(test_loc - this_spike)) < correct_window
		[~,target]= min(abs(test_loc - this_spike));
		c = c+1;
		test_loc(target) = [];
	else
	end
end
%%
% The fraction of B spikes reported by t-SNE that actually match to a B spikes is:
disp(oval(c/length(B_loc)*100,3))


%% Version Info
% The file that generated this document is called:
disp(mfilename)

%%
% and its md5 hash is:
Opt.Input = 'file';
disp(DataHash(strcat(mfilename,'.m'),Opt))

%%
% This file should be in this commit:
[status,m]=unix('git rev-parse HEAD');
if ~status
	disp(m)
end

t = toc;

%% 
% This document was built in: 
disp(strcat(oval(t,3),' seconds.'))

% tag the file as being published 
% add homebrew path
path1 = getenv('PATH');
path1 = [path1 ':/usr/local/bin'];
setenv('PATH', path1);

if being_published
	unix(strjoin({'tag -a published',which(mfilename)}));
end
