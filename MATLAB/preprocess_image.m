clear;                          % Remove all variables from the MATLAB workspace
clc;                            % Clear the Command Window
close all;                      % Close all currently opened figure windows


%% ============================================================
%  IMAGE CONFIGURATION
% ============================================================

IMG_WIDTH  = 64;                % Target image width in pixels
IMG_HEIGHT = 64;                % Target image height in pixels


%% ============================================================
%  READ INPUT IMAGE
% ============================================================

img = imread('images/test.jpg'); % Read the original image from the images folder


%% ============================================================
%  CONVERT IMAGE TO GRAYSCALE
% ============================================================

if size(img,3) == 3              % Check whether the image has 3 channels: R, G, B

    img_gray = rgb2gray(img);    % Convert RGB image into 8-bit grayscale image

else

    img_gray = img;              % Image is already grayscale, so keep it unchanged

end


%% ============================================================
%  RESIZE IMAGE
% ============================================================

img_gray = imresize(img_gray, ...
                    [IMG_HEIGHT IMG_WIDTH]);
                                   % Resize image to 64x64 pixels
                                   % This gives exactly 4096 pixels


%% ============================================================
%  FORCE PIXELS TO 8-BIT UNSIGNED VALUES
% ============================================================

img_gray = uint8(img_gray);       % Make every pixel an unsigned 8-bit value
                                   % Pixel range becomes 0 to 255
                                   % 0   = black
                                   % 255 = white
                                   % This matches logic [7:0] in SystemVerilog


%% ============================================================
%  DISPLAY GRAYSCALE INPUT IMAGE
% ============================================================

figure;                           % Open a new MATLAB figure window

imshow(img_gray);                 % Display the processed grayscale image

title('Input Grayscale Image');   % Add title to the figure


%% ============================================================
%  SOBEL FILTER KERNELS
% ============================================================

Gx_kernel = [
    -1  0  1;
    -2  0  2;
    -1  0  1
];                                 % Sobel kernel used to detect
                                   % intensity changes in the X direction
                                   % Mainly detects vertical edges


Gy_kernel = [
    -1 -2 -1;
     0  0  0;
     1  2  1
];                                 % Sobel kernel used to detect
                                   % intensity changes in the Y direction
                                   % Mainly detects horizontal edges


%% ============================================================
%  GET IMAGE DIMENSIONS
% ============================================================

[height, width] = size(img_gray);  % Obtain number of rows and columns
                                   % For this project:
                                   % height = 64
                                   % width  = 64


%% ============================================================
%  CREATE GRADIENT MEMORY
% ============================================================

gradient = zeros(height, width);   % Create a 64x64 matrix initialized to zero
                                   % This stores the Sobel magnitude
                                   % for every pixel


%% ============================================================
%  PERFORM SOBEL EDGE DETECTION
% ============================================================

for y = 2:height-1                 % Process rows 2 to 63
                                   % First and last rows are skipped because
                                   % Sobel requires a 3x3 pixel window

    for x = 2:width-1              % Process columns 2 to 63
                                   % First and last columns are also skipped


        window = double( ...
            img_gray(y-1:y+1, x-1:x+1));
                                   % Extract the 3x3 pixel window
                                   % around the current pixel
                                   %
                                   % Example:
                                   %
                                   % P00 P01 P02
                                   % P10 P11 P12
                                   % P20 P21 P22
                                   %
                                   % double() is used because Sobel
                                   % calculations contain negative values


        Gx = sum(sum( ...
            window .* Gx_kernel));
                                   % Multiply every pixel in the 3x3 window
                                   % by the corresponding Gx kernel coefficient
                                   %
                                   % Then add all 9 results together
                                   %
                                   % Produces horizontal gradient Gx


        Gy = sum(sum( ...
            window .* Gy_kernel));
                                   % Multiply the same 3x3 window by Gy kernel
                                   %
                                   % Then add all 9 results together
                                   %
                                   % Produces vertical gradient Gy


        G = abs(Gx) + abs(Gy);     % Calculate approximate gradient magnitude
                                   %
                                   % Standard Sobel could use:
                                   % sqrt(Gx^2 + Gy^2)
                                   %
                                   % But abs(Gx) + abs(Gy) is much easier
                                   % to implement using RTL hardware


        gradient(y,x) = G;         % Store calculated gradient magnitude
                                   % at the current pixel position

    end
end


%% ============================================================
%  CONVERT GRADIENT INTO BINARY EDGE IMAGE
% ============================================================

THRESHOLD = 200;                   % Gradient threshold used to decide
                                   % whether a pixel belongs to an edge


edge_img = gradient > THRESHOLD;   % Compare every gradient value with threshold
                                   %
                                   % gradient > 200 --> pixel = 1 (white edge)
                                   % gradient <= 200 --> pixel = 0 (black)


%% ============================================================
%  DISPLAY BINARY EDGE IMAGE
% ============================================================

figure;                            % Open another figure window

imshow(edge_img);                  % Display binary Sobel result

title('Sobel Binary Edge Image');  % Add figure title


%% ============================================================
%  EXPORT INPUT IMAGE FOR SYSTEMVERILOG
% ============================================================

fid = fopen('output/input.hex', 'w');
                                   % Create/open input.hex in write mode
                                   % This file will contain the grayscale pixels


for y = 1:IMG_HEIGHT               % Scan image from first row to last row

    for x = 1:IMG_WIDTH            % Scan each row from left to right

        fprintf(fid, '%02X\n', ...
                img_gray(y,x));
                                   % Write one grayscale pixel per line
                                   % using 2-digit hexadecimal format
                                   %
                                   % Example:
                                   % 00
                                   % 7A
                                   % C5
                                   % FF
                                   %
                                   % Each value represents one 8-bit pixel

    end
end


fclose(fid);                       % Close input.hex after writing all pixels


%% ============================================================
%  EXPORT GOLDEN SOBEL RESULT FOR SYSTEMVERILOG
% ============================================================

fid = fopen('output/golden.hex', 'w');
                                   % Create/open golden.hex
                                   % This contains expected RTL results


for y = 1:IMG_HEIGHT               % Scan all image rows

    for x = 1:IMG_WIDTH            % Scan all pixels in each row

        fprintf(fid, '%01X\n', ...
                edge_img(y,x));
                                   % Write one binary result per line
                                   %
                                   % 0 = not an edge
                                   % 1 = edge
                                   %
                                   % golden.hex will later be compared
                                   % against the SystemVerilog Sobel output

    end
end


fclose(fid);                       % Close golden.hex