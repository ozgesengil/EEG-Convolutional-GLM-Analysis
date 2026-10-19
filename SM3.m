clear; clc; close all

%% 
% this script loads corresponding stats files from cluster perm analysis
% and convolution files for each participant to calculate participant level
% cluster value, and across participants cluster info for confirmatory &
% exploratory clusters.
% It then does a bunch of visualizations and saves the resulting figures
% systematically.


%%

% Things to change in the code to inspect different regressors:
%
% cd
% modelFolder
% load stat file
% comparison
% p_threshold
% cluster_direction
% cluster_number
% regIndex
% baselineWindow (only relevant for post_vs_baseline)
% subject list



%% figure formatting and style %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Figure formatting
set(groot,'defaultFigureColor','w')
set(groot,'defaultAxesFontName','Times New Roman')
set(groot,'defaultTextFontName','Times New Roman')
set(groot,'defaultLegendFontName','Times New Roman')
set(groot,'defaultColorbarFontName','Times New Roman')

% figure text
figureFontSize = 24;
figureFontSize_legend = 16;
figureTitleFontSize = 30;

set(groot,'defaultAxesFontSize',figureFontSize)
set(groot,'defaultTextFontSize',figureFontSize)
set(groot,'defaultLegendFontSize',figureFontSize_legend)
set(groot,'defaultAxesTitleFontSizeMultiplier', ...
    figureTitleFontSize/figureFontSize)

% frequency-band colours for line plots
thetaColor = [0.50 0.18 0.55];   % purple
alphaColor = [0.85 0.25 0.55];   % pink
betaColor  = [0.75 0.10 0.15];   % red

thetaFill = [0.88 0.80 0.90];
alphaFill = [0.96 0.82 0.89];
betaFill  = [0.93 0.80 0.82];



%% analysis type

% Choose:
% 'post_vs_baseline'
% 'vs_zero'

%comparison = 'vs_zero';
comparison = 'post_vs_baseline';


%% figure output & naming

% labels used only for figure file names/folders
modelName     = 'Model2';
regressorName = 'Health';

% Folder for this regressor's figures
figureFolder = fullfile( ...
    'C:\Users\gulsu\Documents\MATLAB\Thesis\convmodel\convmodel\foi_4_30_buttonLR_signedHealthScore', ...
    'Figures', ...
    modelName, ...
    regressorName);

if ~exist(figureFolder,'dir')
    mkdir(figureFolder)
end



%% 1. LOAD ONE CLUSTER-PERMUTATION RESULT

%%%%%%% model 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% cd("C:\Users\gulsu\Documents\MATLAB\Thesis\convmodel\convmodel\foi_4_30_buttonLR_signedHealthScore\Statistics\cluster_post_vs_baseline_4")
% 
% modelFolder = ...
%    'C:\Users\gulsu\Documents\MATLAB\Thesis\convmodel\convmodel\foi_4_30_buttonLR_signedHealthScore\DataModel1\SPM_tf';

%%%%%%% model 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cd("C:\Users\gulsu\Documents\MATLAB\Thesis\convmodel\convmodel\foi_4_30_buttonLR_signedHealthScore\Statistics\cluster_post_vs_baseline_recent_4")

modelFolder = ...
  'C:\Users\gulsu\Documents\MATLAB\Thesis\convmodel\convmodel\foi_4_30_buttonLR_signedHealthScore\Data\SPM_tf';



%% Load stat file %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make sure to check comparison as well writing the name of the stats
% file!!!!

if strcmp(comparison,'vs_zero')

    load('stat3D_signed_within_zero_ButtonOnsetRight.mat')

elseif strcmp(comparison,'post_vs_baseline')

    load('stat3D_signed_within_Health.mat')

end

% stat{1} = Theta
% stat{2} = Alpha/Beta
%
% stat{2}
%   bin 1 = Alpha
%   bin 2 = Beta



%% 2. CHOOSE THE CLUSTER TO INSPECT

p_threshold = 0.050; % decide if significant or exploratory cluster!! but in general can keep 0.05 to see them all

cluster_direction = 'positive';   % 'positive' or 'negative'
cluster_number = 1;

% common identifier used only for figure file names
figurePrefix = sprintf('%s_%s_%s_%s_cluster%d', ...
    modelName, ...
    regressorName, ...
    comparison, ...
    cluster_direction, ...
    cluster_number);


if strcmp(cluster_direction,'negative')

    cluster_field = 'negclusters';
    label_field   = 'negclusterslabelmat';

elseif strcmp(cluster_direction,'positive')

    cluster_field = 'posclusters';
    label_field   = 'posclusterslabelmat';

end


%% 3. THETA CLUSTER MEMBERSHIP
% comes from stat{1}


