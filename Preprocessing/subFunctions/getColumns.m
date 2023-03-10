function columns = getColumns()
% Columns of parquet files. 
% Sarah Walling-Bell, October 2022

columns = {'L1_CF'	'L1_FTi'	'L1_TiTa'	'L2_CF'	'L2_FTi'	'L2_TiTa'	'L3_CF'	'L3_FTi'	'L3_TiTa'	'R1_CF'	'R1_FTi'	'R1_TiTa'	'R2_CF'	'R2_FTi'	... 
    'R2_TiTa'	'R3_CF'	'R3_FTi'	'R3_TiTa'	'L1_BC'	'L2_BC'	'L3_BC'	'R1_BC'	'R2_BC'	'R3_BC'	'L1A_flex'	'L1A_rot'	'L1A_abduct'	'L1B_flex'	... 
    'L1B_rot'	'L1C_flex'	'L1C_rot'	'L1D_flex'	'L2A_flex'	'L2A_rot'	'L2A_abduct'	'L2B_flex'	'L2B_rot'	'L2C_flex'	'L2C_rot'	'L2D_flex'	...
    'L3A_flex'	'L3A_rot'	'L3A_abduct'	'L3B_flex'	'L3B_rot'	'L3C_flex'	'L3C_rot'	'L3D_flex'	'R1A_flex'	'R1A_rot'	'R1A_abduct'	...
    'R1B_flex'	'R1B_rot'	'R1C_flex'	'R1C_rot'	'R1D_flex'	'R2A_flex'	'R2A_rot'	'R2A_abduct'	'R2B_flex'	'R2B_rot'	'R2C_flex'	'R2C_rot'	...
    'R2D_flex'	'R3A_flex'	'R3A_rot'	'R3A_abduct'	'R3B_flex'	'R3B_rot'	'R3C_flex'	'R3C_rot'	'R3D_flex'	'fnum'	'folder_1'	'filename'	...
    'project'	'fictrac_frame_counter'	'fictrac_delta_rot_cam_x'	'fictrac_delta_rot_cam_y'	'fictrac_delta_rot_cam_z'	'fictrac_delta_rot_score'	...
    'fictrac_delta_rot_lab_x'	'fictrac_delta_rot_lab_y'	'fictrac_delta_rot_lab_z'	'fictrac_sphere_orientation_cam_x'	...
    'fictrac_sphere_orientation_cam_y'	'fictrac_sphere_orientation_cam_z'	'fictrac_sphere_orientation_lab_x'	'fictrac_sphere_orientation_lab_y'	...
    'fictrac_sphere_orientation_lab_z'	'fictrac_int_x'	'fictrac_int_y'	'fictrac_heading'	'fictrac_inst_dir'	'fictrac_speed'	'fictrac_int_forward'	...
    'fictrac_int_side'	'fictrac_timestamp'	'fictrac_seqnumber'	'starts'	'fictrac_delta_rot_lab_x_mms'	'fictrac_delta_rot_lab_y_mms'	...
    'fictrac_delta_rot_lab_z_mms'	'fictrac_speed_mms'	'fictrac_inst_dir_deg'	'fictrac_heading_deg'	'fictrac_int_forward_mm'...
    'fictrac_int_side_mm'	'fictrac_int_x_mm'	'fictrac_int_y_mm'	'temp'	'vidname'	'framenum'	'fly'	'rep'	'cond'	'L1A_x'	'L1A_y'	'L1A_z'	...
    'L1A_error'	'L1A_ncams'	'L1A_score'	'L1B_x'	'L1B_y'	'L1B_z'	'L1B_error'	'L1B_ncams'	'L1B_score'	'L1C_x'	'L1C_y'	'L1C_z'	'L1C_error'	'L1C_ncams'	...
    'L1C_score'	'L1D_x'	'L1D_y'	'L1D_z'	'L1D_error'	'L1D_ncams'	'L1D_score'	'L1E_x'	'L1E_y'	'L1E_z'	'L1E_error'	'L1E_ncams'	'L1E_score'	'L2A_x'	'L2A_y'...
    'L2A_z'	'L2A_error'	'L2A_ncams'	'L2A_score'	'L2B_x'	'L2B_y'	'L2B_z'	'L2B_error'	'L2B_ncams'	'L2B_score'	'L2C_x'	'L2C_y'	'L2C_z'	'L2C_error'	...
    'L2C_ncams'	'L2C_score'	'L2D_x'	'L2D_y'	'L2D_z'	'L2D_error'	'L2D_ncams'	'L2D_score'	'L2E_x'	'L2E_y'	'L2E_z'	'L2E_error'	'L2E_ncams'	'L2E_score'	...
    'L3A_x'	'L3A_y'	'L3A_z'	'L3A_error'	'L3A_ncams'	'L3A_score'	'L3B_x'	'L3B_y'	'L3B_z'	'L3B_error'	'L3B_ncams'	'L3B_score'	'L3C_x'	'L3C_y'	'L3C_z'	...
    'L3C_error'	'L3C_ncams'	'L3C_score'	'L3D_x'	'L3D_y'	'L3D_z'	'L3D_error'	'L3D_ncams'	'L3D_score'	'L3E_x'	'L3E_y'	'L3E_z'	'L3E_error'	'L3E_ncams'	...
    'L3E_score'	'R1A_x'	'R1A_y'	'R1A_z'	'R1A_error'	'R1A_ncams'	'R1A_score'	'R1B_x'	'R1B_y'	'R1B_z'	'R1B_error'	'R1B_ncams'	'R1B_score'	'R1C_x'	'R1C_y'...
    'R1C_z'	'R1C_error'	'R1C_ncams'	'R1C_score'	'R1D_x'	'R1D_y'	'R1D_z'	'R1D_error'	'R1D_ncams'	'R1D_score'	'R1E_x'	'R1E_y'	'R1E_z'	'R1E_error'...
    'R1E_ncams'	'R1E_score'	'R2A_x'	'R2A_y'	'R2A_z'	'R2A_error'	'R2A_ncams'	'R2A_score'	'R2B_x'	'R2B_y'	'R2B_z'	'R2B_error'	'R2B_ncams'	'R2B_score'...
    'R2C_x'	'R2C_y'	'R2C_z'	'R2C_error'	'R2C_ncams'	'R2C_score'	'R2D_x'	'R2D_y'	'R2D_z'	'R2D_error'	'R2D_ncams'	'R2D_score'	'R2E_x'	'R2E_y'	'R2E_z'...
    'R2E_error'	'R2E_ncams'	'R2E_score'	'R3A_x'	'R3A_y'	'R3A_z'	'R3A_error'	'R3A_ncams'	'R3A_score'	'R3B_x'	'R3B_y'	'R3B_z'	'R3B_error'	'R3B_ncams'	...
    'R3B_score'	'R3C_x'	'R3C_y'	'R3C_z'	'R3C_error'	'R3C_ncams'	'R3C_score'	'R3D_x'	'R3D_y'	'R3D_z'	'R3D_error'	'R3D_ncams'	'R3D_score'	'R3E_x'	'R3E_y'...
    'R3E_z'	'R3E_error'	'R3E_ncams'	'R3E_score'	'M_00'	'M_01'	'M_02'	'M_10'	'M_11'	'M_12'	'M_20'	'M_21'	'M_22'	'center_0'	'center_1'	...
    'center_2'	'abdomen_grooming_prob'	'air_legs_prob'	'antennae_grooming_prob'	'ball_push_prob'	'ball_tapping_prob'	'crabwalking_prob'...
    'egg_laying_prob'	'head_eye_grooming_prob'	'mouth_grooming_prob'	'other_prob'	'postural_adjustment_prob'	'standing_prob'	...
    't1_grooming_prob'	't1_t2_grooming_prob'	't3_grooming_prob'	'walking_prob'	'abdomen_grooming_bout_number'	'air_legs_bout_number'...
    'antennae_grooming_bout_number'	'ball_push_bout_number'	'ball_tapping_bout_number'	'crabwalking_bout_number'	'egg_laying_bout_number'	...
    'head_eye_grooming_bout_number'	'mouth_grooming_bout_number'	'other_bout_number'	'postural_adjustment_bout_number'	'standing_bout_number'...
    't1_grooming_bout_number'	't1_t2_grooming_bout_number'	't3_grooming_bout_number'	'walking_bout_number'	'flyid'	'fullfile'	'date'...
    'condnum'	'type'	'dir'	'stimlen'	'stimvolt'	'date_parsed'	'pipeline_version'	'Date'	'Fly_'	'FlyLine'	'Sex'	'StimulusProcedure'	...
    'Conds'	'Reps'	'BaslerLength'	'LEDColor'	'LEDIntensity'	'LEDDutyCycle'	'NumVid'	'LEDLength'	'Time_'	'controlLength'	'stimLength'	'Temp'...
    'Humidity'	'Tether'	'Head'	'Ball'	'Anipose'	'FlyAge'	'FramesAligned'	'StructureName'	'Fly___'	'TotalDistance'	'CalibrationVideo'	...
    'Notes_'	'RigVersion'	'FlyPreservationLocation'	'Notes'	'x__index_level_0__'};
end