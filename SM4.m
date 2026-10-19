clear; clc

addpath('C:\Users\gulsu\Documents\MATLAB\Thesis\convmodel\convmodel\data');
load('behavsync_group.mat'); % load the behavioral data

savedir = 'C:\Users\gulsu\Documents\MATLAB\Thesis\convmodel\convmodel\foi_4_30_buttonLR_signedHealthScore\BehavioralCorrelations'; % where to save any output
addpath(savedir);

subjects = [1 2 3 5 7 9 10 12 13 14 15 ...
            17 18 19 20 22 23 24 25 26 ...
            27 28 29 31 32]; % N=25 final sample


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% descriptive stats %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for s = subjects

%% health
health = behavsync{s}.health.Y;
health_x = [0; diff(health)];

health_desc{1} = length(health);
health_desc{2} = mean(health_x,'omitnan');
health_desc{3} = std(health_x,'omitnan');
health_desc{4} = min(health);
health_desc{5} = max(health);
health_desc{6} = range(health);

%% score
score = behavsync{s}.damage.Y;
score_x = [0; diff(score)];

score_desc{1} = length(score);
score_desc{2} = mean(score_x,'omitnan');
score_desc{3} = std(score_x,'omitnan');
score_desc{4} = min(score);
score_desc{5} = max(score);
score_desc{6} = range(score);

%% enemy deaths
xdeaths = behavsync{s}.xdeaths.Y;
xdeaths_desc = {length(xdeaths),'NA','NA','NA','NA','NA'};

%% player deaths
player_deaths = behavsync{s}.health.mytime_death_ms;
player_deaths_desc = {length(player_deaths),'NA','NA','NA','NA','NA'};

%% button presses
buttons = behavsync{s}.buttons.Y;
button_desc = {length(buttons),'NA','NA','NA','NA','NA'};

%% save descriptives for this participant
descriptives{s,1} = health_desc;
descriptives{s,2} = score_desc;
descriptives{s,3} = xdeaths_desc;
descriptives{s,4} = player_deaths_desc;
descriptives{s,5} = button_desc;

%% button-specific counts
button_counts(s,:) = [ ...
    sum(buttons(:)==1), ...
    sum(buttons(:)==2), ...
    sum(buttons(:)==3), ...
    sum(buttons(:)==4), ...
    sum(buttons(:)==5), ...
    sum(buttons(:)==6), ...
    sum(buttons(:)==7), ...
    sum(buttons(:)==8), ...
    sum(buttons(:)==6 | buttons(:)==8), ...
    sum(buttons(:)<6 | buttons(:)==7)];
    % buttons from 1-8 and right and left hand compiled
    % 6,8 left hand
    % 1,2,3,4,5,7 right hand
    
end

descriptives = descriptives(subjects,:); % only active subjects
button_counts = button_counts(subjects,:);
        

        %% save
        %save(fullfile(savedir,'participantlevel_behavioral_descriptives.mat'),'descriptives');
        %save(fullfile(savedir,'participantlevel_button_descriptives.mat'),'button_counts');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Behavioral Performance Measures %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Original game-controller button coding:
%
% Right hand:
%   A  B  X  Y  RS  R
%   1  2  3  4  5   7
%
% Left hand:
%   LS L
%   6  8

% Measure -- Calculation
%
% Enemy kills/min -- N enemy deaths / duration_min
% R (shoot) presses/min -- N(R) / duration_min
% Enemy kills/R presses -- N enemy deaths / N(R)
% Score accumulation rate -- (final score − initial score) / duration_min
% Overall action rate -- N(all button presses) / duration_min
% Action entropy -- Shannon entropy of button-code distribution
% Actions per kill -- N(all button presses) / N enemy deaths
% Combat action rate -- N(combat button presses) / duration_min
% Combat actions per kill -- N(combat button presses) / N enemy deaths


combat_codes = [3 4 5 7]; % the buttons used for combat, but not really sure about these??
% X - Reload / interact
% Y - Switch weapon; hold for sidearm
% RS - Melee
% R - Shoot