theta = stat{1};

theta_ch = [];
theta_found = false;

if isfield(theta,cluster_field) && ...
        ~isempty(theta.(cluster_field)) && ...
        cluster_number <= length(theta.(cluster_field))

    theta_p = theta.(cluster_field)(cluster_number).prob;

    if theta_p < p_threshold

        % channel x time membership for this cluster
        theta_mask = squeeze( ...
            theta.(label_field)(:,1,:) == cluster_number);

        % channels belonging to cluster for >5 time samples
        theta_ch = find(sum(theta_mask,2) > 5);

        if ~isempty(theta_ch)

            theta_found = true;

            fprintf('Included theta channels:\n')
            disp(theta.label(theta_ch))

            figure
            imagesc(theta.time, ...
                1:length(theta.label), ...
                theta_mask)

            axis xy
            xlabel('Time (s)')
            ylabel('Channel')

            exportgraphics(gcf, ...
                fullfile(figureFolder, ...
                [figurePrefix '_Theta_ClusterMembership.png']), ...
                'Resolution',300);

        end
    end
end



%% 4. ALPHA/BETA CLUSTER MEMBERSHIP
% stat{2}


alphabeta = stat{2};

alpha_ch = [];
beta_ch  = [];

alpha_found = false;
beta_found  = false;

if isfield(alphabeta,cluster_field) && ...
        ~isempty(alphabeta.(cluster_field)) && ...
        cluster_number <= length(alphabeta.(cluster_field))

    alphabeta_p = ...
        alphabeta.(cluster_field)(cluster_number).prob;

    if alphabeta_p < p_threshold

        
        %% Alpha membership (stat bin 1)
     
        alpha_mask = squeeze( ...
            alphabeta.(label_field)(:,1,:) == cluster_number);

        alpha_ch = find(sum(alpha_mask,2) > 5);

        if ~isempty(alpha_ch)

            alpha_found = true;

            fprintf('Included alpha channels:\n')
            disp(alphabeta.label(alpha_ch))

            figure
            imagesc(alphabeta.time, ...
                1:length(alphabeta.label), ...
                alpha_mask)

            axis xy
            xlabel('Time (s)')
            ylabel('Channel')

            exportgraphics(gcf, ...
                fullfile(figureFolder, ...
                [figurePrefix '_Alpha_ClusterMembership.png']), ...
                'Resolution',300);

        end


  
        %% Beta membership: bin 2
      
        beta_mask = squeeze( ...
            alphabeta.(label_field)(:,2,:) == cluster_number);

        beta_ch = find(sum(beta_mask,2) > 5);

        if ~isempty(beta_ch)

            beta_found = true;

            fprintf('Included beta channels:\n')
            disp(alphabeta.label(beta_ch))

            figure
            imagesc(alphabeta.time, ...
                1:length(alphabeta.label), ...
                beta_mask)

            axis xy
            xlabel('Time (s)')
            ylabel('Channel')

            exportgraphics(gcf, ...
                fullfile(figureFolder, ...
                [figurePrefix '_Beta_ClusterMembership.png']), ...
                'Resolution',300);

        end
    end
end


%% 5. ORIGINAL CONVOLUTION MODEL DATA

% Full sample:
%
% subjects = [1 2 3 5 7 9 10 12 13 14 15 ...
%             17 18 19 20 22 23 24 25 26 ...
%             27 28 29 31 32];

subjects = [1 2 3 7 9 10 12 13 14 15 ...
            17 18 19 20 22 23 24 25 26 ...
            27 28 29 31 32];

regIndex = 5;  % CHANGE THISSSS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% used only when comparison = 'post_vs_baseline'
%baselineWindow = [-0.8 -0.6]; % for button presses
baselineWindow = [-0.250, -0.050]; % for other regressors

z_threshold = 2.5;

theta_cluster_value = nan(length(subjects),1);
alpha_cluster_value = nan(length(subjects),1);
beta_cluster_value  = nan(length(subjects),1);

channel_labels = [];



%% 6. LOAD EACH PARTICIPANT AND CALCULATE CLUSTER VALUES

