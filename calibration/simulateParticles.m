clear;
load("params.mat", 'params');
cameraMatrix1 = cameraMatrix(params.CameraParameters1, eye(3), [0 0 0]);
cameraMatrix2 = cameraMatrix(params.CameraParameters2, ...
    params.RotationOfCamera2, params.TranslationOfCamera2);
F = params.FundamentalMatrix;

% Create simulated particles in 3D
% origin is the center of the camera X-axis points right, Y-axis points bototm 
nParticles = 100;
rng(0,'twister');
xmin = -50;
xmax = 50;
ymin = -50;
ymax = 50;
zmin = 220;
zmax = 280;
xPts = (xmax-xmin).*rand(nParticles,1) + xmin;
yPts = (ymax-ymin).*rand(nParticles,1) + ymin;
zPts = (zmax-zmin).*rand(nParticles,1) + zmin;
centroids = [xPts yPts zPts];
lPts = projectPoints(centroids, cameraMatrix1');
rPts = projectPoints(centroids, cameraMatrix2');
imageSizeY = 1944;
imageSizeX = 2592;
lImg = zeros(1944, 2592);
rImg = zeros(1944, 2592);
iParticle = 1;
matchedPoints1 = [];
matchedPoints2 = [];
[columnsInImage rowsInImage] = meshgrid(1:imageSizeX, 1:imageSizeY);
radius = 5;

% for i = 1:nParticles
%   xl = floor(lPts(1, i));
%   yl = floor(lPts(2, i));
%   xr = floor(rPts(1, i));
%   yr = floor(rPts(2, i));
%   radius = 5;
%    if isInImage(lPts, i) && isInImage(rPts, i)
%       iParticle = iParticle + 1; 
%       if mod(iParticle, 5) == 2
%           radius = 5 + iParticle;
%       end
%       matchedPoints1 = [matchedPoints1; xl yl];
%       matchedPoints2 = [matchedPoints2; xr yr];
%    end
%    
%    if isInImage(lPts, i)
%       circlePixels = (rowsInImage - yl).^2 ...
%     + (columnsInImage - xl).^2 <= radius.^2;
%       lImg(circlePixels) = 255;
%    end
%    if isInImage(rPts, i)
%       circlePixels = (rowsInImage - yr).^2 ...
%     + (columnsInImage - xr).^2 <= radius.^2;
%       rImg(circlePixels) = 255;
%    end
%    
% 
% end
% epiLines = epipolarLine(F, matchedPoints1);
% points = lineToBorderPoints(epiLines,size(rImg));

f1 = params.CameraParameters1.FocalLength;
p1 = params.CameraParameters1.PrincipalPoint;
pxPitch = 0.0022;
intrinsics = [f1(1), 0, p1(1);
                      0, f1(2), p1(2);
                      0, 0, 1]; % mm
% xl=1086.93177507917; yl = 1244.60319725707; %zl=233.5553;
% [x, y, z] = sphere(20);
% spherePts = [x(:), y(:), z(:)]/10;
% spherePts = bsxfun(@plus,spherePts,centroids(17, :));
nPoints = 1e4;
A=rand(2,nPoints);
R= 0.5;
H= 1;
P=(2*pi).*A(1,1:end);
xc= R.*cos(P);
yc= R.*sin(P);
zc= H.*A(2,1:end);
% random radius 
r = rand([1, nPoints/2]).* R;
xc2 = r.*cos(P(1:nPoints/2)); yc2 = r.*sin(P(1:nPoints/2));
zc2 = zeros(1, nPoints/2);
zc3 = ones(1, nPoints/2).* H;
xc = [xc xc2 xc2]';
yc = [yc yc2 yc2]';
zc = [zc zc2 zc3]';
yawD = deg2rad(45); pitchD = deg2rad(30); rollD = deg2rad(0);
rotX = [cos -sin 0
% plot3(xc, yc, zc, '.');
% t = 0:pi/10:2*pi;
% [xc, yc, zc] = cylinder(2+cos(t), 1e5);
cylinderPts = [xc yc zc];
cylinderPts = bsxfun(@plus,cylinderPts,centroids(17, :));
lPts = projectPoints(cylinderPts, cameraMatrix1');
rPts = projectPoints(cylinderPts, cameraMatrix2');
for i=1:size(cylinderPts, 1)
    xl = floor(lPts(1, i));
    yl = floor(lPts(2, i));
    xr = floor(rPts(1, i));
    yr = floor(rPts(2, i));
    lImg(yl, xl) = 255;
    rImg(yr, xr) = 255;
%     circlePixels = (rowsInImage - yl).^2 ...
%     + (columnsInImage - xl).^2 <= radius.^2;
%       lImg(circlePixels) = 255;
%             circlePixels = (rowsInImage - yr).^2 ...
%     + (columnsInImage - xr).^2 <= radius.^2;
%       rImg(circlePixels) = 255;
end
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
imshow(lImg);
hold off;

figure; 
hold on;
imshow(rImg);
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