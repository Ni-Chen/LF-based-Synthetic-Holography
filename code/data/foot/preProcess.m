%% Preprocess
% Author      : Niya
% Date        : 2009/03/13
% description : This code is used to preprocess the original element image that captured by
%   experiment. The steps are:
%   1> Translate the original element image to gray mode. (by using PS or some other method).
%   2> Initial guess the pixel of one element image. Here we crop the image and get the pixel by
%   using the (total pixel)/(element image num)
%   3> Crop the original element image to get the two objects separately.
%   4> Systhesize the two crop images.
%
%%-----------------------------------------Main Function--------------------------------------------

out_dir = '../../output/';


run(['param.m']);
lx = 1600;
ly = 2200;
for n = 1:2
    for m = 1:2
        mnindex = [num2str(m), num2str(n)];
        oriFileName = ['eleImg','_',mnindex,'.JPG'];
        original = double((imread(oriFileName,'jpg')));
        switch mnindex
            case '11'
                left_crop = imcrop(original,[483 119 lx ly]);  %32x32
                right_crop = imcrop(original,[2173 617 lx ly]);
            case '12'
                left_crop = imcrop(original,[508 119 lx ly]);  %32x32
                right_crop = imcrop(original,[2198 617 lx ly]);   % 37x44
            case '21'
                left_crop = imcrop(original,[482 141 lx ly]);  %32x32
                right_crop = imcrop(original,[2172 639 lx ly]);   % 37x44
            case '22'
                left_crop = imcrop(original,[507 141 lx ly]);  %32x32
                right_crop = imcrop(original,[2197 639 lx ly]);   % 37x44
            otherwise
        end
        %% resize
        nx = 2*lx/eleSizeX;
        ny = 2*ly/eleSizeY;
        offsetX = eleSizeX*4;
        Nx = eleSizeX*nx + offsetX*2;   %
        offsetY = eleSizeY*4;
%         Ny = eleSizeY*ny + offsetY*2;   %
        Ny = Nx;
        
        
        %             [Ny_n, Nx_n, rgb] = size(ImgCrop);
        eleImgCrop = zeros(Ny, Nx, 3);
        eleImgCrop((offsetY+1):(ly+offsetY+1), (offsetX+1):(lx+offsetX+1),:) = left_crop;
        eleImgCrop((Ny-offsetY-ly+1):(Ny-offsetY+1), (Nx-offsetX-lx+1):(Nx-offsetX+1),:) = right_crop;
        imwrite(uint8(eleImgCrop), [out_dir, CaptImageName, '_eleImg_',mnindex,'.jpg'], 'jpg');
        clear ImgCrop;
        
    end
end

