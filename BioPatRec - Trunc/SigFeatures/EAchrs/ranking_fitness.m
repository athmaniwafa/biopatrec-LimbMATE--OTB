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
% ranking_fistness
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update


function newfitness = ranking_fitness(fitness, npop)

fmax = max(fitness);         %Get max value
fmin = min(fitness);        %Get min value

fsort = sort(fitness);       %If we are looking for the maximum value the acending order works well because
                            %the higest fitness will be at the end and can
                            %be linked to its index like que ranking value

for i = 1:npop                      %Run for all the population
    for j = 1:npop                  %to find wich is the value of its rank
        if fitness(i) == fsort(j)
            frank(i) = j;
            break
        end
    end
end

%Write new fitness
for i = 1:npop
    newfitness(i) = fmax - (fmax - fmin)*((frank(i)-1)/(npop-1)); 
end