for i = 1:length(subjects)

    s = subjects(i);


  
    %% original convolution file

    % model 1
    % modelFile = fullfile(modelFolder, ...
    %     ['participant_' num2str(s)], ...
    %     ['conv_model_signed_atf_' ...
    %      num2str(s) ...
    %      '_game_spm_cont.mat']);

    % model 2
    %
    modelFile = fullfile(modelFolder, ...
        ['participant_' num2str(s)], ...
        ['conv_model_signed_currenthealth_atf_' ...
         num2str(s) ...
         '_game_spm_cont_signed_currenthealth.mat']);


    D = spm_eeg_load(modelFile);

    time = double(D.fttimelock.time);
    freq = double(D.fttimelock.freq);

    if i == 1
        channel_labels = D.chanlabels(:);
    end


    % channel x frequency x time
    x = double(squeeze(D.fttimelock.powspctrm(regIndex,:,:,:)));


   
    %% construct the same contrast used in perm test
   

    if strcmp(comparison,'post_vs_baseline')

        [~,base_start] = min(abs(time-baselineWindow(1)));

        [~,base_end] = min(abs(time-baselineWindow(2)));

        base_idx = base_start:base_end;

        baseline = mean(x(:,:,base_idx),3,'omitnan');

        % post-event response minus participant baseline
        x_use = x - baseline;


    elseif strcmp(comparison,'vs_zero')

        % response-versus-zero permutation test used:
        %
        % data = x
        % databas = 0; so x-0

        x_use = x;

    end

    all_use(:,:,:,i) = x_use;


    
    %% THETA
    
    if theta_found

        
        theta_target_freq = [4 6];

        theta_freq_idx = dsearchn(freq',theta_target_freq');

        % this is for TFR visualization
        theta_freq = freq >= 4 & freq <= 6;

        theta_subject(:,:,i) = squeeze(mean(x_use(theta_ch,theta_freq,:),1,'omitnan'));


        
        %% Participant-level cluster value
        

        theta_band = squeeze(mean(x_use(:,theta_freq_idx,:),2,'omitnan'));


        % match perm-test times to convolution times
        theta_time_idx = zeros(1,length(theta.time));

        for t = 1:length(theta.time)

            [~,theta_time_idx(t)] =min(abs(time-theta.time(t)));

        end


        theta_band_stat_time =theta_band(:,theta_time_idx);


        theta_band_cluster_ch = theta_band_stat_time(theta_ch,:);


        theta_cluster_mask =theta_mask(theta_ch,:);


        theta_cluster_value(i) = mean(theta_band_cluster_ch(theta_cluster_mask),'omitnan');

    end

    %% ALPHA
 

    if alpha_found

        alpha_target_freq = 8:2:12;

        alpha_freq_idx = dsearchn(freq',alpha_target_freq');

        % this is for TFR visualization
        alpha_freq = freq >= 8 & freq <= 12;

        alpha_subject(:,:,i) = squeeze(mean(x_use(alpha_ch,alpha_freq,:),1,'omitnan'));


        %% Participant-level cluster value

        alpha_band = squeeze(mean(x_use(:,alpha_freq_idx,:),2,'omitnan'));

        alpha_time_idx =zeros(1,length(alphabeta.time));

        for t = 1:length(alphabeta.time)

            [~,alpha_time_idx(t)] =min(abs(time-alphabeta.time(t)));

        end


        alpha_band_stat_time =alpha_band(:,alpha_time_idx);


        alpha_band_cluster_ch =alpha_band_stat_time(alpha_ch,:);


        alpha_cluster_mask =alpha_mask(alpha_ch,:);


        alpha_cluster_value(i) = mean(alpha_band_cluster_ch(alpha_cluster_mask),'omitnan');

    end


    %% BETA

    if beta_found

        beta_target_freq = 14:2:30;

        beta_freq_idx =dsearchn(freq',beta_target_freq');

        % this if for TFR visualization
        beta_freq = freq >= 14 & freq <= 30;

        beta_subject(:,:,i) = squeeze(mean(x_use(beta_ch,beta_freq,:),1,'omitnan'));


        %% Participant-level cluster value
     

        beta_band = squeeze(mean(x_use(:,beta_freq_idx,:),2,'omitnan'));


        beta_time_idx =zeros(1,length(alphabeta.time));

        for t = 1:length(alphabeta.time)

            [~,beta_time_idx(t)] =min(abs(time-alphabeta.time(t)));

        end


        beta_band_stat_time = beta_band(:,beta_time_idx);


        beta_band_cluster_ch =beta_band_stat_time(beta_ch,:);


        beta_cluster_mask =beta_mask(beta_ch,:);


        beta_cluster_value(i) = mean(beta_band_cluster_ch(beta_cluster_mask),'omitnan');

    end

end



%% axis label for comparison used now


if strcmp(comparison,'post_vs_baseline')

    powerLabel = 'Baseline-corrected power';

else

    powerLabel = 'Convolution response';

end


%% 7. average TRFs

if theta_found

    theta_mean = mean(theta_subject,3,'omitnan');

    figure
    imagesc(time,freq(theta_freq),theta_mean)

    axis xy
    colorbar
    xline(0,'k')

    xlabel('Time (s)')
    ylabel('Frequency (Hz)')

    exportgraphics(gcf,fullfile(figureFolder, [figurePrefix '_Theta_TFR.png']), 'Resolution',300);

