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
function main()
    close all;
    clear;
    clc;
    
    % Add directories to search path
    addpath ../.;   
    
    % Create a directory for output images if needed and does not already exist.
    in_dir = './data/';
    out_dir = './output/';
    
    disp('start!');
    
    CaptImageName = 'exp_MS';

    run([in_dir, CaptImageName,'_param.m']);

    oriFileName = ['data/',CaptImageName,'_eleImg','.JPG'];
    original = double((imread(oriFileName,'jpg')));
  
    lx1 = 1517;
    ly1 = 1476;
    left_crop = imcrop(original,[365 141 lx1 ly1]); 
    lx2 = 1066;
    ly2 = 1312; 
    right_crop = imcrop(original,[1993 1032 lx2 ly2]);
    %% resize
    nx = 2*lx1/eleSizeX;
    ny = 2*ly1/eleSizeY;
    offsetX = eleSizeX*4;
    Nx = eleSizeX*nx + offsetX*2;   %
    offsetY = eleSizeY*4;
    Ny = eleSizeY*ny + offsetY*2;   %
    
    eleImgCrop = zeros(Ny, Nx, 3);
    eleImgCrop((offsetY+1):(ly1+offsetY+1), (offsetX+1):(lx1+offsetX+1),:) = left_crop;
    eleImgCrop((Ny-offsetY-ly2+1):(Ny-offsetY+1), (Nx-offsetX-lx2+1):(Nx-offsetX+1),:) = right_crop;
    imwrite(uint8(eleImgCrop), [out_dir, CaptImageName, '_eleImg','.jpg'], 'jpg');
    clear ImgCrop;

    clear original;


    disp('Finish!');
end