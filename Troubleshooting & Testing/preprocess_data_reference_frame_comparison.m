function data = preprocess_data_reference_frame_comparison(data)

legs = {'L1', 'L2', 'L3', 'R1', 'R2', 'R3'};
jointLetters = {'A', 'B', 'C', 'D', 'E'};
numLegs = 6;
numJoints = 4; 

%Fix Anipose joint output
for leg = 1:numLegs
    % In Anipose output, A_abduct and A_flex are flipped. Swap them back.
    temp = data.([legs{leg} 'A_abduct']);
    data.([legs{leg} 'A_abduct']) = data.([legs{leg} 'A_flex']);
    data.([legs{leg} 'A_flex']) = temp;
    
    % In Anipose output, C_flex is negative. Take absolute value of C_flex
    data.([legs{leg} 'C_flex']) = abs(data.([legs{leg} 'C_flex']));

    
    for joint = 1:numJoints
        % Sometimes flexion data has a wrap around, so if any flex angles are negative, add 360. 
        temp = data.([legs{leg} '' jointLetters{joint} '_flex']);
        idxs = find(temp < 0); %idxs of negative joint angles
        temp(idxs) = temp(idxs) + 360;
        data.([legs{leg} '' jointLetters{joint} '_flex']) = temp;

        % Fix the jumps in rotation angles (note: this makes raw values meaningless, it's all about derivative of rotation angles.)
        if joint < numJoints %TiTa joint does not rotate
            wrapped = data.([legs{leg} '' jointLetters{joint} '_rot']);
            unwrapped = unwrap(wrapped, 160);
            data.([legs{leg} '' jointLetters{joint} '_rot_unwrapped']) = unwrapped;
        end
    end
    
end


end