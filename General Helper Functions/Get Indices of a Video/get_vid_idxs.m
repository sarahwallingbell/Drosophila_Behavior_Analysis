function idxs = get_vid_idxs(data, fly, date, rep, cond)
% 
% Returns the idxs in 'data' of this video. Specified by the fly num, date, 
% rep and cond of the video. Helpful for getting the idxs of a video for plotting, 
% i.e. as input to plot_single_variable() or as part of a loop to get the idxs 
% of all vids with a specific cond. 
% 
% 
% Params:
%     'data' - a parquet summary file of data
%     'fly' - a fly num
%         Ex: '1_0'
%     'date' - a fly date
%         Ex: '10.2.20'
%     'rep' - rep number 
%         Ex: 3
%     'cond' - a cond number
%         Ex: 5
% 
% 
% Sarah Walling-Bell, January 2022
%


idxs = find(strcmpi(data.date_parsed, date) & strcmpi(data.fly, fly) & data.rep == rep & data.condnum == cond);



end