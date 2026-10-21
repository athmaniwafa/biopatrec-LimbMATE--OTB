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
% tournament_select
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz  / Creation
% 20xx-xx-xx / Author  / Comment on update


function i = tournament_select(fitness,npop,ptour)

itmp1 = 1 + fix(rand*npop);                 %Select an individual randomly
itmp2 = 1 + fix(rand*npop);                 %Select an individual randomly

r = rand;

if (r < ptour)                              %Select the best or worst according to the ptour probability
    if (fitness(itmp1) > fitness(itmp2))
        i = itmp1;
    else
        i = itmp2;
    end
else
    if (fitness(itmp1) > fitness(itmp2))
        i = itmp2;
    else
        i = itmp1;
    end
end