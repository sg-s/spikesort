function reloadPreferences(s,~,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

s.pref = readPref(fileparts(fileparts(which(mfilename))));
    