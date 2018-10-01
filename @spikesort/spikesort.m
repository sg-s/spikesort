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
        version_name = 'spikesort';
        build_number = 'automatically-generated';
        pref % stores the preferences

        % file handling 
        file_name
        path_name

        % data handling
        output_channel_names
        sampling_rate

        % current voltage trace
        R  % this holds the dimensionality reduced data
        filtered_voltage  % holds the current trace that is shown on screen
        raw_voltage
        LFP
        V_snippets % matrix of snippets around spike peaks
        time % vector of timestamps
        loc  % holds current spike times

        % auxillary current data
        stimulus
        control_signals
        

        A % stores A spikes of this trace
        B % stores B spikes of this trace
        N % stores identified noise in this trace
        use_this_fragment
        A_amplitude
        B_amplitude


        this_trial
        this_paradigm

        % plugins
        installed_plugins

        % some control variables
        filter_trace = true;

        % UI
        handles % a structure that handles everything else

        % debug
        verbosity = 1;

        % auto-update
        req_update
        req_toolboxes

    end % end properties 

    methods (Access = protected)
        function displayScalarObject(s)
            disp('spikesort')
            s.build_number
        end % end displayScalarObject
    end % end protected methods


    methods
        function s = spikesort()

            % check for dependencies
            % toolboxes = {'srinivas.gs_mtools','spikesort','bhtsne'};
            % build_numbers = checkDeps(toolboxes);
            % s.version_name = strcat('spikesort for Kontroller (Build-',oval(build_numbers(2)),')'); 

            if verLessThan('matlab', '8.0.1')
                error('Need MATLAB 2014b or better to run')
            end

            % check the signal processing toolbox version
            if verLessThan('signal','6.22')
                error('Need Signal Processing toolbox version 6.22 or higher')
            end

            % add src folder to path
            addpath([fileparts(fileparts(which(mfilename))) filesep 'src'])


            % load preferences
            s.pref = readPref(fileparts(fileparts(which(mfilename))));

            % figure out what plugins are installed, and link them
            s = plugins(s);

            % get the version name and number
            s.build_number = ['v' strtrim(fileread([fileparts(fileparts(which(mfilename))) filesep 'build_number']))];
            s.version_name = ['spikesort (' s.build_number ')'];

            % make gui
            s.makeGUI;

            % configure somethings for auto-update
            s.req_toolboxes = {'srinivas.gs_mtools','bhtsne','spikesort'};
            [~,s.req_update] = checkDeps(s.req_toolboxes);

            if ~nargout
                cprintf('red','[WARN] ')
                cprintf('text','spikesort called without assigning to a object. spikesort will create an object called "s" in the workspace\n')
                assignin('base','s',s);
            end

        end

        function s = set.A(s,value)
            
            if any(isnan(s.filtered_voltage))
                set(s.handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
                return
            end
            s.A = value;
            if isempty(value)
                set(s.handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
                return
            else
                if s.filter_trace
                    set(s.handles.ax1_all_spikes,'XData',NaN,'YData',NaN);
                    set(s.handles.ax1_A_spikes,'XData',s.time(s.A),'YData',s.filtered_voltage(s.A));
                    set(s.handles.ax1_A_spikes,'Marker','o','Color',s.pref.A_spike_colour,'LineStyle','none')
                end
            end
        end % end set A

        function s = set.B(s,value)
            
            if any(isnan(s.filtered_voltage))
                set(s.handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
                return
            end
            s.B = value;
            if isempty(value)
                set(s.handles.ax1_B_spikes,'XData',NaN,'YData',NaN);
                return
            else
                if s.filter_trace
                    set(s.handles.ax1_all_spikes,'XData',NaN,'YData',NaN);
                    set(s.handles.ax1_B_spikes,'XData',s.time(s.B),'YData',s.filtered_voltage(s.B));
                    set(s.handles.ax1_B_spikes,'Marker','o','Color',s.pref.B_spike_colour,'LineStyle','none')
                
                end
                
            end
        end % end set B

        function s = set.loc(s,value)
            
            if any(isnan(s.filtered_voltage))
                set(s.handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
                return
            end
            s.loc = value;
            if isempty(value)
                set(s.handles.ax1_all_spikes,'XData',NaN,'YData',NaN);
                set(s.handles.ax1_A_spikes,'XData',NaN,'YData',NaN);
                set(s.handles.ax1_B_spikes,'XData',NaN,'YData',NaN);
                return
            else
                
                set(s.handles.ax1_all_spikes,'XData',s.time(s.loc),'YData',s.filtered_voltage(s.loc));
                set(s.handles.ax1_all_spikes,'Marker','o','Color',s.pref.putative_spike_colour,'LineStyle','none')

                % also update the YLim intelligently
                if s.filter_trace
                    set(s.handles.ax1,'YLim',[-1.1*max(abs(s.filtered_voltage(s.loc))) 1.1*max(abs(s.filtered_voltage(s.loc)))])
                else
                end
            end
        end % end set loc

        function s = set.raw_voltage(s,value)

            s.raw_voltage = value;

            if isempty(value)
                return
            else
                assert(isvector(value),'Raw voltage is not a vector')
            end

            s.plotResp;
        end

        function s = set.stimulus(s,value)
            s.stimulus = value;
            if isempty(value)
                return
            end

            s.plotStim;
        end

        function s = set.filter_trace(s,value)
            s.filter_trace = value;
            s.plotResp;
        end % end set filter_trace

        function s = set.this_paradigm(s,value)
            s.this_paradigm = value;
            if isempty(value)
                return
            end
            s.this_trial = 1;
            s.handles.trial_chooser.Value = 1;
            s.handles.paradigm_chooser.Value = s.this_paradigm;
        end

        function s = set.this_trial(s,value)
            s.this_trial = value;
            if isempty(value)
                return
            end
            s.readData;
        end

        function delete(s)
            if s.verbosity > 5
                cprintf('green','[INFO] ')
                cprintf('text','spikesort shutting down \n')
            end

            % save everything
            s.saveData;

            % try to shut down the GUI
            try
                delete(s.handles.main_fig)
            catch
            end

            % trigger an auto-update if needed
            for i = 1:length(s.req_toolboxes)
                if s.req_update(i) 
                    install('-f',['sg-s/' s.req_toolboxes{i}])
                end
            end

            delete(s)
        end

    end % end general methods

end % end classdef
