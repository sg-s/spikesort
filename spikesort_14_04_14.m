function [] = spikesort_14_04_08()
versionname = 'Spike Sorting Build 9.14';
disp(versionname)
% Carlotta's spike sorting and processing GUI
% Change log:
% b4.26.a: Filter now finds as well, automatically switches modes
% (neuron/Noise) [no longer the case]
% b4.27.a : Added a "Blank Noise" button, that removes noise
% b4.27.a : partly fixed a bug where dots were on zero and on spikes. [fixed in 4.28.b]
% b4.27.b : added a display which displays the stimulus when on
% b4.28.b : fixed bug where a line was drawn on the x-axis indicating spike
% times.
% b4.28.c : added an option for manual sorting, where you draw borders
% around the PCA clusters [incomplete]
% b4.28.c : added a button to remove all valve artifacts
% b4.29.a : 
% 1: improved the "supress noise" button, now works rather well and removes
% nearly all of the noise
% 2. Added an option to sort by amplitude, but it is incomplete, and I
% would not use it
% 3. Spike Shapes now reset to 0 before PCA. 
% 4. finished the manual sorting option, I think it works rather
% well now. 
% 5. minor cosmetic changes, placement of buttons, etc.
% 6. Added an "autofix" button in the manual clustering window
% b5.5.a : numerous bug fixes, and the following new features:
% 1. attempts to automatically load spike file if it can find it
% 2. support for .pref files to allow a common build with hidden features
% 3. autosort disabled till it has what it needs
% b5.11.a
% I keep pressing the wrong button like "find" and lose everything I did.
% So buttons are disabled when they should not be pressed. 
% b5.27.a:
% bugfixes: fixed a bug where clicking the "done" button or the "next
% experiment" button caused an error when using manual (level) sorting.
% this was because a) I had forced the next experiment button to call
% donecallback and b) because tlim was reinialised, and clicking done twice
% would anyway cause an error. There is now a hack which works around this,
% and it should all be OK now. 
%% initialise variables, make the master window
Aamp = [];
svalve = [];
Bamp = [];
Ashape = [];
Bshape = [];
Ax = [];
Bx = [];
currdata = [1 1];
deltat = 0.0001;
stimon = 1;
filein_name = [];
fileout_name = [];
file_path=[];
mode = 0;
numtrials = [];
numexp = [];
px_spk = 1;
px_v = 1;
refractory = 0.0025;
tr = round(refractory/deltat);
tracedone = [];
time = [];
tlim = 1;
tSPKA = [];
tSPKB = [];
xlimit = [0 11];
ylimit = [];
L = [];
startcount = 0.5;
SPKcountA = [];
SPKcountB = [];
SPKcurr = [];
SPKAcurr = [];
SPKBcurr = [];
SPKtemp = [];
SPKAtemp = [];
SPKBtemp = [];
Tnoise= -0.001;   
THnoise = [];
THA = [];
Vcurr = [];
V = []; % voltage matrix
pid = [];
pidcurr = [];
hm1 = [];
hm2 = [];
hm2=  [];
hm3 = [];
hm4 = [];
hm5 = [];
PC= [];
IS= [];
S= [];
cp = [];
hmc = []; % manual sort window handle
editon = [];
autofixbutton = [];
% make the master figure, and the axes to plot the voltage traces
fig = figure('position',[50 50 1200 700],'WindowButtonDownFcn',@mousecallback, 'WindowKeyPressFcn',@keycallback, 'WindowScrollWheelFcn',@scrollcallback, 'Toolbar','none','Menubar','none','Name',versionname,'NumberTitle','off','IntegerHandle','off');
ax = axes('parent',fig,'position',[0.05 0.05 0.9 0.29]);
ax2 = axes('parent',fig,'position',[0.05 0.37 0.9 0.18]);
% set(ax2,'xticklabel',{[]});
ind = [];
%% preferences support. 
% set up defaults
prefs.loadSPK = 0;
prefs.Magic = 0;
% search for preferecnes support
try load('/0dump/fly-data-analysis/prefs.mat');
    disp('Loading preferences...')
catch ME1
    % go with defaults
end
%% viewpanel (the drag and zoom buttons)
viewpanel = uipanel('Title', 'View','units','pixels','pos',[800 390 180 110]);
cur = uicontrol(viewpanel,'Position',[10 10 80 30],'String','cursor','FontSize',12,'Callback',@cursorcallback);
zin = uicontrol(viewpanel,'Position',[10 40 80 30],'String','zoom x','FontSize',12,'Callback',@zoomincallback);
zy = uicontrol(viewpanel,'Position',[90 40 80 30],'String','zoom y','FontSize',12,'Callback',@zoomycallback);
panon = uicontrol(viewpanel,'Position',[10 70 80 30],'String','drag x','FontSize',12,'Callback',@pancallback);
pany = uicontrol(viewpanel,'Position',[90 70 80 30],'String','drag y','FontSize',12,'Callback',@panycallback);

%% parameters (a subpanel to enter parameters like refractory time, deltat)
parameterpanel = uipanel('Title', 'Parameters','units','pixels','pos',[340 600 160 100]);
textdeltat = uicontrol(parameterpanel,'Position',[5 55 55 30],'Style', 'text', 'String', 'deltat = ','FontSize',11,'FontWeight','bold');
getdeltat = uicontrol(parameterpanel,'Position',[80 55 55 30],'Style', 'Edit', 'String',num2str(deltat),'FontSize',11,'Callback',@getdeltatcallback);
textstimon = uicontrol(parameterpanel,'Position',[5 30 65 30],'Style', 'text', 'String', 'stim on = ','FontSize',11,'FontWeight','bold');
getstimon = uicontrol(parameterpanel,'Position',[80 30 55 30],'Style', 'Edit', 'String','1','FontSize',11);
textrefractory = uicontrol(parameterpanel,'Position',[5 5 50 30],'Style', 'text', 'String', 'refr = ','FontSize',11,'FontWeight','bold');
getrefractory = uicontrol(parameterpanel,'Position',[80 5 60 30],'Style', 'Edit', 'String',num2str(refractory),'FontSize',11,'Callback',@getdeltatcallback);

%% file IO
% as explained, this is the file IO module. makes the panel to import data.
% Here we disable the Excel file handles
IOpanel = uipanel('units','pixels','pos',[10 420 320 270]);
selectformat = uicontrol(IOpanel,'Position',[7 215 100 20],'Style', 'popupmenu', 'String', {'matlab', 'axoscope', 'autospike'},'FontSize',11, 'value', 1);
selectformattex = uicontrol(IOpanel,'Position',[5 235 100 20],'Style', 'text', 'String', 'select format','FontSize',12, 'FontWeight','bold');
loadfile = uicontrol(IOpanel,'Position',[5 175 100 30],'String','load data','FontSize',12,'Callback',@loadfilecallback);
showloadfile = uicontrol(IOpanel,'Position',[110 175 200 30],'Style', 'text', 'String', filein_name,'FontSize',11); % no callback needed here
loadspk = uicontrol(IOpanel,'Position',[5 140 100 30],'String','load spk','FontSize',12,'Callback',@loadspkcallback);
showloadspkfile = uicontrol(IOpanel,'Position',[110 140 200 30],'Style', 'text', 'String', filein_name,'FontSize',11); % no callback needed here
savefile = uicontrol(IOpanel,'Position',[5 105 100 30], 'String','save data','FontSize',12,'Callback',@savefilecallback);
getfilenameout = uicontrol(IOpanel,'Position',[110 105 200 30],'Style', 'Edit');
% savexls = uicontrol(IOpanel,'Position',[5 35 100 30], 'String','save xls','FontSize',12,'Callback',@savexlscallback);
% getxlsnameout = uicontrol(IOpanel,'Position',[110 35 200 30],'Style', 'Edit');
% savecountxls = uicontrol(IOpanel,'Position',[5 70 100 30], 'String','save count xls','FontSize',12,'Callback',@savecountxlscallback);
% getcountxlsnameout = uicontrol(IOpanel,'Position',[110 70 200 30],'Style', 'Edit');
% OSmode = uibuttongroup(IOpanel, 'units','pixels','Position',[110 10 200 50],'BorderType','none');
% winmode = uicontrol(OSmode,'Position',[5 5 90 20], 'Style', 'radiobutton', 'String', 'windows','FontSize',12);
% macmode = uicontrol(OSmode,'Position',[100 5 60 20], 'Style', 'radiobutton', 'String', 'mac','FontSize',12);

%% current trace
% this has controls for navigating through the data (trials, experiments
% (dosages))
currtracepanel = uipanel('Title', 'Current Trace','units','pixels','pos',[1000 390 130 120]);
textexp = uicontrol(currtracepanel,'Position',[10 80 110 20],'Style', 'text', 'String', 'num exp:','FontSize',12,'FontWeight','bold');
nextexp = uicontrol(currtracepanel,'Position',[80 50 30 30],'String','>>','FontSize',12,'Callback',@nextexpcallback);
prevexp = uicontrol(currtracepanel,'Position',[50 50 30 30],'String','<<','FontSize',12,'Callback',@prevexpcallback);
setcurrexp = uicontrol(currtracepanel,'Position',[20 50 30 30],'Style', 'Edit', 'String', num2str(currdata(1)),'FontSize',12,'Callback',@setcurrexpcallback);
texttrial = uicontrol(currtracepanel,'Position',[10 30 110 20],'Style', 'text', 'String', 'num trials: ','FontSize',12,'FontWeight','bold');
nexttrial = uicontrol(currtracepanel,'Position',[80 0 30 30],'String','>>','FontSize',12,'Callback',@nexttrialcallback);
prevtrial = uicontrol(currtracepanel,'Position',[50 0 30 30],'String','<<','FontSize',12,'Callback',@prevtrialcallback);
setcurrtrial = uicontrol(currtracepanel,'Position',[20 0 30 30],'Style', 'Edit', 'String', num2str(currdata(2)),'FontSize',12,'Callback',@setcurrtrialcallback);

