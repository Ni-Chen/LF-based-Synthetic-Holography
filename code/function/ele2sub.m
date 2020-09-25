% Sub Image Generate
% Author      : Ni Chen
% Date        : 2009/02/05
% description : This code is used to generate orthogriphy image from elemental image.  
%
%%-----------------------------------------Main Function--------------------------------------------

CaptImage = double(imread([out_dir, CaptImageName, '_eleImg_syn.jpg']));

se = translate(strel(1), [-1 -1]);
CaptImage = imdilate(CaptImage,se);
CaptImage(CaptImage<20) = 1;
CaptImage(CaptImage>150) = 256;

%% generate element images
disp('generating element images...');
[ELE_IMAGE] = lf_2dto4d(CaptImage, eleSizeY, eleSizeX);
%     save([out_dir, CaptImageName, '_eleImg.mat'], 'ELE_IMAGE');
clear CaptImage;

%% save the edited element image
eleImage = lf_4dto2d(ELE_IMAGE, 1);
imwrite(uint8(eleImage), [out_dir,  CaptImageName, '_eleImg.jpg']);
clear eleImage;

%% generate sub images
disp('generating sub images...');
[SUB_IMAGE] = lf_ele2sub(ELE_IMAGE);
%% save the sub image
save([out_dir, CaptImageName, '_subImg.mat'], 'SUB_IMAGE');
clear ELE_IMAGE;

%% write the sub image to file
subImage = lf_4dto2d(SUB_IMAGE, 1);
imwrite(uint8(subImage), [out_dir,  CaptImageName, '_subImg.jpg']);
clear subImage SUB_IMAGE;

toc;
disp('finish!');

