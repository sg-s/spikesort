% testDBN
% tests a deep belief network to see if we can use this to sort spikes
% first, we start with a file with sorted spikes
% then, we train the DBN with data from spike snippets and the stimulus
% and then test it on a different trial to see how well it does 
% compared to human annotation
% 
% created by Srinivas Gorur-Shandilya at 11:11 , 19 August 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

this_paradigm = 3;

% load the data
load('/local-data/obp/2015_08_18_crispr_F1_ab3_1_EA.mat')

% filter all relevant data
for i = 1:width(data(this_paradigm).voltage)
	data(this_paradigm).voltage(i,:) = filter_trace(data(this_paradigm).voltage(i,:),100,10);
end

% make sure all data is between [0 1]
for i = 1:width(data(this_paradigm).voltage)
	data(this_paradigm).voltage(i,:) = data(this_paradigm).voltage(i,:) - min(data(this_paradigm).voltage(i,:));
	data(this_paradigm).voltage(i,:) = data(this_paradigm).voltage(i,:)/max(data(this_paradigm).voltage(i,:));
	data(this_paradigm).PID(i,:) = data(this_paradigm).PID(i,:) - min(data(this_paradigm).PID(i,:));
	data(this_paradigm).PID(i,:) = data(this_paradigm).PID(i,:)/max(data(this_paradigm).PID(i,:));
	
end

% pull out spike snippets and stimulus snippets
before = 30;
after = 29;


% make the training data
A_spikes = find(spikes(this_paradigm).A(1,:));
B_spikes = find(spikes(this_paradigm).B(1,:));

train_x = zeros(length([A_spikes B_spikes]),120);
train_y = zeros(length([A_spikes B_spikes]),2);


for i = 1:length(A_spikes)
	this_loc = A_spikes(i);
	train_x(i,1:60) = data(this_paradigm).voltage(1,this_loc-before:this_loc+after);
	train_x(i,61:120) = data(this_paradigm).PID(1,this_loc-before:this_loc+after);
	train_y(i,1) = 1;
end

for i = length(A_spikes)+1:length(B_spikes)+length(A_spikes)
	this_loc = B_spikes(i-length(A_spikes));
	train_x(i,1:60) = data(this_paradigm).voltage(1,this_loc-before:this_loc+after);
	train_x(i,61:120) = data(this_paradigm).PID(1,this_loc-before:this_loc+after);
	train_y(i,2) = 1;
end

% make training data double
train_y = double(train_y);
train_x = double(train_x);


% make the test data
A_spikes = find(spikes(this_paradigm).A(2,:));
B_spikes = find(spikes(this_paradigm).B(2,:));

test_x = zeros(length([A_spikes B_spikes]),120);
test_y = zeros(length([A_spikes B_spikes]),2);

for i = 1:length(A_spikes)
	this_loc = A_spikes(i);
	test_x(i,1:60) = data(this_paradigm).voltage(2,this_loc-before:this_loc+after);
	test_x(i,61:120) = 0*data(this_paradigm).PID(2,this_loc-before:this_loc+after);
	test_y(i,1) = 1;
end

for i = length(A_spikes)+1:length(B_spikes)+length(A_spikes)
	this_loc = B_spikes(i-length(A_spikes));
	test_x(i,1:60) = data(this_paradigm).voltage(2,this_loc-before:this_loc+after);
	test_x(i,61:120) = 0*data(this_paradigm).PID(2,this_loc-before:this_loc+after);
	test_y(i,2) = 1;
end

% make test data double
test_y = double(test_y);
test_x = double(test_x);


rand('state',0)
%train dbn
dbn.sizes = [6 6];
opts.numepochs =   1;
opts.batchsize = length(train_x)/2;;
opts.momentum  =   0;
opts.alpha     =   1;
dbn = dbnsetup(dbn, train_x, opts);
dbn = dbntrain(dbn, train_x, opts);

%unfold dbn to nn
nn = dbnunfoldtonn(dbn, 2);
nn.activation_function = 'sigm';

%train nn
opts.numepochs =  1e3;
opts.momentum = 1;
opts.batchsize = length(train_x)/2;
nn = nntrain(nn, train_x, train_y, opts);

% test and check error
% [er, bad] = nntest(nn, test_x, test_y);

% also get the predictions back
l = nnpredict(nn,test_x);
plot(l,'x')
