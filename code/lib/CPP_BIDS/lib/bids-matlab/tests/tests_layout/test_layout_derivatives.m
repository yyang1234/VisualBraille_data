function test_suite = test_layout_derivatives %#ok<*STOUT>
  try % assignment of 'localfunctions' is necessary in Matlab >= 2016
    test_functions = localfunctions(); %#ok<*NASGU>
  catch % no problem; early Matlab versions can use initTestSuite fine
  end
  initTestSuite;
end

function test_layout_warning_invalid_subfolder_struct_fieldname()

  % https://github.com/bids-standard/bids-matlab/issues/332

  invalid_subfolder = fullfile(get_test_data_dir(), '..', ...
                               'data', 'synthetic', 'derivatives', 'invalid_subfolder');

  % 'Octave:mixed-string-concat'
  if ~bids.internal.is_octave
    assertWarning(@()bids.layout(invalid_subfolder, ...
                                 'use_schema', false, ...
                                 'verbose', true), ...
                  'layout:invalidSubfolderName');
  end

end

function test_layout_nested()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, 'ds000117'), ...
                     'use_schema', true, ...
                     'index_derivatives', true);

end

function test_layout_meg_derivatives()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, ...
                              'ds000117', ...
                              'derivatives', ...
                              'meg_derivatives'), ...
                     'use_schema', false);

  modalities = {'meg'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  data = bids.query(BIDS, 'data', ...
                    'sub', '01', ...
                    'run', '01', ...
                    'proc', 'sss', ...
                    'suffix', 'meg');
  basename = bids.internal.file_utils(data, 'basename');
  assertEqual(basename, {'sub-01_ses-meg_task-facerecognition_run-01_proc-sss_meg'});

end

function test_layout_prefix()

  pth_bids_example = get_test_data_dir();

  copyfile(fullfile(pth_bids_example, 'qmri_tb1tfl', 'sub-01', 'fmap', ...
                    'sub-01_acq-anat_TB1TFL.nii.gz'), ...
           fullfile(pth_bids_example, 'qmri_tb1tfl', 'sub-01', 'fmap', ...
                    'swuasub-01_acq-anat_TB1TFL.nii.gz'));

  BIDS = bids.layout(fullfile(pth_bids_example, 'qmri_tb1tfl'), ...
                     'use_schema', false);

  data = bids.query(BIDS, 'data', ...
                    'sub', '01', ...
                    'prefix', 'swua');
  basename = bids.internal.file_utils(data, 'basename');
  assertEqual(basename, {'swuasub-01_acq-anat_TB1TFL.nii'});

  assertEqual(bids.query(BIDS, 'prefixes'), {'swua'});

  delete(fullfile(pth_bids_example, 'qmri_tb1tfl', 'sub-01', 'fmap', ...
                  'swuasub-01_acq-anat_TB1TFL.nii.gz'));

end

function test_layout_schemaless()

  pth_bids_example = get_test_data_dir();

  BIDS = bids.layout(fullfile(pth_bids_example, ...
                              'ds000001-fmriprep'), ...
                     'use_schema', false);

  modalities = {'anat', 'figures', 'func'};
  assertEqual(bids.query(BIDS, 'modalities'), modalities);

  data = bids.query(BIDS, 'data', ...
                    'sub', '10', ...
                    'modality', 'func', ...
                    'suffix', 'bold', ...
                    'run', '1', ...
                    'res', '2');

  basename = bids.internal.file_utils(data, 'basename');
  assertEqual(basename, {
                         ['sub-10_task-balloonanalogrisktask_run-1', ...
                          '_space-MNI152NLin2009cAsym_res-2_desc-preproc_bold.nii']
                        });

  data = bids.query(BIDS, 'data', ...
                    'sub', '10', ...
                    'modality', 'func', ...
                    'suffix', 'bold', ...
                    'run', '1', ...
                    'space', 'MNI152NLin6Asym');

  basename = bids.internal.file_utils(data, 'basename');
  assertEqual(basename, {
                         ['sub-10_task-balloonanalogrisktask_run-1', ...
                          '_space-MNI152NLin6Asym_desc-smoothAROMAnonaggr_bold.nii']
                        });
end
