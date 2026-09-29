clear;
clc;
close all;

IMG_WIDTH  = 64;
IMG_HEIGHT = 64;
NUM_PIXELS = IMG_WIDTH * IMG_HEIGHT;


%% ============================================================
% REBUILD IMAGE1
% ============================================================

fid = fopen('../memory/image1.hex', 'r');

data1 = fscanf(fid, '%x');

fclose(fid);

data1 = uint8(data1);

if length(data1) ~= NUM_PIXELS
    error('Image1 HEX does not contain 4096 pixels');
end

img1_rebuilt = reshape(data1, ...
    [IMG_WIDTH IMG_HEIGHT])';

figure;
imshow(img1_rebuilt);

title('Rebuilt Image1');


%% ============================================================
% REBUILD IMAGE2
% ============================================================

fid = fopen('../uart/image2.hex', 'r');

data2 = fscanf(fid, '%x');

fclose(fid);

data2 = uint8(data2);

if length(data2) ~= NUM_PIXELS
    error('Image2 HEX does not contain 4096 pixels');
end

img2_rebuilt = reshape(data2, ...
    [IMG_WIDTH IMG_HEIGHT])';

figure;
imshow(img2_rebuilt);

title('Rebuilt Image2');