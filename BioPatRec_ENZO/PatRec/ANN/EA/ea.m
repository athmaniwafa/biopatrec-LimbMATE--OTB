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
% Evolutionary Algorithm to evolve values of a ANN
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-04-23 / Max Ortiz / Creation
% 20xx-xx-xx / Author  / Comment on update



function [EA, ANN] = ea(EA,ANN,x,y)

fitness = zeros(EA.npop,1);

%Run until the max number of generations
for gen = 1:EA.maxgenerations
    maxfitness = inf;

    %Call function to decode the chromosomes and evalutation of each
    %individual in the population
    for i = 1:EA.npop
        ANN = decode(ANN,EA.population(i,:));                 %Decode creating a matrix
        fitness(i) = evaluate_p(ANN,x,y);                     %Evaluate
        if (fitness(i) < maxfitness)                                %Elitism
            maxfitness = fitness(i);                                %keep the value of higest fitness
            best_individual = i;                                    %keep the index of the higest fitness individual
            xbest = EA.population(i,:);                             %copy the best individual
        end
    end

    %Ranking fitness
    % fitness = ranking_fitness(fitness, EA.npop);

    %Create a temporal copy of the population
    temp_pop = EA.population;
    temp_pop(1,:) = EA.population(best_individual,:);
    %temp_pop(2,:) = EA.population(best_individual,:);

    %Toutnament Selection and Crossover
    %it doesn't apply for the best individual of last generation that is
    %saved in the first 2 places of the matrix
    for i = 3:2:EA.npop                                            %It goes in steps of 2
        %i1 = tournament_select(fitness,EA.npop,EA.ptour);             %Select one individual from 2
        %i2 = tournament_select(fitness,EA.npop,EA.ptour);             %Select one individual from 2

        i1 = roulette_wheel(fitness,EA.npop);                      %Select individual number 1
        i2 = roulette_wheel(fitness,EA.npop);                      %Select individual number 2        
        
        r = rand;
        if (r < EA.pcross)                                         %If random number inside the probability of crossover
            new_individuals = crossover(EA.population,i1,i2,EA.ngenes);
            temp_pop(i,:) = new_individuals(1,:);
            temp_pop(i+1,:) = new_individuals(2,:);
        else
            temp_pop(i,:) = EA.population(i1,:);
            temp_pop(i+1,:) = EA.population(i2,:);
        end
    end

    %Mutation
    % Change mutation rate if population is inbreeding
    if sum(mean(EA.population) > std(EA.population))/EA.ngenes > EA.pinbrd
        EA.pmut = EA.pmut * 2;
    else
        EA.pmut = 1/EA.ngenes;
    end
    % Apply mutation
    mr  = rand(EA.npop,EA.ngenes);       % This is a couple of ms faster than the algorithm below
    mrg = EA.xmin + rand(EA.npop,EA.ngenes) .* (EA.xmax-EA.xmin);  % Two rand matrix are required otherwise it would be only high mutations
    midx = find((mr < EA.pmut));
    temp_pop(midx) = mrg(midx);

    %Create 2 exact copies of the best individual, "Elitism"
    temp_pop(1,:) = EA.population(best_individual,:);
    %temp_pop(2,:) = EA.population(best_individual,:);

    %Copy new population
    EA.population = temp_pop;
    
    %Show result in matlab screen
    disp(maxfitness);
    %xbest    

end

ANN = decode(ANN,xbest);
ANN.fit = maxfitness;

