function [blob_rows, blob_cols, blob_sizes] = base_detector(image, sigma, sublevels, octaves, threshold, resize_image)

levels = sublevels * octaves + 1;
k = 2 ^ (1/sublevels);

[rows, cols] = size(image);

scale_space = zeros(rows, cols, levels);
scale_max = zeros(rows, cols, levels);

tic
if resize_image
    filter_size = 2 * round(3 * sigma) + 1;
    filter = sigma^2 * fspecial('log', filter_size, sigma);
        
    for scale = 1:levels        
        curr_image = imresize(image, 1/(k^(scale - 1)), 'bicubic');
        curr_filtered = imfilter(curr_image, filter, 'same', 'replicate') .^ 2;
        scale_space(:, :, scale) = imresize(curr_filtered, size(image), 'bicubic');
    end
else    
    for scale = 1:levels
        curr_sigma = sigma * k^(scale-1);
        curr_filter_size = 2 * round(3 * curr_sigma) + 1;
        curr_filter = curr_sigma^2 * fspecial('log', curr_filter_size, curr_sigma);
        
        curr_filtered = imfilter(image, curr_filter, 'same', 'replicate') .^ 2;
        scale_space(:, :, scale) = curr_filtered;
        
        disp(curr_sigma);
        figure(1); clf; imagesc(curr_filtered); colorbar;
        drawnow;
        pause(0.01);
    end
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

for scale=1:levels
    [rows, cols] = find(scale_max(:, :, scale) >= threshold);
    sizes = sigma * k^(scale-1) * sqrt(2) * ones(length(rows), 1); 
    
    blob_rows = [blob_rows; rows];
    blob_cols = [blob_cols; cols];
    blob_sizes = [blob_sizes; sizes];
end