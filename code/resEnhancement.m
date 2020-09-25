% Add directories to search path
% addpath ../.;
close all;
clear;
clc;

addpath(genpath('./function/'));  % Add funtion path with sub-folders

in_dir = './data/';
out_dir = './output/';

% bear, girl, foot
CaptImageName = 'foot';

run([in_dir, CaptImageName, '/preProcess.m']);

run('eleCombine.m');

run('ele2sub.m');

run('orthoImg2FourierHolo.m')
% run('ortho2FourierHolo.m')
