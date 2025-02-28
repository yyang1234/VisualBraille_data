function [mask, outputFile, report] = roi_createCustomexpansion(specification, VolumeDefiningImage, OutputDir, saveImg, attempt)
%
% Returns a mask to be used as a ROI by ``spm_summarize``.
% Can also save the ROI as binary image.
% See 'createRoi for more information.
%
% (C) Copyright 2021 CPP ROI developers

% fixed
type = 'expand';
reDo = false;

switch type

    case 'sphere'

        sphere = specification;

        mask.def = type;
        mask.spec = sphere.radius;
        mask.xyz = sphere.location;

        if size(mask.xyz, 1) ~= 3
            mask.xyz = mask.xyz';
        end

        mask = spm_ROI(mask);
        mask.roi.XYZmm = [];

        mask = createRoiLabel(mask);

    case 'mask'

        roiImage = specification;

        isBinaryMask(roiImage);

        mask = struct('XYZmm', []);
        mask = defineGlobalSearchSpace(mask, roiImage);

        % in real world coordinates
        mask.global.XYZmm = returnXYZm(mask.global.hdr.mat, mask.global.XYZ);

        assert(size(mask.global.XYZmm, 2) == sum(mask.global.img(:)));

        locationsToSample = mask.global.XYZmm;

        mask.def = type;
        mask.spec = roiImage;
        [~, mask.roi.XYZmm, j] = spm_ROI(mask, locationsToSample);

        mask.roi.XYZ = mask.global.XYZ(:, j);

        mask = setRoiSizeAndType(mask, type);

        mask = createRoiLabel(mask);

    case 'intersection'
        
        switch attempt
            case 1, roiImage = specification.mask1; % p = 0.001
            case 2, roiImage = specification.mask2; % p = 0.01
            case 3, roiImage = specification.mask3; % p = 0.05
            case 4, roiImage = specification.mask4; % p = 0.1
        end

        sphere = specification.maskSphere;

        isBinaryMask(roiImage);

        mask = createRoi('mask', roiImage);
        mask2 = createRoi('sphere', sphere);

        locationsToSample = mask.global.XYZmm;

        [~, mask.roi.XYZmm] = spm_ROI(mask2, locationsToSample);

        mask = setRoiSizeAndType(mask, type);

        mask = createRoiLabel(mask);

    case 'expand'

        switch attempt
            case 1, roiImage = specification.mask1; % p = 0.001
            case 2, roiImage = specification.mask2; % p = 0.01
            case 3, roiImage = specification.mask3; % p = 0.05
            case 4, roiImage = specification.mask4; % p = 0.1
        end

        sphere = specification.maskSphere;

        isBinaryMask(roiImage);

        % check that input image has at least enough voxels to include
        maskVol = spm_read_vols(spm_vol(roiImage));
        totalNbVoxels = sum(maskVol(:));
        if sphere.maxNbVoxels > totalNbVoxels
            error('Number of voxels requested greater than the total number of voxels in this mask');
        end

        spec  = struct('mask1', roiImage, ...
                       'mask2', sphere);

        % take as radius step the smallest voxel dimension of the roi image
        hdr = spm_vol(roiImage);
        dim = diag(hdr.mat);
        radiusStep = min(abs(dim(1:3)));

        % determine maximum radius to expand to
        maxRadius = hdr.dim .* dim(1:3)';
        maxRadius = max(abs(maxRadius));

        fprintf(1, '\n Expansion:');

        previousSize = 0;

        while  true
            mask = createRoi('intersection', spec);
            mask.roi.radius = spec.mask2.radius;

            fprintf(1, '\n radius: %0.2f mm; roi size: %i voxels', ...
                mask.roi.radius, ...
                mask.roi.size);

            if mask.roi.size == previousSize
                fprintf(['\n An increase in the size did not increase the number of voxels. This cluster''s size is not sufficient.\n' ...
                         'Will use lower threshold\n']);
                reDo = true;
                attempt = attempt+1;
                break
            end

            if mask.roi.radius >= 15
                fprintf(['\n Radius too large\nIt would not make sense for our area to be this large and still not have enough voxels.\n' ...
                         'Will use lower threshold\n']);
                reDo = true;
                attempt = attempt+1;
                break
            end    

            if mask.roi.size > sphere.maxNbVoxels
                break
            end

            if mask.roi.radius > maxRadius
                error('sphere expanded beyond the dimension of the mask.');
            end

            spec.mask2.radius = spec.mask2.radius + radiusStep;
            previousSize = mask.roi.size;
        end

        if reDo
            mask = roi_createCustomexpansion(specification, VolumeDefiningImage, OutputDir, saveImg, attempt);
        end

        fprintf(1, '\n');

        mask.xyz = sphere.location;

        mask = setRoiSizeAndType(mask, type);

        mask = createRoiLabel(mask);


