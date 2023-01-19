function err = sem(data, dim, dim_num_samples, sampleSize)
% err = sem(data)
%conversion from standard deviation to standard error of the mean

% enter 

if nargin == 1
    dim = 1;
    dim_num_samples = dim;
elseif nargin == 2
    dim_num_samples = dim;
end 



% sort out what the sample size is (calculate from dim or take direct input)
if nargin == 3
    switch dim_num_samples %you can input the dimension to look at. 
        case 2
            sampleSize = sum(~isnan(data(1,:)));
        case 1
            sampleSize = sum(~isnan(data(:,1)));
    end
end

st_err = nanstd(data,0,dim);
err = st_err / sqrt(sampleSize);



% size(data,dim_num_samples)
end