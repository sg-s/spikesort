% makeMLUI.m
% makes the UI for machine learning
% created by Srinivas Gorur-Shandilya at 6:01 , 19 August 2015. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.

function ml_ui = makeMLUI()


ml_ui.fig = figure('Position',[60 500 450 450],'Toolbar','none','Menubar','none','Name','Deep Learning','NumberTitle','off','Resize','on','HandleVisibility','on');

ml_ui.loadButton = uicontrol(ml_ui.fig,'units','normalized','Position',[.05 .75 .5 .10],'Style', 'pushbutton', 'String', 'Load DBN','FontSize',20,'Callback',@loadDBN);
uicontrol(ml_ui.fig,'units','normalized','Position',[.05 .60 .35 .10],'Style', 'text', 'String', 'Use this:','FontSize',20);
ml_ui.sort_control = uicontrol(ml_ui.fig,'units','normalized','Position',[.05 .50 .90 .10],'Style', 'pushbutton', 'String', 'Deep Sort','FontSize',20,'Callback',@deepSort,'Enable','off');
ml_ui.chooseDBN = findAllDBNs;
