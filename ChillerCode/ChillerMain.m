% Clear the workspace, clean the terminal and close all figures
clear
clc
close all
%Number of snapshots until baseline calculation. The baseline is calculated
%from the latest 10 snapshots
Nbaseline=20;
%Name of the folder where the data will be saved
name='test';
%uncomment in case you want to play a song using matlab. This will load the
%song and will have it ready to be played once the goosebump recording
%starts
% [y, Fs] = audioread('pathtoaudiofile.mp3');
% play=1;

%Create a Raspebrry Pi object and connect to the Raspberry Pi Zero that
%lies at the core of the CHILLER. You need the IP adress (the laptop/desktop and the CHILLER
%have to be connected to the same Wi-Fi Network) and the user and password
%that you chose when you set the OS of the Raspberry PI Zero. Bellow you
%have examples of those
rpi = raspi('192.168.8.192','pi','pi');
%Create a camera object with a low resolution to speed things up
cam = cameraboard(rpi,'Resolution','320x240');
%Create a folder to save the data and access it
mkdir (name)
cd (name)

% Set the main variables and take note of the time of start. Results has
% three vectors, one with the raw goosebumps data, the second with the
% goosebumps data transformed to percentage of change from the baseline and
% a third vector that indicates the presence (1) or absence (0) of goosebumps
% A goosebumps is present if there is a change of 20% from the baseline
results=NaN(3,300);
grayscale=[];
baseline=[];
B=1;
TStart=tic;
%Maximum number of snapshots of the skin taken. Note that on average we
%take one snapshot every 0.5 seconds aproximately. This fratime will depend on the
%laptop/Desktop doing the computation
maxsnaps=400;

%Loop until the maximum number of snapshots has been taken
for ii = 1:maxsnaps
    %Code to measure how long does it take to collect and process each
    %patch of skin
    if ii>1
        timerec(ii)=toc(TSnapShot);
    end
    TSnapShot=tic;
    
    %take a snapshot of the patch of skin
    img = snapshot(cam);
    
    %If the baseline is being collected, light the LED strip in red
    if B==1
        instr=char(join(["python -c'import blinkt;blinkt.set_all(255,0,0,1); blinkt.show();blinkt.set_clear_on_exit(False)'"]));
        system(rpi,instr);
    end
    %Once the number of snapshots for the baseline has been collected, turn
    %the flag for the baseline off and turn of the LED strip
    if (ii)==Nbaseline
        B=0;
        instr=char(join(["python -c'import blinkt;blinkt.set_all(255,0,0,0); blinkt.show();blinkt.set_clear_on_exit(False)'"]));
        system(rpi,instr);
        
        %Once the baseline has been collected turn on the flag for normal data
        %collelction
    elseif (ii)>Nbaseline
        %Uncomment if you want to play a song just as real data is being
        %collected
        %if play==1
        %    sound(y, Fs, 16);
        %    play=0;
        %end
        B=2;
    end
    
    %Measure time passed since the beggining and if plot a new figure in
    %the first iteration
    t(ii)=toc(TStart);
    if ii==1
        f=figure;
        
    end
    %Function to calculate the intensity of the goosebumps. Arguments are
    %the snapshot of the patch of sking, the last greyscale image, the
    %number of iterations, the vector with the historic gossebump results
    %of the series, the time, the flag for baseline/real data collection,
    %the baseline and the figure identificator. It returns the baseline,
    %the grayscale image and the historic of results updated
    [grayscale,results,baseline]=gooseCalc(img,grayscale,ii,results,ceil(t(ii)),B,baseline,f,maxsnaps,1);
    
    %Check wether the output of the present image there is a goosebump
    %present. If there is one, transform the intensity of the goosebump to
    % LEDValue. LEDValue is the intensity of the light emitted by the LED
    % strip and is a value between 0 and 1. Here we divide it by 100 so
    % that the intensity of the goosebumps detected are reflected in the
    % LED Strip. That is, a goosebump with 80% of change from baseline will
    % elicit a LED green light of 0.8 of intensity (80% of the maximum intensity
    % that the LED strip can emmit). Goosebumps with an intensity above 100% of the change from
    % baseline result in the LED emmiting its maximum light intensity
    goo=results(3,ii);
    if isfinite(goo)
        if goo==1
            LEDValue=results(1,ii)/100;
        elseif goo==0
            LEDValue=0;
        end
        instr=char(join(["python -c'import blinkt;blinkt.set_all(0,255,0," num2str(LEDValue) "); blinkt.show();blinkt.set_clear_on_exit(False)'"]));
        system(rpi,instr);
    end
    %Set the background of the figure to whute
    set(gcf,'color','w');
    % Save the results and the vectors with time information
    if ii>1
        save chiller_results results timerec t
    end
end

