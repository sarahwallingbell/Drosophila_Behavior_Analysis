function [link, frames] = get_visualizer_link(data, idxs, open)

% Returns a link to view the data in the visualizer. If there 
% is more than one video in the idxs of data, return link for idxs(1).
%
% Params:
%     data = a parquet summary file of dat
%     idxs = a list of indices into data for which to return a link
%     open = t/f for opening the link in browser.
%
% Return:
%     link = a string to copy/paste into the browser. 
%     frames = frames in the video so you can locate indices in the video.
%               For example, for finding a specific step in the video. 
% 
% Sarah Walling-Bell, January 2022


idx = idxs(1);
date = data.date_parsed{idx};
fulldate = data.date{idx};
fly  = data.fly{idx};
rep  = num2str(data.rep(idx));
cond  = num2str(data.condnum(idx));
stripe_type = data.type{idx};
stripe_dir = data.dir{idx};
stim_len = num2str(data.stimlen(idx));

frames = data.fnum(idxs);
first_frame = num2str(frames(1)); 
last_frame = num2str(frames(end));

link = ['http://128.95.10.233:5000/#' date '/Fly%20' fly '/' fulldate '_fly' fly '%20R' rep 'C' cond '%20%20' stripe_type '-' stripe_dir '-' stim_len '%20sec'];

fprintf(['\n' link '\nFrames: ' first_frame '-' last_frame]);

if open
    web(link);
end


end