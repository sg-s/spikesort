% preferences file for spikesort
% spikesort has many preferences, and, instead of wasting time building more and more UI to handle them, all preferences are in this text file (like in Sublime Text)
% this is meant to be read by readPref
% 
% created by Srinivas Gorur-Shandilya at 4:52 , 16 September 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.


% general preferences
ssDebug = true; % should spikesort run in debug mode?

% display preferences
marker_size = 5; % how big the spike indicators are
deltat = 1e-4;
fs = 14; 			% UI font size
fw = 'bold'; 		% UI font weight
plot_control = false; % should spikesort plot the control signals?

% UI
smart_scroll = true; 				% intelligently scroll so we keep # visible spikes constant 

% spike detection
minimum_peak_prominence = 'auto'; 	% minimum peak prominence for peak detection. you can also specify a scalar value
minimim_peak_width = 1;
minimim_peak_distance = 1; 			% how separated should the peaks be?
V_cutoff = -1; 						% ignore peaks beyond this limit 
invert_V = false; 					% sometimes, it is easier to find spikes if you invert V
band_pass = [100 1000]; 			% in Hz. band pass V to find spikes more easily 

% doublets
remove_doublets = true;				% resolve doublet peaks, which are very likely AB or BA, not AA or BB
doublet_distance = 90; 				% how far out should you look for doublets? 

% artifact removal 
template_match_artifacts = false;  	% use templates to kill artifacts? 
template_width = 50;
template_amount = 2; 

