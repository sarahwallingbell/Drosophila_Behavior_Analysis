function Plot_step_metric_vs_meta_metric(varargin)

%
% Plot a step metric (e.g. step frequency) by a speed metric (e.g. acceleration)
% 
% Required params:
%     'steps' = a structure with all steps and assoc. metadata, output from steps.m 
%     'param' - param struct from DLC_load_params.m
%     'step_metric' - which step metric to plot - must be a column name
%           in 'steps' struct. 
%           Options:
%               - 'step_frequency'
%               - 'step_duration'
%               - 'step_length'
%               - 'stance_duration'
%               - 'swing_duration'
% 
%     'meta_metric' - which speed metric to plot - must be a column name
%           in 'steps' struct. 
%           Options:
%               - 'avg_speed'
%               - 'avg_acceleration'
%               - 'avg_angular_velocity'
%               - 'avg_heading_angle'
%               - 'avg_temp'
% 
% Optional params:
%     'flies' - a subset of flies to analyze. A cell of 'flyid's. 
%     'exp_type' - 'any' = exp steps have any laser. 'all' = exp steps are fully in laser. Default is 'any'. 
%
% Example usage:
%     
% 
% Sarah Walling-Bell
% November 2021
%     


    %set defaults for optional params
    flySubset = false;
    exp_type = 'any';
    % parse input params
    for ii = 1:nargin
        if ischar(varargin{ii}) && ~isempty(varargin{ii})
            if varargin{ii}(1) == '-' %find command descriptions
                switch lower(varargin{ii}(2:end))
                    case 'steps'
                        steps = varargin{ii+1};
                    case 'param'
                        param = varargin{ii+1};
                    case 'flies'
                        flies = varargin{ii+1};
                        flySubset = true;
                    case 'exp_type'
                        exp_type = varargin{ii+1};
                end
            end
        end
    end

    % make sure required inputs were given
    numRequiredParams = 2;
    if (exist('steps','var') + exist('param','var')) ~= numRequiredParams
        error('Missing required parameter(s)');
    end   








end