end


if alpha_found

    alpha_mean = mean(alpha_subject,3,'omitnan');

    figure
    imagesc(time,freq(alpha_freq),alpha_mean)

    axis xy
    colorbar
    xline(0,'k')

    xlabel('Time (s)')
    ylabel('Frequency (Hz)')

    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_Alpha_TFR.png']), 'Resolution',300);

end


if beta_found

    beta_mean = mean(beta_subject,3,'omitnan');

    figure
    imagesc(time,freq(beta_freq),beta_mean)

    axis xy
    colorbar
    xline(0,'k')

    xlabel('Time (s)')
    ylabel('Frequency (Hz)')

    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_Beta_TFR.png']), 'Resolution',300);

end


%% 8. LINE PLOTS WITH SEM ACROSS PARTICIPANTS

if theta_found

    theta_timecourse_subject = squeeze(mean(theta_subject,1,'omitnan'));

    theta_timecourse_mean = mean(theta_timecourse_subject,2,'omitnan');

    theta_timecourse_sem = std(theta_timecourse_subject,0,2,'omitnan') ./ sqrt(size(theta_timecourse_subject,2));


    theta_cluster_time_idx = find(any(theta_mask(theta_ch,:),1));

    theta_time_window = [min(theta.time(theta_cluster_time_idx)) max(theta.time(theta_cluster_time_idx))];


    figure
    hold on


    fill([time fliplr(time)],[(theta_timecourse_mean + theta_timecourse_sem)' fliplr((theta_timecourse_mean - theta_timecourse_sem)')], ...
        thetaFill,'EdgeColor','none','FaceAlpha',0.4);


    hTheta = plot(time,theta_timecourse_mean,'Color',thetaColor,'LineWidth',2);


    xline(0,'k')
    yline(0,'k')


    yl = ylim;


    hThetaCluster = plot(theta_time_window,[yl(1) yl(1)] + 0.04*range(yl),'k-','LineWidth',6);


    xlabel('Time (s)')
    ylabel(powerLabel)


    legend([hTheta hThetaCluster], {'Theta','Cluster temporal extent'}, 'Location','best')


    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_Theta_TimeCourse.png']),'Resolution',300);

end


if alpha_found

    alpha_timecourse_subject = squeeze(mean(alpha_subject,1,'omitnan'));

    alpha_timecourse_mean = mean(alpha_timecourse_subject,2,'omitnan');

    alpha_timecourse_sem = std(alpha_timecourse_subject,0,2,'omitnan') ./ sqrt(size(alpha_timecourse_subject,2));


    alpha_cluster_time_idx = find(any(alpha_mask(alpha_ch,:),1));

    alpha_time_window = [min(alphabeta.time(alpha_cluster_time_idx)) max(alphabeta.time(alpha_cluster_time_idx))];


    figure
    hold on


    fill([time fliplr(time)], [(alpha_timecourse_mean + alpha_timecourse_sem)' fliplr((alpha_timecourse_mean - alpha_timecourse_sem)')], alphaFill, ...
        'EdgeColor','none','FaceAlpha',0.4);


    hAlpha = plot(time,alpha_timecourse_mean, 'Color',alphaColor, 'LineWidth',2);


    xline(0,'k')
    yline(0,'k')


    yl = ylim;


    hAlphaCluster = plot(alpha_time_window, [yl(1) yl(1)] + 0.04*range(yl), 'k-', 'LineWidth',6);


    xlabel('Time (s)')
    ylabel(powerLabel)


    legend([hAlpha hAlphaCluster],{'Alpha','Cluster temporal extent'},'Location','best')


    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_Alpha_TimeCourse.png']),'Resolution',300);

end


if beta_found

    beta_timecourse_subject = squeeze(mean(beta_subject,1,'omitnan'));

    beta_timecourse_mean = mean(beta_timecourse_subject,2,'omitnan');

    beta_timecourse_sem = std(beta_timecourse_subject,0,2,'omitnan') ./ sqrt(size(beta_timecourse_subject,2));


    beta_cluster_time_idx = find(any(beta_mask(beta_ch,:),1));

    beta_time_window = [min(alphabeta.time(beta_cluster_time_idx)) max(alphabeta.time(beta_cluster_time_idx))];


    figure
    hold on


    fill([time fliplr(time)], [(beta_timecourse_mean + beta_timecourse_sem)' fliplr((beta_timecourse_mean - beta_timecourse_sem)')], betaFill, ...
        'EdgeColor','none', 'FaceAlpha',0.4);


    hBeta = plot(time,beta_timecourse_mean,'Color',betaColor, 'LineWidth',2);


    xline(0,'k')
    yline(0,'k')


    yl = ylim;


    hBetaCluster = plot(beta_time_window, [yl(1) yl(1)] + 0.04*range(yl), 'k-', 'LineWidth',6);


    xlabel('Time (s)')
    ylabel(powerLabel)


    legend([hBeta hBetaCluster], {'Beta','Cluster temporal extent'},'Location','best')


    exportgraphics(gcf, fullfile(figureFolder,[figurePrefix '_Beta_TimeCourse.png']), 'Resolution',300);

