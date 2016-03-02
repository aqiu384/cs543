function [albedo_image, surface_normals] = photometric_stereo(imarray, light_dirs)
% imarray: h x w x Nimages array of Nimages no. of images
% light_dirs: Nimages x 3 array of light source directions
% albedo_image: h x w image
% surface_normals: h x w x 3 array of unit surface normals


%% <<< fill in your code below >>>
[h, w, N] = size(imarray);
imarray = reshape(imarray, [h * w, N])';
surface_normals = reshape((light_dirs \ imarray)', [h, w, 3]);
albedo_image = sum(surface_normals .^ 2, 3) .^ 0.5;
surface_normals = bsxfun(@rdivide, surface_normals, albedo_image);
end

