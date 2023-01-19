function data = addStimRegions(data, param)
% Add a column to data showing when the laser is on (1) and off (0).
% Sarah Walling-Bell, Oct 2022
% University of Washington

vidStarts = find(data.fnum == 0);
% vidEnds = [vidStarts(2:end)-1; height(data)];

data.stim = zeros(height(data), 1); 
for vid = 1:height(vidStarts)
    stim = data.stimlen(vidStarts(vid));
    if stim > 0
        idxs = vidStarts(vid)+param.laser_on-1 : vidStarts(vid)+param.laser_on+(stim*param.fps)-1; 
        data.stim(idxs) = 1; 
    end
end
    
end