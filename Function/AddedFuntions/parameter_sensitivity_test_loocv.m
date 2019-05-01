function [Acc]=parameter_sensitivity_test_loocv(All_Feat,nSubj,label,meth_Net,lambda_lasso)


e = 1:nSubj;

cpred = zeros(nSubj,1);

score = zeros(nSubj,1);

% LOOCV for testing
for i=1:nSubj
    Tst_ind = i;
    telabel = label(i);
    Trn_ind = e;
    Trn_ind(i) = [];
    trlabel = label;
    trlabel(i) = [];
    

    Feat = All_Feat;
    trFe = Feat(Trn_ind,:);
    teFe = Feat(Tst_ind,:);
    
    % Feature selection ag
    if ~strcmpi(meth_Net,'dHOFC')
        pval=0.05;  % generally use pval<0.05 as a threshold for feature selection
        [~,p]=ttest2(trFe(trlabel==-1,:),trFe(trlabel==1,:));
        trFe=trFe(:,p<pval);
        teFe=teFe(:,p<pval);
        
        midw=lasso(trFe,trlabel,'Lambda',lambda_lasso);  % parameter lambda for sparsity
        trFe=trFe(:,midw~=0);
        teFe=teFe(:,midw~=0);
    else
        midw=lasso(trFe,trlabel,'Lambda',lambda_lasso);  % parameter lambda for sparsity
        trFe=trFe(:,midw~=0);
        teFe=teFe(:,midw~=0);
    end
    
    % Feature normalization ag
    Mtr=mean(trFe);
    Str=std(trFe);
    trFe=trFe-repmat(Mtr,size(trFe,1),1);
    trFe=trFe./repmat(Str,size(trFe,1),1);
    teFe=teFe-Mtr;
    teFe=teFe./Str;
    
    % train SVM model ag
    classmodel=svmtrain(trlabel,trFe,'-t 0 -c 1 -q'); % linear SVM (require LIBSVM toolbox)
    % classify ag
    [cpred(i),~,score(i)]=svmpredict(telabel,teFe,classmodel,'-q');
end

Acc=100*sum(cpred==label)/nSubj;
%[AUC,SEN,SPE,F1]=perfeval(label,cpred,score);

