% spikesort.m
% Allows you to view, manipulate and sort spikes from experiments conducted by Kontroller. specifically meant to sort spikes from Drosophila ORNs
% spikesort was written by Srinivas Gorur-Shandilya at 10:20 , 09 April 2014. Contact me at http://srinivas.gs/contact/
% part of the spikesort package
% https://github.com/sg-s/spikesort
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

classdef spikesort < handle & matlab.mixin.CustomDisplay

    properties
        % meta
        version_name = 'automatically-generated';
        build_number = 'automatically-generated';
        pref % stores the preferences

        % file handling 
        file_name
        path_name

        % data handling
        current_data

        % core variables
        R  % this holds the dimensionality reduced data
        V  % holds the current trace that is shown on screen
        Vf  % filtered V
        V_snippets % matrix of snippets around spike peaks
        time % vector of timestamps
        loc  % holds current spike times

        this_trial
        this_paradigm
        

        % UI
        handles % a structure that handles everything else

        % debug
        verbosity = 10;

    end % end properties 

    methods (Access = protected)
        function displayScalarObject(s)
            disp('spikesort')
            s.build_number
        end % end displayScalarObject
    end % end protected methods


    methods
        function s = spikesort

            % check for dependencies
            toolboxes = {'srinivas.gs_mtools','spikesort','t-sne','bhtsne'};
            build_numbers = checkDeps(toolboxes);
            s.version_name = strcat('spikesort for Kontroller (Build-',oval(build_numbers(2)),')'); 

            % load preferences
            s.pref = readPref(fileparts(fileparts(which(mfilename))));

            

            % make gui
            s.makeGUI;

        end
    end % end general methods

end % end classdef
