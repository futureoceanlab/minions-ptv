clear;
load("params.mat", 'params');
cameraMatrix1 = cameraMatrix(params.CameraParameters1, eye(3), [0 0 0]);
cameraMatrix2 = cameraMatrix(params.CameraParameters2, ...
    params.RotationOfCamera2, params.TranslationOfCamera2);
F = params.FundamentalMatrix;
f1 = params.CameraParameters1.FocalLength;
p1 = params.CameraParameters1.PrincipalPoint;
pxPitch = 0.0022;
intrinsics = [f1(1), 0, p1(1);
                      0, f1(2), p1(2);
                      0, 0, 1]; % mm
                  
rng(1,'twister');

% Create simulated particles in 3D
% origin is the center of the camera X-axis points right, Y-axis points bototm 
nParticles = 200;
centroids = generateCentroids(nParticles, -50, 50, -50, 50, 220, 280);
% lPts = projectPoints(centroids, cameraMatrix1');
% rPts = projectPoints(centroids, cameraMatrix2');
imageSizeY = 1944;
imageSizeX = 2592;
lImg = zeros(1944, 2592) + 50;
rImg = zeros(1944, 2592) + 50;
iParticle = 1;
matchedPoints1 = [];
matchedPoints2 = [];
[columnsInImage rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);

%% Filter out the particles in the imaging frame
lPts = projectPoints(centroids, cameraMatrix1');
rPts = projectPoints(centroids, cameraMatrix2');
newCentroids = [];
for i = 1:nParticles
    xl = floor(lPts(1, i));
    yl = floor(lPts(2, i));
    xr = floor(rPts(1, i));
    yr = floor(rPts(2, i));
    if isInImage(lPts, i) || isInImage(rPts, i)
        newCentroids = [newCentroids; centroids(i, :)];
    end
end

%% Generate 3D point clouds given the shape (cylinder + sphere) per centroids
nParticles = size(newCentroids, 1);
nCylinders = 10;
nSpheres = nParticles - nCylinders;
nCylinderPts = 1e6;
nSpherePts = 1e3;

% All in mm
cHeightMin = 0.3; cHeightMax = 4;
cRadiusMin = 0.1; cRadiusMax = 2.5;
sDiameterMin = 0.05; sDiameterMax = 1;

cHeights = (cHeightMax - cHeightMin) * rand([nCylinders, 1]) + cHeightMin;
cRadii = (cRadiusMax - cRadiusMin) * rand([nCylinders, 1]) + cRadiusMin;
sDiameters = (sDiameterMax - sDiameterMin) * rand([nSpheres, 1]) + sDiameterMin;

% cylinders
yawD = 0; 
pitchD = 90*rand([nCylinders, 1]) -45;
rollD = 90*rand([nCylinders, 1]) - 45;
cylinders = zeros(nCylinders, nCylinderPts, 3);
spheres = zeros(nSpheres, (nSpherePts+1)^2, 3);

for i = 1:nParticles
    if (i <= nCylinders)
        cylinderPts = generateCylinder(cRadii(i), cHeights(i), nCylinderPts);
        cylinderPts = rotateCloud(cylinderPts, yawD, pitchD(i), rollD(i));
        cylinderPts = bsxfun(@plus, cylinderPts, newCentroids(i, :));
        cylinders(i, :, :) = cylinderPts;
        lPts = projectPoints(cylinderPts, cameraMatrix1');
        rPts = projectPoints(cylinderPts, cameraMatrix2');
        for j = 1:size(lPts, 2)
            xl = floor(lPts(1, j))+1;
            yl = floor(lPts(2, j))+1;
            if isInImage(lPts, j)
                lImg(yl, xl) = 255;
            end
        end
        for j = 1:size(rPts, 2)
            xr = floor(rPts(1, j))+1;
            yr = floor(rPts(2, j))+1;
            if isInImage(rPts, j)
                rImg(yr, xr) = 255;
            end
        end
    else
        k = i - nCylinders;
        spherePts = generateSphere(nSpherePts, sDiameters(k));
        spherePts = bsxfun(@plus, spherePts, newCentroids(i, :));
        spheres(k, :, :) = spherePts;
        lPts = projectPoints(spherePts, cameraMatrix1');
        rPts = projectPoints(spherePts, cameraMatrix2');
        for j = 1:size(lPts, 2)
            xl = floor(lPts(1, j))+1;
            yl = floor(lPts(2, j))+1;
            if isInImage(lPts, j)
                lImg(yl, xl) = 255;
            end
        end
        for j = 1:size(rPts, 2)
            xr = floor(rPts(1, j))+1;
            yr = floor(rPts(2, j))+1;
            if isInImage(rPts, j)
                rImg(yr, xr) = 255;
            end
        end
    end
end

%     if isInImage(lPts, i) && isInImage(rPts, i)
%       matchedPoints1 = [matchedPoints1; xl yl];
%       matchedPoints2 = [matchedPoints2; xr yr];
%     end
% 
%     if isInImage(lPts, i)
%       circlePixels = (rowsInImage - yl).^2 ...
%     + (columnsInImage - xl).^2 <= radius.^2;
%       lImg(circlePixels) = 255;
%     end
%     if isInImage(rPts, i)
%       circlePixels = (rowsInImage - yr).^2 ...
%     + (columnsInImage - xr).^2 <= radius.^2;
%       rImg(circlePixels) = 255;
%     end
% epiLines = epipolarLine(F, matchedPoints1);
% points = lineToBorderPoints(epiLines,size(rImg));


% xl=1086.93177507917; yl = 1244.60319725707; %zl=233.5553;

% for i=1:size(cylinderPts, 1)
%     xl = floor(lPts(1, i));
%     yl = floor(lPts(2, i));
%     xr = floor(rPts(1, i));
%     yr = floor(rPts(2, i));
%     lImg(yl, xl) = 255;
%     rImg(yr, xr) = 255;
% %     circlePixels = (rowsInImage - yl).^2 ...
% %     + (columnsInImage - xl).^2 <= radius.^2;
% %       lImg(circlePixels) = 255;
% %             circlePixels = (rowsInImage - yr).^2 ...
% %     + (columnsInImage - xr).^2 <= radius.^2;
% %       rImg(circlePixels) = 255;
% end
% pt3d1 = (230.*inv(intrinsics) * [xl; yl; 1])';
% pt3d2 = (270.*inv(intrinsics) * [xl; yl; 1])';
% pt3d3 = (z.*inv(intrinsics) * [xl; yl; 1])';
% rPtsNew = projectPoints([pt3d1; pt3d2; pt3d3], cameraMatrix2');
% circlePixels = (rowsInImage - yl).^2 ...
%     + (columnsInImage - xl).^2 <= radius.^2;
% lImg(circlePixels) = 255;
% circlePixels = (rowsInImage - rPtsNew(2, 1)).^2 ...
%     + (columnsInImage - rPtsNew(1, 1)).^2 <= radius.^2;
% rImg(circlePixels) = 255;
% circlePixels = (rowsInImage - rPtsNew(2, 2)).^2 ...
%     + (columnsInImage - rPtsNew(1, 2)).^2 <= radius.^2;
% rImg(circlePixels) = 255;
% circlePixels = (rowsInImage - rPtsNew(2, 3)).^2 ...
%     + (columnsInImage - rPtsNew(1, 3)).^2 <= (radius*2).^2;
% rImg(circlePixels) = 255;
figure; 
hold on;
imshow(lImg, [0 255]);
hold off;

figure; 
hold on;
imshow(rImg, [0 255]);
% line(points(:,[1,3])',points(:,[2,4])');
hold off;

% lPts(:, (lPts(1, :) < 0) | (lPts(1, :) > 2592)) = [];
% lPts(:, (lPts(2, :) < 0) | (lPts(2, :) > 1944)) = [];
% rPts(:, (rPts(1, :) < 0) | (rPts(1, :) > 2592)) = [];
% rPts(:, (rPts(2, :) < 0) | (rPts(2, :) > 1944)) = [];

% figure; 
% hold on;
% scatter(lPts(1, :), lPts(2, :));
% xlim([0 2592]);
% ylim([0 1944]);
% hold off;
% figure; 
% hold on;
% scatter(rPts(1, :), rPts(2, :));
% xlim([0 2592]);
% ylim([0 1944]);
% hold off;

function k = drawCircle(img, y, x, radius)
    for i = 1:radius
        for j = 1:radius
            new_x = x+round(sqrt(i^2 + j^2));
            new_y = y+round(sqrt(i^2 + j^2));
            img(new_y, new_x) = 255;
        end
    end
end

function val = isInImage(pts, idx)
    val = (pts(1, idx) >= 0) && (pts(2, idx) >= 0) ...
               && pts(1, idx) <= 2592 && (pts(2, idx) <= 1944);
end

function points2d = projectPoints(points3d, P)
    points3dHomog = [points3d, ones(size(points3d, 1), 1, 'like', points3d)]';
    points2dHomog = P * points3dHomog;
    points2d = bsxfun(@rdivide, points2dHomog(1:2, :), points2dHomog(3, :));
end