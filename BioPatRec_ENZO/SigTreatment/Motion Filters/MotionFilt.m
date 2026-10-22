% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec ?? which is open and free software under
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and
% Chalmers University of Technology. All authors??? contributions must be kept
% acknowledged below in the section "Updates % Contributors".
%
% Would you like to contribute to science and sum efforts to improve
% amputees??? quality of life? Join this project! or, send your comments to:
% maxo@chalmers.se.
%
% The entire copyright notice must be kept in this or any source file
% linked to BioPatRec. This will ensure communication with all authors and
% acknowledge contributions here and in the project web page (optional).
%
% -------------------------- Function Description -------------------------
% This function reduces motion disturbances in the signal, based on wavelet
% thresholding (SWT or DWT) and signal separation methods.
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2016-04-07 / Julian Maier  / Creation
% 20xx-xx-xx / Author  / Comment on update

function dataClean = MotionFilt(data,sF,type,alg,varargin)

if ~isempty(varargin)
    params = varargin{1};
else
    % Adjust params for Wavelet filtering
    params.thrCa = 1;
    params.thrCd = 0;
    params.thrK = 1;
end

% Select level depth and corresponding level for threshold selection
if sF == 2000
    params.nLevel = 4;
    params.nThr = 3;
elseif sF == 1000
    params.nLevel = 3;
    params.nThr = 2;
elseif sF == 500
    params.nLevel = 2;
    params.nThr = 1;
else
    error('Use 500, 1000 or 2000 Hz sampling frequency!')
end

% Set ICA algorithm
if nargin < 4
    strAlg = {'PCA','FastICA','SOBI','TDSEP','JADE','Infomax'};
    if ~isempty(strfind(type,'SigSep'))
        [selAlg,ok] = listdlg('PromptString','Select ICA method:',...
            'SelectionMode','single','ListSize',[160 120],...
            'ListString',strAlg); if ~ok, return; end
        alg = strAlg{selAlg};
    else
        alg = 'PCA';
    end
end

% Set type
switch type
    case 'SWT'
        dataClean = SwtIC(data,params)';
    case 'DWT'
        dataClean = DwtIC(data,params)';
    case 'SWT + SigSep'
        [dataIC, ~, A] = ComputeSigSep(data,alg,sF);
        dataIC = SwtIC(dataIC,params);
        dataClean = (A * dataIC)';
    case 'DWT + SigSep'
        [dataIC, ~, A] = ComputeSigSep(data,alg,sF);
        dataIC = DwtIC(dataIC,params);
        dataClean = (A * dataIC)';
    case 'ALCD'
        dataClean = AlcdIC(data)';
end

function sig = AlcdIC(sig)
nThr = 2;
nLevel = 4;

dec = msWaveletDec('SWT',sig,nLevel,'db2');

% Set threshold
sigma = std(dec.cD{nThr},0,2);
thr_0 = mean(abs(dec.cD{nThr}),2);
thr_1 = thr_0 + sigma;

% Find artifacts in cA
maskCa = (abs(dec.cA) < thr_1);
dec.cA = dec.cA.*maskCa;
dec.cD{end} = dec.cD{end}.*maskCa;
for iL = 1:nLevel-1
    dec.cD{iL} = dec.cD{iL}.*((abs(dec.cD{iL}) < thr_0) | maskCa);
end

sig = msWaveletRec(dec);

function sig = SwtIC(sig,params)
% Initialize params
thrCa = params.thrCa;
thrCd = params.thrCd;
thrK = params.thrK;
nLevel = params.nLevel;
nThr = params.nThr;
[nIC, nSample] = size(sig);
dec = msWaveletDec('SWT',sig,nLevel,'db2');

% Set threshold
thr = (median(abs(dec.cD{nThr-1}),2) + median(abs(dec.cD{nThr}),2))/2 * ones(1,nSample);
stdThr = (std(abs(dec.cD{nThr-1})')/2 + std(abs(dec.cD{nThr})'))'/2 * ones(1,nSample);

% Find artifacts in cA
locCa = abs(dec.cA) > thr + thrCa * stdThr;
locCd = abs(cell2mat(dec.cD')) > repmat(thr + thrCd * stdThr,nLevel,1);
locCd = locCd & repmat(locCa,nLevel,1);
loc = cat(1,locCd,locCa)';

loc = logical(reshape(loc,[nSample,nIC,nLevel+1]));
loc = permute(loc,[2,1,3]);

locCa = loc(:,:,end);
dec.cA(locCa) = 0;

% Set coeffs to zero or median value
for iL = nLevel:-1:1
    thr = thr * thrK;
    loc(:,:,iL) = loc(:,:,iL) & locCa;
    %loc(:,:,iL) = loc(:,:,iL) & loc(:,:,iL+1);%
    maskCd = loc(:,:,iL);
    dec.cD{iL}(maskCd) = 0;
    %corrCd = diag(median(abs(dec.cD{iL}),2)) * maskCd;%
    %dec.cD{iL}(maskCd) = sign(dec.cD{iL}(maskCd)) .* corrCd(maskCd);%
    
end

sig = msWaveletRec(dec);


function sig = DwtIC(sig,params)
% Initialize params
thrCa = params.thrCa;
thrCd = params.thrCd;
thrK = params.thrK;
nLevel = params.nLevel;
nThr = params.nThr;
dec = msWaveletDec('DWT',sig,nLevel,'db1');

% Set threshold
thr = (median(abs(dec.cD{nThr-1}),2) + median(abs(dec.cD{nThr}),2))/2;
stdThr = (std(abs(dec.cD{nThr-1})')/2 + std(abs(dec.cD{nThr})'))'/2;

% Find artifacts in cA
locCa = abs(dec.cA) > (thr + stdThr * thrCa) * ones(1,size(dec.cA,2));

% Set coeffs to zero or median value
sizeLocCa = size(locCa,1);
dec.cA(logical(locCa)) = 0;
maskCD = cell(nLevel,1);
thr = thr + stdThr * thrCa;
for iL = nLevel:-1:1
    thr = thr * thrK;
    maskCA = reshape(repmat(locCa,2^(nLevel-iL),1),sizeLocCa,[]);
    maskCD{iL} = abs(dec.cD{iL}) > thr * ones(1,size(dec.cD{iL},2));
    if iL == nLevel%
    maskCD{iL} = maskCA & maskCD{iL};
    else
        maskCD{iL+1} = reshape(repmat(single(maskCD{iL+1}),2,1),sizeLocCa,[]);
        maskCD{iL} = maskCA & maskCD{iL} & maskCD{iL+1};
    end
    corrCd = diag(median(abs(dec.cD{iL}),2)) * maskCD{iL};
    dec.cD{iL}(maskCD{iL}) = sign(dec.cD{iL}(maskCD{iL})) .* corrCd(maskCD{iL});%
    %dec.cD{iL}(maskCD{iL}) = 0;
end

sig = msWaveletRec(dec);
