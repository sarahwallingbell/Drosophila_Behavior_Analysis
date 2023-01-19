function plot_2D_trajectory(varargin)

% Plot the 2D trajectory for a specific video or region of 'data'. 2D trajectory 
% comes from intx and inty from fictrac.  
% 
% Required params:
%     'data' - a parquet summary file of data
%     'param' - param struct from DLC_load_params.m
%     -EITHER- the follosing:
%     'indices' - a vector of row numbers in 'data' to plot
%         Ex: [1:599]
%     -OR- all of the following:
%     'fly' - a fly num
%         Ex: '1_0'
%     'date' - a fly date
%         Ex: '10.2.20'
%     'rep' - rep number 
%         Ex: 3
%     'cond' - a cond number
%         Ex: 5
% 
% Other params:
%     'colorTime' - true/false for whether to plot the line as a range of
%       colors indicating time. Default is true, plot the line with color
%       indicating time. 
% 
% Example: plot_2D_trajectory('-data', data, '-param', param, '-fly', '3_0', '-date', '9.30.20', '-rep', 3, '-cond', 19)
%         
% Sarah Walling-Bell, January 2022

%set default params
colorTime = true;

% parse input params
for ii = 1:nargin
        if ischar(varargin{ii}) && ~isempty(varargin{ii})
            if varargin{ii}(1) == '-' %find command descriptions
                switch lower(varargin{ii}(2:end))
                    case 'data'
                        data = varargin{ii+1};
                    case 'param'
                        param = varargin{ii+1};
                    case 'indices'
                        indices = varargin{ii+1};
                    case 'fly'
                        fly = varargin{ii+1};
                    case 'date'
                        date = varargin{ii+1};
                    case 'rep'
                        rep = varargin{ii+1};
                    case 'cond'
                        cond = varargin{ii+1};
                    case 'colorTime'
                        colorTime = varargin{ii+1};
                end
            end
        end
end

%check for required params and find indices
if ~exist('data','var') | ~exist('param','var'); error('missing function params'); end
if ~exist('indices')
    if ~exist('fly','var') | ~exist('date','var') | ~exist('rep','var') | ~exist('cond','var'); error('missing function params'); end
    indices = find(strcmpi(data.date_parsed, date) & strcmpi(data.fly, fly) & data.rep == rep & data.condnum == cond);
end

%plot path 
fig = fullfig; hold on
if colorTime %plot each fragment of the line with a different color indicating time.
    colors = parula(height(indices));
    for frame = 1:height(indices)-1
        plot(data.fictrac_int_x(indices(frame:frame+1))*-1, data.fictrac_int_y(indices(frame:frame+1)), 'linewidth', 2, 'color', colors(frame, :));  %invert x data to make turning direction be correct if looking down on the fly from above
    end
    c = colorbar('Ticks',[0, 1], 'TickLabels',{'0', num2str(height(indices) / param.fps)});
    c.Label.String = 'Time (s)';
    c.Color = 'w';
else
plot(data.fictrac_int_x(indices)*-1, data.fictrac_int_y(indices), 'linewidth', 2); %invert x data to make turning direction be correct if looking down on the fly from above
end
fig = formatFig(fig, true);
hold off
