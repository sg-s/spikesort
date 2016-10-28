
function modify(s,p)

% compatability layer
spikes = s.current_data.spikes;
A = spikes.A;
B = spikes.B;
V = s.filtered_voltage;

% check that the point is within the axes
ylimits = get(s.handles.ax1,'YLim');
if p(2) > ylimits(2) || p(2) < ylimits(1)
    % console('Rejecting point: Y exceeded')
    return
end
xlimits = get(s.handles.ax1,'XLim');
if p(1) > xlimits(2) || p(1) < xlimits(1)
    % console('Rejecting point: X exceeded')
    return
end

p(1) = p(1)/s.pref.deltat;
xrange = (xlimits(2) - xlimits(1))/s.pref.deltat;
yrange = ylimits(2) - ylimits(1);
% get the width over which to search for spikes dynamically from the zoom factor
search_width = floor((.005*xrange));
if get(s.handles.mode_new_A,'Value') == 1
    % snip out a small waveform around the point
    if s.pref.invert_V
        [~,loc] = min(V(floor(p(1)-search_width:p(1)+search_width)));
    else
        [~,loc] = max(V(floor(p(1)-search_width:p(1)+search_width)));
    end
    spikes(s.this_paradigm).A(s.this_trial,-search_width+loc+floor(p(1))) = 1;
    A = find(spikes(s.this_paradigm).A(s.this_trial,:));
    spikes(s.this_paradigm).amplitudes_A(s.this_trial,A) = s.spikeAmplitudes(V,A);
elseif get(s.handles.mode_new_B,'Value')==1
    % snip out a small waveform around the point
    if s.pref.invert_V
        [~,loc] = min(V(floor(p(1)-search_width:p(1)+search_width)));
    else
        [~,loc] = max(V(floor(p(1)-search_width:p(1)+search_width)));
    end
    spikes(s.this_paradigm).B(s.this_trial,-search_width+loc+floor(p(1))) = 1;
    B = find(spikes(s.this_paradigm).B(s.this_trial,:));
    spikes(s.this_paradigm).amplitudes_B(s.this_trial,B) = s.spikeAmplitudes(V,B);
elseif get(s.handles.mode_delete,'Value') == 1
    % find the closest spike
    Aspiketimes = find(spikes(s.this_paradigm).A(s.this_trial,:));
    Bspiketimes = find(spikes(s.this_paradigm).B(s.this_trial,:));

    dA = (((Aspiketimes-p(1))/(xrange)).^2  + ((V(Aspiketimes) - p(2))/(5*yrange)).^2);
    dB = (((Bspiketimes-p(1))/(xrange)).^2  + ((V(Bspiketimes) - p(2))/(5*yrange)).^2);
    dist_to_A = min(dA);
    dist_to_B = min(dB);
    if dist_to_A < dist_to_B
        [~,closest_spike] = min(dA);
        spikes(s.this_paradigm).A(s.this_trial,Aspiketimes(closest_spike)) = 0;
        spikes(s.this_paradigm).N(s.this_trial,Aspiketimes(closest_spike)) = 1;
        A = find(spikes(s.this_paradigm).A(s.this_trial,:));
        spikes(s.this_paradigm).amplitudes_A(s.this_trial,A) = s.spikeAmplitudes(V,A);
    else
        [~,closest_spike] = min(dB);
        spikes(s.this_paradigm).B(s.this_trial,Bspiketimes(closest_spike)) = 0;
        spikes(s.this_paradigm).N(s.this_trial,Aspiketimes(closest_spike)) = 1;
        B = find(spikes(s.this_paradigm).B(s.this_trial,:));
        spikes(s.this_paradigm).amplitudes_B(s.this_trial,B) = s.spikeAmplitudes(V,B);
    end
elseif get(s.handles.mode_A2B,'Value') == 1 
    % find the closest A spike
    Aspiketimes = find(spikes(s.this_paradigm).A(s.this_trial,:));
    dA = (((Aspiketimes-p(1))/(xrange)).^2 + ((V(Aspiketimes) - p(2))/(5*yrange)).^2);
    [~,closest_spike] = min(dA);
    spikes(s.this_paradigm).A(s.this_trial,Aspiketimes(closest_spike)) = 0;
    spikes(s.this_paradigm).B(s.this_trial,Aspiketimes(closest_spike)) = 1;
    A = find(spikes(s.this_paradigm).A(s.this_trial,:));
    spikes(s.this_paradigm).amplitudes_A(s.this_trial,A) = s.spikeAmplitudes(V,A);
    B = find(spikes(s.this_paradigm).B(s.this_trial,:));
    spikes(s.this_paradigm).amplitudes_B(s.this_trial,B) = s.spikeAmplitudes(V,B);

elseif get(s.handles.mode_B2A,'Value') == 1
    % find the closest B spike
    Bspiketimes = find(spikes(s.this_paradigm).B(s.this_trial,:));
    dB = (((Bspiketimes-p(1))/(xrange)).^2  + ((V(Bspiketimes) - p(2))/(5*yrange)).^2);
    [~,closest_spike] = min(dB);
    spikes(s.this_paradigm).A(s.this_trial,Bspiketimes(closest_spike)) = 1;
    spikes(s.this_paradigm).B(s.this_trial,Bspiketimes(closest_spike)) = 0;
    A = find(spikes(s.this_paradigm).A(s.this_trial,:));
    spikes(s.this_paradigm).amplitudes_A(s.this_trial,A) = s.spikeAmplitudes(V,A);
    B = find(spikes(s.this_paradigm).B(s.this_trial,:));
    spikes(s.this_paradigm).amplitudes_B(s.this_trial,B) = s.spikeAmplitudes(V,B);
end

s.current_data.spikes = spikes;

s.loc = s.loc;
s.A = A;
s.B = B;