for i = 1:length(subjects)

    s = subjects(i);

    buttons = behavsync{s}.buttons.Y;
    button_time = behavsync{s}.buttons.mytime_ms;
    xdeaths = behavsync{s}.xdeaths.Y;

    duration_min = (button_time(end) - button_time(1)) / 60000; % active gameplay duration
    n_kills = length(xdeaths);
    n_R = sum(buttons == 7);
    n_actions = length(buttons);
    n_combat = sum(ismember(buttons,combat_codes));
    score = behavsync{s}.damage.Y;

    % action entropy: I thought of it how evenly or disparsely the 8 buttons
    % are used by a participant
    p = histcounts(buttons,0.5:1:8.5,'Normalization','probability'); % proportions of each button
    p = p(p > 0); %remove buttons that are never used, bec log2(0) is undefined
    entropy = -sum(p .* log2(p)); % calculate shannon entropy
    % for Shannon entropy the value will be btw 0 and 3 bits.
    % 0 would be -- only one button was ever used (like extremely
    % stereotyped behavior)
    % 3 bits would be all 8 buttons used equally frequently (max possible
    % diversity)
    % values increasing from 0 to 3: would indicate increasing diversity or
    % evenness
    % BUTTTT - I will check between participant variability here bec maybe
    % the game imposes common task demands, and everyone has similar
    % entropy and hence it would be a poor-individual differences
    % variable??
    % So -- Before correlating it with EEG, I will inspect:
        % Mean and SD of entropy across participants
        % min–max/range
        % histogram or individual-participant plot
    entropy_norm = entropy / log2(8); % normalized entropy, 0-1, 0: 1 button used only, 1: even use of all  buttons
    
    ScoreAccumRate(i,1) = score(end) / duration_min;
    EnemyKillsPerMin(i,1) = n_kills / duration_min;
    RPressesPerMin(i,1) = n_R / duration_min;
    KillsPerR(i,1) = n_kills / n_R;

    OverallActionRate(i,1) = n_actions / duration_min;
    ActionEntropy(i,1) = entropy_norm;
    ActionsPerKill(i,1) = n_actions / n_kills;

    CombatActionRate(i,1) = n_combat / duration_min;
    CombatActionsPerKill(i,1) = n_combat / n_kills;

end

T = table(subjects', ...
    ScoreAccumRate, ...
    EnemyKillsPerMin, ...
    RPressesPerMin, ...
    KillsPerR, ...
    OverallActionRate, ...
    ActionEntropy, ...
    ActionsPerKill, ...
    CombatActionRate, ...
    CombatActionsPerKill, ...
    'VariableNames', { ...
    'Participant', ...
    'ScoreAccumulationRate', ...
    'EnemyKillsPerMin', ...
    'RPressesPerMin', ...
    'KillsPerR', ...
    'OverallActionRate', ...
    'ActionEntropy', ...
    'ActionsPerKill', ...
    'CombatActionRate', ...
    'CombatActionsPerKill'});

disp(T)


%% NOTES for me after inspecting these 9 variables:

% 1. entropy is a weak individual difference measure.normalized entropy
% ranges roughly .39–.52, with most participants packed around .42–.47. 
% So there is some variability, but much less than in the performance 
% measures. 
% Before discarding it: I will calculate its SD and plot the distribution 
% before deciding. Participant 14 (~.52) and 19 (~.39) -- obvious extremes

% 2. maybe there is a strong underlying general 'performance' dimension?
% Participants with high score accumulation generally also have high 
% kills/min... maybe reassuring since two independent behavioral measures
% are indetifying similar high or low performing participants

% 3. Several of these variables are mathematically redundant, I need to
% keep only one of them: 
% like actionsperkill, combatactionsperkill, and killsperR
% these are not nine independent behavioral dimensions: so before EEG
% correlations, I will do a correlation matrix among the behavioral
% measures themselves and reduce redundancy by discarding some of them. 

% 3b. I think R presses dominate combat action rate anyways, so no need to
% keep them all: combat_codes are driven by mostly Rs....

% 4. Overall action rate varies enormously. Like part23 is around 100,
% part32 is around 282. -- Potentiallly a good interindivual measure??

% 5. Some behaviorally INTERESTINGG participants ----- p19: low score and
% kills, low entropy, and 185.7 actions per kill. 
% p32 almost the opposite: hisghest kill/min, very high score, high action
% rate, but only 70.7 actions per kill. 
% looks like an efficiency contrast
% but 32 is also an expert player????
% also there might be differences due to class as well... These should go
% into discussion



%%
% get behavioral variables only
X = T{:,2:end};