end

% save file - does the mask changes based on the attempt? 
outputFile = [];
if saveImg
    outputFile = saveRoi(mask, VolumeDefiningImage, OutputDir);
end
if not(reDo)

    % Directly write the document
    % open report 
    repFile = dir('expansionReport.txt');
    if not(isempty(repFile))
        report = readcell(repFile.name);
    else
        report = [];
    end

    % add line
    reportMethod = mask.def;
    splitLoca = split(specification.mask1,{'desc-','_label'});
    if startsWith(splitLoca{2},'french'), reportArea = 'VWFA';
    else, reportArea = 'LO';
    end
    switch attempt
        case 1, reportPvalue = '0.001';
        case 2, reportPvalue = '0.01';
        case 3, reportPvalue = '0.05';
        case 4, reportPvalue = '0.1';
    end
    reportAttempt = attempt;
    reportRadius = mask.roi.radius;
    reportVoxels = mask.roi.size;
    report = vertcat(report, {reportArea, reportMethod, reportAttempt, reportPvalue, reportRadius, reportVoxels});

    % save report
    writecell(report,'expansionReport.txt')
end

end

function mask = defineGlobalSearchSpace(mask, image)
%
% gets the X, Y, Z subscripts of the voxels included in the ROI
%

mask.global.hdr = spm_vol(image);
mask.global.img = logical(spm_read_vols(mask.global.hdr));

[X, Y, Z] = ind2sub(size(mask.global.img), find(mask.global.img));

% XYZ format
mask.global.XYZ = [X'; Y'; Z'];
mask.global.size = size(mask.global.XYZ, 2);

end

function XYZmm = returnXYZm(transformationMatrix, XYZ)
%
% apply voxel to world transformation
%

XYZmm = transformationMatrix(1:3, :) * [XYZ; ones(1, size(XYZ, 2))];
end

function mask = setRoiSizeAndType(mask, type)
mask.def = type;
mask.roi.size = size(mask.roi.XYZmm, 2);
end

function mask = createRoiLabel(mask)

switch mask.def

    case 'sphere'

        mask.label = sprintf('sphere%0.0fx%0.0fy%0.0fz%0.0f', ...
            mask.spec, ...
            mask.xyz);

        % change any minus coordinate (x = -67) to minus (xMinus67)
        % SUPER ugly but any minus will mess up the bids parsing otherwise
        mask.label = strrep(mask.label, '-', 'Minus');

        mask.descrip = sprintf('%s at [%0.1f %0.1f %0.1f]', ...
            mask.str, ...
            mask.xyz);

    case 'expand'

        mask.label = sprintf('%sVox%i', ...
            mask.def, ...
            mask.roi.size);

        mask.descrip = sprintf('%s from [%0.0f %0.0f %0.0f] till %i voxels', ...
            mask.def, ...
            mask.xyz, ...
            mask.roi.size);

    otherwise

        mask.label = mask.def;
        mask.descrip = mask.def;

end

end

function outputFile = saveRoi(mask, volumeDefiningImage, outputDir)

hdr = spm_vol(volumeDefiningImage);
if numel(hdr) > 1
    err.identifier =  'createRoi:not3DImage';
    err.message = sprintf(['the volumeDefininigImage:', ...
        '\n\t%s\n', ...
        'must be a 3D image. It seems to be 4D image with %i volume.'], ...
        image, numel(hdr));
    error(err);
end

if ~strcmp(mask.def, 'sphere') && ...
        exist(mask.spec, 'file') == 2 && ...
        strcmp(spm_file(mask.spec, 'ext'), 'nii')
    checkRoiOrientation(volumeDefiningImage, mask.spec);
end

if strcmp(mask.def, 'sphere')

    [~, mask.roi.XYZmm] = spm_ROI(mask, volumeDefiningImage);
    mask = setRoiSizeAndType(mask, mask.def);

end

roiName = createRoiName(mask, volumeDefiningImage);

% use the marsbar toolbox
roiObject = maroi_pointlist(struct('XYZ', mask.roi.XYZmm, ...
    'mat', spm_get_space(volumeDefiningImage), ...
    'label', mask.label, ...
    'descrip', mask.descrip));

% use Marsbar to save as a .mat and then convert that to an image
% in the correct space
outputFile = fullfile(outputDir, roiName);
save_as_image(roiObject, outputFile);

json = bids.derivatives_json(outputFile);
bids.util.jsonencode(json.filename, json.content);

end
