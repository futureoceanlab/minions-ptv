function tracks = simulator(params, simDir, simConfig, simMode, rndSeed)
    %% Load camera parameters
    cameraMatrix1 = cameraMatrix(params.CameraParameters1, eye(3), [0 0 0]);
    cameraMatrix2 = cameraMatrix(params.CameraParameters2, ...
        params.RotationOfCamera2, params.TranslationOfCamera2);
    [~, lCameraPos] = extrinsicsToCameraPose(eye(3),...
                                            zeros(1, 3));
    [~, rCameraPos] = extrinsicsToCameraPose(params.RotationOfCamera2,...
                                            params.TranslationOfCamera2);
    camPoses = [lCameraPos; rCameraPos];
    camMatrix = zeros([2, size(cameraMatrix1)]);
    camMatrix(1, :, :) = cameraMatrix1;
    camMatrix(2, :, :) = cameraMatrix2;
    F = params.FundamentalMatrix;
    f1 = params.CameraParameters1.FocalLength;
    p1 = params.CameraParameters1.PrincipalPoint;
    pxPitch = 0.0022;
    N = 8; % F-stop
    fl = f1(1) * pxPitch;
    desiredResolution = 0.020; %mm/px
    WD = fl * desiredResolution/pxPitch;
    rng(rndSeed,'twister');

    imageSizeY = 1944;
    imageSizeX = 2592;

    %% Path configuration
    imgDir = sprintf('%s/img', simDir);
    if ~exist(imgDir, 'dir')
        mkdir(imgDir)
    end
    
    %% Simulation configuration
    nFrames = simConfig.nFrames;
    nCylinderPts = 1e4;
    nSpherePts = 20;
    actualSpherePts = (nSpherePts+1)^2;
    tic
    if simMode == "monotonic"
        nParticles = simConfig.concentration;
        nSpheres = round(simConfig.sphereRatio * nParticles);
        nCylinders = nParticles - nSpheres;
        
        cRadius = ones(nCylinders, 1) * simConfig.cRadius ./ 1000;
        cHeights = ones(nCylinders, 1) * simConfig.cHeights./ 1000;
        sRadius = ones(nSpheres, 1) * simConfig.sRadius./ 1000;
        sinkRate = reshape(simConfig.sinkRate * simConfig.direction, [1, 1, 3]);
        sinkRate = sinkRate ./ 86.4; % m/day to mm/sec
        cSinkVelocity = repmat(sinkRate, [nCylinders nCylinderPts 1]);
        sSinkVelocity = repmat(sinkRate, [nSpheres actualSpherePts 1]);
        sSingleVelocity = squeeze(sSinkVelocity(:, 1, :));
        cSingleVelocity = squeeze(cSinkVelocity(:, 1, :));
    else % "diverse"
        cHeights = [];
        cRadius = [];
        sRadius = [];
        sSingleVelocity = [];
        cSingleVelocity = [];
        sRRange = diff(simConfig.sRadiusRange, [], 2);
        cRRange = diff(simConfig.cRadiusRange, [], 2);
        cHRange = diff(simConfig.cHeightsRange, [], 2);
        for pIdx = 1:size(simConfig.concentration, 1)
            c = round(simConfig.concentration(pIdx));
            nS = round(c * simConfig.sphereRatio);
            nC = c - nS;
            curSRadius = sRRange(pIdx)*rand([nS 1]) + simConfig.sRadiusRange(pIdx, 1);
            curCRadius = cRRange(pIdx)*rand([nC 1]) + simConfig.cRadiusRange(pIdx, 1);
            curCHeights = cHRange(pIdx)*rand([nC 1]) + simConfig.cHeightsRange(pIdx, 1);
            sRadius = [sRadius; curSRadius];
            cRadius = [cRadius; curCRadius];
            cHeights = [cHeights; curCHeights];
            curSVelocity = repmat(normrnd(simConfig.sinkRateDetail(pIdx, 1),...
                simConfig.sinkRateDetail(pIdx, 2), [nS, 1]), [1 3]);
            curCVelocity = repmat(normrnd(simConfig.sinkRateDetail(pIdx, 1),...
                simConfig.sinkRateDetail(pIdx, 2), [nC, 1]), [1 3]);
            sSingleVelocity = [sSingleVelocity; curSVelocity];
            cSingleVelocity = [cSingleVelocity; curCVelocity];
        end

        cHeights = cHeights./1000;
        cRadius = cRadius./1000;
        sRadius = sRadius./1000;
        nSpheres = size(sRadius, 1);
        nCylinders = size(cRadius, 1);
        nParticles = nSpheres + nCylinders;
        % Below is unnecessary since it is a linear move. We can simply
        % multiply the veclocity by frame number (i.e. time) to get the
        % displacement per each frame
        sSingleVelocity = abs(sSingleVelocity.*repmat(simConfig.direction, [nSpheres, 1]))./1000;
        cSingleVelocity = abs(cSingleVelocity.*repmat(simConfig.direction, [nCylinders, 1]))./1000;
    end
    toc
    %% Generate and filter particles that do not fall in the image frame with buffer
    % Create simulated particles in 3D
    % origin is the center of the camera X-axis points right, Y-axis points bototm 
    centroids = generateCentroids(nParticles, -500, 500, -100, 9900, 200, 300);

    tracksL = table();
    tracksR = table();
    camBounds = [0 0 300; 2592 0 300; 0 1944 300; 2592 1944 300];
    leftBounds = project2Dto3D(camBounds, cameraMatrix1');
    rightBounds = project2Dto3D(camBounds, cameraMatrix2');
    minBound1 = min([leftBounds; rightBounds]);
    maxBound1 = max([leftBounds; rightBounds]);
    minBound1(3) = 200;
    singleVelocity = max([sSingleVelocity; cSingleVelocity]);
    bRange = nFrames * singleVelocity;
    minBound2 = minBound1 - bRange;
    maxBound2 = maxBound1 - bRange; 
    minBound = min([minBound1, minBound2]);
    maxBound = max([maxBound1, maxBound2]);
    cFilter = sum(centroids > minBound & centroids < maxBound, 2) == 3;
    centroids = centroids(cFilter, :);
    nParticles = size(centroids, 1);
    nSpheres = round(nParticles * simConfig.sphereRatio);
    nCylinders = nParticles - nSpheres;
    cSingleVelocity = cSingleVelocity(1:nCylinders, :);
    sSingleVelocity = sSingleVelocity(1:nSpheres, :);
    tic
    cSinkVelocity = permute(repmat(cSingleVelocity, [1 1 nCylinderPts]), [1 3 2]);
    sSinkVelocity = permute(repmat(sSingleVelocity, [1 1 actualSpherePts]), [1 3 2]);
    toc
    %% Generate 3D point clouds given the shape (cylinder + sphere) per centroids

    % Cylinders
    yawD = 0; 
    pitchD = 90*rand([nCylinders, 1]) - 45;
    rollD = 90*rand([nCylinders, 1]) - 45;
    cylinders = zeros(nCylinders, nCylinderPts, 3);
    spheres = zeros(nSpheres, actualSpherePts, 3);
    tic
    % Generate 3D cloud points of cylinders and spheres
    for i = 1:nParticles
        if i <= nCylinders
            cylinderPts = generateCylinder(cRadius(i), cHeights(i), nCylinderPts);
            cylinderPts = rotateCloud(cylinderPts, yawD, pitchD(i), rollD(i));
            cylinderPts = bsxfun(@plus, cylinderPts, centroids(i, :));
            cylinders(i, :, :) = cylinderPts;
        else
            k = i - nCylinders;
            spherePts = generateSphere(nSpherePts, sRadius(k));     
            spherePts = bsxfun(@plus, spherePts, centroids(i, :));
            spheres(i-nCylinders, :, :) = spherePts;
        end
    end
    toc
    
    
    %% Capture particles image and move frame by frame
    imgPair = zeros(2, imageSizeY, imageSizeX) + 50;
    coord2D = zeros(2, nParticles, 2);
    coord3D = zeros(nParticles, 3);
    shapes = zeros(nParticles, 1);

    minSphere3D = squeeze(min(spheres, [], 2));
    maxSphere3D = squeeze(max(spheres, [], 2));
    minCylinder3D = squeeze(min(cylinders, [], 2));
    maxCylinder3D = squeeze(max(cylinders, [], 2));
    tic
    for frameI=1:nFrames
        sBoundFilter = sum(minSphere3D < maxBound1 & maxSphere3D > minBound1, 2) == 3;
        cBoundFilter = sum(minCylinder3D < maxBound1 & maxCylinder3D > minBound1, 2) == 3;
        sIdx = find(sBoundFilter);
        cIdx = find(cBoundFilter);
        sInFrame = spheres(sBoundFilter, :, :);
        cInFrame = cylinders(cBoundFilter, :, :);
        cR = cRadius(cBoundFilter);
        cH = cHeights(cBoundFilter);
        sR = sRadius(sBoundFilter);
        nSpheresInFrame = size(sInFrame, 1);
        nCylindersInFrame = size(cInFrame, 1);
        nParticlesInFrame = nSpheresInFrame + nCylindersInFrame;
        for i=1:nParticlesInFrame
            wasInFrame = [0 0];
            if (i <= nCylindersInFrame)
                curPts = squeeze(cInFrame(i, :, :));
                shapes(i) = 1;
                id = cIdx(i);
                esd = mean([cR(i)*2 cH(i)]);
            else 
                k = i - nCylindersInFrame;
                curPts = squeeze(sInFrame(k, :, :));
                id = sIdx(k);
                esd = sR(k)*2;
            end
            coord3D(i, :) = mean(curPts)';
            for camI=1:2
                imgTemp = zeros(imageSizeY, imageSizeX);
                dist = norm(coord3D(i, :) - camPoses(camI, :));
                pts = round(projectPoints(curPts, squeeze(camMatrix(camI, :, :))'))+1;
                COC = fl * fl / (N * (WD - fl))* (abs(dist - WD) / dist)/pxPitch/2;
                ptsMax = max(1, min([imageSizeX; imageSizeY], max(pts, [], 2) + floor(3*COC)));
                ptsMin = min([imageSizeX; imageSizeY], max(1, min(pts, [], 2) - floor(3*COC)));
                
                if ~(inBoundary2D(ptsMin, 1, 2592, 1, 1944) ...
                        || inBoundary2D(ptsMax, 1, 2592, 1, 1944))
                    continue;
                end
                
                coord2D(camI, i, :) = mean(pts, 2);

                for j = 1:size(pts, 2)
                    x = pts(1, j);
                    y = pts(2, j);
                    if inBoundary2D(pts(:, j), 1, imageSizeX, 1, imageSizeY)
                        imgTemp(y, x) = 255;
                        wasInFrame(camI) = 1;
                    end
                end
                imgTemp2 = imgaussfilt(imgTemp(ptsMin(2):ptsMax(2), ptsMin(1):ptsMax(1)), COC);
%                 imgTemp2 = imgTemp(ptsMin(2):ptsMax(2), ptsMin(1):ptsMax(1));
                imgTemp(ptsMin(2):ptsMax(2), ptsMin(1):ptsMax(1)) = imgTemp2;
                imgPair(camI, :, :) = squeeze(imgPair(camI, :, :)) + imgTemp;
            end
            tracksL = updateTracks(tracksL, wasInFrame(1), id, ...
                squeeze(coord2D(1, i, :)), coord3D(i, :), esd);
            tracksR = updateTracks(tracksR, wasInFrame(2), id, ...
                squeeze(coord2D(2, i, :)), coord3D(i, :), esd);
        end
        if ~isempty(tracksL)
            tracksL.age = tracksL.age + 1;
        end
        if ~isempty(tracksR)
            tracksR.age = tracksR.age + 1;
        end
        img1Path = sprintf('%s/cam_1_%d.tif', imgDir, frameI);
        img2Path = sprintf('%s/cam_2_%d.tif', imgDir, frameI);
        imwrite(squeeze(imgPair(1, :, :))./255, img1Path, 'TIFF');
        imwrite(squeeze(imgPair(2, :, :))./255, img2Path, 'TIFF');

        imgPair = zeros(2, imageSizeY, imageSizeX) + 50;
        cylinders = cylinders + cSinkVelocity;
        spheres = spheres + sSinkVelocity;
        minSphere3D = minSphere3D + sSingleVelocity;
        maxSphere3D = minSphere3D + sSingleVelocity;
        minCylinder3D = minCylinder3D + cSingleVelocity;
        maxCylinder3D = maxCylinder3D + cSingleVelocity;
    end
    toc
    % Remove tracks that did not appear at all
    tracksL(tracksL.age == 0, :) = [];
    tracksR(tracksR.age == 0, :) = [];
    tracks = struct('tracksL', tracksL, 'tracksR', tracksR);
    trackFile = sprintf('%s/tracksSimulated.mat', simDir);
    save(trackFile, 'tracks');
end