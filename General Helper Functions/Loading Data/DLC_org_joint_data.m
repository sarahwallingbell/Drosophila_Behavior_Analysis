function joint_data = DLC_org_joint_data(data, param)

% Organizes data for plotting. 
% Input the data from a parquet file and the param variable. 
% Output is joint_data which contains the data organized by leg, laser, and joint
% 
% S Walling-Bell, University of Washington, 2021 - updated 2022


vid = cell(1,param.numLasers); vid(:) = {0};
for fly = 1:height(param.flyList) 
    %isolate the data for this fly 
    date_data = data(strcmp(data.date_parsed, param.flyList{fly,2}), :); 
    fly_data = date_data(strcmp(date_data.fly, param.flyList{fly,1}), :);  
    for rep = 1:param.numReps
        %isolate data for this rep
        rep_data = fly_data((fly_data.rep == rep),:);
        for cond = 1:param.numConds    
            %isolate data for this condition (arena + laser lenght)
            cond_data = rep_data((rep_data.condnum == cond),:);
            %I'm not separating data by arena condition, so find just the laser_length 
            laser_num = param.laserIdx(cond);
            vid{laser_num} = vid{laser_num}+1; 
%             joint = find(strcmp(param.columns, 'L1_BC')); %first 
%             joint = find(strcmp(param.columns, 'L1A_flex')); %first
            for legIdx = 1:width(param.legs)
                %joint angles (using ABCD joints, ot BCFTiTa joint vars)
                joint_data.leg(legIdx).laser(laser_num).BC.joint{:,vid{laser_num}} = cond_data.([param.legs{legIdx} param.jointLetters{1} '_flex']);
                joint_data.leg(legIdx).laser(laser_num).CF.joint{:,vid{laser_num}} = cond_data.([param.legs{legIdx} param.jointLetters{2} '_flex']);
                joint_data.leg(legIdx).laser(laser_num).FTi.joint{:,vid{laser_num}} = cond_data.([param.legs{legIdx} param.jointLetters{3} '_flex']);
                joint_data.leg(legIdx).laser(laser_num).TiTa.joint{:,vid{laser_num}} = cond_data.([param.legs{legIdx} param.jointLetters{4} '_flex']);

%                 joint_data.leg(legIdx).laser(laser_num).BC.joint{:,vid{laser_num}} = cond_data{:,joint}; joint = joint+1;
%                 joint_data.leg(legIdx).laser(laser_num).CF.joint{:,vid{laser_num}} = cond_data{:,joint}; joint = joint+1;
%                 joint_data.leg(legIdx).laser(laser_num).FTi.joint{:,vid{laser_num}} = cond_data{:,joint}; joint = joint+1;
%                 joint_data.leg(legIdx).laser(laser_num).TiTa.joint{:,vid{laser_num}} = cond_data{:,joint}; joint = joint+1;

                %joint angle changes
                joint_data.leg(legIdx).laser(laser_num).BC.change{:,vid{laser_num}} = diff(joint_data.leg(legIdx).laser(laser_num).BC.joint{:,vid{laser_num}});
                joint_data.leg(legIdx).laser(laser_num).CF.change{:,vid{laser_num}} = diff(joint_data.leg(legIdx).laser(laser_num).CF.joint{:,vid{laser_num}});
                joint_data.leg(legIdx).laser(laser_num).FTi.change{:,vid{laser_num}} = diff(joint_data.leg(legIdx).laser(laser_num).FTi.joint{:,vid{laser_num}});
                joint_data.leg(legIdx).laser(laser_num).TiTa.change{:,vid{laser_num}} = diff(joint_data.leg(legIdx).laser(laser_num).TiTa.joint{:,vid{laser_num}});
                            
                if param.filter  %filter out data that moves too much 
                   if any(abs(joint_data.leg(legIdx).laser(laser_num).BC.change{:,vid{laser_num}}(:)) > param.filterThresh)
                       % if angle changes to fast, replace data with NaNs.
                       joint_data.leg(legIdx).laser(laser_num).BC.joint{:,vid{laser_num}} = NaN(1, height(cond_data));
                       joint_data.leg(legIdx).laser(laser_num).BC.change{:,vid{laser_num}} = NaN(1, (height(cond_data)-1));
                   end
                   if any(abs(joint_data.leg(legIdx).laser(laser_num).CF.change{:,vid{laser_num}}(:)) > param.filterThresh)
                       joint_data.leg(legIdx).laser(laser_num).CF.joint{:,vid{laser_num}} = NaN(1, height(cond_data));
                       joint_data.leg(legIdx).laser(laser_num).CF.change{:,vid{laser_num}} = NaN(1, (height(cond_data)-1));
                   end
                   if any(abs(joint_data.leg(legIdx).laser(laser_num).FTi.change{:,vid{laser_num}}(:)) > param.filterThresh)
                       joint_data.leg(legIdx).laser(laser_num).FTi.joint{:,vid{laser_num}} = NaN(1, height(cond_data));
                       joint_data.leg(legIdx).laser(laser_num).FTi.change{:,vid{laser_num}} = NaN(1, (height(cond_data)-1));
                    end
                   if any(abs(joint_data.leg(legIdx).laser(laser_num).TiTa.change{:,vid{laser_num}}(:)) > param.filterThresh)
                       joint_data.leg(legIdx).laser(laser_num).TiTa.joint{:,vid{laser_num}} = NaN(1, height(cond_data));
                       joint_data.leg(legIdx).laser(laser_num).TiTa.change{:,vid{laser_num}} = NaN(1, (height(cond_data)-1));
                   end
                end
            end
        end
    end
end

end