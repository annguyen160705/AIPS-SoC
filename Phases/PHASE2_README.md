# AIPS-SoC — Phase 2: MATLAB Image Preparation

## 1. Phase Goal

Prepare the two 64x64 grayscale images used by AIPS-SoC V1.

```text
Image1 -> preloaded into SRAM
Image2 -> later transmitted through UART
```

Generated files:

```text
memory/image1.hex
uart/image2.hex
```

Each image must contain:

```text
64 x 64 = 4096 pixels
1 pixel = 1 byte
4096 lines per HEX file
```

---

## 2. Folder Structure

```text
AIPS-SoC/
|
+-- matlab/
|   +-- images/
|   |   +-- image1.jpg
|   |   +-- image2.jpg
|   |
|   +-- prepare_images.m
|   +-- rebuild_image.m
|
+-- memory/
|   +-- image1.hex
|
+-- uart/
    +-- image2.hex
```

---

## 3. Image Format

```text
Resolution  : 64 x 64
Format      : Grayscale
Pixel width : 8 bits
Pixel range : 0 to 255
Image size  : 4096 bytes
```

Pixel meaning:

```text
0   = black
255 = white
```

This matches the RTL representation:

```systemverilog
logic [7:0] pixel;
```

---

## 4. MATLAB Image Preparation

Create:

```text
matlab/prepare_images.m
```

```matlab
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

img1 = uint8(img1);                      % Force 8-bit unsigned pixels


%% ============================================================
% IMAGE 2
% ============================================================

img2 = imread('images/image2.jpg');     % Read Image2

if size(img2,3) == 3
    img2 = rgb2gray(img2);              % Convert RGB to grayscale
end

img2 = imresize(img2, ...
    [IMG_HEIGHT IMG_WIDTH]);             % Resize to 64x64

img2 = uint8(img2);                      % Force 8-bit unsigned pixels


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
% CHECK PIXEL COUNT
% ============================================================

fprintf('Image1 pixels = %d\n', numel(img1));
fprintf('Image2 pixels = %d\n', numel(img2));

fprintf('Expected pixels = %d\n', ...
    IMG_WIDTH * IMG_HEIGHT);
```

Expected output:

```text
Image1 pixels = 4096
Image2 pixels = 4096
Expected pixels = 4096
```

---

## 5. HEX File Format

Example:

```text
00
14
7A
C5
FF
```

Each line represents one 8-bit grayscale pixel.

The export order is:

```text
row 0, pixel 0
row 0, pixel 1
...
row 0, pixel 63

row 1, pixel 0
...
row 63, pixel 63
```

This creates a linear byte stream suitable for SRAM and UART.

---

## 6. MATLAB Image Reconstruction

Create:

```text
matlab/rebuild_image.m
```

```matlab
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
```

The transpose after `reshape()` restores the same row-major order used when exporting the HEX files.

---

## 7. SystemVerilog Mapping

Later, the HEX files can be loaded using:

```systemverilog
logic [7:0] image1_mem [0:4095];
logic [7:0] image2_mem [0:4095];

initial begin
    $readmemh("memory/image1.hex", image1_mem);
    $readmemh("uart/image2.hex",   image2_mem);
end
```

Pixel mapping:

```text
image_mem[0]    = pixel (0,0)
image_mem[1]    = pixel (0,1)
...
image_mem[63]   = pixel (0,63)

image_mem[64]   = pixel (1,0)
...
image_mem[4095] = pixel (63,63)
```

---

## 8. Role of Each Image in AIPS-SoC

### Image1

```text
memory/image1.hex
        |
        v
Preloaded SRAM
        |
        v
CPU reads Image1
        |
        v
UART TX
```

Used by command:

```text
0x02 = Memory -> UART
```

### Image2

```text
uart/image2.hex
       |
       v
UART testbench stimulus
       |
       v
UART RX
       |
       v
CPU
       |
       v
SRAM Image2
```

Used by command:

```text
0x01 = UART -> Memory
```

---

## 9. Phase 2 Verification

Check all of the following:

- [ ] `image1.jpg` exists
- [ ] `image2.jpg` exists
- [ ] Both images are converted to grayscale
- [ ] Both images are resized to 64x64
- [ ] `memory/image1.hex` is generated
- [ ] `uart/image2.hex` is generated
- [ ] `image1.hex` contains 4096 values
- [ ] `image2.hex` contains 4096 values
- [ ] `rebuild_image.m` reconstructs Image1 correctly
- [ ] `rebuild_image.m` reconstructs Image2 correctly

---

## 10. Phase 2 Exit Criteria

Phase 2 is complete when:

```text
Image1 source
    |
    v
64x64 grayscale
    |
    v
memory/image1.hex
    |
    v
rebuild
    |
    v
Correct Image1
```

and:

```text
Image2 source
    |
    v
64x64 grayscale
    |
    v
uart/image2.hex
    |
    v
rebuild
    |
    v
Correct Image2
```

Both HEX files must contain exactly:

```text
4096 bytes
```

---

## Next Phase

**Phase 3 — RV32I CPU in SystemVerilog**

Initial goal:

```asm
addi x1, x0, 10
addi x2, x0, 20
add  x3, x1, x2
```

Expected:

```text
x1 = 10
x2 = 20
x3 = 30
```

The CPU will later be extended with load/store, branch, and memory-mapped I/O instructions for AHB-Lite, SRAM, and UART control.
