function [data, walkingData] = fixFictracOutput(data, walkingData, flyList)
% Shift the rotation and sideslip velocities for each fly to center 'forward' walking. 
% Assume that overall flies walk evenly left and right. Shift the sideslip and velocity 
% vectors by their means while the fly is walking. 
% 
% Sarah Walling-Bell
% October 2022

%get unique flies, important for WT Berlin data
flies = {};
for f = 1:height(flyList)
    flies{f} = flyList.flyid{f}(1:end-2);
end
flies = unique(flies);

%normalize rotation and sideslip by avg per fly 
for fly = 1:width(flies)
    walking_fly_idxs = contains(walkingData.flyid, flies{fly});
    data_fly_idxs = contains(data.flyid, flies{fly});

    walking_rotation_data = walkingData.fictrac_delta_rot_lab_z_mms(walking_fly_idxs); 
    walking_sideslip_data = walkingData.fictrac_delta_rot_lab_x_mms(walking_fly_idxs); 
    
    mean_rotation = mean(walking_rotation_data, 'omitnan');
    mean_sideslip = mean(walking_sideslip_data, 'omitnan');

    %normalize walkingData and data
    data.fictrac_delta_rot_lab_z_mms(data_fly_idxs) = data.fictrac_delta_rot_lab_z_mms(data_fly_idxs) - mean_rotation;
    data.fictrac_delta_rot_lab_x_mms(data_fly_idxs) = data.fictrac_delta_rot_lab_x_mms(data_fly_idxs) - mean_sideslip;

    walkingData.fictrac_delta_rot_lab_z_mms(walking_fly_idxs) = walkingData.fictrac_delta_rot_lab_z_mms(walking_fly_idxs) - mean_rotation;
    walkingData.fictrac_delta_rot_lab_x_mms(walking_fly_idxs) = walkingData.fictrac_delta_rot_lab_x_mms(walking_fly_idxs) - mean_sideslip;

end



end