%% autosort
% this handles the autosort options, and the buttons to do it
sortingpanel = uipanel('units','pixels','pos',[510 390 270 160]);
autosortpaneltxt = uicontrol(sortingpanel, 'units','pixels','pos',[5 135 70 20],'Style','text','String','Autosort','FontWeight','bold','FontSize',12);
autosort = uicontrol(sortingpanel,'Position',[5 5 80 30], 'String', 'autosort','FontSize',12,'Callback',@autosortcallback);
bgroupAB = uibuttongroup(sortingpanel, 'units','pixels','Position',[5 70 80 25]);
Aselect = uicontrol(bgroupAB,'Position',[5 1 35 20], 'Style', 'radiobutton', 'String', 'A','FontSize',12);
Bselect = uicontrol(bgroupAB,'Position',[40 1 35 20], 'Style', 'radiobutton', 'String', 'B','FontSize',12);
textKnum = uicontrol(sortingpanel,'Position',[5 35 40 18],'Style', 'text', 'String', 'K = ','FontSize',10);
Knum = uicontrol(sortingpanel,'Position',[50 35 30 18],'Style', 'Edit', 'String', num2str(3),'FontSize',10);
textPCnum = uicontrol(sortingpanel,'Position',[5 50 40 18],'Style', 'text', 'String', 'PC = ','FontSize',10);
PCnum = uicontrol(sortingpanel,'Position',[50 50 30 18],'Style', 'Edit', 'String', num2str(1),'FontSize',10);
bgroupshape = uibuttongroup(sortingpanel, 'units','pixels','Position',[5 95 80 40]);
shape_sort = uicontrol(bgroupshape,'Position',[2 18 70 17], 'Style', 'radiobutton', 'String', 'shape','FontSize',10);
ampl_sort = uicontrol(bgroupshape,'Position',[2 1 60 17], 'Style', 'radiobutton', 'String', 'ampl','FontSize',10);
%% some extra controls
noisepanel = uipanel('Title','Extra Controls','units','pixels','pos',[335 390 170 200]);
blanknoise = uicontrol(noisepanel,'Position',[5 70 160 30], 'String', 'Suppress Noise','FontSize',12,'Callback',@blanknoisecallback);
plotstimm = uicontrol(noisepanel,'Position',[5 150 160 30], 'String', 'Plot Stimulus','FontSize',12,'Callback',@plotstim);
mansort = uicontrol(noisepanel,'Position',[5 5 160 30], 'String', 'Manual Sort','FontSize',12,'Callback',@mansortcallback);
if prefs.Magic == 1
magicbutton = uicontrol(noisepanel,'Position',[5 35 160 30], 'String', 'Magic Button','FontSize',12,'Callback',@magicbuttoncallback);
end
rmvalve = uicontrol(noisepanel,'Position',[5 100 160 30], 'String', 'Remove Valve Noise','FontSize',12,'Callback',@rmvalvecallback);
%% select for auto sorting
selectpaneltxt = uicontrol(sortingpanel, 'units','pixels','pos',[110 135 60 20],'Style','text','String','Select','FontWeight','bold','FontSize',12);
bgroupmode = uibuttongroup(sortingpanel, 'units','pixels','Position',[110 5 80 20],'BorderType','none');
nomode = uicontrol(bgroupmode,'Position',[2 80 80 27], 'Style', 'radiobutton', 'String', 'no input','FontSize',12);
thnoise = uicontrol(bgroupmode,'Position',[2 2 80 27], 'Style', 'radiobutton', 'String', 'noise','FontSize',12);
thA = uicontrol(bgroupmode,'Position',[2 28 80 27], 'Style', 'radiobutton', 'String', 'neuron','FontSize',12);
modify = uicontrol(bgroupmode,'Position',[2 54 80 27], 'Style', 'radiobutton', 'String', 'modify','FontSize',12);
countmode = uicontrol(bgroupmode,'Position',[2 106 80 27], 'Style', 'radiobutton', 'String', 'count','FontSize',12);

%% filter find and done
% this needs to be modified so that the filter and find become one button
findmin = uicontrol(sortingpanel,'Position',[200 5 60 30], 'String', 'find','FontSize',12,'Callback',@findmincallback);
filt = uicontrol(sortingpanel,'Position',[200 35 60 30],'String', 'filter','FontSize',12, 'Callback',@filtcallback);
done = uicontrol(sortingpanel,'Position',[200 65 60 30],'String','done','FontSize',12, 'Callback',@donecallback);
redo = uicontrol(sortingpanel,'Position',[200 95 60 30],'String','redo','FontSize',12, 'Callback',@redocallback);
undo = uicontrol(sortingpanel,'Position',[200 125 60 30],'String','undo','FontSize',12, 'Callback',@undocallback);

%% count panel
% don't know what this does
countpanel = uipanel('units','pixels','pos',[510 560 270 130]);
countpaneltxt = uicontrol(countpanel, 'units','pixels','pos',[5 105 50 20],'Style','text','String','Count','FontWeight','bold','FontSize',12);
count = uicontrol(countpanel,'Position',[5 50 80 30], 'String', 'count','FontSize',12,'Callback',@countcallback);
textcountA = uicontrol(countpanel,'Position',[5 25 100 20],'Style', 'text', 'String', 'A = 0 spk/sec','FontSize',12,'FontWeight','bold');
textcountB = uicontrol(countpanel,'Position',[5 5 100 20],'Style', 'text', 'String', 'B = 0 spk/sec','FontSize',12,'FontWeight','bold');
textlengthcount = uicontrol(countpanel,'Position',[5 80 55 20],'Style', 'text', 'String', 'win = ','FontSize',11,'FontWeight','bold');
getlengthcount = uicontrol(countpanel,'Position',[55 80 55 20],'Style', 'Edit', 'String','0.5','FontSize',11);

%% plot panel
% this has the buttons to plot the raster plots and the PSTH
plotpanel = uipanel('units','pixels','pos',[830 550 320 140]);
plotpaneltxt = uicontrol(plotpanel, 'units','pixels','pos',[5 109 80 27],'Style','text','String','Plot','FontWeight','bold','FontSize',12);
rasterplot = uicontrol(plotpanel,'Position',[5 80 80 30],'String','raster','FontSize',12, 'Callback',@rasterplotcallback);
setrasterexp = uicontrol(plotpanel,'Position',[88 80 50 30],'Style', 'Edit', 'String', 'all-all', 'FontSize',12);
bgroupraster = uibuttongroup(plotpanel, 'units','pixels','Position',[140 80 50 30],'BorderType','none');
Araster = uicontrol(bgroupraster,'Position',[2 2 50 30], 'Style', 'radiobutton', 'String', 'A','FontSize',12);
Braster = uicontrol(bgroupraster,'Position',[34 2 50 30], 'Style', 'radiobutton', 'String', 'B','FontSize',12);
PSTHplot = uicontrol(plotpanel,'Position',[5 45 80 30],'String','PSTH','FontSize',12, 'Callback',@PSTHplotcallback);
setPSTHexp = uicontrol(plotpanel,'Position',[88 45 50 30],'Style', 'Edit', 'String', 'all-all', 'FontSize',12);
bgroupPSTH = uibuttongroup(plotpanel, 'units','pixels','Position',[140 45 50 30],'BorderType','none');
APSTH = uicontrol(bgroupPSTH,'Position',[2 2 50 30], 'Style', 'radiobutton', 'String', 'A','FontSize',12);
BPSTH = uicontrol(bgroupPSTH,'Position',[34 2 50 30], 'Style', 'radiobutton', 'String', 'B','FontSize',12);
textbin = uicontrol(plotpanel,'Position',[210 52 40 30],'Style', 'text', 'String', 'bin','FontSize',11,'FontWeight','bold');
getbin = uicontrol(plotpanel,'Position',[210 45 40 20],'Style', 'Edit', 'String','0.1','FontSize',11);
textslid = uicontrol(plotpanel,'Position',[250 52 40 30],'Style', 'text', 'String', 'slid','FontSize',11,'FontWeight','bold');
getslid = uicontrol(plotpanel,'Position',[250 45 40 20],'Style', 'Edit', 'String','0.01','FontSize',11);
savecurrplot = uicontrol(plotpanel,'Position',[5 5 80 30],'String','save plot','FontSize',12, 'Callback',@savecurrplotcallback);

%% begin function definitions (the wiring behind the buttons) for view panel
        
    function zoomincallback(eo,ed) % why this? for some weird reason this function is invoked with 2 inputs, and I don't know what they are
        % if i define this function without any inputs, MATLAB complains
        % that there are too many inputs, and gives an error
         zoom xon
    end
    
    function zoomycallback(eo,ed)
         zoom yon
    end

    function cursorcallback(eo,ed)
        zoom off
        pan off
    end

    function pancallback(eo,ed)
        pan xon
    end
    function panycallback(eo,ed)
        pan yon
    end
% we're done wiring up the view panel buttons
%% begin function definitions (the wiring behind the buttons) for parameters panel
    function getdeltatcallback(eo,ed)
        deltat = str2double(get(getdeltat, 'String'));
        refractory = str2double(get(getrefractory, 'String'));
        tr = round(refractory/deltat);
    end
%% begin function definitions (the wiring behind the buttons) for file I/O panel
% the file I/O panel has these callbacks:
% 1. @loadfilecallback
% 2. @loadspkcallback
% 3. @savefilecallback

