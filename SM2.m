clear; clc

% calculates and saves participant level all_cluster_results to be used in
% further analyses; mainly eeg cluster-behavior correlations

%% Settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


rootFolder = ...
    'C:\Users\gulsu\Documents\MATLAB\Thesis\convmodel\convmodel\foi_4_30_buttonLR_signedHealthScore';

% model 1

modelFolder = fullfile(rootFolder,'DataModel1','SPM_tf');

statsFolder = fullfile( ...
    rootFolder,'Statistics','cluster_post_vs_baseline_4');

% model 2
% 
% modelFolder = fullfile(rootFolder,'Data','SPM_tf');
% 
% statsFolder = fullfile( ...
%     rootFolder,'Statistics','cluster_post_vs_baseline_recent_4');

saveFolder = fullfile(rootFolder,'BehavioralCorrelations');

if ~exist(saveFolder,'dir')
    mkdir(saveFolder)
end


subjects = [ ...
    1 2 3 5 7 9 10 12 13 14 15 ...
    17 18 19 20 22 23 24 25 26 ...
    27 28 29 31 32];


regressors = { ...
    'ButtonOnsetLeft', ...
    'ButtonOnsetRight', ...
    'XDeath', ...
    'MyDeath', ...
    'Health', ...
    'Score'};


p_threshold = 0.05;
z_threshold = 2.5;


% baselines used in the permutation analysis
buttonbaseline = [-0.800 -0.600];
mybaseline = [-0.250 -0.050];


%% results struct - master results to be saved
% this will be saved
allClusterResults = struct([]);

%% loop over regressors %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


for k = 1:length(regressors)

    regressor = regressors{k};

    
    %% load post-vs-baseline cluster result
  
    statFile = fullfile(statsFolder, ['stat3D_signed_within_' regressor '.mat']);

    load(statFile,'stat')


  
    %% baseline for this regressor
  
    if k < 3
        baselineWindow = buttonbaseline;
    else
        baselineWindow = mybaseline;
    end


    %% extract all significant post-vs-baseline clusters

    allClusterResults = extract_from_stat(allClusterResults, stat, subjects, regressor, k, ...
        'post_vs_baseline', ...
        modelFolder, baselineWindow, p_threshold, z_threshold);

    %% button-versus-zero analysis !!!!
    
    if k < 3

        zeroFile = fullfile( statsFolder, ['stat3D_signed_within_zero_' regressor '.mat']);

        if exist(zeroFile,'file')

            load(zeroFile,'stat')

            allClusterResults = extract_from_stat(allClusterResults, stat, subjects, regressor, k, ...
                'vs_zero', ...
                modelFolder, [], p_threshold, z_threshold);

        end
    end

end

%% save %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save(fullfile(saveFolder,'all_cluster_results.mat'), 'allClusterResults', 'subjects', 'p_threshold', 'z_threshold');

%% local function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% function loops through alpha/beta/theta clusters

function allClusterResults = extract_from_stat(allClusterResults, stat, subjects, regressor, regIndex, ...
    comparison, modelFolder, baselineWindow, p_threshold, z_threshold)


theta = stat{1};
alphabeta = stat{2};

directions = {'positive','negative'};


for d = 1:length(directions)

    direction = directions{d};

    if strcmp(direction,'positive')

        cluster_field = 'posclusters';
        label_field   = 'posclusterslabelmat';

    else

        cluster_field = 'negclusters';
        label_field   = 'negclusterslabelmat';

    end


    
    %% THETA

    if isfield(theta,cluster_field) && ~isempty(theta.(cluster_field))

        for cluster_number = 1:length(theta.(cluster_field))

            cluster_p = theta.(cluster_field)(cluster_number).prob;

            if cluster_p < p_threshold

                mask = squeeze(theta.(label_field)(:,1,:) == cluster_number);

                ch = find(sum(mask,2) > 5);

                if ~isempty(ch)

                    result = calculate_cluster_value( ...
                        subjects, ...
                        regressor, ...
                        regIndex, ...
                        comparison, ...
                        'Theta', ...
                        direction, ...
                        cluster_number, ...
                        cluster_p, ...
                        mask, ...
                        ch, ...
                        theta.time, ...
                        theta.label, ...
                        [4 6], ...
                        modelFolder, ...
                        baselineWindow, ...
                        z_threshold);

                    if isempty(allClusterResults)
                        allClusterResults = result;
                    else
                        allClusterResults(end+1) = result;
                    end

                end
            end
        end
    end


    %% ALPHA
    % stat{2}, bin 1 -- alpha

    if isfield(alphabeta,cluster_field) && ...
            ~isempty(alphabeta.(cluster_field))

        for cluster_number = 1:length(alphabeta.(cluster_field))

            cluster_p = alphabeta.(cluster_field)(cluster_number).prob;

            if cluster_p < p_threshold

                mask = squeeze(alphabeta.(label_field)(:,1,:) == cluster_number);

                ch = find(sum(mask,2) > 5);

                if ~isempty(ch)

                    result = calculate_cluster_value( ...
                        subjects, ...
                        regressor, ...
                        regIndex, ...
                        comparison, ...
                        'Alpha', ...
                        direction, ...
                        cluster_number, ...
                        cluster_p, ...
                        mask, ...
                        ch, ...
                        alphabeta.time, ...
                        alphabeta.label, ...
                        [8 10 12], ...
                        modelFolder, ...
                        baselineWindow, ...
                        z_threshold);

                    if isempty(allClusterResults)
                        allClusterResults = result;
                    else
                        allClusterResults(end+1) = result;
                    end

                end
            end
        end
    end


    %% BETA
    % stat{2}, bin 2 -- beta
  

    if isfield(alphabeta,cluster_field) && ~isempty(alphabeta.(cluster_field))

        for cluster_number = 1:length(alphabeta.(cluster_field))

            cluster_p = alphabeta.(cluster_field)(cluster_number).prob;

            if cluster_p < p_threshold

                mask = squeeze(alphabeta.(label_field)(:,2,:) == cluster_number);

                ch = find(sum(mask,2) > 5);

                if ~isempty(ch)

                    result = calculate_cluster_value( ...
                        subjects, ...
                        regressor, ...
                        regIndex, ...
                        comparison, ...
                        'Beta', ...
                        direction, ...
                        cluster_number, ...
                        cluster_p, ...
                        mask, ...
                        ch, ...
                        alphabeta.time, ...
                        alphabeta.label, ...
                        14:2:30, ...
                        modelFolder, ...
                        baselineWindow, ...
                        z_threshold);

                    if isempty(allClusterResults)
                        allClusterResults = result;
                    else
                        allClusterResults(end+1) = result;
                    end

                end
            end
        end
    end

