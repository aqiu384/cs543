function [blob_rows, blob_cols, major_axis, minor_axis] = reject_detector(image, min_sigma, max_sigma, octave_size, supress_size, threshold, reject_threshold)

tic
octaves = log(max_sigma / min_sigma) / log(2);
levels = octave_size * octaves + 1;
k = 2 ^ (1/octave_size);

[rows, cols] = size(image);

scale_space = zeros(rows, cols, levels);
scale_max = zeros(rows, cols, levels);

filter_size = 2 * round(3 * min_sigma) + 1;
filter = min_sigma^2 * fspecial('log', filter_size, min_sigma);

for scale = 1:levels  
    curr_image = imresize(image, 1/(k^(scale - 1)), 'bicubic');   
    curr_filtered = imfilter(curr_image, filter, 'same', 'replicate') .^ 2;        

    border_size = ceil(min_sigma * k^(scale-1) * sqrt(2));
    scale_space(:, :, scale) = imresize(curr_filtered, size(image), 'bicubic');

    temp_scale = ordfilt2(scale_space(:, :, scale), supress_size^2, true(supress_size));
    temp_scale(1:border_size, :) = 0;
    temp_scale(end-border_size+1:end, :) = 0;
    temp_scale(:, 1:border_size) = 0;
    temp_scale(:, end-border_size+1:end) = 0;

    scale_max(:, :, scale) = temp_scale;        
end

scale_max(:, :, 1) = max(scale_max(:, :, 1:2), [], 3);

for scale = 2:levels-1
    scale_max(:, :, scale) = max(scale_max(:, :, scale-1:scale+1), [], 3);
end

scale_max(:, :, levels) = max(scale_max(:, :, levels-1:levels), [], 3);

scale_max = scale_max .* (scale_max == scale_space);

blob_rows = [];   
blob_cols = [];   
blob_sizes = [];
blob_levels = [];

for scale=1:levels
    [rows, cols] = find(scale_max(:, :, scale) >= threshold);
    sizes = min_sigma * k^(scale-1) * sqrt(2) * ones(length(rows), 1); 
    
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
min_sigma = min_sigma;
filter_size = 2 * round(3 * min_sigma) + 1;
filter = fspecial('gaussian', filter_size, min_sigma);
 
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
min_maj = zeros(length(blob_rows), 1);

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
    min_maj(index) = scale_factor(1) / scale_factor(2);
end

major_axis = major_axis';
minor_axis = minor_axis';

min_maj = (min_maj > reject_threshold);

blob_rows = blob_rows(min_maj);
blob_cols = blob_cols(min_maj);

major_axis = major_axis(min_maj, :);
minor_axis = minor_axis(min_maj, :);