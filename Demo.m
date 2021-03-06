clear;
load GMM/point_cloud10x_win40_nlsp10_delta0.001_cls32.mat;
% dictionary and regularization parameter
par.D= GMM.D;
par.S = GMM.S;
%par.step = 3;       % the step of two neighbor patches
par.IteNum = 3;  % the iteration number
par.ne_num = ne_num;        % patch size
par.ch = 3;      %每个点有三个数来表示位置，法线
par.nlsp = nlsp;  % number of non-local patches
par.win = win;    % size of window around the patch
par.En = 15;
par.c1 = 0.001;
% if strcmp(dataset, 'CC15')==1
%     par.c1 = 0.001;
% elseif strcmp(dataset, 'CC60')==1
%     par.c1 = 0.0016;
% elseif strcmp(dataset, 'PolyU100')==1
%     par.c1 = 0.001;
% end
%         par.c2 = 0.005;

% par.PSNR = [];
% par.SSIM = [];
% CCPSNR = [];
% CCSSIM = [];
%alltime = zeros(1,im_num);

pc_noisy = pcread('Noisy/Noisy.pcd');
par.nim =   pc_noisy;
%par.imIndex = i;
% Guided denoising
t1=clock;
[IMout,par]  =  Denoising_Guided(par,model);
t2=clock;
etime(t2,t1)
%alltime(par.imIndex)  = etime(t2,t1);
% calc ulate the PSNR and SSIM

