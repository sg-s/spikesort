% clears all the current data, in anticipation of new data from disk

function s = clearCurrentData(s)

s.R  = [];  % this holds the dimensionality reduced data
s.filtered_voltage = []; % holds the current trace that is shown on screen
s.raw_voltage = [];
s.LFP = [];
s.V_snippets = [];% matrix of snippets around spike peaks
s.time  = [];% vector of timestamps
s.loc  = [];% holds current spike times

s.stimulus = [];
s.control_signals = [];

