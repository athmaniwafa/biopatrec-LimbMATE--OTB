% ---------------------------- Copyright Notice ---------------------------
% This file is part of BioPatRec © which is open and free software under
% the GNU Lesser General Public License (LGPL). See the file "LICENSE" for
% the full license governing this code and copyrights.
%
% BioPatRec was initially developed by Max J. Ortiz C. at Integrum AB and
% Chalmers University of Technology. All authors’ contributions must be kept
% acknowledged below in the section "Updates % Contributors".
%
% Would you like to contribute to science and sum efforts to improve
% amputees’ quality of life? Join this project! or, send your comments to:
% maxo@chalmers.se.
%
% The entire copyright notice must be kept in this or any source file
% linked to BioPatRec. This will ensure communication with all authors and
% acknowledge contributions here and in the project web page (optional).
%
% -------------------------- Function Description -------------------------
% Function to run KNN and it use cross validation technique based on evaluation 
% of RMSE for validation data to find optimal k. 
% 
% Algorithm based in: 
% Xindong Wu et al., Top 10 algorithms in data mining, Springer-Verlag
% London Limited 2007, pp.(22-23).
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2012-07-01 / Ali Fouad  / Creation
% 2013-03-03 / Ali Fouad  / Removed minDist
% 20xx-xx-xx / Author  / Comment on update

function [tempKNN accV]=EvaluateKNN(trSets, trOuts, vSets, vOuts, tType)
graph2d=1;
% initial KNN
KNN=InitKNN(trSets,trOuts,vSets,vOuts,tType);
if graph2d  % 2D Graph
    hfig = figure;
    hold on
    set(hfig, 'DoubleBuffer','on');
    %axis([1 KNN.k 0 .3]);
    hbestplot = plot(1:KNN.k,zeros(1,KNN.k));
    htext = text(20,0.2,sprintf('Best RMSE: %4.4f',0.0));
    h2text = text(20,0.18,sprintf('Best K: %4.0f',KNN.k));
    xlabel('K');
    ylabel('rmse');
    hold off
    drawnow;
end
tempKNN=KNN;
%evaluate the KNN
for i=1:KNN.k
    [apV, rmse]=FastTestKNN(vOuts,vSets,KNN,i);
    KNN.apV = apV;
    KNN.fV = rmse;
    
    % evaluate the acc of validation sets.
    if KNN.apV >= tempKNN.apV && KNN.fV <= tempKNN.fV
        tempKNN=KNN;
        % save k.
        tempKNN.k = i;   
    end
    if graph2d  % 2D Graph
        plotvector = get(hbestplot,'YData');
        plotvector(i) = rmse;
        set(hbestplot,'YData',plotvector);
        set(htext,'String',sprintf('Best RMSE: %4.4f',tempKNN.fV));
        set(h2text,'String',sprintf('Best K: %4.0f',tempKNN.k));
        drawnow;
    end
end

[apV rmse]=FullTestKNN(tempKNN,vOuts,vSets);
accV=apV;


% saving validation data as training data
trSet=[trSets
       vSets];
trOut=[trOuts
       vOuts];
trData =trSet;
tempKNN.trData=trData;
tempKNN.trOut=trOut;



disp(['Optimal K:  K=' num2str(tempKNN.k)]);
disp(['General rmse: ' num2str(tempKNN.fV)]);
disp('RMES V: ');
disp(rmse');
disp('Acc V: ');
disp(apV');
close(hfig);
