clear all;
clc;

%Input image
img = imread ('motor.png');
[rows,cols,dims] = size(img);

if dims == 3
    Img = rgb2gray(Img);
end

%Show input image
figure, imshow(img);
% img = rgb2gray(img);

% img = double (img);
%Value for Thresholding  -- recommended ratio between low and high thresholds is between 2:1 and 3:1
T_Low = 0.075;
T_High = 0.175;
  
 B = fspecial('gaussian', [3 3], 1.4);
% Convolution of image by Gaussian Coefficient
 img = conv2(img, B, 'same');
%  img = mat2gray(img);
 figure, imshow(img);
 
 MinImg = min(img,[], 'all');
 MaxImg = max(img,[], 'all');
 fprintf('%s MinImg %d, MaxImg %d \n',class(img), MinImg, MaxImg);
 
%Filter for horizontal and vertical direction 
  KGx = [-1, 0, 1; -2, 0, 2; -1, 0, 1];
  KGy = [1, 2, 1; 0, 0, 0; -1, -2, -1];


%Convolution by image by horizontal and vertical filter
Filtered_X = conv2(img, KGx, 'same');
Filtered_Y = conv2(img, KGy, 'same');



Minx = min(Filtered_X,[], 'all');
Maxx = max(Filtered_X,[], 'all');
fprintf('%s MinX %d, MaxX %d \n',class(Filtered_X), Minx, Maxx);

Miny = min(Filtered_Y,[], 'all');
Maxy = max(Filtered_Y,[], 'all');
fprintf('%s MinY %d, MaxY %d \n',class(Filtered_Y), Miny, Maxy);



%Calculate directions/orientations
arah = atan2 (Filtered_Y, Filtered_X);

arah = arah*180/pi; %convert fron radian to degree
pan=size(img,1);
leb=size(img,2);

%Adjustment for negative directions, making all directions positive
for i=1:pan
    for j=1:leb
        if (arah(i,j)<0) 
            arah(i,j)=360+arah(i,j);
        end;
    end;
end;

arah2=zeros(pan, leb);

%Adjusting directions to nearest 0, 45, 90, or 135 degree
for i = 1  : pan
    for j = 1 : leb
        if ((arah(i, j) >= 0 ) && (arah(i, j) < 22.5) || (arah(i, j) >= 157.5) && (arah(i, j) < 202.5) || (arah(i, j) >= 337.5) && (arah(i, j) <= 360))
            arah2(i, j) = 0;
        elseif ((arah(i, j) >= 22.5) && (arah(i, j) < 67.5) || (arah(i, j) >= 202.5) && (arah(i, j) < 247.5))
            arah2(i, j) = 45;
        elseif ((arah(i, j) >= 67.5 && arah(i, j) < 112.5) || (arah(i, j) >= 247.5 && arah(i, j) < 292.5))
            arah2(i, j) = 90;
        elseif ((arah(i, j) >= 112.5 && arah(i, j) < 157.5) || (arah(i, j) >= 292.5 && arah(i, j) < 337.5))
            arah2(i, j) = 135;
        end;
    end;
end;

% arah3 = 255 * mat2gray(arah2);
% figure, imshow(arah3);

%Calculate magnitude
magnitude2 = sqrt((Filtered_X.^2) + (Filtered_Y.^2));

MinMag = min(magnitude2,[], 'all');
MaxMag = max(magnitude2,[], 'all');

fprintf('%s MinMag %d, MaxMag %d \n', class(magnitude2), MinMag, MaxMag);
 

 magnitude2 =   mat2gray(magnitude2);
%figure, imshow(magnitude2);title('Magnitude');


BW = zeros (pan, leb);

%Non-Maximum Supression
for i=2:pan-1
    for j=2:leb-1
        if (arah2(i,j)==0)
            BW(i,j) = (magnitude2(i,j) == max([magnitude2(i,j), magnitude2(i,j+1), magnitude2(i,j-1)]));
        elseif (arah2(i,j)==45)
            BW(i,j) = (magnitude2(i,j) == max([magnitude2(i,j), magnitude2(i+1,j-1), magnitude2(i-1,j+1)]));
        elseif (arah2(i,j)==90)
            BW(i,j) = (magnitude2(i,j) == max([magnitude2(i,j), magnitude2(i+1,j), magnitude2(i-1,j)]));
        elseif (arah2(i,j)==135)
            BW(i,j) = (magnitude2(i,j) == max([magnitude2(i,j), magnitude2(i+1,j+1), magnitude2(i-1,j-1)]));
        end;
    end;
end;

BW = BW.*magnitude2;

MinBW = min(BW,[], 'all');
MaxBW = max(BW,[], 'all');
fprintf('%s MinBW %d, MaxBW %d \n',class(BW), MinBW, MaxBW);

% figure, imshow(BW);

%Hysteresis Thresholding
T_Low = T_Low * max(max(BW));
T_High = T_High * max(max(BW));

T_res = zeros (pan, leb);

for i = 1  : pan  
    for j = 1 : leb
        if (BW(i, j) < T_Low)
            T_res(i, j) = 0;
        elseif (BW(i, j) > T_High)
            T_res(i, j) = 1;
        %Using 8-connected components
        elseif ( BW(i+1,j)>T_High || BW(i-1,j)>T_High || BW(i,j+1)>T_High || BW(i,j-1)>T_High || BW(i-1, j-1)>T_High || BW(i-1, j+1)>T_High || BW(i+1, j+1)>T_High || BW(i+1, j-1)>T_High)
            T_res(i,j) = 1;
        end;
    end;
end;

edge_final = uint8(T_res.*255);
final =  mat2gray(edge_final);
%Show final edge detection result

 imshowpair(magnitude2, final, 'montage');
  title('(left) Gradient Magnitude, (right) Final Result After NMS')
% 
% % figure, imshow(final);title('Final image');