end


%% 9. COMBINED ALPHA and BETA TFR

if alpha_found && beta_found

    alphabeta_mean = [alpha_mean; beta_mean];

    alphabeta_freq = [freq(alpha_freq) freq(beta_freq)];


    figure
    imagesc(time,alphabeta_freq,alphabeta_mean)


    axis xy
    colorbar
    xline(0,'k')


    xlabel('Time (s)')
    ylabel('Frequency (Hz)')


    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_AlphaBeta_TFR.png']), 'Resolution',300);

end



%% 10. COMBINED ALPHA and BETA LINE PLOT WITH SEM


if alpha_found && beta_found

    figure
    hold on


    fill([time fliplr(time)], [(alpha_timecourse_mean + alpha_timecourse_sem)' fliplr((alpha_timecourse_mean - alpha_timecourse_sem)')], alphaFill, ...
        'EdgeColor','none', 'FaceAlpha',0.35);


    fill([time fliplr(time)], [(beta_timecourse_mean + beta_timecourse_sem)' fliplr((beta_timecourse_mean - beta_timecourse_sem)')], betaFill, ...
        'EdgeColor','none', 'FaceAlpha',0.25);


    hAlpha = plot(time,alpha_timecourse_mean,'Color',alphaColor,'LineWidth',2);


    hBeta = plot(time,beta_timecourse_mean,'Color',betaColor,'LineWidth',2);


    xline(0,'k')
    yline(0,'k')


    yl = ylim;


    hAlphaCluster = plot(alpha_time_window, [yl(1) yl(1)] + 0.04*range(yl), '-','Color',alphaColor, 'LineWidth',6);


    hBetaCluster = plot(beta_time_window, [yl(1) yl(1)] + 0.09*range(yl), '-', 'Color',betaColor, 'LineWidth',6);


    xlabel('Time (s)')
    ylabel(powerLabel)


    legend([hAlpha hBeta hAlphaCluster hBetaCluster],{'Alpha','Beta', 'Alpha cluster', 'Beta cluster'}, ...
        'Location','best')


    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_AlphaBeta_TimeCourse.png']),'Resolution',300);

end


%% 11. CREATE FIELDTRIP TFR STRUCTURE FOR TOPOGRAPHY

% grand-average of the actual quantity used for this comparison:
%
% post_vs_baseline -- baseline-corrected response
% vs_zero          -- original convolution response

grand_use = mean(all_use,4,'omitnan');


topoTFR = [];

topoTFR.label = channel_labels;
topoTFR.freq = freq;
topoTFR.time = time;

topoTFR.powspctrm = grand_use;

topoTFR.dimord = 'chan_freq_time';


fieldtripRoot = fileparts(which('ft_defaults'));

layoutFile = fullfile(fieldtripRoot, 'template', 'layout', 'biosemi64.lay');



%% electrode layout
% I will manually highlight the included channels later


cfg_lay = [];
cfg_lay.layout = layoutFile;

lay = ft_prepare_layout(cfg_lay);


%% 12. THETA EFFECT TOPOGRAPHY

if theta_found

    theta_cluster_time_idx = find(any(theta_mask(theta_ch,:),1));

    theta_time_window = [ min(theta.time(theta_cluster_time_idx)) max(theta.time(theta_cluster_time_idx))];


    cfg = [];

    cfg.layout = layoutFile;
    cfg.ylim = [4 6];
    cfg.xlim = theta_time_window;

    cfg.zlim = 'maxabs';
    cfg.colorbar = 'yes';

    cfg.marker = 'off';
    cfg.comment = 'no';
    cfg.interactive = 'no';


    figure
    ft_topoplotTFR(cfg,topoTFR)
    hold on

    % manually highligthing
    %% Make all EEG channels black

    for ch = 1:length(channel_labels)

        idx = find(strcmp(lay.label, channel_labels{ch}));

        if ~isempty(idx)

            plot(lay.pos(idx,1), lay.pos(idx,2),'k.','MarkerSize',12)

        end
    end


    %% Included theta channels = yellow

    for ch = theta_ch'

        idx = find(strcmp(lay.label, theta.label{ch}));

        if ~isempty(idx)

            plot(lay.pos(idx,1),lay.pos(idx,2),'yo','MarkerFaceColor','y','MarkerEdgeColor','k','MarkerSize',8)

        end
    end


    title('Theta Effect Topography')


    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_Theta_EffectTopography.png']),'Resolution',300);

