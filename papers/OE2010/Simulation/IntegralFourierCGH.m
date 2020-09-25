%% Generation and reconstruction of Integral Fourier hologram
% Author       : Niya
% Created      : 2009/06/10
% Modified     : 2009/11/06(2)
% Description  : This code is used to generare analysis parameters that effect the resolution in the
% integral Fourier hologram. in this code, we generate orthographic image directly without
% generating elementimages. Also we can set different value(such as wavle length, Fourier transform
% focal length,  pixel pitch of the Fourier hologram) in the generation and reconstruction. We do
% this because there are some liminations in doing optical experiment.
% This code is based on Prof. Park's code. 
function main()
    close all;
    clear all;
    clc;
    tic;
    format long;
   
    % Add directories to search path
    addpath ../.;  
    in_dir = './input_images/';
    out_dir = './output_images/';
    
    % The global parameters
    global l b deltaTheta thetaMax deltaS deltaT maxS minS maxT minT lambda lambda_r...
           projPixelPitchX projPixelPitchY z;

    %% read the object
    lensArrF     = 3.3e-3;      % lens array focal lenth (m).
    lambda       = 500e-6;      % wavelenght of laser (m).
    lambda_r     = 500e-6;      % reconstruct wavelenght (m).
    lensArrPitch = 0.5e-3;      % lens array pixel (m).
    z            = 0.050;         % distance of original image from CGH plane (m).
    l            = lensArrF;    % constant for calculation of x_p, y_p (m), equals to the focal 
                                % length of the lens array.
    b            = 2/(lambda*l); 
    
    deltaTheta   = 1*0.1432*pi/180;  % The interval of the projection angle in the element image
                                     % capturing process.
    thetaMax     = 14.324*pi/180;  % The maximum projection angle in the element image capturing 
                                     % process.
    
    oriImage = double(rgb2gray(imread([in_dir,'cow.jpg'],'jpg')));
    [oriImageNy, oriImageNx] = size(oriImage);

    % Original image pixel pitch.
    objPixelPitchX = 0.5e-3;
    objPixelPitchY = 0.5e-3;
    
    % Is equal to the orthographic pixel pitch, and the sampling rate of the orthographic image is
    % given by the element lens pitch, hence the object is sampled with 'lensArrPitch' interval in
    % the orthographic image.
    projPixelPitchX = lensArrPitch;   
    projPixelPitchY = lensArrPitch;  
    
    % Pixel size of element images.
    deltaS = deltaTheta*l;
    deltaT = deltaS;
     
    maxS = thetaMax*l;
    minS = -maxS;
    maxT = maxS;
    minT = minS;
    
    deltaZ=lensArrPitch/(maxS/lensArrF);
    disp(['deltaZ = ', num2str(deltaZ),'m'])
    
    
    %% CGH generate
    disp('CGH generating...');
    [CGH] = FourierCghGenerate(oriImage, objPixelPitchX, objPixelPitchY);

    %% Reconstruction
    FourierCghRecon(CGH, lambda_r, z)
    
    cutFreq = 2*thetaMax/lambda;
    sampleRate = 1/projPixelPitchX;


    disp(['lambda = ', num2str(lambda)])
    disp(['thetaMax = ', num2str(thetaMax*180/pi)])
    disp(['cut off Frequency = ', num2str(cutFreq)])
    disp(['sampling rate = ', num2str(sampleRate)])
    disp(['image_max_fx = ', num2str(0.5/objPixelPitchX)])    
    disp(['deltaTheta = ', num2str(deltaTheta*180/pi),' rad'])
    Lx = lambda/(2*deltaTheta);
    disp(['size_max = ' num2str(Lx)])
    disp(['image_size = ', num2str(objPixelPitchX*oriImageNx)])
   
    disp('finish!');
    toc;
end

