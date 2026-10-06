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
% Evolutionary Algorithm to find the best
% Signal Characteristics for Pattern Recognition
%
% ------------------------- Updates & Contributors ------------------------
% [Contributors are welcome to add their email]
% 2009-05-05 / Max Ortiz  / Creation
% 2010-5-14 / Max Ortiz  / clear memory

function [cIdx, maxfitness] = EAchrs(handles)

%% Evolution Parameters

EA = get(handles.t_oEA,'UserData');

if isempty(EA)
    %npop individuals with ngenes each
    EA.npop = 40;               %Population size 
    EA.ngenes = 21;             %Nomber of Genes

    %range for genes
    EA.xmin = 0;
    EA.xmax = 1;

    %probabilities of change
    EA.pcross  = 0.8;           %crossover probability
    EA.pmut    = 0.05;            %mutation probability
    EA.ptour   = 0.75;             %turnament selection parameter

    EA.maxgenerations = 1000;         %max number of generations

    %Call function to populate the matrix
    EA.population = round(rand(EA.npop,EA.ngenes));
end

%% Training data    
treated_data = get(handles.t_treated_data,'UserData');
if isempty(treated_data)    
    set(handles.t_msg,'String','No treated data loaded!!!');
    return;    
end
% Get the effective number of set to be used
treated_data.etrN = str2double(get(handles.et_trN,'String'));
treated_data.evN = str2double(get(handles.et_vN,'String'));
treated_data.etN = str2double(get(handles.et_tN,'String'));
allChrs = fieldnames(treated_data.trdata);

%% Initialization
nrep    = 3;                                    % Time to average result
fbp     = get(handles.cb_backp,'Value');

tempfit = zeros(nrep,1);
tempacc = tempfit;
tempsim = tempfit;
divd  = str2double(get(handles.et_maxsims,'String'));       % Divider to keep the numer of simulation in the same order of fitness and accuracy
fitmat = zeros(EA.maxgenerations,1);                        % keep track of the evolution of the fitness

maxfitness  = get(handles.t_omaxf,'UserData');      % Get the last max fitness, in this case the minium
if isempty(maxfitness) || maxfitness == 0
    maxfitness = 100000;
end

%xbest           = EA.population(1,:);           % The best will be the first one in the population if it the popolation existed and if not, it will be re-write it anyway
tempi = get(handles.t_ogen,'UserData');         % Get the last max fitness, in this case the minium
if isempty(tempi)
    starti          = 1;
    fitness         = zeros(EA.npop,1);
    xbest           = EA.population(1,:);           % The best will be the first one in the population if it the popolation existed and if not, it will be re-write it anyway
    best_individual = 1;                            % IF not assigned the best individual will be the first one
else
    starti          = tempi;
    fitness         = get(handles.text28,'UserData');         % Get the last max fitness, in this case the minium
    xbest           = get(handles.text26,'UserData');         % Get the last max fitness, in this case the minium
    best_individual = get(handles.t_ss,'UserData');         % Get the last max fitness, in this case the minium
end
    
