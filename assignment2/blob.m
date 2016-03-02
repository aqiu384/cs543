clear all;

I = mat2gray(rgb2gray(imread('butterfly.jpg')));
[r, c, major, minor] = reject_detector(I, 3, 4, 2, 0.01, 0.45);
% dog_detector(I, 3, 4, 4, 0.3)
% base_detector(I, 3, 4, 3, 0.01, true);

figure(2); clf;
show_all_ellipses(I, c, r, major, minor, 'r', 1.5);
pause(.1);
drawnow;