%%-----------------------------------------Sub Function---------------------------------------------
% Description :
%   Generate integral Fourier hologram of one image.
% Usage       :
%   [CGH] = FourierCghGenerate(oriImage, objPixelPitchX, objPixelPitchY)
% Arguments   :
%   oriImage       -> The original image we want to generate it's Fourier hologram.
%   objPixelPitchX -> The pixel pitch of the object in x direction.
%   objPixelPitchY -> The pixel pitch of the object in y direction.
% OutPuts     :
%   CGH            -> The CGH of the object.
function [CGH] = FourierCghGenerate(oriImage, objPixelPitchX, objPixelPitchY)
    global l b deltaS deltaT maxS minS maxT minT  projPixelPitchX projPixelPitchY z;
    [oriImageNy, oriImageNx] = size(oriImage);
    projSizeX = oriImageNx;  
    projSizeY = oriImageNy;  
      
   %% sampling one sub image
    Xp_c = ones(projSizeY,1)*[-projSizeX/2 : projSizeX/2-1]*projPixelPitchX;    
    Yp_c = [-projSizeY/2 : projSizeY/2-1]'*ones(1,projSizeX)*projPixelPitchY;
    
    %clip
    m_1 = round(Xp_c/objPixelPitchX) + floor((oriImageNx + 1)/2);
    temp_list_m_1 = find(m_1<1 | m_1>oriImageNx);
    m_1(temp_list_m_1) = 1;

    n_1 = round(Yp_c/objPixelPitchY) + floor((oriImageNy + 1)/2);
    temp_list_n_1 = find(n_1<1 | n_1>oriImageNy);
    n_1(temp_list_n_1) = 1;

    projImage1 = oriImage((m_1-1)*oriImageNy + n_1);
    projImage1(temp_list_m_1) = 0;
    projImage1(temp_list_n_1) = 0;
    
    % lateral shift
    shiftX = 0.00;
    shiftY = 0.00;
    % longitidual shift
    shiftZ = 0.00; 
    numS = 0;   
    for s = minS:deltaS:maxS
        numS = numS+1;
        Xp_offset = shiftX + s*(z+shiftZ)/l;
        Xp = Xp_c + Xp_offset;
        
        numT = 0;
        for t=minT:deltaT:maxT
            numT = numT+1;
            Yp_offset = shiftY + t*(z+shiftZ)/l;
            Yp = Yp_c + Yp_offset;
            
            B = 2*pi*b.*(Xp*s + Yp*t);      % phase factor of the slanted plane wave 
            FT = projImage1.*(exp(-j*B));   % multiplicate with slanted wave
            CGH(numT, numS) = sum(sum(FT));   % the complex field of the 3D object   
        end
        [num2str(100*(s-minS)/(maxS-minS)), '% is complete!!']
    end
    CGH = fliplr(flipud(CGH));
    magnitude_CGH = abs(CGH);
    phase_CGH = angle(CGH);
    
    figure()
    imshow((magnitude_CGH),[])
    title('magnitude of CGH');
    figure()
    imshow((phase_CGH),[])
    title('phase of CGH');
end

%%-----------------------------------------Sub Function---------------------------------------------
% Description :
%   Reconstruct the object from the Fourier CGH. With different parameters in the reconstruction,we 
%   get the relationship below:
%   f_r = M1*f                       -> f_r is the reconstruction Fourier transform lens focallength.
%   lambda_r = M2*lambda             -> lambda_r is the reconstruction wave length.
%   deltaU_r = M3*deltaU             -> deltaU_r is the pixel pitch of the SLM.
%   M3^2 = M1^2*M2 => M1=M3/sqrt(M2) -> the relationship between the magnifications.
% Usage       :
%   FourierCghRecon(CGH, lambda_r, z)
% Arguments   :
%   CGH      -> The Fourier hologram.
%   lambda_r -> The reconstruction wave length.
%   z        -> The reconstruction distance.
% OutPuts     :
function FourierCghRecon(CGH, lambda_r, z)
    disp('Reconstructing...'); 
    global l deltaS deltaT maxS minS maxT minT lambda;
    [CGHy CGHx] = size(CGH);
    ref_step_u = l*(0.1*pi/180); %0.1degree  
    M = 1;
    deltaU = deltaS*M;
    deltaV = deltaT*M;
    
    % the record lens focal length
    f = M*l/2;
    
    % the pixel pitch of the SLM
    deltaU_r = deltaU;
    deltaV_r = deltaV;
        
    M2 = lambda_r/lambda;
    
    % Magnification factor to the hologram induced by the SLM
    M3 = deltaU_r/deltaU;
    
    maxU_r = maxS*M*M3;
    minU_r = minS*M*M3;
    maxV_r = maxT*M*M3;
    minV_r = minT*M*M3;
    
    M1 = M3/sqrt(M2);
    f_r = f*M1; % the reconstruct lens focal length
    
    % The magnification of the reconstructed object's size induced by the different parameters in
    % generation and reconstruction.
    factor = M3/M2/M1;
    
    v = repmat([linspace(minV_r, maxV_r, length(minS:deltaS:maxS))]', [1, CGHx]);
    u = repmat([linspace(minU_r, maxU_r, length(minT:deltaT:maxT))], [CGHy, 1]);
    
    intermediate_CGH_padded = zeros(500, 500);
    
    flag = 0;
    z1= z + f_r;
    
    for d= z1-0.005:0.001:z1+0.005
        flag = flag+1;
        intermediate_CGH = CGH.*exp(-j*(pi/lambda_r/f_r)*(1-d/f_r).*((u.^2)+(v.^2)));
        intermediate_CGH_padded(1:CGHy, 1:CGHx)= intermediate_CGH;
        FT = fftshift(fft2(intermediate_CGH_padded));
        intensity(:,:,flag) = abs(FT).^1;
        image_to_be_displayed = imresize(uint8(intensity(:,:,flag)*255/max(max(intensity(:,:,flag)))),...
                                         ref_step_u/deltaU);
        figure;
        imshow(abs(image_to_be_displayed), []);
        title(['reconstruct distance is: ',num2str((d-f_r)*1000),'mm'])   
    end
end
