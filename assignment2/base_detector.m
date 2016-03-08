function [blob_rows, blob_cols, blob_sizes] = base_detector(image, min_sigma, max_sigma, octave_size, supress_size, threshold, resize_image)

tic
octaves = log(max_sigma / min_sigma) / log(2);
levels = octave_size * octaves + 1;
k = 2 ^ (1/octave_size);

[rows, cols] = size(image);

scale_space = zeros(rows, cols, levels);
scale_max = zeros(rows, cols, levels);

if resize_image
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
else    
    for scale = 1:levels
        curr_sigma = sigma * k^(scale-1);
        curr_filter_size = 2 * round(3 * curr_sigma) + 1;
        curr_filter = curr_sigma^2 * fspecial('log', curr_filter_size, curr_sigma);
        
        curr_filtered = imfilter(image, curr_filter, 'same', 'replicate') .^ 2;
        scale_space(:, :, scale) = curr_filtered;
    end
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

for scale=1:levels
    [rows, cols] = find(scale_max(:, :, scale) >= threshold);
    sizes = min_sigma * k^(scale) * sqrt(2) * ones(length(rows), 1); 
    
    blob_rows = [blob_rows; rows];
    blob_cols = [blob_cols; cols];
    blob_sizes = [blob_sizes; sizes];
end

toc