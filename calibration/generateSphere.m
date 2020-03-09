function cloudPts = generateSphere(nPoints, dimater)
    [x, y, z] = sphere(nPoints);
    cloudPts = [x(:), y(:), z(:)] * dimater; % in mm
end