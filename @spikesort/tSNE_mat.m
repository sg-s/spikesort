% spikesort plugin
% plugin_type = 'dim-red';
% plugin_dimension = 2; 
% 
% created by Nirag Kadakia at 15:30 , 14 July 2017. 
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function tSNE_mat(s)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

s.R = tsne(s.V_snippets')';