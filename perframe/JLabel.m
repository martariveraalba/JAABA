function varargout = JLabel(varargin)
% JLabel: Start up the JAABA programi
%
% This program is part of JAABA.
%
% JAABA: The Janelia Automatic Animal Behavior Annotator
% Copyright 2012, Kristin Branson, HHMI Janelia Farm Resarch Campus
% http://jaaba.sourceforge.net/
% bransonk@janelia.hhmi.org
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License (version 3 pasted in LICENSE.txt) for 
% more details.

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @JLabel_OpeningFcn, ...
                   'gui_OutputFcn',  @JLabel_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1}) && exist(varargin{1}), %#ok<EXIST>
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
return


% -------------------------------------------------------------------------
function SetSplashStatus(hsplashstatus,varargin)

if ishandle(hsplashstatus),
  set(hsplashstatus,'String',sprintf(varargin{:}));
else
  fprintf([varargin{1},'\n'],varargin{2:end});
end
return
 

% -------------------------------------------------------------------------
% --- Executes just before JLabel is made visible.
function JLabel_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to JLabel (see VARARGIN)

% parse optional inputs
[defaultPath,...
 hsplash,...
 hsplashstatus,...
 jabfile,...
 nthreads] = ...
  myparse(varargin,...
          'defaultpath','',...
          'hsplash',[],...
          'hsplashstatus',[],...
          'jabfile','',...
          'nthreads',struct);

% Create the JLabelData object (which functions as a model in the MVC sense), store a reference to it
figureJLabel=handles.figure_JLabel;
handles.data=JLabelData('setstatusfn',@(s)SetStatusCallback(s,figureJLabel) , ...
                        'clearstatusfn',@()ClearStatusCallback(figureJLabel));
if ~isempty(defaultPath) ,                      
  handles.data.SetDefaultPath(defaultPath);
end

% To help with merging with Adam -- Mayank, 6 march 2012 
set(handles.automaticTimelineBottomRowPopup,'String',...
    {'None','Validated','Old','Imported','Postprocessed','Distance'});

% Added to JLabel.fig
%handles.menu_classifier_compareFrames = uimenu(handles.menu_classifier,...
% 'Label','Find Similar Frames','Callback',...
%@menu_classifier_compareFrames_Callback);

handles.guidata = JLabelGUIData(handles.data);
if isfield(nthreads,'framecache_threads'),
  handles.guidata.framecache_threads = nthreads.framecache_threads;
end
if isfield(nthreads,'computation_threads'),
  handles.guidata.computation_threads = nthreads.computation_threads;
end

% stash optional inputs
handles.guidata.hsplash=hsplash;
handles.guidata.hsplashstatus=hsplashstatus;

% Throw up the splash window
if isempty(handles.guidata.hsplash),
  [handles.guidata.hsplash,handles.guidata.hsplashstatus] = JAABASplashScreen();
end
SetSplashStatus(handles.guidata.hsplashstatus,'Initializing Edit Files GUI...');

handles.output = handles.figure_JLabel;
% initialize statusbar

%handles.guidata.status_bar_text_when_clear = sprintf('Status: No experiment loaded');
handles.guidata.idlestatuscolor = [0,1,0];
handles.guidata.busystatuscolor = [1,0,1];
handles.guidata.movie_height = 100;
handles.guidata.movie_width = 100;
handles.guidata.movie_depth = 1;
handles.guidata.tempname = tempname();

% Set the initial clear status message
syncStatusBarTextWhenClear(handles);
%handles.guidata.status_bar_text_when_clear='No file open.';
ClearStatus(handles);

%[handles,success] = JLabelEditFiles('JLabelHandle',handles,...
%  'JLabelSplashHandle',handles.guidata.hsplash);

% Change a few things so they still work well on Mac
adjustColorsIfMac(hObject);

% % read configuration
% handles.guidata.configfilename='params/featureConfig.xml';
% [handles,success] = LoadConfig(handles);
% if ~success,
%   guidata(hObject,handles);
%   delete(hObject);
%   return;
% end

% Hide the splash window
set(handles.guidata.hsplash,'visible','off');

% save the window state
guidata(hObject,handles);

% Update the arrays of graphics handles (grandles) within the figure's guidata
handles.guidata.UpdateGraphicsHandleArrays(hObject);

% Get some figure dimensions useful when we need to redo the layout
set(handles.togglebutton_label_behavior1,'Units','pixels');
button1_pos = get(handles.togglebutton_label_behavior1,'Position');
set(handles.togglebutton_label_unknown,'Units','pixels');
unknown_button_pos = get(handles.togglebutton_label_unknown,'Position');
handles.guidata.in_border_y = button1_pos(2) - (unknown_button_pos(2)+unknown_button_pos(4));

% Update the label buttons, to get everything into a self-consistent state
handles = UpdateLabelButtons(handles);
handles.guidata.setLayout(hObject);
updatePanelPositions(handles);
%guidata(hObject,handles);

% Update aspects of the GUI to match the current "model" state
%handles=guidata(hObject);
UpdateEnablementAndVisibilityOfControls(handles);
UpdateGUIToMatchPreviewZoomMode(handles)

% keypress callback for all non-edit text objects
RecursiveSetKeyPressFcn(hObject);

% Clear the current fly info
set(handles.text_selection_info,'string','');

% load the RC file (is this the time and place?)
handles = LoadRC(handles);

handles = InitSelectionCallbacks(handles);

% Write the handles to the guidata
guidata(hObject,handles);

set(handles.figure_JLabel,'Visible','on');
drawnow;

if ~isempty(jabfile),
  openEverythingFileGivenFileNameAbs(handles.figure_JLabel,jabfile,false);
else
  
  res = JAABAInitOpen(handles.figure_JLabel);
  
  if ~isempty(res.val)
    if ~res.edit
      switch res.val,
        case 'New',
          newEverythingFile(handles.figure_JLabel);
        case 'Open',
          openEverythingFileViaChooser(findAncestorFigure(hObject),false); % false means labeling mode
        case 'OpenGT',
          openEverythingFileViaChooser(findAncestorFigure(hObject),true);  % true means ground-truthing mode
      end
    else
      switch res.val,
        case 'New',
          newEverythingFile(handles.figure_JLabel);
        case 'Open',
          editEverythingFileViaChooser(findAncestorFigure(hObject),false); % false means labeling mode
        case 'OpenGT',
          editEverythingFileViaChooser(findAncestorFigure(hObject),true);  % true means ground-truthing mode
      end
    end
  end
end

return


% -------------------------------------------------------------------------
function handles = InitSelectionCallbacks(handles)

handles.guidata.callbacks = struct;
handles.guidata.callbacks.figure_WindowButtonMotionFcn = get(handles.figure_JLabel,'WindowButtonMotionFcn');
set(handles.figure_JLabel,'WindowButtonMotionFcn','');
return


% -------------------------------------------------------------------------
% --- Outputs from this function are returned to the command line.
function varargout = JLabel_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = hObject;
% UNCOMMENT
% if isfield(handles,'data'),
%   varargout{1} = handles.data;
% else
%   varargout{1} = [];
% end
% SaveRC(handles);
% delete(handles.figure_JLabel);


%--------------------------------------------------------------------------
function handles = InitializeStateAfterBasicParamsSet(handles)

% % Tell JLabelGUIData to init itself
% handles.guidata.initializeGivenBasicParams(basicParams,handles.figure_JLabel,groundTruthingMode);

% create buttons for each label, as needed
handles = UpdateLabelButtons(handles);

% Set this thing
if ~isempty(handles.data.allperframefns)
  set(handles.timeline_label_prop1,'String',handles.guidata.timeline_prop_options,'Value',3);
end

% Setup the popup menu for bottom row of the automatic timeline.
bottomRowTypes = get(handles.automaticTimelineBottomRowPopup,'String');
set(handles.automaticTimelineBottomRowPopup,'Value', ...
                  find(strcmp(bottomRowTypes,handles.guidata.bottomAutomatic)));
set(handles.automaticTimelinePredictionLabel,'FontSize',10);
set(handles.automaticTimelineScoresLabel,'FontSize',10);
set(handles.automaticTimelineBottomRowPopup,'FontSize',10);

% set([handles.pushbutton_playselection, ...
%      handles.pushbutton_clearselection],'Enable','off');  

%set(handles.togglebutton_select,'Value',0); 

SetJumpGoMenuLabels(handles)

handles.doplottracks = true;
%set(handles.menu_view_plot_tracks,'Checked','on');  %via update

buttonNames = {'pushbutton_train','pushbutton_predict',...
               'togglebutton_select','pushbutton_clearselection',...
               'pushbutton_playselection','pushbutton_playstop',...
               'similarFramesButton','bagButton'};
for buttonNum = 1:numel(buttonNames)
  adjustButtonColorsIfMac(handles.(buttonNames{buttonNum}));
end

%set(handles.similarFramesButton,'Enable','off');  % via update

updateCheckMarksInMenus(handles);

return


% -------------------------------------------------------------------------
function handles = InitializePlotsAfterBasicParamsSet(handles)

handles.guidata.axes_preview_curr = 1;
if numel(handles.guidata.axes_previews) > numel(handles.guidata.ts),
  handles.guidata.ts = [handles.guidata.ts,repmat(handles.guidata.ts(end),[1,numel(handles.guidata.axes_previews)-numel(handles.guidata.ts)])];
end

% slider callbacks
for i = 1:numel(handles.guidata.slider_previews),
  fcn = get(handles.guidata.slider_previews(i),'Callback');
  %set(handles.guidata.slider_previews(i),'Callback','');
  if i == 1,
    handles.guidata.hslider_listeners = handle.listener(handles.guidata.slider_previews(i),...
      'ActionEvent',fcn);
  else
    handles.guidata.hslider_listeners(i) = handle.listener(handles.guidata.slider_previews(i),...
      'ActionEvent',fcn);
  end
end

% fly current positions
nPreviewAxes=numel(handles.guidata.axes_previews);
handles.guidata.hflies = zeros(handles.data.nTargetsInCurrentExp,nPreviewAxes);
handles.guidata.hflies_extra = ...
  zeros(handles.data.nTargetsInCurrentExp, ...
        handles.data.trxGraphicParams.nextra_markers, ...
        nPreviewAxes);
handles.guidata.hfly_markers = zeros(handles.data.nTargetsInCurrentExp,nPreviewAxes);
% fly path
handles.guidata.htrx = zeros(handles.guidata.nflies_label,nPreviewAxes);

% choose colors for flies
% TODO: change hard-coded colormap
nTargetsInCurrentExp=handles.data.nTargetsInCurrentExp;
nColors=fif(isempty(nTargetsInCurrentExp),0,nTargetsInCurrentExp);
handles.guidata.fly_colors = jet(nColors)*.7;
handles.guidata.fly_colors = fif(handles.data.getColorAssignment,...
  handles.guidata.fly_colors(randperm(nColors),:),...
  handles.guidata.fly_colors);

handles.guidata.hlabel_curr = nan(1,numel(handles.guidata.axes_previews));
for i = 1:numel(handles.guidata.axes_previews),
  % cla(handles.guidata.axes_previews(i),'reset');
  delete(get(handles.guidata.axes_previews(i),'children'));
  
  % image in axes_preview
  %handles.guidata.himage_previews(i) = imagesc(0,'Parent',handles.guidata.axes_previews(i),[0,255]);
  set(handles.guidata.axes_previews(i), ...
      'ydir','reverse', ...
      'clim',[0,255], ...
      'layer','top', ...
      'box','on');
  handles.guidata.himage_previews(i) = ...
    image('Parent',handles.guidata.axes_previews(i), ...
          'cdata',0, ...
          'cdatamapping','scaled');
  set(handles.guidata.himage_previews(i),'HitTest','off');
  axis(handles.guidata.axes_previews(i),'equal');
  
  set(handles.guidata.axes_previews(i),'ButtonDownFcn',@(hObject,eventdata) JLabel('axes_preview_ButtonDownFcn',hObject,eventdata,guidata(hObject)));
  %hold(handles.guidata.axes_previews(i),'on');

  % labeled behaviors
  handles.guidata.hlabels = nan(1,handles.data.nbehaviors);
  handles.guidata.hpredicted = nan(1,handles.data.nbehaviors);
  handles.guidata.hlabelstarts = nan(1,handles.data.nbehaviors);
  for j = 1:handles.data.nbehaviors,
    % handles.guidata.hlabels(j) = plot(handles.guidata.axes_previews(i),nan,nan,'-',...
    %   'color',handles.guidata.labelcolors(j,:),'linewidth',5,'HitTest','off');
    handles.guidata.hlabels(j) = ...
      line('parent',handles.guidata.axes_previews(i), ...
           'xdata',nan, ...
           'ydata',nan, ...
           'linestyle','-', ...
           'color',handles.guidata.labelcolors(j,:), ...
           'linewidth',5, ...
           'HitTest','off');
    % handles.guidata.hpredicted(j) = plot(handles.guidata.axes_previews(i),nan,nan,'-',...
    %   'color',handles.guidata.labelcolors(j,:),'linewidth',5,'HitTest','off');
    handles.guidata.hpredicted(j) = ...
      line('parent',handles.guidata.axes_previews(i), ...
           'xdata',nan, ...
           'ydata',nan, ...
           'linestyle','-',...
           'color',handles.guidata.labelcolors(j,:), ...
           'linewidth',5, ...
           'HitTest','off');
    % start of label
    % handles.guidata.hlabelstarts(j) = plot(handles.guidata.axes_previews(i),nan,nan,'v',...
    %   'color',handles.guidata.labelcolors(j,:),'markerfacecolor',handles.guidata.labelcolors(j,:),...
    %   'HitTest','off');
    handles.guidata.hlabelstarts(j) = ...
      line('parent',handles.guidata.axes_previews(i), ...
           'xdata',nan, ...
           'ydata',nan, ...
           'marker','v',...
           'color',handles.guidata.labelcolors(j,:), ...
           'markerfacecolor',handles.guidata.labelcolors(j,:),...
           'HitTest','off');    
    set(handles.guidata.axes_previews(i),'Color','k','XColor','w','YColor','w');
  end
  
  if handles.guidata.plot_labels_manual,
    set(handles.guidata.hlabels,'Visible','on');
  else
    set(handles.guidata.hlabels,'Visible','off');
  end
  if handles.guidata.plot_labels_automatic,
    set(handles.guidata.hpredicted,'Visible','on');
  else
    set(handles.guidata.hpredicted,'Visible','off');
  end
  
  % current label plotted on axes
  %handles.guidata.hlabel_curr(i) = plot(nan(1,2),nan(1,2),'k-',...
  %  'Parent',handles.guidata.axes_previews(i),...
  %  'HitTest','off','Linewidth',5);
  handles.guidata.hlabel_curr(i) = ...
    line('Parent',handles.guidata.axes_previews(i), ...
         'xdata',nan(1,2), ...
         'ydata',nan(1,2), ...
         'color','k', ...
         'linestyle','-', ...    
         'HitTest','off', ...
         'Linewidth',5);
  
  % trx of flies
  for j = 1:handles.guidata.nflies_label,
    % handles.guidata.htrx(j,i) = plot(handles.guidata.axes_previews(i),nan,nan,'.-',...
    %   'linewidth',1,'HitTest','off');
    handles.guidata.htrx(j,i) = ...
      line('parent',handles.guidata.axes_previews(i), ...
           'xdata',nan, ...
           'ydata',nan, ...
           'marker','.', ...
           'linestyle','-', ...
           'linewidth',1, ...
           'HitTest','off');
  end
  
  % fly current positions
  for fly = 1:handles.data.nTargetsInCurrentExp,
    % handles.guidata.hflies(fly,i) = plot(handles.guidata.axes_previews(i),nan,nan,'-',...
    %   'color',handles.guidata.fly_colors(fly,:),'linewidth',3,...
    %   'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i));
    handles.guidata.hflies(fly,i) = ...
      line('parent',handles.guidata.axes_previews(i), ...
           'xdata',nan, ...
           'ydata',nan, ...
           'linestyle','-', ...
           'color',handles.guidata.fly_colors(fly,:), ...
           'linewidth',3,...
           'ButtonDownFcn', ...
             @(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i) );
    % handles.guidata.hflies_extra(fly,i) = plot(handles.guidata.axes_previews(i),nan,nan,...
    %   'Marker',handles.guidata.flies_extra_marker,...
    %   'Color',handles.guidata.fly_colors(fly,:),'MarkerFaceColor',handles.guidata.fly_colors(fly,:),...
    %   'LineStyle',handles.guidata.flies_extra_linestyle,...
    %   'MarkerSize',handles.guidata.flies_extra_markersize,...
    %   'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i));
    handles.guidata.hflies_extra(fly,j,i) = ...
      line('parent',handles.guidata.axes_previews(i), ...
           'xdata',nan, ...
           'ydata',nan,...
           'Marker',handles.data.trxGraphicParams.extra_marker{j},...
           'Color',handles.guidata.fly_colors(fly,:), ...
           'MarkerFaceColor',handles.guidata.fly_colors(fly,:),...
           'LineStyle',handles.data.trxGraphicParams.extra_linestyle{j},...
           'MarkerSize',handles.data.trxGraphicParams.extra_markersize{j},...
           'ButtonDownFcn', ...
             @(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i));
    % handles.guidata.hfly_markers(fly,i) = plot(handles.guidata.axes_previews(i),nan,nan,'*',...
    %   'color',handles.guidata.fly_colors(fly,:),'linewidth',3,...
    %   'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i),...
    %   'Visible','off');
    handles.guidata.hfly_markers(fly,i) = ...
      line('parent',handles.guidata.axes_previews(i), ...
           'xdata',nan, ...
           'ydata',nan, ...
           'marker','*', ...
           'color',handles.guidata.fly_colors(fly,:), ...
           'linewidth',3,...
           'ButtonDownFcn', ...
             @(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i),...
           'Visible','off');
  end

end

% TODO: allow colormap options
%colormap(handles.axes_preview,gray(256));
set(handles.figure_JLabel,'colormap',gray(256));

% timelines

% zoom
handles.guidata.hzoom = zoom(handles.figure_JLabel);
handles.guidata.hpan = pan(handles.figure_JLabel);
set(handles.guidata.hzoom,'ActionPostCallback',@(hObject,eventdata) PostZoomCallback(hObject,eventdata,guidata(eventdata.Axes)));
set(handles.guidata.hpan,'ActionPostCallback',@(hObject,eventdata) PostZoomCallback(hObject,eventdata,guidata(eventdata.Axes)));

% manual timeline
delete(get(handles.axes_timeline_manual,'children'));
timeline_axes_color = get(handles.panel_timelines,'BackgroundColor');
%handles.guidata.himage_timeline_manual = image(zeros([1,1,3]),'Parent',handles.axes_timeline_manual);
handles.guidata.himage_timeline_manual = ...
  image('parent',handles.axes_timeline_manual, ...
        'cdata',zeros([1,1,3]));
set(handles.guidata.himage_timeline_manual,'HitTest','off');
%hold(handles.axes_timeline_manual,'on');
ylim = [.5,1.5];
ydata = [ylim(1)+diff(ylim)*.025,ylim(2)-diff(ylim)*.025];
handles.guidata.htimeline_label_curr = ...
  patch('Parent',handles.axes_timeline_manual, ...
        'xdata',nan(1,5), ...
        'ydata',ydata([1,2,2,1,1]), ...
        'facecolor','k',...
        'LineStyle','--', ...
        'EdgeColor','w',...
        'HitTest','off', ...
        'Linewidth',3, ...
        'Clipping','on');
if handles.guidata.plot_labels_manual,
  set(handles.timeline_label_manual,'ForegroundColor',handles.guidata.emphasiscolor,'FontWeight','bold');
else
  set(handles.timeline_label_manual,'ForegroundColor',handles.guidata.unemphasiscolor,'FontWeight','normal');
end

set(handles.axes_timeline_manual,'YTick',[]);
setAxesZoomMotion(handles.guidata.hzoom,handles.axes_timeline_manual,'horizontal');
setAllowAxesPan(handles.guidata.hpan,handles.axes_timeline_manual,false);

% auto timeline
delete(get(handles.axes_timeline_auto,'children'));
ydata_im = [2/3,4/3];
%handles.guidata.himage_timeline_auto = image(zeros([3,1,3]),'Parent',handles.axes_timeline_auto);
handles.guidata.himage_timeline_auto = ...
  image('Parent',handles.axes_timeline_auto, ...
        'cdata',zeros([3,1,3]));
set(handles.guidata.himage_timeline_auto,'YData',ydata_im);
set(handles.guidata.himage_timeline_auto,'HitTest','off');
%hold(handles.axes_timeline_auto,'on');
%handles.htimeline_auto_starts = plot(handles.axes_timeline_auto,nan,nan,'w-','HitTest','off');
set(handles.axes_timeline_auto,'YTick',[]);
setAxesZoomMotion(handles.guidata.hzoom,handles.axes_timeline_auto,'horizontal');
setAllowAxesPan(handles.guidata.hpan,handles.axes_timeline_auto,false);
if handles.guidata.plot_labels_automatic,
  set(handles.timeline_label_automatic,'ForegroundColor',handles.guidata.emphasiscolor,'FontWeight','bold');
else
  set(handles.timeline_label_automatic,'ForegroundColor',handles.guidata.unemphasiscolor,'FontWeight','normal');
end

% handles.guidata.axes_timeline_labels has two elements, 
% handles.guidata.axes_timeline_manual and 
% handles.guidata.axes_timeline_auto
for h = handles.guidata.axes_timeline_labels,
  %set(h,'YLim',[.5,1.5]);
  set(h, ...
      'layer','top', ...
      'box','on', ...
      'ylim',[0.5 1.5], ...
      'ydir','reverse', ...
      'xticklabel',{});
end
set(handles.axes_timeline_prop1, ...
    'layer','top', ...
    'box','on');

% properties
delete(get(handles.axes_timeline_prop1,'children'));
propi = 1;
%handles.guidata.htimeline_data(propi) = plot(handles.guidata.axes_timeline_props(propi),nan,nan,'w.-','HitTest','off');
handles.guidata.htimeline_data(propi) = ...
  line('parent',handles.guidata.axes_timeline_props(propi), ...
       'xdata',nan, ...
       'ydata',nan, ...
       'color','w', ...
       'marker','.', ...
       'linestyle','-', ...
       'HitTest','off');
%hold(handles.guidata.axes_timeline_props(propi),'on');

% whether the manual and auto match
% handles.guidata.htimeline_errors = plot(handles.axes_timeline_manual,nan,nan,'-',...
%   'color',handles.guidata.incorrectcolor,'HitTest','off','Linewidth',5);
handles.guidata.htimeline_errors = ...
  line('parent',handles.axes_timeline_manual, ...
       'xdata',nan, ...
       'ydata',nan, ...
       'linestyle','-', ...
       'color',handles.guidata.incorrectcolor, ...
       'HitTest','off', ...
       'Linewidth',5);
% menu_file_open_old_school_files suggestions
% handles.guidata.htimeline_suggestions = plot(handles.axes_timeline_manual,nan,nan,'-',...
%   'color',handles.guidata.suggestcolor,'HitTest','off','Linewidth',5);
handles.guidata.htimeline_suggestions = ...
  line('parent',handles.axes_timeline_manual, ...
       'xdata',nan, ...
       'ydata',nan, ...
       'linestyle','-', ...
       'color',handles.guidata.suggestcolor, ...
       'HitTest','off', ...
       'Linewidth',5);

% gt suggestions
% handles.guidata.htimeline_gt_suggestions = plot(handles.axes_timeline_manual,nan,nan,'-',...
%   'color',handles.guidata.suggestcolor,'HitTest','off','Linewidth',5);
handles.guidata.htimeline_gt_suggestions = ...
  line('parent',handles.axes_timeline_manual, ...
       'xdata',nan, ...
       'ydata',nan, ...
       'linestyle','-', ...
       'color',handles.guidata.suggestcolor, ...
       'HitTest','off', ...
       'Linewidth',5);

%handles.guidata.menu_view_zoom_options = setdiff(findall(handles.menu_view_zoom,'Type','uimenu'),...
%  handles.menu_view_zoom);

% suggest timeline
% handles.himage_timeline_suggest = image(zeros([1,1,3]),'Parent',handles.axes_timeline_suggest);
% set(handles.himage_timeline_suggest,'HitTest','off');
% hold(handles.axes_timeline_suggest,'on');
% handles.htimeline_suggest_starts = plot(handles.axes_timeline_suggest,nan,nan,'w-','HitTest','off');

% error timeline
% handles.himage_timeline_error = image(zeros([1,1,3]),'Parent',handles.axes_timeline_error);
% set(handles.himage_timeline_error,'HitTest','off');
% hold(handles.axes_timeline_error,'on');
% handles.htimeline_error_starts = plot(handles.axes_timeline_error,nan,nan,'w-','HitTest','off');

for i = 1:numel(handles.guidata.axes_timeline_props),
  setAxesZoomMotion(handles.guidata.hzoom,handles.guidata.axes_timeline_props(i),'vertical');
  setAllowAxesPan(handles.guidata.hpan,handles.guidata.axes_timeline_props(i),true);
  setAxesPanMotion(handles.guidata.hpan,handles.guidata.axes_timeline_props(i),'vertical');
end

for i = 1:numel(handles.guidata.axes_timelines),
  % hold(handles.guidata.axes_timelines(i),'on');
  set(handles.guidata.axes_timelines(i),'XColor','w','YColor','w','Color',timeline_axes_color);
end

handles.guidata.hcurr_timelines = nan(size(handles.guidata.axes_timelines));
for i = 1:numel(handles.guidata.axes_timelines),
  % handles.guidata.hcurr_timelines(i) = plot(handles.guidata.axes_timelines(i),nan(1,2),[-10^6,10^6],'y-','HitTest','off','linewidth',2);
  handles.guidata.hcurr_timelines(i) = ...
    line('parent',handles.guidata.axes_timelines(i), ...
         'xdata',nan(1,2), ...
         'ydata',[-10^6,10^6], ...
         'color','y', ...
         'linestyle','-', ...
         'HitTest','off', ...
         'linewidth',2);
end
handles.guidata.hselection = nan(size(handles.guidata.axes_timelines));
for i = 1:numel(handles.guidata.axes_timelines),
  ylim = [.5,1.5];
  ydata = [ylim(1)+diff(ylim)*.025,ylim(2)-diff(ylim)*.025];
  % handles.guidata.hselection(i) = ...
  %   plot(handles.guidata.axes_timelines(i),nan(1,5),ydata([1,2,2,1,1]),'--','color',handles.guidata.selection_color,...
  %   'HitTest','off','Linewidth',3);
  handles.guidata.hselection(i) = ...
    line('parent',handles.guidata.axes_timelines(i), ...
         'xdata',nan(1,5), ...
         'ydata',ydata([1,2,2,1,1]), ...
         'linestyle','--', ...
         'color',handles.guidata.selection_color, ...
         'HitTest','off', ...
         'Linewidth',3);
end

for i = 2:numel(handles.guidata.axes_timelines),
%  if handles.guidata.axes_timelines(i) ~= handles.axes_timeline_error,
%  if handles.guidata.axes_timelines(i) ~= handles.axes_timeline_auto,
    set(handles.guidata.axes_timelines(i),'XTickLabel',{});
%  end
end

linkaxes(handles.guidata.axes_timelines,'x');

set(handles.guidata.htimeline_gt_suggestions,'Visible','off');
if handles.data.IsGTMode(),
  set(handles.menu_view_automatic_labels,'Visible','off');
end

% for faster refreshing
set(handles.axes_preview,'BusyAction','cancel');
set(handles.guidata.hflies,'EraseMode','none');
if ~isempty(handles.guidata.hflies_extra),
  set(handles.guidata.hflies_extra,'EraseMode','none');
end
set(handles.guidata.htrx,'EraseMode','none');
set(handles.guidata.hfly_markers,'EraseMode','none');

% keypress callback for all non-edit text objects
RecursiveSetKeyPressFcn(handles.figure_JLabel);

handles = UpdateGUIToMatchGroundTruthingMode(handles);

%for i = 1:numel(handles.guidata.axes_timelines),
%  setAxesZoomMotion(handles.guidata.hzoom,handles.guidata.axes_timelines(i),'horizontal');
%end

% timeline callbacks
% fcn = @(hObject,eventdata) JLabel('axes_timeline_ButtonDownFcn',hObject,eventdata,guidata(hObject));
% for i = 1:numel(handles.guidata.axes_timelines),
%   set(handles.guidata.axes_timelines(i),'ButtonDownFcn',fcn);
% end

return


% % -------------------------------------------------------------------------
% function cache_thread(N,HWD,cache_filename,movie_filename)
% 
% % lastused = nan means please add framenum to cache
% %          = 0 means image is invalid and removed from cache
% %          = -1 means it is locked and being added to cache
% %          otherwise it is the timestamp the valid image was last used
% 
% if isempty(movie_filename),
%   return;
% end
% 
% Mframenum = memmapfile(cache_filename, 'Writable', true, 'Format', 'double', 'Repeat', N);
% Mlastused = memmapfile(cache_filename, 'Writable', true, 'Format', 'double', 'Repeat', N, 'Offset', N*8);
% Mimage    = memmapfile(cache_filename, 'Writable', true, 'Format', {'uint8' HWD 'x'},  'Repeat', N, ...
%     'Offset', 2*N*8);
% 
% readframe=get_readframe_fcn(movie_filename);
% 
% while true
%   idx=find(isnan(Mlastused.Data));
%   if(~isempty(idx))
%     idx2=argmax(Mframenum.Data(idx));
%     Mlastused.Data(idx(idx2))=-1;
%     fnum = Mframenum.Data(idx(idx2));
%     dd = uint8(readframe(fnum));
%     pause(0.0003);     % BJA: why this pause??
%     % MK: Cache the read frame to reduce the number of clashes with
%     % UpdatePlots
%     if Mframenum.Data(idx(idx2)) == fnum
%       Mimage.Data(idx(idx2)).x = dd;
%       Mlastused.Data(idx(idx2)) = now;
%       %Mframenum.Data(idx(idx2)) = fnum;
%     end
%   else
%     pause(0.1);
%   end
% end
% 
% return  %#ok


% -------------------------------------------------------------------------
function UpdatePlots(handles,varargin)

persistent Mframenum Mlastused Mimage movie_filename cache_miss cache_total exp_next fly_next ts_next imnorm

debug_cache = false;

% if no experiments are loaded, nothing to do
%if isempty(handles.data) || handles.data.nexps==0 ,
if ~handles.data.thereIsAnOpenFile || handles.data.nexps==0 ,
  return
end

if ~isempty(varargin) && strcmp(varargin{1},'CLEAR'),
  %fprintf('Clearing UpdatePlots data\n');
  try
    if isfield(handles,'guidata') && ~isempty(handles.guidata.cache_thread),
      for i=1:length(handles.guidata.cache_thread)
        delete(handles.guidata.cache_thread{i});
      end
      handles.guidata.cache_thread = [];
    end
    Mframenum = struct('Data',[]);
    Mlastused = struct('Data',[]);
    Mimage = struct('Data',[]);
    movie_filename = '';
  catch ME,
    warning('Error when trying to clear UpdatePlots data: %s',getReport(ME)); 
  end
  return;
end

% If the movie has changed, want to re-initialize the frame cache
handles.guidata.cache_size=200;  % cache size
if(handles.data.ismovie && ...
   handles.guidata.shouldOpenMovieIfPresent && ...
   handles.guidata.thisMoviePresent && ...
   (isempty(movie_filename) || ~strcmp(movie_filename,handles.guidata.movie_filename)))
  movie_filename=handles.guidata.movie_filename;
  HWD = [handles.guidata.movie_height handles.guidata.movie_width handles.guidata.movie_depth];

  % release data used in thread
  if ~isempty(handles.guidata.cache_thread),
    for i=1:length(handles.guidata.cache_thread)
      delete(handles.guidata.cache_thread{i});
    end
    handles.guidata.cache_thread = [];
  end
%   Mframenum = struct('Data',[]); 
%   Mlastused = struct('Data',[]);
%   Mimage = struct('Data',[]); 
  
  if(isfield(handles.guidata,'cachefilename') && exist(handles.guidata.cachefilename,'file'))
    delete(handles.guidata.cachefilename);
  end
  handles.guidata.cache_filename=[handles.guidata.tempname 'cache-' num2str(feature('getpid')) '.dat'];
  fid=fopen(handles.guidata.cache_filename,'w');
  if fid < 1,
    pause(.1);
    fid=fopen(handles.guidata.cache_filename,'w');
  end

  for i = 1:5,
    if fid >= 1,
      break;
    end
    new_cache_filename = fullfile(tempdir(),['cache-' num2str(feature('getpid')) '_' num2str(i) '.dat']);
    warning('Could not open cache file %s, trying %s',handles.guidata.cache_filename,new_cache_filename); 
    handles.guidata.cache_filename = new_cache_filename;
    fid=fopen(handles.guidata.cache_filename,'w');
  end
    
  fwrite(fid,zeros(1,handles.guidata.cache_size),'double');
  fwrite(fid,zeros(1,handles.guidata.cache_size),'double');
  fwrite(fid,zeros(1,handles.guidata.cache_size*prod(HWD),'uint8'),'uint8');  % need to make this work for other formats
  fclose(fid);
  Mframenum = memmapfile(handles.guidata.cache_filename, 'Writable', true, 'Format', 'double', 'Repeat', handles.guidata.cache_size);
  Mlastused = memmapfile(handles.guidata.cache_filename, 'Writable', true, 'Format', 'double', 'Repeat', handles.guidata.cache_size, 'Offset', handles.guidata.cache_size*8);
  Mimage =    memmapfile(handles.guidata.cache_filename, 'Writable', true, 'Format', {'uint8' HWD 'x'},  'Repeat', handles.guidata.cache_size, 'Offset', 2*handles.guidata.cache_size*8);

  %c=parcluster;
  %framecache_threads = min(c.NumWorkers - matlabpool('size'), feature('numCores'));
  for i=1:handles.guidata.framecache_threads,
    SetStatus(handles,sprintf('Adding %d of %d frame cache thread(s)',...
      i,handles.guidata.framecache_threads));
    handles.guidata.cache_thread{i}=batch(@cache_thread,0,...
      {handles.guidata.cache_size,HWD,handles.guidata.cache_filename,handles.guidata.movie_filename},...
      'CaptureDiary',true,'AdditionalPaths',{'../filehandling','../misc'});
  end
  ClearStatus(handles);
  cache_miss=0;
  cache_total=0;
  %if(ismac),  pause(10);  end  % BJA: only necessary if on a mac and using a remote file system, not sure why
end

% WARNING: we directly access handles.data.trx for speed here -- 
% REMOVED! NOT SO SLOW

[axes2,refreshim,refreshflies,refreshtrx,refreshlabels,...
  refresh_timeline_manual,refresh_timeline_auto,refresh_timeline_suggest,refresh_timeline_error,...
  refresh_timeline_xlim,refresh_timeline_hcurr,...
  refresh_timeline_props,refresh_timeline_selection,...
  refresh_curr_prop,refresh_GT_suggestion] = ...
  myparse(varargin,'axes',1:numel(handles.guidata.axes_previews),...
  'refreshim',true,'refreshflies',true,'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',true,...
  'refresh_timeline_auto',true,...
  'refresh_timeline_suggest',true,...
  'refresh_timeline_error',true,...
  'refresh_timeline_xlim',true,...
  'refresh_timeline_hcurr',true,...
  'refresh_timeline_props',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',true,...
  'refresh_GT_suggestion',true);

% make sure data for this experiment is loaded
% if handles.data.expi ~= handles.data.expi,
%   SetStatus('Preloading data for experiment %s, flies %s',handles.data.expnames{handles.data.expi},mat2str(handles.data.flies));
%   handles.data.PreLoad(handles.data.expi,handles.data.flies);
% end

% update timelines
if refresh_timeline_manual,
  set(handles.guidata.himage_timeline_manual,'CData',handles.guidata.labels_plot.im);
  %tmp = find(handles.guidata.labels_plot.isstart);
  %nstarts = numel(tmp);
  %tmpx = reshape(cat(1,repmat(tmp,[2,1]),nan(1,nstarts)),[3*nstarts,1]);
  %tmpy = reshape(repmat([.5;1.5;nan],[1,nstarts]),[3*nstarts,1]);
  %set(handles.htimeline_manual_starts,'XData',tmpx,'YData',tmpy);  
  if handles.guidata.label_state ~= 0,
    ts = sort([handles.label_t0,handles.guidata.ts(1)]);
    ts(1) = max(ts(1),handles.guidata.ts(1)-(handles.guidata.timeline_nframes-1)/2);
    ts(2) = min(ts(2),handles.guidata.ts(1)+(handles.guidata.timeline_nframes-1)/2);
    ts = ts + [-.5,.5];
    set(handles.guidata.htimeline_label_curr,'XData',ts([1,1,2,2,1]));
  end
end

if refresh_timeline_auto,
  set(handles.guidata.himage_timeline_auto,'CData',handles.guidata.labels_plot.predicted_im);
  [pred,t0,t1] = handles.data.GetPredictedIdx(handles.data.expi,handles.data.flies,handles.guidata.ts(1),handles.guidata.ts(1));
  if t0 <= handles.guidata.ts(1) && t1>=handles.guidata.ts(1) &&    pred.predictedidx~=0 
    cur_scores = handles.data.NormalizeScores(pred.scoresidx);
    set(handles.text_scores,'String',sprintf('%+.2f',cur_scores));
  else
    set(handles.text_scores,'String','');
  end
    
end
if refresh_timeline_suggest && ~handles.data.IsGTMode(),
  set(handles.guidata.htimeline_suggestions,'XData',handles.guidata.labels_plot.suggest_xs,...
    'YData',zeros(size(handles.guidata.labels_plot.suggest_xs))+1.5);
  %set(handles.himage_timeline_suggest,'CData',handles.guidata.labels_plot.suggested_im);
end
if refresh_timeline_error,
  set(handles.guidata.htimeline_errors,'XData',handles.guidata.labels_plot.error_xs,...
  'YData',zeros(size(handles.guidata.labels_plot.error_xs))+1.5);
  %set(handles.himage_timeline_error,'CData',handles.guidata.labels_plot.error_im);
end
if refresh_GT_suggestion && ~isempty(fieldnames(handles.guidata.labels_plot)),
  set(handles.guidata.htimeline_gt_suggestions,'XData',handles.guidata.labels_plot.suggest_gt,...
    'YData',zeros(size(handles.guidata.labels_plot.suggest_gt))+1.5);
end


if refresh_timeline_xlim,
  xlim = [handles.guidata.ts(1)-(handles.guidata.timeline_nframes-1)/2,...
    handles.guidata.ts(1)+(handles.guidata.timeline_nframes-1)/2];
  for i = 1:numel(handles.guidata.axes_timelines),
    set(handles.guidata.axes_timelines(i),'XLim',xlim);
    %zoom(handles.guidata.axes_timelines(i),'reset');
  end
end


if refresh_timeline_hcurr,
  set(handles.guidata.hcurr_timelines,'XData',handles.guidata.ts([1,1]));
end
if refresh_timeline_selection,
  tmp = handles.guidata.selected_ts + .5*[-1,1];
  set(handles.guidata.hselection,'XData',tmp([1,1,2,2,1]));
end

if refresh_timeline_props,
  for propi = 1:numel(handles.guidata.perframepropis),
    v = handles.guidata.perframepropis(propi);
    [perframedata,T0,T1] = handles.data.GetPerFrameData(handles.data.expi,handles.data.flies,v);
    set(handles.guidata.htimeline_data(propi),'XData',T0:T1,...
      'YData',perframedata);
    %if isnan(handles.guidata.timeline_data_ylims(1,v)),
      ylim = [min(perframedata),max(perframedata)];
      if ylim(2) <= ylim(1),
        ylim(2) = ylim(1)+1;
      end
      set(handles.guidata.axes_timeline_props(propi),'YLim',ylim);
      zoom(handles.guidata.axes_timeline_props(propi),'reset');
    %end
    if ~isnan(handles.guidata.timeline_data_ylims(1,v)),
      ylim = handles.guidata.timeline_data_ylims(:,v);
      set(handles.guidata.axes_timeline_props(propi),'YLim',ylim);
    end
    ydata = [ylim(1)+diff(ylim)*.025,ylim(2)-diff(ylim)*.025];
    set(handles.guidata.hselection(propi),'YData',ydata([1,2,2,1,1]));      
  end
end

for i = axes2,
  
  if refreshim,
    
    if handles.data.ismovie && handles.guidata.shouldOpenMovieIfPresent && handles.guidata.thisMoviePresent ,
      j = find((Mframenum.Data==handles.guidata.ts(i)) & ...
               (~isnan(Mlastused.Data)) & ...
               (Mlastused.Data>0) ...
               ,1,'first');
      %if(numel(j)>1)  j=j(1);  end
      cache_total=cache_total+1;
      if isempty(j),
        cache_miss=cache_miss+1;
        j = find(Mframenum.Data==handles.guidata.ts(i));
        
        if isempty(j)
            tmp=find(Mlastused.Data>=0);
            j=tmp(argmin(Mlastused.Data(tmp)));
            if isempty(j), % If all frames last used is nan i.e., they are waiting to be cached.
                j = find(isnan(Mlastused.Data),1);
            end
        end
        %j = argmin(Mlastused.Data);
        Mlastused.Data(j) = -1;
        Mframenum.Data(j) = handles.guidata.ts(i);
        Mimage.Data(j).x = uint8(handles.guidata.readframe(handles.guidata.ts(i)));
        % ALT: Added uint8() 2012-09-14.  Without that, threw error when
        % loading a .fmf file, which led to handles.guidata.readframe(handles.guidata.ts(i))
        % being of class double
        if debug_cache
        fprintf('%s\n',['frame #' num2str(handles.guidata.ts(i)) ' NOT CACHED, len queue = ' ...
             num2str(sum(isnan(Mlastused.Data))) ', miss rate = ' num2str(cache_miss/cache_total*100) '%']);
        end
      else
        ClearStatus(handles);
      end
      Mlastused.Data(j) = now;
      set(handles.guidata.himage_previews(i),'CData',Mimage.Data(j).x);
      
      idx=find(strncmp('spacetime',handles.data.allperframefns(handles.guidata.perframepropis),9));
      if (~isempty(idx) && (handles.guidata.ts(i)+1) <= handles.data.GetEndFrames{handles.data.expi}(handles.data.flies(1)))
        fly=handles.data.flies(1);
        if (isempty(exp_next) || (exp_next ~= handles.data.expi) || ...
            isempty(fly_next) || (fly_next ~= fly) || ...
            isempty(ts_next) || (ts_next ~= handles.guidata.ts(i)))
          ts=handles.guidata.ts(i);
          imnorm = compute_spacetime_transform(Mimage.Data(j).x, ...
              handles.data.GetTrxValues('X1',handles.data.expi,fly,ts), ...
              handles.data.GetTrxValues('Y1',handles.data.expi,fly,ts), ...
              handles.data.GetTrxValues('Theta1',handles.data.expi,fly,ts), ...
              handles.data.GetTrxValues('A1',handles.data.expi,fly,ts), ...
              handles.data.GetTrxValues('B1',handles.data.expi,fly,ts),...
              handles.spacetime.meana, handles.spacetime.meanb);
        end

        j_next = find((Mframenum.Data==(handles.guidata.ts(i)+1)) & ...
                 (~isnan(Mlastused.Data)) & ...
                 (Mlastused.Data>0) ...
                 ,1,'first');
        cache_total=cache_total+1;
        if isempty(j_next),
          cache_miss=cache_miss+1;
          tmp=find(Mlastused.Data>=0);
          j_next=tmp(argmin(Mlastused.Data(tmp)));
          if isempty(j_next), % If all frames last used is nan i.e., they are waiting to be cached.
            j_next = find(isnan(Mlastused.Data),1);
          end
          %j_last = argmin(Mlastused.Data);
          Mlastused.Data(j_next) = -1;
          Mframenum.Data(j_next) = handles.guidata.ts(i)+1;
          Mimage.Data(j_next).x = uint8(handles.guidata.readframe(handles.guidata.ts(i)+1));
          fprintf('%s\n',['frame #' num2str(handles.guidata.ts(i)) ' NOT CACHED, len queue = ' ...
               num2str(sum(isnan(Mlastused.Data))) ', miss rate = ' num2str(cache_miss/cache_total*100) '%']);
        else
          ClearStatus(handles);
        end
        Mlastused.Data(j_next) = now;

        ts=handles.guidata.ts(i)+1;
        imnorm_next = compute_spacetime_transform(Mimage.Data(j_next).x, ...
            handles.data.GetTrxValues('X1',handles.data.expi,fly,ts), ...
            handles.data.GetTrxValues('Y1',handles.data.expi,fly,ts), ...
            handles.data.GetTrxValues('Theta1',handles.data.expi,fly,ts), ...
            handles.data.GetTrxValues('A1',handles.data.expi,fly,ts), ...
            handles.data.GetTrxValues('B1',handles.data.expi,fly,ts),...
            handles.spacetime.meana, handles.spacetime.meanb);

        rb_nog(:,:,1)=imnorm_next;
        rb_nog(:,:,2)=imnorm;
        rb_nog(:,:,3)=imnorm;
        exp_next = handles.data.expi;
        fly_next = fly;
        ts_next = ts;
        imnorm = imnorm_next;
        for l=1:length(handles.spacetime.mask)
          image(rb_nog,'parent',handles.spacetime.ax(l));
          axis(handles.spacetime.ax(l),'image');
          axis(handles.spacetime.ax(l),'off');
          for k=1:length(handles.spacetime.featureboundaries{handles.spacetime.mask(l)})
            handles.data.GetPerFrameData(handles.data.expi,handles.data.flies,...
                ['spacetime_' handles.spacetime.featurenames{handles.spacetime.mask(l)}{k}], ...
                handles.guidata.ts(i), handles.guidata.ts(i));
            color=(ans-handles.spacetime.prc1)/(handles.spacetime.prc99-handles.spacetime.prc1);
            color=min(1,max(0,color));
            for m=1:length(handles.spacetime.featureboundaries{handles.spacetime.mask(l)}{k})
              line(handles.spacetime.featureboundaries{handles.spacetime.mask(l)}{k}{m}(:,2), ...
                   handles.spacetime.featureboundaries{handles.spacetime.mask(l)}{k}{m}(:,1),...
                  'color',[0 color 0],'parent',handles.spacetime.ax(l));
            end
            text(handles.spacetime.featurecenters{handles.spacetime.mask(l)}{k}(1), ...
                 handles.spacetime.featurecenters{handles.spacetime.mask(l)}{k}(2),...
                 handles.spacetime.featurenames{handles.spacetime.mask(l)}{k},'Interpreter','none','HorizontalAlignment','center',...
                'color',[0 color 0],'parent',handles.spacetime.ax(l));
          end
        end
%         end
      end

      % remove from the queue frames preceeding current frame
      j=(Mframenum.Data<handles.guidata.ts(i)) & isnan(Mlastused.Data);
      if(sum(j)>0)
        %disp(['unqueueing frame(s) ' num2str(Mframenum.Data(j)')...
        %    '; current frame = ' num2str(handles.guidata.ts(i))]);
        Mlastused.Data(j) = 0;
        Mframenum.Data(j) = 0;
      end

      % add to the queue frames subsequent to current frame
      tmp=min(handles.guidata.cache_size,handles.guidata.nframes_jump_go);
      j=setdiff(handles.guidata.ts(i)+[1:tmp -1 -tmp], ...
                Mframenum.Data);
      j=j(find(j>=handles.data.GetMinFirstFrame & j<=handles.data.GetMaxEndFrame));  %#ok
      
      [y,idx]=sort(Mlastused.Data);
      
      idx1=find(y>=0,1,'first');
      idx2=min([-1+idx1+length(j) -1+find(isnan(y),1,'first')]);
      idx=idx(idx1:idx2);
      %idx=idx(1:min([length(j) -1+find(isnan(y),1,'first')]));
      if(~isempty(idx))
        Mframenum.Data(idx) = j(1:length(idx));
        Mlastused.Data(idx) = nan;
      end

    else
      
      set(handles.guidata.himage_previews(i),'Visible','off');
    end
    
  end
  
  % update current position
  if refreshflies,
    if handles.guidata.ts(i) < handles.data.t0_curr || handles.guidata.ts(i) > handles.data.t1_curr,
      labelidx = [];
    elseif handles.guidata.label_state ~= 0,
      labelidx = handles.guidata.label_state;
    elseif handles.guidata.plot_labels_manual,
      labelidxStruct = handles.data.GetLabelIdx(handles.data.expi,handles.data.flies,handles.guidata.ts(i),handles.guidata.ts(i));
      labelidx = labelidxStruct.vals;
    elseif handles.guidata.plot_labels_automatic,
       prediction = handles.data.GetPredictedIdx(handles.data.expi,handles.data.flies,handles.guidata.ts(i),handles.guidata.ts(i));
       labelidx = prediction.predictedidx;
    end
    inbounds = handles.data.firstframes_per_exp{handles.data.expi} <= handles.guidata.ts(i) & ...
      handles.data.endframes_per_exp{handles.data.expi} >= handles.guidata.ts(i);
    
    % indices that will be removed
    goodidx = find(handles.guidata.idx2fly~=0);
    idxremove = goodidx(find(~inbounds(handles.guidata.idx2fly(goodidx))));  %#ok
    fliesadd = find(inbounds & handles.guidata.fly2idx==0);
    if ~isempty(idxremove),
      handles.guidata.fly2idx(~inbounds) = 0;
      handles.guidata.idx2fly(idxremove) = 0;
    end
    idxfree = find(handles.guidata.idx2fly==0);
    if ~isempty(fliesadd),
      for j = 1:numel(fliesadd),
        fly = fliesadd(j);
        handles.guidata.fly2idx(fly) = idxfree(j);
        handles.guidata.idx2fly(idxfree(j)) = fly;
        set(handles.guidata.hflies(idxfree(j),i),'Color',handles.guidata.fly_colors(fly,:));
        set(handles.guidata.hflies_extra(idxfree(j),:,i),...
          'Color',handles.guidata.fly_colors(fly,:),...
          'MarkerFaceColor',handles.guidata.fly_colors(fly,:));
        set(handles.guidata.hfly_markers(idxfree(j),i),...
          'Color',handles.guidata.fly_colors(fly,:));
      end
    end
    if handles.doplottracks,
      isinvisible = handles.guidata.idx2fly == 0;
      set(handles.guidata.hflies(isinvisible,i),'Visible','off');
      set(handles.guidata.hflies_extra(isinvisible,:,i),'Visible','off');
      set(handles.guidata.hfly_markers(isinvisible,i),'Visible','off');
      set(handles.guidata.hflies(~isinvisible,i),'Visible','on');
      set(handles.guidata.hflies_extra(~isinvisible,:,i),'Visible','on');
      set(handles.guidata.hfly_markers(~isinvisible,i),'Visible','on');
    end
    
    allflypredictions = handles.data.GetPredictionsAllFlies(...
      handles.data.expi,handles.guidata.ts(i),find(inbounds));
    
    count = 0;
    for fly = find(inbounds),
      count = count+1;
      t = handles.guidata.ts(i);
      pos = handles.data.GetTrxPos1(handles.data.expi,fly,t);
      j = handles.guidata.fly2idx(fly);
      UpdateTargetPosition(handles.data.targettype,handles.guidata.hflies(j,i),...
        handles.guidata.hflies_extra(j,:,i),pos);
      
      if handles.guidata.showPredictionsAllFlies
        if allflypredictions(count) ==0
          curcolor = handles.guidata.labelunknowncolor;
        else
          curcolor = handles.guidata.labelcolors(allflypredictions(count),:);
        end
        set([handles.guidata.hflies(j,i) handles.guidata.hfly_markers(j,i)],...
          'Color',curcolor);
        if ~isempty(handles.guidata.hflies_extra)
          set(handles.guidata.hflies_extra(j,i),'Color',curcolor);
        end
      end

      set(handles.guidata.hfly_markers(j,i),'XData',pos.x,'YData',pos.y);
      sexcurr = handles.data.GetSex1(handles.data.expi,fly,t);
      if lower(sexcurr(1)) == 'm' && handles.doplottracks,
        set(handles.guidata.hfly_markers(j,i),'Visible','on');
      else
        set(handles.guidata.hfly_markers(j,i),'Visible','off');
      end
%       updatefly(handles.guidata.hflies(fly,i),...
%         handles.data.GetTrxX1(handles.data.expi,fly,t),...
%         handles.data.GetTrxY1(handles.data.expi,fly,t),...
%         handles.data.GetTrxTheta1(handles.data.expi,fly,t),...
%         handles.data.GetTrxA1(handles.data.expi,fly,t),...
%         handles.data.GetTrxB1(handles.data.expi,fly,t));
%       j = handles.guidata.ts(i) + handles.data.trx(fly).off;
%       updatefly(handles.guidata.hflies(fly,i),handles.data.trx(fly).x(j),...
%         handles.data.trx(fly).y(j),...
%         handles.data.trx(fly).theta(j),...
%         handles.data.trx(fly).a(j),...
%         handles.data.trx(fly).b(j));
      %updatefly(handles.guidata.hflies(fly,i),trx(fly).x,trx(fly).y,trx(fly).theta,trx(fly).a,trx(fly).b);
      if ismember(fly,handles.data.flies),
        set(handles.guidata.hfly_markers(j,i),'Visible','on');
        set(handles.guidata.hflies(j,i),'LineWidth',3);
      else
        set(handles.guidata.hflies(j,i),'LineWidth',1);
      end
      
      if ismember(fly,handles.data.flies) && ~handles.guidata.showPredictionsAllFlies,
        if labelidx <= 0,
          set(handles.guidata.hflies(j,i),'Color',handles.guidata.labelunknowncolor);
          set(handles.guidata.hflies_extra(j,:,i),'Color',handles.guidata.labelunknowncolor,...
            'MarkerFaceColor',handles.guidata.labelunknowncolor);
        else
          set(handles.guidata.hflies(j,i),'Color',handles.guidata.labelcolors(labelidx,:),...
            'MarkerFaceColor',handles.guidata.labelcolors(labelidx,:));
        end
      end
    end
    
    if strcmpi(handles.guidata.preview_zoom_mode,'center_on_fly'),
      ZoomInOnFlies(handles,i);
    elseif strcmpi(handles.guidata.preview_zoom_mode,'follow_fly'),
      KeepFliesInView(handles,i);
    end    
  end

  % update trx
  nprev = handles.guidata.traj_nprev;
  npost = handles.guidata.traj_npost;
  if refreshtrx,
    for j = 1:numel(handles.data.flies),
      fly = handles.data.flies(j);
      tmp = handles.guidata.ts(i);
      t0 = handles.data.firstframes_per_exp{handles.data.expi}(fly);
      t1 = handles.data.endframes_per_exp{handles.data.expi}(fly);
      ts = max(t0,tmp-nprev):min(t1,tmp+npost);
      set(handles.guidata.htrx(j,i),'XData',handles.data.GetTrxValues('X1',handles.data.expi,fly,ts),...
        'YData',handles.data.GetTrxValues('Y1',handles.data.expi,fly,ts));
      %j0 = max(1,tmp-nprev);
      %j1 = min(handles.data.trx(fly).nframes,tmp+npost);
      %set(handles.guidata.htrx(j,i),'XData',handles.data.trx(fly).x(j0:j1),...
      %  'YData',handles.data.trx(fly).y(j0:j1));
      %trx = handles.data.GetTrx(handles.data.expi,fly,handles.guidata.ts(i)-nprev:handles.guidata.ts(i)+npost);
      %set(handles.guidata.htrx(j,i),'XData',trx.x,'YData',trx.y);
    end
  end  
  
  % update labels plotted
  if refreshlabels,
    for k = 1:numel(handles.data.flies),
      fly = handles.data.flies(k);
      T0 = handles.data.firstframes_per_exp{handles.data.expi}(fly);
      T1 = handles.data.endframes_per_exp{handles.data.expi}(fly);
%       T0 = handles.data.GetTrxFirstFrame(handles.data.expi,fly);
%       T1 = handles.data.GetTrxEndFrame(handles.data.expi,fly);
      t0 = min(T1,max(T0,handles.guidata.ts(i)-nprev));
      t1 = min(T1,max(T0,handles.guidata.ts(i)+npost));
      for j = 1:handles.data.nbehaviors,
        xplot = handles.guidata.labels_plot.x(:,handles.guidata.labels_plot_off+t0:handles.guidata.labels_plot_off+t1,j,k);
        yplot = handles.guidata.labels_plot.y(:,handles.guidata.labels_plot_off+t0:handles.guidata.labels_plot_off+t1,j,k);
        set(handles.guidata.hlabels(j),'XData',xplot(:),'YData',yplot(:));
        xpred = handles.guidata.labels_plot.predx(:,handles.guidata.labels_plot_off+t0:handles.guidata.labels_plot_off+t1,j,k);
        ypred = handles.guidata.labels_plot.predy(:,handles.guidata.labels_plot_off+t0:handles.guidata.labels_plot_off+t1,j,k);
        set(handles.guidata.hpredicted(j),'XData',xpred(:),'YData',ypred(:));
      end
      if handles.guidata.label_state ~= 0,
        ts = sort([handles.label_t0,handles.guidata.ts(1)]);
        t0 = max(t0,ts(1));
        t1 = min(t1,ts(2)+1);
        xdata = handles.data.GetTrxValues('X1',handles.data.expi,handles.data.flies(1),t0:t1);
        ydata = handles.data.GetTrxValues('Y1',handles.data.expi,handles.data.flies(1),t0:t1);
        set(handles.guidata.hlabel_curr(1),'XData',xdata,'YData',ydata);
        if handles.guidata.label_state == -1,
          set(handles.guidata.hlabel_curr(1),'Color',handles.guidata.labelunknowncolor);
        else
          set(handles.guidata.hlabel_curr(1),'Color',handles.guidata.labelcolors(handles.guidata.label_state,:));
        end
      else
        set(handles.guidata.hlabel_curr(1),'XData',nan,'YData',nan);
      end

    end
  end
  
  if refresh_curr_prop,
    for propi = 1:numel(handles.guidata.perframepropis),
      v = handles.guidata.perframepropis(propi);
      if handles.guidata.ts(i) < handles.data.t0_curr || handles.guidata.ts(i) > handles.data.t1_curr,
        s = '';
      else
        perframedata = handles.data.GetPerFrameData1(handles.data.expi,handles.data.flies,v,handles.guidata.ts(i));
        s = sprintf('%.3f',perframedata);
      end
      if numel(handles.guidata.text_timeline_props) >= propi && ishandle(handles.guidata.text_timeline_props(propi)),
        set(handles.guidata.text_timeline_props(propi),'String',s);
      end
    end
  end
  
  %drawnow;
  
end
return


% -------------------------------------------------------------------------
function [handles,success] = SetCurrentMovie(handles,expi)

% success = false;

if expi == handles.data.expi,
  success = true;
  return;
end

% check that the current movie exists
handles.guidata.thisMoviePresent=false;
if handles.data.ismovie && handles.guidata.shouldOpenMovieIfPresent,
  [moviefilename,timestamp] = handles.data.GetFile('movie',expi);
  if isinf(timestamp) && ~exist(moviefilename,'file'),
    uiwait(warndlg(sprintf('Movie file %s does not exist for current experiment.  No movie will be shown.',moviefilename), ...
                   'Error setting movie'));
    handles.guidata.thisMoviePresent=false;             
  else
    handles.guidata.thisMoviePresent=true;
  end

  % close previous movie
  if ~isempty(handles.guidata.movie_fid) && ~isempty(fopen(handles.guidata.movie_fid)),
    if ~isempty(handles.guidata.movie_fid) && handles.guidata.movie_fid > 0,
      fclose(handles.guidata.movie_fid);
    end
  end

  if handles.guidata.thisMoviePresent ,
    SetStatus(handles,'Opening movie...');
    %if 1,
    [handles.guidata.readframe,handles.guidata.nframes,handles.guidata.movie_fid,handles.guidata.movieheaderinfo] = ...
      get_readframe_fcn(moviefilename);
    %else
    %  fprintf('DEBUG!!!! USING GLOBAL VARIABLE WITH MOVIE READFRAME !!!DEBUG\n');
    %  global JLABEL__READFRAME;
    %  handles.guidata.readframe = JLABEL__READFRAME.readframe;
    %  handles.guidata.nframes = JLABEL__READFRAME.nframes;
    %  handles.guidata.movie_fid = JLABEL__READFRAME.movie_fid;
    %  handles.guidata.movieheaderinfo = JLABEL__READFRAME.movieheaderinfo;
    %end
    im = handles.guidata.readframe(1);
    handles.guidata.movie_depth = size(im,3);
    handles.guidata.movie_width = size(im,2);
    handles.guidata.movie_height = size(im,1);
    handles.guidata.movie_filename = moviefilename;
    % catch ME,
    %   uiwait(warndlg(sprintf('Error opening movie file %s: %s',moviefilename,getReport(ME)),'Error setting movie'));
    %   ClearStatus(handles);
    %   return;
    % end
  end
  
end

% number of flies
% handles.guidata.nflies_curr = handles.data.nflies_per_exp(expi);

% choose flies
if handles.data.nTargetsInCurrentExp == 0,
  flies = [];
else
  flies = 1;
end

% load trx
[success,msg] = handles.data.setCurrentTarget(expi,flies);
if ~success,
  uiwait(errordlg(sprintf('Error loading data for experiment %d: %s',expi,msg)));
  return;
end

% if no movie, then set limits, or we don't want to use
if ~(handles.data.ismovie && handles.guidata.shouldOpenMovieIfPresent && handles.guidata.thisMoviePresent),
  maxx = max([handles.data.trx.x]+[handles.data.trx.a]*2);
  maxy = max([handles.data.trx.y]+[handles.data.trx.a]*2);
  handles.guidata.movie_height = ceil(maxy);
  handles.guidata.movie_width = ceil(maxx);
  handles.guidata.nframes = max([handles.data.trx.endframe]);

  % remove old grid
  delete(handles.guidata.bkgdgrid(ishandle(handles.guidata.bkgdgrid)));

  % grid width
  gridwidth = nanmean([handles.data.trx.a])*5;

  % create new grid
  handles.guidata.bkgdgrid = nan(2,numel(handles.guidata.axes_previews));
  xgrid = gridwidth/2:gridwidth:handles.guidata.movie_width;
  xgrid1 = [xgrid;xgrid;nan(1,numel(xgrid))];
  xgrid2 = [zeros(1,numel(xgrid));handles.guidata.movie_height+ones(1,numel(xgrid));nan(1,numel(xgrid))];
  ygrid = gridwidth/2:gridwidth:handles.guidata.movie_height;
  ygrid2 = [ygrid;ygrid;nan(1,numel(ygrid))];
  ygrid1 = [zeros(1,numel(ygrid));handles.guidata.movie_width+ones(1,numel(ygrid));nan(1,numel(ygrid))];
  for i = 1:numel(handles.guidata.axes_previews),
    holdstate = ishold(handles.guidata.axes_previews(i));
    hold(handles.guidata.axes_previews(i),'on');
    handles.guidata.bkgdgrid(1,i) = plot(handles.guidata.axes_previews(i),xgrid1(:),xgrid2(:),'--','Color',[.7,.7,.7],'LineWidth',.5,'HitTest','off');
    handles.guidata.bkgdgrid(2,i) = plot(handles.guidata.axes_previews(i),ygrid1(:),ygrid2(:),'--','Color',[.7,.7,.7],'LineWidth',.5,'HitTest','off');
    if ~holdstate,
      hold(handles.guidata.axes_previews(i),'off');
    end
      
  end
  
  % set axes colors to be white instead of black
  set(handles.guidata.axes_previews,'Color','w');
  
end

% set zoom radius
if isnan(handles.guidata.zoom_fly_radius(1)),
  tmp = [handles.data.trx.a];
  handles.guidata.meana = nanmean(tmp(:));
  handles.guidata.zoom_fly_radius = handles.guidata.meana*20 + [0,0];
end
for previewi = 1:numel(handles.guidata.axes_previews),
  [handles] = UpdateZoomFlyRadius(handles,previewi,true);
end
  

% count the maximum number of flies in any frames
off = 1-min(handles.data.firstframes_per_exp{expi});
nflies_per_frame = zeros(1,max(handles.data.endframes_per_exp{expi}+off));
for fly = 1:handles.data.nflies_per_exp(expi),
  i0 = handles.data.firstframes_per_exp{expi}(fly)+off;
  i1 = handles.data.endframes_per_exp{expi}(fly)+off;
  nflies_per_frame(i0:i1) = nflies_per_frame(i0:i1) + 1;
end
maxnflies_curr = max(nflies_per_frame);

% handles.data.expi = expi;

ClearStatus(handles);

% TODO: change hard-coded colormap
% update colors
nTargetsInCurrentExp=handles.data.nTargetsInCurrentExp;
nColors=fif(isempty(nTargetsInCurrentExp),0,nTargetsInCurrentExp);
handles.guidata.fly_colors = jet(nColors)*.7;
handles.guidata.fly_colors = fif(handles.data.getColorAssignment,...
  handles.guidata.fly_colors(randperm(nColors),:),...
  handles.guidata.fly_colors);

% delete old fly current positions
if ~isempty(handles.guidata.hflies),
  delete(handles.guidata.hflies(ishandle(handles.guidata.hflies)));
  handles.guidata.hflies = [];
end
if ~isempty(handles.guidata.hflies_extra),
  delete(handles.guidata.hflies_extra(ishandle(handles.guidata.hflies_extra)));
  handles.guidata.hflies_extra = [];
end
if ~isempty(handles.guidata.hfly_markers),
  delete(handles.guidata.hfly_markers(ishandle(handles.guidata.hfly_markers)));
  handles.guidata.hfly_markers = [];
end

% update plotted trx handles, as number of flies will change
nPreviewAxes=numel(handles.guidata.axes_previews);
handles.guidata.hflies = nan(maxnflies_curr,nPreviewAxes);
handles.guidata.hflies_extra = nan(maxnflies_curr,handles.data.trxGraphicParams.nextra_markers,nPreviewAxes);
handles.guidata.hfly_markers = nan(maxnflies_curr,nPreviewAxes);
handles.guidata.idx2fly = zeros(1,maxnflies_curr);
handles.guidata.fly2idx = zeros(1,handles.data.nTargetsInCurrentExp);

for i = 1:nPreviewAxes,
  % fly current positions
  for fly = 1:maxnflies_curr,
    % handles.guidata.hflies(fly,i) = plot(handles.guidata.axes_previews(i),nan,nan,'-',...
    %   'color',handles.guidata.fly_colors(fly,:),'linewidth',3,...
    %   'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i));
    handles.guidata.hflies(fly,i) = ...
      line('parent',handles.guidata.axes_previews(i), ...
           'xdata',nan, ...
           'ydata',nan, ...
           'linestyle','-',...
           'color',handles.guidata.fly_colors(fly,:), ...
           'linewidth',3,...
           'ButtonDownFcn', ...
             @(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i));
    % handles.guidata.hflies_extra(fly,i) = plot(handles.guidata.axes_previews(i),nan,nan,...
    %   'Marker',handles.guidata.flies_extra_marker,...
    %   'Color',handles.guidata.fly_colors(fly,:),'MarkerFaceColor',handles.guidata.fly_colors(fly,:),...
    %   ...'LineStyle',handles.guidata.flies_extra_linestyle,...
    %   'MarkerSize',handles.guidata.flies_extra_markersize,...
    %   'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i));
    for j = 1:handles.data.trxGraphicParams.nextra_markers,
      handles.guidata.hflies_extra(fly,j,i) = ...
          line('parent',handles.guidata.axes_previews(i), ...
               'xdata',nan, ...
               'ydata',nan, ...
               'Marker',handles.data.trxGraphicParams.extra_marker{j}, ...
               'Color',handles.guidata.fly_colors(fly,:), ...
               'MarkerFaceColor',handles.guidata.fly_colors(fly,:), ...
               'LineStyle',handles.data.trxGraphicParams.extra_linestyle{j}, ...
               'MarkerSize',handles.data.trxGraphicParams.extra_markersize(j), ...
               'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i));
    end
    % handles.guidata.hfly_markers(fly,i) = plot(handles.guidata.axes_previews(i),nan,nan,'*',...
    %   'color',handles.guidata.fly_colors(fly,:),'linewidth',3,...
    %   'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i),...
    %   'Visible','off');
    handles.guidata.hfly_markers(fly,i) = ...
      line('parent',handles.guidata.axes_previews(i), ...
           'xdata',nan, ...
           'ydata',nan, ...
           'marker','*', ...
           'color',handles.guidata.fly_colors(fly,:), ...
           'linewidth',3, ...
           'ButtonDownFcn',@(hObject,eventdata) JLabel('fly_ButtonDownFcn',hObject,eventdata,guidata(hObject),fly,i),...
           'Visible','off');
  end
end

% set flies
handles = SetCurrentFlies(handles,flies,true,false);

% update slider steps, range
for i = 1:numel(handles.guidata.slider_previews),
  set(handles.guidata.slider_previews(i),'Min',1,'Max',handles.guidata.nframes,...
    'Value',1,...
    'SliderStep',[1/(handles.guidata.nframes-1),100/(handles.guidata.nframes-1)]);
end

% choose frame
for i = 1:numel(handles.guidata.axes_previews),
  handles = SetCurrentFrame(handles,i,handles.data.t0_curr,nan,true,false);
end

% update zoom
for i = 1:numel(handles.guidata.axes_previews),
  axis(handles.guidata.axes_previews(i),[.5,handles.guidata.movie_width+.5,.5,handles.guidata.movie_height+.5]);
end
for i = 1:numel(handles.guidata.axes_previews),
  zoom(handles.guidata.axes_previews(i),'reset');
end

% update plot
UpdatePlots(handles,'refresh_timeline_props',true,'refresh_timeline_selection',true);
ZoomInOnFlies(handles);

for h = handles.guidata.axes_timeline_labels,
  zoom(h,'reset');
end

% enable GUI components
UpdateEnablementAndVisibilityOfControls(handles);

success = true;
return


% -------------------------------------------------------------------------
function handles = UnsetCurrentMovie(handles)

% Unset the target in the model
handles.data.unsetCurrentTarget();

% close previous movie
if ~isempty(handles.guidata.movie_fid) && ~isempty(fopen(handles.guidata.movie_fid)) && ...
    handles.guidata.movie_fid~=0,
  fclose(handles.guidata.movie_fid);
end

% handles.data.expi = 0;
% handles.data.flies = nan(1,handles.guidata.nflies_label);
handles.guidata.ts = zeros(1,numel(handles.guidata.axes_previews));
handles.guidata.label_state = 0;
handles.guidata.label_imp = [];
% handles.data.nTargetsInCurrentExp = 0;
% delete old fly current positions
if ~isempty(handles.guidata.hflies),
  delete(handles.guidata.hflies(ishandle(handles.guidata.hflies)));
  handles.guidata.hflies = [];
end
if ~isempty(handles.guidata.hflies_extra),
  delete(handles.guidata.hflies_extra(ishandle(handles.guidata.hflies_extra)));
  handles.guidata.hflies_extra = [];
end
if ~isempty(handles.guidata.hfly_markers),
  delete(handles.guidata.hfly_markers(ishandle(handles.guidata.hfly_markers)));
  handles.guidata.hfly_markers = [];
end

syncStatusBarTextWhenClear(handles)

% % Update the GUI
% UpdateGUIToMatchMovieState(handles);

return


% -------------------------------------------------------------------------
function i = GetPreviewPanelNumber(hObject)

i = regexp(get(get(hObject,'Parent'),'Tag'),'^panel_axes(\d+)$','tokens','once');
if isempty(i),
  warning('Could not find index of parent panel'); 
  i = 1;
else
  i = str2double(i{1});
end
return


% -------------------------------------------------------------------------
% --- Executes on slider movement.
function slider_preview_Callback(hObject, eventdata, handles) %#ok<*DEFNU>
% hObject    handle to slider_preview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% get slider value
% t = min(max(1,round(get(hObject,'Value'))),handles.guidata.nframes);
t = min(max(handles.data.GetMinFirstFrame,round(get(hObject,'Value'))),handles.data.GetMaxEndFrame);
set(hObject,'Value',t);
% which preview panel is this
i = GetPreviewPanelNumber(hObject);

% set current frame
SetCurrentFrame(handles,i,t,hObject);
return


% -------------------------------------------------------------------------
function handles = SetCurrentFlies(handles,flies,doforce,doupdateplot)

if ~exist('doforce','var'),
  doforce = false;
end
if ~exist('doupdateplot','var'),
  doupdateplot = true;
end

data=handles.data;  % a ref
oldFlies=data.flies;
[success,msg] = data.setCurrentTarget(data.expi,flies);
if ~success,
  uiwait(waitdlg(sprintf('Error loading data for current set of flies: %s',msg)));
  return;
end

% same flies, return
if ~doforce && ...
   isempty(setdiff(flies,oldFlies)) && ...
   isempty(setdiff(oldFlies,flies)),
  return;
end

% handles.data.flies = flies;

% % frames these flies are both alive
% handles.guidata.t0_curr = max(data.GetTrxFirstFrame(handles.data.expi,handles.data.flies));
% handles.data.t1_curr = min(data.GetTrxEndFrame(handles.data.expi,handles.data.flies));

% form of labels for easier plotting:
% x, y positions of all labels
handles.guidata.labels_plot = struct;
n = handles.data.t1_curr-handles.data.t0_curr+1;
handles.guidata.labels_plot.im = zeros([1,n,3]);
handles.guidata.labels_plot.predicted_im = zeros([1,n,3]);
handles.guidata.labels_plot.suggest_xs = nan;
handles.guidata.labels_plot.error_xs = nan;
%handles.guidata.labels_plot.suggested_im = zeros([1,n,3]);
%handles.guidata.labels_plot.error_im = zeros([1,n,3]);
handles.guidata.labels_plot.x = nan(2,n,data.nbehaviors,numel(handles.data.flies));
handles.guidata.labels_plot.y = nan(2,n,data.nbehaviors,numel(handles.data.flies));
handles.guidata.labels_plot.predx = nan(2,n,data.nbehaviors,numel(handles.data.flies));
handles.guidata.labels_plot.predy = nan(2,n,data.nbehaviors,numel(handles.data.flies));
handles.guidata.labels_plot_off = 1-handles.data.t0_curr;
% set([handles.guidata.himage_timeline_manual,handles.guidata.himage_timeline_auto,...
%   handles.himage_timeline_error,handles.himage_timeline_suggest],...
%   'XData',[handles.data.t0_curr,handles.data.t1_curr]);
set([handles.guidata.himage_timeline_manual,handles.guidata.himage_timeline_auto],...
  'XData',[handles.data.t0_curr,handles.data.t1_curr]);

labelidxStruct = data.GetLabelIdx(handles.data.expi,flies);
labelidx = labelidxStruct.vals;

classifierPresent=data.classifierIsPresent();
if classifierPresent ,
  prediction = data.GetPredictedIdx(handles.data.expi,flies);
  predictedidx = prediction.predictedidx;
  scores = data.NormalizeScores(prediction.scoresidx);
end
for flyi = 1:numel(flies),
  fly = flies(flyi);
  x = data.GetTrxValues('X1',handles.data.expi,fly,handles.data.t0_curr:handles.data.t1_curr);
  y = data.GetTrxValues('Y1',handles.data.expi,fly,handles.data.t0_curr:handles.data.t1_curr);
  for behaviori = 1:data.nbehaviors
    idx = find(labelidx == behaviori);
    idx1 = min(idx+1,numel(x));
    handles.guidata.labels_plot.x(1,idx,behaviori,flyi) = x(idx);
    handles.guidata.labels_plot.x(2,idx,behaviori,flyi) = x(idx1);
    handles.guidata.labels_plot.y(1,idx,behaviori,flyi) = y(idx);
    handles.guidata.labels_plot.y(2,idx,behaviori,flyi) = y(idx1);
    
    if classifierPresent ,
      % idx = find(predictedidx == behaviori);
      idx = find((predictedidx == behaviori) & ...
        (abs(scores)>data.GetConfidenceThreshold(behaviori)));
      idx1 = min(idx+1,numel(x));
      handles.guidata.labels_plot.predx(1,idx,behaviori,flyi) = x(idx);
      handles.guidata.labels_plot.predx(2,idx,behaviori,flyi) = x(idx1);
      handles.guidata.labels_plot.predy(1,idx,behaviori,flyi) = y(idx);
      handles.guidata.labels_plot.predy(2,idx,behaviori,flyi) = y(idx1);
    end
  end
end
handles = UpdateTimelineImages(handles);

% which interval we're currently within
handles.guidata.current_interval = [];

% update timelines
set(handles.guidata.himage_timeline_manual,'CData',handles.guidata.labels_plot.im);
%axis(handles.axes_timeline_manual,[handles.data.t0_curr-.5,handles.data.t1_curr+.5,.5,1.5]);
set(handles.axes_timeline_manual,'xlim',[handles.data.t0_curr-.5,handles.data.t1_curr+.5]);
set(handles.axes_timeline_manual,'ylim',[.5 1.5]);
% update zoom
for h = handles.guidata.axes_timeline_labels,
  zoom(h,'reset');
end

% update trx colors
for i = 1:numel(handles.guidata.axes_previews),
  for j = 1:numel(handles.data.flies),
    fly = handles.data.flies(j);
    set(handles.guidata.htrx(j,i),'Color',handles.guidata.fly_colors(fly,:));
  end
end

% Update colors for all other flies. 
inbounds = data.firstframes_per_exp{handles.data.expi} <= handles.guidata.ts(i) & ...
  data.endframes_per_exp{handles.data.expi} >= handles.guidata.ts(i);

for i = 1:numel(handles.guidata.axes_previews),
  for j = 1:numel(handles.guidata.idx2fly),
    fly = handles.guidata.idx2fly(j);
    if fly == 0 || ~inbounds(fly),
      continue;
    end
    set(handles.guidata.hflies(j,i),'Color',handles.guidata.fly_colors(fly,:));
    set(handles.guidata.hflies_extra(j,:,i),'Color',handles.guidata.fly_colors(fly,:),...
      'MarkerFaceColor',handles.guidata.fly_colors(fly,:));
  end
end

% status bar text
% [~,expname] = myfileparts(data.expdirs{handles.data.expi});
% if numel(handles.data.flies) == 1,
%   handles.guidata.status_bar_text_when_clear = sprintf('%s, %s %d',expname,data.targettype,handles.data.flies);
% else
%   handles.guidata.status_bar_text_when_clear = [sprintf('%s, %d',expname,data.targettype),sprintf(' %d',handles.data.flies)];
%     % I don't understand the line above.  targettype is a string! ---ALT, march 18, 2013
% end
syncStatusBarTextWhenClear(handles);

% make sure frame is within bounds
isset = handles.guidata.ts ~= 0;
ts = max(handles.data.t0_curr,min(handles.data.t1_curr,handles.guidata.ts));
ts(~isset) = 0;
for i = 1:numel(ts),
  if ts(i) ~= handles.guidata.ts(i),
    handles = SetCurrentFrame(handles,i,ts(i),nan);
    handles.guidata.ts(i) = ts(i);
  end
end

ClearStatus(handles);

% TODO: generalize to multiple flies
s = GetTargetInfo(handles,flies(1));
set(handles.text_selection_info,'String',s);

guidata(handles.figure_JLabel,handles);

if doupdateplot,
  UpdatePlots(handles,'refresh_timeline_props',true,'refresh_timeline_selection',true);
end

return


% -------------------------------------------------------------------------
function handles = UpdateTimelineImages(handles)

% Note: this function directly accesses handles.data.labelidx,
% handles.data.predictedidx for speed, so make sure we've preloaded the
% right experiment, flies
% REMOVED!

% if handles.data.expi ~= handles.data.expi || ~all(handles.data.flies == handles.data.flies),
%   handles.data.Preload(handles.data.expi,handles.data.flies);
% end

if handles.data.nexps==0 ,
  return
end
handles.guidata.labels_plot.im(:) = 0;
labelidx = handles.data.GetLabelIdx(handles.data.expi,handles.data.flies);

for behaviori = 1:handles.data.nbehaviors
  idx = (labelidx.vals == behaviori) & labelidx.imp;
  curColor = handles.guidata.labelcolors(behaviori,:);
  for channel = 1:3,
    handles.guidata.labels_plot.im(1,idx,channel) = curColor(channel);
  end
  
  idx = (labelidx.vals == behaviori) & ~labelidx.imp;
  curColor = ShiftColor.decreaseIntensity(handles.guidata.labelcolors(behaviori,:));
  for channel = 1:3,
    handles.guidata.labels_plot.im(1,idx,channel) = curColor(channel);
  end
end

handles.guidata.labels_plot.predicted_im(:) = 0;
prediction= handles.data.GetPredictedIdx(handles.data.expi,handles.data.flies);
predictedidx = prediction.predictedidx;
scores = handles.data.NormalizeScores(prediction.scoresidx);

% Scores for the bottom row.
switch handles.guidata.bottomAutomatic
  case 'Validated'
    scores_bottom = handles.data.GetValidatedScores(handles.data.expi,handles.data.flies);
    scores_bottom = handles.data.NormalizeScores(scores_bottom);
  case 'Imported'
    [scores_bottom,prediction_bottom] = handles.data.GetLoadedScores(handles.data.expi,handles.data.flies);
    scores_bottom = handles.data.NormalizeScores(scores_bottom);
  case 'Old'
    scores_bottom = handles.data.GetOldScores(handles.data.expi,handles.data.flies);
    scores_bottom = handles.data.NormalizeScores(scores_bottom);
  case 'Postprocessed'
    [scores_bottom,prediction_bottom] =  handles.data.GetPostprocessedScores(handles.data.expi,handles.data.flies);
    scores_bottom = handles.data.NormalizeScores(scores_bottom);
  case 'None'
    scores_bottom = zeros(size(scores));
  case 'Distance'
    dist = handles.data.GetDistance(handles.data.expi,handles.data.flies);
    scores_bottom = zeros(size(scores));
  otherwise
    warndlg('Undefined scores type to display for the bottom part of the automatic');
end

if ~(any(strcmp(handles.guidata.bottomAutomatic,{'Postprocessed','Distance','Imported'})))
prediction_bottom = zeros(size(scores_bottom));
prediction_bottom(scores_bottom>0) = 1;
prediction_bottom(scores_bottom<0) = 2;
end

idxBottomScores = ~isnan(scores_bottom);
bottomScoreNdx = ceil(scores_bottom(idxBottomScores)*31)+32;

for behaviori = 1:handles.data.nbehaviors

  idxScores = predictedidx == behaviori ;
  idxPredict = idxScores & ...
    (abs(scores)>handles.data.GetConfidenceThreshold(behaviori));
  for channel = 1:3,
    
      handles.guidata.labels_plot.predicted_im(1,idxPredict,channel) = handles.guidata.labelcolors(behaviori,channel);
      handles.guidata.labels_plot.predicted_im(2,idxPredict,channel) = handles.guidata.labelcolors(behaviori,channel);
      scoreNdx = ceil(scores(idxScores)*31)+32;
      handles.guidata.labels_plot.predicted_im(3,idxScores,channel) = handles.guidata.scorecolor(scoreNdx,channel,1);
      handles.guidata.labels_plot.predicted_im(4,idxScores,channel) = handles.guidata.scorecolor(scoreNdx,channel,1);
    
      % bottom row scores.
      if strcmp(handles.guidata.bottomAutomatic,'Distance'),
        handles.guidata.labels_plot.predicted_im(5:6,:,channel) = repmat(1-dist(:)',[2 1 1]);
        handles.guidata.labels_plot.predicted_im(5:6,isnan(dist),channel) = 0;
        
      else
        handles.guidata.labels_plot.predicted_im(5,idxBottomScores,channel) = handles.guidata.scorecolor(bottomScoreNdx,channel,1);
        handles.guidata.labels_plot.predicted_im(6,prediction_bottom==behaviori,channel) = ...
          handles.guidata.labelcolors(behaviori,channel);
      end
  end    
  
end

[error_t0s,error_t1s] = get_interval_ends(labelidx.vals ~= 0 & predictedidx ~= 0 & ...
  labelidx.vals ~= predictedidx);
error_t0s = error_t0s + handles.data.t0_curr - 1.5;
error_t1s = error_t1s + handles.data.t0_curr - 1.5;
handles.guidata.labels_plot.error_xs = reshape([error_t0s;error_t1s;nan(size(error_t0s))],[1,numel(error_t0s)*3]);
set(handles.guidata.htimeline_errors,'XData',handles.guidata.labels_plot.error_xs,...
  'YData',zeros(size(handles.guidata.labels_plot.error_xs))+1.5);
  [suggest_t0s,suggest_t1s] = get_interval_ends(labelidx.vals == 0 & predictedidx ~= 0);
  suggest_t0s = suggest_t0s + handles.data.t0_curr - 1.5;
  suggest_t1s = suggest_t1s + handles.data.t0_curr - 1.5;
  handles.guidata.labels_plot.suggest_xs = reshape([suggest_t0s;suggest_t1s;nan(size(suggest_t0s))],[1,numel(suggest_t0s)*3]);
  [suggest_t0s,suggest_t1s] = get_interval_ends(handles.data.GetGTSuggestionIdx(handles.data.expi,handles.data.flies));
  suggest_t0s = suggest_t0s + handles.data.t0_curr - 1.5;
  suggest_t1s = suggest_t1s + handles.data.t0_curr - 1.5;
  handles.guidata.labels_plot.suggest_gt = reshape([suggest_t0s;suggest_t1s;nan(size(suggest_t0s))],[1,numel(suggest_t0s)*3]);
if ~handles.data.IsGTMode,
  set(handles.guidata.htimeline_suggestions,'XData',handles.guidata.labels_plot.suggest_xs,...
    'YData',zeros(size(handles.guidata.labels_plot.suggest_xs))+1.5);
else
  set(handles.guidata.htimeline_gt_suggestions,'XData',handles.guidata.labels_plot.suggest_gt,...
    'YData',zeros(size(handles.guidata.labels_plot.suggest_gt))+1.5);
end
%{
%handles.guidata.labels_plot.suggested_im(:) = 0;
%for behaviori = 1:handles.data.nbehaviors
%  idx = handles.data.suggestedidx == behaviori;
%  for channel = 1:3,
%    handles.guidata.labels_plot.suggested_im(1,idx,channel) = handles.guidata.labelcolors(behaviori,channel);
%  end
%end
%handles.guidata.labels_plot.error_im(:) = 0;
%idx = handles.data.erroridx == 1;
%for channel = 1:3,
%  handles.guidata.labels_plot.error_im(1,idx,channel) = handles.guidata.correctcolor(channel);
%end
%idx = handles.data.erroridx == 2;
%for channel = 1:3,
%  handles.guidata.labels_plot.error_im(1,idx,channel) = handles.guidata.incorrectcolor(channel);
%end
%}

handles.guidata.labels_plot.isstart = ...
cat(2,labelidx.vals(1)~=0,...
labelidx.vals(2:end)~=0 & ...
labelidx.vals(1:end-1)~=labelidx.vals(2:end));
return


% -------------------------------------------------------------------------
function handles = SetCurrentFrame(handles,i,t,hObject,doforce,doupdateplot)

if ~exist('doforce','var'),
  doforce = false;
end
if ~exist('doupdateplot','var'),
  doupdateplot = true;
end

t = round(t);

minFirstFrame = min(cell2mat(handles.data.GetFirstFrames(handles.data.expi)));
maxEndFrame = max(cell2mat(handles.data.GetEndFrames(handles.data.expi)));


if t<minFirstFrame || t>maxEndFrame,
  fprintf('Current frame is out of range for the current fly');
  t = min(max(minFirstFrame,round(pt(1,1))),maxEndFrame);
end


% check for change
if doforce || handles.guidata.ts(i) ~= t,

  handles.guidata.ts(i) = t;
  
  % update labels
%   if handles.guidata.label_state < 0,
%     handles = SetLabelPlot(handles,min(handles.data.t1_curr,max(handles.data.t0_curr,t)),0);
%   elseif handles.guidata.label_state > 0,
%     handles = SetLabelPlot(handles,min(handles.data.t1_curr,max(handles.data.t0_curr,t)),handles.guidata.label_state);
%   end
  
  % update slider
  if hObject ~= handles.guidata.slider_previews(i),
    set(handles.guidata.slider_previews(i),'Value',t);
  end

  % update frame number edit box
  if hObject ~= handles.guidata.edit_framenumbers(i),
    set(handles.guidata.edit_framenumbers(i),'String',num2str(t));
  end
  
  % update selection
  if handles.guidata.selecting,
    handles.guidata.selected_ts(end) = t;
    UpdateSelection(handles);
  end
  
  guidata(handles.figure_JLabel,handles);

  % update plot
  if doupdateplot,
    UpdatePlots(handles,'axes',i);
  end
  
  % TODO: update timeline zoom
  for h = handles.guidata.axes_timeline_labels,
    zoom(h,'reset');
  end
  
%   % out of bounds for labeling? then turn off labeling
%   if (t < handles.data.t0_curr || t > handles.data.t1_curr),
%     if handles.guidata.label_state > 0,
%       set(handles.guidata.togglebutton_label_behaviors(handles.guidata.label_state),'Value',0);
%     elseif handles.guidata.label_state < 0,
%       set(handles.togglebutton_label_unknown,'Value',0);
%     end
%     handles.guidata.label_state = 0;
%     set([handles.guidata.togglebutton_label_behaviors,handles.togglebutton_label_unknown],'Enable','off');
%   else
%     set([handles.guidata.togglebutton_label_behaviors,handles.togglebutton_label_unknown],'Enable','on');
%   end
end  % if
return


% -------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function slider_preview_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to slider_preview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
return


% -------------------------------------------------------------------------
function pushtool_save_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to pushtool_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
saveAs=false;
saveEverythingFile(findAncestorFigure(hObject),saveAs);
return


% --------------------------------------------------------------------
function menu_file_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


%--------------------------------------------------------------------------
function menu_file_modify_experiment_list_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_modify_experiment_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% if isfield(handles,'data'),
% %   [success,msg] = handles.data.UpdateStatusTable();
% %   if ~success,
% %     error(msg);
% %   end
%   params = {handles.data};
% else
%   params = {handles.guidata.configfilename};
%   if isfield(handles,'defaultpath'),
%     params(end+1:end+2) = {'defaultpath',handles.guidata.defaultpath};
%   end
% end

% store the name of the current experiment, so that we can
% stay with it (if possible) after the user modifies the list of 
% experiment dirs
if ~isempty(handles.data.expi) && handles.data.expi > 0,
  handles.guidata.oldexpdir = handles.data.expdirs{handles.data.expi};
else
  handles.guidata.oldexpdir = '';
end

JModifyFiles('figureJLabel',handles.figure_JLabel);

return


%--------------------------------------------------------------------------
function handles = UpdateMovies(handles)
return


% %--------------------------------------------------------------------------
% function handles = SetNeedSave(handles)
% handles.data.needsave = true;
% UpdateEnablementAndVisibilityOfControls(handles);
% %set(handles.menu_file_export_classifier,'Enable','on');
% %set(handles.menu_file_export_labels,'Enable','on');
% return


% % --------------------------------------------------------------------
% function handles = SetSaved(handles)
% 
% handles.guidata.needsave = false;
% set(handles.menu_file_export_classifier,'Enable','off');
% set(handles.menu_file_export_labels,'Enable','off');


% % --------------------------------------------------------------------
% function success = menu_file_export_classifier_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_file_export_classifier (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% success=exportClassifierFile(findAncestorFigure(hObject));
% 
% return


% --------------------------------------------------------------------
function menu_file_quit_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_quit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figure_JLabel_CloseRequestFcn(hObject, eventdata, handles);
return


% --------------------------------------------------------------------
function menu_edit_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
function menu_view_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
function menu_go_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
function menu_edit_undo_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_undo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% % -------------------------------------------------------------------------
% function [handles,success] = LoadConfig(handles,forceui)
% 
% if ~exist('forceui','var'),
%   forceui = false;
% end
% 
% % initialize output to success = false
% success = false;
% 
% % get config file
% havefilename = false;
% % if ~forceui && ~isempty(handles.guidata.configfilename),
% %   havefilename = true;
% % end
% 
% % default config file name
% if isempty(handles.guidata.configfilename),
%   defaultconfigfilename = fullfile(handles.guidata.defaultpath,'JLabelConfig.xml');
% else
%   defaultpath = myfileparts(handles.guidata.configfilename);
%   if exist(defaultpath,'file'),
%     handles.guidata.defaultpath = defaultpath;
%   end
%   defaultconfigfilename = handles.guidata.configfilename;
% end
% 
% % loop until we have a valid config file
% while true,
% 
%   if ~havefilename,
%     
%     if ~exist(defaultconfigfilename,'file'),
%       defaultconfigfilename = handles.guidata.defaultpath;
%     end
%   
%     % get from user
%     [filename,pathname] = uigetfile('*.xml','Choose XML config file',defaultconfigfilename);
%     
%     % if cancel clicked, just return
%     if ~ischar(filename),
%       return;
%     end
%     
%     handles.guidata.configfilename = fullfile(pathname,filename);
% 
%     % store path as default
%     handles.guidata.defaultpath = pathname;
% 
%   end
%   
%   % make sure the file exists
%   if ~exist(handles.guidata.configfilename,'file'),
%     havefilename = false;
%     uiwait(warndlg(sprintf('File %s does not exist',handles.guidata.configfilename),'Error reading config file'));
%     continue;
%   end
%     
% %   try
%   [~,~,ext] = fileparts(handles.guidata.configfilename);
%   if strcmp(ext,'.xml')
%     JLabelHandle.guidata.configparams = ReadXMLConfigParams(handles.guidata.configfilename);
%   elseif strcmp(ext,'.mat')
%     JLabelHandle.guidata.configparams = load(handles.guidata.configfilename);
%   else
%     errordlg('Project file is not a valid');
%   end
% %   catch ME,
% %     uiwait(warndlg(sprintf('Error reading configuration from file %s: %s',handles.guidata.configfilename,getReport(ME)),'Error reading config file'));
% %     havefilename = false;
% %     continue;
% %   end
%   
%   % success -- break
%   break;
% 
% end
% 
% success = true;


% %--------------------------------------------------------------------------
% function handles = InitializeStateGivenBasicParams(handles,basicParams,groundTruthingMode)
% 
% % Tell JLabelGUIData to init itself
% handles.guidata.initializeGivenBasicParams(basicParams,handles.figure_JLabel,groundTruthingMode);
% 
% % create buttons for each label, as needed
% handles = UpdateLabelButtons(handles);
% 
% % Set this thing
% if ~isempty(handles.data.allperframefns)
%   set(handles.timeline_label_prop1,'String',handles.guidata.timeline_prop_options,'Value',3);
% end
% 
% % Setup the popup menu for bottom row of the automatic timeline.
% bottomRowTypes = get(handles.automaticTimelineBottomRowPopup,'String');
% set(handles.automaticTimelineBottomRowPopup,'Value', ...
%                   find(strcmp(bottomRowTypes,handles.guidata.bottomAutomatic)));
% set(handles.automaticTimelinePredictionLabel,'FontSize',10);
% set(handles.automaticTimelineScoresLabel,'FontSize',10);
% set(handles.automaticTimelineBottomRowPopup,'FontSize',10);
% 
% % set([handles.pushbutton_playselection, ...
% %      handles.pushbutton_clearselection],'Enable','off');  
% 
% %set(handles.togglebutton_select,'Value',0); 
% 
% SetJumpGoMenuLabels(handles)
% 
% handles.doplottracks = true;
% %set(handles.menu_view_plot_tracks,'Checked','on');  %via update
% 
% buttonNames = {'pushbutton_train','pushbutton_predict',...
%                'togglebutton_select','pushbutton_clearselection',...
%                'pushbutton_playselection','pushbutton_playstop',...
%                'similarFramesButton','bagButton'};
% for buttonNum = 1:numel(buttonNames)
%   adjustButtonColorsIfMac(handles.(buttonNames{buttonNum}));
% end
% 
% %set(handles.similarFramesButton,'Enable','off');  % via update
% 
% updateCheckMarksInMenus(handles);
% 
% return


%--------------------------------------------------------------------------
function updateCheckMarksInMenus(handles)

% basic vs advanced mode
if handles.guidata.GUIAdvancedMode,
  set(handles.menu_edit_basic_mode   ,'checked','off');
  set(handles.menu_edit_advanced_mode,'checked','on' );
else
  set(handles.menu_edit_basic_mode   ,'checked','on ');
  set(handles.menu_edit_advanced_mode,'checked','off');
end

% labeling vs GT mode
%if isempty(handles.data)
if ~handles.data.thereIsAnOpenFile
  set(handles.menu_edit_normal_mode      ,'checked','off');
  set(handles.menu_edit_ground_truthing_mode,'checked','off' );
else
  if handles.data.gtMode,
    set(handles.menu_edit_normal_mode    ,'checked','off');
    set(handles.menu_edit_ground_truthing_mode,'checked','on' );
  else
    set(handles.menu_edit_normal_mode    ,'checked','on ');
    set(handles.menu_edit_ground_truthing_mode,'checked','off');
  end
end

return


% -------------------------------------------------------------------------
function SetJumpGoMenuLabels(handles)

set(handles.menu_go_forward_several_frames,'Label',sprintf('Forward %d frames (down arrow)',handles.guidata.nframes_jump_go));
set(handles.menu_go_back_several_frames,'Label',sprintf('Back %d frames (up arrow)',handles.guidata.nframes_jump_go));
jumpType = handles.guidata.NJObj.GetCurrentType();
set(handles.menu_go_next_automatic_bout_start,'Label',...
  sprintf('Next %s bout start (shift + right arrow)',jumpType));
set(handles.menu_go_previous_automatic_bout_end,'Label',...
  sprintf('Next %s bout end (shift + left arrow)',jumpType));
return


%--------------------------------------------------------------------------
function handles = UpdateLabelButtons(handles)
% Makes sure the label buttons are appropriate for the current behavior and
% the the current mode.

% get some freqeuntly used things into local vars
%if isempty(handles.data)
if ~handles.data.thereIsAnOpenFile ,
  %projectPresent=false;
  nBehaviors=2;  % just for layout purposes
  labelColors=[1 0 0 ; ...
               0 0 1];
  behaviorNameCapitalized={'Abiding'; ...
                           'None'};           
else
  %projectPresent=true;
  nBehaviors=handles.data.nbehaviors;
  labelColors=handles.guidata.labelcolors;
  behaviorNameCapitalized=cell(nBehaviors,1);
  for i=1:nBehaviors
    behaviorNameCapitalized{i}=upperFirstLowerRest(handles.data.labelnames{i});
  end
end
isAdvancedMode=handles.guidata.GUIAdvancedMode;
isBasicMode=~isAdvancedMode;

% get positions of stuff
set(handles.panel_labelbuttons,'Units','pixels');
panel_pos = get(handles.panel_labelbuttons,'Position');
select_pos = get(handles.panel_select,'Position');
set(handles.togglebutton_label_behavior1,'Units','pixels');
button1_pos = get(handles.togglebutton_label_behavior1,'Position');
set(handles.togglebutton_label_unknown,'Units','pixels');
unknown_button_pos = get(handles.togglebutton_label_unknown,'Position');
out_border_y = unknown_button_pos(2);
out_border_x = unknown_button_pos(1);
in_border_y = handles.guidata.in_border_y;
button_width = button1_pos(3);
button_height = button1_pos(4);

% calculate menu_file_open_old_school_files height for the panel
if isBasicMode
  new_panel_height = 2*out_border_y + (nBehaviors+1)*button_height + ...
    nBehaviors*in_border_y;
else
  new_panel_height = 2*out_border_y + (2*nBehaviors+1)*button_height + ...
    2*nBehaviors*in_border_y;
end
% update panel position
panel_top = panel_pos(2)+panel_pos(4);
new_panel_pos = [panel_pos(1),panel_top-new_panel_height,panel_pos(3),new_panel_height];
set(handles.panel_labelbuttons,'Position',new_panel_pos);
dy_label_select = panel_pos(2) - select_pos(2) - select_pos(4);
new_select_pos = [select_pos(1),new_panel_pos(2)-select_pos(4)-dy_label_select,select_pos(3:4)];
set(handles.panel_select,'Position',new_select_pos);

% move unknown button to the bottom
new_unknown_button_pos = [unknown_button_pos(1),out_border_y,unknown_button_pos(3),button_height];
set(handles.togglebutton_label_unknown,'Position',new_unknown_button_pos);

% update the array of button handles
handles.guidata.togglebutton_label_behaviors = nan(1,2*nBehaviors);
  % order is: behavior1
  %           behavior1 maybe ("normbehavior")
  %           behavior2
  %           behavior2 maybe ("normbehavior")
  %           et cetera
for i=1:nBehaviors
  % the behavior proper
  thisButton=findobj(handles.figure_JLabel,'tag',sprintf('togglebutton_label_behavior%d',i));
  handles.guidata.togglebutton_label_behaviors(2*i-1)= ...
    fif(isempty(thisButton),nan,thisButton);
  % maybe the behavior
  thisButton=findobj(handles.figure_JLabel,'tag',sprintf('togglebutton_label_normbehavior%d',i));
  handles.guidata.togglebutton_label_behaviors(2*i  )= ...
    fif(isempty(thisButton),nan,thisButton);
end
  
% Update the buttons, creating them de novo if needed
callback=get(handles.togglebutton_label_behavior1,'Callback');
for i = 1:nBehaviors,
  %
  % Set up the "definitely the behavior" button.
  %
  % Create the button if needed.
  if isnan(handles.guidata.togglebutton_label_behaviors(2*i-1))
    handles.guidata.togglebutton_label_behaviors(2*i-1) = ...
      uicontrol('Style','togglebutton', ...
                'Units','pixels', ...
                'FontUnits','pixels', ...
                'FontSize',14,...
                'FontWeight','bold', ...
                'Callback',callback,...
                'Parent',handles.panel_labelbuttons,...
                'Tag',sprintf('togglebutton_label_behavior%d',i));
    %SetButtonImage(handles.guidata.togglebutton_label_behaviors(2*i-1));
  end
  % Set the button properties (always)
  if isAdvancedMode
    pos = [out_border_x,new_panel_height-out_border_y-button_height*(2*i-1)-in_border_y*(2*i-2),...
           button_width,button_height];
    buttonLabel=sprintf('Important %s',behaviorNameCapitalized{i});
  else
    % basic mode, or no project present
    pos = [out_border_x,new_panel_height-out_border_y-button_height*i-in_border_y*(i-1),...
           button_width,button_height];
    buttonLabel=behaviorNameCapitalized{i};
  end
  set(handles.guidata.togglebutton_label_behaviors(2*i-1), ...
      'Position',pos, ...
      'String',buttonLabel, ...
      'UserData',2*i-1);
    % Need userdata in above b/c not set in guide for guide-made buttons
  setLabelButtonColor(handles.guidata.togglebutton_label_behaviors(2*i-1), ...
                      labelColors(i,:));
  
  %  
  % Set up the "maybe the behavior" buttons
  %
  if isAdvancedMode
    % Create the button if needed.
    if isnan(handles.guidata.togglebutton_label_behaviors(2*i))
      handles.guidata.togglebutton_label_behaviors(2*i) = ...
        uicontrol('Style','togglebutton', ...
                  'Units','pixels', ...
                  'FontUnits','pixels', ...
                  'FontSize',14,...
                  'FontWeight','bold', ...
                  'Callback',callback,...
                  'Parent',handles.panel_labelbuttons,...
                  'Tag',sprintf('togglebutton_label_normbehavior%d',i));
      %SetButtonImage(handles.guidata.togglebutton_label_behaviors(2*i));
    end
    % Set the button properties
    pos = [out_border_x,new_panel_height-out_border_y-button_height*(2*i)-in_border_y*(2*i-1),...
           button_width,button_height];
    buttonLabel=behaviorNameCapitalized{i};
    set(handles.guidata.togglebutton_label_behaviors(2*i), ...
        'Position',pos, ...
        'String',buttonLabel, ...
        'UserData',2*i);
    setLabelButtonColor(handles.guidata.togglebutton_label_behaviors(2*i), ...
                        ShiftColor.decreaseIntensity(labelColors(i,:)));
  else
    % basic mode, or no-data-yet
    % delete the maybe-the-behavior button if it exists
    thisButton=handles.guidata.togglebutton_label_behaviors(2*i);
    if ~isnan(thisButton)
      delete(thisButton)
      handles.guidata.togglebutton_label_behaviors(2*i)=nan;
    end
  end
end

% set props for unknown button (always present)
set(handles.togglebutton_label_unknown,...
    'String','Unknown',...
    'Units','pixels', ...
    'FontUnits','pixels', ...
    'FontSize',14,...
    'FontWeight','bold', ...
    'UserData',-1);
%SetButtonImage(handles.togglebutton_label_unknown);
setLabelButtonColor(handles.togglebutton_label_unknown, ...
                    handles.guidata.labelunknowncolor);

% Since we made and deleted buttons, need to make sure the arrays of
% buttons are up-to-date
handles.guidata.UpdateGraphicsHandleArrays(handles.figure_JLabel);

return


% %--------------------------------------------------------------------------
% function UpdateEnablementOfGUI(handles)
% % Updates the enablement of controls according to the number of experiments
% % and the current experiment, and handles.guidata.needsave.  Also, disables
% % File > Save Project...
% 
% UpdateGUIToMatchMovieState(handles);
% 
% % Disable the save menu item if things have recently been saved,
% % Enable it if there are unsaved changes
% UpdateGUIToMatchFileAndExperimentState(handles);
% 
% return


% %--------------------------------------------------------------------------
% function UpdateGUIToMatchOpenFileState(handles)
% 
% % Disable the save menu item if things have recently been saved,
% % Enable it if there are unsaved changes
% thereIsAnOpenFile=handles.guidata.thereIsAnOpenFile;
% needsave=handles.guidata.needsave;
% set(handles.menu_file_new,'Enable',offIff(thereIsAnOpenFile));  
% set(handles.menu_file_open,'Enable',offIff(thereIsAnOpenFile));  
% set(handles.menu_file_open_in_ground_truthing_mode, ...
%     'Enable',offIff(thereIsAnOpenFile));  
% set(handles.menu_file_save,'Enable',onIff(thereIsAnOpenFile&&needsave));
% set(handles.menu_file_save_as,'Enable',onIff(thereIsAnOpenFile));
% set(handles.menu_file_close,'Enable',onIff(thereIsAnOpenFile));
% set(handles.menu_file_import_old_style_project, ...
%     'Enable',offIff(thereIsAnOpenFile));
% 
% return


% %--------------------------------------------------------------------------
% function UpdateGUIToMatchMovieState(handles)
% % Updates the visbility of controls depending on whether there is a valid
% % current experiment.  (I.e., a movie showing)
% 
% % these controls require a movie to currently be open, and should be
% % disabled if there's no movie
% grobjectsEnabledIffMovie = ...
%   [handles.contextmenu_timeline_manual_timeline_options,...
%    handles.guidata.togglebutton_label_behaviors,...
%    handles.togglebutton_label_unknown,...
%    handles.togglebutton_select,...
%    handles.pushbutton_clearselection, ...
%    handles.pushbutton_playselection, ...
%    handles.bagButton, ...
%    handles.similarFramesButton, ...
%    handles.guidata.menu_view_zoom_options(:)'];
% grobjectsEnabledIffMovie = ...
%   grobjectsEnabledIffMovie(~isnan(grobjectsEnabledIffMovie));
% 
% % these require a movie to currently be open and should be _invisible_
% % if there's no movie
% grobjectsVisibileIffMovie = [handles.guidata.panel_previews,...
%                              handles.panel_timelines,...
%                              handles.panel_learn ...
%                              handles.panel_labelbuttons ...
%                              handles.panel_select ...
%                              handles.panel_selection_info];
% 
% % set enablement/visibility according to the current movie index    
% isMovieShowing=handles.data.expi >= 1 && ...
%                handles.data.expi <= handles.data.nexps;
% set(grobjectsEnabledIffMovie,'Enable',onIff(isMovieShowing));
% set(grobjectsVisibileIffMovie,'Visible',onIff(isMovieShowing));
% % % for debugging:
% % set(grobjectsEnabledIffMovie,'Enable','on');
% % set(grobjectsVisibileIffMovie,'Visible','on');
% set(handles.menu_file_import_old_style_classifier, ...
%     'Enable',offIff(isMovieShowing));
% 
% return


%--------------------------------------------------------------------------
function UpdateEnablementAndVisibilityOfControls(handles)
% Set enablement and visibility of various controls depending on
% whether a file is currently open, and whether that file contains more
% than zero experiments.

% Calculate some logical values that determine enablement and visibility of
% things.
data=handles.data;  % a ref, or empty
thereIsAnOpenFile=data.thereIsAnOpenFile;
openFileHasUnsavedChanges=thereIsAnOpenFile&&handles.data.needsave;
% if thereIsAnOpenFile
%   if isempty(data)
%     nExps=0;
%   else
%     nExps=handles.data.nexps;
%   end
% else
%   nExps=0;
% end
nExps=data.nexps;
someExperimentIsCurrent=handles.data.getSomeExperimentIsCurrent();
inGroundTruthingMode=thereIsAnOpenFile && ...
                     ~isempty(data) && ...
                     data.gtMode;
%inNormalMode=~inGroundTruthingMode;
classifierExists=~isempty(data) && ...
                 ~isempty(data.classifier);
% atLeastOneNormalLabelExists= ...
%   ~isempty(data) && ...
%   data.getAtLeastOneNormalLabelExists();
atLeastOneNormalLabelOfEachClassExists= ...
  ~isempty(data) && ...
  data.getAtLeastOneNormalLabelOfEachClassExists;
labelPenIsUp=(handles.guidata.label_state==0);
userHasSpecifiedEverythingFileName=handles.data.userHasSpecifiedEverythingFileName;
savewindowdata = handles.data.savewindowdata;
%                      
% Update the File menu items.
%
set(handles.menu_file,'enable',onIff(labelPenIsUp));
set(handles.menu_file_new,'Enable',offIff(thereIsAnOpenFile));  
set(handles.menu_file_open,'Enable',offIff(thereIsAnOpenFile));  
set(handles.menu_file_open_in_ground_truthing_mode, ...
    'Enable',offIff(thereIsAnOpenFile));  
set(handles.menu_file_save,'Enable',onIff(openFileHasUnsavedChanges));
set(handles.pushtool_save,'Enable',onIff(openFileHasUnsavedChanges));
set(handles.menu_file_save_as,'Enable',onIff(thereIsAnOpenFile));
set(handles.menu_file_savewindowdata,'Enable',onIff(thereIsAnOpenFile&&~inGroundTruthingMode));
set(handles.menu_file_close,'Enable',onIff(thereIsAnOpenFile));
% set(handles.menu_file_import_old_style_project, ...
%     'Enable',offIff(thereIsAnOpenFile));
% set(handles.menu_file_import_old_style_classifier, ...
%     'Enable',onIff(thereIsAnOpenFile&&(nExps==0)));
%set(handles.menu_file_basic_settings,'Enable',onIff(thereIsAnOpenFile));
%set(handles.menu_file_change_target_type,'Enable',onIff(thereIsAnOpenFile));
set(handles.menu_file_change_behavior_name,'Enable',onIff(thereIsAnOpenFile));
set(handles.menu_file_change_score_file_name,'Enable',onIff(thereIsAnOpenFile));
set(handles.menu_file_modify_experiment_list,'Enable',onIff(thereIsAnOpenFile));
set(handles.menu_file_remove_experiments_with_no_labels,'Enable',onIff( thereIsAnOpenFile&&(nExps>0) ));
set(handles.menu_file_import_classifier, ...
    'Enable',onIff(thereIsAnOpenFile));
% Import Scores... and it's submenu items
set(handles.menu_file_import_scores, ...
    'Enable',onIff(someExperimentIsCurrent));
set(handles.menu_file_import_scores_curr_exp_default_loc, ...
    'Enable',onIff(someExperimentIsCurrent));
set(handles.menu_file_import_scores_curr_exp_diff_loc, ...
    'Enable',onIff(someExperimentIsCurrent));
set(handles.menu_file_import_scores_all_exp_default_loc, ...
    'Enable',onIff(someExperimentIsCurrent));
% Export things    
%set(handles.menu_file_export_classifier, ...
%    'Enable',onIff(someExperimentIsCurrent));  % Should we enable iff a classifier or labels exist?
%set(handles.menu_file_export_labels, ...
%    'Enable',onIff(someExperimentIsCurrent));  % Should we enable iff labels exist?
% Export scores... and it's submenu items    
% These may need refining
set(handles.menu_file_export_scores, ...
    'Enable',onIff(someExperimentIsCurrent));
% The rest of the File menu items
% These may need refining
set(handles.menu_file_export_ground_truthing_suggestions, ...
    'Enable',onIff(someExperimentIsCurrent), ...
    'Visible',onIff(inGroundTruthingMode));
% set(handles.menu_file_export_labels, ...
%     'Enable',onIff(someExperimentIsCurrent));

%  
% Update the Edit menu items
%
set(handles.menu_edit,'enable',onIff(labelPenIsUp));
set(handles.menu_edit_label_shortcuts,'Enable',onIff(thereIsAnOpenFile));  

%
% Update the View menu items
%
set(handles.menu_view_show_whole_frame, ...
    'Enable',onIff(someExperimentIsCurrent));  
set(handles.menu_view_show_bookmarked_clips, ...
    'Enable',onIff(thereIsAnOpenFile));  
set(handles.menu_view_show_predictions, ...
    'Enable',onIff(someExperimentIsCurrent));  
set(handles.menu_view_suggest_gt_intervals, ...
    'Visible',onIff(inGroundTruthingMode));  

%
% Update the Go menu items
%
set(handles.menu_go,'enable',onIff(labelPenIsUp));
set(handles.menu_go_switch_target, ...
    'Enable',onIff(someExperimentIsCurrent));  
set(handles.menu_go_next_frame, ...
    'Enable',onIff(someExperimentIsCurrent));  
set(handles.menu_go_previous_frame, ...
    'Enable',onIff(someExperimentIsCurrent));  
set(handles.menu_go_forward_several_frames, ...
    'Enable',onIff(someExperimentIsCurrent));  
set(handles.menu_go_back_several_frames, ...
    'Enable',onIff(someExperimentIsCurrent));  
set(handles.menu_go_next_manual_bout_start, ...
    'Enable',onIff(someExperimentIsCurrent));  
set(handles.menu_go_previous_manual_bout_end, ...
    'Enable',onIff(someExperimentIsCurrent));  
set(handles.menu_go_next_automatic_bout_start, ...
    'Enable',onIff(someExperimentIsCurrent));  
set(handles.menu_go_previous_automatic_bout_end, ...
    'Enable',onIff(someExperimentIsCurrent));  

%
% Update the Classifier menu items
%
set(handles.menu_classifier,'enable',onIff(labelPenIsUp));
set(handles.menu_classifier_change_score_features, ...
    'Enable',onIff(thereIsAnOpenFile&&~inGroundTruthingMode));
set(handles.menu_classifier_select_features, ...
    'Enable',onIff(thereIsAnOpenFile&&~inGroundTruthingMode));  
set(handles.menu_classifier_training_parameters, ...
    'Enable',onIff(thereIsAnOpenFile&&~inGroundTruthingMode));  
set(handles.menu_classifier_classify, ...
    'Enable',onIff(classifierExists&&someExperimentIsCurrent));
set(handles.menu_classifier_classifyCurrentMovieSave, ...
    'Enable',onIff(classifierExists&&someExperimentIsCurrent&&userHasSpecifiedEverythingFileName));
set(handles.menu_classifier_classifyCurrentMovieSaveNew, ...
    'Enable',onIff(classifierExists&&someExperimentIsCurrent&&userHasSpecifiedEverythingFileName));
set(handles.menu_classifier_classifyall_default, ...
    'Enable',onIff(classifierExists&&someExperimentIsCurrent&&userHasSpecifiedEverythingFileName));
set(handles.menu_classifier_classifyall_new, ...
    'Enable',onIff(classifierExists&&someExperimentIsCurrent&&userHasSpecifiedEverythingFileName));
set(handles.menu_classifier_set_confidence_thresholds, ...
    'Enable',onIff(classifierExists&&someExperimentIsCurrent&&~inGroundTruthingMode));  
set(handles.menu_classifier_cross_validate, ...
    'Enable',onIff(classifierExists&&someExperimentIsCurrent&&~inGroundTruthingMode));  
set(handles.menu_classifier_evaluate_on_new_labels, ...
    'Enable',onIff(classifierExists&&someExperimentIsCurrent&&~inGroundTruthingMode));  
set(handles.menu_classifier_visualize, ...
    'Enable',onIff(classifierExists&&~inGroundTruthingMode));  
set(handles.menu_classifier_compute_gt_performance, ...
    'Enable',onIff(classifierExists&&someExperimentIsCurrent&&inGroundTruthingMode));  
set(handles.menu_classifier_post_processing, ...
    'Enable',onIff(classifierExists&&someExperimentIsCurrent&&~inGroundTruthingMode));  
set(handles.menu_classifier_compareFrames, ...
    'Enable',onIff(classifierExists&&someExperimentIsCurrent&&~inGroundTruthingMode));  
set(handles.menu_classifier_clear, ...
    'Enable',onIff(classifierExists));  

% These controls require a movie to currently be open, and should be
% disabled if there's no movie.
grobjectsEnabledIffMovie = ...
  [handles.contextmenu_timeline_manual_timeline_options,...
   handles.guidata.togglebutton_label_behaviors,...
   handles.togglebutton_label_unknown,...
   handles.togglebutton_select,...
   handles.pushbutton_clearselection, ...
   handles.pushbutton_playselection, ...
   handles.bagButton, ...
   handles.similarFramesButton, ...
   handles.guidata.menu_view_zoom_options(:)'];
grobjectsEnabledIffMovie = ...
  grobjectsEnabledIffMovie(~isnan(grobjectsEnabledIffMovie));
set(grobjectsEnabledIffMovie,'Enable',onIff(someExperimentIsCurrent));

if ispc && someExperimentIsCurrent,

  % refresh button text colors
  h = [handles.guidata.togglebutton_label_behaviors,handles.togglebutton_label_unknown];
  h = h(ishandle(h));
  set(h,'ForegroundColor','k');
  set(h,'ForegroundColor','w');
  
end

% These require a movie to currently be open and should be _invisible_
% if there's no movie.
grobjectsVisibileIffMovie = [handles.guidata.panel_previews,...
                             handles.panel_timelines,...
                             handles.panel_learn ...
                             handles.panel_labelbuttons ...
                             handles.panel_select ...
                             handles.panel_selection_info];
set(grobjectsVisibileIffMovie,'Visible',onIff(someExperimentIsCurrent));

% The Train button is enabled iff there are (normal) labels and the 
% per-frame feature set is non-empty.
set(handles.pushbutton_train, ...
    'enable',onIff(labelPenIsUp && ...
                   atLeastOneNormalLabelOfEachClassExists));

% The Predict button is enabled iff a classifier exists.
set(handles.pushbutton_predict, ...
    'enable',onIff(classifierExists&&someExperimentIsCurrent));

if savewindowdata,
  set(handles.menu_file_savewindowdata,'checked','on' );
else
  set(handles.menu_file_savewindowdata,'checked','off' );
  
end
  
return


%--------------------------------------------------------------------------
function handles = LoadRC(handles)
% Load the user preferences from the .JLabelrc.mat file.

% rc file name
if isdeployed,
  handles.guidata.rcfilename = deployedRelative2Global('.JLabelrc.mat');
else
  handles.guidata.rcfilename = fullfile(myfileparts(mfilename('fullpath')),'.JLabelrc.mat');
end
handles.guidata.rc = struct;
if exist(handles.guidata.rcfilename,'file'),
  try
    handles.guidata.rc = load(handles.guidata.rcfilename);
  catch ME,
    warning('Error loading rc file %s: %s',handles.guidata.rcfilename,getReport(ME));
  end
end
try
  if isfield(handles.guidata.rc,'defaultpath'),
%     handles.guidata.defaultpath = handles.guidata.rc.defaultpath;
% %     if ~isempty(handles.data),
%     if handles.data.thereIsAnOpenFile ,
%       handles.data.SetDefaultPath(handles.guidata.defaultpath);
%     end
    handles.data.SetDefaultPath(handles.guidata.rc.defaultpath);
  end
  if isfield(handles.guidata.rc,'figure_JLabel_Position_px'),
    pos = handles.guidata.rc.figure_JLabel_Position_px;
    set(handles.figure_JLabel,'Units','pixels');
    % TODO: remove this once resizing is implemented
    pos0 = get(handles.figure_JLabel,'Position');
    pos(3:4) = pos0(3:4);
    set(handles.figure_JLabel,'Position',pos);
  end
  if isfield(handles.guidata.rc,'timeline_nframes'),
    handles.guidata.timeline_nframes = handles.guidata.rc.timeline_nframes;
  else
    handles.guidata.timeline_nframes = 250;
  end
  if isfield(handles.guidata.rc,'nframes_jump_go')
    handles.guidata.nframes_jump_go = handles.guidata.rc.nframes_jump_go;
  else
    handles.guidata.nframes_jump_go = 30;
  end
  
  if isfield(handles.guidata.rc,'label_shortcuts'),
    handles.guidata.label_shortcuts = handles.guidata.rc.label_shortcuts;
  else
    handles.guidata.label_shortcuts = [];
  end

  %output avi options
  
  % compression: scheme for compression for output avis
  if isfield(handles.guidata.rc,'outavi_compression'),
    handles.guidata.outavi_compression = handles.guidata.rc.outavi_compression;
  else
    handles.guidata.outavi_compression = 'None';
  end
  % outavi_fps: output frames per second
  if isfield(handles.guidata.rc,'outavi_fps'),
    handles.guidata.outavi_fps = handles.guidata.rc.outavi_fps;
  else
    handles.guidata.outavi_fps = 15;
  end
  % outavi_quality: output quality
  if isfield(handles.guidata.rc,'outavi_quality'),
    handles.guidata.outavi_quality = handles.guidata.rc.outavi_quality;
  else
    handles.guidata.outavi_quality = 95;
  end
  % useVideoWriter: whether to use videowriter class
  if isfield(handles.guidata.rc,'useVideoWriter'),
    handles.guidata.useVideoWriter = handles.guidata.rc.useVideoWriter > 0;
  else
    handles.guidata.useVideoWriter = exist('VideoWriter','file') > 0;
  end
  
  % preview options
  
  % playback speed
  if isfield(handles.guidata.rc,'play_FPS'),
    handles.guidata.play_FPS = handles.guidata.rc.play_FPS;
  else
    handles.guidata.play_FPS = 2;
  end
  
  if isfield(handles.guidata.rc,'framecache_threads'),
    handles.guidata.framecache_threads = handles.guidata.rc.framecache_threads;
  else
    handles.guidata.framecache_threads = 1;
  end
  
  if isfield(handles.guidata.rc,'traj_nprev'),
    handles.guidata.traj_nprev = handles.guidata.rc.traj_nprev;
  else
    handles.guidata.traj_nprev = 25;
  end
  
  if isfield(handles.guidata.rc,'traj_npost'),
    handles.guidata.traj_npost = handles.guidata.rc.traj_npost;
  else
    handles.guidata.traj_npost = 25;
  end
  
  if isfield(handles.guidata.rc,'bottomAutomatic')
    handles.guidata.bottomAutomatic = handles.guidata.rc.bottomAutomatic;
  else
    handles.guidata.bottomAutomatic = 'None';
  end
  
  % cache size
  if isfield(handles.guidata.rc,'cacheSize'),
    % handles.guidata.cacheSize = handles.guidata.rc.cacheSize;
    handles.data.cacheSize = handles.guidata.rc.cacheSize;
  else
    % handles.guidata.cacheSize = 4000;
    handles.data.cacheSize = 4000;
  end
  
  if isfield(handles.guidata.rc,'expdefaultpath'),
    handles.data.SetExpDefaultPath(handles.guidata.rc.expdefaultpath);
  end

  if isfield(handles.guidata.rc,'moviefilename')
    handles.guidata.defaultmoviefilename = handles.guidata.rc.moviefilename;
  end
  
  if isfield(handles.guidata.rc,'trxfilename')
    handles.guidata.defaulttrxfilename = handles.guidata.rc.trxfilename;
  end
  
%   % load the default configfilename, if present
%   if isfield(handles.guidata.rc,'previousConfigFileName'),
%     handles.guidata.previousConfigFileName = ...
%       handles.guidata.rc.previousConfigFileName;
%   end
  
  
catch ME,
  warning('Error loading RC file: %s',getReport(ME));  
end
return


% -------------------------------------------------------------------------
function handles = SaveRC(handles)

% try
  if isempty(handles.guidata.rcfilename),
    handles.guidata.rcfilename = fullfile(myfileparts(which('JLabel')),'.JLabelrc.mat');
  end
  
  rc = handles.guidata.rc;
  
  % if ~isempty(handles.data),
  if ~isempty(handles.data.defaultpath),
    rc.defaultpath = handles.data.defaultpath;
  end
  
  if ~isempty(handles.data.expdefaultpath),
    rc.expdefaultpath = handles.data.expdefaultpath;
  end
  
  rc.timeline_nframes = handles.guidata.timeline_nframes;
  
  set(handles.figure_JLabel,'Units','pixels');
  rc.figure_JLabel_Position_px = get(handles.figure_JLabel,'Position');
  
  rc.nframes_jump_go = handles.guidata.nframes_jump_go;
  
  % label shortcuts
  if ~isempty(handles.guidata.label_shortcuts),
    rc.label_shortcuts = handles.guidata.label_shortcuts;
  end
  
  
  %output avi options
  
  % compression: scheme for compression for output avis
  rc.outavi_compression = handles.guidata.outavi_compression;
  % outavi_fps: output frames per second
  rc.outavi_fps = handles.guidata.outavi_fps;
  % outavi_quality: output frames per second
  rc.outavi_quality = handles.guidata.outavi_quality;
  % useVideoWriter: whether to use videowriter class
  rc.useVideoWriter = handles.guidata.useVideoWriter;
  
  % preview options
  
  % playback speed
  rc.play_FPS = handles.guidata.play_FPS;
  
  rc.framecache_threads = handles.guidata.framecache_threads;
  rc.computation_threads = handles.guidata.computation_threads;
  rc.traj_nprev = handles.guidata.traj_nprev;
  rc.traj_npost = handles.guidata.traj_npost;
  
  % navigation preferences
  if isempty(handles.guidata.NJObj)
    rc.navPreferences = [];
  else
    rc.navPreferences = handles.guidata.NJObj.GetState();
  end
  rc.bottomAutomatic = handles.guidata.bottomAutomatic;
  
  % cache size
  % rc.cacheSize = handles.guidata.cacheSize;
  rc.cacheSize = handles.data.cacheSize;
  
  if ischar(handles.data.moviefilename),
    rc.moviefilename = handles.data.moviefilename;
  end
  
  if ischar(handles.data.trxfilename),
    rc.trxfilename = handles.data.trxfilename;
  end
  
  
  % % save the configfilename, if present
  % if ~isempty(handles.guidata.configfilename),
  %   rc.previousConfigFileName = handles.guidata.configfilename;
  % end
  
  save(handles.guidata.rcfilename,'-struct','rc');

% catch ME,
%   warning('Error saving RC file: %s',getReport(ME));
% end
return


% -------------------------------------------------------------------------
function proceed=checkForUnsavedChangesAndDealIfNeeded(figureJLabel)
% Check for unsaved changes, and if there are unsaved changes, ask the user
% if she wants to do a save.  Returns true if everything is copacetic and
% the caller should proceed with whatever they were going to do.  Returns
% false if the user wanted to save but there was an error, or if the user
% hit cancel, and therefore the caller should _not_ proceed with whatever
% they were going to do.
handles=guidata(figureJLabel);
if handles.data.needsave,
  res = questdlg('There are unsaved changes.  Save?','Save?','Save','Discard','Cancel','Save');
  if strcmpi(res,'Save'),
    saved=saveEverythingFile(figureJLabel);
    if saved,
      proceed=true;
    else
      proceed=false;
    end
  elseif strcmpi(res,'Discard'),
    proceed=true;    
  elseif strcmpi(res,'Cancel'),
    proceed=false;
  else
    error('JLabel.internalError','Internal error.  Please report to the JAABA developers.');  %#ok
  end
else
  proceed=true;
end
return


% -------------------------------------------------------------------------
% --- Executes when user attempts to close figure_JLabel.
function figure_JLabel_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
%delete(hObject);

for i=1:length(handles.guidata.cache_thread)
  delete(handles.guidata.cache_thread{i});
end
handles.guidata.cache_thread = [];
UpdatePlots(handles,'CLEAR');
%clear functions  % BJA: need to clear persistent vars in UpdatePlots
if ispc, pause(.1); end
if isfield(handles.guidata,'cache_filename') & exist(handles.guidata.cache_filename,'file'),
  delete(handles.guidata.cache_filename);
end

% Check if we need to save.
proceed=checkForUnsavedChangesAndDealIfNeeded(hObject);
if ~proceed,
  return;
end
handles=guidata(hObject);

% if ~isempty(handles.data) && handles.data.NeedSaveProject(),
%   res = questdlg(['Current window features do not match the ones in the project file.'...
%       'Update the project file with the current window features?'],...
%       'Update?','Yes','No','Cancel','Yes');
%   if strcmpi(res,'Yes')
%     menu_file_save_project_Callback(hObject,eventdata,handles);
%   elseif strcmpi(res,'Cancel');
%     return;
%   end
% end  

if ~isempty(handles.guidata.movie_fid) && ...
    handles.guidata.movie_fid > 1 && ~isempty(fopen(handles.guidata.movie_fid)),
  fclose(handles.guidata.movie_fid);
  handles.guidata.movie_fid = [];
end
% try
  % turn off zooming
  zoom(handles.figure_JLabel,'off');
% catch %#ok<CTCH>
% end
% SWITCH THIS
for ndx = 1:numel(handles.guidata.open_peripherals)
  if ishandle(handles.guidata.open_peripherals(ndx)),
    delete(handles.guidata.open_peripherals(ndx));
  end
end

if true,
  SaveRC(handles);
  delete(handles.figure_JLabel);
  handles.guidata=[];
  handles.data=[];  % this should call the delete() method of the JLabelData
else
  uiresume(handles.figure_JLabel); %#ok<UNRCH>
end
return


% --------------------------------------------------------------------
function toggletool_zoomin_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_zoomin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
function toggletool_zoomin_OnCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_zoomin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmpi(get(handles.toggletool_zoomout,'State'),'on'),
  set(handles.toggletool_zoomout,'State','off');
end
if strcmpi(get(handles.toggletool_pan,'State'),'on'),
  set(handles.toggletool_pan,'State','off');
end
if strcmpi(get(handles.guidata.hpan,'Enable'),'on'),
  pan(handles.figure_JLabel,'off');
end
set(handles.guidata.hzoom,'Direction','in','Enable','on');

return


% --------------------------------------------------------------------
function toggletool_zoomin_OffCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_zoomin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.guidata.hzoom,'Enable','off');
for i = 1:numel(handles.guidata.axes_previews),
  [handles] = UpdateZoomFlyRadius(handles,i);
end

return


% --------------------------------------------------------------------
function toggletool_zoomout_OffCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_zoomout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.guidata.hzoom,'Enable','off');
for i = 1:numel(handles.guidata.axes_previews),
  [handles] = UpdateZoomFlyRadius(handles,i);
end

return


% --------------------------------------------------------------------
function toggletool_zoomout_OnCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_zoomout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmpi(get(handles.toggletool_zoomin,'State'),'on'),
  set(handles.toggletool_zoomin,'State','off');
end
if strcmpi(get(handles.toggletool_pan,'State'),'on'),
  set(handles.toggletool_pan,'State','off');
end
if strcmpi(get(handles.guidata.hpan,'Enable'),'on'),
  pan(handles.figure_JLabel,'off');
end
set(handles.guidata.hzoom,'Direction','out','Enable','on');
return


% --------------------------------------------------------------------
function toggletool_zoomout_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_zoomout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
function toggletool_pan_OnCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_pan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set([handles.toggletool_zoomin,handles.toggletool_zoomout],'State','off');
zoom(handles.figure_JLabel,'off');
pan(handles.figure_JLabel,'on');
return


% -------------------------------------------------------------------------
function toggletool_pan_OffCallback(hObject, eventdata, handles)
% hObject    handle to toggletool_pan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pan(handles.figure_JLabel,'off');
for i = 1:numel(handles.guidata.axes_previews),
  [handles] = UpdateZoomFlyRadius(handles,i);
end

return


% -------------------------------------------------------------------------
% --- Executes on button press in togglebutton_label_behavior1.
function togglebutton_label_behavior1_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_label_behavior1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_label_behavior1
buttonNum = get(hObject,'UserData');
behaviori = ceil(buttonNum/2);
isImportant = mod(buttonNum,2);

if get(hObject,'Value'),
  % toggle on, label pen is down.
  
  handles.guidata.label_state = behaviori;
  handles.guidata.label_imp = isImportant;
  handles.label_t0 = handles.guidata.ts(1);
  
  % set everything else to off
  for j = 1:2*handles.data.nbehaviors,
    if j == buttonNum || isnan(handles.guidata.togglebutton_label_behaviors(j)),
      continue;
    end
    set(handles.guidata.togglebutton_label_behaviors(j),'Value',0,'Enable','off');
  end
  set(handles.togglebutton_label_unknown,'Value',0,'Enable','off');

  curColor = handles.guidata.labelcolors(behaviori,:);
  if ~isImportant, curColor = ShiftColor.decreaseIntensity(curColor); end
  set(handles.guidata.htimeline_label_curr,'XData',handles.label_t0 + [-.5,-.5,.5,.5,-.5],...
    'FaceColor',curColor);
  % set the current frame to be labeled
  %handles.lastframe_labeled = [];
  %handles = SetLabelPlot(handles,min(handles.data.t1_curr,max(handles.data.t0_curr,handles.guidata.ts(1))),behaviori);
  
  UpdatePlots(handles,...
              'refreshim',false, ...
              'refreshflies',true, ...
              'refreshtrx',false, ...
              'refreshlabels',true,...
              'refresh_timeline_manual',true,...
              'refresh_timeline_auto',false,...
              'refresh_timeline_suggest',false,...
              'refresh_timeline_error',true,...
              'refresh_timeline_xlim',false,...
              'refresh_timeline_hcurr',false,...
              'refresh_timeline_props',false,...
              'refresh_timeline_selection',false,...
              'refresh_curr_prop',false);

   UpdateEnablementAndVisibilityOfControls(handles);
   % set(handles.menu_file,'enable','off');
   % set(handles.menu_edit,'enable','off');
   % set(handles.menu_go,'enable','off');
   % set(handles.menu_classifier,'enable','off');
   % set(handles.pushbutton_train,'Enable','off');
   
else % label pen is up.
  
  
  if handles.guidata.ts(1) <= handles.label_t0,
    t0 = handles.guidata.ts(1);
    t1 = handles.label_t0;
  else
    t0 = handles.label_t0;
    t1 = handles.guidata.ts(1);
  end
  t0 = min(handles.data.t1_curr,max(handles.data.t0_curr,t0));
  t1 = min(handles.data.t1_curr,max(handles.data.t0_curr,t1));
  handles = SetLabelPlot(handles,t0,t1,handles.guidata.label_state,handles.guidata.label_imp);

  handles.guidata.label_state = 0;
  handles.guidata.label_imp = [];
  handles.label_t0 = [];
  set(handles.guidata.htimeline_label_curr,'XData',nan(1,5));
  UpdatePlots(handles,...
              'refreshim',false, ...
              'refreshflies',true, ...
              'refreshtrx',false, ...
              'refreshlabels',true,...
              'refresh_timeline_manual',true,...
              'refresh_timeline_auto',false,...
              'refresh_timeline_suggest',false,...
              'refresh_timeline_error',true,...
              'refresh_timeline_xlim',false,...
              'refresh_timeline_hcurr',false,...
              'refresh_timeline_props',false,...
              'refresh_timeline_selection',false,...
              'refresh_curr_prop',false);
  
%   handles.data.StoreLabels();
  for j = 1:2*handles.data.nbehaviors,
    if isnan(handles.guidata.togglebutton_label_behaviors(j)), continue; end
    set(handles.guidata.togglebutton_label_behaviors(j),'Value',0,'Enable','on');
  end
  set(handles.togglebutton_label_unknown,'Value',0,'Enable','on');
  %set(handles.guidata.togglebutton_label_behaviors(behaviori),'String',sprintf('Label %s',handles.data.labelnames{behaviori}));

  UpdateEnablementAndVisibilityOfControls(handles);
  %set(handles.menu_file,'enable','on');
  %set(handles.menu_edit,'enable','on');
  %set(handles.menu_go,'enable','on');
  %set(handles.menu_classifier,'enable','on');
  %set(handles.pushbutton_train,'Enable','on');


end

guidata(hObject,handles);

return


% -------------------------------------------------------------------------
function handles = SetLabelPlot(handles,t0,t1,behaviori,important)

% if behaviori == 0,
%   return;
% end

% if t == handles.lastframe_labeled,
%   warning('This should never happen');
%   keyboard;
% end
% 
% if isempty(handles.lastframe_labeled),
%   t0 = t;
%   t1 = t;
%   t2 = min(t+1,handles.data.t1_curr);
% else
%   if t < handles.lastframe_labeled,
%     t0 = t;
%     t1 = handles.lastframe_labeled-1;
%     t2 = handles.lastframe_labeled;
%   elseif t > handles.lastframe_labeled,
%     t0 = handles.lastframe_labeled+1;
%     t1 = t;
%     t2 = min(t+1,handles.data.t1_curr);
%   end
% end

% WARNING: this function directly accesses handles.data.labelidx, trx make sure
% that we've preloaded the right experiment and flies. 
% REMOVED!
% if handles.data.expi ~= handles.data.expi || ~all(handles.data.flies == handles.data.flies),
%   handles.data.Preload(handles.data.expi,handles.data.flies);
% end

if t1 < t0,
  tmp = t1;
  t1 = t0;
  t0 = tmp;
end
handles.guidata.labels_plot.x(:,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,:,:) = nan;
handles.guidata.labels_plot.y(:,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,:,:) = nan;
% handles.data.labelidx(t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off) = 0;

for channel = 1:3,
  handles.guidata.labels_plot.im(1,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,channel) = handles.guidata.labelunknowncolor(channel);
end
handles.data.SetLabel(handles.data.expi,handles.data.flies,t0:t1,behaviori,important);
if behaviori > 0,
  % handles.data.labelidx(t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off) = behaviori;
  for channel = 1:3,
    handles.guidata.labels_plot.im(1,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,channel) = handles.guidata.labelcolors(behaviori,channel);
  end
  for l = 1:numel(handles.data.flies),
    %off = handles.data.trx(handles.data.flies(l)).off;
    %j0 = t0+off;
    %j2 = t2+off;
    k0 = t0+handles.guidata.labels_plot_off;
    k2 = t1+handles.guidata.labels_plot_off+1;
    xplot = handles.data.GetTrxValues('X1',handles.data.expi,handles.data.flies(l),min(t0:t1+1,handles.data.t1_curr));
    yplot = handles.data.GetTrxValues('Y1',handles.data.expi,handles.data.flies(l),min(t0:t1+1,handles.data.t1_curr));
    handles.guidata.labels_plot.x(:,k0:k2-1,behaviori,l) = [xplot(1:end-1);xplot(2:end)];
    handles.guidata.labels_plot.y(:,k0:k2-1,behaviori,l) = [yplot(1:end-1);yplot(2:end)];      

%     handles.guidata.labels_plot.x(k0:k2,behaviori,l) = ...
%       handles.data.trx(handles.data.flies(l)).x(j0:j2);
%     handles.guidata.labels_plot.y(k0:k2,behaviori,l) = ...
%       handles.data.trx(handles.data.flies(l)).y(j0:j2);
  end
end

% isstart
if t0 == handles.data.t0_curr,
  handles.guidata.labels_plot.isstart(t0+handles.guidata.labels_plot_off) = behaviori ~= 0;
end
t00 = max(handles.data.t0_curr+1,t0);
off0 = t00+handles.guidata.labels_plot_off;
off1 = t1+handles.guidata.labels_plot_off;
% handles.guidata.labels_plot.isstart(off0:off1) = ...
%   handles.data.labelidx(off0:off1)~=0 & ...
%   handles.data.labelidx(off0-1:off1-1)~=handles.data.labelidx(off0:off1);
handles.guidata.labels_plot.isstart(off0:off1) = ...
  handles.data.IsLabelStart(handles.data.expi,handles.data.flies,t00:t1);

handles = UpdateErrors(handles);

%handles = SetNeedSave(handles);
UpdateEnablementAndVisibilityOfControls(handles);

%handles.lastframe_labeled = t;

guidata(handles.figure_JLabel,handles);

return


% -------------------------------------------------------------------------
function handles = SetLabelsPlot(handles,t0,t1,behavioris)


if t1 < t0,
  tmp = t1;
  t1 = t0;
  t0 = tmp;
end

handles.guidata.labels_plot.x(:,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,:,:) = nan;
handles.guidata.labels_plot.y(:,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,:,:) = nan;

for channel = 1:3,
  handles.guidata.labels_plot.im(1,t0+handles.guidata.labels_plot_off:t1+handles.guidata.labels_plot_off,channel) = handles.guidata.labelunknowncolor(channel);
end
handles.data.SetLabel(handles.data.expi,handles.data.flies,t0:t1,behavioris,0);

for behaviori = 1:handles.data.nbehaviors,

  bidx = find(behaviori == behavioris);
  if isempty(bidx),
    continue;
  end
  for channel = 1:3,
    handles.guidata.labels_plot.im(1,t0-1+bidx+handles.guidata.labels_plot_off,channel) = handles.guidata.labelcolors(behaviori,channel);
  end
  for l = 1:numel(handles.data.flies),
    ks = t0-1+handles.guidata.labels_plot_off+bidx;
    xplot0 = handles.data.GetTrxValues('X1',handles.data.expi,handles.data.flies(l),t0-1+bidx);
    xplot1 = handles.data.GetTrxValues('X1',handles.data.expi,handles.data.flies(l),min(t0+bidx,handles.data.t1_curr));
    handles.guidata.labels_plot.x(:,ks,behaviori,l) = [xplot0;xplot1];
    yplot0 = handles.data.GetTrxValues('Y1',handles.data.expi,handles.data.flies(l),t0-1+bidx);
    yplot1 = handles.data.GetTrxValues('Y1',handles.data.expi,handles.data.flies(l),min(t0+bidx,handles.data.t1_curr));
    handles.guidata.labels_plot.y(:,ks,behaviori,l) = [yplot0;yplot1];
  end
  
end

% isstart
if t0 == handles.data.t0_curr,
  handles.guidata.labels_plot.isstart(t0+handles.guidata.labels_plot_off) = behavioris(1) ~= 0;
end
t00 = max(handles.data.t0_curr+1,t0);
off0 = t00+handles.guidata.labels_plot_off;
off1 = t1+handles.guidata.labels_plot_off;
% handles.guidata.labels_plot.isstart(off0:off1) = ...
%   handles.data.labelidx(off0:off1)~=0 & ...
%   handles.data.labelidx(off0-1:off1-1)~=handles.data.labelidx(off0:off1);
handles.guidata.labels_plot.isstart(off0:off1) = ...
  handles.data.IsLabelStart(handles.data.expi,handles.data.flies,t00:t1);

handles = UpdateErrors(handles);

%handles = SetNeedSave(handles);
UpdateEnablementAndVisibilityOfControls(handles);

%handles.lastframe_labeled = t;

guidata(handles.figure_JLabel,handles);
return


% -------------------------------------------------------------------------
function handles = SetPredictedPlot(handles,t0,t1)
% Updates handles.guidata.labels_plot.predx and handles.guidata.labels_plot.predx 
% to match the current predictions.

% If no experiments, nothing to do
if (handles.data.nexps==0)
  return
end

% Get the prediction over the relevant time range, and the time range, if
% not provided.
iExp=handles.data.expi;
if nargin < 2,
  [prediction,t0,t1] = handles.data.GetPredictedIdx(iExp,handles.data.flies);
else
  prediction = handles.data.GetPredictedIdx(iExp,handles.data.flies,t0,t1);
end

% Break out prediction
predictedidx = prediction.predictedidx;
scoresidx=prediction.scoresidx;

% Normalize the scores
scores = handles.data.NormalizeScores(scoresidx);

% Set the x,y for the predictions to nan, so they don't show up except
% where we set them below
labelsPlotOffset=handles.guidata.labels_plot_off;
iFirst=t0+labelsPlotOffset;
iLast=t1+labelsPlotOffset;
handles.guidata.labels_plot.predx(:,iFirst:iLast,:,:) = nan;
handles.guidata.labels_plot.predy(:,iFirst:iLast,:,:) = nan;

% Loop over the behaviors (including "none")
for behaviori = 1:handles.data.nbehaviors,
  confidenceThreshold=handles.data.GetConfidenceThreshold(behaviori);
  bidx = find( (behaviori == predictedidx) & ...
               (abs(scores)>confidenceThreshold) );
  if isempty(bidx),
    continue;
  end
  for i = 1:numel(handles.data.flies),
    ks = t0-1+labelsPlotOffset+bidx;
    j=handles.data.flies(i);
    xplot0 = handles.data.GetTrxValues('X1',iExp,j,t0-1+bidx);
    xplot1 = handles.data.GetTrxValues('X1',iExp,j,min(t0+bidx,handles.data.t1_curr));
    handles.guidata.labels_plot.predx(:,ks,behaviori,i) = [xplot0;xplot1];
    yplot0 = handles.data.GetTrxValues('Y1',iExp,j,t0-1+bidx);
    yplot1 = handles.data.GetTrxValues('Y1',iExp,j,min(t0+bidx,handles.data.t1_curr));
    handles.guidata.labels_plot.predy(:,ks,behaviori,i) = [yplot0;yplot1];
  end
end

guidata(handles.figure_JLabel,handles);
return


% -------------------------------------------------------------------------
% --- Executes on button press in togglebutton_label_unknown.
function togglebutton_label_unknown_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_label_unknown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_label_unknown
if get(hObject,'Value'),
  % toggle on
  handles.guidata.label_state = -1; 
  handles.guidata.label_imp = [];
  handles.label_t0 = handles.guidata.ts(1);

  % set everything else to off
  for j = 1:2*handles.data.nbehaviors,
    if isnan(handles.guidata.togglebutton_label_behaviors(j)), continue; end
    set(handles.guidata.togglebutton_label_behaviors(j),'Value',0,'Enable','off');
  end

  set(handles.guidata.htimeline_label_curr,'XData',handles.label_t0 + [-.5,-.5,.5,.5,-.5],...
    'FaceColor',handles.guidata.labelunknowncolor);
  
  UpdatePlots(handles,...
    'refreshim',false,'refreshflies',true,'refreshtrx',false,'refreshlabels',true,...
    'refresh_timeline_manual',true,...
    'refresh_timeline_auto',false,...
    'refresh_timeline_suggest',false,...
    'refresh_timeline_error',true,...
    'refresh_timeline_xlim',false,...
    'refresh_timeline_hcurr',false,...
    'refresh_timeline_props',false,...
    'refresh_timeline_selection',false,...
    'refresh_curr_prop',false);

  set(handles.menu_file,'enable','off');
  set(handles.menu_edit,'enable','off');
  set(handles.menu_go,'enable','off');
  set(handles.menu_classifier,'enable','off');
  set(handles.pushbutton_train,'Enable','off');
  

  
%   % set everything else to off
%   for j = 1:handles.data.nbehaviors,
%     set(handles.guidata.togglebutton_label_behaviors(j),'Value',0,'String',sprintf('Start %s',handles.data.labelnames{j}));
%   end
%   % set the current frame to be labeled
%   %handles.lastframe_labeled = [];
%   handles = SetLabelPlot(handles,min(handles.data.t1_curr,max(handles.data.t0_curr,handles.guidata.ts(1))),0);
%   UpdatePlots(handles,'refreshim',false,'refreshtrx',false,'refreshflies',false);
%   set(handles.togglebutton_label_unknown,'String','*Label Unknown*');

else
  
  if handles.guidata.ts(1) <= handles.label_t0,
    t0 = handles.guidata.ts(1);
    t1 = handles.label_t0;
  else
    t0 = handles.label_t0;
    t1 = handles.guidata.ts(1);
  end
  t0 = min(handles.data.t1_curr,max(handles.data.t0_curr,t0));
  t1 = min(handles.data.t1_curr,max(handles.data.t0_curr,t1));
  handles = SetLabelPlot(handles,t0,t1,0,0);

  handles.guidata.label_state = 0;
  handles.guidata.label_imp = [];
  handles.label_t0 = [];
  set(handles.guidata.htimeline_label_curr,'XData',nan(1,5));
    
  %handles.data.StoreLabels();
  for j = 1:2*handles.data.nbehaviors,
    if isnan(handles.guidata.togglebutton_label_behaviors(j)), continue; end
    buttonStr = sprintf('%s',handles.data.labelnames{ceil(j/2)});
    if handles.guidata.GUIAdvancedMode && mod(j,2); 
      buttonStr = sprintf('Important %s',buttonStr); 
    end
    set(handles.guidata.togglebutton_label_behaviors(j),'Value',0,'String',buttonStr,'Enable','on');
  end
  set(handles.togglebutton_label_unknown,'Value',0,'String','Unknown','Enable','on');  
  UpdatePlots(handles,...
    'refreshim',false,'refreshflies',true,'refreshtrx',false,'refreshlabels',true,...
    'refresh_timeline_manual',true,...
    'refresh_timeline_auto',false,...
    'refresh_timeline_suggest',false,...
    'refresh_timeline_error',true,...
    'refresh_timeline_xlim',false,...
    'refresh_timeline_hcurr',false,...
    'refresh_timeline_props',false,...
    'refresh_timeline_selection',false,...
    'refresh_curr_prop',false);
  
%   handles.guidata.label_state = 0;
%   %handles.data.StoreLabels();
%   set(handles.togglebutton_label_unknown,'String','Start Unknown');
  set(handles.menu_file,'enable','on');
  set(handles.menu_edit,'enable','on');
  set(handles.menu_go,'enable','on');
  set(handles.menu_classifier,'enable','on');
  set(handles.pushbutton_train,'Enable','on');
   
end

guidata(hObject,handles);
return


% -------------------------------------------------------------------------
function edit_framenumber_Callback(hObject, eventdata, handles)
% hObject    handle to edit_framenumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_framenumber as text
%        str2double(get(hObject,'String')) returns contents of edit_framenumber as a double
v = str2double(get(hObject,'String'));
i = GetPreviewPanelNumber(hObject);
if isnan(v) || isempty(v),
  set(hObject,'String',num2str(handles.guidata.ts(i)));
else
  v = round(v);
  if v >= handles.data.t0_curr && v <= handles.data.t1_curr
    handles = SetCurrentFrame(handles,i,v,hObject);
  else
    warndlg('Frame number should be within the range for the current fly');
    set(hObject,'String',num2str(handles.guidata.ts(i)));
  end
  guidata(hObject,handles);
end
return


% -------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function edit_framenumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_framenumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return


% --------------------------------------------------------------------
function menu_view_timeline_view_options_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_timeline_view_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prompts = {'N. frames shown:'};
answers = {num2str(handles.guidata.timeline_nframes)};
res = inputdlg(prompts,'Timeline view options',numel(prompts),answers);
if isempty(res); return; end;
handles.guidata.timeline_nframes = str2double(res{1});

xlim = [handles.guidata.ts(1)-(handles.guidata.timeline_nframes-1)/2,...
  handles.guidata.ts(1)+(handles.guidata.timeline_nframes-1)/2];
for i = 1:numel(handles.guidata.axes_timelines),
  set(handles.guidata.axes_timelines(i),'XLim',xlim);
  zoom(handles.guidata.axes_timelines(i),'reset');
end
guidata(hObject,handles);
return


% -------------------------------------------------------------------------
% --- Executes on mouse press over axes background.
function axes_preview_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes_preview (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% WARNING: this function directly accesses handles.data.trx make sure
% that we've preloaded the right experiment and flies. 
% REMOVED!

% if ~handles.guidata.enabled,
%   return;
% end

% double-click does nothing
if strcmpi(get(handles.figure_JLabel,'SelectionType'),'open'),
  return;
end

if handles.data.expi ~= handles.data.expi,
  handles.data.Preload(handles.data.expi,handles.data.flies);
end

% which preview panel is this
i = GetPreviewPanelNumber(hObject);
nprev = handles.guidata.traj_nprev;
npost = handles.guidata.traj_npost;
mind = inf;
pt = get(handles.guidata.axes_previews(i),'CurrentPoint');
xclick = pt(1,1);
yclick = pt(1,2);
dx = diff(get(handles.guidata.axes_previews(i),'XLim'));
dy = diff(get(handles.guidata.axes_previews(i),'YLim'));
for j = 1:numel(handles.data.flies),
  fly = handles.data.flies(j);
  T0 = handles.data.firstframes_per_exp{handles.data.expi}(fly);
  T1 = handles.data.endframes_per_exp{handles.data.expi}(fly);
  t0 = min(T1,max(T0,handles.guidata.ts(i)-nprev));
  t1 = min(T1,max(T0,handles.guidata.ts(i)+npost));
  %off = handles.data.trx(fly).off;
%   [mindcurr,k] = min( ((handles.data.trx(fly).x(t0+off:t1+off)-xclick)/dx).^2 + ...
%     ((handles.data.trx(fly).y(t0+off:t1+off)-yclick)/dy).^2 );
  [mindcurr,k] = min( ((handles.data.GetTrxValues('X1',handles.data.expi,fly,t0:t1)-xclick)/dx).^2 + ...
    ((handles.data.GetTrxValues('Y1',handles.data.expi,fly,t0:t1)-yclick)/dy).^2 );
  if mindcurr < mind,
    mind = mindcurr;
    mint = k+t0-1;
  end
end
if mind <= handles.guidata.max_click_dist_preview
  handles = SetCurrentFrame(handles,i,mint,hObject);
end
guidata(hObject,handles);
return


function fly_ButtonDownFcn(hObject, eventdata, handles, flyi, i)

fly = handles.guidata.idx2fly(flyi);

% TODO: figure out how to do this when multiple flies define a behavior

% if ~handles.guidata.enabled,
%   return;
% end

% check for double click
if ~strcmpi(get(handles.figure_JLabel,'SelectionType'),'open') || ...
    numel(handles.data.flies) == 1 && handles.data.flies == fly,
  % call the axes button down fcn
  axes_preview_ButtonDownFcn(handles.axes_preview(i), eventdata, handles);
  return;
end

% Dont switch flies when the label pen is down.
penDown = false;
if ~handles.guidata.GUIAdvancedMode,
  behaviorVals = get(handles.guidata.togglebutton_label_behaviors(1:2:end),'Value');
else
  behaviorVals = get(handles.guidata.togglebutton_label_behaviors,'Value');
end

for ndx = 1:length(behaviorVals)
  penDown = penDown | behaviorVals{ndx};
end
penDown = penDown | get(handles.togglebutton_label_unknown,'Value');
if penDown, return; end

% check if the user wants to switch to this fly
% TODO: this directly accesses handles.data.labels -- abstract this
if isempty(handles.data.labels(handles.data.expi).flies)
  ism = false;
else
  [ism,j] = ismember(fly,handles.data.labels(handles.data.expi).flies,'rows');
end
if ism,
  nbouts = nnz(~strcmpi(handles.data.labels(handles.data.expi).names{j},'None'));
else
  nbouts = 0;
end

endframe = handles.data.endframes_per_exp{handles.data.expi}(fly);
firstframe = handles.data.firstframes_per_exp{handles.data.expi}(fly);
prompt = {sprintf('Switch to fly %d?',fly),...
  sprintf('Trajectory length = %d',endframe-firstframe+1),...
  sprintf('First frame = %d',firstframe),...
  sprintf('N. bouts labeled: %d',nbouts)};

if handles.data.hassex,
  if handles.data.hasperframesex,
    sexfrac = handles.data.GetSexFrac(handles.data.expi,fly);
    prompt{end+1} = sprintf('Sex: %d%%M, %d%%F',round(sexfrac.M*100),round(sexfrac.F*100));
  else
    t = max(handles.data.t0_curr,handles.guidata.ts(1));
    sex = handles.data.GetSex(handles.data.expi,fly,t);
    if iscell(sex),
      sex = sex{1};
    end
    prompt{end+1} = sprintf('Sex: %s',sex);
  end
end

res = questdlg(prompt,...
  'Change flies?','Yes','No','Yes');

if strcmpi(res,'No'),
  return;
end

SetCurrentFlies(handles,fly);
return


% -------------------------------------------------------------------------
% --- Executes on mouse press over axes background.
function axes_timeline_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to axes_timeline_manual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if ~handles.guidata.enabled,
%   return;
% end

pt = get(hObject,'CurrentPoint');

t = min(max(handles.data.GetMinFirstFrame,round(pt(1,1))),handles.data.GetMaxEndFrame);
% TODO: which axes?
SetCurrentFrame(handles,1,t,hObject);
return


% -------------------------------------------------------------------------
% --- Executes on button press in pushbutton_train.
function pushbutton_train_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_train (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check that the user has selected features already

%t=tic;
perFrameFeatureSetIsNonEmpty= ...
  ~isempty(handles.data) && ...
  handles.data.getPerFrameFeatureSetIsNonEmpty();
if ~perFrameFeatureSetIsNonEmpty,
  uiwait(helpdlg('Select Features before training'));
  oldPointer=pointerToWatch(hObject);
  SelectFeatures(handles.figure_JLabel);
  restorePointer(hObject,oldPointer);
  return;
end
% store the current labels to windowdata_labeled
%handles.data.StoreLabelsAndPreLoadWindowData();  
%  now do this inside JLabelData.Train()
handles.data.Train(handles.guidata.doFastUpdates);
handles = SetPredictedPlot(handles);
% predict for current window
handles = predict(handles);
% handles.data.needsave=true;  % done in .Train()
UpdateEnablementAndVisibilityOfControls(handles);
guidata(hObject,handles);
%toc(t)
return


% -------------------------------------------------------------------------
function handles = predict(handles)

% predict for the currently shown timeline
% TODO: make this work for multiple axes
% Note that this is a controller-like "method", b/c it changes the model
% and the view.
t0 = max(handles.data.t0_curr,floor(handles.guidata.ts(1)-handles.guidata.timeline_nframes/2));
t1 = min(handles.data.t1_curr,ceil(handles.guidata.ts(1)+7*handles.guidata.timeline_nframes/2));
handles.data.Predict(handles.data.expi,handles.data.flies,t0,t1);
handles = SetPredictedPlot(handles);

handles = UpdateTimelineImages(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles, ...
            'refreshim',false, ...
            'refreshflies',true,  ...
            'refreshtrx',true, ...
            'refreshlabels',true,...
            'refresh_timeline_manual',false,...
            'refresh_timeline_xlim',false,...
            'refresh_timeline_hcurr',false,...
            'refresh_timeline_selection',false,...
            'refresh_curr_prop',false);
return


% -------------------------------------------------------------------------
function handles = UpdateErrors(handles)

% update prediction for currently shown timeline
% TODO: make this work for multiple axes
%handles.data.UpdateErrorIdx();  % we now do this wehn we set the
% labels in JLabelData
handles = UpdateTimelineImages(handles);
UpdatePlots(handles, ...
            'refreshim',false, ...
            'refreshflies',false, ...
            'refreshtrx',false, ...
            'refreshlabels',false,...
            'refresh_timeline_manual',false,...
            'refresh_timeline_xlim',false,...
            'refresh_timeline_hcurr',false,...
            'refresh_timeline_selection',false,...
            'refresh_curr_prop',false);
return


% -------------------------------------------------------------------------
% --- Executes on button press in pushbutton_predict.
function pushbutton_predict_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_predict (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = predict(handles);
guidata(hObject,handles);
return


% -------------------------------------------------------------------------
% --- Executes on key press with focus on figure_JLabel or any of its controls.
function figure_JLabel_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

%disp(eventdata.Character);
%disp(eventdata.Modifier);
return


% -------------------------------------------------------------------------
function SetStatusCallback(s,h)

handles = guidata(h);
SetStatus(handles,s);
return


% -------------------------------------------------------------------------
function ClearStatusCallback(h)

handles = guidata(h);
ClearStatus(handles);
return


% -------------------------------------------------------------------------
function SetStatus(handles,s,isbusy)
if nargin < 3 || isbusy,
  color = handles.guidata.busystatuscolor;
  set(handles.figure_JLabel,'Pointer','watch');
else
  color = handles.guidata.idlestatuscolor;
  set(handles.figure_JLabel,'Pointer','arrow');
end
set(handles.text_status,'ForegroundColor',color,'String',s);
if strcmpi(get(handles.figure_JLabel,'Visible'),'off'),
  msgbox(s,'JAABA Status','modal');
end
drawnow('update');  % want immediate update
return


% -------------------------------------------------------------------------
function ClearStatus(handles)
set(handles.text_status, ...
    'ForegroundColor',handles.guidata.idlestatuscolor, ...
    'String',handles.guidata.status_bar_text_when_clear);
set(handles.figure_JLabel,'Pointer','arrow');
h = findall(0,'Type','figure','Name','JAABA Status');
if ~isempty(h), delete(h(ishandle(h))); end
drawnow('update');  % want immediate update
return 


% -------------------------------------------------------------------------
function syncStatusBarTextWhenClear(handles)
% Set the status bar text displayed when the status bar is in the "clear"
% state to the default clear message, which is something along the lines of
% "<file name>: <experiment dir name>, Fly <target index>"
% It figures this out by looking at various fields in handles.guidata and
% handles.data.

thereIsAnOpenFile=handles.data.thereIsAnOpenFile;
if thereIsAnOpenFile ,
  fileNameAbs=handles.data.everythingFileNameAbs;
  fileNameRel=fileNameRelFromAbs(fileNameAbs);
  someExperimentIsCurrent=handles.data.getSomeExperimentIsCurrent();
  if someExperimentIsCurrent ,
    iCurrentExp=handles.data.expi;
    expDirNameAbs=handles.data.expdirs{iCurrentExp};
    expName=fileNameRelFromAbs(expDirNameAbs);
    targetType=handles.data.targettype;
    nTargetsInThisExp=handles.data.nflies_per_exp(iCurrentExp);
    if nTargetsInThisExp==0 ,
      statusBarText=sprintf('%s: %s',fileNameRel,expName);
    else
      iCurrentTarget=handles.data.flies;
      statusBarText = sprintf('%s: %s, %s %d',fileNameRel,expName,targetType,iCurrentTarget);
    end
  else
    statusBarText=fileNameRel;
  end
else
  statusBarText='No file open.';
end
handles.guidata.status_bar_text_when_clear=statusBarText;

return 


% --------------------------------------------------------------------
function menu_file_load_top_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_load_top (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
% function menu_go_switch_experiment_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_go_switch_experiment (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% s = cell(1,handles.data.nexps);
% for i = 1:handles.data.nexps,
%   expStats = handles.data.GetExpStats(i);
%   if i == handles.data.expi,
%     s{i} = sprintf('%s, N flies: %d, OPEN NOW',...
%       expStats.name,expStats.nflies);
%   else
%     s{i} = sprintf('%s, N flies: %d',expStats.name,expStats.nflies);
%     if handles.data.hassex,
%       nmales = sum([handles.data.frac_sex_per_exp{i}.M]);
%       nfemales = sum([handles.data.frac_sex_per_exp{i}.F]);
%       if handles.data.hasperframesex,
%         s{i} = [s{i},sprintf('(%.1f M, %.1f F)',nmales,nfemales)];
%       else
%         s{i} = [s{i},sprintf('(%d M, %d F)',nmales,nfemales)];
%       end
%     end
%     s{i} = [s{i},sprintf(', N flies labeled: %d, N bouts labeled: %d, last labeled: %s',...
%       expStats.nlabeledflies,...
%       expStats.nlabeledbouts,...
%       expStats.labeldatestr)];
%     if ~isempty(expStats.nscoreframes)
%       s{i} = [s{i},sprintf(', Frames Predicted as %s:%d, Total Frames Predicted:%d, Classifier used to predict:%s',...
%         handles.data.labelnames{1},...
%         expStats.nscorepos,...
%         expStats.nscoreframes,...
%         expStats.classifierfilename)];
%     end
%     
%   end
% end
% [expi,ok] = listdlg('ListString',s,'SelectionMode','single',...
%   'InitialValue',handles.data.expi,'Name','Switch experiment',...
%   'PromptString','Select experiment:',...
%   'ListSize',[640,300]);
% if ~ok || expi == handles.data.expi,
%   return;
% end
% [handles,success] = SetCurrentMovie(handles,expi);
% if ~success,
%   return;
% end
% guidata(hObject,handles);

% --------------------------------------------------------------------
% function menu_go_switch_target_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_go_switch_target (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % TODO: generalize this to multiple flies labeled
% 
% nflies = handles.data.nflies_per_exp(handles.data.expi);
% s = cell(1,nflies);
% for fly = 1:nflies,
%   if fly == handles.data.flies(1),
%     s{fly} = sprintf('Target %3d, CURRENTLY SELECTED',fly);
%   else
%     flyStats = handles.data.GetFlyStats(handles.data.expi,fly);
%     s{fly} = sprintf('Target %3d, Trajectory length %5d, First frame %5d, N bouts labeled %2d',...
%       fly,flyStats.trajLength,flyStats.firstframe,flyStats.nbouts);
%     if flyStats.hassex,
%       if ~isempty(flyStats.sexfrac),
%         s{fly} = [s{fly},sprintf(', Sex: %3d%%M, %3d%%F',...
%           round(flyStats.sexfrac.M*100),round(flyStats.sexfrac.F*100))];
%       else
%         s{fly} = [s{fly},sprintf(', Sex: %s',flyStats.sex{1})];
%       end
%     end
%     if ~isempty(flyStats.nscoreframes)
%       s{fly} = [s{fly},sprintf(', Frames Predicted as %s:%d, Total Frames Predicted:%d',...
%         handles.data.labelnames{1},flyStats.nscorepos,flyStats.nscoreframes)];
%     end
%   end
% end
% 
% 
% [fly,ok] = listdlg('ListString',s,'SelectionMode','single',...
%   'InitialValue',handles.data.flies(1),'Name','Switch target',...
%   'PromptString','Select experiment:',...
%   'ListSize',[640,300]);
% if ~ok || fly == handles.data.flies(1),
%   return;
% end
% handles = SetCurrentFlies(handles,fly);
% guidata(hObject,handles);
%}


% --------------------------------------------------------------------
function menu_view_center_on_target_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_center_on_target (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.preview_zoom_mode = 'center_on_fly';
UpdateGUIToMatchPreviewZoomMode(handles)
ZoomInOnFlies(handles);
guidata(hObject,handles);
return


% -------------------------------------------------------------------------
function ZoomInOnFlies(handles,indicesOfPreviewAxes)
% Modify the limits of the given preview axes to get all of the current 
% flies centered in the axes, without changing the zoom level.  
% (I think.  --ALT; Feb 3, 2013)

someExperimentIsCurrent=handles.data.getSomeExperimentIsCurrent();
if ~someExperimentIsCurrent,
  return
end
  
if nargin < 2,
  indicesOfPreviewAxes = 1:numel(handles.guidata.axes_previews);
end

xs = nan(1,numel(handles.data.flies));
ys = nan(1,numel(handles.data.flies));
for i = indicesOfPreviewAxes,
  firstframes = handles.data.firstframes_per_exp{handles.data.expi}(handles.data.flies);
  endframes = handles.data.endframes_per_exp{handles.data.expi}(handles.data.flies);
  %inds = handles.guidata.ts(i)-firstframes+1;
  for j = 1:numel(handles.data.flies),
    if handles.guidata.ts(i) < firstframes(j) || handles.guidata.ts(i) > endframes(j),
      continue;
    end
    xs(j) = handles.data.GetTrxValues('X1',handles.data.expi,handles.data.flies(j),handles.guidata.ts(i));
    ys(j) = handles.data.GetTrxValues('Y1',handles.data.expi,handles.data.flies(j),handles.guidata.ts(i));
    %xs(j) = handles.data.trx(handles.data.flies(j)).x(inds(j));
    %ys(j) = handles.data.trx(handles.data.flies(j)).y(inds(j));
  end
  if ~all(isnan(xs)) && ~all(isnan(ys)),
    %xlim = [max([.5,xs-handles.guidata.zoom_fly_radius(1)]),min([handles.guidata.movie_width+.5,xs+handles.guidata.zoom_fly_radius(1)])];
    %ylim = [max([.5,ys-handles.guidata.zoom_fly_radius(2)]),min([handles.guidata.movie_height+.5,ys+handles.guidata.zoom_fly_radius(2)])];
    x0 = min(xs) - handles.guidata.zoom_fly_radius(1);
    x1 = max(xs) + handles.guidata.zoom_fly_radius(1);
    if x1 - x0 + 1 >= handles.guidata.movie_width,
      xlim = [.5,handles.guidata.movie_width+.5];
    elseif x0 < .5,
      dx = .5 - x0;
      xlim = [.5,x1 + dx];
    elseif x1 > handles.guidata.movie_width+.5,
      dx = x1 - (handles.guidata.movie_width+.5);
      xlim = [x0-dx,handles.guidata.movie_width+.5];
    else
      xlim = [x0,x1];
    end
    y0 = min(ys) - handles.guidata.zoom_fly_radius(2);
    y1 = max(ys) + handles.guidata.zoom_fly_radius(2);
    if y1 - y0 + 1 >= handles.guidata.movie_height,
      ylim = [.5,handles.guidata.movie_height+.5];
    elseif y0 < .5,
      dy = .5 - y0;
      ylim = [.5,y1 + dy];
    elseif y1 > handles.guidata.movie_height+.5,
      dy = y1 - (handles.guidata.movie_height+.5);
      ylim = [y0-dy,handles.guidata.movie_height+.5];
    else
      ylim = [y0,y1];
    end    
    set(handles.guidata.axes_previews(i),'XLim',xlim,'YLim',ylim);
  end
end
return


% -------------------------------------------------------------------------
function KeepFliesInView(handles,indicesOfPreviewAxes,doforce)
% Modify the limits of the given preview axes to get all of the current 
% flies in view, without changing the zoom level.  (I think.  ALT; Feb 3,
% 2013)

if nargin < 3,
  doforce = false;
end

someExperimentIsCurrent=handles.data.getSomeExperimentIsCurrent();
if ~someExperimentIsCurrent,
  return
end

if nargin < 2,
  indicesOfPreviewAxes = 1:numel(handles.guidata.axes_previews);
end

% get the vars we need to mess with a lot
flies=handles.data.flies;  % indices of the current flies
nFlies=numel(flies);
expi=handles.data.expi;
zoom_fly_radius=handles.guidata.zoom_fly_radius;  % 2x1
movie_width=handles.guidata.movie_width;
movie_height=handles.guidata.movie_height;

xs = nan(1,nFlies);
ys = nan(1,nFlies);
for i = indicesOfPreviewAxes,
  firstframes = handles.data.firstframes_per_exp{expi}(flies);
  endframes = handles.data.endframes_per_exp{expi}(flies);
  %inds = handles.guidata.ts(i)-firstframes+1;
  for j = 1:nFlies,
    if handles.guidata.ts(i) < firstframes(j) || handles.guidata.ts(i) > endframes(j),
      continue;
    end
    xs(j) = handles.data.GetTrxValues('X1',expi,flies(j),handles.guidata.ts(i));
    ys(j) = handles.data.GetTrxValues('Y1',expi,flies(j),handles.guidata.ts(i));
    %xs(j) = handles.data.trx(flies(j)).x(inds(j));
    %ys(j) = handles.data.trx(flies(j)).y(inds(j));
  end
  xl = get(handles.guidata.axes_previews(i),'XLim');
  % a little border at the edge of the image
  border = .1;
  dx = diff(xl);
  xl(1) = xl(1) + dx*border;
  xl(2) = xl(2) - dx*border;
  yl = get(handles.guidata.axes_previews(i),'YLim');
  dy = diff(yl);
  yl(1) = yl(1) + dy*border;
  yl(2) = yl(2) - dy*border;
  % If any of the flies is out of view, re-center on the fly, without
  % changing the size of the viewport
  if doforce || min(xs)-handles.guidata.meana*2 < xl(1) || min(ys)-handles.guidata.meana*2 < yl(1) || ...
     max(xs)+handles.guidata.meana*2 > xl(2) || max(ys)+handles.guidata.meana*2 > yl(2),
    % center on flies
    newxlim = [max([.5,xs-zoom_fly_radius(1)]), ...
               min([movie_width+.5,xs+zoom_fly_radius(1)])];
    newylim = [max([.5,ys-zoom_fly_radius(2)]), ...
               min([movie_height+.5,ys+zoom_fly_radius(2)])];
    set(handles.guidata.axes_previews(i),'XLim',newxlim,'YLim',newylim);    
  end
end

return


% -------------------------------------------------------------------------
function ShowWholeVideo(handles,is)

if nargin < 2,
  is = 1:numel(handles.guidata.axes_previews);
end

for i = is,
  newxlim = [.5,handles.guidata.movie_width+.5];
  newylim = [.5,handles.guidata.movie_height+.5];
  set(handles.guidata.axes_previews(i),'XLim',newxlim,'YLim',newylim);  
end
return


% % --------------------------------------------------------------------
% function menu_file_export_labels_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_file_export_labels (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% handles.data.SaveLabels();
% handles.data.SaveGTLabels();


% --------------------------------------------------------------------
function menu_edit_clear_all_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_clear_all_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

s = {};
s{end+1} = 'Experiments with labels: ';
for i = 1:numel(handles.data.labelstats),
  if handles.data.labelstats(i).nbouts_labeled > 0,
    s{end+1} = sprintf('%s: %d bouts',handles.data.expnames{i},handles.data.labelstats(i).nbouts_labeled); %#ok<AGROW>
  end
end

res = questdlg(s,'Really delete all labels?','Yes','No','Cancel','Cancel');
if strcmpi(res,'Yes'),
  handles.data.ClearLabels();
  handles = UpdateTimelineImages(handles);
  UpdatePlots(handles);
end
return


% -------------------------------------------------------------------------
function RecursiveSetKeyPressFcn(hfig)

hchil = findall(hfig,'-property','KeyPressFcn');
goodidx = true(1,numel(hchil));
for i = 1:numel(hchil),
  if strcmpi(get(hchil(i),'Type'),'uicontrol') && strcmpi(get(hchil(i),'Style'),'edit'),
    goodidx(i) = false;
  end
end
set(hchil(goodidx),'KeyPressFcn',get(hfig,'KeyPressFcn'));
return


% -------------------------------------------------------------------------
% --- Executes on key release with focus on figure_JLabel and none of its controls.
function figure_JLabel_KeyReleaseFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was released, in lower case
%	Character: character interpretation of the key(s) that was released
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) released
% handles    structure with handles and user data (see GUIDATA)
switch eventdata.Key,
  case 'space',
    pushbutton_playstop_Callback(handles.pushbutton_playstop,[],handles);
end
return


% -------------------------------------------------------------------------
% --- Executes on key press with focus on figure_JLabel and none of its controls.
function figure_JLabel_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

% if ~handles.guidata.enabled,
%   return;
% end

if isempty(handles)
  handles=guidata(get(hObject,'UserData'));
end

if strcmpi(eventdata.Modifier,'control')
  switch eventdata.Key,
    case 't',
      % if ~isempty(handles.data) && ...
      if handles.data.thereIsAnOpenFile && ...
         ~handles.data.gtMode,
        pushbutton_train_Callback(hObject,eventdata,handles);
      end
      
    case 'p',
        pushbutton_predict_Callback(hObject,eventdata,handles);
    case 'n',
      menu_go_navigation_preferences_Callback(hObject,eventdata,handles);
    case 'j',
      menu_go_switch_target_Callback(hObject,eventdata,handles);
    case 'u',
      menu_go_switch_exp_Callback(hObject,eventdata,handles);
    case 'k'
      menu_view_plot_tracks_Callback(handles.menu_view_plot_tracks,eventdata,handles);
    case 'f'
      menu_view_show_whole_frame_Callback(handles.menu_view_show_whole_frame,eventdata,handles);
    case '9'
      if (handles.data.expi -1)>0,
        SetCurrentMovie(handles,handles.data.expi-1);
      end
    case '0'
      if (handles.data.expi +1) <= handles.data.nexps 
        SetCurrentMovie(handles,handles.data.expi+1);
      end
    case '1'

      if handles.data.flies - 1 > 0
        handles = SetCurrentFlies(handles,handles.data.flies - 1);
        guidata(hObject,handles);
      end
      
    case '2'
      if handles.data.flies + 1 <= handles.data.nflies_per_exp(handles.data.expi)
        handles = SetCurrentFlies(handles,handles.data.flies + 1);
        guidata(hObject,handles);
      end
      
    case 's'
      if strcmp(get(handles.menu_file_save,'Enable'),'on')
        menu_file_save_Callback(hObject,[],handles);
      end
    case 'ii'
      for i = 1:numel(handles.guidata.axes_previews),
        xx = get(handles.guidata.axes_previews(i),'XLim');
        yy = get(handles.guidata.axes_previews(i),'YLim');
        set(handles.guidata.axes_previews(i),'XLim',xx/2);
        set(handles.guidata.axes_previews(i),'YLim',yy/2);
        [handles] = UpdateZoomFlyRadius(handles,i);
      end
      guidata(hObject,handles);
    case 'oo'
      handles.guidata.zoom_fly_radius = handles.guidata.zoom_fly_radius*2;
      handles = UpdateZoomFlyRadius(handles,1);
      guidata(hObject,handles);
      
  end
end

switch eventdata.Key,
  
  case 'leftarrow',
    if ~isempty(eventdata.Modifier) && any(strcmpi(eventdata.Modifier,{'control','command'})),
      menu_go_previous_manual_bout_end_Callback(hObject,eventdata,handles);
    elseif strcmpi(eventdata.Modifier,'shift'),
      menu_go_previous_automatic_bout_end_Callback(hObject,eventdata,handles);
    else
      menu_go_previous_frame_Callback(hObject, eventdata, handles);
    end
     
  case 'rightarrow',
    if ~isempty(eventdata.Modifier) && any(strcmpi(eventdata.Modifier,{'control','command'})),
      menu_go_next_manual_bout_start_Callback(hObject,eventdata,handles);
    elseif strcmpi(eventdata.Modifier,'shift'),
      menu_go_next_automatic_bout_start_Callback(hObject,eventdata,handles);
    else
      menu_go_next_frame_Callback(hObject, eventdata, handles);
    end
  
  case 'uparrow',
    menu_go_back_several_frames_Callback(hObject, eventdata, handles);
    
  case 'downarrow',
    menu_go_forward_several_frames_Callback(hObject, eventdata, handles);

    
  case handles.guidata.label_shortcuts,
    if strcmpi(eventdata.Modifier,'control')
      return;
    end
    buttonNum = find(strcmp(eventdata.Key,handles.guidata.label_shortcuts),1);
    if buttonNum > 2*handles.data.nbehaviors,
      if handles.guidata.label_state > 0,
        buttonNum = 2*handles.guidata.label_state - handles.guidata.label_imp;
        set(handles.guidata.togglebutton_label_behaviors(buttonNum),'Value',false);
        togglebutton_label_behavior1_Callback(handles.guidata.togglebutton_label_behaviors(buttonNum), eventdata, handles);
        handles = guidata(hObject);
      end
      set(handles.togglebutton_label_unknown,'Value',get(handles.togglebutton_label_unknown,'Value')==0);
      togglebutton_label_unknown_Callback(handles.togglebutton_label_unknown, eventdata, handles);
      return;
    else
      if ~handles.guidata.GUIAdvancedMode && ~mod(buttonNum,2); return; end 
      % Don't do anything when unimportant label keys are pressed in the Normal mode
      if handles.guidata.label_state == -1,
        set(handles.togglebutton_label_unknown,'Value',false);
        togglebutton_label_unknown_Callback(handles.togglebutton_label_unknown, eventdata, handles);
        handles = guidata(hObject);
      elseif handles.guidata.label_state > 0 && (2*handles.guidata.label_state -handles.guidata.label_imp)~= buttonNum,
        prevButtonNum = 2*handles.guidata.label_state - handles.guidata.label_imp;
        set(handles.guidata.togglebutton_label_behaviors(prevButtonNum),'Value',false);
        togglebutton_label_behavior1_Callback(handles.guidata.togglebutton_label_behaviors(prevButtonNum), eventdata, handles);
        handles = guidata(hObject);
      end
      set(handles.guidata.togglebutton_label_behaviors(buttonNum),'Value',...
        get(handles.guidata.togglebutton_label_behaviors(buttonNum),'Value')==0);
      togglebutton_label_behavior1_Callback(handles.guidata.togglebutton_label_behaviors(buttonNum), eventdata, handles);
      return;
    end
  case {'esc','escape'},
    if get(handles.togglebutton_label_unknown,'Value') ~= 0,
      set(handles.togglebutton_label_unknown,'Value',0);
      togglebutton_label_unknown_Callback(handles.togglebutton_label_unknown, eventdata, handles);
    else
      for behaviori = 1:2*handles.data.nbehaviors,
        if isnan(handles.guidata.togglebutton_label_behaviors(behaviori)), continue; end
        if get(handles.guidata.togglebutton_label_behaviors(behaviori),'Value') ~= 0,
          set(handles.guidata.togglebutton_label_behaviors(behaviori),'Value',0);
          togglebutton_label_behavior1_Callback(handles.guidata.togglebutton_label_behaviors(behaviori), eventdata, handles);
        end
      end
    end
    
end
return


% --------------------------------------------------------------------
function menu_go_next_frame_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_next_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;
t = min(max(handles.data.GetMinFirstFrame,handles.guidata.ts(axesi)+1),handles.data.GetMaxEndFrame);%handles.guidata.nframes);
% set current frame
SetCurrentFrame(handles,axesi,t,hObject);
return


% --------------------------------------------------------------------
function menu_go_previous_frame_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_previous_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;
t = min(max(handles.data.GetMinFirstFrame,handles.guidata.ts(axesi)-1),handles.data.GetMaxEndFrame);
% set current frame
SetCurrentFrame(handles,axesi,t,hObject);
return


% --------------------------------------------------------------------
function menu_go_forward_several_frames_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_forward_several_frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;
% TODO: hardcoded in 10 as up/down arrow step
t = min(max(handles.data.GetMinFirstFrame,handles.guidata.ts(axesi)+handles.guidata.nframes_jump_go),handles.data.GetMaxEndFrame);%nframes);
% set current frame
SetCurrentFrame(handles,axesi,t,hObject);
return


% --------------------------------------------------------------------
function menu_go_back_several_frames_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_back_several_frames (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;
% TODO: hardcoded in 10 as up/down arrow step
t = min(max(handles.data.GetMinFirstFrame,handles.guidata.ts(axesi)-handles.guidata.nframes_jump_go),handles.data.GetMaxEndFrame);%nframes);
% set current frame
SetCurrentFrame(handles,axesi,t,hObject);
return


% --------------------------------------------------------------------
function menu_go_next_manual_bout_start_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_next_manual_bout_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;

t = handles.guidata.NJObj.Manual_bout_start(handles.data,handles.data.expi,handles.data.flies,...
  handles.guidata.ts(axesi),handles.data.t0_curr,handles.data.t1_curr);
if isempty(t); return; end

SetCurrentFrame(handles,axesi,t,hObject);
return


% --------------------------------------------------------------------
function menu_go_previous_manual_bout_end_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_previous_manual_bout_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;

t = handles.guidata.NJObj.Manual_bout_end(handles.data,handles.data.expi,handles.data.flies,...
  handles.guidata.ts(axesi),handles.data.t0_curr,handles.data.t1_curr);
if isempty(t); return; end

SetCurrentFrame(handles,axesi,t,hObject);
return


% --------------------------------------------------------------------
function menu_go_navigation_preferences_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_navigation_preferences (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'figure_NavigationPreferences') && ishandle(handles.figure_NavigationPreferences),
  figure(handles.figure_NavigationPreferences);
else
  handles.figure_NavigationPreferences = NavigationPreferences(handles.figure_JLabel,handles.guidata.NJObj);
  handles.guidata.open_peripherals(end+1) = handles.figure_NavigationPreferences;
  guidata(hObject,handles);
end
return


% --------------------------------------------------------------------
function menu_edit_label_shortcuts_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_label_shortcuts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prompts  = {};
allShortcuts = handles.guidata.label_shortcuts;
curShortcuts = {};
tprompts = {};
for j = 1:2*handles.data.nbehaviors
    
  labelStr = handles.data.labelnames{ceil(j/2)};
  if mod(j,2), 
    labelStr = ['Important ' labelStr];  %#ok
  end
  tprompts{end+1} = labelStr;  %#ok
  
  if ~handles.guidata.GUIAdvancedMode && ~mod(j,2); continue; end
  % Don't show unimportant keys for Normal mode.
  labelStr = handles.data.labelnames{ceil(j/2)};
  if handles.guidata.GUIAdvancedMode && mod(j,2), 
    labelStr = ['Important ' labelStr];  %#ok
  end
  prompts{end+1} = labelStr;  %#ok
  curShortcuts{end+1} = allShortcuts{j};  %#ok
end
prompts{end+1} = 'Unknown';
tprompts{end+1} = 'Unknown';
curShortcuts{end+1} = allShortcuts{end};
sh = inputdlg(prompts,'Label Shortcuts',1,curShortcuts);
if isempty(sh),
  return;
end

curshortcuts = allShortcuts;
if ~handles.guidata.GUIAdvancedMode
  curshortcuts(1:2:2*handles.data.nbehaviors)= sh(1:handles.data.nbehaviors);
  curshortcuts(2*handles.data.nbehaviors+1)= sh(handles.data.nbehaviors+1);
else
  curshortcuts = sh;
end
[uniquekeys,~,~] = unique(curshortcuts);
nbeh = handles.data.nbehaviors;
if numel(uniquekeys)~= 2*nbeh+1
  overlap = [];
  for ndx = 1:2*nbeh+1
    nb = find(strcmp(curshortcuts{ndx},curshortcuts));
    if numel(nb) > 1,
      overlap = [overlap ', ' tprompts{ndx} ':' curshortcuts{ndx}];  %#ok
    end
  end
  overlap = overlap(3:end);
  uiwait(warndlg(sprintf(...
      'Some short cut keys are assigned to multiple behaviors:%s',overlap))); 
  return;
end

if ~handles.guidata.GUIAdvancedMode
  handles.guidata.label_shortcuts(1:2:2*handles.data.nbehaviors)= sh(1:handles.data.nbehaviors);
  handles.guidata.label_shortcuts(2*handles.data.nbehaviors+1)= sh(handles.data.nbehaviors+1);
else
  handles.guidata.label_shortcuts = sh;
end
guidata(hObject,handles);
return


% -------------------------------------------------------------------------
% --- Executes when figure_JLabel is resized.
function figure_JLabel_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles,'guidata') || ~isfield(handles.guidata.guipos,'leftborder_leftpanels'),
  return;
end

originalUnits=get(handles.figure_JLabel,'units');
set(handles.figure_JLabel,'Units','pixels');
figpos = get(handles.figure_JLabel,'Position');
set(handles.figure_JLabel,'Units',originalUnits);

minh = 700;
minw = 500;
if figpos(3) < minw || figpos(4) < minh,
  figpos(3:4) = max(figpos(3:4),[minw,minh]);
  set(handles.figure_JLabel,'Position',figpos);
end

updatePanelPositions(handles);

return


% -------------------------------------------------------------------------
function handles = updatePanelPositions(handles)
% Update the position and visibility of the labelbuttons, select, learn, 
% similar, and selection info panels based on the current mode.

originalUnits=get(handles.figure_JLabel,'units');
set(handles.figure_JLabel,'Units','pixels');
figpos = get(handles.figure_JLabel,'Position');
set(handles.figure_JLabel,'Units',originalUnits);

labelbuttons_pos = get(handles.panel_labelbuttons,'Position');
select_pos = get(handles.panel_select,'Position');
learn_pos = get(handles.panel_learn,'Position');
similar_pos = get(handles.panel_similar,'Position');
info_pos = get(handles.panel_selection_info,'Position');

width_leftpanels = figpos(3) - handles.guidata.guipos.leftborder_leftpanels - ...
  handles.guidata.guipos.leftborder_rightpanels - handles.guidata.guipos.width_rightpanels - ...
  handles.guidata.guipos.rightborder_rightpanels;
h = figpos(4) - handles.guidata.guipos.bottomborder_bottompanels - ...
  handles.guidata.guipos.topborder_toppanels - handles.guidata.guipos.bottomborder_previewpanels;
height_timelines = h*handles.guidata.guipos.frac_height_timelines;
height_previews = h - height_timelines;
timelines_pos = [handles.guidata.guipos.leftborder_leftpanels,handles.guidata.guipos.bottomborder_bottompanels,...
  width_leftpanels,height_timelines];
set(handles.panel_timelines,'Position',timelines_pos);
% TODO: deal with multiple preview panels
preview_pos = [handles.guidata.guipos.leftborder_leftpanels,...
  figpos(4) - handles.guidata.guipos.topborder_toppanels - height_previews,...
  width_leftpanels,height_previews];
set(handles.guidata.panel_previews(1),'Position',preview_pos);

label_pos = [figpos(3) - labelbuttons_pos(3) - handles.guidata.guipos.rightborder_rightpanels,...
  figpos(4) - labelbuttons_pos(4) - handles.guidata.guipos.topborder_toppanels,...
  labelbuttons_pos(3:4)];
set(handles.panel_labelbuttons,'Position',label_pos);

dy_label_select = labelbuttons_pos(2) - select_pos(2) - select_pos(4);
new_select_pos = [figpos(3) - select_pos(3) - handles.guidata.guipos.rightborder_rightpanels,...
  label_pos(2) - select_pos(4) - dy_label_select,...
  select_pos(3:4)];
set(handles.panel_select,'Position',new_select_pos);

% %dy_label_select = labelbuttons_pos(2) - select_pos(2) - select_pos(4);
% if ~handles.guidata.GUIAdvancedMode || ...
%     ( isnonempty(handles.data) && ...
%       handles.data.IsGTMode() ) ,
if ~handles.guidata.GUIAdvancedMode || ...
    ( handles.data.thereIsAnOpenFile && handles.data.IsGTMode() ) ,
  set(handles.panel_similar,'Visible','off');
  new_info_pos = [figpos(3) - info_pos(3) - handles.guidata.guipos.rightborder_rightpanels,...
    new_select_pos(2) - info_pos(4) - dy_label_select,...
    info_pos(3:4)];
  set(handles.panel_selection_info,'Position',new_info_pos);
else
  new_similar_pos = [figpos(3) - similar_pos(3) - handles.guidata.guipos.rightborder_rightpanels,...
    new_select_pos(2) - similar_pos(4) - dy_label_select,...
    similar_pos(3:4)];
  set(handles.panel_similar,'Position',new_similar_pos,'Visible','on');
  new_info_pos = [figpos(3) - info_pos(3) - handles.guidata.guipos.rightborder_rightpanels,...
    new_similar_pos(2) - info_pos(4) - dy_label_select,...
    info_pos(3:4)];
  set(handles.panel_selection_info,'Position',new_info_pos);
end


new_learn_pos = [figpos(3) - learn_pos(3) - handles.guidata.guipos.rightborder_rightpanels,...
  handles.guidata.guipos.bottomborder_bottompanels,...
  learn_pos(3:4)];
set(handles.panel_learn,'Position',...
  new_learn_pos);





return


% % -------------------------------------------------------------------------
% function handles = StoreGUIPositionsInternally(handles)
% 
% figpos = get(handles.figure_JLabel,'Position');
% panel_labelbuttons_pos = get(handles.panel_labelbuttons,'Position');
% % panel_learn_pos = get(handles.panel_learn,'Position');
% panel_timelines_pos = get(handles.panel_timelines,'Position');
% panel_previews_pos = cell(size(handles.guidata.panel_previews));
% for i = 1:numel(handles.guidata.panel_previews),
%   panel_previews_pos{i} = get(handles.guidata.panel_previews(i),'Position');
% end
% handles.guidata.guipos.width_rightpanels = panel_labelbuttons_pos(3);
% handles.guidata.guipos.rightborder_rightpanels = figpos(3) - (panel_labelbuttons_pos(1) + panel_labelbuttons_pos(3));
% handles.guidata.guipos.leftborder_leftpanels = panel_timelines_pos(1);
% handles.guidata.guipos.leftborder_rightpanels = panel_labelbuttons_pos(1) - (panel_timelines_pos(1) + panel_timelines_pos(3));
% handles.guidata.guipos.topborder_toppanels = figureHeight - (panel_labelbuttons_pos(2) + panel_labelbuttons_pos(4));
% if handles.guidata.guipos.topborder_toppanels < 0
%   handles.guidata.guipos.topborder_toppanels = 15;
% end
% handles.guidata.guipos.bottomborder_bottompanels = panel_timelines_pos(2);
% handles.guidata.guipos.bottomborder_previewpanels = panel_previews_pos{end}(2) - (panel_timelines_pos(2)+panel_timelines_pos(4));
% handles.guidata.guipos.frac_height_timelines = panel_timelines_pos(4) / (panel_timelines_pos(4) + panel_previews_pos{1}(4));
% 
% handles.guidata.guipos.timeline_bottom_borders = nan(1,numel(handles.guidata.axes_timelines));
% handles.guidata.guipos.timeline_left_borders = nan(1,numel(handles.guidata.axes_timelines));
% handles.guidata.guipos.timeline_label_middle_offsets = nan(1,numel(handles.guidata.axes_timelines));
% pos0 = get(handles.guidata.axes_timelines(1),'Position');
% handles.guidata.guipos.timeline_bottom_borders(1) = pos0(2);
% handles.guidata.guipos.timeline_heights(1) = pos0(4);
% handles.guidata.guipos.timeline_xpos = pos0(1);
% handles.guidata.guipos.timeline_rightborder = panel_timelines_pos(3) - pos0(1) - pos0(3);
% for i = 2:numel(handles.guidata.axes_timelines),
%   pos1 = get(handles.guidata.axes_timelines(i),'Position');
%   handles.guidata.guipos.timeline_bottom_borders(i) = pos1(2) - pos0(2) - pos0(4);
%   handles.guidata.guipos.timeline_heights(i) = pos1(4);
%   pos0 = pos1;
% end
% handles.guidata.guipos.timeline_top_border = panel_timelines_pos(4) - pos1(2) - pos1(4);
% handles.guidata.guipos.timeline_heights = handles.guidata.guipos.timeline_heights / sum(handles.guidata.guipos.timeline_heights);
% for i = 1:numel(handles.guidata.axes_timelines),
%   ax_pos = get(handles.guidata.axes_timelines(i),'Position');
%   label_pos = get(handles.guidata.labels_timelines(i),'Position');
%   handles.guidata.guipos.timeline_left_borders(i) = label_pos(1);
%   m = ax_pos(2) + ax_pos(4)/2;
%   handles.guidata.guipos.timeline_label_middle_offsets(i) = label_pos(2)-m;
% end
% ax_pos = get(handles.axes_timeline_prop1,'Position');
% handles.guidata.guipos.timeline_prop_height = ax_pos(4);
% pos = get(handles.timeline_label_prop1,'Position');
% handles.guidata.guipos.timeline_prop_label_left_border = pos(1);
% handles.guidata.guipos.timeline_prop_label_size = pos(3:4);
% handles.guidata.guipos.timeline_prop_label_callback = get(handles.timeline_label_prop1,'Callback');
% handles.guidata.guipos.timeline_prop_fontsize = get(handles.timeline_label_prop1,'FontSize');
% m = ax_pos(2) + ax_pos(4)/2;
% handles.guidata.guipos.timeline_prop_label_middle_offset = pos(2)-m;
% 
% pos = get(handles.text_timeline_prop1,'Position');
% handles.guidata.guipos.text_timeline_prop_right_border = ax_pos(1) - pos(1) - pos(3);
% handles.guidata.guipos.text_timeline_prop_size = pos(3:4);
% handles.guidata.guipos.text_timeline_prop_middle_offset = pos(2)-m;
% handles.guidata.guipos.text_timeline_prop_fontsize = get(handles.text_timeline_prop1,'FontSize');
% handles.guidata.guipos.text_timeline_prop_bgcolor = get(handles.text_timeline_prop1,'BackgroundColor');
% handles.guidata.guipos.text_timeline_prop_fgcolor = get(handles.text_timeline_prop1,'ForegroundColor');
% 
% axes_pos = get(handles.axes_preview,'Position');
% slider_pos = get(handles.slider_preview,'Position');
% edit_pos = get(handles.edit_framenumber,'Position');
% play_pos = get(handles.pushbutton_playstop,'Position');
% handles.guidata.guipos.preview_axes_top_border = panel_previews_pos{end}(4) - axes_pos(4) - axes_pos(2);
% handles.guidata.guipos.preview_axes_bottom_border = axes_pos(2);
% handles.guidata.guipos.preview_axes_left_border = axes_pos(1);
% handles.guidata.guipos.preview_axes_right_border = panel_previews_pos{end}(3) - axes_pos(1) - axes_pos(3);
% handles.guidata.guipos.preview_slider_left_border = slider_pos(1);
% handles.guidata.guipos.preview_slider_right_border = panel_previews_pos{end}(3) - slider_pos(1) - slider_pos(3);
% handles.guidata.guipos.preview_slider_bottom_border = slider_pos(2);
% handles.guidata.guipos.preview_play_left_border = play_pos(1) - slider_pos(1) - slider_pos(3);
% handles.guidata.guipos.preview_play_bottom_border = play_pos(2);
% handles.guidata.guipos.preview_edit_left_border = edit_pos(1) - play_pos(1) - play_pos(3);
% handles.guidata.guipos.preview_edit_bottom_border = edit_pos(2);
% 
% return


% -------------------------------------------------------------------------
% --- Executes when panel_timelines is resized.
function panel_timelines_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to panel_timelines (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.guidata.axes_timelines),
  return;
end
panel_pos = get(handles.panel_timelines,'Position');

ntimelines = numel(handles.guidata.axes_timelines);
h = panel_pos(4) - sum(handles.guidata.guipos.timeline_bottom_borders) - handles.guidata.guipos.timeline_top_border;
w = panel_pos(3) - handles.guidata.guipos.timeline_rightborder - handles.guidata.guipos.timeline_xpos;

y0 = 0;
for i = 1:ntimelines,
  y0 = y0 + handles.guidata.guipos.timeline_bottom_borders(i);
  axes_pos = [handles.guidata.guipos.timeline_xpos,y0,w,h*handles.guidata.guipos.timeline_heights(i)];
  m = axes_pos(2) + axes_pos(4)/2;
  set(handles.guidata.axes_timelines(i),'Position',axes_pos);
  label_pos = get(handles.guidata.labels_timelines(i),'Position');
  new_label_pos = [handles.guidata.guipos.timeline_left_borders(i),...
    m+handles.guidata.guipos.timeline_label_middle_offsets(i),...
    label_pos(3:4)];
  set(handles.guidata.labels_timelines(i),'Position',new_label_pos);
  if ishandle(handles.guidata.text_timelines(i)),
    new_text_pos = [axes_pos(1)-handles.guidata.guipos.text_timeline_prop_right_border-handles.guidata.guipos.text_timeline_prop_size(1),...
      m+handles.guidata.guipos.text_timeline_prop_middle_offset,...
      handles.guidata.guipos.text_timeline_prop_size];
    set(handles.guidata.text_timelines(i),'Position',new_text_pos);
  end
  y0 = y0 + axes_pos(4);
end

% Position for the auto and manual radio buttons.
timeline_select_pos = get(handles.panel_timeline_select,'Position');
timeline_manual_pos = get(handles.guidata.axes_timelines(end),'Position');
timeline_auto_pos = get(handles.guidata.axes_timelines(end-1),'Position');
timeline_select_pos(2) = timeline_auto_pos(2);
timeline_select_pos(4) = timeline_manual_pos(2)-timeline_auto_pos(2)+...
                            timeline_manual_pos(4);
set(handles.panel_timeline_select,'Position',timeline_select_pos);

auto_radio_pos = get(handles.timeline_label_automatic,'Position');
manual_radio_pos = get(handles.timeline_label_manual,'Position');
auto_radio_pos(2) = timeline_auto_pos(4)/2-auto_radio_pos(4)/2;
set(handles.timeline_label_automatic,'Position',auto_radio_pos);
manual_radio_pos(2) = timeline_select_pos(4)-auto_radio_pos(2)...
  -manual_radio_pos(4);
set(handles.timeline_label_manual,'Position',manual_radio_pos);


% Positions of the automatic timeline's labels
labelPredictionPos = get(handles.automaticTimelinePredictionLabel,'Position');
labelScoresPos =     get(handles.automaticTimelineScoresLabel,'Position');
popupBottomPos =     get(handles.automaticTimelineBottomRowPopup,'Position');
popupBottomPos(2) = timeline_auto_pos(2) + ...
  timeline_auto_pos(4)/6 - popupBottomPos(4)/2;
set(handles.automaticTimelineBottomRowPopup,'Position',popupBottomPos);
labelScoresPos(2) = timeline_auto_pos(2) + ...
  timeline_auto_pos(4)/2 - labelScoresPos(4)/2;
set(handles.automaticTimelineScoresLabel,'Position',labelScoresPos);
labelPredictionPos(2) = timeline_auto_pos(2) + ...
  5*timeline_auto_pos(4)/6 - labelPredictionPos(4)/2;
set(handles.automaticTimelinePredictionLabel,'Position',labelPredictionPos);

% Scores text position
scores_pos = get(handles.text_scores,'Position');
scores_pos(2) = popupBottomPos(2);
scores_pos(1) = auto_radio_pos(1)+auto_radio_pos(3)/2-scores_pos(3)/2;
set(handles.text_scores,'Position',scores_pos);


%{
% axes_manual_pos = [handles.guidata.guipos.timeline_xpos,...
%   panel_pos(4)-handles.guidata.guipos.timeline_bordery-h,w,h];
% set(handles.axes_timeline_manual,'Position',axes_manual_pos);  
% 
% axes_auto_pos = [handles.guidata.guipos.timeline_xpos,...
%   axes_manual_pos(2)-handles.guidata.guipos.timeline_bordery-h,w,h];
% set(handles.axes_timeline_auto,'Position',axes_auto_pos);  
% 
% text_manual_pos = get(handles.timeline_label_manual,'Position');
% m = axes_manual_pos(2) + axes_manual_pos(4)/2;
% new_text_manual_pos = [text_manual_pos(1),m - text_manual_pos(4)/2,...
%   text_manual_pos(3:4)];
% set(handles.timeline_label_manual,'Position',new_text_manual_pos);
% 
% text_auto_pos = get(handles.timeline_label_automatic,'Position');
% m = axes_auto_pos(2) + axes_auto_pos(4)/2;
% new_text_auto_pos = [text_auto_pos(1),m - text_auto_pos(4)/2,...
%   text_auto_pos(3:4)];
% set(handles.timeline_label_automatic,'Position',new_text_auto_pos);
%}
return


% -------------------------------------------------------------------------
% --- Executes when panel_axes1 is resized.
function panel_axes1_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to panel_axes1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.guidata.panel_previews),
  return;
end
previewi = find(handles.guidata.panel_previews==hObject,1);
if isempty(previewi), 
  return;
end

panel_pos = get(handles.guidata.panel_previews(previewi),'Position');

axes_pos = [handles.guidata.guipos.preview_axes_left_border,...
  handles.guidata.guipos.preview_axes_bottom_border,...
  panel_pos(3) - handles.guidata.guipos.preview_axes_left_border - handles.guidata.guipos.preview_axes_right_border,...
  panel_pos(4) - handles.guidata.guipos.preview_axes_top_border - handles.guidata.guipos.preview_axes_bottom_border];
set(handles.guidata.axes_previews(previewi),'Position',axes_pos);
[handles] = UpdateZoomFlyRadius(handles,previewi);

slider_pos = get(handles.guidata.slider_previews(previewi),'Position');
new_slider_pos = [handles.guidata.guipos.preview_slider_left_border,...
  handles.guidata.guipos.preview_slider_bottom_border,...
  panel_pos(3) - handles.guidata.guipos.preview_slider_left_border - handles.guidata.guipos.preview_slider_right_border,...
  slider_pos(4)];
set(handles.guidata.slider_previews(previewi),'Position',new_slider_pos);

play_pos = get(handles.guidata.pushbutton_playstops(previewi),'Position');
new_play_pos = [new_slider_pos(1) + new_slider_pos(3) + handles.guidata.guipos.preview_play_left_border,...
  handles.guidata.guipos.preview_play_bottom_border,play_pos(3:4)];
set(handles.guidata.pushbutton_playstops(previewi),'Position',new_play_pos);


edit_pos = get(handles.guidata.edit_framenumbers(previewi),'Position');
new_edit_pos = [new_play_pos(1) + new_play_pos(3) + handles.guidata.guipos.preview_edit_left_border,...
  handles.guidata.guipos.preview_edit_bottom_border,edit_pos(3:4)];
set(handles.guidata.edit_framenumbers(previewi),'Position',new_edit_pos);
return

function [handles] = UpdateZoomFlyRadius(handles,previewi,ignorecurr)

if nargin < 3,
  ignorecurr = false;
end

axes_pos = get(handles.guidata.axes_previews(previewi),'Position');

if ignorecurr,
  rxcurr = 0;
  rycurr = 0;
else
  ax = axis(handles.guidata.axes_previews(previewi));
  dx = ax(2)-ax(1);
  dy = ax(4)-ax(3);
  rxcurr = (dx-1)/2;
  rycurr = (dy-1)/2;
end

max_ry = max(rycurr,min(handles.guidata.zoom_fly_radius(1) * axes_pos(4) / axes_pos(3),handles.guidata.movie_height/2));
max_rx = max(rxcurr,min(handles.guidata.zoom_fly_radius(2) * axes_pos(3) / axes_pos(4),handles.guidata.movie_width/2));
ischange = false;
if max_ry - handles.guidata.zoom_fly_radius(2) >= 1,
  handles.guidata.zoom_fly_radius(2) = max_ry;
  ischange = true;
elseif max_rx - handles.guidata.zoom_fly_radius(1) >= 1,
  handles.guidata.zoom_fly_radius(1) = max_rx;
  ischange = true;
end
if max_ry - rycurr >= 1 || max_rx - rxcurr >= 1,
  ischange = true;
end
if ischange,
  guidata(handles.figure_JLabel,handles);
  if strcmpi(handles.guidata.preview_zoom_mode,'center_on_fly'),
    ZoomInOnFlies(handles,previewi);
  elseif strcmpi(handles.guidata.preview_zoom_mode,'follow_fly'),
    KeepFliesInView(handles,previewi,true);
  end
end



% --------------------------------------------------------------------
function menu_view_preview_options_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_preview_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prompts = {'Playback Speed (fps):',...
  'N. previous positions plotted:','N. future positions plotted:'};

while true,
  defaults = {num2str(handles.guidata.play_FPS),...
    num2str(handles.guidata.traj_nprev),num2str(handles.guidata.traj_npost)};
  res = inputdlg(prompts,'Preview Options',1,defaults);
  if isempty(res), return, end;
  errs = {};
  play_FPS = str2double(res{1});
  if isnan(play_FPS) || play_FPS <= 0,
    errs{end+1} = 'Playback speed must be a positive number'; %#ok<AGROW>
  else
    handles.guidata.play_FPS = play_FPS;
  end
  
  traj_nprev = str2double(res{2});
  if isnan(traj_nprev) || traj_nprev < 0 || rem(traj_nprev,1) ~= 0,
    errs{end+1} = 'N. previous positions plotted must be a postive integer'; %#ok<AGROW>
  else
    handles.guidata.traj_nprev = traj_nprev;
  end
  
  traj_npost = str2double(res{3});
  if isnan(traj_npost) || traj_npost < 0 || rem(traj_npost,1) ~= 0,
    errs{end+1} = 'N. future positions plotted must be a postive integer'; %#ok<AGROW>
  else
    handles.guidata.traj_npost = traj_npost;
  end
  
  if isempty(errs),
    break;
  else
    uiwait(warndlg(errs,'Bad preview options'));
  end
  
end
guidata(hObject,handles);
UpdatePlots(handles,...
  'refreshim',false,'refreshflies',false,'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',true,...
     'refresh_timeline_auto',false,...
     'refresh_timeline_suggest',false,...
     'refresh_timeline_error',true,...
     'refresh_timeline_xlim',false,...
     'refresh_timeline_hcurr',false,...
     'refresh_timeline_props',false,...
     'refresh_timeline_selection',false,...
     'refresh_curr_prop',false);
return

   
% -------------------------------------------------------------------------
% --- Executes on button press in pushbutton_add_timeline.
function pushbutton_add_timeline_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_add_timeline (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

AddPropAxes(handles);
return


% -------------------------------------------------------------------------
% --- Executes on selection change in timeline_label_prop1.
function timeline_label_prop1_Callback(hObject, eventdata, handles)
% hObject    handle to timeline_label_prop1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns timeline_label_prop1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from timeline_label_prop1
propi = GetTimelinePropNumber(hObject,handles);
v = get(hObject,'Value');
s = handles.guidata.timeline_prop_options{v};
if strcmpi(s,handles.guidata.timeline_prop_remove_string),
  RemovePropAxes(handles,propi);
elseif strcmpi(s,handles.guidata.timeline_prop_help_string),
  % do nothing
else
  prop = find(strcmpi(s,handles.data.allperframefns),1);
  handles.guidata.perframepropis(propi) = prop;
  handles.perframeprops{propi} = s;
  [perframedata,T0,T1] = handles.data.GetPerFrameData(handles.data.expi,handles.data.flies,prop);
  set(handles.guidata.htimeline_data(propi),'XData',T0:T1,'YData',perframedata);
  ylim = [min(perframedata),max(perframedata)];
  if ylim(1) >= ylim(2)
    ylim(2) = ylim(1)+0.001;
  end
  set(handles.guidata.axes_timeline_props(propi),'YLim',ylim);
  zoom(handles.guidata.axes_timeline_props(propi),'reset');
  if ~isnan(handles.guidata.timeline_data_ylims(1,prop)),
    ylim = handles.guidata.timeline_data_ylims(:,prop);
    set(handles.guidata.axes_timeline_props(propi),'YLim',ylim);
  end
  ydata = [ylim(1)+diff(ylim)*.025,ylim(2)-diff(ylim)*.025];
  set(handles.guidata.hselection(propi),'YData',ydata([1,2,2,1,1]));
  s='NaN';
  if(((handles.guidata.ts(1)-T0+1)>0) && ((handles.guidata.ts(1)-T0+1)<length(perframedata)))
    s = sprintf('%.3f',perframedata(handles.guidata.ts(1)-T0+1));
  end
  set(handles.guidata.text_timeline_props(propi),'String',s);
  
  idx=find(strncmp('spacetime',handles.data.allperframefns(handles.guidata.perframepropis),9));
  if ~isempty(idx)
    if (~isfield(handles,'spacetime'))
      [tmp{1:length(handles.data.trx)}]=deal(handles.data.trx(:).a);
      handles.spacetime.meana = prctile(cellfun(@nanmean,tmp),90);
      [tmp{1:length(handles.data.trx)}]=deal(handles.data.trx(:).b);
      handles.spacetime.meanb = prctile(cellfun(@nanmean,tmp),90);
      [handles.spacetime.binidx, handles.spacetime.nbins, ...
          handles.spacetime.featurenames, handles.spacetime.featureboundaries, handles.spacetime.featurecenters] = ...
          compute_spacetime_mask(handles.spacetime.meana, handles.spacetime.meanb);
      find(cellfun(@(x) strncmp('spacetime_',x,10),handles.data.allperframefns));
      prctile([handles.data.perframedata{ans}],[1 99]);
      handles.spacetime.prc1=ans(1);
      handles.spacetime.prc99=ans(2);
    end
    tmp=nan(1,length(idx));
    for i=1:length(idx)
      foo=handles.data.allperframefns{handles.guidata.perframepropis(idx(i))}(11:end);
      if (length(foo)>11) && strcmp(foo(end-10:end),'_difference')
        bar=regexp(foo,'t(\d+)_r','tokens','once');  bar=bar{1};
        if((str2num(bar(1))+str2num(bar(2)))==10)
          foo=['t' bar(1) '_r1'];
        else
          foo=['t' bar(1) '_r1_overlap'];
        end
      end
      tmp(i)=1;
      while(tmp(i)<length(handles.spacetime.featurenames)) && ...
            isempty(find(strcmp(handles.spacetime.featurenames{tmp(i)}, foo)))
        tmp(i) = tmp(i)+1;
      end
    end
    handles.spacetime.mask=unique(tmp);
    if (~isfield(handles.spacetime,'fig'))
      handles.spacetime.fig=[];
    end
    tmp=length(handles.spacetime.mask)-length(handles.spacetime.fig);
    if tmp>0
      handles.spacetime.fig=[handles.spacetime.fig nan(1,tmp)];
      for i=1:length(handles.spacetime.mask)
        if (~ishandle(handles.spacetime.fig(i)))
          handles.spacetime.fig(i)=figure('position',...
              [0 0 10*size(handles.spacetime.binidx{1},2) 10*size(handles.spacetime.binidx{1},1)],...
              'UserData',hObject,...
              'KeyPressFcn',get(handles.figure_JLabel,'KeyPressFcn'));
          handles.spacetime.ax(i)=axes('position',[0 0 1 1],'parent',handles.spacetime.fig(i));
        end
      end
    end
    if tmp<0
      close(handles.spacetime.fig(length(handles.spacetime.mask)+1:end));
      handles.spacetime.fig=handles.spacetime.fig(1:length(handles.spacetime.mask));
      handles.spacetime.ax=handles.spacetime.ax(1:length(handles.spacetime.mask));
    end
  else
    if isfield(handles,'spacetime')
      close(handles.spacetime.fig);
      handles=rmfield(handles,'spacetime');
    end
  end

  guidata(hObject,handles);
end
return


% -------------------------------------------------------------------------
function i = GetTimelinePropNumber(hObject,handles)

t = get(hObject,'Type');
if strcmpi(t,'axes'),
  i = find(hObject == handles.guidata.axes_timeline_props,1);
elseif strcmpi(t,'uicontrol'),
  s = get(hObject,'Style');
  if strcmpi(s,'popupmenu'),
    j = find(hObject == handles.guidata.labels_timelines,1);
    if isempty(j),
      i = [];
    else
      i = find(handles.guidata.axes_timelines(j) == handles.guidata.axes_timeline_props,1);
    end
  else
    i = [];
  end
else
  i = [];
end
if isempty(i),
  warning('Could not find index of parent panel');
  i = 1;
end
return


% -------------------------------------------------------------------------
function handles = RemovePropAxes(handles,propi)

% which axes
axi = find(handles.guidata.axes_timelines == handles.guidata.axes_timeline_props(propi));

% how much height we will remove
axes_pos = get(handles.guidata.axes_timeline_props(propi),'Position');
hremove = axes_pos(4) + handles.guidata.guipos.timeline_bottom_borders(axi+1);

% set the sizes of the other axes to stretch
Z0 = sum(handles.guidata.guipos.timeline_heights);
Z1 = Z0 - handles.guidata.guipos.timeline_heights(axi);
handles.guidata.guipos.timeline_heights = handles.guidata.guipos.timeline_heights * Z0 / Z1;

% delete the axes
delete(handles.guidata.axes_timeline_props(propi));
delete(handles.guidata.labels_timelines(axi));
if ishandle(handles.guidata.text_timelines(axi)),
  delete(handles.guidata.text_timelines(axi));
end
handles.guidata.axes_timeline_props(propi) = [];
handles.guidata.axes_timelines(axi) = [];
handles.guidata.labels_timelines(axi) = [];
handles.guidata.text_timelines(axi) = [];
handles.guidata.text_timeline_props(propi) = [];
handles.guidata.htimeline_data(propi) = [];
handles.guidata.hcurr_timelines(axi) = [];
handles.guidata.hselection(axi) = [];
handles.guidata.guipos.timeline_bottom_borders(axi+1) = [];
handles.guidata.guipos.timeline_heights(axi) = [];
handles.guidata.guipos.timeline_left_borders(axi) = [];
handles.guidata.guipos.timeline_label_middle_offsets(axi) = [];
% handles.perframepropfns(propi) = [];
handles.guidata.perframepropis(propi) = [];

% show the xticks
set(handles.guidata.axes_timelines(1),'XTickLabelMode','auto');

guidata(handles.figure_JLabel,handles);

% make the panel smaller
panel_timelines_pos = get(handles.panel_timelines,'Position');
panel_timelines_pos(4) = panel_timelines_pos(4) - hremove;
set(handles.panel_timelines,'Position',panel_timelines_pos);

% make the preview panel bigger
panel_previews_pos = get(handles.guidata.panel_previews,'Position');
panel_previews_pos(2) = panel_previews_pos(2) - hremove;
panel_previews_pos(4) = panel_previews_pos(4) + hremove;
set(handles.guidata.panel_previews,'Position',panel_previews_pos);

handles = guidata(handles.figure_JLabel);

handles.guidata.guipos.frac_height_timelines = panel_timelines_pos(4) / (panel_timelines_pos(4) + panel_previews_pos(4));
guidata(handles.figure_JLabel,handles);

idx=find(strncmp('spacetime',handles.data.allperframefns(handles.guidata.perframepropis),9));
if ((isfield(handles,'spacetime')) && (isfield(handles.spacetime,'fig')) && (length(idx)<length(handles.spacetime.fig)))
  tmp=nan(1,length(idx));
  for i=1:length(idx)
    tmp(i)=1;
    while(tmp(i)<length(handles.spacetime.featurenames)) && ...
          isempty(find(strcmp(handles.spacetime.featurenames{tmp(i)}, ...
            handles.data.allperframefns{handles.guidata.perframepropis(idx(i))}(11:end))))
      tmp(i) = tmp(i)+1;
    end
  end
  handles.spacetime.mask=unique(tmp);
  close(handles.spacetime.fig(length(handles.spacetime.mask)+1:end));
  handles.spacetime.fig=handles.spacetime.fig(1:length(handles.spacetime.mask));
  handles.spacetime.ax=handles.spacetime.ax(1:length(handles.spacetime.mask));
  guidata(handles.figure_JLabel,handles);
end

return


% -------------------------------------------------------------------------
function handles = AddPropAxes(handles,prop)

% choose a property
if nargin < 2,
  prop = find(~ismember(1:numel(handles.data.allperframefns),handles.guidata.perframepropis),1);
  if isempty(prop),
    prop = 1;
  end
end
propi = numel(handles.guidata.axes_timeline_props)+1;
% how much height we will add
hadd = handles.guidata.guipos.timeline_prop_height + handles.guidata.guipos.timeline_bottom_borders(2);

% make the preview panel smaller
panel_previews_pos = get(handles.guidata.panel_previews,'Position');
panel_previews_pos(2) = panel_previews_pos(2) + hadd;
panel_previews_pos(4) = panel_previews_pos(4) - hadd;

axes_pos = [handles.guidata.guipos.preview_axes_left_border,...
  handles.guidata.guipos.preview_axes_bottom_border,...
  panel_previews_pos(3) - handles.guidata.guipos.preview_axes_left_border - handles.guidata.guipos.preview_axes_right_border,...
  panel_previews_pos(4) - handles.guidata.guipos.preview_axes_top_border - handles.guidata.guipos.preview_axes_bottom_border];

if any(axes_pos<0),
  uiwait(warndlg('Not enough space to add another timeline'));
  return;
end

% set the sizes of the other axes to shrink
panel_pos = get(handles.panel_timelines,'Position');
Z0 = panel_pos(4) - sum(handles.guidata.guipos.timeline_bottom_borders) - handles.guidata.guipos.timeline_top_border;
Z1 = Z0 + hadd;
handles.guidata.guipos.timeline_heights = handles.guidata.guipos.timeline_heights * Z0 / Z1;

% add the axes
w = panel_pos(3) - handles.guidata.guipos.timeline_rightborder - handles.guidata.guipos.timeline_xpos;
ax_pos = [handles.guidata.guipos.timeline_xpos,handles.guidata.guipos.timeline_bottom_borders(1),...
  w,handles.guidata.guipos.timeline_prop_height];
hax = axes('Parent',handles.panel_timelines,'Units','pixels',...
  'Position',ax_pos,'XColor','w','YColor','w',...
  'Color',get(handles.panel_timelines,'BackgroundColor'),...
  'Tag',sprintf('timeline_axes_prop%d',propi));
handles.guidata.axes_timeline_props = [hax,handles.guidata.axes_timeline_props];
handles.guidata.axes_timelines = [hax,handles.guidata.axes_timelines];
% fcn = get(handles.guidata.axes_timelines(1),'ButtonDownFcn');
% set(hax,'ButtonDownFcn',fcn);
setAxesZoomMotion(handles.guidata.hzoom,hax,'vertical');
%hold(hax,'on');
[perframedata,T0,T1] = handles.data.GetPerFrameData(handles.data.expi,handles.data.flies,prop);
maxylim = [min(perframedata),max(perframedata)];
% hdata = plot(T0:T1,perframedata,'w.-');
hdata = line('parent',gca, ...
             'xdata',T0:T1, ...
             'ydata',perframedata, ...
             'color','w', ...
             'marker','.', ...
             'linestyle','-');
handles.guidata.htimeline_data = [hdata,handles.guidata.htimeline_data];
xlim = get(handles.guidata.axes_timelines(2),'XLim');
if isnan(handles.guidata.timeline_data_ylims(1,prop)),
  ylim = maxylim;
else
  ylim = handles.guidata.timeline_data_ylims(:,prop)';
end
set(hax,'XLim',xlim,'YLim',ylim);
zoom(hax,'reset');
%hcurr = plot(hax,[0,0]+handles.guidata.ts(1),[-10^6,10^6],'y-','HitTest','off','linewidth',2);
hcurr = line('parent',hax, ...
             'xdata',[0,0]+handles.guidata.ts(1), ...
             'ydata',[-10^6,10^6], ...
             'color','y', ...
             'linestyle','-', ...
             'HitTest','off', ...
             'linewidth',2);
handles.guidata.hcurr_timelines = [hcurr,handles.guidata.hcurr_timelines];
ydata = [ylim(1)+diff(ylim)*.025,ylim(2)-diff(ylim)*.025];
% hselection = plot(hax,handles.guidata.selected_ts([1,1,2,2,1]),ydata([1,2,2,1,1]),'--',...
%   'color',handles.guidata.selection_color,...
%   'HitTest','off',...
%   'LineWidth',3);
hselection = ...
  line('parent',hax, ...
       'xdata',handles.guidata.selected_ts([1,1,2,2,1]), ...
       'ydata',ydata([1,2,2,1,1]), ...
       'linestyle','--', ...
       'color',handles.guidata.selection_color, ...
       'HitTest','off', ...
       'LineWidth',3);
handles.guidata.hselection = [hselection,handles.guidata.hselection];
linkaxes(handles.guidata.axes_timelines,'x');

% add the label
m = ax_pos(2)+ax_pos(4)/2; 
pos = [handles.guidata.guipos.timeline_prop_label_left_border,...
  m+handles.guidata.guipos.timeline_prop_label_middle_offset,...
  handles.guidata.guipos.timeline_prop_label_size];
hlabel = uicontrol(handles.panel_timelines,...
  'Style','popupmenu',...
  'Units','pixels',...
  'BackgroundColor',get(handles.guidata.labels_timelines(1),'BackgroundColor'),...
  'ForegroundColor',get(handles.guidata.labels_timelines(1),'ForegroundColor'),...
  'String',handles.guidata.timeline_prop_options,...
  'Value',prop+2,...
  'Position',pos,...
  'FontUnits','pixels',...
  'FontSize',handles.guidata.guipos.timeline_prop_fontsize,...
  'Tag',sprintf('timeline_label_prop%d',propi));
set(hlabel,'Callback',@(hObject,eventdata) timeline_label_prop1_Callback(hObject,eventdata,guidata(hObject)));

handles.guidata.labels_timelines = [hlabel;handles.guidata.labels_timelines];

% add menu_file_open_old_school_files axes sizes
handles.guidata.guipos.timeline_heights = [ax_pos(4) / Z1,handles.guidata.guipos.timeline_heights];
handles.guidata.guipos.timeline_bottom_borders = handles.guidata.guipos.timeline_bottom_borders([1,2,2:numel(handles.guidata.guipos.timeline_bottom_borders)]);
handles.guidata.guipos.timeline_left_borders = [pos(1),handles.guidata.guipos.timeline_left_borders];
handles.guidata.guipos.timeline_label_middle_offsets = [handles.guidata.guipos.timeline_prop_label_middle_offset,handles.guidata.guipos.timeline_label_middle_offsets];
% handles.perframepropfns = [handles.data.allperframefns(prop),handles.perframepropfns];
handles.guidata.perframepropis = [prop,handles.guidata.perframepropis];

% add the text box
pos = [ax_pos(1)-handles.guidata.guipos.text_timeline_prop_right_border-handles.guidata.guipos.text_timeline_prop_size(1),...
  m+handles.guidata.guipos.text_timeline_prop_middle_offset,...
  handles.guidata.guipos.text_timeline_prop_size];
htext = uicontrol(handles.panel_timelines,...
  'Style','text',...
  'Units','pixels',...
  'BackgroundColor',handles.guidata.guipos.text_timeline_prop_bgcolor,...
  'ForegroundColor',handles.guidata.guipos.text_timeline_prop_fgcolor,...
  'String','????????',...
  'Position',pos,...
  'FontUnits','pixels',...
  'FontSize',handles.guidata.guipos.text_timeline_prop_fontsize,...
  'Tag',sprintf('text_timeline_prop%d',propi),...
  'HorizontalAlignment','right');

handles.guidata.text_timeline_props = [htext;handles.guidata.text_timeline_props];
handles.guidata.text_timelines = [htext,handles.guidata.text_timelines];

% hide the xtick labels
set(handles.guidata.axes_timelines(2),'XTickLabel',{});

guidata(handles.figure_JLabel,handles);

% make the panel bigger
panel_timelines_pos = get(handles.panel_timelines,'Position');
panel_timelines_pos(4) = panel_timelines_pos(4) + hadd;
set(handles.panel_timelines,'Position',panel_timelines_pos);


set(handles.guidata.panel_previews,'Position',panel_previews_pos);

handles = guidata(handles.figure_JLabel);

handles.guidata.guipos.frac_height_timelines = panel_timelines_pos(4) / (panel_timelines_pos(4) + panel_previews_pos(4));

guidata(handles.figure_JLabel,handles);

UpdatePlots(handles,...
  'refreshim',false,'refreshflies',false,'refreshtrx',false,'refreshlabels',false,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_auto',false,...
  'refresh_timeline_suggest',false,...
  'refresh_timeline_error',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_props',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',true);
return


% -------------------------------------------------------------------------
function PostZoomCallback(hObject,eventdata,handles)

timelinei = find(eventdata.Axes == handles.guidata.axes_timelines,1);
previewi = find(eventdata.Axes == handles.guidata.axes_previews,1);
if ~isempty(timelinei),
  prop = handles.guidata.perframepropis(timelinei);
  ylim = get(eventdata.Axes,'YLim');
  handles.guidata.timeline_data_ylims(:,prop) = ylim;
  ydata = [ylim(1)+diff(ylim)*.025,ylim(2)-diff(ylim)*.025];
  set(handles.guidata.hselection(timelinei),'YData',ydata([1,2,2,1,1]));
  guidata(eventdata.Axes,handles);
elseif ismember(eventdata.Axes,handles.guidata.axes_timeline_labels),
  xlim = get(eventdata.Axes,'XLim');
  handles.guidata.timeline_nframes = max(1,round(diff(xlim)-1)/2);
  guidata(eventdata.Axes,handles);
elseif ~isempty(previewi),
  xlim = get(eventdata.Axes,'XLim');
  ylim = get(eventdata.Axes,'YLim');
  rx = round((diff(xlim)-1)/2);
  ry = round((diff(ylim)-1)/2);
  axes_pos = get(eventdata.Axes,'Position');
  max_ry = min(rx * axes_pos(4) / axes_pos(3),handles.guidata.movie_height/2);
  max_rx = min(ry * axes_pos(3) / axes_pos(4),handles.guidata.movie_width/2);
  ischange = false;
  if max_ry > ry,
    ry = max_ry;
    ischange = true;
  elseif max_rx > rx,
    rx = max_rx;
    ischange = true;
  end
  if rx ~= handles.guidata.zoom_fly_radius(1) || ...
      ry ~= handles.guidata.zoom_fly_radius(2),
    handles.guidata.zoom_fly_radius = [rx,ry];
    guidata(eventdata.Axes,handles);
  end  
  if ischange,
    if strcmpi(handles.guidata.preview_zoom_mode,'center_on_fly'),
      ZoomInOnFlies(handles,previewi);
    elseif strcmpi(handles.guidata.preview_zoom_mode,'follow_fly'),
      KeepFliesInView(handles,previewi);
    end
  end
end
return


% -------------------------------------------------------------------------
% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure_JLabel_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if ~handles.guidata.enabled,
%   return;
% end

hchil = gco;
if ismember(hchil,handles.guidata.axes_timelines),
  seltype = get(hObject,'SelectionType');
  switch lower(seltype),
    case 'normal', %left
      pt = get(hchil,'CurrentPoint');
      handles.guidata.buttondown_t0 = round(pt(1,1));
      handles.guidata.buttondown_axes = hchil;
      
      handles.guidata.didclearselection = ~any(isnan(handles.guidata.selected_ts));
      if handles.guidata.didclearselection,
        pushbutton_clearselection_Callback(hObject, eventdata, handles);
      else
        guidata(hObject,handles);
      end
      
      %fprintf('buttondown at %d\n',handles.guidata.buttondown_t0);
      %handles.guidata.selection_t0 = nan;
      %handles.guidata.selection_t1 = nan;

    case {'alternate','extend'}, %right,middle
      pt = get(hchil,'CurrentPoint');
      t = pt(1,1);
      if t >= handles.guidata.selected_ts(1) && t <= handles.guidata.selected_ts(2),
      end
    case 'open', % double click
  end
end
return


% -------------------------------------------------------------------------
% --- Executes on mouse motion over figure - except title and menu.
function figure_JLabel_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles,'guidata') || ~ishandle(handles.guidata.buttondown_axes),
  return;
end
if ~isnan(handles.guidata.buttondown_t0) && isnan(handles.guidata.selection_t0) && ...
    isnan(handles.guidata.selection_t1),    
  handles.guidata.selection_t0 = handles.guidata.buttondown_t0;
  handles.guidata.buttondown_t0 = nan;
  if handles.guidata.selecting,
    set(handles.togglebutton_select,'Value',0);
    handles.guidata.selecting = false;
  end
  guidata(hObject,handles);
end
if ~isnan(handles.guidata.selection_t0),
  pt = get(handles.guidata.buttondown_axes,'CurrentPoint');
  handles.guidata.selection_t1 = round(pt(1,1));
  handles.guidata.selected_ts = [handles.guidata.selection_t0,handles.guidata.selection_t1];
  %fprintf('Selecting %d to %d\n',handles.guidata.selection_t0,handles.guidata.selection_t1);
  guidata(hObject,handles);
  UpdateSelection(handles);
end
return
  

% -------------------------------------------------------------------------
% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure_JLabel_WindowButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to figure_JLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~ishandle(handles.guidata.buttondown_axes),
  return;
end
if isnan(handles.guidata.selection_t0),
  h = handles.guidata.buttondown_axes;
  handles.guidata.buttondown_axes = nan;
  handles.guidata.selection_t0 = nan;
  handles.guidata.selection_t1 = nan;
  if ~handles.guidata.didclearselection,
    axes_timeline_ButtonDownFcn(h, eventdata, handles);
  end
  return;
end
if ~isnan(handles.guidata.selection_t0),
  pt = get(handles.guidata.buttondown_axes,'CurrentPoint');
  handles.guidata.selection_t1 = round(pt(1,1));
  ts = sort([handles.guidata.selection_t0,handles.guidata.selection_t1]);
  ts(1) = min(max(ts(1),handles.data.t0_curr),handles.data.t1_curr);
  ts(2) = min(max(ts(2),handles.data.t0_curr),handles.data.t1_curr);
  if ts(1) == ts(2); % outside the range.
    handles.guidata.selected_ts = nan(1,2);
  else
    handles.guidata.selected_ts = ts;
  end
  %fprintf('Selected %d to %d\n',handles.guidata.selected_ts);
  UpdateSelection(handles);
end
handles.guidata.buttondown_axes = nan;
handles.guidata.selection_t0 = nan;
handles.guidata.selection_t1 = nan;
guidata(hObject,handles);
return


% -------------------------------------------------------------------------
function UpdateSelection(handles)

tmp = handles.guidata.selected_ts + .5*[-1,1];
set(handles.guidata.hselection,'XData',tmp([1,1,2,2,1]));
buttons = [handles.pushbutton_playselection,handles.pushbutton_clearselection];
if any(isnan(handles.guidata.selected_ts)),
  set(buttons,'Enable','off');
else
  set(buttons,'Enable','on');
end
return


% -------------------------------------------------------------------------
% --- Executes on button press in togglebutton_select.
function togglebutton_select_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_select
if get(hObject,'Value'),
  
  set(handles.figure_JLabel,'WindowButtonMotionFcn',handles.guidata.callbacks.figure_WindowButtonMotionFcn);

%   handles.guidata.selecting = true;
%   handles.guidata.selected_ts = handles.guidata.ts(1)+[0,0];
%   handles.guidata.buttondown_axes = nan;
%   UpdateSelection(handles);
else
  set(handles.figure_JLabel,'WindowButtonMotionFcn','');
  handles.guidata.selecting = false;
end
guidata(hObject,handles);
return


% -------------------------------------------------------------------------
% --- Executes on button press in pushbutton_clearselection.
function pushbutton_clearselection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_clearselection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.guidata.hplaying == handles.pushbutton_playselection,
  handles = stopPlaying(handles);
end

handles.guidata.selected_ts = nan(1,2);
handles.guidata.buttondown_axes = nan;
handles.guidata.selection_t0 = nan;
handles.guidata.selection_t1 = nan;
guidata(hObject,handles);
UpdateSelection(handles);
return


% -------------------------------------------------------------------------
% --- Executes on button press in pushbutton_playstop.
function pushbutton_playstop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_playstop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% fprintf('In playstop\n');

if handles.guidata.hplaying == hObject,
  stopPlaying(handles);
else
  if ~isnan(handles.guidata.hplaying),
    stopPlaying(handles);
  end
  play(hObject,handles);
end
return


% -------------------------------------------------------------------------
% --- Executes on button press in pushbutton_playselection.
function pushbutton_playselection_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_playselection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.guidata.hplaying == hObject,
  stopPlaying(handles);
else
  if ~isnan(handles.guidata.hplaying),
    stopPlaying(handles);
  end
  if any(isnan(handles.guidata.selected_ts)),
    return;
  end
  play(hObject,handles,handles.guidata.selected_ts(1),handles.guidata.selected_ts(2),true);
end
return


% -------------------------------------------------------------------------
function predictTimerCallback(obj,event,hObject,framesPerTick)
  handles = guidata(hObject);
  if handles.data.IsGTMode(),
    return;
  end
  global PLAY_TIMER_DONE CALC_FEATURES;
  CALC_FEATURES = true;
  %fprintf('Calling predictTimerCallback at time %s\n',datestr(now));
  t0 = max(floor(handles.guidata.ts(1)-handles.guidata.timeline_nframes/2),handles.data.t0_curr);
  t1 = min(t0+framesPerTick,handles.data.t1_curr);
  handles.data.Predict(handles.data.expi,handles.data.flies,t0,t1);
  PLAY_TIMER_DONE = true;
return
  
  
% -------------------------------------------------------------------------
function handles = play(hObject,handles,t0,t1,doloop)

clear global PLAY_TIME_DONE CALC_FEATURES
global PLAY_TIMER_DONE CALC_FEATURES;
PLAY_TIMER_DONE = false;
CALC_FEATURES = false;

axi = 1;
set(hObject,'String','Stop','BackgroundColor',[.5,0,0]);
%SetButtonImage(handles.pushbutton_playstop);
adjustButtonColorsIfMac(hObject);

if ~handles.data.IsGTMode()
  handles = predict(handles);
  guidata(hObject,handles);
end

handles.guidata.hplaying = hObject;
guidata(hObject,handles);
ticker = tic;
if nargin < 3,
  t0 = handles.guidata.ts(axi);
  t1 = handles.data.GetMaxEndFrame;
  doloop = false;
end

if ~doloop
  framesPerTick = 4000;
  t_period = round(framesPerTick/handles.guidata.play_FPS*1000)/1000;
  T = timer('TimerFcn',{@predictTimerCallback,hObject,framesPerTick},...
        'Period',t_period,...
        'ExecutionMode','fixedRate',...
        'Tag','predictTimer');
  start(T);
end

if(1)  % test framerate
while true,
  handles = guidata(hObject);
  if handles.guidata.hplaying ~= hObject,
    return;
  end
  
  if exist('CALC_FEATURES','var') && CALC_FEATURES
    t0 = handles.guidata.ts(axi);
    CALC_FEATURES = false;
  end
  
  if exist('PLAY_TIMER_DONE','var') && PLAY_TIMER_DONE
    ticker = tic;
    PLAY_TIMER_DONE = false;
    %predictStart = max(handles.data.t0_curr,floor(handles.guidata.ts(1)-handles.guidata.timeline_nframes));
    %predictEnd = min(handles.data.t1_curr,ceil(handles.guidata.ts(1)+handles.guidata.timeline_nframes/2));
    handles = SetPredictedPlot(handles);
    handles = UpdateTimelineImages(handles);

    guidata(hObject,handles);
    UpdatePlots(handles, ...
                'refreshim',false,'refreshflies',true,...
                'refreshtrx',true,'refreshlabels',true,...
                'refresh_timeline_manual',false,...
                'refresh_timeline_xlim',false,...
                'refresh_timeline_hcurr',false,...
                'refresh_timeline_selection',false,...
                'refresh_curr_prop',false);

  end
  % how long has it been
  dt_sec = toc(ticker);
  % wait until the next frame should be played
  dt = dt_sec*handles.guidata.play_FPS;
  t = ceil(dt)+t0;
  if t > t1,
    if doloop,
      ticker = tic;
      continue;
    else
      SetCurrentFrame(handles,axi,t1,hObject);
      break;
    end
  end
  SetCurrentFrame(handles,axi,t,hObject);
  handles = UpdateTimelineImages(handles);
  dt_sec = toc(ticker);
  pause_time = (t-t0)/handles.guidata.play_FPS - dt_sec;
  if pause_time <= 0,
    drawnow;
  else
    pause(pause_time);
  end
end

else  % test framerate

%t_last=t0;
t=t0;  %#ok
while true,
  handles = guidata(hObject);
  if handles.guidata.hplaying ~= hObject,
    return;
  end
  
  if CALC_FEATURES
    t0 = handles.guidata.ts(axi);
    CALC_FEATURES = false;
  end
  
  if PLAY_TIMER_DONE
    ticker = tic;
    PLAY_TIMER_DONE = false;
    predictStart = max(handles.data.t0_curr,floor(handles.guidata.ts(1)-handles.guidata.timeline_nframes));
    predictEnd = min(handles.data.t1_curr,ceil(handles.guidata.ts(1)+handles.guidata.timeline_nframes/2));
    handles = SetPredictedPlot(handles);
    handles = UpdateTimelineImages(handles);

    guidata(hObject,handles);
    UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
      'refreshtrx',true,'refreshlabels',true,...
      'refresh_timeline_manual',false,...
      'refresh_timeline_xlim',false,...
      'refresh_timeline_hcurr',false,...
      'refresh_timeline_selection',false,...
      'refresh_curr_prop',false);

  end
  if t > t1,
    if doloop,
      ticker = tic;
      continue;
    else
      break;
    end
  end
  SetCurrentFrame(handles,axi,t,hObject);
  handles = UpdateTimelineImages(handles);
  drawnow;
if(exist('tocker')),  disp(num2str(1/toc(tocker),2));  end
tocker=tic;
%if(t-t_last>1)  disp(['skip ' num2str(t-t_last) ' @ ' num2str(t)]);  end
%if(t==t_last)  disp(['repeat @ ' num2str(t)]);  end
%t_last=t;
  t=t+1;
end

end  % test framerate

stopPlaying(handles);

return

% -------------------------------------------------------------------------
function handles = stopPlaying(handles)

clear global PLAY_TIMER_DONE;
T = timerfind('Tag','predictTimer');
if ~isempty(T),  stop(T(:)); delete(T(:)); end
if isnan(handles.guidata.hplaying), return; end;
set(handles.guidata.hplaying,'String','Play','BackgroundColor',[.2,.4,0]);
%SetButtonImage(handles.guidata.hplaying);
adjustButtonColorsIfMac(handles.guidata.hplaying);
  
hObject = handles.guidata.hplaying;
handles.guidata.hplaying = nan;
guidata(hObject,handles);
return


% --------------------------------------------------------------------
function menu_view_plot_tracks_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_plot_tracks (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

v = get(handles.menu_view_plot_tracks,'Checked');

if strcmpi(v,'on'),
  h = findall(handles.guidata.axes_previews,'Type','line','Visible','on');
  handles.tracks_visible = h;
  handles.doplottracks = false;
  set(h,'Visible','off');
  set(hObject,'Checked','off');
  
  %  Show the marker for just the current fly.
  for i = 1:numel(handles.guidata.axes_previews)
    for curfly = handles.data.flies(:)'
      
      j = handles.guidata.fly2idx(curfly);
      set(handles.guidata.hfly_markers(j,i),'Visible','on','Marker','o');
      
    end
  end
  
else
  handles.tracks_visible = handles.tracks_visible(ishandle(handles.tracks_visible));
  handles.doplottracks = true;
  set(handles.tracks_visible(:),'Visible','on');
  set(hObject,'Checked','on');
  

  %  Change the markers back to sex markers.

  for i = 1:numel(handles.guidata.axes_previews)
    t = handles.guidata.ts(i);
    for curfly = handles.data.flies(:)'
      
      j = handles.guidata.fly2idx(curfly);
      
      sexcurr = handles.data.GetSex1(handles.data.expi,curfly,t);
      if lower(sexcurr(1)) == 'm',
        set(handles.guidata.hfly_markers(j,i),'Visible','on','Marker','*');
      else
        set(handles.guidata.hfly_markers(j,i),'Visible','off','Marker','*');
      end
      if ismember(curfly,handles.data.flies),
        set(handles.guidata.hfly_markers(j,i),'Visible','on');
        set(handles.guidata.hflies(j,i),'LineWidth',3);
      end
    end
  end
end
guidata(hObject,handles);
return


% --------------------------------------------------------------------
function contextmenu_timeline_manual_go_next_bout_start_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual_go_next_bout_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_go_next_bout_start_Callback(hObject,eventdata,handles);
return


% --------------------------------------------------------------------
function contextmenu_timeline_manual_go_previous_bout_end_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual_go_previous_bout_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_go_previous_bout_end_Callback(hObject,eventdata,handles);
return


% -------------------------------------------------------------------------
function [t0,t1,labelidx,label] = GetBoutProperties(handles,t,labeltype)

if nargin < 3,
  labeltype = 'manual';
end

if t < handles.data.t0_curr && t > handles.data.t1_curr,
  t0 = nan;
  t1 = nan;
  labelidx = nan;
  label = '';
  return;
end

if strcmpi(labeltype,'manual'),
  [labelidxStruct,T0,T1] = handles.data.GetLabelIdx(handles.data.expi,handles.data.flies);
  labelidx = labelidxStruct.vals;
else
  [prediction,T0,T1] = handles.data.GetPredictedIdx(handles.data.expi,handles.data.flies);
  labelidx = prediction.predictedidx;
end
i = t - T0 + 1;
i0 = find(labelidx(1:i-1) ~= labelidx(i),1,'last');
if isempty(i0),
  t0 = T0;
else
  t0 = i0 + T0;
end
i1 = find(labelidx(i+1:end) ~= labelidx(i),1,'first');
if isempty(i1),
  t1 = T1;
else
  t1 = i1 + t - 1;
end
labelidx = labelidx(i);
if nargout >= 4,
  if labelidx == 0,
    label = 'Unknown';
  else
    label = handles.data.labelnames{labelidx};
  end
  if ~strcmpi(labeltype,'manual'),
    label = ['Predicted ',label];
  end
end
return


% --------------------------------------------------------------------
function contextmenu_timeline_manual_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%disp('hi');
pt = get(handles.axes_timeline_manual,'CurrentPoint');
t = pt(1,1);

% inside a bout?
if t >= handles.data.t0_curr && t <= handles.data.t1_curr,
  [handles.bookmark_info.t0,handles.bookmark_info.t1,...
    handles.bookmark_info.labelidx,handles.bookmark_info.label] = ...
    GetBoutProperties(handles,round(t));
  s = sprintf('Bookmark %s bout (%d:%d)',handles.bookmark_info.label,...
    handles.bookmark_info.t0,handles.bookmark_info.t1);  
  set(handles.contextmenu_timeline_manual_bookmark_bout,'Visible','on',...
    'Label',s);
else
  set(handles.contextmenu_timeline_manual_bookmark_bout,'Visible','off');
end
  
% inside the current selection?
if t >= handles.guidata.selected_ts(1) && t <= handles.guidata.selected_ts(2),
  s = sprintf('Bookmark selection (%d:%d)',handles.guidata.selected_ts);
  handles.bookmark_info.t0 = min(handles.guidata.selected_ts);
  handles.bookmark_info.t1 = max(handles.guidata.selected_ts);
  handles.bookmark_info.labelidx = nan;
  handles.bookmark_info.label = 'Selection';
  set(handles.contextmenu_timeline_manual_bookmark_selection,'Visible','on','Label',s);
else
  set(handles.contextmenu_timeline_manual_bookmark_selection,'Visible','off');
end

guidata(hObject,handles);
return


% --------------------------------------------------------------------
function contextmenu_timeline_manual_bookmark_bout_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual_bookmark_bout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clip = handles.bookmark_info;
clip.t0 = max(handles.data.t0_curr,clip.t0-1);
clip.t1 = min(clip.t1+1,handles.data.t1_curr);%nframes);
AddBookmark(handles,handles.bookmark_info);
return


% --------------------------------------------------------------------
function contextmenu_timeline_manual_bookmark_selection_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual_bookmark_selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

labelidxStruct = handles.data.GetLabelIdx(handles.data.expi,handles.data.flies,handles.bookmark_info.t0,handles.bookmark_info.t1);
labelidx = labelidxStruct.vals;
handles.bookmark_info.labelidx = unique(labelidx);
tmp = [{'Unknown'},handles.data.labelnames];
if numel(handles.bookmark_info.labelidx) == 1,
  handles.bookmark_info.label = tmp{handles.bookmark_info.labelidx+1};
else
  counts = hist(labelidx,handles.bookmark_info.labelidx);
  pct = round(counts / numel(labelidx) * 100);
  s = '';
  for i = 1:numel(handles.bookmark_info.labelidx),
    s = [s,sprintf('%s(%d%%), ',tmp{handles.bookmark_info.labelidx(i)+1},pct(i))]; %#ok<AGROW>
  end
  s = s(1:end-2);
  handles.bookmark_info.label = s;
end
guidata(hObject,handles);

AddBookmark(handles,handles.bookmark_info);
return


% -------------------------------------------------------------------------
function handles = AddBookmark(handles,clip)

fprintf('TODO: Create bookmark for %d:%d\n',clip.t0,clip.t1);
flystr = sprintf('%d, ',handles.data.flies);
flystr = flystr(1:end-2);
SetStatus(handles,sprintf('Saving AVI for experiment %s, %s %s, frames %d to %d...',...
  handles.data.expnames{handles.data.expi},handles.data.targettype,flystr,clip.t0,clip.t1));
%clipsdir = 'wingexclips';

handles = make_jlabel_results_movie(handles,clip.t0,clip.t1);%,'clipsdir',clipsdir);
ClearStatus(handles);

%{
% clip.expi = handles.data.expi;
% clip.flies = handles.data.flies;
% clip.preview_zoom_mode = handles.guidata.preview_zoom_mode;
% axesi = 1;
% clip.xlim = get(handles.guidata.axes_previews(axesi),'XLim');
% clip.ylim = get(handles.guidata.axes_previews(axesi),'YLim');
% clip.zoom_fly_radius = handles.guidata.zoom_fly_radius;
% for i = 1:numel(handles.data.flies),
%   fly = handles.data.flies(i);
%   t0 = min(max(clip.t0,handles.data.t0_curr),handles.data.t1_curr);
%   t1 = min(max(clip.t1,handles.data.t0_curr),handles.data.t1_curr);
%   if t0 <= t1,
%     [xcurr,ycurr,thetacurr,acurr,bcurr] = ...
%       handles.data.GetTrxPos1(handles.data.expi,fly,t0:t1);
%   end
%   clip.trx(i).x = [nan(1,t0-clip.t0),xcurr,nan(1,clip.t1-t1)];
%   clip.trx(i).y = [nan(1,t0-clip.t0),ycurr,nan(1,clip.t1-t1)];
%   clip.trx(i).a = [nan(1,t0-clip.t0),acurr,nan(1,clip.t1-t1)];
%   clip.trx(i).b = [nan(1,t0-clip.t0),bcurr,nan(1,clip.t1-t1)];
%   clip.trx(i).theta = [nan(1,t0-clip.t0),thetacurr,nan(1,clip.t1-t1)];
% end
%  
% BookmarkedClips(handles.figure_JLabel,handles.data,'clips',clip);
%}
return


% --------------------------------------------------------------------
function contextmenu_timeline_manual_timeline_options_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual_timeline_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_view_timeline_options_Callback(hObject, eventdata, handles);
return


% -------------------------------------------------------------------------
% --- Executes on button press in similarFramesButton.
function similarFramesButton_Callback(hObject, eventdata, handles)
% hObject    handle to similarFramesButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of similarFramesButton

handles = predict(handles);
curTime = handles.guidata.ts(1);
handles.data.SimilarFrames(curTime, handles);
return


% -------------------------------------------------------------------------
function s = GetTargetInfo(handles,fly)

  s = {};
  i = 1;
  s{i} = sprintf('Target: %d',fly);
  i = i + 1;
  if handles.data.hassex,
    %t = max(handles.data.t0_curr,handles.guidata.ts(1));
    sexfrac = handles.data.GetSexFrac(handles.data.expi,fly);
    if sexfrac.M > sexfrac.F,
      sex = 'M';
    elseif sexfrac.M < sexfrac.F,
      sex = 'F';
    else
      sex = '?';
    end
    if handles.data.hasperframesex,
      s{i} = sprintf('Sex: %s (%d%%M, %d%%F)',sex,round(sexfrac.M*100),round(sexfrac.F*100));
    else
      s{i} = sprintf('Sex: %s',sex);
    end
    i = i + 1;
  end
  endframe = handles.data.endframes_per_exp{handles.data.expi}(fly);
  firstframe = handles.data.firstframes_per_exp{handles.data.expi}(fly);
  s{i} = sprintf('Frames: %d-%d',firstframe,endframe);
  i = i + 1;
  s{i} = sprintf(handles.data.expnames{handles.data.expi});
return


% --------------------------------------------------------------------
function menu_go_next_automatic_bout_start_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_next_automatic_bout_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;

[t,flies,expi] = handles.guidata.NJObj.JumpToStart(handles.data,handles.data.expi,handles.data.flies,...
  handles.guidata.ts(axesi),handles.data.t0_curr,handles.data.t1_curr);
if isempty(t),  return; end

try
  if handles.data.expi == expi && handles.data.flies == flies
    SetCurrentFrame(handles,axesi,t,hObject);
  elseif handles.data.expi == expi
    handles = SetCurrentFlies(handles,flies);
    handles = UpdateTimelineImages(handles);
    SetCurrentFrame(handles,axesi,t,hObject);
    UpdatePlots(handles,'refreshim',true,'refreshflies',true,...
      'refreshtrx',true,'refreshlabels',true,...
      'refresh_GT_suggestion',true,...
      'refresh_timeline_manual',false,...
      'refresh_timeline_xlim',false,...
      'refresh_timeline_hcurr',false,...
      'refresh_timeline_selection',false,...
      'refresh_curr_prop',false);
  else
    handles = SetCurrentMovie(handles,expi);
    handles = SetCurrentFlies(handles,flies);
    handles = UpdateTimelineImages(handles);
    SetCurrentFrame(handles,axesi,t,hObject);
    UpdatePlots(handles,'refreshim',true,'refreshflies',true,...
      'refreshtrx',true,'refreshlabels',true,...
      'refresh_GT_suggestion',true,...
      'refresh_timeline_manual',false,...
      'refresh_timeline_xlim',false,...
      'refresh_timeline_hcurr',false,...
      'refresh_timeline_selection',false,...
      'refresh_curr_prop',false);
    
  end
catch ME,
  uiwait(warndlg(sprintf('Could not switch target:%s',ME.message)));
end
guidata(hObject,handles);
return


% --------------------------------------------------------------------
function menu_go_previous_automatic_bout_end_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_previous_automatic_bout_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% TODO: make this work with multiple preview axes
axesi = 1;

[t,flies,expi] = handles.guidata.NJObj.JumpToEnd(handles.data,handles.data.expi,handles.data.flies,...
  handles.guidata.ts(axesi),handles.data.t0_curr,handles.data.t1_curr);
if isempty(t); return; end

try
  if handles.data.expi == expi && handles.data.flies == flies
    SetCurrentFrame(handles,axesi,t,hObject);
  elseif handles.data.expi == expi
    handles = SetCurrentFlies(handles,flies);
    SetCurrentFrame(handles,axesi,t,hObject);
    UpdatePlots(handles,'refreshim',true,'refreshflies',true,...
      'refreshtrx',true,'refreshlabels',true,...
      'refresh_GT_suggestion',true,...
      'refresh_timeline_manual',false,...
      'refresh_timeline_xlim',false,...
      'refresh_timeline_hcurr',false,...
      'refresh_timeline_selection',false,...
      'refresh_curr_prop',false);
  else
    handles = SetCurrentMovie(handles,expi);
    handles = SetCurrentFlies(handles,flies);
    SetCurrentFrame(handles,axesi,t,hObject);
    UpdatePlots(handles,'refreshim',true,'refreshflies',true,...
      'refreshtrx',true,'refreshlabels',true,...
      'refresh_GT_suggestion',true,...
      'refresh_timeline_manual',false,...
      'refresh_timeline_xlim',false,...
      'refresh_timeline_hcurr',false,...
      'refresh_timeline_selection',false,...
      'refresh_curr_prop',false);
  end
catch ME,
  uiwait(warndlg(sprintf('Could not switch target:%s',ME.message)));
end

return


% --------------------------------------------------------------------
function menu_view_zoom_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_zoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
function menu_view_keep_target_in_view_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_keep_target_in_view (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.preview_zoom_mode = 'follow_fly';
UpdateGUIToMatchPreviewZoomMode(handles)
KeepFliesInView(handles);
guidata(hObject,handles);
return


% --------------------------------------------------------------------
function menu_view_static_view_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_static_view (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.preview_zoom_mode = 'static';
UpdateGUIToMatchPreviewZoomMode(handles)
guidata(hObject,handles);
return


% --------------------------------------------------------------------
function contextmenu_timeline_automatic_go_next_bout_start_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_go_next_bout_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_go_next_automatic_bout_start_Callback(hObject,eventdata,handles);
return


% --------------------------------------------------------------------
function contextmenu_timeline_automatic_go_previous_bout_end_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_go_previous_bout_end (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_go_previous_automatic_bout_end_Callback(hObject,eventdata,handles);
return


% --------------------------------------------------------------------
function contextmenu_timeline_automatic_bookmark_bout_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_bookmark_bout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clip = handles.bookmark_info;
clip.t0 = max(handles.data.t0_curr,clip.t0-1);
clip.t1 = min(clip.t1+1,handles.data.t1_curr);%nframes);
AddBookmark(handles,handles.bookmark_info);
return


% --------------------------------------------------------------------
function contextmenu_timeline_automatic_bookmark_selection_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_bookmark_selection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

prediction = handles.data.GetPredictedIdx(handles.data.expi,handles.data.flies,handles.bookmark_info.t0,handles.bookmark_info.t1);
labelidx = prediction.predictedidx;
handles.bookmark_info.labelidx = unique(labelidx);
tmp = [{'Unknown'},handles.data.labelnames];
if numel(handles.bookmark_info.labelidx) == 1,
  handles.bookmark_info.label = ['Predicted ',tmp{handles.bookmark_info.labelidx+1}];
else
  counts = hist(labelidx,handles.bookmark_info.labelidx);
  pct = round(counts / numel(labelidx) * 100);
  s = 'Predicted ';
  for i = 1:numel(handles.bookmark_info.labelidx),
    s = [s,sprintf('%s(%d%%), ',tmp{handles.bookmark_info.labelidx(i)+1},pct(i))]; %#ok<AGROW>
  end
  s = s(1:end-2);
  handles.bookmark_info.label = s;
end
guidata(hObject,handles);

AddBookmark(handles,handles.bookmark_info);
return


% --------------------------------------------------------------------
function contextmenu_timeline_automatic_timeline_options_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_timeline_options (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_view_timeline_options_Callback(hObject, eventdata, handles);
return


% --------------------------------------------------------------------
function contextmenu_timeline_automatic_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pt = get(handles.axes_timeline_auto,'CurrentPoint');
t = pt(1,1);

% inside a bout?
if t >= handles.data.t0_curr && t <= handles.data.t1_curr,
  [handles.bookmark_info.t0,handles.bookmark_info.t1,...
    handles.bookmark_info.labelidx,handles.bookmark_info.label] = ...
    GetBoutProperties(handles,round(t),'automatic');
  s = sprintf('Bookmark %s bout (%d:%d)',handles.bookmark_info.label,...
    handles.bookmark_info.t0,handles.bookmark_info.t1);  
  set(handles.contextmenu_timeline_automatic_bookmark_bout,'Visible','on',...
    'Label',s);
  s = sprintf('Accept %s bout (%d:%d)',handles.bookmark_info.label,...
    handles.bookmark_info.t0,handles.bookmark_info.t1);
  set(handles.contextmenu_timeline_automatic_accept_bout,'Visible','on',...
    'Label',s);
else
  set(handles.contextmenu_timeline_automatic_bookmark_bout,'Visible','off');
  set(handles.contextmenu_timeline_automatic_accept_bout,'Visible','off');
end
  
% inside the current selection?
if t >= handles.guidata.selected_ts(1) && t <= handles.guidata.selected_ts(2),
  s = sprintf('Bookmark selection (%d:%d)',handles.guidata.selected_ts);
  handles.bookmark_info.t0 = min(handles.guidata.selected_ts);
  handles.bookmark_info.t1 = max(handles.guidata.selected_ts);
  handles.bookmark_info.labelidx = nan;
  handles.bookmark_info.label = 'Selection';
  set(handles.contextmenu_timeline_automatic_bookmark_selection,'Visible','on','Label',s);
  s = sprintf('Accept selected suggested labels (%d:%d)',handles.guidata.selected_ts);
  set(handles.contextmenu_timeline_automatic_accept_selected,'Visible','on','Label',s);  
else
  set(handles.contextmenu_timeline_automatic_bookmark_selection,'Visible','off');
  set(handles.contextmenu_timeline_automatic_accept_selected,'Visible','off');
end

guidata(hObject,handles);
return


% --------------------------------------------------------------------
function contextmenu_timeline_automatic_accept_selected_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_accept_selected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

t0 = handles.bookmark_info.t0;
t1 = handles.bookmark_info.t1;

t0 = min(handles.data.t1_curr,max(handles.data.t0_curr,t0));
t1 = min(handles.data.t1_curr,max(handles.data.t0_curr,t1));
prediction = handles.data.GetPredictedIdx(handles.data.expi,handles.data.flies,t0,t1);
predictedidx = prediction.predictedidx;
handles = SetLabelsPlot(handles,t0,t1,predictedidx);

UpdatePlots(handles,...
  'refreshim',false,'refreshflies',true,'refreshtrx',false,'refreshlabels',true,...
  'refresh_timeline_manual',true,...
  'refresh_timeline_auto',false,...
  'refresh_timeline_suggest',false,...
  'refresh_timeline_error',true,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_props',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);

guidata(hObject,handles);
return


% --------------------------------------------------------------------
function contextmenu_timeline_automatic_accept_bout_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_accept_bout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
function menu_view_plot_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_plot_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
function handles = menu_view_manual_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_manual_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.plot_labels_manual = true;
handles.guidata.plot_labels_automatic = false;
% set(handles.panel_timeline_select,'SelectedObject',handles.timeline_label_manual);
set(handles.timeline_label_manual,'Value',1);
UpdatePlotLabels(handles);
guidata(hObject,handles);
return


% --------------------------------------------------------------------
function menu_view_automatic_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_automatic_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.guidata.plot_labels_manual = false;
handles.guidata.plot_labels_automatic = true;
% set(handles.panel_timeline_select,'SelectedObject',handles.timeline_label_automatic);
set(handles.timeline_label_automatic,'Value',1);
UpdatePlotLabels(handles);
guidata(hObject,handles);
return


% --------------------------------------------------------------------
function UpdatePlotLabels(handles)

% Always update the menu item checkboxes
set(handles.menu_view_manual_labels, ...
    'Checked',onIff(handles.guidata.plot_labels_manual));
set(handles.menu_view_automatic_labels, ...
    'Checked',onIff(handles.guidata.plot_labels_automatic));

% If there's no current experiment, we're done  
someExperimentIsCurrent=handles.data.getSomeExperimentIsCurrent();
if ~someExperimentIsCurrent,
  return
end

if handles.guidata.plot_labels_manual,
  set(handles.guidata.hlabels,'Visible','on');
  set(handles.timeline_label_manual, ...
      'ForegroundColor',handles.guidata.emphasiscolor, ...
      'FontWeight','bold');
else
  set(handles.guidata.hlabels,'Visible','off');
  set(handles.timeline_label_manual, ...
      'ForegroundColor',handles.guidata.unemphasiscolor, ...
      'FontWeight','normal');
end
if handles.guidata.plot_labels_automatic,
  set(handles.guidata.hpredicted,'Visible','on');
  set(handles.timeline_label_automatic, ...
      'ForegroundColor',handles.guidata.emphasiscolor, ...
      'FontWeight','bold');
else
  set(handles.guidata.hpredicted,'Visible','off');
  set(handles.timeline_label_automatic, ...
      'ForegroundColor',handles.guidata.unemphasiscolor, ...
      'FontWeight','normal');
end

UpdatePlots(handles,...
            'refreshim',false, ...
            'refreshflies',true, ...
            'refreshtrx',false, ...
            'refreshlabels',true,...
            'refresh_timeline_manual',false,...
            'refresh_timeline_auto',false,...
            'refresh_timeline_suggest',false,...
            'refresh_timeline_error',false,...
            'refresh_timeline_xlim',false,...
            'refresh_timeline_hcurr',false,...
            'refresh_timeline_props',false,...
            'refresh_timeline_selection',false,...
            'refresh_curr_prop',false);

return


% --------------------------------------------------------------------
function contextmenu_timeline_automatic_overlay_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_automatic_overlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_view_plot_labels_automatic_Callback(hObject, eventdata, handles);
return


% --------------------------------------------------------------------
function contextmenu_timeline_manual_overlay_Callback(hObject, eventdata, handles)
% hObject    handle to contextmenu_timeline_manual_overlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

menu_view_plot_labels_manual_Callback(hObject, eventdata, handles);
return


% --------------------------------------------------------------------
function menu_view_show_bookmarked_clips_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_show_bookmarked_clips (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clipdir = handles.data.GetFile('clipsdir',handles.data.expi);
if ispc,
  winopen(clipdir);
else
  web(clipdir,'-browser');
end
return


% --------------------------------------------------------------------
function menu_edit_compression_preferences_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_compression_preferences (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

CompressionPreferences(handles.figure_JLabel);
return


% --------------------------------------------------------------------
function menu_classifier_set_confidence_thresholds_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_set_confidence_thresholds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ROCCurve(hObject,handles.data);
return


% ---------------------------------------------------------------------
function ROCCurve(JLabelHandle,jld)
% This now shows histogram, apt naming be damned.
try
  [curScores,modLabels]=jld.getCurrentScoresForROCCurve();
catch excp
  if isequal(excp.identifier,'JLabelData:noClassifier')
    uiwait(warndlg('No classifier has been trained to set the confidence thresholds.'));
    return
  else
    uiwait(errordlg('Some sort of error has occurred.'));
    return
  end
end
ShowROCCurve(modLabels,curScores,jld,JLabelHandle);
return


% --------------------------------------------------------------------
function menu_classifier_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
function menu_classifier_classify_all_experiments_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classify_all_experiments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% -------------------------------------------------------------------------
% --- Executes on button press in bagButton.
function bagButton_Callback(hObject, eventdata, handles)
% hObject    handle to bagButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.data.DoBagging();
set(handles.similarFramesButton,'Enable','on');
return


% --------------------------------------------------------------------
function menu_classifier_doFastUpdates_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_doFastUpdates (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curVal = get(hObject,'Checked');
if strcmp(curVal,'on')
  set(hObject,'Checked','off');
  handles.guidata.doFastUpdates = false;
else
  set(hObject,'Checked','on');
  handles.guidata.doFastUpdates = true;
end
guidata(hObject,handles);
return


% --------------------------------------------------------------------
function menu_classifier_select_features_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_select_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% handles=ShowSelectFeatures(handles);
oldPointer=pointerToWatch(hObject);
SelectFeatures(handles.figure_JLabel);
restorePointer(hObject,oldPointer);
% uiwait(selHandle);
% someExperimentIsCurrent=handles.data.getSomeExperimentIsCurrent();
% if ~someExperimentIsCurrent,
%   return
% end
% handles = predict(handles);
% guidata(hObject,handles);
return

  
% -------------------------------------------------------------------------
% --- Executes when selected object is changed in panel_timeline_select.
function panel_timeline_select_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panel_timeline_select 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

if  strcmp(get(eventdata.NewValue,'tag'),'timeline_label_manual')
  menu_view_manual_labels_Callback(hObject, eventdata, handles);
else
  menu_view_automatic_labels_Callback(hObject, eventdata, handles);
end
return


% --------------------------------------------------------------------
function menu_classifier_cross_validate_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_cross_validate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%handles.data.StoreLabelsAndPreLoadWindowData();
%  The above is done inside JLabelData.CrossValidate()
[success,msg,crossError,tlabels] = handles.data.CrossValidate();

if ~success, warndlg(msg); 
  return; 
end;

contents = cellstr(get(handles.automaticTimelineBottomRowPopup,'String'));
handles.guidata.bottomAutomatic = 'Validated';
set(handles.automaticTimelineBottomRowPopup,'Value',...
find(strcmp(contents,handles.guidata.bottomAutomatic)));

handles = SetPredictedPlot(handles);
handles = predict(handles);
guidata(hObject,handles);



cnames = {sprintf('%s|Predicted',handles.data.labelnames{1}),...
          'Not|Predicted',...
          sprintf('%s|Predicted',handles.data.labelnames{2}),...
          };
rnames = {sprintf('%s Important ',handles.data.labelnames{1}),...
          sprintf('%s Important ',handles.data.labelnames{2}),...
          '',...
          sprintf('Old %s Important',handles.data.labelnames{1}),...
          sprintf('Old %s Important',handles.data.labelnames{2}),...
          };

dat = {};
for col = 1:3
  for row = 1:4
    t1 = sprintf('%d ',crossError(1).numbers(row,col));
    if isnan(crossError(1).frac(row,col))
      t2 = ' (-)';
    else
      t2 = sprintf(' (%.1f%%)',crossError(1).frac(row,col)*100);
    end
    dat{row,col} = sprintf('%s%s',t1,t2);  %#ok
  end
end

dat(5,:) = repmat({''},1,3);

for col = 1:3
  for row = 1:4
    t1 = sprintf('%d ',crossError(1).oldNumbers(row,col));
    if isnan(crossError(1).oldFrac(row,col))
      t2 = ' (-)';
    else
      t2 = sprintf(' (%.1f%%)',crossError(1).oldFrac(row,col)*100);
    end
    dat{5+row,col} = sprintf('%s%s',t1,t2);  %#ok  
  end
end
        
f = figure('Position',[200 200 550 140],'Name','Cross Validation Error');
t = uitable('Parent',f,'Data',dat([1 3 5 6 8],:),'ColumnName',cnames,... 
            'ColumnWidth',{100},...
            'RowName',rnames,'Units','normalized','Position',[0 0 0.99 0.99]);  %#ok  

handles.guidata.open_peripherals(end+1) = f;          
if numel(crossError)>1
  for tndx = 1:numel(crossError)
    errorAll(tndx,1) = crossError(tndx).numbers(2,3)+crossError(tndx).numbers(4,1);  %#ok
    errorImp(tndx,1) = crossError(tndx).numbers(1,3)+crossError(tndx).numbers(3,1);  %#ok
  end
  totExamplesAll = sum(crossError(1).numbers(2,:))+sum(crossError(1).numbers(4,:));
  totExamplesImp = sum(crossError(1).numbers(1,:))+sum(crossError(1).numbers(3,:));

  errorAll = errorAll/totExamplesAll;
  errorImp = errorImp/totExamplesImp;

  f = figure('Name','Cross Validation Error with time');
  % ax = plot([errorAll errorImp]);
  % legend(ax,{'All', 'Important'});
  % set(gca,'XTick',1:numel(errorAll),'XTickLabel',tlabels,'XDir','reverse');
  % title(gca,'Cross Validation Error with time');
  ax = axes('parent',f,'box','on');
  line('parent',ax, ...
       'ydata',[errorAll errorImp]);
  legend(ax,{'All', 'Important'});
  set(ax,'XTick',1:numel(errorAll),'XTickLabel',tlabels,'XDir','reverse');
  title(ax,'Cross Validation Error with time');
  handles.guidata.open_peripherals(end+1) = f;          
end
return


% --------------------------------------------------------------------
function menu_classifier_classify_current_fly_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classify_current_fly (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
t0 =handles.data.t0_curr;
t1 = handles.data.t1_curr;
handles.data.Predict(handles.data.expi,handles.data.flies,handles.data.t0_curr,handles.data.t1_curr);
handles = SetPredictedPlot(handles,t0,t1);

handles = UpdateTimelineImages(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);
return


% --------------------------------------------------------------------
function menu_file_import_scores_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_import_scores (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
function menu_file_import_scores_curr_exp_default_loc_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_import_scores_curr_exp_default_loc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.data.LoadScoresDefault(handles.data.expi);

contents = cellstr(get(handles.automaticTimelineBottomRowPopup,'String'));
handles.guidata.bottomAutomatic = 'Imported';
set(handles.automaticTimelineBottomRowPopup,'Value',...
find(strcmp(contents,handles.guidata.bottomAutomatic)));

handles = UpdateTimelineImages(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);
return


% --------------------------------------------------------------------
function menu_file_import_scores_curr_exp_diff_loc_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_import_scores_curr_exp_diff_loc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tstring = sprintf('Scores file for %s',handles.data.expnames{handles.data.expi});
defaultPath=handles.data.defaultpath;
[fname,pname,~] = uigetfile('*.mat',tstring,defaultPath);
if ~fname; return; end;
sfn = fullfile(pname,fname);
handles.data.LoadScores(handles.data.expi,sfn);

contents = cellstr(get(handles.automaticTimelineBottomRowPopup,'String'));
handles.guidata.bottomAutomatic = 'Imported';
set(handles.automaticTimelineBottomRowPopup,'Value',...
find(strcmp(contents,handles.guidata.bottomAutomatic)));

handles = UpdateTimelineImages(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);
return


% --------------------------------------------------------------------
function menu_file_import_scores_curr_exp_diff_rootdir_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_import_scores_curr_exp_diff_rootdir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tstring = sprintf('Root dir to load scores for current experiment');
fname = uigetdir(handles.data.defaultpath,'*.mat',tstring);
if ~fname; return; end;
scoreFileName = handles.data.GetFile('scores',handles.data.expi);
[~, scoreFileName, ext] = myfileparts(scoreFileName);
sfn = fullfile(fname,handles.data.expnames{handles.data.expi},[scoreFileName ext]);
if ~exist(sfn,'file')
  warndlg(sprintf('Scores file %s does not exist for exp:%s',...
    scoreFileName,handles.data.expnames{handles.data.expi}));
  return;
end
handles.data.LoadScores(handles.data.expi,sfn);

contents = cellstr(get(handles.automaticTimelineBottomRowPopup,'String'));
handles.guidata.bottomAutomatic = 'Imported';
set(handles.automaticTimelineBottomRowPopup,'Value',...
find(strcmp(contents,handles.guidata.bottomAutomatic)));

handles = UpdateTimelineImages(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);
return


% --------------------------------------------------------------------
function menu_file_import_scores_all_exp_default_loc_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_import_scores_all_exp_default_loc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
for ndx = 1:handles.data.nexps,
  handles.data.LoadScoresDefault(ndx);
end

contents = cellstr(get(handles.automaticTimelineBottomRowPopup,'String'));
handles.guidata.bottomAutomatic = 'Imported';
set(handles.automaticTimelineBottomRowPopup,'Value',...
find(strcmp(contents,handles.guidata.bottomAutomatic)));

handles = UpdateTimelineImages(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);
return


% --------------------------------------------------------------------
function menu_file_import_scores_all_exp_diff_rootdir_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_import_scores_all_exp_diff_rootdir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

tstring = sprintf('Root dir to load scores for all experiments');
fname = uigetdir(handles.data.defaultpath,'*.mat',tstring);
if ~fname; return; end;
scoreFileName = handles.data.GetFile('scores',handles.data.expi);
[~, scoreFileName, ext] = myfileparts(scoreFileName);
scoreFileName = [scoreFileName ext];

for ndx = 1:handles.data.nexps,
  sfn = fullfile(fname,handles.data.expnames{ndx},scoreFileName);
  if ~exist(sfn,'file')
    warndlg(sprintf('Scores file %s does not exist for exp:%s',...
      scoreFileName,handles.data.expnames{ndx}));
    continue; 
  end
  handles.data.LoadScores(ndx,sfn);
end

contents = cellstr(get(handles.automaticTimelineBottomRowPopup,'String'));
handles.guidata.bottomAutomatic = 'Imported';
set(handles.automaticTimelineBottomRowPopup,'Value',...
find(strcmp(contents,handles.guidata.bottomAutomatic)));

handles = UpdateTimelineImages(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);
return


% --------------------------------------------------------------------
function menu_classifier_evaluate_on_new_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_evaluate_on_new_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

newError = handles.data.TestOnNewLabels();
handles = predict(handles);
if ~isfield(newError,'numbers'), return; end;
dialogStr = {};
if isfield(newError,'classifierfilename'),
  dialogStr{end+1} = sprintf('Classifier used to generate scores:%s',newError.classifierfilename);
end
dialogStr{end+1} = sprintf('%28s Predicted %10s    Predicted %10s \n',...
  '',handles.data.labelnames{2},handles.data.labelnames{1});
dialogStr{end+1} = sprintf('Labeled Important %12s      %d(%.2f)          %d(%.2f)\n',...
  handles.data.labelnames{1},...
  newError.numbers(1,1),newError.frac(1,1),...
  newError.numbers(1,3),newError.frac(1,3));
dialogStr{end+1} = sprintf('Labeled            %12s      %d(%.2f)          %d(%.2f)\n',...
  handles.data.labelnames{1},...
  newError.numbers(2,1),newError.frac(2,1),...
  newError.numbers(2,3),newError.frac(2,3));
dialogStr{end+1} = sprintf('Labeled Important  %12s      %d(%.2f)          %d(%.2f)\n',...
  handles.data.labelnames{2},...
  newError.numbers(3,1),newError.frac(3,1),...
  newError.numbers(3,3),newError.frac(3,3));
dialogStr{end+1} = sprintf('Labeled            %12s      %d(%.2f)          %d(%.2f)\n',...
  handles.data.labelnames{2},...
  newError.numbers(4,1),newError.frac(4,1),...
  newError.numbers(4,3),newError.frac(4,3));

helpdlg(dialogStr,'Performance on new labeled data');
return


% % --------------------------------------------------------------------
% function menu_file_load_exps_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_file_load_exps (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% filename = handles.data.classifierfilename;
% [filename,pathname] = uigetfile('*.mat','Load classifier',filename);
% if ~ischar(filename),
%   return;
% end
% classifiername = fullfile(pathname,filename);
% handles.data.SetClassifierFileName(classifiername);


% % --------------------------------------------------------------------
% function menu_file_load_woexps_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_file_load_woexps (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% filename = handles.data.classifierfilename;
% [filename,pathname] = uigetfile('*.mat','Load classifier',filename);
% if ~ischar(filename),
%   return;
% end
% classifiername = fullfile(pathname,filename);
% handles.data.SetClassifierFileNameWoExp(classifiername);


% --------------------------------------------------------------------
function menu_classifier_training_parameters_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_training_parameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cohandles = ClassifierOptions(handles.data);
handles.guidata.open_peripherals(end+1) = cohandles;
return


% --------------------------------------------------------------------
function menu_go_switch_target_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_switch_target (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
changeTargetHandle = SwitchTarget(hObject);
SwitchTarget('initTable',changeTargetHandle);
handles.guidata.open_peripherals(end+1) = changeTargetHandle;
return


% --------------------------------------------------------------------
function menu_classifier_visualize_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_visualize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~handles.data.HasWindowdata();
  uiwait(warndlg('Cannot create classifier visualization without windowdata. Train a classifier again to generate windowdata.'));
  return;
end

SetStatus(handles,'Creating classifier visualization');

[hweight,hscore,hax,hfig,hylabel,hticks,hcolorbar,...
  sorted_weights,feature_order,bins,scores] = ...
  ShowWindowFeatureWeights(handles.data,'figpos',...
  [10,10,1000,1000],'nfeatures_show',50); %#ok<ASGLU>

ti = sprintf('Classifier %s',datestr(handles.data.classifierTS));
set(hfig,'Name',ti);

handles.visualizeclassifier = ...
  struct('sorted_weights',sorted_weights,...
  'feature_order',feature_order,'bins',bins,...
  'scores',scores);

handles.guidata.open_peripherals(end+1) = hfig;

guidata(hObject,handles);

ClearStatus(handles);
return


% --------------------------------------------------------------------
function menu_classifier_classify_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classify (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function menu_classifier_classify_current_experiment_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classify_current_experiment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in automaticTimelineBottomRowPopup.
function automaticTimelineBottomRowPopup_Callback(hObject, eventdata, handles)
% hObject    handle to automaticTimelineBottomRowPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

contents = cellstr(get(hObject,'String'));
handles.guidata.bottomAutomatic = contents{get(hObject,'Value')};
%set(handles.automaticTimelineBottomRowPopup,'BackgroundColor',[50 50 50]/256);
handles = UpdateTimelineImages(handles);
guidata(hObject,handles);
UpdatePlots(handles, ...
            'refreshim',false,'refreshflies',true,...
            'refreshtrx',true,'refreshlabels',true,...
            'refresh_timeline_manual',false,...
            'refresh_timeline_xlim',false,...
            'refresh_timeline_hcurr',false,...
            'refresh_timeline_selection',false,...
            'refresh_curr_prop',false);
return


% -------------------------------------------------------------------------
% --- Executes during object creation, after setting all properties.
function automaticTimelineBottomRowPopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to automaticTimelineBottomRowPopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
return


% -------------------------------------------------------------------------
function handles = UpdateGUIToMatchGroundTruthingMode(handles)
% Updates the graphics objects as needed to match the current labeling mode 
% (normal or ground-truthing)

% get the mode
%if isempty(handles.data) ,
if ~handles.data.thereIsAnOpenFile ,
  mode=[];
else
  mode=handles.data.gtMode;
end

% Make all the mode checkmarks self-consistent
updateCheckMarksInMenus(handles);

% If no experiments, just return
%if isempty(handles.data) || handles.data.nexps < 1,
if ~handles.data.thereIsAnOpenFile || handles.data.nexps < 1 , 
  return
end

% specify graphics object visible in only one mode or another
labelingOnlyGrobjects = [handles.pushbutton_train,...
                         handles.axes_timeline_auto, ...
                         handles.guidata.himage_timeline_auto,...
                         handles.guidata.htimeline_errors, ...
                         handles.guidata.htimeline_suggestions,...
                         handles.automaticTimelinePredictionLabel,...
                         handles.automaticTimelineScoresLabel,...
                         handles.automaticTimelineBottomRowPopup,...
                         handles.timeline_label_automatic, ...
                         handles.text_scores];
groundTruthOnlyGrobjects = [handles.menu_view_show_predictions, ...
                            handles.menu_view_suggest_gt_intervals,...
                            handles.menu_classifier_compute_gt_performance];

% Determine whether the visibility of each groups should be 'on' or 'off'                          
if isempty(mode)
  visibilityOfLabelingOnlyGrobjects='off';
  visibilityOfGroundTruthOnlyGrobjects='off';
else
  visibilityOfLabelingOnlyGrobjects=fif(mode,'off','on');
  visibilityOfGroundTruthOnlyGrobjects=fif(mode,'on','off');
end

% Set the mode of each group accordingly
set(labelingOnlyGrobjects,'Visible',visibilityOfLabelingOnlyGrobjects);
set(groundTruthOnlyGrobjects,'Visible',visibilityOfGroundTruthOnlyGrobjects);

% For axes, set the mode of their children accordingly
for h=labelingOnlyGrobjects
  if strcmpi(get(h,'type'),'axes')
    set(get(h,'children'),'visible',visibilityOfLabelingOnlyGrobjects)
  end
end
for h=groundTruthOnlyGrobjects
  if strcmpi(get(h,'type'),'axes')
    set(get(h,'children'),'visible',visibilityOfGroundTruthOnlyGrobjects)
  end
end

% Don't think we need to do this here
%handles = UpdateGUIAdvancedMode(handles);

return


% -------------------------------------------------------------------------
function UpdateGUIToMatchPreviewZoomMode(handles)

switch handles.guidata.preview_zoom_mode,
  case 'follow_fly',
    set(handles.menu_view_keep_target_in_view,'checked','on' );
    set(handles.menu_view_center_on_target,   'checked','off');
    set(handles.menu_view_static_view,        'checked','off');
  case 'center_on_fly',
    set(handles.menu_view_keep_target_in_view,'checked','off');
    set(handles.menu_view_center_on_target,   'checked','on' );
    set(handles.menu_view_static_view,        'checked','off');
  case 'static',
    set(handles.menu_view_keep_target_in_view,'checked','off');
    set(handles.menu_view_center_on_target,   'checked','off');
    set(handles.menu_view_static_view,        'checked','on' );
end

return


% -------------------------------------------------------------------------
function handles = UpdateGUIToMatchAdvancedMode(handles)

% make sure the menu checkboxes are self-consistent
updateCheckMarksInMenus(handles);

% update the label buttons and the panel positions, even if there's no open
% file and therefore they're invisble
handles=UpdateLabelButtons(handles);
updatePanelPositions(handles);

return


% --------------------------------------------------------------------
function menu_view_show_predictions_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_show_predictions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

h_prediction = [handles.axes_timeline_auto,handles.guidata.himage_timeline_auto,...
    handles.automaticTimelinePredictionLabel,...
    handles.automaticTimelineScoresLabel,...
    handles.automaticTimelineBottomRowPopup,...
    handles.timeline_label_automatic,...
    handles.text_scores];

if strfind(get(hObject,'Label'),'Show')
  set(hObject,'Label','Hide Predictions');
  set(h_prediction,'Visible','on');
else
  set(hObject,'Label','Show Predictions');
  set(h_prediction,'Visible','off');  
end
set(handles.menu_view_automatic_labels,'Visible','on');
return


% --------------------------------------------------------------------
function menu_view_suggest_gt_intervals_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_suggest_gt_intervals (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
function menu_view_suggest_gt_intervals_random_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_suggest_gt_intervals_random (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

in = inputdlg({'Number of frames per fly','Number of flies per experiment'});
if isempty(in), return; end
perfly = str2double(in{1});
perexp = str2double(in{2});
if isnan(perfly) || (round(perfly)-perfly)~=0 || ...
    isnan(perexp) || (round(perexp)-perexp)~=0 
  warndlg('Input error: enter integer values');
  return;
end

if any( handles.data.nflies_per_exp<perexp)
  warndlg('Some experiments have less than %d flies\n',perexp);
  return;
end

%handles.data.SuggestRandomGT(perfly,perexp);
handles.data.setGTSuggestionMode('Random',perfly,perexp);

set(handles.menu_view_suggest_gt_intervals_random,'Checked','on');
set(handles.menu_view_suggest_gt_intervals_load,'Checked','off');
set(handles.menu_view_suggest_gt_intervals_balanced_random,'Checked','off');
set(handles.menu_view_suggest_gt_intervals_none,'Checked','off');
set(handles.guidata.htimeline_gt_suggestions,'Visible','on');
handles = UpdateTimelineImages(handles);
guidata(handles.figure_JLabel,handles);

GTSuggestions = struct('start',{},'end',{},'exp',{},'flies',{});
for i = 1:numel(handles.data.randomGTSuggestions),
  for j = 1:numel(handles.data.randomGTSuggestions{i}),
    for k = 1:numel(handles.data.randomGTSuggestions{i}(j).start),
      GTSuggestions(end+1) = struct('start',handles.data.randomGTSuggestions{i}(j).start(k),...
        'end',handles.data.randomGTSuggestions{i}(j).end(k),...
        'exp',i,'flies',j);
    end
  end
end

handles = NavigateToGTSuggestion(handles,GTSuggestions);

UpdatePlots(handles,'refreshim',true,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',true,...
  'refresh_timeline_xlim',true,...
  'refresh_timeline_hcurr',true,...
  'refresh_timeline_selection',true,...
  'refresh_curr_prop',true);
return

function handles = NavigateToGTSuggestion(handles,GTSuggestions)

nextexpi = nan;
nextfly = nan;
nextframe = nan;

[~,ord] = sortrows([ [GTSuggestions.exp]' [GTSuggestions.flies]' [GTSuggestions.start]']);
GTSuggestions = GTSuggestions(ord);
for i = 1:numel(GTSuggestions),
  expi = GTSuggestions(i).exp;
  flies = GTSuggestions(i).flies;
  t0 = GTSuggestions(i).start;
  t1 = GTSuggestions(i).end;
  
  % ground-truth suggestions are frames in the video, same as the input
  % to GetLabelIdx
  
  % are there labels within this interval?
  labelidxcurr = handles.data.GetLabelIdx(expi,flies,t0,t1);
  if all(labelidxcurr.vals == 0),
    nextexpi = expi;
    nextfly = flies;
    nextframe = t0;
    break;
  end
end

if isnan(nextexpi),
  uiwait(msgbox('No more ground-truthing suggestion intervals to label'));
  return;
else
  nextexp = handles.data.expnames{nextexpi};
end

if i == 1,
  res = questdlg(sprintf('Navigate to first ground truth suggestion (exp %s, target %d, frame %d)?',nextexp,nextfly,nextframe));
else
  res = questdlg(sprintf('Navigate to next ground truth suggestion (exp %s, target %d, frame %d)?',nextexp,nextfly,nextframe));
end
if ~strcmpi(res,'Yes'),
  return;
end

[handles,success] = SetCurrentMovie(handles,nextexpi);
if ~success,
  uiwait(warndlg(sprintf('Could not switch to experiment %s',expname)));
  return;
end

handles = SetCurrentFlies(handles,nextfly,false,false);

handles = SetCurrentFrame(handles,1,nextframe,handles.figure_JLabel,false,false);

% --------------------------------------------------------------------
function menu_view_suggest_gt_intervals_none_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_suggest_gt_intervals_none (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.menu_view_suggest_gt_intervals_random,'Checked','off');
set(handles.menu_view_suggest_gt_intervals_load,'Checked','off');
set(handles.menu_view_suggest_gt_intervals_balanced_random,'Checked','off');
set(handles.menu_view_suggest_gt_intervals_none,'Checked','on');
set(handles.guidata.htimeline_gt_suggestions,'Visible','off');

handles = UpdateTimelineImages(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',true,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);
return


% --------------------------------------------------------------------
function menu_view_suggest_gt_intervals_balanced_random_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_suggest_gt_intervals_balanced_random (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
  avgBoutLen = handles.data.GetAverageLoadedPredictionBoutLength();
catch excp
  if isequal(excp.identifier,'JLabelData:noLoadedScores')
    uiwait(warndlg('No scores have been Imported. You have to import the scores before you can view balanced GT suggestions.'));
    return
  else
    rethrow(excp);
  end
end  % try/catch

indlg1 = sprintf('Number of frames per labeling interval (Avg prediction bout length is %.2f)',avgBoutLen);
in = inputdlg({indlg1,'Number of intervals'});
if isempty(in), return; end
intsize = str2double(in{1});
numint = str2double(in{2});
if isnan(intsize) || (round(intsize)-intsize)~=0 || ...
    isnan(numint) || (round(numint)-numint)~=0 
  warndlg('Input error: enter integer values');
  return;
end

SetStatus(handles,'Finding suggestions for ground truthing...');
%[success,msg ] = handles.data.SuggestBalancedGT(intsize,numint);
[success,msg] = handles.data.setGTSuggestionMode('Balanced',intsize,numint);
ClearStatus(handles);
if ~success, warndlg(msg); return; end

set(handles.menu_view_suggest_gt_intervals_random,'Checked','off');
set(handles.menu_view_suggest_gt_intervals_load,'Checked','off');
set(handles.menu_view_suggest_gt_intervals_balanced_random,'Checked','on');
set(handles.menu_view_suggest_gt_intervals_none,'Checked','off');
set(handles.guidata.htimeline_gt_suggestions,'Visible','on');

handles = UpdateTimelineImages(handles);

handles = NavigateToGTSuggestion(handles,handles.data.balancedGTSuggestions);

guidata(hObject,handles);

UpdatePlots(handles,'refreshim',true,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',true,...
  'refresh_timeline_xlim',true,...
  'refresh_timeline_hcurr',true,...
  'refresh_timeline_selection',true,...
  'refresh_curr_prop',true);

return


% --------------------------------------------------------------------
function menu_view_suggest_gt_intervals_load_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_suggest_gt_intervals_load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[filename,pathname] = uigetfile('*.txt',...
  sprintf('Choose ground truth suggestion file config file for experiment %s',handles.data.expnames{handles.data.expi}) ,...
  handles.data.expdirs{handles.data.expi});
if ~filename, return, end;

%handles.data.SuggestLoadedGT(handles.data.expi,fullfile(pathname,filename));
handles.data.setGTSuggestionMode('Imported', ...
                                         fullfile(pathname,filename));

set(handles.menu_view_suggest_gt_intervals_random,'Checked','off');
set(handles.menu_view_suggest_gt_intervals_load,'Checked','on');
set(handles.menu_view_suggest_gt_intervals_none,'Checked','off');
set(handles.guidata.htimeline_gt_suggestions,'Visible','on');
set(handles.menu_view_suggest_gt_intervals_load,'Checked','off');
handles = UpdateTimelineImages(handles);

if iscell(handles.data.loadedGTSuggestions),
  GTSuggestions = struct('start',{},'end',{},'exp',{},'flies',{});
  for i = 1:numel(handles.data.loadedGTSuggestions),
    for j = 1:numel(handles.data.loadedGTSuggestions{i}),
      for k = 1:numel(handles.data.loadedGTSuggestions{i}(j).start),
        if handles.data.loadedGTSuggestions{i}(j).start(k) > handles.data.loadedGTSuggestions{i}(j).end(k),
          continue;
        end
        GTSuggestions(end+1) = struct('start',handles.data.loadedGTSuggestions{i}(j).start(k),...
          'end',handles.data.loadedGTSuggestions{i}(j).end(k),...
          'exp',i,'flies',j);
      end
    end
  end
else
  GTSuggestions = handles.data.loadedGTSuggestions;
end

handles = NavigateToGTSuggestion(handles,GTSuggestions);

guidata(hObject,handles);

UpdatePlots(handles,'refreshim',true,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',true,...
  'refresh_timeline_xlim',true,...
  'refresh_timeline_hcurr',true,...
  'refresh_timeline_selection',true,...
  'refresh_curr_prop',true);


return


% --------------------------------------------------------------------
function menu_classifier_compute_gt_performance_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_compute_gt_performance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
crossError = handles.data.GetGTPerformance();
cnames = {sprintf('%s|Predicted',handles.data.labelnames{1}),...
          'Not|Predicted',...
          sprintf('%s|Predicted',handles.data.labelnames{2}),...
          };
rnames = {sprintf('%s Important ',handles.data.labelnames{1}),...
          sprintf('%s ',handles.data.labelnames{1}),...
          sprintf('%s Important ',handles.data.labelnames{2}),...
          sprintf('%s ',handles.data.labelnames{2}),...
          };

dat = {};
for col = 1:3
  for row = 1:4
    t1 = sprintf('%d ',crossError.numbers(row,col));
    if isnan(crossError.frac(row,col))
      t2 = ' (-)';
    else
      t2 = sprintf(' (%.1f%%)',crossError.frac(row,col)*100);
    end
    dat{row,col} = sprintf('%s%s',t1,t2);  %#ok
  end
end

        
f = figure('Position',[200 200 500 120],'Name','Ground Truth Performance');
t = uitable('Parent',f,'Data',dat,'ColumnName',cnames,... 
            'RowName',rnames,'Units','normalized','Position',[0 0 0.99 0.99]);  %#ok
return


% --------------------------------------------------------------------
function menu_view_show_whole_frame_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_show_whole_frame (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set to static view
menu_view_static_view_Callback(hObject, eventdata, handles);
% and now set the view to the whole frame
ShowWholeVideo(handles);

return


% --------------------------------------------------------------------
function menu_file_export_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%exportEverythingFile(findAncestorFigure(hObject),'Labels');

return


% %--------------------------------------------------------------------------
% function DisableGUI(handles)
% 
% handles.guidata.henabled = findall(handles.figure_JLabel,'Enable','on');
% handles.guidata.enabled = false;
% set(handles.guidata.henabled,'Enable','off');
% 
% return


% %--------------------------------------------------------------------------
% function ReEnableGUI(handles)
% 
% handles.guidata.enabled = true;
% set(handles.guidata.henabled,'Enable','on');
% 
% return


% --------------------------------------------------------------------
function menu_file_export_ground_truthing_suggestions_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_ground_truthing_suggestions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% expi = handles.data.expi;
% expdir = handles.data.expdirs{expi};
outfile = fullfile('GTSuggestions.txt');
[fname,pname] = uiputfile('*.txt','Save Ground Truth Suggestions',outfile);
if isempty(fname), return; end;
outfile = fullfile(pname,fname);
handles.data.SaveSuggestionGT(outfile);
return


% --------------------------------------------------------------------
function menu_edit_memory_usage_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_memory_usage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% curval = sprintf('%d',handles.data.cacheSize);
curval = sprintf('%d',handles.data.cacheSize);
v = inputdlg('Memory usage (MB)','Cache Size',1,{curval});
if isempty(v),
  return;
end
if ~ischar(v),
  return;
end
sz = str2double(v{1});
if isnan(sz) || sz<0;
  return;
end

% handles.guidata.cacheSize = round(sz);
% handles.data.cacheSize = round(sz);
handles.data.cacheSize = round(sz);
return


% --------------------------------------------------------------------
function menu_classifier_post_processing_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_post_processing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

posthandle = PostProcess(handles.data,handles);
handles.guidata.open_peripherals(end+1) = posthandle;
return


% --------------------------------------------------------------------
function menu_classifier_classifyCurrentMovieSave_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyCurrentMovieSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
  handles.data.PredictSaveMovie(handles.data.expi);
catch excp
  uiwait(errordlg(excp.message,'Error Saving Scores','modal'));
end  % try/catch

return


% --------------------------------------------------------------------
function menu_classifier_classifyCurrentMovieSaveNew_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyCurrentMovieSaveNew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
expi = handles.data.expi;
fspec = fullfile(handles.data.expdirs{expi},'*.mat'); 
[fname,pname] = uiputfile(fspec);
if fname==0,
  return;
end
try
  handles.data.PredictSaveMovie(handles.data.expi,fullfile(pname,fname));
catch excp
  uiwait(errordlg(excp.message,'Error Saving Scores','modal'));
end  % try/catch
handles = UpdateTimelineImages(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);
return


% --------------------------------------------------------------------
function menu_classifier_classifyCurrentMovieNoSave_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyCurrentMovieNoSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.data.PredictWholeMovieNoSave(handles.data.expi);
handles = UpdateTimelineImages(handles);
guidata(handles.figure_JLabel,handles);
UpdatePlots(handles,'refreshim',false,'refreshflies',true,...
  'refreshtrx',true,'refreshlabels',true,...
  'refresh_timeline_manual',false,...
  'refresh_timeline_xlim',false,...
  'refresh_timeline_hcurr',false,...
  'refresh_timeline_selection',false,...
  'refresh_curr_prop',false);
return


% --------------------------------------------------------------------
function menu_file_export_scores_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_scores (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% --------------------------------------------------------------------
function menu_file_export_scores_curr_exp_default_loc_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_scores_curr_exp_default_loc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
  handles.data.SaveCurScores(handles.data.expi);
catch excp
  uiwait(errordlg(excp.message,'Error Saving Scores','modal'));
end  % try/catch
return


% --------------------------------------------------------------------
function menu_file_export_scores_curr_exp_diff_loc_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_scores_curr_exp_diff_loc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
expi = handles.data.expi;
fspec = fullfile(handles.data.expdirs{expi},'*.mat'); 
[fname,pname] = uiputfile(fspec);
if fname==0,
  return;
end
try
  handles.data.SaveCurScores(handles.data.expi,fullfile(pname,fname));
catch excp
  uiwait(errordlg(excp.message,'Error Saving Scores','modal'));
end  % try/catch
return


% --------------------------------------------------------------------
function menu_file_export_scores_all_exp_default_loc_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_scores_all_exp_default_loc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
  for ndx = 1:handles.data.nexps
    handles.data.SaveCurScores(ndx);
  end
catch excp
  uiwait(errordlg(excp.message,'Error Saving Scores','modal'));
end  % try/catch
return


% --------------------------------------------------------------------
function menu_file_export_scores_all_exp_diff_loc_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_scores_all_exp_diff_loc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fname = inputdlg('Save the scores in the experiment directory to file.. ' );
if isempty(fname),
  return;
end
try
  for ndx = 1:handles.data.nexps
    handles.data.SaveCurScores(ndx,fullfile(handles.data.expdirs{ndx},fname));
  end
catch excp
  uiwait(errordlg(excp.message,'Error Saving Scores','modal'));
end  % try/catch
return


% --------------------------------------------------------------------
function menu_classifier_classifyall_default_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyall_default (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
  for ndx = 1:handles.data.nexps,
    handles.data.PredictSaveMovie(ndx);
  end
catch excp
  uiwait(errordlg(excp.message,'Error Saving Scores','modal'));
end  % try/catch
return


% --------------------------------------------------------------------
function menu_classifier_classifyall_new_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyall_new (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fileNameAsCellArray = inputdlg('Save scores to file name:','Scores File Name?');
if isempty(fileNameAsCellArray),
  return
else
  fileName=fileNameAsCellArray{1};
  if isempty(fileName)
    return
  end
end
try
  for ndx = 1:handles.data.nexps
    thisExpDirName=handles.data.expdirs{ndx};
    thisScoreFileName=fullfile(thisExpDirName,fileName);
    handles.data.PredictSaveMovie(ndx,thisScoreFileName);
  end
catch excp
  uiwait(errordlg(excp.message,'Error Saving Scores','modal'));
end  % try/catch
return


% --------------------------------------------------------------------
function menu_classifier_classifyall_nosave_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_classifyall_nosave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
for ndx = 1:handles.data.nexps
handles.data.PredictWholeMovieNoSave(ndx);
end
return


% --------------------------------------------------------------------
function menu_file_save_project_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_save_project (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.data.SaveProject();
set(handles.menu_file_save_project,'Enable','off');
return


% --------------------------------------------------------------------
function menu_help_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
return


% -------------------------------------------------------------------------
function menu_help_about_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help_about (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
vid = fopen('version.txt','r');
vv = textscan(vid,'%s');
fclose(vid);
helpdlg(sprintf('JAABA (Janelia Automated Animal Behavior Annotator) version:%s',vv{1}{1}));
return
 

% --------------------------------------------------------------------
function menu_help_documentation_Callback(hObject, eventdata, handles)
% hObject    handle to menu_help_documentation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isdeployed,
  %html_file = deployedRelative2Global('docs/index.html');
  html_file = 'http://jaaba.sourceforge.net/';
  [stat,msg] = myweb_nocheck(html_file);
  if stat ~= 0,
    errordlg({'Please see documentation at http://jaaba.sourceforge.net'
      'Error opening webpage within MATLAB:'
      msg});
  end
else
  web('-browser','http://jaaba.sourceforge.net/');
end
return


% % -------------------------------------------------------------------------
% function menu_file_open_old_school_files_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_file_open_old_school_files (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % This is part of the "grand unified project" project
% 
% % This creates a menu_file_open_old_school_files project from scratch.
% 
% % Create the modal window that allows specification of the project, etc.
% %[handles,success] = ...
% %  JLabelEditFiles('JLabelHandle',handles,...
% %                  'JLabelSplashHandle',handles.guidata.hsplash);
% JLabelEditFiles('figureJLabel',handles.figure_JLabel);
% 
% % % If user hits 'Cancel' just return                
% % if ~success,
% %   guidata(hObject,handles);
% %   return;
% % end
% % 
% % % Switch to the watch, this could take a while
% % set(handles.figure_JLabel,'pointer','watch');
% % 
% % % I don't know what this does --ALT, Jan 8 2013
% % handles.data.SetStatusFn(@(s) SetStatusCallback(s,handles.figure_JLabel));
% % handles.data.SetClearStatusFn(@() ClearStatusCallback(handles.figure_JLabel));
% % 
% % % read configuration
% % [handles,success] = LoadConfig(handles);
% % if ~success,
% %   guidata(hObject,handles);
% %   %delete(hObject);
% %   return;
% % end
% % 
% % handles = InitSelectionCallbacks(handles);
% % 
% % if (handles.data.nexps > 0 && handles.data.expi == 0) ,
% %   handles = SetCurrentMovie(handles,1);
% % else
% %   handles = SetCurrentMovie(handles,handles.data.expi);
% % end
% % 
% % handles = UpdateGUIGroundTruthingMode(handles);
% % 
% % % keypress callback for all non-edit text objects
% % RecursiveSetKeyPressFcn(handles.figure_JLabel);
% % 
% % % enable gui
% % EnableGUI(handles);
% % 
% % % OK, almost done
% % set(handles.figure_JLabel,'pointer','arrow');
% % 
% % % Update handles structure
% % guidata(hObject, handles);
% 
% return


% % -------------------------------------------------------------------------
% function importDone(figureJLabel)
% 
% % get the handles
% handles=guidata(figureJLabel);
% 
% % Switch to the watch, this could take a while
% set(figureJLabel,'pointer','watch');
% 
% % I don't know what this does --ALT, Jan 8 2013
% handles.data.SetStatusFn(@(s) SetStatusCallback(s,figureJLabel));
% handles.data.SetClearStatusFn(@() ClearStatusCallback(figureJLabel));
% 
% % % read project configuration
% % [handles,success] = LoadConfig(handles);
% % if ~success,
% %   guidata(hObject,handles);
% %   %delete(hObject);
% %   return;
% % end
% 
% handles = InitSelectionCallbacks(handles);
% 
% handles = UnsetCurrentMovie(handles);
% if (handles.data.nexps > 0 && handles.data.expi == 0) ,
%   handles = SetCurrentMovie(handles,1);
% else
%   handles = SetCurrentMovie(handles,handles.data.expi);
% end
% 
% handles = UpdateGUIToMatchGroundTruthingMode(handles);
% 
% % % keypress callback for all non-edit text objects
% % RecursiveSetKeyPressFcn(figureJLabel);
% 
% % save needed, since this is an import
% handles.data.thereIsAnOpenFile=true;
% handles.data.everythingFileNameAbs=fullfile(pwd(),'untitled.jab');
% handles.data.userHasSpecifiedEverythingFileName=false;
% handles.data.needsave=true;
% 
% % Update certain aspect of the GUI to match the current "model" state
% UpdateEnablementAndVisibilityOfControls(handles);
% 
% % OK, almost done
% set(figureJLabel,'pointer','arrow');
% 
% % Update handles structure
% guidata(figureJLabel, handles);
% 
% return


%--------------------------------------------------------------------------
function modifyFilesDone(figureJLabel,listChanged)

% get out the guidata
handles=guidata(figureJLabel);

% direct SetStatus() and ClearStatus() back to JLabel figure
handles.data.SetStatusFn(@(s) SetStatusCallback(s,figureJLabel));
handles.data.SetClearStatusFn(@() ClearStatusCallback(figureJLabel));

SetStatus(handles,sprintf('Saving changes to experiment list...'));

% % Update our copy of the default path
% handles.guidata.defaultpath = handles.data.defaultpath;

% % save needed if list has changed
% if listChanged,
%   handles.guidata.needsave=true;
% end

% Make sure the current experiment stays the same, if possible.
% All this should really happen within JLabelData... --ALT, Apr 30, 2013
oldexpdir=handles.guidata.oldexpdir;
if isempty(oldexpdir) || ~ismember(oldexpdir,handles.data.expdirs),
  % either there were no experiments before, or the old experiment is no
  % longer among the current experiment list
  SetStatus(handles,sprintf('Opening new experiment...'));
  handles = UnsetCurrentMovie(handles);
  if handles.data.nexps > 0 && handles.data.expi == 0,
    handles = SetCurrentMovie(handles,1);
  else
    handles = SetCurrentMovie(handles,handles.data.expi);
  end
  if handles.data.gtMode
    set(handles.menu_view_show_predictions,'Label','Hide Predictions');
    menu_view_show_predictions_Callback(handles.menu_view_show_predictions,[],handles);
  end
end

% Don't need this anymore, so clear it
handles.guidata.oldexpdir='';

SetStatus(handles,sprintf('Updating GUI...'));


% Update the GUI to match the current "model" state
UpdateEnablementAndVisibilityOfControls(handles);


% Set the status message back to the clear message.
ClearStatus(handles);

% write the guidata back
guidata(figureJLabel,handles);

return


%--------------------------------------------------------------------------
% function setProjectParams(figureJLabel,projectParams)
% 
% handles=guidata(figureJLabel);
% handles.guidata.configparams=projectParams;
% 
% return


% -------------------------------------------------------------------------
function menu_file_save_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_classifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
saveAs=false;
saveEverythingFile(findAncestorFigure(hObject),saveAs);
return


% -------------------------------------------------------------------------
function menu_file_save_as_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_export_classifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
saveAs=true;
saveEverythingFile(findAncestorFigure(hObject),saveAs);
return


% -------------------------------------------------------------------------
function saved=saveEverythingFile(figureJLabel,saveAs)
% Method to handle both Save and Save As...  The argument saveAs should be
% true iff the user selected Save As...  If saveAs is omitted, it defaults
% to false (i.e. it defaults to plain-old saving).

% Deal with args.
if nargin<2 || isempty(saveAs),
  saveAs=false;
end

% Do eveything else.
saved=false;  % default return
handles=guidata(figureJLabel);
%data=handles.data;  % reference
if saveAs || ~handles.data.userHasSpecifiedEverythingFileName
  windowTitle=fif(saveAs, ...
                  'Save As...', ...
                  'Save...');
  [filename,pathname] = ...
    uiputfile({'*.jab','JAABA files (*.jab)'}, ...
              windowTitle, ...
              handles.data.everythingFileNameAbs);
  if ~ischar(filename),
    % user hit cancel
    return;
  end
  fileNameAbs=fullfile(pathname,filename);
else
  fileNameAbs=handles.data.everythingFileNameAbs;
end
fileNameRel=fileNameRelFromAbs(fileNameAbs);
% save the file
try
  handles.data.saveJabFile(fileNameAbs);
catch excp
  if isequal(excp.identifier,'JLabelData:unableToCreateBackup')
    uiwait(errordlg(excp.message, ...
                    'Unable to Create Backup'));
  else
    uiwait(errordlg(sprintf('Unable to save %s.', ...
                            fileNameRel), ...
                    'Unable to Save'));
  end
  return
end
saved=true;
%handles.guidata.status_bar_text_when_clear=fileNameRel;
syncStatusBarTextWhenClear(handles);
UpdateEnablementAndVisibilityOfControls(handles);
ClearStatus(handles);
guidata(figureJLabel,handles);

return


% % -------------------------------------------------------------------------
% function saved=exportEverythingFile(figureJLabel,whatToExport)
% 
% % Figure out the filterSpec from whatToExport
% if strcmp(whatToExport,'Classifier')
%   filterSpec={'*.jcf','JAABA Classifier Files (*.jcf)'};
%   fileExtension='.jcf';
% elseif strcmp(whatToExport,'Labels')
%   filterSpec={'*.jlb','JAABA Label Files (*.jlb)'};
%   fileExtension='.jlb';
% end
% 
% % Figure out the suggested file name
% handles=guidata(figureJLabel);
% everythingFileNameAbs=handles.data.everythingFileNameAbs;
% [dirName,fileBaseName]=fileparts(everythingFileNameAbs);
% suggestedFileNameAbs=fullfile(dirName,[fileBaseName fileExtension]);
% 
% % Do eveything else.
% saved=false;  % default return
% %data=handles.data;  % reference
% windowTitle=sprintf('Export %s...',whatToExport);
% [filename,pathname] = ...
%   uiputfile(filterSpec, ...
%             windowTitle, ...
%             suggestedFileNameAbs);
% if ~ischar(filename),
%   % user hit cancel
%   return;
% end
% fileNameAbs=fullfile(pathname,filename);
% fileNameRel=fileNameRelFromAbs(fileNameAbs);
% handles=guidata(figureJLabel);
% SetStatus(handles,sprintf('Exporting to %s...',fileNameAbs));
% % Extract the structure that will be saved in the everything file
% s=handles.guidata.getMacguffin();  %#ok
% % write the everything structure to disk
% try
%   save('-mat',fileNameAbs,'-struct','s');
% catch  %#ok
%   uiwait(errordlg(sprintf('Unable to save %s.', ...
%                           fileNameRel), ...
%                   'Unable to Save'));
%   ClearStatus(handles);
%   return;
% end
% saved=true;
% UpdateEnablementAndVisibilityOfControls(handles);
% ClearStatus(handles);
% guidata(figureJLabel,handles);
% 
% return


% % -------------------------------------------------------------------------
% function saved=exportClassifierFile(figureJLabel)
% 
% % Set these things
% filterSpec={'*.jcf','JAABA Classifier Files (*.jcf)'};
% fileExtension='.jcf';
% 
% % Figure out the suggested file name
% handles=guidata(figureJLabel);
% everythingFileNameAbs=handles.guidata.everythingFileNameAbs;
% [dirName,fileBaseName]=fileparts(everythingFileNameAbs);
% suggestedFileNameAbs=fullfile(dirName,[fileBaseName fileExtension]);
% 
% % Do eveything else.
% saved=false;  % default return
% %data=handles.data;  % reference
% windowTitle=sprintf('Export Classifier...');
% [filename,pathname] = ...
%   uiputfile(filterSpec, ...
%             windowTitle, ...
%             suggestedFileNameAbs);
% if ~ischar(filename),
%   % user hit cancel
%   return;
% end
% fileNameAbs=fullfile(pathname,filename);
% fileNameRel=fileNameRelFromAbs(fileNameAbs);
% handles=guidata(figureJLabel);
% SetStatus(handles,sprintf('Exporting to %s...',fileNameAbs));
% % Extract the structure that will be saved in the file
% classifier=handles.data.getClassifier();  %#ok
% % write the classifier structure to disk
% try
%   save('-mat',fileNameAbs,'-struct','classifier');
% catch  %#ok
%   uiwait(errordlg(sprintf('Unable to save %s.', ...
%                           fileNameRel), ...
%                   'Unable to Save'));
%   ClearStatus(handles);
%   return;
% end
% saved=true;
% UpdateGUIToMatchFileAndExperimentState(handles);
% ClearStatus(handles);
% guidata(figureJLabel,handles);
% 
% return


% -------------------------------------------------------------------------
function menu_file_open_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
openEverythingFileViaChooser(findAncestorFigure(hObject),false);  % false means labeling mode
return


% -------------------------------------------------------------------------
function menu_file_open_in_ground_truthing_mode_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_open (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
openEverythingFileViaChooser(findAncestorFigure(hObject),true);  % true means ground-truthing mode
return


% -------------------------------------------------------------------------
function openEverythingFileViaChooser(figureJLabel,groundTruthingMode)

% Prompt user for filename
handles=guidata(figureJLabel);
defaultPath=handles.data.defaultpath;
title=fif(groundTruthingMode, ...
          'Open in Ground-Truthing Mode...', ...
          'Open...');
if ispc,
  pause(1);
end
[filename,pathname] = ...
  uigetfile({'*.jab','JAABA Files (*.jab)'}, ...
            title, ...
            defaultPath);
if ~ischar(filename),
  % user hit cancel
  return;
end
fileNameAbs=fullfile(pathname,filename);

% Call the function that does the real work
openEverythingFileGivenFileNameAbs(figureJLabel,fileNameAbs,groundTruthingMode)

if handles.data.nexps == 0,

  drawnow;
  JModifyFiles('figureJLabel',handles.figure_JLabel);
  
end

% Set the jump type to be ground truth suggestions for gtmode
if handles.data.IsGTMode
  handles.guidata.NJObj.SetCurrentType('Ground Truth Suggestions');
end


return


% -------------------------------------------------------------------------
function openEverythingFileGivenFileNameAbs(figureJLabel,fileNameAbs,groundTruthingMode)

% get handles
handles=guidata(figureJLabel);

% get just the relative file name
[~,baseName,ext]=fileparts(fileNameAbs);
fileNameRel=[baseName ext];

% Update the status, change the pointer to the watch
SetStatus(handles,sprintf('Opening %s...',fileNameRel));

% Don't want to see "No experiment loaded" when status is cleared!
originalClearStatusText=handles.guidata.status_bar_text_when_clear;
handles.guidata.status_bar_text_when_clear='';
guidata(figureJLabel,handles);  % sync the guidata to handles

% load the file
% This is a loop because we try, then if we fail b/c an exp dir is missing,
% we prompt the user to locate it, then try again, etc, etc.
successfullyOpened=false;
openCancelled=false;
keepTrying=true;
findinrootdir = false;
originalExpDirs=cell(0,1); 
substituteExpDirs=cell(0,1);
rootdir = '';
while ~successfullyOpened && keepTrying ,
  try
    handles.data.openJabFile(fileNameAbs, ...
                             groundTruthingMode, ...
                             originalExpDirs, ...
                             substituteExpDirs);
    successfullyOpened=true;
  catch excp
    %ClearStatus(handles);
    if isequal(excp.identifier,'JLabelData:expDirDoesNotExist') ,
      originalExpDir=excp.message;
      originalExpName=fileNameRelFromAbs(originalExpDir);
      if findinrootdir && ~isempty(findMatchingFolder(rootdir,originalExpName));
        
        originalExpDirs{end+1} = originalExpDir; %#ok<AGROW>
        substituteExpDirs{end+1} = findMatchingFolder(rootdir,originalExpName); %#ok<AGROW>
        
      else
        
        answer=questdlg(sprintf('Unable to open experiment directory %s.  Would you like to locate it manually?',originalExpName), ...
          'Unable to Open', ...
          'Yes, Locate It','No, Leave It Out and Discard All Labels For It','Cancel File Open', ...
          'Yes, Locate It');
        if isempty(answer) || isequal(answer,'Cancel File Open')
          keepTrying=false;
          openCancelled=true;
        elseif isequal(answer,'No, Leave It Out and Discard All Labels For It')
          substituteExpDir='';  % Means to leave it out
          originalExpDirs{end+1}=originalExpDir;  %#ok
          substituteExpDirs{end+1}=substituteExpDir;  %#ok
          
        else % Answer was 'Yes, Locate It'

          fanswer=questdlg(sprintf('Locate just %s or others?',originalExpName), ...
            'Locate directories', ...
            'Locate just this experiment','Locate this and others in a rootdir','Cancel File Open', ...
            'Locate just this experiment');
          if isempty(answer) || isequal(answer,'Cancel File Open')
            keepTrying=false;
            openCancelled=true;
            
          elseif isequal(fanswer,'Locate this and others in a rootdir')
            findinrootdir = true;
            rootdir= ...
              uigetdir(handles.data.expdefaultpath, ...
              'Locate Root dir to find Experiment Directories');
            
            if isempty(rootdir)
              % means user hit Cancel button
              keepTrying=false;
            end

            if ~isempty(findMatchingFolder(rootdir,originalExpName))
              originalExpDirs{end+1} = originalExpDir; %#ok<AGROW>
              substituteExpDirs{end+1} = findMatchingFolder(rootdir,originalExpName); %#ok<AGROW>
            end
            
          else
            
            [~,dname,~] = fileparts(originalExpName);
            substituteExpDir= ...
              uigetdir(handles.data.expdefaultpath, ...
              sprintf('Locate Experiment Directory %s',dname));
            if isempty(substituteExpDir)
              % means user hit Cancel button
              keepTrying=false;
            else
              originalExpDirs{end+1}=originalExpDir;  %#ok
              substituteExpDirs{end+1}=substituteExpDir;  %#ok
            end
          end
        end
      end % rootdir
    else
      message=getReport(excp,'extended','hyperlinks','off');
      keepTrying=false;
    end  % if
  end  % try/catch
end  % while
if ~successfullyOpened ,
  if ~openCancelled ,
    uiwait(errordlg(message,'Error','modal'));
  end
  handles.guidata.status_bar_text_when_clear=originalClearStatusText;
  ClearStatus(handles);
  return
end
% If we get here then the JLabelData object has successfully opened the
% .jab file

% First set the project parameters, which will initialize the JLabelData
%basicParams=basicParamsFromMacguffin(everythingParams);
%initBasicParams(figureJLabel,basicParams,groundTruthingMode);
initAfterBasicParamsSet(figureJLabel);
handles=guidata(figureJLabel);  % make sure handles is up-to-date

% Need to set the labeling mode in the JLabelData, before the experiments 
% are loaded.
data=handles.data;  % ref
%data.SetGTMode(groundTruthingMode);

% Set the GUI to match the labeling mode
%handles.guidata.GUIGroundTruthingMode=groundTruthingMode;
handles = UpdateGUIToMatchGroundTruthingMode(handles);
%handles = setGUIGroundTruthingMode(handles,groundTruthingMode);
guidata(figureJLabel,handles);  % write the handles back to the figure

% % Load the labels and classifier
% data.setAllLabels(everythingParams);
% data.setScoreFeatures(everythingParams.scoreFeatures);
% data.setWindowFeaturesParams(everythingParams.windowFeaturesParams);
% data.setClassifier(everythingParams.classifier);

% Set the functions that end up getting called when we call SetStatus()
% and ClearStatus()
% handles.data.SetStatusFn(@(s) SetStatusCallback(s,figureJLabel));
% handles.data.SetClearStatusFn(@() ClearStatusCallback(figureJLabel));

% % Copy the default path out of the JLabelData.
% handles.guidata.defaultpath = handles.data.defaultpath;

% % Note that there is currently an open file, and note its name
% handles.guidata.thereIsAnOpenFile=true;
% handles.guidata.everythingFileNameAbs=fileNameAbs;
% handles.guidata.userHasSpecifiedEverythingFileName=true;
% handles.guidata.needsave=false;

% Set the current movie.
handles = UnsetCurrentMovie(handles);
if data.nexps > 0 && data.expi == 0,
  handles = SetCurrentMovie(handles,1);
else
  handles = SetCurrentMovie(handles,data.expi);
end

% clear the old experiment directory
handles.guidata.oldexpdir='';

% Updates the graphics objects to match the current labeling mode (normal
% or ground-truthing)
handles = UpdateGUIToMatchGroundTruthingMode(handles);

% Update the GUI match the current "model" state
UpdateEnablementAndVisibilityOfControls(handles);

% Done, set status message to cleared message, pointer to normal
%fileNameRel=fileNameRelFromAbs(fileNameAbs);
%handles.guidata.status_bar_text_when_clear=fileNameRel;
syncStatusBarTextWhenClear(handles);
ClearStatus(handles);

% write the handles back to figure
guidata(figureJLabel,handles);

return


% % -------------------------------------------------------------------------
% function setProjectFileName(figureJLabel,configFileName)
% % Initializes the JLabel gui once the user selects the behavior.
% % This assumes that JLabel is curently a blank slate
% handles=guidata(figureJLabel);
% handles.guidata.configfilename = configFileName;  % should go away eventually...
% [~,~,ext] = fileparts(configFileName);
% if strcmp(ext,'.xml')
%   projectParams = ReadXMLConfigParams(configFileName);
% elseif strcmp(ext,'.mat')
%   projectParams = load(configFileName);
% else
%   errordlg('Project file is not valid');
% end
% setProjectParams(figureJLabel,projectParams);
% return


% % -------------------------------------------------------------------------
% function initBasicParams(figureJLabel,basicParams,groundTruthingMode)
% % Initializes the JLabel GUI on return from ProjectSetup after the user
% % selects New..., or during opening of an existing everything file.
% handles=guidata(figureJLabel);
% handles.guidata.setLayout(figureJLabel);
% handles=InitializeStateGivenBasicParams(handles,basicParams,groundTruthingMode);
% handles=InitializePlotsAfterBasicParamsSet2(handles);
% guidata(figureJLabel,handles);
% return


% -------------------------------------------------------------------------
function initAfterBasicParamsSet(figureJLabel)
% Initializes the JLabel GUI on return from ProjectSetup after the user
% selects New..., or during opening of an existing everything file.
handles=guidata(figureJLabel);
handles.guidata.initializeAfterBasicParamsSet();                               
handles.guidata.setLayout(figureJLabel);
handles=InitializeStateAfterBasicParamsSet(handles);
handles=InitializePlotsAfterBasicParamsSet(handles);
handles = updatePanelPositions(handles);
guidata(figureJLabel,handles);
return


% % -------------------------------------------------------------------------
% function setBasicParams(figureJLabel,basicParams,featureConfigParams)
% % Sets the basic parameters on return from ProjectSetup after the user
% % selects Basic Settings...
% handles=guidata(figureJLabel);
% %handles=StoreGUIPositionsInternally(handles);
% data=handles.data;  % a ref
% data.setBasicParams(basicParams,featureConfigParams);
% %handles=InitializeStateGivenBasicParams(handles,basicParams,featureConfigParams);
% %handles=InitializePlotsAfterBasicParamsSet2(handles);
% %guidata(figureJLabel,handles);
% 
% return


% -------------------------------------------------------------------------
% function setLabelingMode(figureJLabel,modeString)
% handles=guidata(figureJLabel);
% data=handles.data;  % a ref, or empty
% if isempty(data)
%   error('JLabel.dataIsEmpty','JLabel data is currently empty');  %#ok
% else
%   switch modeString,
%     case 'Advanced',
%       data.SetAdvancedMode(true);
%       data.SetGTMode(false);
%     case 'Normal'
%       data.SetAdvancedMode(false);
%       data.SetGTMode(false);
%     case 'Ground Truthing',
%       data.SetAdvancedMode(false);
%       data.SetGTMode(true);
%     case 'Ground Truthing Advanced',
%       data.SetAdvancedMode(true);
%       data.SetGTMode(true);
%   end 
%   data.SetMode();
% end
% 
% return


% -------------------------------------------------------------------------
function data=getJLabelData(figureJLabel)

handles=guidata(figureJLabel);
data=handles.data;

return


% -------------------------------------------------------------------------
function maxWindowRadiusCommon=getMaxWindowRadiusCommonCached(figureJLabel)

handles=guidata(figureJLabel);
maxWindowRadiusCommon=handles.guidata.maxWindowRadiusCommonCached;

return


% -------------------------------------------------------------------------
function setMaxWindowRadiusCommonCached(figureJLabel,maxWindowRadiusCommon)

handles=guidata(figureJLabel);
handles.guidata.maxWindowRadiusCommonCached=maxWindowRadiusCommon;

return


% % -------------------------------------------------------------------------
% function configfilename=getConfigFileName(figureJLabel)
% 
% handles=guidata(figureJLabel);
% configfilename=handles.guidata.configfilename;
% 
% return


% % -------------------------------------------------------------------------
% function previousConfigFileName=getPreviousConfigFileName(figureJLabel)
% 
% handles=guidata(figureJLabel);
% previousConfigFileName=handles.guidata.previousConfigFileName;
% 
% return


% % -------------------------------------------------------------------------
% function menu_edit_normal_mode_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_edit_normal_mode (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% handles.data.SetGTMode(false);
% handles.guidata.GUIGroundTruthingMode=false;
% handles = UpdateGUIToMatchGroundTruthingMode(handles);
% guidata(hObject,handles);
% 
% return


% % -------------------------------------------------------------------------
% function menu_edit_ground_truthing_mode_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_edit_ground_truthing_mode (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% handles.data.SetGTMode(true);
% handles.guidata.GUIGroundTruthingMode=true;
% handles = UpdateGUIToMatchGroundTruthingMode(handles);
% guidata(hObject,handles);
% 
% return


% -------------------------------------------------------------------------
function menu_edit_basic_mode_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_basic_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%handles = setGUIAdvancedMode(handles,false);
handles.guidata.GUIAdvancedMode=false;
handles=UpdateGUIToMatchAdvancedMode(handles);
guidata(hObject,handles);

return


% -------------------------------------------------------------------------
function menu_edit_advanced_mode_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_advanced_mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%handles = setGUIAdvancedMode(handles,true);
handles.guidata.GUIAdvancedMode=true;
handles=UpdateGUIToMatchAdvancedMode(handles);
guidata(hObject,handles);

return


% -------------------------------------------------------------------------
function ret=isBasicMode(figureJLabel)
handles=guidata(figureJLabel);
ret=~handles.guidata.GUIAdvancedMode;
return


% -------------------------------------------------------------------------
function ret=isAdvancedMode(figureJLabel)
handles=guidata(figureJLabel);
ret=handles.guidata.GUIAdvancedMode;
return


% -------------------------------------------------------------------------
function ret=isLabelingMode(figureJLabel)
handles=guidata(figureJLabel);
data=handles.data;
if isempty(data) ,
  ret=[];
else
  ret=~data.gtMode;
end
return


% -------------------------------------------------------------------------
function ret=isGroundTruthingMode(figureJLabel)
handles=guidata(figureJLabel);
data=handles.data;
if isempty(data) ,
  ret=[];
else
  ret=data.gtMode;
end
return


% -------------------------------------------------------------------------

% function modesString=getModesString(figureJLabel)
% 
% if isGroundTruthingMode(figureJLabel),
%   if isAdvancedMode(figureJLabel),
%     modesString = 'Ground Truthing Advanced';
%   else
%     modesString = 'Ground Truthing';
%   end
% else
%   if isAdvancedMode(figureJLabel),
%     modesString = 'Labeling Advanced';
%   else
%     modesString = 'Labeling Basic';
%   end
% end  
% 
% return


% % -------------------------------------------------------------------------
% function setGroundTruthingMode(figureJLabel,groundTruthingMode)
% % Intended to be called by other "objects" (like JLabelEditFiles) when
% % they was to set the labeling mode in JLabel, and thereby in the
% % single JLabelData object, if present.
% handles=guidata(figureJLabel);
% % Tell the data about the new mode
% data=handles.data;  % ref
% data.SetGTMode(groundTruthingMode);
% handles.guidata.GUIGroundTruthingMode=groundTruthingMode;
% handles = UpdateGUIToMatchGroundTruthingMode(handles);
% guidata(figureJLabel,handles);  % write the handles back to the figure
% return


% --------------------------------------------------------------------
function menu_file_close_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Release the thread cache
for i=1:length(handles.guidata.cache_thread)
  delete(handles.guidata.cache_thread{i});
end
handles.guidata.cache_thread = [];
UpdatePlots(handles,'CLEAR');
%clear functions  % BJA: need to clear persistent vars in UpdatePlots
if ispc, pause(.1); end
if isfield(handles.guidata,'cachefilename') & exist(handles.guidata.cachefilename,'file'),
  delete(handles.guidata.cachefilename);
end

% Check if we need to save.
proceed=checkForUnsavedChangesAndDealIfNeeded(hObject);
if ~proceed,
  return;
end
handles = guidata(hObject);  % re-load handles, may have changed

% % Check if any of the project things have changed, and if so, see if user
% % wants to save.  (How should this work in the context of the everything
% % files?)
% if ~isempty(handles.data) && handles.data.NeedSaveProject(),
%   res = questdlg(['Current window features do not match the ones in the project file.'...
%       'Update the project file with the current window features?'],...
%       'Update?','Yes','No','Cancel','Yes');
%   if strcmpi(res,'Yes')
%     menu_file_save_project_Callback(hObject,eventdata,handles);
%   elseif strcmpi(res,'Cancel');
%     return;
%   end    
% end  

% Unset the current movie
handles=UnsetCurrentMovie(handles);
UpdateEnablementAndVisibilityOfControls(handles);

% Close any open movie files
if ~isempty(handles.guidata.movie_fid) && ...
    handles.guidata.movie_fid > 1 && ...
    ~isempty(fopen(handles.guidata.movie_fid)),
  fclose(handles.guidata.movie_fid);
  handles.guidata.movie_fid = [];
end

% Turn off zooming
zoom(handles.figure_JLabel,'off');

% Close any open peripherals
for ndx = 1:numel(handles.guidata.open_peripherals)
  if ishandle(handles.guidata.open_peripherals(ndx)),
    delete(handles.guidata.open_peripherals(ndx));
  end
end

% delete whatever is in the various axes
delete(get(handles.axes_preview,'children'));
delete(get(handles.axes_timeline_manual,'children'));
delete(get(handles.axes_timeline_auto,'children'));
valid_props = ishandle(handles.axes_timeline_prop1);
delete(get(handles.axes_timeline_prop1(valid_props),'children'));

% % Release the JLabelData
% if ~isempty(handles.data)
%   handles.data=[];
% end

% Close the .jab file in JLabelData
handles.data.closeJabFile();

% % save things we want to reinstate
% in_border_y=handles.guidata.in_border_y;

% % delete graphics objects that were created on the fly
% buttons=handles.guidata.togglebutton_label_behaviors(2:end);
% delete(buttons(ishandle(buttons)));
% %panels=handles.guidata.panel_previews;
% %delete(panels(ishandle(panels)));

% % Release and re-generate handles.guidata, to make sure it's fresh
% handles.guidata=[];
% handles.guidata = JLabelGUIData();
% handles.guidata.UpdateGraphicsHandleArrays(findAncestorFigure(hObject));

% % init stuff
% handles.output = handles.figure_JLabel;
% handles.guidata.classifierfilename='';
% handles.guidata.configfilename='';
% handles.guidata.defaultpath='';
% %handles.guidata.hsplash=[];
% %handles.guidata.hsplashstatus=[];
% handles.guidata.status_bar_text_when_clear = sprintf('Status: No experiment loaded');
% handles.guidata.idlestatuscolor = [0,1,0];
% handles.guidata.busystatuscolor = [1,0,1];
% handles.guidata.movie_height = 100;
% handles.guidata.movie_width = 100;
% handles.guidata.movie_depth = 1;
% handles.guidata.tempname = tempname();
% ClearStatus(handles);

% % save the window state
% guidata(hObject,handles);

% % Update the arrays of graphics handles (grandles) within the figure's guidata
% handles.guidata.UpdateGraphicsHandleArrays(hObject);
% 
% % Get some figure dimensions useful when we need to redo the layout
% handles.guidata.in_border_y = in_border_y;

% % Create the label buttons
% handles=guidata(hObject);
% handles = UpdateLabelButtons(handles);
% guidata(hObject,handles);

% % Note that there is currently no open file.
% handles.guidata.thereIsAnOpenFile=false;
% % these next three aren't strictly necessary
% handles.guidata.everythingFileNameAbs='';
% handles.guidata.userHasSpecifiedEverythingFileName=false;
% handles.guidata.needsave=false;

% Set the GT state back to "none"
%handles.guidata.GUIGroundTruthingMode=[];
UpdateGUIToMatchGroundTruthingMode(handles);

% Update the GUI to match the current "model" state
%handles=guidata(hObject);
UpdateEnablementAndVisibilityOfControls(handles);

% Clear the current fly info
set(handles.text_selection_info,'string','');

% Set the clear status message
%handles.guidata.status_bar_text_when_clear='No file open.';
syncStatusBarTextWhenClear(handles);
ClearStatus(handles);

% Write the handles to the guidata
guidata(hObject,handles);

res = JAABAInitOpen(handles.figure_JLabel);

if ~isempty(res.val)
  if ~res.edit
    switch res.val,
      case 'New',
        newEverythingFile(handles.figure_JLabel);
      case 'Open',
        openEverythingFileViaChooser(findAncestorFigure(hObject),false); % false means labeling mode
      case 'OpenGT',
        openEverythingFileViaChooser(findAncestorFigure(hObject),true);  % true means ground-truthing mode
    end
  else
    switch res.val,
      case 'New',
        newEverythingFile(handles.figure_JLabel);
      case 'Open',
        editEverythingFileViaChooser(findAncestorFigure(hObject),false); % false means labeling mode
      case 'OpenGT',
        editEverythingFileViaChooser(findAncestorFigure(hObject),true);  % true means ground-truthing mode
    end
  end
end

return


% --------------------------------------------------------------------
function menu_file_new_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_new (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
newEverythingFile(hObject);
return


% -------------------------------------------------------------------------
function newEverythingFile(figureJLabel)

% get handles
handles=guidata(figureJLabel);

% launch the project setup GUI
uiwait(ProjectSetup('figureJLabel',handles.figure_JLabel,...
  'defaultmoviefilename',handles.guidata.defaultmoviefilename,...
  'defaulttrxfilename',handles.guidata.defaulttrxfilename));

% no experiments? ask to add
if handles.data.nexps == 0,

  drawnow;
  JModifyFiles('figureJLabel',handles.figure_JLabel);
  
end
  
           
return


% -------------------------------------------------------------------------
function editEverythingFileViaChooser(figureJLabel,groundTruthingMode)

% Prompt user for filename
handles=guidata(figureJLabel);
defaultPath=handles.data.defaultpath;
title=fif(groundTruthingMode, ...
          'Open in Ground-Truthing Mode...', ...
          'Open...');
if ispc,
  pause(1);
end
[filename,pathname] = ...
  uigetfile({'*.jab','JAABA Files (*.jab)'}, ...
            title, ...
            defaultPath);
if ~ischar(filename),
  % user hit cancel
  return;
end
fileNameAbs=fullfile(pathname,filename);

try 
  Q = load(fileNameAbs,'-mat');
catch ME,
  warndlg('Could not read the jab file');
  return;
end

% launch the project setup GUI
uiwait(ProjectSetup('figureJLabel',handles.figure_JLabel,...
  'defaultmoviefilename',handles.guidata.defaultmoviefilename,...
  'defaulttrxfilename',handles.guidata.defaulttrxfilename,...
  'basicParamsStruct',Q.x));

% no experiments? ask to add
if handles.data.nexps == 0,

  drawnow;
  JModifyFiles('figureJLabel',handles.figure_JLabel);
  
end

return


% -------------------------------------------------------------------------
function newFileSetupDone(figureJLabel,basicParams)
% Called by ProjectSetup after the user clicks Done.  Causes the JLabel
% "object" to set itself up for a new file, using the settings in
% basicParams, which is a Macguffin.

% get handles
handles=guidata(figureJLabel);

% % Make up filename
% try
%   behaviorName=basicParams.getMainBehaviorName();
%   fileNameRel=sprintf('%s.jab',behaviorName);
% catch excp
%   if isequal(excp.identifier,'Macguffin:mainBehaviorNotDefined')
%     fileNameRel='untitled.jab';
%   else
%     rethrow(excp);
%   end
% end  
% fileNameAbs=fullfile(pwd(),fileNameRel);

% % Update the status, change the pointer to the watch
% SetStatus(handles,sprintf('Opening %s ...',filename));

% Don't want to see "No experiment loaded" when status is cleared!
handles.guidata.status_bar_text_when_clear='';
guidata(figureJLabel,handles);  % sync the guidata to handles

% Set up the model for a new file
handles.data.newJabFile(basicParams);

% % First set the project parameters, which will initialize the JLabelData
% groundTruthingMode=false;  % all new files start in labeling mode
% %initBasicParams(figureJLabel,basicParams,groundTruthingMode);
% handles.guidata.initializeGivenMacguffin(basicParams, ...
%                                          figureJLabel, ...
%                                          groundTruthingMode, ...
%                                          @(s)SetStatusCallback(s,figureJLabel) , ...
%                                          @()ClearStatusCallback(figureJLabel) );

%handles.guidata.initializeAfterBasicParamsSet();                               
initAfterBasicParamsSet(figureJLabel);
handles=guidata(figureJLabel);  % make sure handles is up-to-date

% Don't want to type "handles.data" all the damn time
data=handles.data;  % ref
%data.SetGTMode(groundTruthingMode);

% Set the GUI to match the labeling mode
%handles.guidata.GUIGroundTruthingMode=groundTruthingMode;
handles = UpdateGUIToMatchGroundTruthingMode(handles);
guidata(figureJLabel,handles);  % write the handles back to the figure

% % Now load the classifier, which includes the experiments, and load the
% % labels also.  ('classifierlabels',true means to load the labels, too.)
% data.setClassifierParams(everythingParams.saveableClassifier, ...
%                          'classifierlabels',true);

% Set the functions that end up getting called when we call SetStatus()
% and ClearStatus()
% handles.data.SetStatusFn(@(s) SetStatusCallback(s,figureJLabel));
% handles.data.SetClearStatusFn(@() ClearStatusCallback(figureJLabel));

% % Copy the default path out of the JLabelData.
% handles.guidata.defaultpath = handles.data.defaultpath;

% Set the current movie.
handles = UnsetCurrentMovie(handles);
if data.nexps > 0 && data.expi == 0,
  handles = SetCurrentMovie(handles,1);
else
  handles = SetCurrentMovie(handles,data.expi);
end

% clear the old experiment directory
handles.guidata.oldexpdir='';

% % Note that there is currently an open file, and note its name
% handles.guidata.thereIsAnOpenFile=true;
% handles.guidata.everythingFileNameAbs=fileNameAbs;
% handles.guidata.userHasSpecifiedEverythingFileName=false;
% handles.guidata.needsave=true;

% Updates the graphics objects to match the current labeling mode (normal
% or ground-truthing)
handles = UpdateGUIToMatchGroundTruthingMode(handles);

% Update the GUI match the current "model" state
UpdateEnablementAndVisibilityOfControls(handles);

% Done, set status message to cleared message, pointer to normal
%fileNameRel=fileNameRelFromAbs(fileNameAbs);
%handles.guidata.status_bar_text_when_clear=fileNameRel;
syncStatusBarTextWhenClear(handles);
ClearStatus(handles);

% write the handles back to figure
guidata(figureJLabel,handles);

return


% % -------------------------------------------------------------------------
% function basicSettingsChanged(figureJLabel,basicParams)
% 
% % get handles
% handles=guidata(figureJLabel);
% data=handles.data;  % a ref
% 
% % Set the functions that end up getting called when we call SetStatus()
% % and ClearStatus()
% data.SetStatusFn(@(s) SetStatusCallback(s,figureJLabel));
% data.SetClearStatusFn(@() ClearStatusCallback(figureJLabel));
% 
% % Set the feature dictionary, basic params in JLabelData
% [success,msg]=data.setBasicParams(basicParams);
% if ~success,
%   uiwait(errordlg(msg,'Error Setting Basic Parameters','modal'));
% end
% 
% % % Re-load the perframe feature signals, since the PFFs may have changed
% % data should take of this itself
% % data.loadPerframeData(data.expi,data.flies);
% 
% % Set the GUI to match the labeling mode
% % Main point of this is to set the proper behavior names on the 
% % labeling buttons.
% handles = UpdateLabelButtons(handles);
% %handles = UpdateGUIToMatchGroundTruthingMode(handles);
% guidata(figureJLabel,handles);  % write the handles back to the figure
% 
% % Note that we now need saving
% handles.data.needsave=true;
% 
% % Done, set status message to cleared message, pointer to normal
% syncStatusBarTextWhenClear(handles);
% ClearStatus(handles);
% 
% % write the handles back to figure
% guidata(figureJLabel,handles);
% 
% return


% % --------------------------------------------------------------------
% function menu_file_import_old_style_project_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_file_import_old_style_project (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% importOldStyleProject(hObject)
% return
% 
% 
% % --------------------------------------------------------------------
% function importOldStyleProject(figureJLabel)
% 
% % get handles
% handles=guidata(figureJLabel);
% 
% % Prompt user for filename
% title='Import Old-Style Project...';
% 
% [filename,pathname] = ...
%   uigetfile({'*.mat','JAABA Old-Style Project Files (*.mat)'}, ...
%             title);
% if ~ischar(filename),
%   % user hit cancel
%   return;
% end
% projectFileNameAbs=fullfile(pathname,filename);
% 
% % Update the status, change the pointer to the watch
% SetStatus(handles,sprintf('Opening %s ...',filename));
% 
% % load the file
% try
%   projectParamsWithFeatureConfigFileName=load('-mat',projectFileNameAbs);
% catch  %#ok
%   uiwait(errordlg(sprintf('Unable to load %s.',filename),'Error'));
%   ClearStatus(handles);
%   return;
% end
% 
% % Don't want to see "No experiment loaded" when status is cleared!
% handles.guidata.status_bar_text_when_clear='';
% guidata(figureJLabel,handles);  % sync the guidata to handles
% 
% % Get the feature config file name
% featureConfigFileName=projectParamsWithFeatureConfigFileName.file.featureconfigfile;
% 
% % remove feature config file name from the project params
% projectParams=projectParamsWithFeatureConfigFileName;
% projectParams.file=rmfield(projectParams.file,'featureconfigfile');
% 
% % read the feature config file
% featureConfigFileNameAbs = deployedRelative2Global(featureConfigFileName);
% featureConfigParams = ReadXMLParams(featureConfigFileNameAbs);
% 
% % First set the project parameters, which will initialize the JLabelData
% setProjectParams(findAncestorFigure(hObject),projectParams,featureConfigParams);
% handles=guidata(figureJLabel);  % make sure handles is up-to-date
% 
% % Need to set the labeling mode in the JLabelData, before the experiments 
% % are loaded.
% groundTruthingMode=false;  % Always start in normal mode on import
% data=handles.data;  % ref
% data.SetGTMode(groundTruthingMode);
% 
% % Set the GUI to match the labeling mode
% handles.guidata.GUIGroundTruthingMode=groundTruthingMode;
% handles = UpdateGUIToMatchGroundTruthingMode(handles);
% %handles = setGUIGroundTruthingMode(handles,groundTruthingMode);
% guidata(figureJLabel,handles);  % write the handles back to the figure
% 
% % Don't load the classifier, b/c there isn't one yet
% % % Now load the classifier, which includes the experiments, and load the
% % % labels also.  ('classifierlabels',true means to load the labels, too.)
% % data.setClassifierParams(everythingParams.saveableClassifier, ...
% %                          'classifierlabels',true);
% 
% % Set the functions that end up getting called when we call SetStatus()
% % and ClearStatus()
% handles.data.SetStatusFn(@(s) SetStatusCallback(s,figureJLabel));
% handles.data.SetClearStatusFn(@() ClearStatusCallback(figureJLabel));
% 
% % Copy the default path out of the JLabelData.
% handles.guidata.defaultpath = handles.data.defaultpath;
% 
% % Set the current movie.
% handles = UnsetCurrentMovie(handles);
% if handles.data.nexps > 0 && handles.data.expi == 0,
%   handles = SetCurrentMovie(handles,1);
% else
%   handles = SetCurrentMovie(handles,handles.data.expi);
% end
% 
% % clear the old experiment directory
% handles.guidata.oldexpdir='';
% 
% % Make up a file name for the everything file
% path=fileparts(projectFileNameAbs);
% fileNameRel='untitled.jab';
% fileNameAbs=fullfile(path,fileNameRel);
% 
% % Note that there is currently an open file, and note its name
% handles.guidata.thereIsAnOpenFile=true;
% handles.guidata.everythingFileNameAbs=fileNameAbs;
% handles.guidata.userHasSpecifiedEverythingFileName=false;
% handles.guidata.needsave=true;
% 
% % Updates the graphics objects to match the current labeling mode (normal
% % or ground-truthing)
% handles = UpdateGUIToMatchGroundTruthingMode(handles);
% 
% % Update the GUI match the current "model" state
% UpdateGUIToMatchFileAndExperimentState(handles);
% 
% % Done, set status message to cleared message, pointer to normal
% handles.guidata.status_bar_text_when_clear=fileNameRel;
% ClearStatus(handles);
% 
% % write the handles back to figure
% guidata(figureJLabel,handles);
% 
% return
% 
% 
% % --------------------------------------------------------------------
% function menu_file_import_old_style_classifier_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_file_import_old_style_classifier (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% importOldStyleClassifier(hObject);
% return
% 
% 
% % -------------------------------------------------------------------------
% function importOldStyleClassifier(figureJLabel)
% 
% % get the handles, data
% handles = guidata(figureJLabel);
% data=handles.data;  % a ref
% 
% % Have the user choose the classifier file
% [filename,pathname] = uigetfile('*.mat','Import classifier...');
% if ~ischar(filename),
%   return;
% end
% classifierFileNameAbs = fullfile(pathname,filename);
% 
% % Ask the the user if they want both labels and classifier, or just the 
% % classifier
% res = questdlg(['Import the labels and the classifier, ' ...
%                 'or just the classifier?'], ...
%                'Import Labels?', ...
%                'Load Labels and Classifier', ...
%                'Load Classifier Only', ...
%                'Cancel', ...
%                'Load Labels and Classifier');
% if strcmpi(res,'Cancel'), return, end
% loadLabels = strcmpi(res,'Load Labels and Classifier');
% 
% % Load the classifier file
% try
%   classifierParams=load('-mat',classifierFileNameAbs);
% catch  %#ok
%   uiwait(errordlg(sprintf('Unable to load %s.',filename),'Error'));
%   ClearStatus(handles);
%   return;
% end
% 
% % Now load the classifier, which includes the experiments, and load the
% % labels also.  ('classifierlabels', if true, loads the labels also)
% data.setClassifierParamsOld(classifierParams, ...
%                             'classifierlabels',loadLabels);
% 
% % Set the functions that end up getting called when we call SetStatus()
% % and ClearStatus()
% handles.data.SetStatusFn(@(s) SetStatusCallback(s,figureJLabel));
% handles.data.SetClearStatusFn(@() ClearStatusCallback(figureJLabel));
% 
% % Copy the default path out of the JLabelData.
% handles.guidata.defaultpath = handles.data.defaultpath;
% 
% % Set the current movie.
% handles = UnsetCurrentMovie(handles);
% if handles.data.nexps > 0 && handles.data.expi == 0,
%   handles = SetCurrentMovie(handles,1);
% else
%   handles = SetCurrentMovie(handles,handles.data.expi);
% end
% 
% % clear the old experiment directory
% handles.guidata.oldexpdir='';
% 
% % Note that there are now unsaved changes
% handles.guidata.needsave=true;
% 
% % Updates the graphics objects to match the current labeling mode (normal
% % or ground-truthing)
% handles = UpdateGUIToMatchGroundTruthingMode(handles);
% 
% % Update the GUI match the current "model" state
% UpdateGUIToMatchFileAndExperimentState(handles);
% 
% % Done, set status message to cleared message, pointer to normal
% %fileNameAbs=handles.guidata.everythingFileNameAbs;
% %fileNameRel=fileNameRelFromAbs(fileNameAbs);
% %handles.guidata.status_bar_text_when_clear=fileNameRel;
% ClearStatus(handles);
% 
% % write the handles back to figure
% guidata(figureJLabel,handles);
% 
% return


% % ------------------------------------------------------------------------ 
% function ShowSelectFeatures(handles)
% %SetStatus('Set the window computation features...');
% SelectFeatures(handles.figure_JLabel);
% %uiwait(selHandle);
% %ClearStatus(handles);
% 
% return    


% ------------------------------------------------------------------------ 
function selectFeaturesDone(figureJLabel, ...
                            windowFeaturesParams, ...
                            maxWindowRadiusCommon)
% Called by SelectFeatures after the user clicks on "Done", tells us that
% the per-frame features may have been changed.
setMaxWindowRadiusCommonCached(figureJLabel,maxWindowRadiusCommon);
handles=guidata(figureJLabel);
handles.data.setWindowFeaturesParams(windowFeaturesParams);
% handles.data.needsave=true;  % done in data.setWindowFeaturesParams() now
UpdateTimelineImages(handles);
UpdatePlots(handles);
UpdateEnablementAndVisibilityOfControls(handles);
% someExperimentIsCurrent=handles.data.getSomeExperimentIsCurrent();
% if someExperimentIsCurrent,
%   handles = predict(handles);
% end
% guidata(figureJLabel,handles);

return


% % ------------------------------------------------------------------------ 
% function classifierParams=classifierParamsFromMacguffin(everythingParams)
% 
% fieldNamesToKeep={'classifierTS' , ...
%                   'trainingdata' , ...
%                   'expdirs' , ...
%                   'expnames' , ...
%                   'nflies_per_exp' , ...
%                   'sex_per_exp' , ...
%                   'frac_sex_per_exp' , ...
%                   'firstframes_per_exp' , ...
%                   'endframes_per_exp' , ...
%                   'classifiertype' , ...
%                   'classifier' , ...
%                   'classifier_params' , ...
%                   'confThresholds' , ...
%                   'scoreNorm' , ...
%                   'windowfeaturesparams' , ...
%                   'windowfeaturescellparams' , ...
%                   'basicFeatureTable' , ...
%                   'featureWindowSize' , ...
%                   'postprocessparams' , ...
%                   'featurenames' , ...
%                   'scoreFeatures' }';
% 
% classifierParams=struct();
% for i=1:length(fieldNamesToKeep)
%   fieldNameThis=fieldNamesToKeep{i};
%   classifierParams.(fieldNameThis)=everythingParams.(fieldNameThis);
% end
% 
% return


% --------------------------------------------------------------------
function menu_file_import_classifier_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_import_classifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
importClassifier(hObject)
return


% -------------------------------------------------------------------------
function importClassifier(figureJLabel)

% get handles
handles=guidata(figureJLabel);

% Prompt user for filename
title='Import Classifier...';
defaultPath=handles.data.defaultpath;
[filename,pathname] = ...
  uigetfile({'*.jab','JAABA Files (*.jab)'}, ...
            title, ...
            defaultPath);
if ~ischar(filename),
  % user hit cancel
  return;
end
fileNameAbs=fullfile(pathname,filename);

% Update the status, change the pointer to the watch
SetStatus(handles,sprintf('Importing classifier from %s...',filename));

% load the file
try
  handles.data.importClassifier(fileNameAbs);
catch  %#ok
  uiwait(errordlg(sprintf('Unable to import classifier from %s.',filename),'Error'));
  ClearStatus(handles);
  return;
end

% % Set the classifier in the JLabelData object
% data=handles.data;  % ref
% data.setScoreFeatures(everythingParams.scoreFeatures);
% data.setWindowFeaturesParams(everythingParams.windowFeaturesParams);
% data.setClassifierStuff(everythingParams.classifierStuff);
% 
% % Note that we now need saving
% handles.data.needsave=true;

% Not sure what this does  --ALT, March 15, 2013
handles = SetPredictedPlot(handles);

% Update the image that represents the prediction
handles = UpdateTimelineImages(handles);

% write the handles back to figure
guidata(figureJLabel,handles);

% Update the graphics objects that need updating
UpdatePlots(handles, ...
            'refreshim',false, ...
            'refreshflies',true,  ...
            'refreshtrx',true, ...
            'refreshlabels',true,...
            'refresh_timeline_manual',false,...
            'refresh_timeline_xlim',false,...
            'refresh_timeline_hcurr',false,...
            'refresh_timeline_selection',false,...
            'refresh_curr_prop',false);

% Update enablement of stuff
UpdateEnablementAndVisibilityOfControls(handles);
                    
% Done, set status message to cleared message, pointer to normal
ClearStatus(handles);

return


% --------------------------------------------------------------------
function menu_classifier_clear_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Make sure the user _really_ wants to clear the classifier
res = questdlg('Are you sure you want to clear the current classifier?', ...
               'Really Clear the Classifier?', ...
               'Clear','Cancel', ...
               'Cancel');
if strcmpi(res,'Clear'),
  proceed=true;
elseif strcmpi(res,'Cancel'),
  proceed=false;
else
  error('JLabel.internalError','Internal error.  Please report to the JAABA developers.');  %#ok
end

% Clear the classifier, if called for
if proceed ,
  clearClassifier(hObject);
end

return


% -------------------------------------------------------------------------
function clearClassifier(figureJLabel)
% Deletes the current classifier

% get handles
handles=guidata(figureJLabel);

% Update the status, change the pointer to the watch
SetStatus(handles,'Clearing classifier...');

% Clear the current classifier in the model
handles.data.clearClassifierProper();

% % Note that we now need saving (done in .clearClassifierProper())
% handles.data.needsave=true;

% Not sure what this does  --ALT, March 15, 2013
handles = SetPredictedPlot(handles);

% Update the image that represents the prediction
handles = UpdateTimelineImages(handles);

% write the handles back to figure
guidata(figureJLabel,handles);

% Update the graphics objects that need updating
UpdatePlots(handles, ...
            'refreshim',false, ...
            'refreshflies',true,  ...
            'refreshtrx',true, ...
            'refreshlabels',true,...
            'refresh_timeline_manual',false,...
            'refresh_timeline_xlim',false,...
            'refresh_timeline_hcurr',false,...
            'refresh_timeline_selection',false,...
            'refresh_curr_prop',false);

% Update the enablement, etc of controls to reflect the fact that 
% there is no classifier
UpdateEnablementAndVisibilityOfControls(handles)

% Done, set status message to cleared message, pointer to normal
ClearStatus(handles);

return


% --------------------------------------------------------------------
function menu_file_basic_settings_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_new (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
basicSettings(findAncestorFigure(hObject));
return


% -------------------------------------------------------------------------
function basicSettings(figureJLabel)

% get handles
handles=guidata(figureJLabel);

% launch the project setup GUI
basicParamsStruct=handles.data.getBasicParamsStruct();
ProjectSetup('figureJLabel',handles.figure_JLabel, ...
             'basicParams',basicParamsStruct);
           
return


% % --------------------------------------------------------------------
% function menu_file_change_target_type_Callback(hObject, eventdata, handles)
% % hObject    handle to menu_file_change_target_type (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% featureLexiconName=handles.data.featureLexiconName;
% ChangeFeatureLexiconDialog(featureLexiconName,handles.figure_JLabel);
% return


% % -------------------------------------------------------------------------
% function changeFeatureLexiconDone(figureJLabel,newFeatureLexiconName)
% 
% % get handles
% handles=guidata(figureJLabel);
% data=handles.data;  % a ref
% 
% % % if new same as old, do nothing
% % if isequal(newFeatureLexiconName,data.featureLexiconName)
% %   return
% % end
% 
% % If the user selected custom, no change is required.
% if isequal(newFeatureLexiconName,'custom')
%   return
% end
% 
% % Update the status, change the pointer to the watch
% SetStatus(handles,'Changing target type...');
% 
% % Set the feature dictionary, basic params in JLabelData
% [success,msg]=data.setFeatureLexiconAndTargetSpeciesFromFLName(newFeatureLexiconName);
% if ~success,
%   uiwait(errordlg(msg,'Error Changing Target Type','modal'));
% end
% 
% % % Note that we now need saving
% % handles.data.needsave=true;
% 
% % Update the plots
% %UpdatePlots(handles,'refresh_timeline_props',true,'refresh_timeline_selection',true);
% UpdatePlots(handles);
% 
% % Done, set status message to cleared message, pointer to normal
% syncStatusBarTextWhenClear(handles);
% ClearStatus(handles);
% 
% % write the handles back to figure
% guidata(figureJLabel,handles);
% 
% return


% --------------------------------------------------------------------
function menu_file_change_behavior_name_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_change_target_type (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

behaviorName=handles.data.getBehaviorName();
ChangeBehaviorNameDialog(behaviorName,handles.figure_JLabel);
return


% -------------------------------------------------------------------------
function changeBehaviorNameDone(figureJLabel,newBehaviorName)

% get handles
handles=guidata(figureJLabel);

% if new same as old, do nothing
data=handles.data;  % a ref
if isequal(newBehaviorName,data.getBehaviorName())
  return
end
  
% Update the status, change the pointer to the watch
SetStatus(handles,'Changing behavior name...');

% Set the behavior name in JLabelData
data.setBehaviorName(newBehaviorName);

% % Note that we now need saving
% handles.data.needsave=true;

% Update the names on the labeling buttons
handles = UpdateLabelButtons(handles);

% Update the plots
%UpdatePlots(handles,'refresh_timeline_props',true,'refresh_timeline_selection',true);
%UpdatePlots(handles);

% Done, set status message to cleared message, pointer to normal
syncStatusBarTextWhenClear(handles);
ClearStatus(handles);

% write the handles back to figure
guidata(figureJLabel,handles);

uiwait(helpdlg('You have changed the behavior name. You may want to change the score file name.','Change score file name'));

return


% --------------------------------------------------------------------
function menu_classifier_change_score_features_Callback(hObject, eventdata, handles)
% hObject    handle to menu_classifier_change_score_features (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
scoreFeaturesFileNameList={handles.data.scoreFeatures(:).classifierfile};
timeStampList=[handles.data.scoreFeatures(:).ts];
scoreBaseNameList={handles.data.scoreFeatures(:).scorefilename};
ChangeScoreFeaturesDialog(scoreFeaturesFileNameList, ...
                             timeStampList, ...
                             scoreBaseNameList, ...
                             handles.figure_JLabel);
return


% -------------------------------------------------------------------------
function changeScoreFeaturesDone(figureJLabel, ...
                                 scoreFeaturesFileNameListNew, ...
                                 timeStampListNew, ...
                                 scoreBaseNameListNew)

% get handles
handles=guidata(figureJLabel);

% if new same as old, do nothing
data=handles.data;  % a ref
scoreFeaturesFileNameList={data.scoreFeatures(:).classifierfile};
if isequal(scoreFeaturesFileNameListNew,scoreFeaturesFileNameList)
  return
end

% Update the status, change the pointer to the watch
SetStatus(handles,'Changing score features list...');

% Set the behavior name in JLabelData
try
  data.setScoreFeatures(scoreFeaturesFileNameListNew, ...
                        timeStampListNew, ...
                        scoreBaseNameListNew);
catch excp
  if isequal(excp.identifier,'JLabelData:unableToSetScoreFeatures') || ...
     isequal(excp.identifier,'JLabelData:errorGeneratingPerframeFileFromScoreFile')
    % Set status message to cleared message, pointer to normal
    syncStatusBarTextWhenClear(handles);
    ClearStatus(handles);
    uiwait(errordlg(sprintf('Unable to add score features(s): %s',excp.message), ...
                    'Error', ...
                    'modal'));
    return              
  else
    rethrow(excp);
  end
end

% % Note that we now need saving
% handles.data.needsave=true;

% Update the plots
UpdateTimelineImages(handles);

% update the list in the drop down timelines.
oldprops = handles.guidata.timeline_prop_options;
handles.guidata.timeline_prop_options = [handles.guidata.timeline_prop_options(1:2) handles.data.allperframefns(:)'];

for ndx = 1:numel(handles.guidata.axes_timeline_props)
  timelinendx = find(handles.guidata.axes_timelines == handles.guidata.axes_timeline_props(ndx),1);
  hobj = handles.guidata.labels_timelines(timelinendx);
  v = get(hobj,'Value');
  s = oldprops{v};
  if ~any(strcmpi(s,handles.data.allperframefns))
     set(hobj,'Value',3);    
  end
  set(hobj,'String',handles.guidata.timeline_prop_options);
  timeline_label_prop1_Callback(hobj,[],handles); 
end

%UpdatePlots(handles,'refresh_timeline_props',true,'refresh_timeline_selection',true);
UpdatePlots(handles);

% Update menus, etc, b/c classifier has been cleared
UpdateEnablementAndVisibilityOfControls(handles);

% Done, set status message to cleared message, pointer to normal
syncStatusBarTextWhenClear(handles);
ClearStatus(handles);

% write the handles back to figure
guidata(figureJLabel,handles);

helpdlg('Remember to add the score features in Select Features','Add score features');
return


% -------------------------------------------------------------------------
function menu_file_change_score_file_name_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_change_score_file_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

scoreFileName=handles.data.getScoreFileName();
ChangeScoreFileNameDialog(scoreFileName,handles.figure_JLabel);
return


% -------------------------------------------------------------------------
function changeScoreFileNameDone(figureJLabel,newScoreFileName)

% get handles
handles=guidata(figureJLabel);

% if new same as old, do nothing
data=handles.data;  % a ref
if isequal(newScoreFileName,data.getScoreFileName())
  return
end
  
% Update the status, change the pointer to the watch
SetStatus(handles,'Changing score file name...');

% Set the score file name in JLabelData
data.setScoreFileName(newScoreFileName);

% % Note that we now need saving
% handles.data.needsave=true;

% Update the names on the labeling buttons
handles = UpdateLabelButtons(handles);

% Update the plots
%UpdatePlots(handles,'refresh_timeline_props',true,'refresh_timeline_selection',true);
%UpdatePlots(handles);

% Done, set status message to cleared message, pointer to normal
syncStatusBarTextWhenClear(handles);
ClearStatus(handles);

% write the handles back to figure
guidata(figureJLabel,handles);

return


% -------------------------------------------------------------------------
function menu_classifier_compareFrames_Callback(hObject,eventdata,handles)
%handles = guidata(hObject);
if isempty(handles.data.expi) || handles.data.expi<1, return, end
chandles = CompareFrames('JLabelH',handles, ...
                         'expnum',handles.data.expi,...
                         'fly',handles.data.flies, ...
                         't',handles.guidata.ts);
handles.guidata.open_peripherals(end+1) = chandles;
return


% --------------------------------------------------------------------
function menu_file_remove_experiments_with_no_labels_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_remove_experiments_with_no_labels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
removeExperimentsWithNoLabels(handles.figure_JLabel);
return


% -------------------------------------------------------------------------
function removeExperimentsWithNoLabels(figureJLabel)
handles=guidata(figureJLabel);
data=handles.data;  % a ref
% Save the current exp dir name
iExp=data.expi;
currentExpDirName=data.expdirs{iExp};
% Tell the model to remove experiments with no labels
data.removeExperimentsWithNoLabels();
% If the once-current experiment is now removed, update the view
% accordingly
iExpNow=whichstr(currentExpDirName,data.expdirs);
if isempty(iExpNow) ,
  % Update the movie to reflect the current movie
  iExp=handles.data.expi;
  handles = UnsetCurrentMovie(handles);
  if handles.data.nexps > 0 && iExp>0
    handles = SetCurrentMovie(handles,iExp);
  end
  % Update the GUI to match the current "model" state
  UpdateEnablementAndVisibilityOfControls(handles);
  UpdatePlots(handles)
  guidata(figureJLabel,handles);
end
return


% --------------------------------------------------------------------
function menu_file_savewindowdata_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_savewindowdata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(handles.menu_file_savewindowdata,'checked'),'on')
  handles.data.setsavewindowdata(false);
  set(handles.menu_file_savewindowdata,'checked','off');
else
  handles.data.setsavewindowdata(true);
  set(handles.menu_file_savewindowdata,'checked','on');
  
end


% --------------------------------------------------------------------
function menu_edit_multithreading_preferences_Callback(hObject, eventdata, handles)
% hObject    handle to menu_edit_multithreading_preferences (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

numCores = feature('numCores');
prompts = {sprintf('N. threads for display (btn 1 and %d)',numCores),...
  sprintf('N. threads for computation (btn 1 and %d)',numCores)};
c = parcluster;
NumWorkers = c.NumWorkers;

while true,
    ischange = false;
  defaults = {num2str(handles.guidata.framecache_threads),...
    num2str(handles.guidata.computation_threads)};
  res = inputdlg(prompts,'Multi-threading Preferences',1,defaults);
  if isempty(res), return, end;
  errs = {};

  framecache_threads = str2double(res{1});
  ischange = false;
  if isnan(framecache_threads) || framecache_threads < 1 || framecache_threads > feature('numCores') || rem(framecache_threads,1) ~= 0,
    errs{end+1} = 'Number of threads devoted to display must be a positive integer less than or equal to the number of CPU cores';  %#ok<AGROW>
  else
    if(handles.guidata.framecache_threads ~= framecache_threads)
      ischange = true;
    end
  end
  
  computation_threads = str2double(res{2});
  if isnan(computation_threads) || computation_threads < 1 || computation_threads > numCores || rem(computation_threads,1) ~= 0,
    errs{end+1} = 'Number of threads devoted to computation must be a positive integer less than or equal to the number of CPU cores';  %#ok<AGROW>
  else
    if(handles.guidata.computation_threads ~= computation_threads)
      ischange = true;
    end
  end
  
  if framecache_threads+computation_threads > NumWorkers,
    errs{end+1} = sprintf('Total number of threads (%d + %d) must be at most %d',...
      framecache_threads,computation_threads,NumWorkers); %#ok<AGROW>
  end

  if ischange && isempty(errs),
    
    % remove extra computation threads
    if matlabpool('size') > computation_threads,
      SetStatus(handles,sprintf('Shrinking matlab pool to %d workers',computation_threads));
      pause(2);
      matlabpool close;
      matlabpool('open',computation_threads);
    end
    
    % remove extra frame cache threads
    nremove=numel(handles.guidata.cache_thread)-framecache_threads;
    if (nremove>0) && ~isempty(handles.guidata.cache_thread)
      SetStatus(handles,sprintf('Deleting %d frame cache thread(s) leaving a total of %d',nremove,framecache_threads));
      for i=1:nremove,
        delete(handles.guidata.cache_thread{end});
        handles.guidata.cache_thread(end)=[];
      end
      pause(2);
    end
   
    % add extra computation threads
    if matlabpool('size') < computation_threads,
      SetStatus(handles,sprintf('Growing matlab pool to %d workers',computation_threads));
      if matlabpool('size') > 0,
        matlabpool close;
      end
      pause(1);
      matlabpool('open',computation_threads);
      pause(1);
    end
    
    % add extra frame cache threads
    nadd = -nremove;
    if nadd > 0 && ~isempty(handles.guidata.cache_thread)
      for i=1:nadd,
        SetStatus(handles,sprintf('Adding %d of %d new frame cache thread(s) for a total of %d',...
          i,nadd,framecache_threads));
        handles.guidata.cache_thread{end+1}=batch(@cache_thread,0,...
          {handles.guidata.cache_size,...
          [handles.guidata.movie_height handles.guidata.movie_width handles.guidata.movie_depth],...
          handles.guidata.cache_filename,handles.guidata.movie_filename},...
          'CaptureDiary',true,'AdditionalPaths',{'../filehandling','../misc'});
      end
    end
    
    handles.guidata.framecache_threads = framecache_threads;
    handles.guidata.computation_threads = computation_threads;
    ClearStatus(handles);
    
  end
  
  if isempty(errs),
    break;
  else
    uiwait(warndlg(errs,'Bad preview options'));
  end
  
end
guidata(hObject,handles);
return


% --------------------------------------------------------------------
function menu_file_import_exps_Callback(hObject, eventdata, handles)
% hObject    handle to menu_file_import_exps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

title='Import Experiments and Labels from...';
defaultPath=handles.data.defaultpath;
[filename,pathname] = ...
  uigetfile({'*.jab','JAABA Files (*.jab)'}, ...
            title, ...
            defaultPath);
if ~ischar(filename),
  % user hit cancel
  return;
end

fileNameAbs=fullfile(pathname,filename);

choice = questdlg('Would you like to import both experiments and labels or only the experiments and labels?', ...
 title,...
 'Experiments and Labels','Experiments only', ...
 'Cancel','Experiments and Labels');
% Handle response
importlabels = true;
switch choice
  case 'Experiments and Labels'
    importlabels = true;
  case 'Experiments only'
    importlabels = false;
  case 'Cancel'
    return;
end


% Update the status, change the pointer to the watch
SetStatus(handles,sprintf('Importing Experiments and Labels from %s...',filename));
try
  [success,msg] = handles.guidata.data.AddExpDirAndLabelsFromJab(fileNameAbs,importlabels);
  if ~success,
    uiwait(warndlg(sprintf('Could not import:%s',msg)));
  end
catch ME,
  uiwait(warndlg(sprintf('Could not import: %s',ME.message)));
end
if handles.data.expi == 0 && handles.data.nexps>0
  handles = SetCurrentMovie(handles,1);
  handles = UpdateTimelineImages(handles);
  UpdatePlots(handles,'refresh_timeline_manual',true);
end
guidata(handles.figure_JLabel,handles);
ClearStatus(handles);


% --------------------------------------------------------------------
function menu_view_clearcache_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_clearcache (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
UpdatePlots(handles,'CLEAR');
UpdatePlots(handles);


% --------------------------------------------------------------------
function menu_view_shortcutslist_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_shortcutslist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
str = {'Ctrl + t  --  Train'
  'Ctrl + p  --  Predict'
  'Ctrl + n  --  Navigation Preferences'
  'Ctrl + j  --  Switch Target'
  'Ctrl + u  --  Switch Experiment'
  'Ctrl + k  --  Plot/Hide tracks'
  'Ctrl + f  --  Show Whole Frame'
  'Ctrl + s  --  Save Project'
  'Ctrl + 9  --  Previous Movie'
  'Ctrl + 0 (zero)  --  Next Movie'
  'Ctrl + 1  --  Previous Target'
  'Ctrl + 2  --  Next Target'
  'Space     --  Play (Does not always work)' 
  };
helpdlg(str,'List of Shortcuts')


% --------------------------------------------------------------------
function menu_go_switch_exp_Callback(hObject, eventdata, handles)
% hObject    handle to menu_go_switch_exp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
expnames = handles.data.expnames;
[sel,ok] = listdlg('ListSize',[650 220],'Name','Select Experiments',...
  'ListString',expnames,'SelectionMode','single','OKString','Switch..',...
  'InitialValue',handles.data.expi);
if ok == 0, return; end
if numel(sel)>1, uiwait(warndlg('Select one experiment')); return; end

handles = SetCurrentMovie(handles,sel);
guidata(hObject,handles);


% --------------------------------------------------------------------
function menu_view_showpredictionsall_Callback(hObject, eventdata, handles)
% hObject    handle to menu_view_showpredictionsall (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.guidata.showPredictionsAllFlies 
  handles.guidata.showPredictionsAllFlies = false;
  set(handles.menu_view_showpredictionsall,'Checked','off');  
else
  handles.guidata.showPredictionsAllFlies = true;
  set(handles.menu_view_showpredictionsall,'Checked','on');
end
UpdatePlots(handles);
guidata(hObject,handles);
