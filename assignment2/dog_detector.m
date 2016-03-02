function [blob_rows, blob_cols, blob_sizes] = dog_detector(image, sigma, sublevels, octaves, threshold)

levels = sublevels * octaves + 1;
k = 2 ^ (1/sublevels);

[rows, cols] = size(image);

scale_octave = zeros(rows, cols, sublevels + 1);
scale_space = zeros(rows, cols, levels);
scale_max = zeros(rows, cols, levels);

tic
filter_size = 2 * round(3 * sigma) + 1;
filter = sigma^2 * fspecial('gaussian', filter_size, sigma);

for octave = 0:octaves-1
    for sublevel = 0:sublevels
        curr_image = imresize(image, 1/(k^(octave * sublevels + sublevel)), 'bicubic');
        curr_filtered = imfilter(curr_image, filter, 'same', 'replicate') .^ 2;
        scale_octave(:, :, sublevel + 1) = imresize(curr_filtered, size(image), 'bicubic');
    end
    
    for sublevel = 1:sublevels
        scale_space(:, :, octave * sublevels + sublevel) = scale_octave(:, :, sublevel) - scale_octave(:, :, sublevel + 1);
        imshow(scale_space(:, :, octave * sublevels + sublevel));
        pause(.1);
    end
end

filter = sigma^2 * fspecial('log', filter_size, sigma);
curr_image = imresize(image, 1/(k^(octaves * sublevels)), 'bicubic');
curr_filtered = imfilter(curr_image, filter, 'same', 'replicate') .^ 2;
scale_space(:, :, octaves * sublevels + 1) = imresize(curr_filtered, size(image), 'bicubic');
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