function opt = stats_localizer_option()
%
% returns a structure that contains the options chosen by the user to run
% slice timing correction, pre-processing, FFX, RFX.
%
% (C) Copyright 2019 Remi Gau

opt = [];

opt.subjects = {'012'}; % 002 003 004 005

% Task to analyze - change accordingly
opt.taskName = 'visualLocalizer';

opt.verbosity = 2;

% space to analyse
opt.space = 'MNI';

% Drastically improve analysis speed with a simple trick!  
% the F in false stands fo fast
opt.glm.QA.do = false;

% The functional smoothing 
opt.fwhm.func = 6;
opt.fwhm.contrast = 6;

% The directory where the data are located
opt.dir.root = fullfile(fileparts(mfilename('fullpath')), '..', '..');

opt.dir.raw = fullfile(opt.dir.root, 'inputs', 'raw');
opt.dir.derivatives = fullfile(opt.dir.root, 'outputs', 'derivatives');
opt.dir.preproc = fullfile(opt.dir.root, 'outputs', 'derivatives', 'bidspm-preproc');
opt.dir.input = opt.dir.preproc;
opt.dir.roi = fullfile(opt.dir.root, 'outputs', 'derivatives', 'cpp_spm-roi');
opt.dir.stats = fullfile(opt.dir.root, 'outputs', 'derivatives', 'bidspm-stats');

% Model specifies all the contrasts
opt.model.file = fullfile(opt.dir.root, 'code', ...
    'models', 'model-visualLocalizerUnivariate_smdl.json');

opt.pipeline.type = 'stats';

% % Specify the result to compute
% opt.results.Nodes(1) = defaultResultsStructure();
% 
% opt.results.Nodes(1).Level = 'subject';

% For each contrats, you can adapt:
%  - voxel level (p)
%  - cluster (k) level threshold
%  - type of multiple comparison:
%    - 'FWE' is the defaut
%    - 'FDR'
%    - 'none'

% nodeName = name of the Node in the BIDS stats model
opt.results(1).nodeName = 'subject_level';
% name of the contrast in the BIDS stats model
opt.results(1).name = {'french_gt_scrambled'};
% Specify how you want your output (all the following are on false by default)
opt.results(1).png = true();
opt.results(1).csv = true();
opt.results(1).p = 0.001;
opt.results(1).MC = 'none';
opt.results(1).k = 0;
% those don't change across contrasts, try to put only once
opt.results(1).binary = true();
opt.results(1).montage.do = true();
opt.results(1).montage.background = struct('suffix', 'T1w', 'desc', 'preproc', 'modality', 'anat');
opt.results(1).montage.slices = -20:2:0;
opt.results(1).montage.orientation = 'axial'; % also 'sagittal', 'coronal'
opt.results(1).nidm = true();
opt.results(1).threshSpm = true();

opt.results(2).nodeName = 'subject_level';
opt.results(2).name = {'braille_gt_scrambled'};
opt.results(2).png = true();
opt.results(2).csv = true();
opt.results(2).p = 0.001;
opt.results(2).MC = 'none';
opt.results(2).k = 0;
% those don't change across contrasts, try to put only once
opt.results(2).binary = true();
opt.results(2).montage.do = true();
opt.results(2).montage.background = struct('suffix', 'T1w', 'desc', 'preproc', 'modality', 'anat');
opt.results(2).montage.slices = -20:2:0;
opt.results(2).montage.orientation = 'axial'; % also 'sagittal', 'coronal'
opt.results(2).nidm = true();
opt.results(2).threshSpm = true();

opt.results(3).nodeName = 'subject_level';
opt.results(3).name = {'drawing_gt_scrambled'};
opt.results(3).png = true();
opt.results(3).csv = true();
opt.results(3).p = 0.001;
opt.results(3).MC = 'none';
opt.results(3).k = 0;
% those don't change across contrasts, try to put only once
opt.results(3).binary = true();
opt.results(3).montage.do = true();
opt.results(3).montage.background = struct('suffix', 'T1w', 'desc', 'preproc', 'modality', 'anat');
opt.results(3).montage.slices = -20:2:0;
opt.results(3).montage.orientation = 'axial'; % also 'sagittal', 'coronal'
opt.results(3).nidm = true();
opt.results(3).threshSpm = true();

opt.results(4).nodeName = 'subject_level';
opt.results(4).name = {'frWords_gt_scrLines'};
opt.results(4).png = true();
opt.results(4).csv = true();
opt.results(4).p = 0.001;
opt.results(4).MC = 'none';
opt.results(4).k = 0;
% those don't change across contrasts, try to put only once
opt.results(4).binary = true();
opt.results(4).montage.do = true();
opt.results(4).montage.background = struct('suffix', 'T1w', 'desc', 'preproc', 'modality', 'anat');
opt.results(4).montage.slices = -20:2:0;
opt.results(4).montage.orientation = 'axial'; % also 'sagittal', 'coronal'
opt.results(4).nidm = true();
opt.results(4).threshSpm = true();

opt.results(5).nodeName = 'subject_level';
opt.results(5).name = {'allWords_gt_scrLines'};
opt.results(5).png = true();
opt.results(5).csv = true();
opt.results(5).p = 0.001;
opt.results(5).MC = 'none';
opt.results(5).k = 0;
% those don't change across contrasts, try to put only once
opt.results(5).binary = true();
opt.results(5).montage.do = true();
opt.results(5).montage.background = struct('suffix', 'T1w', 'desc', 'preproc', 'modality', 'anat');
opt.results(5).montage.slices = -20:2:0;
opt.results(5).montage.orientation = 'axial'; % also 'sagittal', 'coronal'
opt.results(5).nidm = true();
opt.results(5).threshSpm = true();

% % Specify how you want your output (all the following are on false by default)

%% DO NOT TOUCH
opt = checkOptions(opt);
saveOptions(opt);

end