%% 9 x 9 Pearson correlation matrix
R = corr(X,'Rows','complete');

R_table = array2table(R, ...
    'VariableNames',T.Properties.VariableNames(2:end), ...
    'RowNames',T.Properties.VariableNames(2:end));

disp(R_table)


%% Descriptive statistics for behavioral measures
Mean = mean(X,1,'omitnan')';
SD   = std(X,0,1,'omitnan')';
Min  = min(X,[],1)';
Max  = max(X,[],1)';

Variable = T.Properties.VariableNames(2:end)';

Desc_table = table(Variable,Mean,SD,Min,Max);

disp(Desc_table)


%% NOTES for me after isnpection:

% I will drop these 4 variables because they are redundant and highly
% correlated with some others:
% OverallActionRate
% ActionsPerKill
% CombatActionRate
% CombatActionsPerKill

% I am keeping these 5 variables : because:

% ScoreAccumulationRate : I thnk this might be a global performance/ 
% progression measure; with substantial variability (32.5–351.6)

% EnemyKillsPerMin : direct combat-performance measure. Correlates strongly
% with scoreacc (r = .85), but conceptually distinct enough that I 
% will keep it initially

% RPressesPerMin : this one is the most simple measure of firing/action 
% intensity compared to the dropped ones

% KillsPerR : combat efficiency relative to R use; 
% captures something different from raw activity I think

% ActionEntropy : not really sure about this one; buy only measure of 
% behavioral repertoire/diversity here. Correlations with the other 
% variables are moderate or small, and there is somewhat between-participant 
% variation (.387–.521), so will keep for now????

%% Variables to keep

vars = {'ScoreAccumulationRate', ...
        'EnemyKillsPerMin', ...
        'RPressesPerMin', ...
        'KillsPerR', ...
        'ActionEntropy'};

X = T{:,vars};

%save(fullfile(savedir,'participantlevel_behavioral_measures.mat'), ...
%   'X','vars');
%% Descriptive statistics

Mean = mean(X,1,'omitnan')';
SD   = std(X,0,1,'omitnan')';
Min  = min(X,[],1)';
Max  = max(X,[],1)';