% 1. 
    function loadfilecallback(eo,ed)
        dataformat = get(selectformat, 'value');
        [V filein_name file_path svalve pid] = spike_sorting_loadfile_b(dataformat);
        if ~isempty(V)
            [numexp numtrials L] = size(V);
            time = (1:L)'*deltat;
            Vcurr = squeeze(V(currdata(1),currdata(2),:));
            plot(ax,time, Vcurr, 'k');           
            plotstim;
            pidcurr = squeeze(pid(currdata(1),currdata(2),:));
            plot(ax2, time(1:10:end), pidcurr(1:10:end), 'k');
            set(showloadfile, 'String', filein_name)
            THnoise = zeros(L,1);
            SPKcurr = zeros(L,1);
            THA = zeros(L,1);
            tSPKA = zeros(numexp,numtrials,3000);
            tSPKB = zeros(numexp,numtrials,3000);
            tracedone = zeros(numexp, numtrials);
            SPKcountA = zeros(numexp, numtrials);
            SPKcountB = zeros(numexp, numtrials);
            set(setcurrexp, 'String', num2str(currdata(1)))
            set(setcurrtrial, 'String', num2str(currdata(2)))
            s = regexp(filein_name, '\.mat', 'split');
            fileout_name = [s{1} '_SPKtemp.mat'];
            set(getfilenameout, 'String', fileout_name);
