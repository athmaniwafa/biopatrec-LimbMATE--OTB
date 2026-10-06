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
% decode_chromosome.m
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 20xx-xx-xx / Max Ortiz / Creation
% 20xx-xx-xx / Author  / Comment on update


function w = encode(ANN)

    %w1
    w(1 : ANN.nIn*ANN.nHn)                                                          = ANN.w1(1:ANN.nIn*ANN.nHn);

    %b1
    w(ANN.nIn*ANN.nHn + 1 : ANN.nIn*ANN.nHn + ANN.nHn)                              = ANN.b1(1:ANN.nHn);

    %w2
    w(ANN.nIn*ANN.nHn + ANN.nHn + 1 : ANN.nIn*ANN.nHn + ANN.nHn + ANN.nHn*ANN.nOn)  = ANN.w2(1:ANN.nHn*ANN.nOn);

    %b1
    w(ANN.nIn*ANN.nHn + ANN.nHn + ANN.nHn*ANN.nOn + 1 : ...
      ANN.nIn*ANN.nHn + ANN.nHn + ANN.nHn*ANN.nOn + ANN.nOn)                        = ANN.b2(1:ANN.nOn);
