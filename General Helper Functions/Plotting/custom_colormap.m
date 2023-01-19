

function customCMap = custom_colormap(L, datat, indexValue, topColor, indexColor, bottomColor)

% L = 10;             %number of datapoints
% datat = 3.6*rand(L); % create example data set with values ranging from 0 to 3.6
% indexValue = 1;     % value for which to set a particular color
% topColor = [1 0 0];         % color for maximum data value (red = [1 0 0])
% indexColor = [1 1 1];       % color for indexed data value (white = [1 1 1])
% bottomColor = [0 0 1];      % color for minimum data value (blue = [0 0 1])

%CREATES A COLORMAP WHERE TOP AND BOTTOM VALUES ARE EXTREME COLORS, BUT THE
%SLOP OF THE COLOR BAR IS NOT EVEN FOR POSITIVE AND NEGATIVE VALUES. 

% % Calculate where proportionally indexValue lies between minimum and
% % maximum values
% largest = max(max(datat));
% smallest = min(min(datat));
% index = L*abs(indexValue-smallest)/(largest-smallest);
% % Create color map ranging from bottom color to index color
% % Multipling number of points by 100 adds more resolution
% customCMap1 = [linspace(bottomColor(1),indexColor(1),100*index)',...
%             linspace(bottomColor(2),indexColor(2),100*index)',...
%             linspace(bottomColor(3),indexColor(3),100*index)'];
% % Create color map ranging from index color to top color
% % Multipling number of points by 100 adds more resolution
% customCMap2 = [linspace(indexColor(1),topColor(1),100*(L-index))',...
%             linspace(indexColor(2),topColor(2),100*(L-index))',...
%             linspace(indexColor(3),topColor(3),100*(L-index))'];
% customCMap = [customCMap1;customCMap2];  % Combine colormaps


%CREATES A COLORMAP WHERE LARGEST ABS VALUE IS MOST EXTREME COLORS, SO THE
%SLOP OF THE COLOR BAR IS EVEN FOR POSITIVE AND NEGATIVE VALUES. 
% absMax = max(max(abs(datat)));
num_colors = 256; %number of colors in the dataset
middle = num_colors/2;  


% Calculate where proportionally indexValue lies between minimum and
% maximum values

% Create color map ranging from bottom color to index color
% Multipling number of points by 100 adds more resolution
customCMap1 = [linspace(bottomColor(1),indexColor(1),middle)',...
            linspace(bottomColor(2),indexColor(2),middle)',...
            linspace(bottomColor(3),indexColor(3),middle)'];
% Create color map ranging from index color to top color
% Multipling number of points by 100 adds more resolution
customCMap2 = [linspace(indexColor(1),topColor(1),middle)',...
            linspace(indexColor(2),topColor(2),middle)',...
            linspace(indexColor(3),topColor(3),middle)'];
customCMap = [customCMap1;customCMap2];  % Combine colormaps
