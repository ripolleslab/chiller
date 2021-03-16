function sdata = smooth2(data, winwidth, type)

if nargin < 3
    type = 'mean';
end

%data = data(:)'; %ensure data as a row;
winwidth = ceil(winwidth/2)*2;   % force even winsize for odd window
switch type,
    case 'mean'
        window = ones(winwidth+1, winwidth+1); %moving average
    case 'gauss'
        g = exp(-(((.5:winwidth)-winwidth/2)/(winwidth*.5)).^2);
        window = g'*g;
    otherwise
        error('Unknown type')
end
window = window / sum(window(:));  % normalize window
s = size(data);
w = winwidth/2;
data_ext = zeros(s + winwidth);
data_ext(1:w, 1:w) = data(1,1); %left-upper
data_ext(1:w, w+1:w+s(2)) = ones(w,1) * data(1,:); %mid-upper
data_ext(1:w, w+s(2)+1:end) = data(1,end); %right-upper

data_ext(w+1:w+s(1), 1:w) = data(:,1) * ones(1,w); %left-mid
data_ext(w+1:w+s(1), w+1:w+s(2)) = data; %center
data_ext(w+1:w+s(1), w+s(2)+1:end) = data(:,end) * ones(1,w); %right-mid

data_ext(w+s(1)+1:end, 1:w) = data(end,1); %left-lower
data_ext(w+s(1)+1:end, w+1:w+s(2)) = ones(w,1) * data(end,:); %mid-lower
data_ext(w+s(1)+1:end, w+s(2)+1:end) = data(end,end); %right-lower

sdata_ext = conv2(data_ext, window); % convolute with window
sdata = sdata_ext(1+winwidth : end-winwidth,1+winwidth : end-winwidth); %cut to data length