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
        OutputChannelNames

        % core variables for current trace
        R  % this holds the dimensionality reduced data
        filtered_voltage  % holds the current trace that is shown on screen
        raw_voltage
        LFP
        V_snippets % matrix of snippets around spike peaks
        time % vector of timestamps
        loc  % holds current spike times
        use_this_fragment

        A % stores A spikes of this trace
        B % stores B spikes of this trace
        N % stores identified noise in this trace

        this_trial
        this_paradigm

        % plugins
        installed_plugins



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

            % figure out what plugins are installed, and link them
            s = plugins(s);

            % make gui
            s.makeGUI;

            if ~nargout
                cprintf('red','[WARN] ')
                cprintf('text','spikesort called without assigning to a object. spikesort will create an object called "s" in the workspace\n')
                assignin('base','s',s);
            end

        end

        function s = set.A(s,value)
            if isempty(value)
                return
            else
                s.A = value;
                set(s.handles.ax1_all_spikes,'XData',NaN,'YData',NaN);
                set(s.handles.ax1_A_spikes,'XData',s.time(s.A),'YData',s.filtered_voltage(s.A));
                set(s.handles.ax1_A_spikes,'Marker','o','Color',s.pref.A_spike_colour,'LineStyle','none')
                s.saveData;
            end
        end % end set A

        function s = set.B(s,value)
            if isempty(value)
                return
            else
                s.B = value;
                set(s.handles.ax1_all_spikes,'XData',NaN,'YData',NaN);
                set(s.handles.ax1_B_spikes,'XData',s.time(s.B),'YData',s.filtered_voltage(s.B));
                set(s.handles.ax1_B_spikes,'Marker','o','Color',s.pref.B_spike_colour,'LineStyle','none')
                s.saveData;
            end
        end % end set B

        function s = set.loc(s,value)
            if isempty(value)
                return
            else
                s.loc = value;
                set(s.handles.ax1_all_spikes,'XData',s.time(s.loc),'YData',s.filtered_voltage(s.loc));
                set(s.handles.ax1_all_spikes,'Marker','o','Color',s.pref.putative_spike_colour,'LineStyle','none')
            end
        end % end set loc
    end % end general methods

end % end classdef