end


%% 13. THETA STATISTICAL CLUSTER TOPOGRAPHY

if theta_found

    theta_stat = squeeze(theta.stat(:,1,:));


    theta_stat(~theta_mask) = NaN;


    theta_stat_topo = mean(theta_stat,2,'omitnan');


    statTopo = [];

    statTopo.label = theta.label;
    statTopo.avg = theta_stat_topo;
    statTopo.time = 0;
    statTopo.dimord = 'chan_time';


    cfg = [];

    cfg.layout = layoutFile;
    cfg.parameter = 'avg';
    cfg.zlim = 'maxabs';
    cfg.colorbar = 'yes';
    cfg.marker = 'off';
    cfg.comment = 'no';
    cfg.interactive = 'no';


    figure
    ft_topoplotER(cfg,statTopo)
    hold on


    for ch = 1:length(theta.label)

        idx = find(strcmp(lay.label, theta.label{ch}));

        if ~isempty(idx)

            plot(lay.pos(idx,1), lay.pos(idx,2),'k.','MarkerSize',12)

        end
    end


    for ch = theta_ch'

        idx = find(strcmp(lay.label, theta.label{ch}));

        if ~isempty(idx)

            plot(lay.pos(idx,1),lay.pos(idx,2),'yo','MarkerFaceColor','y','MarkerEdgeColor','k','MarkerSize',8)

        end
    end


    title('Theta Statistical Cluster Topography')


    exportgraphics(gcf,fullfile(figureFolder,[figurePrefix '_Theta_StatisticalTopography.png']),'Resolution',300);

end


%% 14. ALPHA EFFECT TOPOGRAPHY

if alpha_found

    alpha_cluster_time_idx = find(any(alpha_mask(alpha_ch,:),1));

    alpha_time_window = [min(alphabeta.time(alpha_cluster_time_idx)) max(alphabeta.time(alpha_cluster_time_idx))];


    cfg = [];

    cfg.layout = layoutFile;
    cfg.ylim = [8 12];
    cfg.xlim = alpha_time_window;

    cfg.zlim = 'maxabs';
    cfg.colorbar = 'yes';
    cfg.marker = 'off';
    cfg.comment = 'no';
    cfg.interactive = 'no';


    figure
    ft_topoplotTFR(cfg,topoTFR)
    hold on


    for ch = 1:length(channel_labels)

        idx = find(strcmp(lay.label, channel_labels{ch}));

        if ~isempty(idx)

            plot(lay.pos(idx,1), lay.pos(idx,2), 'k.', 'MarkerSize',12)

        end
    end


    for ch = alpha_ch'

        idx = find(strcmp(lay.label,alphabeta.label{ch}));

        if ~isempty(idx)

            plot(lay.pos(idx,1),lay.pos(idx,2),'yo','MarkerFaceColor','y','MarkerEdgeColor','k','MarkerSize',8)

        end
    end


    title('Alpha Effect Topography')


    exportgraphics(gcf,fullfile(figureFolder, [figurePrefix '_Alpha_EffectTopography.png']),'Resolution',300);

end



%% 15. ALPHA STATISTICAL CLUSTER TOPOGRAPHY

if alpha_found

    alpha_stat = squeeze(alphabeta.stat(:,1,:));


    alpha_stat(~alpha_mask) = NaN;


    alpha_stat_topo = mean(alpha_stat,2,'omitnan');


    statTopo = [];

    statTopo.label = alphabeta.label;
    statTopo.avg = alpha_stat_topo;
    statTopo.time = 0;
    statTopo.dimord = 'chan_time';


    cfg = [];

    cfg.layout = layoutFile;
    cfg.parameter = 'avg';
    cfg.zlim = 'maxabs';
    cfg.colorbar = 'yes';
    cfg.marker = 'off';
    cfg.comment = 'no';
    cfg.interactive = 'no';


    figure
    ft_topoplotER(cfg,statTopo)
    hold on


    for ch = 1:length(alphabeta.label)

        idx = find(strcmp(lay.label, alphabeta.label{ch}));

        if ~isempty(idx)

            plot(lay.pos(idx,1), lay.pos(idx,2), 'k.', 'MarkerSize',12)

        end
    end


    for ch = alpha_ch'

        idx = find(strcmp(lay.label, alphabeta.label{ch}));

        if ~isempty(idx)

            plot(lay.pos(idx,1),lay.pos(idx,2),'yo','MarkerFaceColor','y','MarkerEdgeColor','k','MarkerSize',8)

        end
    end


    title('Alpha Statistical Cluster Topography')


    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_Alpha_StatisticalTopography.png']), 'Resolution',300);

