
function results = save_figure(fig_handle, figure_name, type)
% 
% results = save_figure(fig_handle, figure_name)
% 
% Export the input figure to the given location and name
% with the following settings: 
% '-png', '-nocrop', '-r300' , '-painters', '-rgb'
% Default type is '-png' but can be specified
%
% Inputs:
% 'fig_handle' [handle for figure being saved]
% 'figure_name' [path and name for saving location of fig]
% 'type' ['-pdf' or '-png' output type]
%
% Outputs: 
% 'results' [logical true|false if figure is saved]
%     
% % ES Dickinson, University of Washington, Jan 2019 - adapted by Sarah 2022

results = false;

if false % a way to turn on/off all figure saving in one place

    %default 
    if nargin == 2
        type = '-pdf';
    end
    
    
    % 
    % switch questdlg('Save Image?', 'Figure', 'Save Figure', 'Close Figure', 'Cancel', 'Save Figure')
    %     case 'Save Figure'
            export_fig(fig_handle,[figure_name '.pdf'], '-pdf','-nocrop', '-r600' , '-painters', '-rgb')
            export_fig(fig_handle,[figure_name '.png'], '-png','-nocrop', '-r600' , '-painters', '-rgb')
            close(fig_handle)
            fprintf('\nSaved:')
            disp(figure_name) 
            results = true;
    %     case 'Close Figure'
    %         close(fig_handle)
    %         results = false;
    %     case 'Cancel'
    %         results = false;
    % end
    
    % %how john wants figs saved for making papers:
    %  export_fig(fig1,[outputpath '\' filename(1:end-4) '_' label '.pdf'], '-pdf','-nocrop', '-r600' , '-painters', '-rgb')

end

end