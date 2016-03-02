function show_all_ellipses(I, cx, cy, majors, minors, color, ln_wid)
%% I: image on top of which you want to display the circles
%% cx, cy: column vectors with x and y coordinates of circle centers
%% rad: column vector with radii of circles. 
%% The sizes of cx, cy, and rad must all be the same
%% color: optional parameter specifying the color of the circles
%%        to be displayed (red by default)
%% ln_wid: line width of circles (optional, 1.5 by default

if nargin < 5
    color = 'r';
end

if nargin < 6
   ln_wid = 1.5;
end

imshow(I); hold on;

theta = 0:0.1:(2*pi+0.1);

cx1 = cx(:,ones(size(theta)));
cy1 = cy(:,ones(size(theta)));
ax1 = majors(:,ones(size(theta)));
ay1 = majors(:,2*ones(size(theta)));
bx1 = minors(:,ones(size(theta)));
by1 = minors(:,2*ones(size(theta)));
theta = theta(ones(size(cx1,1),1),:);

X = cx1 + ax1.*sin(theta) + bx1.*cos(theta);
Y = cy1 + ay1.*sin(theta) + by1.*cos(theta);
line(X', Y', 'Color', color, 'LineWidth', ln_wid);

title(sprintf('%d circles', size(cx,1)));