end


%% ============================================================
%% 16. BETA EFFECT TOPOGRAPHY
%% ============================================================

if beta_found

    beta_cluster_time_idx = find(any(beta_mask(beta_ch,:),1));

    beta_time_window = [min(alphabeta.time(beta_cluster_time_idx)) max(alphabeta.time(beta_cluster_time_idx))];


    cfg = [];

    cfg.layout = layoutFile;
    cfg.ylim = [14 30];
    cfg.xlim = beta_time_window;

    cfg.zlim = 'maxabs';
    cfg.colorbar = 'yes';
    cfg.marker = 'off';
    cfg.comment = 'no';
    cfg.interactive = 'no';


    figure
    ft_topoplotTFR(cfg,topoTFR)
    hold on


    for ch = 1:length(channel_labels)

        idx = find(strcmp(lay.label, channel_labels{ch}));

        if ~isempty(idx)

            plot(lay.pos(idx,1), lay.pos(idx,2), 'k.', 'MarkerSize',12)

        end
    end


    for ch = beta_ch'

        idx = find(strcmp(lay.label, alphabeta.label{ch}));

        if ~isempty(idx)

            plot(lay.pos(idx,1),lay.pos(idx,2),'yo','MarkerFaceColor','y','MarkerEdgeColor','k','MarkerSize',8)

        end
    end


    title('Beta Effect Topography')


    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_Beta_EffectTopography.png']), 'Resolution',300);

end



%% 17. BETA STATISTICAL CLUSTER TOPOGRAPHY
if beta_found

    beta_stat = squeeze(alphabeta.stat(:,2,:));


    beta_stat(~beta_mask) = NaN;


    beta_stat_topo = mean(beta_stat,2,'omitnan');


    statTopo = [];

    statTopo.label = alphabeta.label;
    statTopo.avg = beta_stat_topo;
    statTopo.time = 0;
    statTopo.dimord = 'chan_time';


    cfg = [];

    cfg.layout = layoutFile;
    cfg.parameter = 'avg';
    cfg.zlim = 'maxabs';
    cfg.colorbar = 'yes';
    cfg.marker = 'off';
    cfg.comment = 'no';
    cfg.interactive = 'no';


    figure
    ft_topoplotER(cfg,statTopo)
    hold on


    for ch = 1:length(alphabeta.label)

        idx = find(strcmp(lay.label, alphabeta.label{ch}));

        if ~isempty(idx)

            plot(lay.pos(idx,1), lay.pos(idx,2), 'k.', 'MarkerSize',12)

        end
    end


    for ch = beta_ch'

        idx = find(strcmp(lay.label, alphabeta.label{ch}));

        if ~isempty(idx)

            plot(lay.pos(idx,1),lay.pos(idx,2),'yo','MarkerFaceColor','y','MarkerEdgeColor','k','MarkerSize',8)

        end
    end


    title('Beta Statistical Cluster Topography')


    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_Beta_StatisticalTopography.png']), 'Resolution',300);

end


%% 18. PARTICIPANT Z-SCORE CHECK: THETA

if theta_found

    theta_mean_value = mean(theta_cluster_value,'omitnan');

    theta_sd_value = std(theta_cluster_value,0,'omitnan');


    theta_z = (theta_cluster_value-theta_mean_value) ./ ...
        theta_sd_value;


    theta_outliers = find(abs(theta_z) > z_threshold);


    theta_upper = theta_mean_value + z_threshold*theta_sd_value;


    theta_lower = theta_mean_value - z_threshold*theta_sd_value;


    if isempty(theta_outliers)

    else

        for j = 1:length(theta_outliers)

            idx = theta_outliers(j);

            fprintf('P%d: value = %.4f, z = %.2f\n', ...
                subjects(idx), theta_cluster_value(idx), theta_z(idx))

        end
    end


    figure
    hold on


    x_pos = 1:length(subjects);


    scatter(x_pos, theta_cluster_value, 45, 'filled')


    if ~isempty(theta_outliers)

        scatter(x_pos(theta_outliers), theta_cluster_value(theta_outliers), 120, 'o', 'LineWidth',2)

    end


    for i = 1:length(subjects)

        text(x_pos(i)+0.1, theta_cluster_value(i), sprintf('P%d',subjects(i)), 'FontSize',8)

    end


    for j = 1:length(theta_outliers)

        idx = theta_outliers(j);

        text(x_pos(idx)+0.1, theta_cluster_value(idx), sprintf('P%d\nz=%.2f', subjects(idx),theta_z(idx)), 'FontWeight','bold')

    end


    yline(0,'k')


    yline(theta_mean_value,'--k','Group mean')


    yline(theta_upper, ':r', 'z = +2.5','LineWidth',1.5)


    yline(theta_lower, ':r', 'z = -2.5', 'LineWidth',1.5)


    xlabel('Participant')
    ylabel('Mean cluster response')


    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_Theta_ParticipantValues.png']), 'Resolution',300);

