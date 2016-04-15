function Path = hmmsdecode(Xin,T,metahmm,markovTrans,type)
% 1) Compute the stata time courses or viterbi paths 
% 2) Compute the entropy,avglifetime,nochanges from it
%
% INPUTS
% Xin: cell with strings referring to the subject files
% T: cell of vectors, where each element has the length of each trial per
% metahmm: the metastates computed from trainBigHMM
% markovTrans.P and Pi: transition prob table and initial prob
% type: 0, state time courses; 1, viterbi path
% NOTE: computations of stats now done in getshmmstats.m
%
% Diego Vidaurre, OHBA, University of Oxford (2015)

if nargin<4, markovTrans = []; end
if nargin<5, type = 0; end

for i = 1:length(T)
    if size(T{i},1)==1, T{i} = T{i}'; end
end

N = length(Xin);
K = length(metahmm.state);
TT = []; for i=1:N, TT = [TT; T{i}]; end
tacc = 0; 

Path = zeros(sum(TT)-length(TT)*metahmm.train.order,K);

BIGuniqueTrans = metahmm.train.BIGuniqueTrans;
if ~BIGuniqueTrans
    if isempty(markovTrans)
        error('Parameter markovTrans needs to be supplied')
    end
    P = markovTrans.P;
    Pi = markovTrans.Pi;
    Dir2d_alpha = markovTrans.Dir2d_alpha;
    Dir_alpha = markovTrans.Dir_alpha;
end

for i = 1:N
    [X,XX,Y] = loadfile(Xin{i},T{i},metahmm.train);    
    XX_i = cell(1); XX_i{1} = XX;
    if BIGuniqueTrans
        metahmm_i = metahmm;
    else
        metahmm_i = copyhmm(metahmm,P(:,:,i),Pi(:,i)',Dir2d_alpha(:,:,i),Dir_alpha(:,i)');
    end
    t = (1:(sum(T{i})-length(T{i})*metahmm.train.order)) + tacc;
    tacc = tacc + length(t);
    if type==0
        data = struct('X',X,'C',NaN(sum(T{i})-length(T{i})*metahmm.train.order,K));
        gamma = hsinference(data,T{i},metahmm_i,Y,[],XX_i);
        Path(t,:) = single(gamma);
    else
        vp = hmmdecode(X,T{i},metahmm,Y);
        gamma = zeros(numel(vp),K,'single');
        vp = vp(:);
        for k=1:K, gamma(vp==k,k) = 1; end
        Path(t,:) = gamma;
    end

end


end