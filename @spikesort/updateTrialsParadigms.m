function [] = updateTrialsParadigms(s,src,~)

switch src 
case s.handles.next_paradigm
	s.this_paradigm = s.this_paradigm + 1;
case s.handles.prev_paradigm
	s.this_paradigm = s.this_paradigm - 1;
case s.handles.next_trial
	s.this_trial = s.this_trial + 1;
case s.handles.prev_trial
	s.this_trial = s.this_trial - 1;
end
