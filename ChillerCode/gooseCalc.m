function [greyscale,results,baseline] = gooseCalc(img,grayscale,n,results,t,B,baseline,f,maximox,sv)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This function uses code from the GooseLab (v. 1.26 12-10-2012), a tooolbox which analyzes a     % 
%   video of human skin for the intensity of goosebumps. The code for the GooseLab was developed by %                
%   C. Kaernback and M. Benedek.                                                                    %
%   See:                                                                                            %
%   http://www.goosecam.de/gooselab.html                                                            %  
%   Benedek, M. & Kaernbach, C. (2011). Physiological correlates and emotional specificity          %
%   of human piloerection. Biological Psychology, 86(3), 320-329.                                   %
%   doi: 10.1016/j.biopsycho.2010.12.012.                                                           %
%   Benedek, M., Wilfling, B., Lukas-Wolfbauer, R., Katzur, B. H. & Kaernbach, C. (2010).           %
%   Objective and continuous measurement of piloerection. Psychophysiology,                         % 
%   47 (5), 989-993. doi: 10.1111/j.1469-8986.2010.01003.x                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Function to calculate the intensity of the goosebumps. Arguments are
% the snapshot of the patch of sking, the last greyscale image, the
% number of iterations, the vector with the historic gossebump results
% of the series, the time, the flag for baseline/real data collection,
% the baseline and the figure identificator. It returns the baseline,
% the grayscale image and the historic of results updated




%% define constants
gooserange=[2 7];
spectbyf=2;
detrend_errorlim=4;
detrendfact=30;
convwinsize=2;

%% Selection of central square within the image
s=size(img);
l1=s(1);
l2=s(2);
L = l1;
Lm = L;

d1a = round((1+l1)/2 - (L-1)/2);  
d1e = round((1+l1)/2 + (L-1)/2);  
d2a = round((1+l2)/2 - (L-1)/2);  
d2e = round((1+l2)/2 + (L-1)/2);  
cut = [d1a, d1e, d2a, d2e];
im = img(cut(1):cut(2), cut(3):cut(4), :);   % centered square area
%Plot the snapshot showing the patch of skin
figure(f)
subplot(2,2,[1:2])
imagesc(img);
drawnow;
%% Gray image conversion and detrend
gim = mean(im, 3); % add RGB-channels for gray image

if n==1
    detrend_gray=gim;
    greyscale=gim;
else
    detrend_gray=grayscale;
end

% Adaptive Detrend
detrend_smooth=0;
if detrend_errorlim > 0
    dev = norm(detrend_gray - gim,1);  %check for grey image deviation of last detrend update
else  %non-adaptive, no deviation allowed
    dev = detrend_errorlim + 1;
end

if dev >detrend_errorlim
    detrend_smooth = smooth2(gim, detrendfact, 'mean');
    greyscale = gim; %Reference image for assessment of next need for new detrend  
end

%Detrend
gim = gim - detrend_smooth; %Subtraction of low-frequency image
mgim = mean(gim(:)); % Subtraction of mean to correct for inter-individual differences (i.e. normalization)
sdgim = std(gim(:));
if sdgim > 0.01 %necessary line for black pictures not to result in error
    gim = (gim-mgim);
end

%% 2D- Fourier transform with smoothing by convolution
% Fourier transformation (fft2), shift frequency 0 to the middle (fftshift)
fgim = abs(fftshift(fft2(gim))).^2 / (Lm/2)^2;

% Convolution Window
hw = .5*(1-cos(2*pi*(1:2*convwinsize+1)/(2*convwinsize+2)));
g = hw ./ sum(hw(:));
convwin_fft2 = g'*g;
fgim = conv2(fgim, convwin_fft2, 'same'); %Smoothing FFT2 plot by convolution

%% Goosebump amplitude calculation
% R-Window
xr = zeros(Lm, Lm);
m = (Lm/2)+1;
for xi = 1:Lm
    for yi = 1:Lm
        xr(xi,yi) = norm([xi,yi]-[m,m]);
    end
end
rwin = xr;

% Radial Spectrum
rad = 1:(Lm/2);
radindx = zeros(length(rad), 180);
for phi = 1:180
    x = round(m + cos(phi/180*pi)*(rad-.5));
    y = round(m + sin(phi/180*pi)*(rad-.5)); 
    radindx(:, phi) = (x-1)*Lm+y;
end

fgim = fgim .* rwin .^ spectbyf;

% Mean radial spectrum
radspec = mean(fgim(radindx),2)';

% Get goose-amp
[amp, ~] = max(radspec(gooserange(1):gooserange(2))); %max-amplitude in spectogram (gooserange)
figure(f)
subplot(2,2,[3:4])

%% Updating of results vector and plotting
%default maximum percentage for the Y axis of the figure
maximo=100;

%If the baseline is being collected we save the raw goose data and we do
%not plot anything
if B==1
    results(1,n)=amp;
    results(2,n)=amp;
    plot(NaN(1,n))
    baseline=NaN;
%Once the baseline period has ended, we calculate the baseline as the
%average of the last 10 frames and start plotting
elseif B==0
    baseline=nanmean(results(2,n-11:n-1));
    results(1,1:n)=0;
    plot(results(1,:))
%Real data is being collected
elseif B==2
%   Calculate the percentage of change from the baselin. Save it in results
%   and in save as well the raw values
    aux=(amp-baseline)*100/baseline;
    results(1,n)=aux;
    results(2,n)=amp;
% If the percentage of change is greater than 100, update the Y limit of
% the figure
    if max(results(1,20:end))>maximo
        maximo=floor(max(results(1,:)))+20;
    end
 %If the percentage of change is greater than 30%, a goosebump is detected. Save that result  
    if results(1,n)>30
        results(3,n)=1;
    else
        results(3,n)=0;
    end
    %Update the current figure by plotting the vector with the percentage
    %of change only for those moments in which a goosebump is detected
    goose=NaN(1,maximox);
    goose(1:n)=0;
    ig=find(results(3,:)==1);
    goose(ig)=results(1,ig);
    plot(1:maximox,goose,'r','LineWidth',1)
    
    if results(1,n)>30
        title('GOOSEBUMP DETECTED','Color','r')
    else
        title('')       
    end
end

xticks([0 n])
xticklabels([0 t])
xlabel('Time (s)')
ylabel('Goose Amplitude %')
xlim([1 maximox])
ylim([-5 maximo])
%Save the figure for the current snapshot
if sv==1
saveas(gcf,['Chiller' num2str(n) '.fig'])
end

end
