clear all;

I = mat2gray(rgb2gray(imread('assignment2_images/butterfly.jpg')));
[r, c, radii] = base_detector(I, 2, 2*2^4, 4, 7, 0.005, true);

% [r, c, radii] = dog_detector(image, 2, 2*2^4, 4, 7, 0.001);
% [r, c, major, minor] = reject_detector(I, 2, 2*2^4, 4, 7, 0.005, 0.1);

figure(2); clf;
show_all_circles(I, c, r, radii, 'r', 1.5);
% show_all_ellipses(I, c, r, major, minor, 'r', 1.5);
pause(.1);
drawnow;