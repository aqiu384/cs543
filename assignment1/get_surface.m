function  height_map = get_surface(surface_normals, image_size, method)
% surface_normals: 3 x num_pixels array of unit surface normals
% image_size: [h, w] of output height map/image
% height_map: height map of object

%% <<< fill in your code below >>>
TRIALS = 20;

h = image_size(1);
w = image_size(2);
fx = surface_normals(:, :, 1) ./ surface_normals(:, :, 3);
fy = surface_normals(:, :, 2) ./ surface_normals(:, :, 3);

    switch method
        case 'row'
            height_map = bsxfun(@plus, cumsum(fy, 1), cumsum(fx(1, :), 2));
        case 'column'
            height_map = bsxfun(@plus, cumsum(fx, 2), cumsum(fy(:, 1), 1));
        case 'average'
            height_map = bsxfun(@plus, cumsum(fy, 1), cumsum(fx(1, :), 2));
            height_map =  height_map + bsxfun(@plus, cumsum(fx, 2), cumsum(fy(:, 1), 1));
            height_map = height_map ./ 2;
        case 'random'
            sum_map = zeros(image_size);
            
            for TRIAL = 1:TRIALS
                height_map = zeros(image_size);
                height_map(1, :) = cumsum(fx(1, :), 2);
                height_map(:, 1) = cumsum(fy(:, 1), 1);

                coin_flips = randi(2, h, w);
                coin_flips = (coin_flips == 1);

                for row = 2:h
                    for col = 2:w
                        if coin_flips(row, col)
                            height_map(row, col) = height_map(row - 1, col) + fy(row, col);
                        else
                            height_map(row, col) = height_map(row, col - 1) + fx(row, col);
                        end
                    end
                end
                
                sum_map = sum_map + height_map;
            end
            
            height_map = sum_map / TRIALS;
        case 'dummy'
            height_map = zeros(image_size);
            
            for row = 1:h
                for col = 1:w
                    total_sum = 0;
                    
                    for trials = 1:TRIALS
                        steps = randperm(row + col - 2);
                        curr_row = 1;
                        curr_col = 1;

                        for step = 1:length(steps)
                            if steps(step) < row
                                total_sum = total_sum + fy(curr_row, curr_col);
                                curr_row = curr_row + 1;
                            else
                                total_sum = total_sum + fx(curr_row, curr_col);
                                curr_col = curr_col + 1;
                            end
                        end
                    end
                        
                    height_map(row, col) = total_sum / TRIALS;
                end
            end
    end
    
end