%             xlsout_name = [s{1} '_SPKtemp.xls'];   % Excel stuff,
%             disabled.
%             countxlsout_name = [s{1} '_COUNT.xls']; 
%             set(getxlsnameout, 'String', xlsout_name);
%             set(getcountxlsnameout, 'String', countxlsout_name);
            set(texttrial, 'String', ['num trials: ' num2str(numtrials)],'FontSize',12,'FontWeight','bold');
            set(textexp, 'String', ['num exp: ' num2str(numexp)],'FontSize',12,'FontWeight','bold');
        end
         if prefs.loadSPK == 1
            if length(dir(strcat(file_path,s{1},'_SPK*.mat')))== 1;
                temp = dir(strcat(file_path,s{1},'_SPK*.mat'));
                filespk_name = temp.name; clear temp;
                set(showloadspkfile, 'String', filespk_name)
                F = load([ file_path filespk_name]);
                tSPKA = F.tSPKA;
                tSPKB = F.tSPKB;
                tracedone = F.tracedone;
                SPKcountA = F.SPKcountA;
                SPKcountB = F.SPKcountB;
                if tracedone(currdata(1), currdata(2)) && ~isempty(V)
                    replot_tracedone(ax)
                end
                set(getfilenameout, 'String', filespk_name);
                s = regexp(filespk_name, '\.mat', 'split');
                [numexp numtrials] = size(tracedone);
                set(texttrial, 'String', ['num trials: ' num2str(numtrials)],'FontSize',12,'FontWeight','bold');
                set(textexp, 'String', ['num exp: ' num2str(numexp)],'FontSize',12,'FontWeight','bold');
                set(textcountA, 'String', ['A = ' num2str(SPKcountA(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
                set(textcountB, 'String', ['B = ' num2str(SPKcountB(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
            end
         end
        
    end

% 2. @loadspkcallback
function loadspkcallback(eo,ed)
    [filespk_name, file_path] = uigetfile('*.mat','Select the data file');
    if filespk_name~=0
        set(showloadspkfile, 'String', filespk_name)
        F = load([ file_path filespk_name]);
        tSPKA = F.tSPKA;
        tSPKB = F.tSPKB;
        tracedone = F.tracedone;
        SPKcountA = F.SPKcountA;
        SPKcountB = F.SPKcountB;
        if tracedone(currdata(1), currdata(2)) && ~isempty(V)
            replot_tracedone(ax)
        end
        set(getfilenameout, 'String', filespk_name);
        s = regexp(filespk_name, '\.mat', 'split');
%             xlsout_name = [s{1} '.xls'];
%             set(getxlsnameout, 'String', xlsout_name);
%             s = regexp(filespk_name, '\SPK', 'split');
%             countxlsout_name = [s{1} 'COUNT.xls'];
%             set(getcountxlsnameout, 'String', countxlsout_name);
        [numexp numtrials] = size(tracedone);
        set(texttrial, 'String', ['num trials: ' num2str(numtrials)],'FontSize',12,'FontWeight','bold');
        set(textexp, 'String', ['num exp: ' num2str(numexp)],'FontSize',12,'FontWeight','bold');
        set(textcountA, 'String', ['A = ' num2str(SPKcountA(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
        set(textcountB, 'String', ['B = ' num2str(SPKcountB(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
    end
end

% 3. @savefilecallback
     

    function savefilecallback(eo,ed)
        fileout_name = get(getfilenameout, 'String');
        save([file_path fileout_name], 'tSPKA', 'tSPKB', 'deltat', 'tracedone', 'SPKcountA', 'SPKcountB');
    end

%% disabled excel functions
%     function savexlscallback(eo,ed)
%         xlsout_name = get(getxlsnameout, 'String');
%         if get(winmode, 'Value')==1       
%             for i=1:numexp
%                 maxsizeA = 1;
%                 for t=1:numtrials
%                     c = find(squeeze(tSPKA(i,t,2:end))==0,1);
%                     if c>maxsizeA; maxsizeA = c; end
%                 end
%                 xlswrite([file_path xlsout_name], squeeze(tSPKA(i,:,1:maxsizeA))'*deltat, ['exp#' num2str(i)]);
%             end
% 
%             if any(tSPKB)
%                 for i=1:numexp
%                     maxsizeB = 1;
%                     for t=1:numtrials
%                         c = find(squeeze(tSPKB(i,t,2:end))==0,1);
%                         if c>maxsizeB; maxsizeB = c; end
%                     end
%                     xlswrite([file_path xlsout_name], squeeze(tSPKB(i,:,1:maxsizeB))'*deltat, ['exp#' num2str(i)], ['A' num2str(maxsizeA + 5)]);
%                 end
%             end
%         elseif get(macmode, 'Value')==1
%             for i=1:numexp
%                 maxsizeA = 1;
%                 for t=1:numtrials
%                     c = find(squeeze(tSPKA(i,t,2:end))==0,1);
%                     if c>maxsizeA; maxsizeA = c; end
%                 end
%                 s = regexp(xlsout_name, '.xls', 'split');
%                 csvwrite([file_path s{1} '_' num2str(i) '.csv'], squeeze(tSPKA(i,:,1:maxsizeA))'*deltat);
% 
%                 if any(tSPKB) 
%                     maxsizeB = 1;
%                     for t=1:numtrials
%                         c = find(squeeze(tSPKB(i,t,2:end))==0,1);
%                         if c>maxsizeB; maxsizeB = c; end
%                     end
%                     csvwrite([file_path s{1} '_' num2str(i) '.csv'], squeeze(tSPKA(i,:,1:maxsizeA))'*deltat, num2str(maxsizeA + 5), 0);
%                 end
%             end
%         end
%     end
% 
%     function savecountxlscallback(eo,ed)
%         countxlsout_name = get(getcountxlsnameout, 'String');
%         if get(winmode, 'Value')==1       
%             xlswrite([file_path countxlsout_name], SPKcountA, 'A neuron');
%             xlswrite([file_path countxlsout_name], SPKcountB, 'B neuron');
%         elseif get(macmode, 'Value')==1
%             s = regexp(countxlsout_name, '\.xls', 'split');
%             csvwrite([file_path s{1} '_A.csv'], SPKcountA);
%             csvwrite([file_path s{1} '_B.csv'], SPKcountB);
%         end
%     end
    
%% this special callback controls what the mouse does globally    

    function mousecallback(eo,ed)
        xlimit = get(ax, 'xlim');
        ylimit = get(ax, 'ylim');
        pos = get(ax,'CurrentPoint');
        xpos = pos(1);
        ypos = pos(3);
        if get(nomode, 'Value')==1
            [dmin,px_spk] = min((time-xpos).^2+(SPKcurr-ypos).^2);
            [dmin,px_v] = min((time-xpos).^2+(Vcurr-ypos).^2);
            if get(Aselect, 'value')
                Aamp = SPKcurr(px_spk);
                Ashape = Vcurr(px_spk-tr:px_spk + tr - 1);
                Ax = px_spk;
            elseif get(Bselect, 'value')
                Bamp = SPKcurr(px_spk);
                Bshape = Vcurr(px_spk-tr:px_spk+tr-1);
                Bx = px_spk;
            end
        elseif get(countmode, 'value')
            startcount = xpos;
           
        elseif get(modify, 'Value')==0
            xpos = round(xpos/deltat);
            if xpos<=0; xpos = 1; end
            if xpos>L; xpos = L; end
            if xpos<tlim; tlim=1; end
            
            if get(thnoise, 'Value')==1
                mode = 1;
                if tlim==1; THnoise = zeros(L,1); end
                THnoise(tlim:xpos) = ypos;
                pSPKcurr = SPKcurr; pSPKcurr(SPKcurr == 0) = NaN; 
                plot(ax,time, Vcurr, 'k', time, pSPKcurr, '.r', time, THnoise, 'r')
                set(ax,'xlim',xlimit)
                set(ax,'ylim',ylimit)
                set(ax2,'xlim',xlimit)
                clear pSPKcurr
                plotstim;
                tlim = xpos+1;
            end
            if get(thA, 'Value')==1
                mode = 2;
                if tlim==1; THA = zeros(L,1); end
                THA(tlim:xpos) = ypos;
                pSPKcurr = SPKcurr; pSPKcurr(SPKcurr == 0) = NaN; 
                plot(ax,time, Vcurr, 'k', time, pSPKcurr, '.r', time, THA, 'r')
                set(ax,'xlim',xlimit)
                set(ax,'ylim',ylimit)
                set(ax2,'xlim',xlimit)
                clear pSPKcurr
                plotstim;
                tlim = xpos+1;
            end
        elseif get(modify, 'Value')==1
            mode = 3;
            [dmin,px_spk] = min((time-xpos).^2+(SPKcurr-ypos).^2);
            [dmin,px_v] = min((time-xpos).^2+(Vcurr-ypos).^2);
            
        end
        
    end

%% this special callback handles what the keyboard does

    function keycallback(eo,ed)    % so now this uses ed. What is this?
        % ed is a structure that contains the keyboard input values, the
        % character, the modifier, and the key, which is the actial thing
        % entered. eo seems to contain a number, maybe a handle? not sure.
        if get(modify, 'Value') || get(thnoise, 'Value') || get(thA, 'Value')
            keypressed = ed.Key;
            xlimit = get(ax, 'xlim');
            ylimit = get(ax, 'ylim');
            if strcmp(keypressed, 'rightarrow');
                newlim = xlimit + (xlimit(2)-xlimit(1))/3;
                if newlim(1)<0; newlim(1)=-0.1; newlim(2) = newlim(1) + (xlimit(2)-xlimit(1));   end
                if newlim(2)>(L*deltat)+1; newlim(2)=(L*deltat)+1.1; newlim(1) = newlim(2) - (xlimit(2)-xlimit(1)); end
                xlimit = newlim;
                set(ax,'xlim', xlimit, 'ylim', ylimit)
                set(ax2,'xlim', xlimit)
            elseif strcmp(keypressed, 'leftarrow');
                newlim = xlimit - (xlimit(2)-xlimit(1))/3;
                if newlim(1)<0; newlim(1)=-0.1; newlim(2) = newlim(1) + (xlimit(2)-xlimit(1));   end
                if newlim(2)>(L*deltat)+1; newlim(2)=(L*deltat)+1.1; newlim(1) = newlim(2) - (xlimit(2)-xlimit(1)); end
                xlimit = newlim;
                set(ax,'xlim', xlimit, 'ylim', ylimit)
                set(ax2,'xlim', xlimit);
            elseif get(modify, 'Value')
                mode = 3; % modify mode.
                SPKAtemp = SPKAcurr;
                SPKBtemp = SPKBcurr;
                SPKtemp = SPKcurr;
                if strcmp(keypressed, 'backspace')
                    SPKcurr(px_spk) = 0;
                    SPKAcurr(px_spk) = 0;
                    SPKBcurr(px_spk) = 0;
                    pSPKAcurr = SPKAcurr; pSPKBcurr = SPKBcurr; pSPKAcurr(SPKAcurr == 0) = NaN; pSPKBcurr(SPKBcurr ==0) =NaN;
                    plot(ax,time, Vcurr, 'k', time, pSPKAcurr, '.r', time, pSPKBcurr, '.b')
                    clear pSPKAcurr pSPKBcurr
                    xlim(xlimit)
                    ylim(ylimit)
                    plotstim;
                    set(ax2,'xlim',xlimit)
                   
                end
                if strcmp(keypressed, 'a')
                    SPKAcurr(px_spk) = SPKcurr(px_spk);
                    SPKBcurr(px_spk) = 0;
                    pSPKAcurr = SPKAcurr; pSPKBcurr = SPKBcurr; pSPKAcurr(SPKAcurr == 0) = NaN; pSPKBcurr(SPKBcurr ==0) =NaN;
                    plot(ax, time, Vcurr, 'k', time, pSPKAcurr, '.r', time, pSPKBcurr, '.b')
                    clear pSPKAcurr pSPKBcurr
                    xlim(xlimit)
                    ylim(ylimit)
                    plotstim;
                    set(ax2,'xlim',xlimit)
                   
                end
                if strcmp(keypressed, 'b')
                    SPKBcurr(px_spk) = SPKcurr(px_spk);
                    SPKAcurr(px_spk) = 0;
                    pSPKAcurr = SPKAcurr; pSPKBcurr = SPKBcurr; pSPKAcurr(SPKAcurr == 0) = NaN; pSPKBcurr(SPKBcurr ==0) =NaN;
                    plot(ax, time, Vcurr, 'k', time, pSPKAcurr, '.r', time, pSPKBcurr, '.b')
                    clear pSPKAcurr pSPKBcurr
                    xlim(xlimit)
                    ylim(ylimit)
                    plotstim;
                    set(ax2,'xlim',xlimit)
                   
                end
                if strcmp(keypressed, 'n')
                    SPKAcurr(px_v) = Vcurr(px_v);
                    SPKcurr(px_v) = Vcurr(px_v);
                    pSPKAcurr = SPKAcurr; pSPKBcurr = SPKBcurr; pSPKAcurr(SPKAcurr == 0) = NaN; pSPKBcurr(SPKBcurr ==0) =NaN;
                    plot(ax, time, Vcurr, 'k', time, pSPKAcurr, '.r', time, pSPKBcurr, '.b')
                    clear pSPKAcurr pSPKBcurr
                    xlim(xlimit)
                    ylim(ylimit)
                    plotstim;
                    set(ax2,'xlim',xlimit)
                    
                end
                % save on modify
                tSPKA(currdata(1), currdata(2),1:sum(SPKAcurr~=0))=find(SPKAcurr~=0);
                tSPKB(currdata(1), currdata(2),1:sum(SPKBcurr~=0))=find(SPKBcurr~=0);
                tSPKA(currdata(1), currdata(2),sum(SPKAcurr~=0)+1:end)=0;
                tSPKB(currdata(1), currdata(2),sum(SPKBcurr~=0)+1:end)=0;
                tracedone(currdata(1),currdata(2))=1;
                fileout_name = get(getfilenameout, 'String');
                save([file_path fileout_name], 'tSPKA', 'tSPKB', 'deltat', 'tracedone', 'SPKcountA', 'SPKcountB');
            end
        end
    end

%% scroll callbacks
    function scrollcallback(eo,ed)
        xlimit = get(ax, 'xlim');
        scrollsize = ed.VerticalScrollCount;
        newlim = xlimit + scrollsize*(xlimit(2)-xlimit(1))/3;
        if newlim(1)<0; newlim(1)=-0.1; newlim(2) = newlim(1) + (xlimit(2)-xlimit(1));   end
        if newlim(2)>+(L*deltat)+1; newlim(2)=(L*deltat)+1.1; newlim(1) = newlim(2) - (xlimit(2)-xlimit(1)); end
        xlimit = newlim;
        set(ax,'xlim', xlimit)
        set(ax2,'xlim', xlimit);
    end


    function nextexpcallback(eo,ed)
        % donecallback; % NO autosave
        if currdata(1)<numexp
            currdata(1) = currdata(1)+1;
            Vcurr = squeeze(V(currdata(1), currdata(2),:));
            pidcurr = squeeze(pid(currdata(1), currdata(2),:));
            set(setcurrexp, 'String', num2str(currdata(1)));
            set(setcurrtrial, 'String', num2str(currdata(2)));
            set(textcountA, 'String', ['A = ' num2str(SPKcountA(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
            set(textcountB, 'String', ['B = ' num2str(SPKcountB(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
            if tracedone(currdata(1), currdata(2))   
                replot_tracedone(ax)
            else
               plot(ax, time, Vcurr, 'k');
               plotstim;
               set(findmin,'Enable','on')
               plot(ax2, time(1:10:end), pidcurr(1:10:end), 'k');
            end
        end
    end

    function prevexpcallback(eo,ed)
        % donecallback; % NO autosave
        if currdata(1)>1
            currdata(1) = currdata(1)-1;
            Vcurr = squeeze(V(currdata(1), currdata(2),:));
            pidcurr = squeeze(pid(currdata(1), currdata(2),:));
            set(setcurrexp, 'String', num2str(currdata(1)));
            set(setcurrtrial, 'String', num2str(currdata(2)));
            set(textcountA, 'String', ['A = ' num2str(SPKcountA(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
            set(textcountB, 'String', ['B = ' num2str(SPKcountB(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
            if tracedone(currdata(1), currdata(2))  
                replot_tracedone(ax)
            else
               plot(ax, time, Vcurr, 'k');
               plotstim;
               set(findmin,'Enable','on')
               plot(ax2, time(1:10:end), pidcurr(1:10:end), 'k');
            end
        end
    end

    function nexttrialcallback(eo,ed)
        % donecallback; % NO autosave
        if currdata(2)<numtrials            
            currdata(2) = currdata(2)+1;
            Vcurr = squeeze(V(currdata(1), currdata(2),:));
            pidcurr = squeeze(pid(currdata(1), currdata(2),:));
            set(setcurrtrial, 'String', num2str(currdata(2)))
            if tracedone(currdata(1), currdata(2))    
                replot_tracedone(ax)
            else
               plot(ax, time, Vcurr, 'k');
               plotstim;
               set(findmin,'Enable','on')
               plot(ax2, time(1:10:end), pidcurr(1:10:end), 'k');
            end
            set(textcountA, 'String', ['A = ' num2str(SPKcountA(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
            set(textcountB, 'String', ['B = ' num2str(SPKcountB(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
        end
    end

    function prevtrialcallback(eo,ed)
        % donecallback; % NO autosave
        if currdata(2)>1            
            currdata(2) = currdata(2)-1;
            Vcurr = squeeze(V(currdata(1), currdata(2),:));
            pidcurr = squeeze(pid(currdata(1), currdata(2),:));
            set(setcurrtrial, 'String', num2str(currdata(2)))
            if tracedone(currdata(1), currdata(2))  
                replot_tracedone(ax)
            else
               plot(ax, time, Vcurr, 'k');
               plotstim;
               set(findmin,'Enable','on')
               plot(ax2, time(1:10:end), pidcurr(1:10:end), 'k');
            end
            set(textcountA, 'String', ['A = ' num2str(SPKcountA(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
            set(textcountB, 'String', ['B = ' num2str(SPKcountB(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
        end
    end

    function setcurrexpcallback(eo,ed) 
       %  donecallback; % NO autosave
        n1 = get(setcurrtrial, 'String');
        currdata(1) = str2num(n1);
        currdata(2) = 1;
        if currdata(1)<numexp
            Vcurr = squeeze(V(currdata(1), currdata(2),:));
            pidcurr = squeeze(pid(currdata(1), currdata(2),:));
            if tracedone(currdata(1), currdata(2))   
                replot_tracedone(ax)
            else
               plot(ax, time, Vcurr, 'k');
               plotstim;
               set(findmin,'Enable','on')
               plot(ax2, time(1:10:end), pidcurr(1:10:end), 'k');
            end
        end
        set(textcountA, 'String', ['A = ' num2str(SPKcountA(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
        set(textcountB, 'String', ['B = ' num2str(SPKcountB(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
    end

    function setcurrtrialcallback(eo,ed)
        n2 = get(setcurrtrial, 'String');
        currdata(2) = str2num(n2);
        if currdata(2)<numtrials
            Vcurr = squeeze(V(currdata(1), currdata(2),:));
            pidcurr = squeeze(pid(currdata(1), currdata(2),:));
            if tracedone(currdata(1), currdata(2))  
                replot_tracedone(ax)
            else
               plot(ax, time, Vcurr, 'k');
               plotstim;
               set(findmin,'Enable','on')
               plot(ax2, time(1:10:end), pidcurr(1:10:end), 'k');
            end
            set(textcountA, 'String', ['A = ' num2str(SPKcountA(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
            set(textcountB, 'String', ['B = ' num2str(SPKcountB(currdata(1), currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
        end
    end

    function filtcallback(eo,ed)
        Vcurr = butter_filter(Vcurr, 70, 1000, deltat, 1, 3);
        plot(ax, time, Vcurr, 'k');
        % for Srinivas
        %findmincallback;   
        %set(thnoise,'Value',1)
        plotstim;
    end

    function findmincallback(eo,ed)   
        
        xlimit = get(ax, 'xlim');
        V0 = zeros(tr, 1);
        SPKcurr = Mfind_spikes([V0; Vcurr],Tnoise, tr);
        % SPKcurr appears to be a long vector, with zeros everywhere,
        % except at the minimia corresponding to the spikes.     
        pSPKcurr = SPKcurr;
        pSPKcurr(SPKcurr == 0) =  NaN;
        plot(ax, time, Vcurr, 'k',time, pSPKcurr, '.r')
        set(ax,'xlim',xlimit)
        plotstim;
        % and calling findmin disables the button
        set(findmin, 'Enable', 'off');
        set(ax2,'xlim', xlimit);
    end

%% blank noise function
    function blanknoisecallback(eo,ed)
        getdeltatcallback;
        S = [];        
        ind = find(SPKcurr<0);
        
        if any(find(ind>tr, 1)) % tr is a function of the refractory period. 
            ind(1:find(ind>tr, 1))=[];
        end
        if any(find(ind>length(SPKcurr)-tr-1))
            ind(find(ind>length(SPKcurr)-tr-1,1):end)=[];
        end
        amp = SPKcurr(ind);
        % find shapes for clustering
        dropV = zeros(1,length(ind));  % voltage difference to preceding maxima
        climbV = dropV; % voltage difference to next maxima
        for i=1:length(ind)
            S(i,:) = Vcurr(ind(i)-tr:ind(i)+tr-1);
            dbeforeV = diff(Vcurr(max(1,ind(i) - 50):ind(i)));
            dafterV = diff(Vcurr(ind(i):min(length(Vcurr),50+ind(i))));
            % find last peak 
            
            lastpeak = Vcurr(ind(i) - find(dbeforeV>0,1,'last'));
            % find next peak
            nextpeak = Vcurr(ind(i) + find(dafterV<0,1,'first'));
            if isempty(lastpeak)
                lastpeak = Vcurr(ind(i) - 50); % spike so broad we can't see the end of it
            end
            if isempty(nextpeak)
                nextpeak = Vcurr(ind(i) + 50); % spike so broad we can't see the end of it
            end
            dropV(i) = lastpeak - S(i,26);
            climbV(i) = nextpeak - S(i,26);
        end
        
        SPKcurr(ind(dropV + climbV < 0.02)) = 0;
        
        S((dropV + climbV < 0.02),:) = [];
        ind(dropV + climbV < 0.02 < 0.1) = [];
       
        xlimit = get(ax, 'xlim');   
        pSPKcurr = SPKcurr;
        pSPKcurr(SPKcurr == 0) =  NaN;
        plot(ax, time, Vcurr, 'k',time, pSPKcurr, '.r')
        set(ax,'xlim',xlimit)
        plotstim;
        set(ax2,'xlim', xlimit);
        disp('Some noise removed.')
    end

%% remove valve noise 
    function rmvalvecallback(eo,ed)
        % we assume that for every valve on & off, there is a valve artefact
        % around 2 ms after the valve off time. we find it, if it exists,
        % and obliterate it. t
        if isempty(svalve)
            disp('I cant remove valve artefacts because I dont have stim signal data. ')
            return
        end
        toff = (svalve(currdata(1),currdata(2)).toff);
        ton = (svalve(currdata(1),currdata(2)).ton);
        if toff(length(toff))+20*1e-4 > 20  % this is a subtle module to make sure there are no
            % errors when toff is very close to the end
            endhere = length(toff) - 1;
        else
            endhere = length(toff);
        end
        for i = 1:endhere
            rmthis = find(SPKcurr(round(toff(i)/deltat):round(toff(i)/deltat)+20)) - 1;
            SPKcurr(round(toff(i)/deltat) + rmthis) = 0;
            rmthis = find(SPKcurr(round(ton(i)/deltat):round(ton(i)/deltat)+20)) - 1;
            SPKcurr(round(ton(i)/deltat) + rmthis) = 0;
        end
        pSPKcurr = SPKcurr;  pSPKcurr(SPKcurr == 0) = NaN; 
        plot(ax, time, Vcurr, 'k', time, pSPKcurr, '.r')
        plotstim;
    end

%% magic button callback
    function magicbuttoncallback(eo,ed)
        filtcallback;
        filtcallback;
        findmincallback;
        rmvalvecallback;
        mansortcallback;
    end

%% manual sort callbacks
    function mansortcallback(eo,ed)
        cp = []; PC = []; ind = []; IS = []; S = [];
        % interface from autosort...
         % SPKcurr is a vector as long as time, with zeros everywhere except
        % at the minima of spikes, where it takes the value of the minima.               
        ind = find(SPKcurr<0);      
        disp(strcat(mat2str(length(ind)),' putative spikes found.'))

        if any(find(ind>tr, 1)) % tr is a function of the refractory period. 
            ind(1:find(ind>tr, 1))=[];
            
        end
        if any(find(ind>length(SPKcurr)-tr-1))
            ind(find(ind>length(SPKcurr)-tr-1,1):end)=[];
        end
        % find shapes for clustering
        for i=1:length(ind)
            S(i,:) = Vcurr(ind(i)-tr:ind(i)+tr-1);   
             S(i,:) = S(i,:) - S(i,25);
        end 
        
        % what's happened so far is that little segments around the time of
        % spike have been cut out, and are assembled into the matrix S
        [ans,PC] = princomp(S);

        
        % open up a new window for the interactive clustering interface
        hmc = figure('Name',strcat(versionname, ': Interactive Clustering'),'WindowButtonDownFcn',@mansortmouse,'NumberTitle','off','position',[50 50 1200 700]); hold on,axis off
        hm1 = axes('parent',hmc,'position',[-0.05 0.1 0.7 0.7]);axis square, hold on ; title('Clusters'), xlabel('PC 1'), ylabel('PC 2')
        hm2 = axes('parent',hmc,'position',[0.5 0.5 0.3 0.3]);axis square, hold on  ; title('Unsorted Spikes'), set(gca,'YLim',[min(min(S)) max(max(S))]);
        hm3 = axes('parent',hmc,'position',[0.5 0.1 0.3 0.3]);axis square, hold on ; title('A Spikes'),set(gca,'YLim',[min(min(S)) max(max(S))]);
        hm4 = axes('parent',hmc,'position',[0.72 0.5 0.3 0.3]);axis square, hold on ; title('B Spikes'),set(gca,'YLim',[min(min(S)) max(max(S))]);
        hm5 = axes('parent',hmc,'position',[0.72 0.1 0.3 0.3]);axis square, hold on ; title('Noise Spikes'),set(gca,'YLim',[min(min(S)) max(max(S))]);
        % define the buttons and stuff
        sortpanel = uipanel('Title','Controls','units','pixels','pos',[35 650 970 70]);
        addA = uicontrol(sortpanel,'Position',[15 10 100 30], 'String', 'Add to A','FontSize',12,'Callback',@addAcallback);
        addB = uicontrol(sortpanel,'Position',[115 10 100 30], 'String', 'Add to B','FontSize',12,'Callback',@addBcallback);
        addN = uicontrol(sortpanel,'Position',[220 10 160 30], 'String', 'Add to Noise','FontSize',12,'Callback',@addNcallback);
        upcb = uicontrol(sortpanel,'Position',[800 10 160 30], 'String', 'Update and Quit','FontSize',12,'Callback',@updatecluster);
        autofixbutton = uicontrol(sortpanel,'Position',[610 10 160 30], 'String', 'Auto Fix','FontSize',12,'Enable','off','Callback',@autofixcallback);
        editon = 0; % this is a mode selector b/w edititing and looking
        IS = zeros(1,length(PC));
        % plot the clusters
        clusterplot;
        
        cp = [];
      
    end
    function addAcallback(eo,ed)
        editon = 1;
        ifh = imfreehand(hm1);
        p = getPosition(ifh);
        inp = inpolygon(PC(:,1),PC(:,2),p(:,1),p(:,2));
        IS(inp) = 1; % A is 1
        clusterplot;
        editon = 0;
    end
    function addBcallback(eo,ed)
        editon = 1;
        ifh = imfreehand(hm1);
        p = getPosition(ifh);
        inp = inpolygon(PC(:,1),PC(:,2),p(:,1),p(:,2));
        IS(inp) = 2; % B is 2
        clusterplot;
        editon = 0;
    end
    function addNcallback(eo,ed)
        editon = 1;
        ifh = imfreehand(hm1);
        p = getPosition(ifh);
        inp = inpolygon(PC(:,1),PC(:,2),p(:,1),p(:,2));
        IS(inp) = 3; % Noise is 3    
        clusterplot;
        editon = 0;
    end


    function autofixcallback(eo,ed)
        % this automatically assigns unsorted points to the nearsest
        % clusters
        if length(unique(IS))  == 4         
            % we have made at least some assignments to each cluster
             xN = PC(IS==3,1); yN = PC(IS==3,2);
             xA = PC(IS==1,1); yA = PC(IS==1,2);
             xB = PC(IS==2,1); yB = PC(IS==2,2);
            dothese = find(IS == 0);
            for i = 1:length(dothese)
                p = PC(dothese(i),1:2);
                cdist(1) = min((xA-p(1)).^2+(yA-p(2)).^2);
                cdist(2) = min((xB-p(1)).^2+(yB-p(2)).^2);
                cdist(3) = min((xN-p(1)).^2+(yN-p(2)).^2);
                IS(dothese(i)) = find(cdist == min(cdist));
            end
            clusterplot;
        end
    end

    function mansortmouse(eo,ed)
        if editon == 1
            return
        end
        if gca == hm2
            pp = get(hm2,'CurrentPoint');
            
            p(1) = round(pp(1,1)); p(2) = pp(1,2);
            [ans mi] = min(abs(p(2) - S(IS==0,p(1))));
            
            clear ans
            % plot on main plot
            cla(hm1)
            plot(hm1,PC(IS == 1,1),PC(IS == 1,2),'.r')         % plot A
            plot(hm1,PC(IS == 2,1),PC(IS == 2,2),'.b')         % plot B
            plot(hm1,PC(IS == 3,1),PC(IS == 3,2),'.k')         % plot Noise
            plot(hm1,PC(IS == 0,1),PC(IS == 0,2),'.g')         % plot unassigned
            scatter(hm1,PC(cp,1),PC(cp,2),'+k')
            scatter(hm1,PC(mi,1),PC(mi,2),64,'dk')
            
        elseif gca == hm1 
             pp = get(hm1,'CurrentPoint');
             p(1) = (pp(1,1)); p(2) = pp(1,2);
             x = PC(:,1); y = PC(:,2);
             [ans,cp] = min((x-p(1)).^2+(y-p(2)).^2); % cp is the index of the chosen point
                if length(cp) > 1
                    cp = min(cp);
                end
            % plot the point
             cla(hm1)         
             plot(hm1,PC(IS == 1,1),PC(IS == 1,2),'.r')         % plot A
             plot(hm1,PC(IS == 2,1),PC(IS == 2,2),'.b')         % plot B
             plot(hm1,PC(IS == 3,1),PC(IS == 3,2),'.k')         % plot Noise
             plot(hm1,PC(IS == 0,1),PC(IS == 0,2),'.g')         % plot unassigned
             scatter(hm1,PC(cp,1),PC(cp,2),'+k')
             title(hm1,strcat(mat2str(length(PC)),' putative spikes.'))  

             cla(hm2)       
             plot(hm2,S(IS == 0,:)','g')
             plot(hm2,S(cp,:),'k','LineWidth',2)
             set(hm2,'XLim',[0 50])
        end
    end

    function clusterplot(eo,ed)
         cla(hm1)     
         % plot A
         plot(hm1,PC(IS == 1,1),PC(IS == 1,2),'.r')
         % plot B
         plot(hm1,PC(IS == 2,1),PC(IS == 2,2),'.b')
         % plot Noise
         plot(hm1,PC(IS == 3,1),PC(IS == 3,2),'.k')
         % plot unassigned
         plot(hm1,PC(IS == 0,1),PC(IS == 0,2),'.g')
         
         
         % also plot the spike shapes
         cla(hm2)
         plot(hm2,S(IS == 0,:)','g')
         set(hm2,'XLim',[0 50])
         
         
         try 
             cla(hm3)
             plot(hm3,S(IS == 1,:)','r')
             set(hm3,'XLim',[0 50])
         catch ME1
             if strcmp(regexp(ME1.identifier, '(?<=:)\w+$', 'match'),'invalidHandle')
                 disp('MATLAB is having problems clearing an plot window. This is an error, but your data has been saved, and you can proceed')
             end
         end
         
         
         
         
         try 
             cla(hm4)
             plot(hm4,S(IS == 2,:)','b')
             set(hm4,'XLim',[0 50])
         catch ME1
             if strcmp(regexp(ME1.identifier, '(?<=:)\w+$', 'match'),'invalidHandle')
                 disp('MATLAB is having problems clearing an plot window. This is an error, but your data has been saved, and you can proceed')
             end
         end
         
         
        
         

         try 
             cla(hm5)
             plot(hm5,S(IS == 3,:)','k')
             set(hm5,'XLim',[0 50])
         catch ME1
             if strcmp(regexp(ME1.identifier, '(?<=:)\w+$', 'match'),'invalidHandle')
                 disp('MATLAB is having problems clearing an plot window. This is an error, but your data has been saved, and you can proceed')
             end
         end

        if min([length(find(IS == 1)) length(find(IS == 2)) length(find(IS == 3))]) > 0
            set(autofixbutton,'Enable','on')
        end
         
         
         
         
         
    end

%% update cluster
    function updatecluster(eo,ed)
        % let's also autofix
        autofixcallback;
        % only update cluster has writing privelege to SPKcurr        
        % this labels the spikes with A, B or noise
        % this is copied from autosort....
        close(hmc)
        figure(fig)
        SPKAcurr = SPKcurr*0;
        SPKBcurr = SPKcurr*0;             
        SPKAcurr(ind(IS==1))= SPKcurr(ind(IS==1));
        SPKBcurr(ind(IS==2))= SPKcurr(ind(IS==2));        
        
        SPKcurr(ind(IS==3))=0; % bug fix here
        % recompute ind
        ind = find(SPKcurr < 0);
        IS(IS==3) =[];
        % update the main plot
        pSPKAcurr = SPKAcurr; pSPKBcurr = SPKBcurr; pSPKAcurr(SPKAcurr == 0) = NaN; pSPKBcurr(SPKBcurr ==0) =NaN;
        plot(ax, time, Vcurr, 'k', time, pSPKAcurr, '.r', time, pSPKBcurr, '.b')
        clear pSPKAcurr pSPKBcurr
        axes(ax)
        plotstim;
        
        if any(SPKAcurr<0)
            tSPKA(currdata(1), currdata(2),1:sum(SPKAcurr<0))=find(SPKAcurr<0);
            tSPKA(currdata(1), currdata(2),sum(SPKAcurr<0)+1:end)=0;
        else
            tSPKA(currdata(1), currdata(2),:)=0;
        end
        if any(SPKBcurr<0)
            tSPKB(currdata(1), currdata(2),1:sum(SPKBcurr<0))=find(SPKBcurr<0);
            tSPKB(currdata(1), currdata(2),sum(SPKBcurr<0)+1:end)=0;
        else
            tSPKB(currdata(1), currdata(2),:)=0;
        end
        tracedone(currdata(1),currdata(2))=1;
        fileout_name = get(getfilenameout, 'String');
        save([file_path fileout_name], 'tSPKA', 'tSPKB', 'deltat', 'tracedone', 'SPKcountA', 'SPKcountB');
        clear abs_S
        
      
    end

%% plot rectangles for stimulus on/off function
    function plotstim(eo,ed)
        goon = 1;
        % currdata is a 2-element vector which has the current experiment
%         % (1) and the current trial (2)
        if isempty(svalve)
            disp('Cant plot Stimulus, I dont have the data.')
            return
        end
        try
            ton = svalve(currdata(1),currdata(2)).ton;
        catch ME1 
            if strcmp(ME1.message,'Index exceeds matrix dimensions.')
                disp('I cant plot the stimulus signal for some reason. Maybe you are looking at blank data? Try going back in time')
                goon = 0;
            end
        end
        
        if goon == 0 || isempty(svalve(currdata(1),currdata(2)).ton)
            disp('I cant plot the stimulus signal for some reason. Maybe you are looking at blank data? Try going back in time')
            return
        end
        toff = svalve(currdata(1),currdata(2)).toff;
        if length(ton) == length(toff)
            
            if ton(1) < toff(1)
                % all OK
            else
                % padd both ends
                ton = vertcat(0,ton); toff = vertcat(toff,max(time));
                % chop off the last ton and the first toff
%                 toff(1) = []; ton(length(ton)) = []; % old code
            end
        elseif length(ton) > length(toff)
            % more tons than toffs
            if ton(1) < toff(1)
                % pad  last toff
                toff = vertcat(toff,max(time));
                
            else
                disp('Havent coded this case instance yet...')
                keyboard
            end
        elseif length(toff) > length(ton)
            % more toffs than tons
            if ton(1) < toff(1)
                disp('Havent coded this case instance yet...')
                keyboard
            else
                % ton(1) > toff(1), pad tons
                ton = vertcat(0,ton);
            end
        end
        
        % plot
        if length(toff) ~= length(ton)
            error('The last time this error happened, the lengths of ton and toff were very different. I fixed this by digitisting the stim signal, but apparently this problem is still there. ')
        end
        twidths = toff - ton;
        % there are always some artefacts with very large amplitude that
        % throw the plotstim. Instead of finding the max(Vcurr), which
        % includes these unknown artefacts, let's find the mean of the the
        % top 10%. -- CANCELLED. Too complex. 
        axes(ax);
        for i = 1:length(twidths)
            if twidths(i)>0 && max(Vcurr)>0
                rectangle('Position',[ton(i) max(Vcurr) twidths(i) max(Vcurr)/10],'FaceColor',[0.6 0.6 0.6],'EdgeColor',[1 1 1])
            end
        end
        
    end

%% the autosort call back -- this does PCA
    function autosortcallback(eo,ed)       
        if get(ampl_sort,'Value')
            % Aplitude sorting
            getdeltatcallback;
            S = [];        
            ind = find(SPKcurr<0);

            if any(find(ind>tr, 1)) % tr is a function of the refractory period. 
                ind(1:find(ind>tr, 1))=[];
            end
            if any(find(ind>length(SPKcurr)-tr-1))
                ind(find(ind>length(SPKcurr)-tr-1,1):end)=[];
            end
            amp = SPKcurr(ind);
            % find shapes for clustering
            dropV = zeros(1,length(ind));  % voltage difference to preceding maxima
            climbV = dropV; % voltage difference to next maxima
            for i=1:length(ind)
                S(i,:) = Vcurr(ind(i)-tr:ind(i)+tr-1);
                dbeforeV = diff(Vcurr(max(1,ind(i) - 50):ind(i)));
                dafterV = diff(Vcurr(ind(i):min(length(Vcurr),50+ind(i))));
                % find last peak 

                lastpeak = Vcurr(ind(i) - find(dbeforeV>0,1,'last'));
                % find next peak
                nextpeak = Vcurr(ind(i) + find(dafterV<0,1,'first'));
                if isempty(lastpeak)
                    lastpeak = Vcurr(ind(i) - 50); % spike so broad we can't see the end of it
                end
                if isempty(nextpeak)
                    nextpeak = Vcurr(ind(i) + 50); % spike so broad we can't see the end of it
                end
                dropV(i) = lastpeak - S(i,26);
                climbV(i) = nextpeak - S(i,26);
            end
            [IS] = kmeans(vertcat(climbV,dropV)',3);
            figure, subplot(2,2,1), hold on, scatter(dropV(IS==1),climbV(IS==1),'.k'), hold on
            scatter(dropV(IS==2),climbV(IS==2),'.r')
            scatter(dropV(IS==3),climbV(IS==3),'.g')
            subplot(2,2,2), plot(S(IS==1,:)','k')
            subplot(2,2,3), plot(S(IS==2,:)','r')
            subplot(2,2,4), plot(S(IS==3,:)','g')
            warning('Incompelte code..')
            keyboard
        else
        % Shape sorting
     
        % SPKcurr is a vector as long as time, with zeros everywhere except
        % at the minima of spikes, where it takes the value of the minima.        
        ind = find(SPKcurr<0);       
        if any(find(ind>tr, 1)) % tr is a function of the refractory period. 
            ind(1:find(ind>tr, 1))=[];
        end
        if any(find(ind>length(SPKcurr)-tr-1))
            ind(find(ind>length(SPKcurr)-tr-1,1):end)=[];
        end
        amp = SPKcurr(ind);
        % find shapes for clustering
        for i=1:length(ind)
            S(i,:) = Vcurr(ind(i)-tr:ind(i)+tr-1);     
            % test: set minimum to zero in each case
            S(i,:) = S(i,:) - min(S(i,:));
        end
        % what's happened so far is that little segments around the time of
        % spike have been cut out, and are assembled into the matrix S
        numPC = str2num(get(PCnum, 'String'));
        [ans,PC] = princomp(S);
        K = str2num(get(Knum, 'String'));
        % let's attempt k-means now
        [IS] = kmeans(PC(:,1:numPC),K);

        % Carlotta's method, using pdist + cluster
%         Y = pdist(PC(:,1:numPC),'euclidean'); % pdist finds the distance between points on a matrix
%         Z = linkage(Y,'average');    % linkage creates a agglomerative hierarchical cluster tree      
%         IS = cluster(Z,'maxclust', K);
        
        K = max(IS); % it is always the same as the input, why is this here?
        disp(['K = ', num2str(K)])
        SPKAcurr = SPKcurr*0;
        SPKBcurr = SPKcurr*0;       

        for i = 1:K
            dmk = 0;
            for j = 1:length(S(1,:))
                mk(j) = mean(S(IS==i,j)); % this is the centroid of cluster i
                
                dmkA = dmk + (mk(j)-Ashape(j))^2; % this is the distance from the centroid
                dmkB = dmk + (mk(j)-Bshape(j))^2;
            end
            dmkA(i) = sqrt(dmkA);
            dmkB(i) = sqrt(dmkB);
            size_mk = sum(IS==i);
            display(['dmkA = ' num2str(dmkA(i)) ' dmkB = ' num2str(dmkB(i)) ' size_mk =  ' num2str(size_mk)]);
        end
        
        kA = IS(ind==Ax);
        SPKAcurr(ind(IS==kA))= SPKcurr(ind(IS==kA));
        kB = IS(ind==Bx);
        SPKBcurr(ind(IS==kB))= SPKcurr(ind(IS==kB));
        display(['KA = ' num2str(kA) ' KB = ' num2str(kB)])
        
        figure(222); subplot(1,2,1); hold on;
        plot(PC(:,1), PC(:,2), 'ok');
        plot(PC(IS==kA,1), PC(IS==kA,2), 'or', 'MarkerFaceColor', 'r');
        plot(PC(IS==kB,1), PC(IS==kB,2), 'ob', 'MarkerFaceColor', 'b');
        xlabel('PC1', 'fontsize', 24)
        ylabel('PC2', 'fontsize', 24)
        axis equal;
        subplot(1,2,2); hold on;
        plot(S', 'k');
        plot(S(IS==kA,:)', 'r');
        plot(S(IS==kB,:)', 'b');
        
        for i=1:K
            if (i~=kA && i~=kB)
                SPKcurr(ind(IS==i))=0;
            end
        end
        pSPKAcurr = SPKAcurr; pSPKBcurr = SPKBcurr; pSPKAcurr(SPKAcurr == 0) = NaN; pSPKBcurr(SPKBcurr ==0) =NaN;
        plot(ax, time, Vcurr, 'k', time, pSPKAcurr, '.r', time, pSPKBcurr, '.b')
        plotstim;
        if any(SPKAcurr<0)
            tSPKA(currdata(1), currdata(2),1:sum(SPKAcurr<0))=find(SPKAcurr<0);
            tSPKA(currdata(1), currdata(2),sum(SPKAcurr<0)+1:end)=0;
        else
            tSPKA(currdata(1), currdata(2),:)=0;
        end
        if any(SPKBcurr<0)
            tSPKB(currdata(1), currdata(2),1:sum(SPKBcurr<0))=find(SPKBcurr<0);
            tSPKB(currdata(1), currdata(2),sum(SPKBcurr<0)+1:end)=0;
        else
            tSPKB(currdata(1), currdata(2),:)=0;
        end
        tracedone(currdata(1),currdata(2))=1;
        fileout_name = get(getfilenameout, 'String');
        save([file_path fileout_name], 'tSPKA', 'tSPKB', 'deltat', 'tracedone', 'SPKcountA', 'SPKcountB');
        axes(ax) % fixed a bug where stimulus would be plotted on 
        plotstim;
        clear abs_S S clear IS
        end
    end
%% count call back
    function countcallback(eo,ed)    
        lengthcount = str2num(get(getlengthcount, 'String'));
        if get(countmode, 'value')
            startcount = find(SPKAcurr(round(startcount/deltat):end)<0,1) + round(startcount/deltat)-1;
        else startcount = round(str2double(get(getstimon, 'String'))/deltat);
        end
        SPKcountA(currdata(1),currdata(2)) = sum(SPKAcurr(startcount:startcount + lengthcount/deltat)<0)/lengthcount;
        set(textcountA, 'String', ['A = ' num2str(SPKcountA(currdata(1),currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
        SPKcountB(currdata(1),currdata(2)) = sum(SPKBcurr(startcount:startcount + lengthcount/deltat)<0)/lengthcount;
        set(textcountB, 'String', ['B = ' num2str(SPKcountB(currdata(1),currdata(2))) ' spk/sec'],'FontSize',12,'FontWeight','bold');
    end
%% done call back
    function donecallback(eo,ed)
        if get(thnoise, 'Value')==1
                mode = 1;
        elseif get(thA,'Value')==1
            mode = 2;
        elseif get(modify,'Value')==1
            mode=3;
        end
%         if tlim == 1
%             mode = 3; % disabled in v6.6
%         end
        if mode==1 % noise mode
            THnoise(tlim:end)=THnoise(tlim-1);
            SPKcurr(SPKcurr>THnoise)=0;
            pSPKcurr = SPKcurr; pSPKcurr(SPKcurr==0) = NaN;
            plot(ax, time, Vcurr, 'k', time, pSPKcurr, '.r')
            plotstim;
            tlim = 1;
            THnoise = zeros(L,1);
        end
        if mode==2           
            THA(tlim:end)=THA(tlim-1);
            SPKAcurr = SPKcurr;
            SPKBcurr = SPKcurr;
            SPKAcurr(SPKcurr>THA)=0;
            SPKBcurr(SPKcurr<THA)=0;
            pSPKAcurr = SPKAcurr; pSPKBcurr = SPKBcurr; pSPKAcurr(SPKAcurr == 0) = NaN; pSPKBcurr(SPKBcurr ==0) =NaN;
            plot(ax, time, Vcurr, 'k', time, pSPKAcurr, '.r', time, pSPKBcurr, '.b')  
            plotstim;
            if any(SPKAcurr<0)
                tSPKA(currdata(1), currdata(2),1:sum(SPKAcurr<0))=find(SPKAcurr<0);
                tSPKA(currdata(1), currdata(2),sum(SPKAcurr<0)+1:end)=0;         
            else
                tSPKA(currdata(1), currdata(2),:)=0;
            end
            if any(SPKBcurr<0)
                tSPKB(currdata(1), currdata(2),1:sum(SPKBcurr<0))=find(SPKBcurr<0);
                tSPKB(currdata(1), currdata(2),sum(SPKBcurr<0)+1:end)=0;         
            else
                tSPKB(currdata(1), currdata(2),:)=0;
            end          
            tracedone(currdata(1),currdata(2))=1;
            fileout_name = get(getfilenameout, 'String');
            save([file_path fileout_name], 'tSPKA', 'tSPKB', 'deltat', 'tracedone', 'SPKcountA', 'SPKcountB');
            tlim = 1;
            THA = zeros(L,1);
        end
        if mode==3
            tSPKA(currdata(1), currdata(2),1:sum(SPKAcurr<0))=find(SPKAcurr<0);
            tSPKB(currdata(1), currdata(2),1:sum(SPKBcurr<0))=find(SPKBcurr<0);
            tSPKA(currdata(1), currdata(2),sum(SPKAcurr<0)+1:end)=0;
            tSPKB(currdata(1), currdata(2),sum(SPKBcurr<0)+1:end)=0;
            tracedone(currdata(1),currdata(2))=1;
            fileout_name = get(getfilenameout, 'String');
            save([file_path fileout_name], 'tSPKA', 'tSPKB', 'deltat', 'tracedone', 'SPKcountA', 'SPKcountB');
        end
    end

    function redocallback(eo,ed)
       tracedone(currdata(1),currdata(2))=0;
       Vcurr = squeeze(V(currdata(1), currdata(2),:));
       pidcurr = squeeze(pid(currdata(1), currdata(2),:));
       plot(ax, time, Vcurr, 'k');
       plotstim;
       set(findmin,'Enable','on');
       plot(ax2, time(1:10:end), pidcurr(1:10:end), 'k');
    end

    function undocallback(eo,ed)
        xlimit = get(ax, 'xlim');
        ylimit = get(ax, 'ylim');
        SPKAcurr = SPKAtemp;
        SPKBcurr = SPKBtemp;
        SPKcurr = SPKtemp;
        pSPKAcurr = SPKAcurr; pSPKBcurr = SPKBcurr; pSPKAcurr(SPKAcurr == 0) = NaN; pSPKBcurr(SPKBcurr ==0) =NaN;
        plot(ax, time, Vcurr, 'k', time, pSPKAcurr, '.r', time, pSPKBcurr, '.b')
        xlim(xlimit);
        ylim(ylimit);
        plotstim;
    end
        
    function replot_tracedone(h)
        SPKAcurr = zeros(L,1);
        SPKBcurr = zeros(L,1);
        Vcurr = butter_filter(Vcurr, 70, 1000, deltat, 1, 3);
        tSP = tSPKA(currdata(1),currdata(2),:);
        tSP(tSP==0)=[];
        SPKAcurr(tSP)=Vcurr(tSP);
        tSP = tSPKB(currdata(1),currdata(2),:);
        tSP(tSP==0)=[];
        SPKBcurr(tSP)=Vcurr(tSP);
        pSPKAcurr = SPKAcurr; pSPKBcurr = SPKBcurr; pSPKAcurr(SPKAcurr == 0) = NaN; pSPKBcurr(SPKBcurr ==0) =NaN;
        plot(h, time, Vcurr, 'k', time, pSPKAcurr, '.r', time, pSPKBcurr, '.b')
        plotstim;
        THnoise = zeros(L,1);
        THA = zeros(L,1);
        SPKcurr = SPKAcurr + SPKBcurr;
        set(findmin,'Enable','off')
        plot(ax2, time, pidcurr, 'k')
    end
%% raster plot   
    function rasterplotcallback(eo,ed)
        stimon = str2double(get(getstimon, 'String'));
        rastexp = get(setrasterexp, 'String');
        
        s = regexp(rastexp, '-', 'split');
        if strcmp(s(1), 'all')
            exptoplot = 1:numexp;
        else
            s_ = regexp(s{1}, ',', 'split');
            exptoplot = str2double(s_);
        end
        if strcmp(s(2), 'all')
            trialstoplot = 1:numtrials;
        else
            s_ = regexp(s{2}, ',', 'split');
            trialstoplot = str2double(s_);
        end
        
        if get(Araster, 'Value')
            neu = [1 0];
        else
            neu = [0 1];
        end
        figure; hold on;
        h = length(exptoplot)*(numtrials+1);
        area([0 stimon stimon (stimon+0.5) (stimon+0.5) 10], [0 0 h h 0 0], 'faceColor', [.85 .85 .85], 'edgeColor', [.85 .85 .85])
        nn=1;
        for i = exptoplot
            for t = trialstoplot
                if neu(1)
                    timesp = squeeze(tSPKA(i,t,:));
                else
                    timesp = squeeze(tSPKB(i,t,:));
                end
                timesp(timesp==0)=[];
                errorbar_raster(timesp*deltat, nn*ones(length(timesp),1),0.5*ones(length(timesp),1), 'k');
                nn=nn+1;
            end
            nn=nn+3;
        end
        ylim([0 nn-2])
%         axis off
    end
%% PSTH plot
    function PSTHplotcallback(eo,ed)
        stimon = str2double(get(getstimon, 'String'));
        PSTHexp = get(setPSTHexp, 'String');
        
        s = regexp(PSTHexp, '-', 'split');
        if strcmp(s(1), 'all')
            exptoplot = 1:numexp;
        else
            s_ = regexp(s{1}, ',', 'split');
            exptoplot = str2double(s_);
        end
        if strcmp(s(2), 'all')
            trialstoplot = 1:numtrials;
        else
            s_ = regexp(s{2}, ',', 'split');
            trialstoplot = str2double(s_);
        end
        
        if get(APSTH, 'Value')
            neu = [1 0];
        else
            neu = [0 1];
        end
        win = str2num(get(getbin, 'String'));
        sliding = str2num(get(getslid, 'String'));
        maxtime = (L*deltat)+1; %seconds
        sr = [];
        jj=0;
        for i = exptoplot
            jj=jj+1;
            zz = 0;
            for t = trialstoplot
                zz = zz+1;
                if neu(1)
                    timesp = squeeze(tSPKA(i,t,:));
                else
                    timesp = squeeze(tSPKB(i,t,:));
                end
                timesp(timesp==0)=[];
                spk = spiketime2spk(timesp',maxtime/deltat);
                [timesr sr(jj,zz,:)] = spike_rate(spk', deltat, win, sliding);
            end
        end
        figure; hold on;
        msr = zeros(numexp, length(sr));
        ser = zeros(numexp, length(sr));
        area([0 stimon stimon (stimon+0.5) (stimon+0.5) 10], [0 0 240 240 0 0], 'faceColor', [.85 .85 .85],'edgeColor', [.85 .85 .85])
        spkrate_clr = [{'k'},{'r'},{'b'},{'g'},{'c'},{'m'},{'--k'},{'--r'},{'--b'},{'--g'},{'--c'},{'--m'},{'ok'},{'or'},{'ob'},{'og'},{'oc'},{'om'}];
        for dil=1:length(exptoplot)
            SR = squeeze(sr(dil,:,:));
            jj=0;
            for t=1:size(SR,1)
                if any(SR(t,:))
                    jj=jj+1;
                    good(jj) = t;
                end
            end
            msr(dil, :) = mean(SR(good,:));
            ser(dil, :) = std(SR(good,:))/sqrt(length(good));
            errorbar(timesr, msr(dil,:), ser(dil,:), spkrate_clr{dil});
        end
        ylim([0 max(max(msr))+30])
%         xlim([0 4])
        clear good
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % this part extracts the spike rates and puts them on workspace
                if neu(1)
                    msrA = msr;
                    serA = ser;
                    srA = sr;
                    warning('off','putvar:overwrite')
                    putvar(msrA);
                    putvar(serA);
                    putvar(timesr);
                    putvar(srA);
                else
                    msrB = msr;
                    serB = ser;
                    srB = sr;
                    warning('off','putvar:overwrite')
                    putvar(msrB);
                    putvar(serB);
                    putvar(timesr);
                    putvar(srB);
                end

    end

%% PSTH plot
    function savecurrplotcallback(eo,ed)
        figure(111);
        SPKAcurr = zeros(L,1);
        SPKBcurr = zeros(L,1);
%         Vcurr = butter_filter(Vcurr, 70, 1000, deltat, 1, 3);
        tSP = tSPKA(currdata(1),currdata(2),:);
        tSP(tSP==0)=[];
        SPKAcurr(tSP)=Vcurr(tSP);
        tSP = tSPKB(currdata(1),currdata(2),:);
        tSP(tSP==0)=[];
        SPKBcurr(tSP)=Vcurr(tSP);
        pSPKAcurr = SPKAcurr; pSPKBcurr = SPKBcurr; pSPKAcurr(SPKAcurr == 0) = NaN; pSPKBcurr(SPKBcurr ==0) =NaN;
        subplot(2,1,2)
        plot(time, Vcurr, 'k', time, pSPKAcurr, '.r', time, pSPKBcurr, '.b')
        subplot(2,1,1)
        plot(time, pidcurr, 'k')        
    end
end


