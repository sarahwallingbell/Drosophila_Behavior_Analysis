function joint_data = DLC_org_joint_data_byFly(data, param)

% same as DLC_org_joint_data except the data for each fly is separated
% for plotting data of individual flies. 

for fly = 1:height(param.flyList) 
    vid = cell(1,param.numLasers); vid(:) = {0};
    date_data = data(strcmp(data.date_parsed, param.flyList{fly,2}), :);
    fly_data = date_data(strcmp(date_data.fly, param.flyList{fly,1}), :);  
    joint_data.meta(fly).date = param.flyList{fly,2};
    joint_data.meta(fly).fly = param.flyList{fly,1};
    for rep = 1:param.numReps
        rep_data = fly_data((fly_data.rep == rep),:);
        for cond = 1:param.numConds    
            cond_data = rep_data((rep_data.condnum == cond),:);
            laser_num = param.laserIdx(cond);
            vid{laser_num} = vid{laser_num}+1;
%             joint = find(strcmp(param.columns, 'L1_BC'));
            for legIdx = 1:width(param.legs)
                
                %joint angles (using ABCD joints, ot BCFTiTa joint vars)
                joint_data.fly(fly).leg(legIdx).laser(laser_num).BC.joint{:,vid{laser_num}} = cond_data.([param.legs{legIdx} param.jointLetters{1} '_flex']);
                joint_data.fly(fly).leg(legIdx).laser(laser_num).CF.joint{:,vid{laser_num}} = cond_data.([param.legs{legIdx} param.jointLetters{2} '_flex']);
                joint_data.fly(fly).leg(legIdx).laser(laser_num).FTi.joint{:,vid{laser_num}} = cond_data.([param.legs{legIdx} param.jointLetters{3} '_flex']);
                joint_data.fly(fly).leg(legIdx).laser(laser_num).TiTa.joint{:,vid{laser_num}} = cond_data.([param.legs{legIdx} param.jointLetters{4} '_flex']);
                 
%                 joint_data.fly(fly).leg(legIdx).laser(laser_num).BC.joint{:,vid{laser_num}} = cond_data{:,joint}; joint = joint+1;
%                 joint_data.fly(fly).leg(legIdx).laser(laser_num).CF.joint{:,vid{laser_num}} = cond_data{:,joint}; joint = joint+1;
%                 joint_data.fly(fly).leg(legIdx).laser(laser_num).FTi.joint{:,vid{laser_num}} = cond_data{:,joint}; joint = joint+1;
%                 joint_data.fly(fly).leg(legIdx).laser(laser_num).TiTa.joint{:,vid{laser_num}} = cond_data{:,joint}; joint = joint+1;

                %joint angle changes
                joint_data.fly(fly).leg(legIdx).laser(laser_num).BC.change{:,vid{laser_num}} = diff(joint_data.fly(fly).leg(legIdx).laser(laser_num).BC.joint{:,vid{laser_num}});
                joint_data.fly(fly).leg(legIdx).laser(laser_num).CF.change{:,vid{laser_num}} = diff(joint_data.fly(fly).leg(legIdx).laser(laser_num).CF.joint{:,vid{laser_num}});
                joint_data.fly(fly).leg(legIdx).laser(laser_num).FTi.change{:,vid{laser_num}} = diff(joint_data.fly(fly).leg(legIdx).laser(laser_num).FTi.joint{:,vid{laser_num}});
                joint_data.fly(fly).leg(legIdx).laser(laser_num).TiTa.change{:,vid{laser_num}} = diff(joint_data.fly(fly).leg(legIdx).laser(laser_num).TiTa.joint{:,vid{laser_num}});
%                             
            end
        end
    end
end

end