function stimRegions = DLC_getStimRegions(data, param)
    %given the data loaded from parquet files, return an array indicating
    %for every frame in the data structure if the laser is on (1) or off (0)
    
    stimRegions = zeros(height(data), 1);
    
    vidIndices = find(data.fnum == 0);
    for vid = 1:height(vidIndices)
       this_vid_start = vidIndices(vid);
       if data.stimlen(this_vid_start) > 0
          %change portion of stimRegions to 1 where stim is on
          temp_laser = zeros(param.vid_len_f+1, 1);
          laser_len_f = data.stimlen(this_vid_start)*param.fps;
          temp_laser(param.laser_on:param.laser_on+round(laser_len_f)) = 1;
          stimRegions(this_vid_start:this_vid_start+param.vid_len_f) = temp_laser;
       end
    end

end