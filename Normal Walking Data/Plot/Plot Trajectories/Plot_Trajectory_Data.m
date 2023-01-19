function Plot_Trajectory_Data_Var_X_Cond()

Plots trajectory data where rows are variables and columns are conditions.
A 'variable' is a column in the parquet file of data. Every frame has a value for each variable, so 
    we can plot different variables for the same time period. 
    Examples: 'speed', 'L1_FTi', 'Rep', 'Temp'
A 'Condition' is the value of a variable. The value of each variable changes across the data, so 
    we can filter the data by these values, called conditions. 
    Examples: laser length, flyid,  

Required params:
    'data' - a parquet summary file of data
    'param' - param struct from DLC_load_params.m
    'ctl_indices' - a vector of row numbers in 'data' to plot. Control condition.
    'exp_indices' - a vector of row numbers in 'data' to plot. Experimental condition.
    'variable' - the variable(s) to plot over time. Column name(s) in 'data'. 
        Ex: {'speed'} or {'L1_FTi', 'L2_FTi'}
    'path' - a file path for saving the plot

Optional params:
    'normalize' - true normalizes data to the value at stim onset (param.laser_on). Default is true.
    'average' - true plots average and standard error of the mean (sem). false plots raw data. Default is true.
    'behavior' - 
    
Sarah Walling-Bell
November, 2021

end