end



%% 19. PARTICIPANT Z-SCORE CHECK: ALPHA

if alpha_found

    alpha_mean_value = mean(alpha_cluster_value,'omitnan');

    alpha_sd_value = std(alpha_cluster_value,0,'omitnan');


    alpha_z = (alpha_cluster_value-alpha_mean_value) ./ alpha_sd_value;


    alpha_outliers = find(abs(alpha_z) > z_threshold);


    alpha_upper = alpha_mean_value + z_threshold*alpha_sd_value;


    alpha_lower = alpha_mean_value - z_threshold*alpha_sd_value;


    if isempty(alpha_outliers)

    else

        for j = 1:length(alpha_outliers)

            idx = alpha_outliers(j);

            fprintf('P%d: value = %.4f, z = %.2f\n', ...
                subjects(idx), alpha_cluster_value(idx), alpha_z(idx))

        end
    end


    figure
    hold on


    x_pos = 1:length(subjects);


    scatter(x_pos, alpha_cluster_value, 45, 'filled')


    if ~isempty(alpha_outliers)

        scatter(x_pos(alpha_outliers), alpha_cluster_value(alpha_outliers), 120, 'o', 'LineWidth',2)

    end


    for i = 1:length(subjects)

        text(x_pos(i)+0.1, alpha_cluster_value(i), sprintf('P%d',subjects(i)), 'FontSize',8)

    end


    for j = 1:length(alpha_outliers)

        idx = alpha_outliers(j);

        text(x_pos(idx)+0.1, alpha_cluster_value(idx), sprintf('P%d\nz=%.2f', subjects(idx),alpha_z(idx)), 'FontWeight','bold')

    end


    yline(0,'k')


    yline(alpha_mean_value, '--k', 'Group mean')


    yline(alpha_upper, ':r', 'z = +2.5', 'LineWidth',1.5)


    yline(alpha_lower, ':r', 'z = -2.5', 'LineWidth',1.5)


    xlabel('Participant')
    ylabel('Mean cluster response')


    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_Alpha_ParticipantValues.png']), 'Resolution',300);

end


%% 20. PARTICIPANT Z-SCORE CHECK: BETA

if beta_found

    beta_mean_value = mean(beta_cluster_value,'omitnan');

    beta_sd_value = std(beta_cluster_value,0,'omitnan');


    beta_z = (beta_cluster_value-beta_mean_value) ./ beta_sd_value;


    beta_outliers = find(abs(beta_z) > z_threshold);


    beta_upper = beta_mean_value + z_threshold*beta_sd_value;


    beta_lower = beta_mean_value - z_threshold*beta_sd_value;


    if isempty(beta_outliers)

    else

        for j = 1:length(beta_outliers)

            idx = beta_outliers(j);

            fprintf('P%d: value = %.4f, z = %.2f\n', ...
                subjects(idx), beta_cluster_value(idx), beta_z(idx))

        end
    end


    figure
    hold on


    x_pos = 1:length(subjects);


    scatter(x_pos, beta_cluster_value, 45, 'filled')


    if ~isempty(beta_outliers)

        scatter(x_pos(beta_outliers), beta_cluster_value(beta_outliers), 120, 'o', 'LineWidth',2)

    end


    for i = 1:length(subjects)

        text(x_pos(i)+0.1, beta_cluster_value(i), sprintf('P%d',subjects(i)), 'FontSize',8)

    end


    for j = 1:length(beta_outliers)

        idx = beta_outliers(j);

        text(x_pos(idx)+0.1, beta_cluster_value(idx), sprintf('P%d\nz=%.2f', subjects(idx),beta_z(idx)), 'FontWeight','bold')

    end


    yline(0,'k')


    yline(beta_mean_value,'--k', 'Group mean')


    yline(beta_upper, ':r', 'z = +2.5', 'LineWidth',1.5)


    yline(beta_lower, ':r', 'z = -2.5', 'LineWidth',1.5)


    xlabel('Participant')
    ylabel('Mean cluster response')


    exportgraphics(gcf, fullfile(figureFolder, [figurePrefix '_Beta_ParticipantValues.png']), 'Resolution',300);

end


%% 21. if no clusters found

if ~theta_found && ~alpha_found && ~beta_found

    fprintf('\nNo cluster/band passed\n')

end