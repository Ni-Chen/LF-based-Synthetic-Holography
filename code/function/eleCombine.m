% Synthesize Elemental images
% Author      : Niya
% Date        : 2009/03/17
% description : The element images are generated by shifting the lens array to get a high resolution
% orthographic image.
%%-----------------------------------------Main Function--------------------------------------------

% Create a directory for output images if needed and does not already exist.
out_dir = './output/';

% shifted element images
eleImg = imread([out_dir, CaptImageName, '_eleImg_11.jpg']);
[eleImg11] = lf_2dto4d(eleImg,elePixelCount,elePixelCount);

eleImg = imread([out_dir, CaptImageName, '_eleImg_12.jpg']);
[eleImg12] = lf_2dto4d(eleImg,elePixelCount,elePixelCount);

eleImg = imread([out_dir, CaptImageName, '_eleImg_21.jpg']);
[eleImg21] = lf_2dto4d(eleImg,elePixelCount,elePixelCount);

eleImg = imread([out_dir, CaptImageName, '_eleImg_22.jpg']);
[eleImg22] = lf_2dto4d(eleImg,elePixelCount,elePixelCount);

clear eleImg;

%%
[eleSizeY, eleSizeX, eleNumY, eleNumX, rgb]=size(eleImg11);
synImage = zeros(elePixelCount*2, elePixelCount*2, eleNumY, eleNumX, rgb);
oriImage = zeros(eleNumY*2*elePixelCount, eleNumX*2*elePixelCount,rgb);

disp('Synthesizing elemental image...');
for j = 1:eleNumY
    for i = 1:eleNumX
        synImage(1:elePixelCount, 1:elePixelCount, j, i,:) = eleImg11(:,:,j,i,:);
        synImage(1:elePixelCount, (elePixelCount+1):(elePixelCount*2), j, i,:) = eleImg12(:,:,j,i,:);
        
        synImage((elePixelCount+1):(elePixelCount*2), 1:elePixelCount, j, i,:) = eleImg21(:,:,j,i,:);
        synImage((elePixelCount+1):(elePixelCount*2), (elePixelCount+1):(elePixelCount*2), j, i,:) = eleImg22(:,:,j,i,:);
        
        oriImage((j-1)*2*elePixelCount+1:j*2*elePixelCount, (i-1)*2*elePixelCount+1:i*2*elePixelCount,:)=synImage(:,:,j,i,:);
    end
end
clear synImage eleImg11 eleImg12 eleImg21 eleImg22;
disp('Synthesize finished!');

temp = max(max(max(abs(oriImage))));
imwrite(uint8(255.*abs(oriImage)./temp), [out_dir, CaptImageName,'_eleImg_syn.jpg'], 'jpg');
disp('Finish!!');
toc;


