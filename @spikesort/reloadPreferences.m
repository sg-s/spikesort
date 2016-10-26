function reloadPreferences(s,~,~)

s.pref = readPref(fileparts(fileparts(which(mfilename))));
    