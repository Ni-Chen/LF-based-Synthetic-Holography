elePixelCount = 41;
eleSizeX = elePixelCount;
eleSizeY = elePixelCount;


% clip constraints
invalidL = 3;
invalidR = 3;
invalidU = 3;
invalidD = 3;

lambda       = 532e-6;       % record wavelenght(m).
lambda_r     = 532e-6;       % recontruct wave length
lensArrF     = 3.3e-3;       % lens array focal lenth
lensArrPixel = 1e-3;         % lens array pixel
s_div        = 3;

projPixel = 1e-3;   %0.1e-3;

zscope= 0.035 : 0.005 : 0.08;  


%% Initial guess about the pixel number of the element image
% M_crop = imcrop(original,[365 141 1517 1476]);
% S_crop = imcrop(original,[1993 1032 1066 1312]);
