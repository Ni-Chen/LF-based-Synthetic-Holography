elePixelCount = 50;
eleSizeX = elePixelCount;
eleSizeY = elePixelCount;

lensArrF     = 3.3e-3;       % lens array focal lenth
lensArrPixel = 1e-3;         % lens array pixel

% clip constraints
invalidL = 3;
invalidR = 3;
invalidU = 3;
invalidD = 3;

lambda       = 0.5*600e-6;       % record wavelenght(m).
lambda_r     = 0.5*600e-6;       % recontruct wave length
lensArrF     = 3.3e-3;       % lens array focal lenth
lensArrPixel = 1e-3;         % lens array pixel
s_div        = 2*2;

projPixel = 0.5e-3;



z1=55e-3;
z2=70e-3;

zscope=45e-3:5e-3:80e-3;