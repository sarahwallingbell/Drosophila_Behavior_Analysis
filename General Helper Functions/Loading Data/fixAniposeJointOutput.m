function data = fixAniposeJointOutput(data, param, flyList)

% Some of the joint data output by Anipose needs altering before use. 
% Main changes are:
%     1) In Anipose output, A_abduct and A_flex are flipped. Swap them back.
%     2) In Anipose output, C_flex is negative. Take absolute value of C_flex
%     3) Sometimes flexion data has a wrap around, so if any flex angles are negative, add 360. 
%     4) Fix the jumps in rotation angles (note: this makes raw values meaningless, it's all about derivative of rotation angles.)
%     5) Change position units to body length proxy: L1 coxa length (per fly)
% 
% Sarah Walling-Bell
% October 2022




%Fix Anipose joint output
for leg = 1:param.numLegs
    % In Anipose output, A_abduct and A_flex are flipped. Swap them back.
    temp = data.([param.legs{leg} 'A_abduct']);
    data.([param.legs{leg} 'A_abduct']) = data.([param.legs{leg} 'A_flex']);
    data.([param.legs{leg} 'A_flex']) = temp;
    
    % In Anipose output, C_flex is negative. Take absolute value of C_flex
    data.([param.legs{leg} 'C_flex']) = abs(data.([param.legs{leg} 'C_flex']));

    
    for joint = 1:param.numJoints
        % Sometimes flexion data has a wrap around, so if any flex angles are negative, add 360. 
        temp = data.([param.legs{leg} '' param.jointLetters{joint} '_flex']);
        idxs = find(temp < 0); %idxs of negative joint angles
        temp(idxs) = temp(idxs) + 360;
        data.([param.legs{leg} '' param.jointLetters{joint} '_flex']) = temp;

        % Fix the jumps in rotation angles (note: this makes raw values meaningless, it's all about derivative of rotation angles.)
        if joint < param.numJoints %TiTa joint does not rotate
            wrapped = data.([param.legs{leg} '' param.jointLetters{joint} '_rot']);
            unwrapped = unwrap(wrapped, 160);
            data.([param.legs{leg} '' param.jointLetters{joint} '_rot_unwrapped']) = unwrapped;
        end
    end
    
end

% Change position units to body length proxy: L1 coxa length (per fly)
dims = {'x', 'y', 'z'};
for fly = 1:height(flyList)
    idx = find(contains(data.flyid, flyList.flyid{fly}), 1, 'first'); %first frame of this fly
    L1_coxa_length = pdist2([data.L1A_x(idx), data.L1A_y(idx), data.L1A_z(idx)], [data.L1B_x(idx), data.L1B_y(idx), data.L1B_z(idx)]);
    
    %adjust position data to be in 'coxa lengths'
    idxs = find(contains(data.flyid, flyList.flyid{fly})); %all frames of this fly;
    for leg = 1:param.numLegs
        for jnt = 1:width(param.jointLetters)
            for dim = 1:width(dims)
                data.([param.legs{leg} param.jointLetters{jnt} '_' dims{dim}])(idxs) = ...
                    data.([param.legs{leg} param.jointLetters{jnt} '_' dims{dim}])(idxs)/L1_coxa_length;
            end
        end
    end

end



