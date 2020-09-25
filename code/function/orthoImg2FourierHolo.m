%% Fourier transform and reconstruction
% Author      : Ni Chen
% Date        : 2009/02/05
% description : this code is used to reconstruct the 3D object from the projective sub image, the
% IFTA is used to optimize the image.

tic;
format long;

global subNumX subNumY lambda projPixel s_div;

%% load the data of the sub image
load([out_dir, CaptImageName, '_subImg.mat']);% SUB_IMAGE subNumX subNumY subSizeX subSizeY
[subSizeY, subSizeX, subNumY, subNumX, rgb]=size(SUB_IMAGE);
run([in_dir, CaptImageName,'/param.m']);

%% initialize
l = lensArrF;       % the distance between the lens array and the element image plane
%     lambda/(lensArrPixel/54/lensArrF/s_div)/2;
%% clip the edages
disp('Pre processing...');
projNumX = 0;
for index_i = (invalidL+1) : (subNumX-invalidR)
    projNumX = projNumX + 1;
    projNumY = 0;
    for index_j = (invalidU+1) : (subNumY-invalidD)
        projNumY = projNumY + 1;
        P(:, :, projNumY, projNumX) = SUB_IMAGE( : , : , index_j, index_i);
    end
end
%% clip end

%% CGH generate
disp('CGH generating...');
[CGH, numT, numS, maxS, minS, maxT, minT] = FourierCghGenerate(P, lensArrF, lensArrPixel);
imwrite(mat2gray(real(CGH)), ['foot_holo_phase', '.png']);
imwrite(mat2gray(imag(CGH)), ['foot_holo_amp', '.png']);

%% Reconstruction
disp('Reconstructing...');
[numT numS] = size(CGH);

deltaS_0 = lensArrPixel / subNumX;    % subNumX = eleSizeX;
deltaT_0 = lensArrPixel / subNumY;    % subNumY = eleSizeY;

deltaS = deltaS_0 / s_div;
deltaT = deltaT_0 / s_div;

deltaU = 10e-6;
deltaV = 10e-6;

M = deltaU/deltaS;                  % Magnification factor of each coordinate direction
lensF = -M*l/2;

max_u = M * maxS;
min_u = M * minS;
max_v = M * maxT;
min_v = M * minT;

v = repmat([min_v:deltaV:max_v]', [1, numS]);
u = repmat([min_u:deltaU:max_u], [numT,1]);

num = 0;
for d = lensF+zscope
    num = num + 1;
    temp = CGH.*exp(1i*(pi/lambda_r/lensF)*(1-d/lensF).*((u.^2)+(v.^2)));
    FT = fftshift(fft2(temp));
    temp = abs(FT);
    
    figure;
    imshow(temp, []);
    title(['d= ', num2str((d-lensF)*1000),'mm']);
end

save([out_dir, CaptImageName,'_CGH_DATA.mat'], 'CGH','deltaT','deltaS');
toc;
disp('finish!');


%% Generate CGH of the projection image
function [cgh, numT, numS, maxS, minS, maxT, minT] = FourierCghGenerate(projImage, lensArrF, lensArrPixel)
    global subNumX subNumY lambda projPixel s_div;
    [projSizeY, projSizeX, projNumY, projNumX] = size(projImage);   %[54,67,29,32]
    
    deltaS = lensArrPixel / subNumX;    % subNumX = eleSizeX;
    deltaT = lensArrPixel / subNumY;    % subNumY = eleSizeY; 
    
    l = lensArrF;
    b = -2/(lambda*l); 
    
    halfNumS = floor(projNumX/2); 
    halfNumT = floor(projNumY/2);

    maxS = halfNumS*deltaS; % maximum value of s (m)
    minS = -(projNumX - halfNumS - 1)*deltaS;
    maxT = halfNumT*deltaT; % maximum value of s (m)
    minT = -(projNumY - halfNumT - 1)*deltaT;
    
    %% sampling one sub image
    Xp = ones(projSizeY,1)*[-projSizeX/2 : projSizeX/2-1]*projPixel;    
    Yp = [-projSizeY/2 : projSizeY/2-1]'*ones(1,projSizeX)*projPixel;

    %%
    numS = 0;   
    numT = 0; 
    for s = minS:deltaS/s_div:maxS
        numS = numS+1;
        numT = 0;
        for t=minT:deltaT/s_div:maxT
            numT = numT+1;

            indexT = 1+floor((numT-1)/s_div);
            indexS = 1+floor((numS-1)/s_div);

            %% most important
            B = 2*pi*b.*(Xp*s + Yp*t);      % phase factor of the slanted plane wave 
            FT = projImage(:, :, indexT, indexS).*(exp(-j*B));   % multiplicate with slanted wave
            CGH(numT, numS) = sum(sum(FT));   % the complex field of the 3D object   
        end
    end
%    cgh = fliplr(flipud(CGH));
   cgh = CGH;
   size(CGH)
   
   deltaZ=projPixel/(maxS/lensArrF);
   disp(['deltaZ = ', num2str(deltaZ),'m'])
        
end