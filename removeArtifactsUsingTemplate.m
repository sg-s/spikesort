% removeArtifactsUsingTemplate.m
% 
% created by Srinivas Gorur-Shandilya at 9:21 , 09 February 2016. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function [VC] = removeArtifactsUsingTemplate(V,this_control,pref)

VC = V;

% read the template file
load('template.mat','template')

% figure out the control signal
c = this_control(template.control_signal_channels,:);
assert(width(c) == 1, 'too many control signals specified. I expected only one control channel')
c = c(:);

% find ons and offs and build templates
on_transitions = find(diff(c)==1);
off_transitions = find(diff(c)==-1);

after = length(template.on_template) - 1;
if isempty(on_transitions)
else
    % trim some edge cases
    on_transitions(find(on_transitions+after>(length(V)-1))) = [];
    off_transitions(find(off_transitions+after>(length(V)-1))) = [];

	for ti = 1:length(on_transitions)
		if pref.use_on_template
    		VC(on_transitions(ti):on_transitions(ti)+after) = VC(on_transitions(ti):on_transitions(ti)+after) - template.on_template';
    	end
    	if pref.use_off_template
    		VC(off_transitions(ti):off_transitions(ti)+after) = VC(off_transitions(ti):off_transitions(ti)+after) - template.off_template';
    	end
	end
end