Desc = table(vars',Mean,SD,Min,Max, 'VariableNames',{'Variable','Mean','SD','Min','Max'});

disp('DESCRIPTIVES of Behavioral Measures')
disp(Desc)


%% Pearson correlations

[R,P] = corr(X,'Type','Pearson','Rows','complete');

R_table = array2table(R,'VariableNames',vars,'RowNames',vars);

P_table = array2table(P, 'VariableNames',vars, 'RowNames',vars);

disp('PEARSON R')
disp(R_table)

disp('P VALUES')
disp(P_table)

%% FDR correction for multiple correlations

%% FDR correction

mask = triu(true(size(P)),1);
pvals = P(mask);

p_fdr = mafdr(pvals,'BHFDR',true);

P_FDR = nan(size(P));
P_FDR(mask) = p_fdr;

P_FDR = P_FDR';
P_FDR(mask) = p_fdr;

P_FDR(1:size(P_FDR,1)+1:end) = 1;

P_FDR_table = array2table(P_FDR, 'VariableNames',vars, 'RowNames',vars);

disp(P_FDR_table)


%% Scatterplots
% Check linear relationships and obvious outliers

figure
plotmatrix(X) % pairwise scatter plots, I think looks OK


%% Spearman sensitivity check

[R_spearman, P_spearman] = corr(X, 'Type','Spearman', 'Rows','complete');

R_spearman_table = array2table(R_spearman, 'VariableNames',vars, 'RowNames',vars);

P_spearman_table = array2table(P_spearman, 'VariableNames',vars, 'RowNames',vars);

disp('SPEARMAN R')
disp(R_spearman_table)

disp('SPEARMAN P VALUES')
disp(P_spearman_table)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EEG CORRELATES GLM 1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% New participant-level cluster file.
% allClusterResults is now a STRUCT ARRAY, with one element per
% cluster-band result (e.g., Alpha and Beta are separate elements).
%
% Important fields used here:
%   regressor
%   comparison
%   band
%   direction
%   cluster_number
%   cluster_p
%   subjects
%   participant_values

glm1File = ...
    'C:\Users\gulsu\Documents\MATLAB\Thesis\convmodel\convmodel\foi_4_30_buttonLR_signedHealthScore\BehavioralCorrelations\all_cluster_results_model1_p05.mat';

S1 = load(glm1File);

fn1 = fieldnames(S1);
isClusterVar1 = contains(lower(fn1),'allclusterresults');

allClusterResults1 = S1.(fn1{find(isClusterVar1,1)});

% behavioral measures. X rows correspond to "subjects" / Or you can use the
% variable created before!!!!
load participantlevel_behavioral_measures.mat;


%% Pearson cluster-behavior correlations


results = {};

for c = 1:numel(allClusterResults1)

    if iscell(allClusterResults1)
        cluster = allClusterResults1{c};
    else
        cluster = allClusterResults1(c);
    end

    cluster_values = cluster.participant_values(:);
    cluster_subjects = cluster.subjects(:);

    % explicitly align behavior rows to the subject order stored with
    % this cluster, do not assume participant order!!!!

    [subject_found,behavior_row] = ismember(cluster_subjects,subjects(:));

    for v = 1:length(vars)

        behavior_values = X(behavior_row,v);

        [r,p] = corr(cluster_values,behavior_values, 'Type','Pearson', 'Rows','complete');

        results{end+1,1}  = cluster.regressor;
        results{end,2}    = cluster.comparison;
        results{end,3}    = cluster.band;
        results{end,4}    = cluster.direction;
        results{end,5}    = cluster.cluster_number;
        results{end,6}    = cluster.cluster_p;
        results{end,7}    = vars{v};
        results{end,8}    = r;
        results{end,9}    = p;

    end
end


%% Make table

R_model1 = cell2table(results, ...
    'VariableNames', { ...
    'Regressor', ...
    'Comparison', ...
    'Band', ...
    'Direction', ...
    'ClusterNumber', ...
    'ClusterP', ...
    'Behavior', ...
    'PearsonR', ...
    'PValue'});

disp('GLM 1 PEARSON CLUSTER-BEHAVIOR CORRELATIONS')
disp(R_model1)


%% FDR correction across all GLM 1 cluster-band x behavior correlations
% 
% pvals = R_model1.PValue;
% 
% p_fdr = mafdr(pvals,'BHFDR',true);
% 
% R_model1.P_FDR = p_fdr;
% 
% disp('GLM 1 PEARSON CORRELATIONS WITH FDR')
% disp(R_model1)


%% Save

save(fullfile(savedir,'cluster_behavior_correlations_model1.mat'), 'R_model1');

% writetable(R_model1, fullfile(savedir,'cluster_behavior_correlations_model1.csv'));



%% Spearman sensitivity correlations


results_s = {};

for c = 1:numel(allClusterResults1)

    if iscell(allClusterResults1)
        cluster = allClusterResults1{c};
    else
        cluster = allClusterResults1(c);
    end

    cluster_values = cluster.participant_values(:);
    cluster_subjects = cluster.subjects(:);

    [subject_found,behavior_row] = ismember(cluster_subjects,subjects(:));

    for v = 1:length(vars)

        behavior_values = X(behavior_row,v);

        [r,p] = corr(cluster_values,behavior_values, 'Type','Spearman', 'Rows','complete');

        results_s{end+1,1} = cluster.regressor;
        results_s{end,2}   = cluster.comparison;
        results_s{end,3}   = cluster.band;
        results_s{end,4}   = cluster.direction;
        results_s{end,5}   = cluster.cluster_number;
        results_s{end,6}   = cluster.cluster_p;
        results_s{end,7}   = vars{v};
        results_s{end,8}   = r;
        results_s{end,9}   = p;

    end
end


R_spearman_model1 = cell2table(results_s, ...
    'VariableNames', { ...
    'Regressor', ...
    'Comparison', ...
    'Band', ...
    'Direction', ...
    'ClusterNumber', ...
    'ClusterP', ...
    'Behavior', ...
    'SpearmanRho', ...
    'PValue'});


%% FDR correction

% pvals = R_spearman_model1.PValue;
% 
% p_fdr = mafdr(pvals,'BHFDR',true);
% 
% R_spearman_model1.P_FDR = p_fdr;
% 
% disp('GLM 1 SPEARMAN CORRELATIONS WITH FDR')
% disp(R_spearman_model1)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EEG CORRELATES GLM 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Change only this file path/name to your GLM 2 cluster-results file.
% The code does not require the internal variable to have exactly the same
% name as GLM 1; it identifies the allClusterResults variable automatically.

glm2File = ...
    'C:\Users\gulsu\Documents\MATLAB\Thesis\convmodel\convmodel\foi_4_30_buttonLR_signedHealthScore\BehavioralCorrelations\all_cluster_results_model2_p05.mat';

S2 = load(glm2File);

fn2 = fieldnames(S2);
isClusterVar2 = contains(lower(fn2),'allclusterresults');

allClusterResults2 = S2.(fn2{find(isClusterVar2,1)});

% X and vars are already loaded above

%% Pearson cluster-behavior correlations

results = {};

for c = 1:numel(allClusterResults2)

    if iscell(allClusterResults2)
        cluster = allClusterResults2{c};
    else
        cluster = allClusterResults2(c);
    end

    cluster_values = cluster.participant_values(:);
    cluster_subjects = cluster.subjects(:);

    [subject_found,behavior_row] = ismember(cluster_subjects,subjects(:));


    for v = 1:length(vars)

        behavior_values = X(behavior_row,v);

        [r,p] = corr(cluster_values,behavior_values, 'Type','Pearson', 'Rows','complete');

        results{end+1,1}  = cluster.regressor;
        results{end,2}    = cluster.comparison;
        results{end,3}    = cluster.band;
        results{end,4}    = cluster.direction;
        results{end,5}    = cluster.cluster_number;
        results{end,6}    = cluster.cluster_p;
        results{end,7}    = vars{v};
        results{end,8}    = r;
        results{end,9}    = p;

    end
end


%% Make table

R_model2 = cell2table(results, ...
    'VariableNames', { ...
    'Regressor', ...
    'Comparison', ...
    'Band', ...
    'Direction', ...
    'ClusterNumber', ...
    'ClusterP', ...
    'Behavior', ...
    'PearsonR', ...
    'PValue'});

disp('GLM 2 PEARSON CLUSTER-BEHAVIOR CORRELATIONS')
disp(R_model2)


%% FDR correction across all GLM 2 cluster-band x behavior correlations

% pvals = R_model2.PValue;
% 
% p_fdr = mafdr(pvals,'BHFDR',true);
% 
% R_model2.P_FDR = p_fdr;
% 
% disp('GLM 2 PEARSON CORRELATIONS WITH FDR')
% disp(R_model2)
% 
% 
% %% Save
% 
save(fullfile(savedir,'cluster_behavior_correlations_model2.mat'), 'R_model2');
% %
% % writetable(R_model2, fullfile(savedir,'cluster_behavior_correlations_model2.csv'));
% 
% 


%% Spearman sensitivity correlations

results_s = {};

for c = 1:numel(allClusterResults2)

    if iscell(allClusterResults2)
        cluster = allClusterResults2{c};
    else
        cluster = allClusterResults2(c);
    end

    cluster_values = cluster.participant_values(:);
    cluster_subjects = cluster.subjects(:);

    [subject_found,behavior_row] = ismember(cluster_subjects,subjects(:));

  

    for v = 1:length(vars)

        behavior_values = X(behavior_row,v);

        [r,p] = corr(cluster_values,behavior_values, 'Type','Spearman', 'Rows','complete');

        results_s{end+1,1} = cluster.regressor;
        results_s{end,2}   = cluster.comparison;
        results_s{end,3}   = cluster.band;
        results_s{end,4}   = cluster.direction;
        results_s{end,5}   = cluster.cluster_number;
        results_s{end,6}   = cluster.cluster_p;
        results_s{end,7}   = vars{v};
        results_s{end,8}   = r;
        results_s{end,9}   = p;

    end
end


R_spearman_model2 = cell2table(results_s, ...
    'VariableNames', { ...
    'Regressor', ...
    'Comparison', ...
    'Band', ...
    'Direction', ...
    'ClusterNumber', ...
    'ClusterP', ...
    'Behavior', ...
    'SpearmanRho', ...
    'PValue'});


%% FDR correction
% 
% pvals = R_spearman_model2.PValue;
% 
% p_fdr = mafdr(pvals,'BHFDR',true);
% 
% R_spearman_model2.P_FDR = p_fdr;
% 
% disp('GLM 2 SPEARMAN CORRELATIONS WITH FDR')
% disp(R_spearman_model2)
