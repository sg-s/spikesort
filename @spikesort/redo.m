function redo(s,~,~)

if s.verbosity > 5
    cprintf('green','\n[INFO] ')
    cprintf('text',[mfilename ' called'])
end

s.A = [];
s.B = [];
s.N = [];
s.use_this_fragment = [];

s.plotResp;

s.saveData;
