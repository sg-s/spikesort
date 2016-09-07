%% buildValveTemplate.m

on_template_size = 100;
off_template_size = 100;
valve_channel = 2;

% get all .mat files
allfiles = dir('*.mat');
rm_this = false(length(allfiles),1);
for i = 1:length(allfiles)
	if any(strfind(allfiles(i).name,'cached'))
		rm_this(i) = true;
	end
end
allfiles(rm_this) = [];
disp('Located these files:')
disp({allfiles.name}')


% for each file....
for i = 1:length(allfiles)

	% load it
	load(allfiles(i).name)


	on_template = zeros(1,on_template_size);
	off_template = zeros(1,off_template_size);
	c = 1;


	for j = 1:length(data)
		valve_signal = ControlParadigm(j).Outputs(valve_channel,:);
		[ons,offs] = computeOnsOffs(valve_signal);
		n_trials = size(data(j).voltage,1);
		for k = 1:n_trials
			for l = 1:length(ons)
				on_template = on_template + data(j).voltage(k,ons(l):ons(l)-1+on_template_size);
				off_template = off_template + data(j).voltage(k,offs(l):offs(l)-1+off_template_size);
				c = c + 1;
			end
		end
	end

end



% 