end

end




%% LOCAL FUNCTION
% function calculates participant values for one band specific cluster

function result = calculate_cluster_value( ...
    subjects, ...
    regressor, ...
    regIndex, ...
    comparison, ...
    band, ...
    direction, ...
    cluster_number, ...
    cluster_p, ...
    mask, ...
    ch, ...
    stat_time, ...
    labels, ...
    target_freqs, ...
    modelFolder, ...
    baselineWindow, ...
    z_threshold)


participant_values = nan(length(subjects),1);



%% cluster metadata %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


cluster_time_idx = find(any(mask(ch,:),1));

latency = [min(stat_time(cluster_time_idx)) max(stat_time(cluster_time_idx))];



%% loop through participnats %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


for i = 1:length(subjects)

    s = subjects(i);

    % model 1
    modelFile = fullfile( ...
        modelFolder, ...
        ['participant_' num2str(s)], ...
        ['conv_model_signed_atf_' ...
         num2str(s) ...
         '_game_spm_cont.mat']);

    % model 2
    % modelFile = fullfile(modelFolder, ...
    %     ['participant_' num2str(s)], ...
    %     ['conv_model_signed_currenthealth_atf_' ...
    %      num2str(s) ...
    %      '_game_spm_cont_signed_currenthealth.mat']); 

    D = spm_eeg_load(modelFile);

    time = double(D.fttimelock.time);
    freq = double(D.fttimelock.freq);


    
    %% get the original regressor response, channel x frequency x time

    x = double(squeeze(.fttimelock.powspctrm(regIndex,:,:,:)));

    
    %% contrast used in permutation test

    if strcmp(comparison,'post_vs_baseline')

        [~,xp1] = min(abs(time-baselineWindow(1)));
        [~,xp2] = min(abs(time-baselineWindow(2)));

        mbas = mean(x(:,:,xp1:xp2), 3, 'omitnan');

        % data - baseline
        xdiff = x - mbas;

    elseif strcmp(comparison,'vs_zero')

        % data - zero
        xdiff = x;

    end


    %% frequency averaging??
    % logic I got from run_cluster_3D_dependent!! CHECK!!!! %%%%%%%%%%%%%%
 
    ii = dsearchn(freq',target_freqs(:));

    % channel x time
    band_data = squeeze(mean(xdiff(:,ii,:), 2,'omitnan'));


    %% select the time samples represented in stat.time
 

    time_idx = zeros(1,length(stat_time));

    for t = 1:length(stat_time)

        [~,time_idx(t)] = min(abs(time-stat_time(t)));

    end

    band_data = band_data(:,time_idx);


    
    %% channels passing >5 cluster samples
    

    band_data = band_data(ch,:);


    %% band-specific cluster membership

    cluster_mask = mask(ch,:);


    %% participant-level cluster value

    % here only channel x time samples belonging
    % to this band specific cluster is averaged
  
    participant_values(i) = mean(band_data(cluster_mask), 'omitnan');

end



%% Z SCORES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


participant_mean = mean(participant_values,'omitnan');

participant_sd = std(participant_values,0,'omitnan');

participant_zscores = (participant_values-participant_mean) ./ participant_sd;

z_flagged_indices = find(abs(participant_zscores) > z_threshold);

z_flagged_subjects = subjects(z_flagged_indices);



%% result structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


result = struct();

result.regressor = regressor;
result.comparison = comparison;
result.band = band;

result.direction = direction;
result.cluster_number = cluster_number;
result.cluster_p = cluster_p;

result.target_frequencies = target_freqs;

result.latency = latency;

result.channel_indices = ch;
result.channel_labels = labels(ch);
result.n_channels = length(ch);

result.cluster_mask = mask;
result.stat_time = stat_time;

result.subjects = subjects;

result.participant_values = participant_values;
result.participant_zscores = participant_zscores;

result.z_threshold = z_threshold;
result.z_flagged_indices = z_flagged_indices;
result.z_flagged_subjects = z_flagged_subjects;

end