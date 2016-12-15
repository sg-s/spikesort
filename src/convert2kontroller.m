% temporary script that converts .mat files created by kontroller to true kontroller format
allfiles = dir('*.mat');

% remove hidden files
rm_this = false(length(allfiles));
for i = 1:length(allfiles)
	if strcmp(allfiles(i).name(1:2),'._')
		rm_this(i) = true;
	end
end
allfiles(rm_this) = [];

for i = 1:length(allfiles)
	convertMATFileTo73(allfiles(i).name)
	movefile(allfiles(i).name,[allfiles(i).name(1:end-3) 'kontroller'])
end

