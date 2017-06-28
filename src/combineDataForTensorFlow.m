function [] = combineDataForTensorFlow()

% find all X_ and Y_ files in current folder 

allfiles = dir('X_*.mat');
load(allfiles(1).name)
all_X = X;
for i = 2:length(allfiles)
	load(allfiles(i).name)
	all_X = [all_X X];
end

allfiles = dir('Y_*.mat');
load(allfiles(1).name)
all_Y = Y;
for i = 2:length(allfiles)
	load(allfiles(i).name)
	all_Y = [all_Y Y];
end

X = all_X;
Y = all_Y;

% shuffle these arrays 
idx = randperm(size(X,2));
X = X(:,idx);
Y = Y(:,idx);

% PCA it
X = pca(X)';

% take only the first ten dimensions
X = X(1:12,:);


savefast('~/X.mat','X')
savefast('~/Y.mat','Y')