%Run until the max number of generations
for gen = 1:EA.maxgenerations
    %maxfitness = inf;

    %Call function to decode the chromosomes and evalutation of each
    %individual in the population
    for i = starti:EA.npop

        set(handles.t_msg2,'String',['Generation: ' num2str(gen) ' Ind: ' num2str(i)]);

        %Limit population to have only 4 characteristics        
        Cs  = find(EA.population(i,:));
        nC = length(Cs);
        if nC == 0          % Validation against 0
            rj = round(1 + rand * (EA.ngenes-1));
            EA.population(i,rj) = 1;
        end
        while nC > 5        % Validation agains more than 4
            rC = round(1 + rand * (nC-1));
            EA.population(i,Cs(rC)) = 0;
            Cs  = find(EA.population(i,:));
            nC = length(Cs);
        end
        % help to clear memory
        clear Cs;
        clear nC;
        clear rj;
        
        
        cIdx = decode_chromosomeChrs(EA.population(i,:));                   % Decode
        % Run it nrep times
        for j = 1 : nrep
            if fbp            
                ANN = train_ann_backp(handles, treated_data, cIdx);         % Run available training algorithms
                set(handles.t_bp,'UserData',ANN);
                tempfit(j) = ANN.Ft;
                tempacc(j) = 1/(ANN.At);
                tempsim(j) = str2double(get(handles.t_bpsims,'String'));
                clear ANN;
            end
            if get(handles.cb_break,'Value') == 1
                tempfit(j) = 1;
                tempacc(j) = 1;
                tempsim(j) = 1000;
            end
        end
        
        fitness(i) = mean(tempfit) * mean(tempacc) * (mean(tempsim)/divd);
        if (fitness(i) < maxfitness)                                %Elitism
            maxfitness = fitness(i);                                %keep the value of smallest fitness
            best_individual = i;                                    %keep the index of the higest fitness individual
            xbest = EA.population(i,:);                             %copy the best individual        
        end
        % Temp save to file after each invidual test
        cIdx = decode_chromosomeChrs(xbest);                   % Decode
        cChrs = allChrs(cIdx);
        tempi = i;
        save('SigChrsOptTEMP.mat','EA','maxfitness','cIdx','cChrs','fitness','tempi','xbest','best_individual');     % No need to save since it can be re-use at this point
        clear cIdx;
        clear cChrs;
    end
    
    starti = 1;
    fitmat(gen)     = maxfitness;
    xbestmat(gen,:) = xbest;

    %Ranking fitness
    %fitness = ranking_fitness(fitness, npop);

    %Create a temporal copy of the population
    temp_pop = EA.population;
    temp_pop(1,:) = xbest;
    temp_pop(2,:) = xbest;

    %Toutnament Selection and Crossover
    %it doesn't apply for the best individual of last generation that is
    %saved in the first 2 places of the matrix
    for i = 3:2:EA.npop                                            %It goes in steps of 2
        %i1 = tournament_select(fitness,EA.npop,EA.ptour);             %Select one individual from 2
        %i2 = tournament_select(fitness,EA.npop,EA.ptour);             %Select one individual from 2

        i1 = roulette_wheelChrs(fitness,EA.npop);                      %Select individual number 1
        i2 = roulette_wheelChrs(fitness,EA.npop);                      %Select individual number 2        
        
        r = rand;
        if (r < EA.pcross)                                         %If random number inside the probability of crossover
            new_individuals = crossoverChrs(EA.population,i1,i2,EA.ngenes);
            temp_pop(i,:)   = new_individuals(1,:);
            temp_pop(i+1,:) = new_individuals(2,:);
        else
            temp_pop(i,:)   = EA.population(i1,:);
            temp_pop(i+1,:) = EA.population(i2,:);
        end
        clear r;
        clear new_individuals;
    end

    %Mutation
    mr   = rand(EA.npop,EA.ngenes);          % This is a couple of ms faster than the algorithm below
    mrg  = round(rand(EA.npop,EA.ngenes));   % Two rand matrix are required otherwise it would be only high mutations
    midx = find((mr < EA.pmut));             % Find the individuals to mutate
    temp_pop(midx) = mrg(midx);              % Replace the original individual with the mutated individuals

    %Create 2 exact copies of the best individual, "Elitism", this is
    %required again by the way mutation is done
    temp_pop(1,:) = EA.population(best_individual,:);
    temp_pop(2,:) = EA.population(best_individual,:);

    %Copy new population
    EA.population = temp_pop;
    clear temp_pop;
    
    %Show result in matlab screen
    disp('EAchrs Maxfitness:');
    disp(maxfitness);
    %xbest    

    cIdx  = decode_chromosomeChrs(xbest)                   % Decode
    cChrs = allChrs(cIdx)

    %Show status in GUI
    set(handles.t_ogen,'String',num2str(gen));
    set(handles.t_omaxf,'String',num2str(maxfitness));
    set(handles.t_omaxf,'UserData',maxfitness);
    set(handles.t_tchrs,'UserData',cIdx);             
    set(handles.t_oEA,'UserData',EA);    
    set(handles.lb_ochrs,'String',cChrs);
        
    % Tamp save to file after each generation
    save('SigChrsOpt.mat','EA','maxfitness','cIdx','cChrs','fitness','fitmat','xbestmat');
    
    if get(handles.cb_break,'Value') == 1
        break;
    end
    
    clear cIdx;
    clear cChrs;
end

cIdx  = decode_chromosomeChrs(xbest);                   % Decode
disp('Charecteristics Index:');
disp(cIdx);
