%% Experiment for COOC 2009.
%% Parameters of the experimental setup
lensArrF     = 3.3e-3;       % lens array focal lenth
lensArrPixel = 1e-3;         % lens array pixel

zscope = 0.03 : 0.005 : 0.080 ;

%% Parameters of the elemental image
elePixelCount = 46;
eleSizeX = elePixelCount;
eleSizeY = elePixelCount;

invalidL = 3;
invalidR = 3;
invalidU = 3;
invalidD = 3;

%% For hologram
lambda       = 500e-6;       % record wavelenght(m).
lambda_r     = 500e-6;       % recontruct wave length
s_div        = 2;
projPixel = 0.5e-3;

%% Pre-process the experimental images
lx1 = 1058;
ly1 = 1104;

lx2 = 1242;
ly2 = 1288;

crop_11_left = [339 289 lx1 ly1];   %23x24
crop_11_right = [1620 793 lx2 ly2];  %27x28

crop_12_left = [370 287 lx1 ly1];
crop_12_right = [1649 791 lx2 ly2];

crop_21_left = [349 305 lx1 ly1];
crop_21_right = [1627 814 lx2 ly2];

crop_22_left = [371 304 lx1 ly1];
crop_22_right = [1649 813 lx2 ly2];


