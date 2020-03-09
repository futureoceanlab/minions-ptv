function cloudPts = generateCylinder(radius, height, nPoints)
% Generate a cylinder with custom radius and height centered around (0, 0,
% 0)
    A=rand(2, nPoints/2);
    P=(2*pi).*A(1,1:end); % random angle 
    
    % random points around the cylindrical surface
    xc= radius.*cos(P);
    yc= radius.*sin(P);
    zc= height.*A(2,1:end);
    
    % random radius for top/bottom surface
    r = rand([1, nPoints/4]).* radius;
    xc2 = r.*cos(P(1:nPoints/4)); yc2 = r.*sin(P(1:nPoints/4));
    zcBottom = zeros(1, nPoints/4) ;
    zcTop = ones(1, nPoints/4).* height;
    xc = [xc xc2 xc2]';
    yc = [yc yc2 yc2]';
    zc = [zc zcTop zcBottom]' - height/2;
    cloudPts = [xc yc zc];
    
%     plot3(cloudPts(:, 1), cloudPts(:, 2), cloudPts(:, 3), '.');
%     cylinderPts = bsxfun(@plus, cylinderPts, [cx cy cz]);
end