clear;
clc;
close all;

IMG_WIDTH  = 64;
IMG_HEIGHT = 64;


%% ============================================================
% IMAGE 1
% ============================================================

img1 = imread('images/image1.jpg');     % Read Image1

if size(img1,3) == 3
    img1 = rgb2gray(img1);              % Convert RGB to grayscale
end

img1 = imresize(img1, ...
    [IMG_HEIGHT IMG_WIDTH]);             % Resize to 64x64

img1 = uint8(img1);                      % Force 8-bit pixels


%% ============================================================
% IMAGE 2
% ============================================================

img2 = imread('images/image2.jpg');     % Read Image2

if size(img2,3) == 3
    img2 = rgb2gray(img2);              % Convert RGB to grayscale
end

img2 = imresize(img2, ...
    [IMG_HEIGHT IMG_WIDTH]);             % Resize to 64x64

img2 = uint8(img2);                      % Force 8-bit pixels


%% ============================================================
% DISPLAY BOTH IMAGES
% ============================================================

figure;

subplot(1,2,1);
imshow(img1);
title('Image1 - SRAM');

subplot(1,2,2);
imshow(img2);
title('Image2 - UART');


%% ============================================================
% EXPORT IMAGE1 TO MEMORY HEX FILE
% ============================================================

fid = fopen('../memory/image1.hex', 'w');

for y = 1:IMG_HEIGHT
    for x = 1:IMG_WIDTH

        fprintf(fid, '%02X\n', img1(y,x));
        % Write one grayscale pixel per line

    end
end

fclose(fid);


%% ============================================================
% EXPORT IMAGE2 TO UART HEX FILE
% ============================================================

fid = fopen('../uart/image2.hex', 'w');

for y = 1:IMG_HEIGHT
    for x = 1:IMG_WIDTH

        fprintf(fid, '%02X\n', img2(y,x));
        % Write one grayscale pixel per line

    end
end

fclose(fid);


%% ============================================================
% CHECK FILE SIZE
% ============================================================

fprintf('Image1 pixels = %d\n', numel(img1));
fprintf('Image2 pixels = %d\n', numel(img2));

fprintf('Expected pixels = %d\n', ...
    IMG_WIDTH * IMG_HEIGHT);