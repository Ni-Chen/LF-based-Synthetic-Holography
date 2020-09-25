%% Preprocess
% Author      : Ni Chen
% Date        : 2009/03/13
% description : This code is used to preprocess the original element image that captured by
%   experiment. The steps are:
%   1> Translate the original element image to gray mode. (by using PS or some other method).
%   2> Initial guess the pixel of one element image. Here we crop the image and get the pixel by
%   using the (total pixel)/(element image num)
%   3> Crop the original element image to get the two objects separately.
%   4> Systhesize the two crop images.
%

out_dir = '../../output/';

disp('start preprocess!');

CaptImageName = 'bear';

run(['param.m']);

for n = 1:2
    for m = 1:2
        mnindex = [num2str(m), num2str(n)];
        oriFileName = ['eleImg', '_',mnindex,'.JPG'];
        original = double((imread(oriFileName,'jpg')));
        switch mnindex
            case '11'
                ImgCrop = imcrop(original,[866 252 2646 2538]);  %32x32
            case '12'
                ImgCrop = imcrop(original,[895 252 2646 2538]);  %32x32
            case '21'
                ImgCrop = imcrop(original,[866 276 2646 2538]);  %32x32
            case '22'
                ImgCrop = imcrop(original,[895 276 2646 2538]);  %32x32
            otherwise
        end
        %% resize
        nx = 2538/eleSizeX;
        ny = 2646/eleSizeY;
        offsetX = eleSizeX*2;
        Nx = eleSizeX*49 + offsetX*2;   %
        offsetY = eleSizeY*2;
        Ny = eleSizeY*47 + offsetY*2;   %
        
        [Ny_n, Nx_n, rgb] = size(ImgCrop);
        eleImgCrop = zeros(Ny, Nx, 3);
        eleImgCrop((offsetY+1):(Ny_n+offsetY), (offsetX+1):(Nx_n+offsetX),:) = ImgCrop;
        imwrite(uint8(eleImgCrop), [out_dir, CaptImageName, '_eleImg_',mnindex,'.jpg']);
        
    end
end