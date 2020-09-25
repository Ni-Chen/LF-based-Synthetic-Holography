%% PSNR (Peak Signal-to-Noise Ratio)
function main()
    close all;
    clear all;
    clc;
    tic;
    
    ori = imread('pen.bmp');
    rec = imread('rec_out.jpg');
    hex = imread('hex_out.jpg');
    

    
    [Ny Nx rgb] = size(rec);
    ori =  imresize(ori, [Ny Nx]);
%     figure;
%     imshow(ori,[]);
%     hex = imresize(hex, [Ny Nx]);
%     figure;
%     imshow(hex,[]);
%        
%     figure;
%     imshow(rec,[]);
    
%     hex_snr = PSNR(ori, hex);
%     rec_snr = PSNR(ori, rec);
%    
%     hex_snr
%     rec_snr
%     
%     hex_ncc = AverDiff(ori, hex);
%     rec_ncc = AverDiff(ori, rec);
%    
%     hex_ncc
%     rec_ncc
    
    %%
    rec = rgb2gray(rec);
    hex = rgb2gray(hex);
    ori = rgb2gray(ori); 
%     plot();
%     figure;
%     imhist(rec);
%     figure;
%     imhist(hex);
   
    iori = fftshift(fft2(ori,Ny,Nx));
    max_value = max(max(iori));
    iori = iori/max_value;
    figure;
%      set(gca,'xtick',on) 
    mesh((abs(iori)));
    zlabel('frequency');
    xlabel('fx');
    ylabel('fy');
    title('Frequency spectrum of ori');
    
    irec = fftshift(fft2(rec,Ny,Nx));
    max_value = max(max(irec));
    irec = irec/max_value;
    figure;
%      set(gca,'xtick',on) 
    mesh((abs(irec)));
    zlabel('frequency');
    xlabel('fx');
    ylabel('fy');
    title('Frequency spectrum of rectangle');
        
    ihex = fftshift(fft2(hex,Ny,Nx));
    max_value = max(max(ihex))
    ihex = ihex/max_value;
    figure;
    mesh((abs(ihex)));
    zlabel('frequency');
    xlabel('fx');
    ylabel('fy');
    title('Frequency spectrum of hexagonal');

end