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
% [Give a short summary about the principle of your function here.]
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz / Creation
% 20xx-xx-xx / Author  / Comment on update

function indiv = roulette_wheelChrs(fitness,npop)

sumfitness = sum(fitness);

for i = 1:npop     
    pfitness(i) = fitness(i) / sumfitness;       %Get the probability according to fitness
    if i==1
        lowlimpf(i)=0.0;                         %The lower limit for the first one will always be 0
    else
        lowlimpf(i) = uplimpf(i-1);              %Set the lower limit in the RW according to probability
    end 
    uplimpf(i) = lowlimpf(i) + pfitness(i);      %Set the uper limit in the RW according to probability
end

r = rand;                                        %Number randomly generated
for i = 1:npop
    if (r >= lowlimpf(i)) && (r <= uplimpf(i))
        indiv = i;
        break
    end
end

if ~exist('indiv','var')
    indiv = randi(npop,1);
end