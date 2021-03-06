function  [im_out,Par] = Denoising_Guided(Par,model)
im_out = Par.nim;
Par.count = im_out.Count;
Par.dim = Par.ne_num*Par.ch;  %每个向量的维数
for ite = 1 : Par.IteNum
    % search non-local patch groups
    [nDCnlX,blk_arr,DC,Par,dis_near_number] = PointCloud2PG( im_out, Par);
    % Gaussian dictionary selection by MAP
    if mod(ite-1,2) == 0
        %% GMM: full posterior calculation
        nPG = size(nDCnlX,2)/Par.nlsp; % number of PGs
        PYZ = zeros(model.nmodels,nPG);
        for i = 1:model.nmodels
            sigma = model.covs(:,:,i);
            [R,~] = chol(sigma);
            Q = R'\nDCnlX;
            TempPYZ = - sum(log(diag(R))) - dot(Q,Q,1)/2;
            TempPYZ = reshape(TempPYZ,[Par.nlsp nPG]);
            PYZ(i,:) = sum(TempPYZ);
        end
        %% find the most likely component for each patch group
        [~,dicidx] = max(PYZ);
        dicidx=repmat(dicidx, [Par.nlsp 1]);
        dicidx = dicidx(:);%变成一列
        [idx,  s_idx] = sort(dicidx);
        idx2 = idx(1:end-1) - idx(2:end);
        seq = find(idx2);
        seg = [0; seq; length(dicidx)];
    end
    % Weighted Sparse Coding
    Y_hat = zeros(Par.dim,Par.count,'double');
    W_hat = zeros(Par.dim,Par.count,'double');
    
    for   j = 1:length(seg)-1
        idx =   s_idx(seg(j)+1:seg(j+1));
        cls =   dicidx(idx(1));%
        Y = nDCnlX(:,idx);
        De = Par.D{cls};
        b = De'*Y;
        De = De(:,1:Par.En);
        Se = Par.S{cls};
        lambdae = repmat(Par.c1./ (sqrt(Se)+eps),[1 length(idx)]);%将矩阵内容看作一体，复制成1行length（idx）列
        % soft threshold
        alpha = sign(b).*max(abs(b)-lambdae,0);%为什么lambdae没有除以2？
        alphai = alpha(Par.En+1:end,:);
        [U,~,V] = svd((eye(size(Y,1))-De*De')*Y*alphai','econ');
        Di = U*V';
        % lambdai = repmat(Par.c2./ (sqrt(Se)+eps),[1 length(idx)]);
        Dnew = [De Di];
        bnew = Dnew'*Y;
        % soft threshold
        alphanew = sign(bnew).*max(abs(bnew)-lambdae,0);
        % add DC components and aggregation
        Y_hat(:,blk_arr(:,idx)) = Y_hat(:,blk_arr(:,idx)) + bsxfun(@plus, Dnew*alphanew, DC(:,idx)); % not DC(:,blk_arr(:,idx))
        W_hat(:,blk_arr(:,idx)) = W_hat(:,blk_arr(:,idx)) + ones(Par.dim, length(idx));
    end
    % Reconstruction
    im_out = PGs2Normals(Y_hat,W_hat,Par,dis_near_number);
end
pcwrite(IMout,'test.pcd');
% im_out(im_out > 1) = 1;
% im_out(im_out < 0) = 0;
return;
