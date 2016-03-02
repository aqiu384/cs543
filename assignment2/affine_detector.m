function [blob_rows, blob_cols, major_axis, minor_axis] = affine_detector(image, sigma, sublevels, octaves, threshold, resize_image)

levels = sublevels * octaves + 1;
k = 2 ^ (1/sublevels);

[rows, cols] = size(image);

scale_space = zeros(rows, cols, levels);
scale_max = zeros(rows, cols, levels);

tic
filter_size = 2 * round(3 * sigma) + 1;
filter = sigma^2 * fspecial('log', filter_size, sigma);

for scale = 1:levels        
    curr_image = imresize(image, 1/(k^(scale - 1)), 'bicubic');
    curr_filtered = imfilter(curr_image, filter, 'same', 'replicate') .^ 2;
    scale_space(:, :, scale) = imresize(curr_filtered, size(image), 'bicubic');
end
toc

tic
SUPPRESS_SIZE = 3;

for scale = 1:levels
    scale_max(:, :, scale) = ordfilt2(scale_space(:, :, scale), SUPPRESS_SIZE^2, true(SUPPRESS_SIZE));
end
toc

tic
scale_max(:, :, 1) = max(scale_max(:, :, 1:2), [], 3);

for scale = 2:levels-1
    scale_max(:, :, scale) = max(scale_max(:, :, scale-1:scale+1), [], 3);
end

scale_max(:, :, levels) = max(scale_max(:, :, levels-1:levels), [], 3);
toc

scale_max = scale_max .* (scale_max == scale_space);

blob_rows = [];   
blob_cols = [];   
blob_sizes = [];
blob_levels = [];

for scale=1:levels
    [rows, cols] = find(scale_max(:, :, scale) >= threshold);
    sizes = sigma * k^(scale-1) * sqrt(2) * ones(length(rows), 1); 
    
    blob_rows = [blob_rows; rows];
    blob_cols = [blob_cols; cols];
    blob_sizes = [blob_sizes; sizes];
    blob_levels = [blob_levels; scale * ones(length(rows), 1)];
end

[rows, cols] = size(image);

dx = [-1 0 1; -1 0 1; -1 0 1];
dy = dx';

Ix = conv2(image, dx, 'same');
Iy = conv2(image, dy, 'same');

Isquares = zeros(rows, cols, 3);
Isquares(:, :, 1) = Ix.^2;
Isquares(:, :, 2) = Iy.^2;
Isquares(:, :, 3) = Ix.*Iy;
Ispace = zeros(rows, cols, 3, levels);

tic
filter_size = 2 * round(3 * sigma) + 1;
filter = fspecial('gaussian', filter_size, sigma);
 
for scale = 1:levels
    for square = 1:3
        curr_image = imresize(Isquares(:, :, square), 1/(k^(scale - 1)), 'bicubic');
        curr_filtered = imfilter(curr_image, filter, 'same', 'replicate');
        Ispace(:, :, square, scale) = imresize(curr_filtered, size(image), 'bicubic');
    end
end
toc

major_axis = zeros(2, length(blob_rows));
minor_axis = zeros(2, length(blob_rows));

for index = 1:length(blob_rows)
    curr_row = blob_rows(index);
    curr_col = blob_cols(index);
    curr_rad = blob_sizes(index);
    curr_lev = blob_levels(index);
    
    curr_d = Ispace(curr_row, curr_col, :, curr_lev);
    secdev = [curr_d(1), curr_d(3); curr_d(3), curr_d(2)];
    
    [V, D] = eig(secdev);
    scale_factor = diag(D) / sum(diag(D)) * 2 * curr_rad;
    
    major_axis(:, index) = V(:, 2) * scale_factor(1);
    minor_axis(:, index) = V(:, 1) * scale_factor(2);
end

major_axis = major_axis';
minor_axis = minor_axis';