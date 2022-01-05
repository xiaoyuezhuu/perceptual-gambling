classdef PerceptGam < ProtoObj
    
    % The Perceptual Gambling Task
    % "Be right or be good"
    % Written by Xiaoyue Zhu, Dec/2018 - Jul/2019
    
    properties
        ITI
        Sounds
        start_port
        reward_port
        correct_port
        incorrect_port
        better_side
        trial_num = 0
        correct_reward
        pitch_high % 1 if higher
        this_sound % the actual sound
        correct_choice % 1 if correct
        ft %fixation time for each trial
        init_time
        resp_time
        fixation_attempts
        one_fixation
        n_wrong_pokes
        init_timeout
        choice_timeout
        timeout
        pitch_high_in_block
        trial_in_block = 0
        block_num = 0
        block_hit % for performance-based blocks
        log2_sound % track what sound is played in perceptual_cont
        flash % to flash or not
        log2_history %used for repeating on errors
        flash_timer
        block_length
        better_side_in_block
        flash_in_block % for hedging_multi
        audi % if the value component is signalled via sound or visual stimulus
        timeout_history
        flash_level = 0
        flash_level_in_block
    end
    
    methods
        
        function [x, y] = init(obj, varargin)
            %             // [x,y] = init@ProtoObj(obj, varargin);
            %             // SF = 48000;
            %             // obj.Sounds = SoundServerLauncher();
            %             // obj.Sounds.getSF(SF);
            %             // obj.Sounds.setLatency('high');
            %
            %             // obj.Sounds.load('GoSound',[GenerateSineWave(SF, 8, .1) .* GenerateSineWave(SF, 2000, .1) 0*GenerateSineWave(SF, 2000, .1)],'volume',0.15);
            %             // obj.Sounds.load('1kSound',GenerateSineWave(SF, 1000, 1),'volume',0.5);
            %             // obj.Sounds.load('4kSound',GenerateSineWave(SF, 4000, 1),'volume',0.5);
            %             // obj.Sounds.load('ShortViolSound',rand(1,SF*.1)*2-1,'volume',0.3);
            %            // obj.Sounds.sync();
            
            [x,y] = init@ProtoObj(obj, varargin);
            SF = PsychSound.SF;
            
            obj.Sounds.GoSound = PsychSound([GenerateSineWave(SF, 8, .1) .* GenerateSineWave(SF, 2000, .1) 0*GenerateSineWave(SF, 2000, .1)]);
            obj.Sounds.fourkSound = PsychSound(GenerateSineWave(SF, 4000, 0.5));
            obj.Sounds.sixteenkSound = PsychSound(GenerateSineWave(SF, 16000, 0.5));
            obj.Sounds.contSound = PsychSound(GenerateSineWave(SF, 4000, 0.5));%just a place holder, its wave will be changed
            
            obj.Sounds.ShortViolSound = PsychSound(rand(1,SF*.1)*2 - 1);
            
            obj.Sounds.ShortViolSound.volume = 0.3;
            obj.Sounds.GoSound.volume = 0.3;
            obj.Sounds.fourkSound.volume = 0.6;
            obj.Sounds.sixteenkSound.volume = 0.6;
            obj.Sounds.contSound.volume = 0.6;
            
            
            
            
        end
        
        function useSettings(obj, settings_name, expg_data, subj_data)
            
            if isempty(settings_name)
                settings_name = 'hedging';
            end
            
            switch settings_name
                
                case 'fix_perceptual'
                    % Fixation with two end sounds in blocks
                    obj.settings.name = 'fix_perceptual';
                    obj.settings.ITI_min = 3;
                    obj.settings.ITI_max = 10;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 0.1;
                    obj.settings.correct_reward = 32;
                    
                    obj.settings.block_length = [5,10,15,20];
                    
                    % Here marks the beginning of training pipeline 1: sound first, flash later.
                case 'fix_perceptual_cont'
                    % Fixation with discrete sounds in blocks
                    obj.settings.name = 'fix_perceptual_cont';
                    obj.settings.ITI_min = 3;
                    obj.settings.ITI_max = 10;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 0.1;
                    obj.settings.correct_reward = 32;
                    
                    obj.settings.pitch_edge = 2;
                    obj.settings.block_length = [3,5,7,9,11];
                    
                case 'fix_perceptual_rcont'
                    % Fixation with random sounds
                    obj.settings.name = 'fix_perceptual_rcont';
                    obj.settings.ITI_min = 3;
                    obj.settings.ITI_max = 10;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 0.1;
                    obj.settings.correct_reward = 32;
                    
                    obj.settings.sigma_s = 1;
                    obj.settings.repeat_error = 1;
                    
                case 'perceptual_cont'
                    % Discrete sounds in blocks
                    obj.settings.name = 'perceptual_cont';
                    obj.settings.ITI_min = 3;
                    obj.settings.ITI_max = 10;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1;
                    obj.settings.correct_reward = 32;
                    
                    obj.settings.pitch_edge = 2; % how far away the sound range is from the 4k, 16k edge
                    % if pitch_edge >= 5, we use simply draw from a uniform distribution
                    obj.settings.block_length = [3,5,7,9,11];
                    
                case 'perceptual_rcont'
                    % Random sounds only
                    obj.settings.name = 'perceptual_rcont';
                    obj.settings.ITI_min = 3;
                    obj.settings.ITI_max = 10;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1;
                    obj.settings.correct_reward = 32;
                    
                    obj.settings.sigma_s = 1;
                    obj.settings.repeat_error = 1;
                    
                case 'hedging'
                    % Random sounds with flash in blocks of adjustable lengths
                    obj.settings.name = 'hedging';
                    obj.settings.ITI_min = 3;
                    obj.settings.ITI_max = 10;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1;
                    obj.settings.correct_reward = 20;
                    
                    obj.settings.rew_multi = 5; % reward multiplier
                    obj.settings.sigma_s = 0.5; % to control the p(s) distribution
                    obj.settings.oneside_prob = 0.4; % trials that will be left or right flashes
                    obj.settings.double_prob = 0; % trials that will be both flashes
                    obj.settings.block_length = [5,7,9,11];
                    obj.settings.flash_timer = 0;
                    
                    % flash levels indicate diff reward magnitudes
                    obj.settings.flash_level = 0; % 0 means this function is not active; one level means one more flash
                    obj.settings.multi_unit = 3; % this overrides rew_multi; rew_multi = flash_level * multi_unit;
                    obj.settings.flash_on_time = 0.1;
                    obj.settings.flash_off_time = 0.1;
                    
                    % constraints must be satisfied 
                    if obj.settings.flash_timer >= 0
                       assert((obj.settings.flash_level * (obj.settings.flash_on_time + obj.settings.flash_off_time) + obj.settings.flash_timer) <= obj.settings.ft_init);
                    else
                       assert((obj.settings.flash_level * (obj.settings.flash_on_time + obj.settings.flash_off_time)) <= obj.settings.ft_init);
                    end
                        
                    
                case 'hedging_rand'
                    % Random sounds; random flashes
                    obj.settings.name = 'hedging_rand';
                    obj.settings.ITI_min = 3;
                    obj.settings.ITI_max = 10;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1;
                    obj.settings.correct_reward = 32;
                    
                    obj.settings.rew_multi = 5; % reward multiplier
                    obj.settings.sigma_s = 1.5; % to control the p(s) distribution
                    obj.settings.oneside_prob = 0.5; % trials that will be left or right flashes
                    obj.settings.double_prob = 0; % trials that will be both flashes
                    obj.settings.flash_timer = 0.3;
                    
                    
                    % Here marks the beginning of training pipeline 2: sound and flash at the same time.
                case 'perceptual_rends'
                    % Random two end sounds
                    obj.settings.name = 'perceptual_rends';
                    obj.settings.ITI_min = 3;
                    obj.settings.ITI_max = 10;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1;
                    obj.settings.correct_reward = 32;
                    
                    obj.settings.repeat_error = 1;
                    
                case 'hedging_rends'
                    % Random two end sounds; flash in blocks of adjustable lengths
                    obj.settings.name = 'hedging_rends';
                    obj.settings.ITI_min = 3;
                    obj.settings.ITI_max = 10;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1;
                    obj.settings.correct_reward = 32;
                    
                    obj.settings.rew_multi = 5; % reward multiplier
                    obj.settings.oneside_prob = 0.5; % trials that will be left or right flashes
                    obj.settings.double_prob = 0; % trials that will be both flashes
                    obj.settings.block_length = [3,5,7];
                    obj.settings.flash_timer = 0.5;
                    
                    
                case 'hedging_r2g'
                    % Random sounds centered at two ends as 2 trucated Gaussians; flash in blocks
                    obj.settings.name = 'hedging_r2g';
                    obj.settings.ITI_min = 3;
                    obj.settings.ITI_max = 10;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1;
                    obj.settings.correct_reward = 32;
                    
                    obj.settings.rew_multi = 5; % reward multiplier
                    obj.settings.oneside_prob = 0.5; % trials that will be left or right flashes
                    obj.settings.double_prob = 0; % trials that will be both flashes
                    obj.settings.block_length = [3,5,7];
                    obj.settings.sigma_low = 0.1; % gaussian sd for 2
                    obj.settings.sigma_high = 0.1; % gaussian sd for 4
                    obj.settings.flash_timer = 0.5;
                    
                    
                    % The following are the control tasks
                case 'hedging_multi'
                    % Random sounds, random flash/audi (same side) in blocks
                    obj.settings.name = 'hedging_multi';
                    obj.settings.ITI_min = 3;
                    obj.settings.ITI_max = 10;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1;
                    obj.settings.correct_reward = 32;
                    
                    obj.settings.rew_multi = 5; % reward multiplier
                    obj.settings.sigma_s = 1; % to control the p(s) distribution
                    obj.settings.oneside_prob = 0.6; % trials that will be left or right flashes
                    obj.settings.double_prob = 0; % trials that will be both flashes
                    obj.settings.flash_prob = 0.7; % proportion of trials using flash
                    obj.settings.block_length = [5,7,9,11];
                    obj.settings.flash_timer = 0.5;
                    
                    
                case 'just_flash'
                    % Control task for visual impairments
                    % Animal just has to go to the side where the flash is
                    obj.settings.name = 'just_flash';
                    obj.settings.ITI_min = 3;
                    obj.settings.ITI_max = 10;
                    obj.settings.start_timeout = 30;
                    obj.settings.choice_timeout = 30;
                    obj.settings.reward_timeout = 30;
                    obj.settings.ft_init = 1;
                    obj.settings.correct_reward = 32;
                    obj.settings.lsp = 0.5; % left side prob of flashing
                    obj.settings.rsp = 0.5; % right side prob of flashing
                    
                    
                otherwise
                    obj.settings = [];
            end
            
            obj.settings = utils.apply_struct(obj.settings, subj_data);
            
        end
        
        function prepareNextTrial(obj)
            
            %First trial ITI = 1s
            if obj.n_done_trials == 0
                obj.ITI = 1;
            else
                obj.ITI = rand*(obj.settings.ITI_max-obj.settings.ITI_min)+obj.settings.ITI_min;
            end
            
            obj.trial_num = obj.trial_num + 1;
            obj.trial_in_block = obj.trial_in_block + 1;
            
            obj.start_port = 'MidC';
            obj.reward_port = 'BotC';
            obj.correct_reward = obj.settings.correct_reward;
            
            % Set up fixation time
            if contains(obj.settings.name, 'fix')
                if obj.n_done_trials == 0
                    obj.ft = obj.settings.ft_init;
                else
                    %If the last trial is a one-fixation trial, we increase ft in this trial
                    %by 5ms; if not, we decrease ft by 5ms
                    obj.ft = utils.adaptive_step(obj.ft, obj.one_fixation(end),...
                        'hit_step',0.005,'stableperf',0.5,'mx',1,'mn',obj.settings.ft_init);
                end
            else
                if obj.trial_num <= 10
                    obj.ft = obj.trial_num * 0.1 + 0.001;
                elseif obj.trial_num > 10
                    obj.ft = obj.settings.ft_init;
                else
                    obj.ft = obj.settings.ft_init;
                end
            end
            
            
            % Choose the sound and assign the correct port for this trial
            if contains(obj.settings.name,'perceptual')
                
                if ~contains(obj.settings.name, '_r') % if using block structure
                    %Performance-based block
                    if obj.trial_num == 1
                        obj.block_length = datasample(obj.settings.block_length,1);
                        obj.block_num = obj.block_num + 1;
                        obj.pitch_high_in_block = mod(obj.block_num,2);
                        obj.pitch_high = obj.pitch_high_in_block;
                    end
                    
                    if obj.n_done_trials~=0 && ~obj.hit_history(end) % if the last was error or timeout
                        obj.pitch_high = obj.pitch_high_in_block; % Extend this block until it gets it
                    elseif obj.trial_in_block > obj.block_length
                        if nanmean(obj.block_hit)> 0.7 || obj.trial_in_block > obj.block_length*2
                            obj.block_length = datasample(obj.settings.block_length,1);
                            obj.trial_in_block = 1;
                            obj.block_num = obj.block_num + 1;
                            obj.pitch_high_in_block = mod(obj.block_num,2);
                        end
                        obj.pitch_high = obj.pitch_high_in_block;
                    else obj.pitch_high = obj.pitch_high_in_block;
                    end
                    
                    
                elseif contains(obj.settings.name, '_r') % if no block structure
                    SF = PsychSound.SF;
                    if obj.settings.repeat_error == 1 && obj.n_done_trials~=0 && ~obj.hit_history(end) % if the last was error or timeout
                        obj.log2_sound = obj.log2_history(end);
                    elseif contains(obj.settings.name, 'rcont')  % Randomised trials
                        obj.log2_sound = normrnd(3,obj.settings.sigma_s);
                        while obj.log2_sound < 2 || obj.log2_sound > 4
                            obj.log2_sound = normrnd(3,obj.settings.sigma_s);
                        end
                    elseif contains(obj.settings.name, 'rends') % just two end sounds
                        obj.log2_sound = utils.pick_with_prob([2,4],[0.5,0.5]);
                    end
                    obj.Sounds.contSound.wave = GenerateSineWave(SF, 1000*(2^obj.log2_sound), 0.5);
                    obj.this_sound = obj.Sounds.contSound;
                    if obj.log2_sound >= 3
                        obj.pitch_high = 1;
                    elseif obj.log2_sound < 3
                        obj.pitch_high = 0;
                    end
                    obj.better_side = 9;
                end
                
                %Select a sound based on pitch
                if endsWith(obj.settings.name,'perceptual')
                    if obj.pitch_high % if higher pitch
                        obj.this_sound = obj.Sounds.sixteenkSound;
                        obj.log2_sound = 4;
                    else obj.this_sound = obj.Sounds.fourkSound;
                        obj.log2_sound = 2;
                    end
                    obj.better_side = 9;
                    
                elseif contains(obj.settings.name,'perceptual_cont')
                    if obj.n_done_trials~=0 && ~obj.hit_history(end) % if the last was error or timeout
                        obj.log2_sound = obj.log2_history(end); % Keep playing this sound
                    else
                        SF = PsychSound.SF;
                        pe = obj.settings.pitch_edge;
                        if pe < 5
                            all_sounds = 2:0.25:4;
                            lower_range = all_sounds(1:pe);
                            higher_range = all_sounds(end-(pe-1):end);
                            if obj.pitch_high
                                obj.log2_sound = datasample(higher_range,1);
                                obj.Sounds.contSound.wave = GenerateSineWave(SF, 1000*(2^obj.log2_sound), 0.5);
                                obj.this_sound = obj.Sounds.contSound;
                            else obj.log2_sound = datasample(lower_range,1);
                                obj.Sounds.contSound.wave = GenerateSineWave(SF, 1000*(2^obj.log2_sound), 0.5);
                                obj.this_sound = obj.Sounds.contSound;
                            end
                            
                        else
                            if obj.pitch_high
                                obj.log2_sound = rand + 3;
                                obj.Sounds.contSound.wave = GenerateSineWave(SF, 1000*(2^obj.log2_sound), 0.5);
                                obj.this_sound = obj.Sounds.contSound;
                            else
                                obj.log2_sound = rand + 2;
                                obj.Sounds.contSound.wave = GenerateSineWave(SF, 1000*(2^obj.log2_sound), 0.5);
                                obj.this_sound = obj.Sounds.contSound;
                            end
                        end
                        obj.better_side = 9;
                    end
                end
                
                
            elseif contains(obj.settings.name,'hedging')
                
                % set default values
                obj.audi = 0;
                obj.flash_level = obj.settings.flash_level; 
                obj.flash_timer = obj.settings.flash_timer;
                % Some abbreviations
                osp = obj.settings.oneside_prob;
                dsp = obj.settings.double_prob;
                np = 1 - osp - dsp;
                % Choose sounds
                if strcmpi(obj.settings.name,'hedging_rends')
                    obj.log2_sound = utils.pick_with_prob([2,4],[0.5,0.5]);
                elseif strcmpi(obj.settings.name,'hedging_r2g')
                    g_center = utils.pick_with_prob([2,4],[0.5,0.5]);
                    if g_center == 2
                        obj.log2_sound = normrnd(g_center,obj.settings.sigma_low);
                        while obj.log2_sound < 2 || obj.log2_sound > 4
                            obj.log2_sound = normrnd(g_center,obj.settings.sigma_low);
                        end
                    elseif g_center == 4
                        obj.log2_sound = normrnd(g_center,obj.settings.sigma_high);
                        while obj.log2_sound < 2 || obj.log2_sound > 4
                            obj.log2_sound = normrnd(g_center,obj.settings.sigma_high);
                        end
                    end
                else
                    obj.log2_sound = normrnd(3,obj.settings.sigma_s);
                    while obj.log2_sound < 2 || obj.log2_sound > 4
                        obj.log2_sound = normrnd(3,obj.settings.sigma_s);
                    end
                end
                % Assign pitch_high
                if obj.log2_sound >= 3
                    obj.pitch_high = 1;
                elseif obj.log2_sound < 3
                    obj.pitch_high = 0;
                end
                % Assign log2_sound to the sound wave
                SF = PsychSound.SF;
                obj.Sounds.contSound.wave = GenerateSineWave(SF, 1000*(2^obj.log2_sound), 0.5);
                obj.this_sound = obj.Sounds.contSound;
                
                % Decide to flash or not and how to flash/audi
                if ~contains(obj.settings.name,'rand') % If in blocks
                    % If we are at trial one
                    if obj.trial_num == 1
                        obj.block_length = datasample(obj.settings.block_length,1);
                        obj.block_num = obj.block_num + 1;
                        obj.better_side_in_block = utils.pick_with_prob([0,1,2,9],[osp/2,osp/2,dsp,np]);
                        obj.better_side = obj.better_side_in_block;
                        obj.flash = obj.better_side ~= 9;
                        
                        % if there are levels in flash
                        if obj.settings.flash_level > 0
                            fl = 1:obj.settings.flash_level;
                            obj.flash_level_in_block = utils.pick_with_prob(fl, repmat(1/length(fl), 1, length(fl))); % chose each one with equal prob
                            obj.flash_level = obj.flash_level_in_block;
                        end
                        
                        % if uneven rewards and in hedging_multi
                        if strcmpi(obj.settings.name, 'hedging_multi') && obj.flash
                            obj.flash_in_block = rand <= obj.settings.flash_prob;
                            obj.flash = obj.flash_in_block;
                            obj.audi = 1 - obj.flash;
                        end
                    end
                    
                    % If we finish this block
                    if obj.trial_in_block > obj.block_length
                        obj.block_length = datasample(obj.settings.block_length,1);
                        obj.trial_in_block = 1;
                        obj.block_num = obj.block_num + 1;
                        obj.better_side_in_block = utils.pick_with_prob([0,1,2,9],[osp/2,osp/2,dsp,np]);
                        obj.better_side = obj.better_side_in_block;
                        obj.flash = obj.better_side ~= 9;
                        
                        % if there are levels in flash
                        if obj.settings.flash_level > 0
                            fl = 1:obj.settings.flash_level;
                            obj.flash_level_in_block = utils.pick_with_prob(fl, repmat(1/length(fl), 1, length(fl))); % chose each one with equal prob
                            obj.flash_level = obj.flash_level_in_block;
                        end
                        
                        % if uneven rewards and in hedging_multi
                        if strcmpi(obj.settings.name, 'hedging_multi') && obj.flash
                            obj.flash_in_block = rand <= obj.settings.flash_prob;
                            obj.flash = obj.flash_in_block;
                            obj.audi = 1 - obj.flash;
                        end
                        
                        % If we are still in the block
                    else
                        obj.better_side = obj.better_side_in_block;
                        obj.flash = obj.better_side ~= 9;
                        % if there are levels in flash
                        if obj.settings.flash_level > 0
                            obj.flash_level = obj.flash_level_in_block;
                        end
                        % if uneven rewards and in hedging_multi
                        if strcmpi(obj.settings.name, 'hedging_multi') && obj.flash
                            obj.flash = obj.flash_in_block;
                            obj.audi = 1 - obj.flash;
                        end
                    end
                    
                elseif strcmpi(obj.settings.name, 'hedging_rand')
                    obj.better_side = utils.pick_with_prob([0,1,2,9],[osp/2,osp/2,dsp,np]);
                    obj.flash = obj.better_side ~= 9;
                end
                
                % Figure out the reward size
                if isempty(obj.saveload.subjid) || mod(obj.saveload.subjid,2) % if odd subjid or is testing
                    if obj.pitch_high % right port is correct
                        if obj.better_side == 0 % left flash
                            obj.correct_reward = obj.settings.correct_reward;
                        elseif ismember(obj.better_side, [1,2]) % right flash or both flash
                            obj.correct_reward = obj.settings.correct_reward * obj.settings.rew_multi;
                            % if there are levels in flash
                            if obj.settings.flash_level > 0
                                obj.correct_reward = obj.settings.correct_reward * obj.flash_level * obj.settings.multi_unit;
                            end
                        end
                    elseif ~obj.pitch_high % left port is correct
                        if obj.better_side == 1 % right flash
                            obj.correct_reward = obj.settings.correct_reward;
                        elseif ismember(obj.better_side, [0,2]) % left flash or both flash
                            obj.correct_reward = obj.settings.correct_reward * obj.settings.rew_multi;
                            % if there are levels in flash
                            if obj.settings.flash_level > 0
                                obj.correct_reward = obj.settings.correct_reward * obj.flash_level * obj.settings.multi_unit;
                            end
                        end
                    end
                    
                elseif ~mod(obj.saveload.subjid,2) % if subjid is even number
                    if obj.pitch_high % left port is correct
                        if obj.better_side == 1 % right flash
                            obj.correct_reward = obj.settings.correct_reward;
                        elseif ismember(obj.better_side, [0,2]) % left flash or both flash
                            obj.correct_reward = obj.settings.correct_reward * obj.settings.rew_multi;
                            % if there are levels in flash
                            if obj.settings.flash_level > 0
                                obj.correct_reward = obj.settings.correct_reward * obj.flash_level * obj.settings.multi_unit;
                            end
                        end
                    elseif ~obj.pitch_high % right port is correct
                        if obj.better_side == 0 % left flash
                            obj.correct_reward = obj.settings.correct_reward;
                        elseif ismember(obj.better_side, [1,2]) % right flash or both flash
                            obj.correct_reward = obj.settings.correct_reward * obj.settings.rew_multi;
                            % if there are levels in flash
                            if obj.settings.flash_level > 0
                                obj.correct_reward = obj.settings.correct_reward * obj.flash_level * obj.settings.multi_unit;
                            end
                        end
                    end
                end
            end
            
            
            % Left and right counterbalance across animals
            if isempty(obj.saveload.subjid) || mod(obj.saveload.subjid,2) % if subjid is odd number or is testing
                if obj.pitch_high
                    obj.correct_port = 'BotR'; % high = R, low = L;
                    obj.incorrect_port = 'BotL';
                else obj.correct_port = 'BotL';
                    obj.incorrect_port = 'BotR';
                end
            else % if subjid is even number
                if obj.pitch_high
                    obj.correct_port = 'BotL'; % high = L, low = R;
                    obj.incorrect_port = 'BotR';
                else obj.correct_port = 'BotR';
                    obj.incorrect_port = 'BotL';
                end
            end
            
            % For the control task
            if strcmpi(obj.settings.name,'just_flash')
                obj.pitch_high = 9; % wrong number for pitch_high
                obj.log2_sound = 3; % there is no sound anyway!
                SF = PsychSound.SF;
                obj.Sounds.contSound.volume = 0; % should we keep the sound or just no sound?
                obj.Sounds.contSound.wave = GenerateSineWave(SF, 1000*(2^obj.log2_sound), 0.5);
                obj.this_sound = obj.Sounds.contSound;
                obj.better_side = utils.pick_with_prob([0,1],[obj.settings.lsp, obj.settings.rsp]);
                obj.flash_timer = 0.3;
                obj.flash = 1;
                obj.audi = 0;
                if obj.better_side == 0 % if left
                    obj.correct_port = 'BotL';
                    obj.incorrect_port = 'BotR';
                elseif obj.better_side == 1 % if right
                    obj.correct_port = 'BotR';
                    obj.incorrect_port = 'BotL';
                end
            end
            
            
            % Print some trial-relevant information
            fprintf(1,' Settings:%s \n Trial:%d\t Block:%d\t Trial in block:%d\n log2_sound:%.3f\t Better side:%d\t Flash level:%d\n Correct port:%s\t Correct reward:%d\n Flash timer:%.3f\t Fix time:%.3f\t ITI:%.2f\n',...
                obj.settings.name,obj.trial_num, obj.block_num, obj.trial_in_block, obj.log2_sound, obj.better_side, obj.flash_level, obj.correct_port, obj.correct_reward, obj.flash_timer, obj.ft, obj.ITI);
        end
        
        function sma = generateSM(obj)
            % Assemble state matrix
            snd = obj.Sounds;
            sma = NewStateMatrix(); 
            
            % reward valve times
            reward_valve_time = GetValveTimes(obj.correct_reward,1);
            
            % default values when they are not in settings / not used
            rew_multi = 5;
            flash_on_time = 0.05;
            flash_off_time = 0.05;
            
            % Reward state
            if obj.correct_reward == obj.settings.correct_reward
                reward_state = 'get_reward';
            elseif obj.correct_reward > obj.settings.correct_reward
                reward_state = 'get_multi_reward_on1';
            else reward_state = 'get_reward';
            end
            
            % If just perceptual
            if contains(obj.settings.name,'perceptual')
                fixation_state = 'just_fixation';
                
            % If everything hedging
            elseif contains(obj.settings.name,'hedging') || strcmpi(obj.settings.name,'just_flash')
                % if there are levels in flash
                if obj.settings.flash_level > 0
                    rew_multi = obj.flash_level * obj.settings.multi_unit;
                    flash_on_time = obj.settings.flash_on_time;
                    flash_off_time = obj.settings.flash_off_time;
                else 
                    rew_multi = obj.settings.rew_multi;
                end
                
                if obj.flash_timer >= 0 % sound first, flash later
                    fixation_state = 'flash_fixation1';                  
                     % determine the number of flashes
                    if obj.settings.flash_level > 0
                        n_flashes = obj.flash_level; % one flash per level
                        flash_duration = n_flashes * (flash_on_time + flash_off_time);
                        flash_fix_off_timer = obj.settings.ft_init - obj.flash_timer  - flash_duration;
                        if flash_fix_off_timer <= 0 
                            flash_fix_off_timer = 0.001;
                        end
                    else
                        n_flashes = round((obj.settings.ft_init - obj.flash_timer) / (flash_on_time + flash_off_time)); % flash for entire left duration in ft
                        flash_fix_off_timer = 0.001;
                    end
                    
                    % determine the which flash state to go to
                    if obj.better_side == 0 % Left is better
                        where_flash = 'left_flash_on_a1';
                    elseif obj.better_side == 1 % Right is better
                        where_flash = 'right_flash_on_a1';
                    elseif obj.better_side == 2 % Both are better
                        where_flash = 'both_flash_on_a1';
                    end
                    
                elseif obj.flash_timer < 0 % flash first, sound later
                    fixation_state = 'flash_fixation2';
                    if obj.settings.flash_level > 0
                        n_flashes = obj.flash_level; % one flash per level
                        flash_duration = n_flashes * (flash_on_time + flash_off_time); % how long is the entire flash duration
                        if flash_duration < abs(obj.flash_timer) 
                            where_sound = n_flashes; % the sound plays with the last flash
                        else 
                            where_sound = round(abs(obj.flash_timer) / (flash_on_time + flash_off_time)) + 1;
                        end                       
                        flash_fix_off_timer = obj.settings.ft_init - flash_duration;
                        if flash_fix_off_timer <= 0
                            flash_fix_off_timer = 0.001;
                        end
                    else % when there is no flash levels
                        n_flashes = round(obj.settings.ft_init / (flash_on_time + flash_off_time));  % flash for entire ft duration
                        where_sound = round(abs(obj.flash_timer) / (flash_on_time + flash_off_time)) + 1; % the sound comes on when obj.flash_timer has elapsed
                        flash_fix_off_timer = 0.001;
                    end
                    
                    if obj.better_side == 0 % Left is better
                        where_flash = 'left_flash_on_b1';
                    elseif obj.better_side == 1 % Right is better
                        where_flash = 'right_flash_on_b1';
                    elseif obj.better_side == 2 % Both are better
                        where_flash = 'both_flash_on_b1';
                    end
                end
                
                if obj.better_side == 9 % None is better
                    fixation_state = 'just_fixation';
                end
                % If in hedging_multi and in audi block
                if obj.audi
                    fixation_state = 'just_fixation';
                    if obj.better_side == 0 % Left is better
                        obj.this_sound.wave = [obj.this_sound.wave; zeros(size(obj.this_sound.wave))];
                    elseif obj.better_side == 1 % Right is better
                        obj.this_sound.wave = [zeros(size(obj.this_sound.wave)),obj.this_sound.wave];
                    elseif obj.better_side == 9 % None is better
                        obj.this_sound = obj.Sounds.contSound;
                    end
                end
            else
                fixation_state = 'just_fixation';
            end
            
            
            
            % Trial starts
            sma = AddState(sma, 'name','trial_start','Timer',0.001,...
                'StateChangeConditions',{'Tup','wait_for_poke'});
            
            % Both LED in start port on
            sma = AddState(sma, 'name','wait_for_poke','Timer',obj.settings.start_timeout,...
                'StateChangeConditions',{'Tup','viol_timeout_init',pokeIn(obj.start_port),fixation_state,'OtherIn','viol_sound_init'},...
                'OutputActions',{blueLight(obj.start_port),1, yellowLight(obj.start_port),1});
            
            % Just fixation, no flash but sound
            sma = AddState(sma, 'name','just_fixation','Timer',obj.ft,...
                'StateChangeConditions',{'Tup','fixation_complete',pokeOut(obj.start_port),'trial_start'},...
                'OutputActions',{'PlaySound',obj.this_sound.id});
            
            %Flash during fixation, which requires several states
            if obj.flash
                if obj.flash_timer >= 0 % sound first, flash later
                    sma = AddState(sma, 'name','flash_fixation1','Timer',obj.flash_timer,...
                        'StateChangeConditions',{'Tup',where_flash,pokeOut(obj.start_port),'trial_start'},...
                        'OutputActions', {'PlaySound',obj.this_sound.id});
                    
                    % Left flashes
                    for sx = 1:n_flashes
                        
                        sma = AddState(sma, 'name',sprintf('left_flash_on_a%d',sx),'Timer',flash_on_time,...
                            'StateChangeConditions',{'Tup',sprintf('left_flash_off_a%d',sx),pokeOut(obj.start_port),'trial_start'},...
                            'OutputActions', {yellowLight('BotL'),0.6,yellowLight('MidL'),0.6,yellowLight('TopL'),0.6});
                        
                        if sx == n_flashes
                            sma = AddState(sma, 'name',sprintf('left_flash_off_a%d',sx),'Timer',flash_off_time,...
                                'StateChangeConditions',{'Tup','flash_fixation_off_a',pokeOut(obj.start_port),'trial_start'});
                        else
                            
                            sma = AddState(sma, 'name',sprintf('left_flash_off_a%d',sx),'Timer',flash_off_time,...
                                'StateChangeConditions',{'Tup',sprintf('left_flash_on_a%d',sx+1),pokeOut(obj.start_port),'trial_start'});
                        end
                        
                    end
                    
                    % Right flashes
                    for sx = 1:n_flashes
                        
                        sma = AddState(sma, 'name',sprintf('right_flash_on_a%d',sx),'Timer',flash_on_time,...
                            'StateChangeConditions',{'Tup',sprintf('right_flash_off_a%d',sx),pokeOut(obj.start_port),'trial_start'},...
                            'OutputActions', {yellowLight('BotR'),0.6,yellowLight('MidR'),0.6,yellowLight('TopR'),0.6});
                        
                        if sx == n_flashes
                            sma = AddState(sma, 'name',sprintf('right_flash_off_a%d',sx),'Timer',flash_off_time,...
                                'StateChangeConditions',{'Tup','flash_fixation_off_a',pokeOut(obj.start_port),'trial_start'});
                        else
                            
                            sma = AddState(sma, 'name',sprintf('right_flash_off_a%d',sx),'Timer',flash_off_time,...
                                'StateChangeConditions',{'Tup',sprintf('right_flash_on_a%d',sx+1),pokeOut(obj.start_port),'trial_start'});
                        end
                    end
                    
                    % Both flashes
                    for sx = 1:n_flashes
                        
                        sma = AddState(sma, 'name',sprintf('both_flash_on_a%d',sx),'Timer',flash_on_time,...
                            'StateChangeConditions',{'Tup',sprintf('both_flash_off_a%d',sx),pokeOut(obj.start_port),'trial_start'},...
                            'OutputActions', {yellowLight('BotR'),0.6,yellowLight('MidR'),0.6,yellowLight('TopR'),0.6,...
                            yellowLight('BotL'),0.6,yellowLight('MidL'),0.6,yellowLight('TopL'),0.6});
                        
                        if sx == n_flashes
                            sma = AddState(sma, 'name',sprintf('both_flash_off_a%d',sx),'Timer',flash_off_time,...
                                'StateChangeConditions',{'Tup','flash_fixation_off_a',pokeOut(obj.start_port),'trial_start'});
                        else
                            
                            sma = AddState(sma, 'name',sprintf('both_flash_off_a%d',sx),'Timer',flash_off_time,...
                                'StateChangeConditions',{'Tup',sprintf('both_flash_on_a%d',sx+1),pokeOut(obj.start_port),'trial_start'});
                        end
                    end
                    
                    sma = AddState(sma, 'name','flash_fixation_off_a','Timer',flash_fix_off_timer,...
                        'StateChangeConditions',{'Tup','fixation_complete',pokeOut(obj.start_port),'trial_start'});
                    
                elseif obj.flash_timer < 0 % flash first, sound later
                    sma = AddState(sma, 'name','flash_fixation2','Timer',0.001,...
                        'StateChangeConditions',{'Tup',where_flash,pokeOut(obj.start_port),'trial_start'});
                    
                    % Left flashes
                    for sx = 1:n_flashes
                        
                        if sx == where_sound
                            sma = AddState(sma, 'name',sprintf('left_flash_on_b%d',sx),'Timer',flash_on_time,...
                                'StateChangeConditions',{'Tup',sprintf('left_flash_off_b%d',sx),pokeOut(obj.start_port),'trial_start'},...
                                'OutputActions', {yellowLight('BotL'),0.6,yellowLight('MidL'),0.6,yellowLight('TopL'),0.6,'PlaySound',obj.this_sound.id});
                        else
                            sma = AddState(sma, 'name',sprintf('left_flash_on_b%d',sx),'Timer',flash_on_time,...
                                'StateChangeConditions',{'Tup',sprintf('left_flash_off_b%d',sx),pokeOut(obj.start_port),'trial_start'},...
                                'OutputActions', {yellowLight('BotL'),0.6,yellowLight('MidL'),0.6,yellowLight('TopL'),0.6});
                        end
                        
                        if sx == n_flashes
                            sma = AddState(sma, 'name',sprintf('left_flash_off_b%d',sx),'Timer',flash_off_time,...
                                'StateChangeConditions',{'Tup','flash_fixation_off_b',pokeOut(obj.start_port),'trial_start'});
                        else
                            
                            sma = AddState(sma, 'name',sprintf('left_flash_off_b%d',sx),'Timer',flash_off_time,...
                                'StateChangeConditions',{'Tup',sprintf('left_flash_on_b%d',sx+1),pokeOut(obj.start_port),'trial_start'});
                        end
                        
                    end
                    
                    % Right flashes
                    for sx = 1:n_flashes
                        
                        if sx == where_sound
                            sma = AddState(sma, 'name',sprintf('right_flash_on_b%d',sx),'Timer',flash_on_time,...
                                'StateChangeConditions',{'Tup',sprintf('right_flash_off_b%d',sx),pokeOut(obj.start_port),'trial_start'},...
                                'OutputActions', {yellowLight('BotR'),0.6,yellowLight('MidR'),0.6,yellowLight('TopR'),0.6,'PlaySound',obj.this_sound.id});
                        else
                            sma = AddState(sma, 'name',sprintf('right_flash_on_b%d',sx),'Timer',flash_on_time,...
                                'StateChangeConditions',{'Tup',sprintf('right_flash_off_b%d',sx),pokeOut(obj.start_port),'trial_start'},...
                                'OutputActions', {yellowLight('BotR'),0.6,yellowLight('MidR'),0.6,yellowLight('TopR'),0.6});
                        end
                        
                        if sx == n_flashes
                            sma = AddState(sma, 'name',sprintf('right_flash_off_b%d',sx),'Timer',flash_off_time,...
                                'StateChangeConditions',{'Tup','flash_fixation_off_b',pokeOut(obj.start_port),'trial_start'});
                        else
                            
                            sma = AddState(sma, 'name',sprintf('right_flash_off_b%d',sx),'Timer',flash_off_time,...
                                'StateChangeConditions',{'Tup',sprintf('right_flash_on_b%d',sx+1),pokeOut(obj.start_port),'trial_start'});
                        end
                    end
                    
                    % Both flashes
                    for sx = 1:n_flashes
                        if sx == where_sound
                            sma = AddState(sma, 'name',sprintf('both_flash_on_b%d',sx),'Timer',flash_on_time,...
                                'StateChangeConditions',{'Tup',sprintf('both_flash_off_b%d',sx),pokeOut(obj.start_port),'trial_start'},...
                                'OutputActions', {yellowLight('BotR'),0.6,yellowLight('MidR'),0.6,yellowLight('TopR'),0.6,...
                                yellowLight('BotL'),0.6,yellowLight('MidL'),0.6,yellowLight('TopL'),0.6,'PlaySound',obj.this_sound.id});
                        else
                            sma = AddState(sma, 'name',sprintf('both_flash_on_b%d',sx),'Timer',flash_on_time,...
                                'StateChangeConditions',{'Tup',sprintf('both_flash_off_b%d',sx),pokeOut(obj.start_port),'trial_start'},...
                                'OutputActions', {yellowLight('BotR'),0.6,yellowLight('MidR'),0.6,yellowLight('TopR'),0.6,...
                                yellowLight('BotL'),0.6,yellowLight('MidL'),0.6,yellowLight('TopL'),0.6});
                        end
                        
                        if sx == n_flashes
                            sma = AddState(sma, 'name',sprintf('both_flash_off_b%d',sx),'Timer',flash_off_time,...
                                'StateChangeConditions',{'Tup','flash_fixation_off_b',pokeOut(obj.start_port),'trial_start'});
                        else
                            
                            sma = AddState(sma, 'name',sprintf('both_flash_off_b%d',sx),'Timer',flash_off_time,...
                                'StateChangeConditions',{'Tup',sprintf('both_flash_on_b%d',sx+1),pokeOut(obj.start_port),'trial_start'});
                        end
                    end
                    
                    sma = AddState(sma, 'name','flash_fixation_off_b','Timer',flash_fix_off_timer,...
                        'StateChangeConditions',{'Tup','fixation_complete',pokeOut(obj.start_port),'trial_start'});
                end
            end
            
            % Fixation complete state
            sma = AddState(sma, 'name','fixation_complete','Timer',0.001,...
                'StateChangeConditions',{'Tup','wait_for_choice'},...
                'OutputActions', {'PlaySound',snd.GoSound.id});
            
            % Waiting for the animal to make a choice
            sma = AddState(sma, 'name','wait_for_choice','Timer',obj.settings.choice_timeout,...
                'StateChangeConditions',{'Tup','viol_timeout_choice',pokeIn(obj.correct_port),'chose_correct',...
                pokeIn(obj.incorrect_port),'chose_incorrect','OtherIn','viol_sound_choice'},...
                'OutputActions', {blueLight(obj.correct_port),1,blueLight(obj.incorrect_port),1});
            
            
            %If chose the correct port
            sma = AddState(sma, 'name', 'chose_correct', ...
                'StateChangeConditions', {pokeIn(obj.reward_port),reward_state},...
                'OutputActions',{'BotCled', 0.5});
            
            %If chose the incorrect port
            sma = AddState(sma,'name','chose_incorrect','Timer',0.001,...
                'StateChangeConditions',{'Tup','ITI'});
            
            % Get reward
            sma = AddState(sma, 'name', 'get_reward', 'Timer', reward_valve_time,...
                'StateChangeConditions', {'Tup','ITI'},...
                'OutputActions',{'ValveState',1});
            
            for rx = 1:rew_multi
                sma = AddState(sma, 'name', sprintf('get_multi_reward_on%d',rx), 'Timer', reward_valve_time/rew_multi,...
                    'StateChangeConditions', {'Tup',sprintf('get_multi_reward_off%d',rx)},...
                    'OutputActions',{'ValveState',1});
                if rx == rew_multi
                    sma = AddState(sma, 'name', sprintf('get_multi_reward_off%d',rx), 'Timer', 0.1,...
                        'StateChangeConditions', {'Tup','ITI'});
                else
                    sma = AddState(sma, 'name', sprintf('get_multi_reward_off%d',rx), 'Timer', 0.1,...
                        'StateChangeConditions', {'Tup',sprintf('get_multi_reward_on%d',rx+1)});
                end
            end
            
            % a new ITI begins
            sma = AddState(sma, 'name','ITI','Timer', obj.ITI, ...
                'StateChangeConditions', {'Tup','exit'});
            
            %Timeout
            sma = AddState(sma, 'Name','viol_timeout_init','Timer',0.001,...
                'StateChangeConditions',{'Tup','ITI'});
            
            sma = AddState(sma, 'Name','viol_timeout_choice','Timer',0.001,...
                'StateChangeConditions',{'Tup','ITI'});
            
            %Violation sound
            sma = AddState(sma, 'Name','viol_sound_init','Timer',0.1,...
                'OutputActions',{'PlaySound',snd.ShortViolSound.id},...
                'StateChangeConditions',{'Tup','wait_for_poke'});
            
            sma = AddState(sma, 'Name','viol_sound_choice','Timer',0.1,...
                'OutputActions',{'PlaySound',snd.ShortViolSound.id},...
                'StateChangeConditions',{'Tup','wait_for_choice'});
            
            obj.statematrix = sma;
        end
        
        function trialCompleted(obj)
            
            parsed_events = obj.peh(end);
            all_states = fields(parsed_events.States);
            entered_states_index = structfun(@(x)~isnan(x(1)), parsed_events.States);
            entered_states = all_states(entered_states_index);
            
            obj.hit = 0;
            obj.viol = sum(strncmpi(entered_states, 'viol_timeout',12));
            obj.init_timeout = sum(strcmpi(entered_states, 'viol_timeout_init'));
            obj.choice_timeout = sum(strcmpi(entered_states, 'viol_timeout_choice'));
            if obj.init_timeout || obj.choice_timeout
                obj.timeout = 1;
            else obj.timeout = 0;
            end
            
            % Get init_time
            if obj.init_timeout
                obj.init_time = 0;
                obj.resp_time = 0;
                obj.reward = 0;
            else
                obj.init_time = parsed_events.States.wait_for_poke(1,2) - parsed_events.States.trial_start(1,2);
            end
            
            % Get fixation related information
            obj.fixation_attempts = size(parsed_events.States.trial_start,1)-1;
            
            [all_poke_times, all_poke_types]= getAllPokes(parsed_events);
            obj.n_wrong_pokes = length(all_poke_types) - obj.fixation_attempts - 2;
            if obj.n_wrong_pokes < 0
                obj.n_wrong_pokes = 0;
            end
            
            % Find out the animal's choice; get resp_time
            if ~obj.timeout
                choice_state = findState('chose_', entered_states);
                choice_split = strsplit(choice_state, '_');
                
                if strcmpi(choice_split{2}, 'correct')
                    obj.correct_choice = 1;
                elseif strcmpi(choice_split{2}, 'incorrect')
                    obj.correct_choice = 0;
                else obj.correct_choice = 0;
                end
                
                if mod(obj.saveload.subjid,2) % if subjid odd
                    obj.choice = ~xor(obj.pitch_high,obj.correct_choice); % 0 = left, 1 = right
                else obj.choice = xor(obj.pitch_high,obj.correct_choice);
                end
                
                obj.resp_time = parsed_events.States.wait_for_choice(end) - parsed_events.States.wait_for_choice(1,1);
                obj.reward = obj.correct_reward * obj.correct_choice;
                
            elseif obj.timeout
                obj.choice = 0;
                obj.resp_time = 0;
                obj.correct_choice = 0;
                obj.reward = 0;
            end
            
            % A hit is defined by
            if ~obj.timeout
                obj.hit = obj.correct_choice;
            end
            
            % Define one_fixation for fixation folks
            if contains(obj.settings.name, 'fix')
                if obj.fixation_attempts == 0 && obj.timeout ~= 1
                    obj.one_fixation = 1;
                elseif obj.timeout == 1
                    obj.one_fixation = rand < 0.5;
                else obj.one_fixation = 0;
                end
            end
            
            % Get hits for the performance-based block
            if contains(obj.settings.name, 'perceptual')
                tib = obj.trial_in_block;
                if obj.trial_in_block == 1 % If a new block initiates
                    obj.block_hit = [];
                    obj.block_hit(tib) = obj.hit;
                else
                    obj.block_hit(tib) = obj.hit;
                end
            end
            
            
            % Other stuff we apparently need to save
            ndt = obj.n_done_trials;
            obj.timeout_history(ndt) = obj.timeout;
            obj.log2_history(ndt) = obj.log2_sound;
            obj.choice_history{ndt} = obj.choice;
            obj.violation_history(ndt) = obj.viol;
            obj.reward_history(ndt) = obj.reward;
            obj.hit_history(ndt) = obj.hit;
            obj.RT_history(ndt) = obj.resp_time;
            %obj.completed_trials(ndt) = numel(obj.timeout_history) - sum(obj.timeout_history);
        end
        
        
        function savedata = getProtoTrialData(obj)
            % Save data to proto.hedging
            savedata.ITI = obj.ITI;
            savedata.log2_sound = obj.log2_sound;
            savedata.flash_timer = obj.flash_timer;
            savedata.better_side = obj.better_side;
            savedata.correct_choice = obj.correct_choice;
            savedata.init_time = obj.init_time;
            savedata.resp_time = obj.resp_time;
            savedata.pitch_high = obj.pitch_high;
            savedata.fixation_time = obj.ft;
            savedata.fixation_attempts = obj.fixation_attempts;
            savedata.block_num = obj.block_num;
            savedata.timeout = obj.timeout;
            savedata.n_wrong_pokes = obj.n_wrong_pokes;
            savedata.flash_level = obj.flash_level;
            
        end
        
        function list = trialPropertiesToSave(obj)
            % Save data to beh.trialsview
            parentlist = trialPropertiesToSave@ProtoObj(obj);
            
            list = [ parentlist;
                { 'ITI' };
                { 'log2_sound',
                'better_side',
                'correct_choice',
                'init_time',
                'resp_time',
                'init_time',
                'pitch_high',
                'correct_port',
                'ft',
                'fixation_attempts',
                'one_fixation',
                'block_num',
                'init_timeout',
                'choice_timeout',
                'timeout',
                'n_wrong_pokes',
                'flash_timer',
                'flash_level'}];
        end
        
        function next_settings = prepareNextSession(obj)
            next_settings = [];
            
            if contains(obj.settings.name,'fix_perceptual')
                next_settings.ft_init = obj.ft(end);
            end
            
            if contains(obj.settings.name,'perceptual_cont')
                % If perform well, increase the difficulty
                if obj.hit > 0.9
                    next_settings.pitch_edge = obj.settings.pitch_edge + 1;
                else next_settings.pitch_edge = obj.settings.pitch_edge;
                end
                % If perform really well on block-rand sound, promote to stage 7
                if next_settings.pitch_edge >= 5 && obj.hit > 0.9
                    obj.saveload.stage = obj.saveload.stage + 1;
                end
                next_settings.block_length = obj.settings.block_length;
            end
            
            if contains(obj.settings.name,'perceptual_r')
                next_settings.repeat_error = obj.settings.repeat_error;
            end
            
            if strcmpi(obj.settings.name,'hedging')
                next_settings.correct_reward = obj.settings.correct_reward;
                next_settings.rew_multi = obj.settings.rew_multi;
                next_settings.sigma_s = obj.settings.sigma_s;
                next_settings.oneside_prob = obj.settings.oneside_prob;
                next_settings.double_prob = obj.settings.double_prob;
                next_settings.block_length = obj.settings.block_length;
                next_settings.flash_timer = obj.settings.flash_timer;
                next_settings.ITI_min = obj.settings.ITI_min;
                next_settings.ITI_max = obj.settings.ITI_max;
                next_settings.flash_level = obj.settings.flash_level;
                next_settings.multi_unit = obj.settings.multi_unit;
                next_settings.flash_on_time = obj.settings.flash_on_time;
                next_settings.flash_off_time = obj.settings.flash_off_time;
            end
            
            if strcmpi(obj.settings.name,'hedging_rends')
                next_settings.rew_multi = obj.settings.rew_multi;
                next_settings.oneside_prob = obj.settings.oneside_prob;
                next_settings.double_prob = obj.settings.double_prob;
                next_settings.block_length = obj.settings.block_length;
                next_settings.flash_timer = obj.settings.flash_timer;
            end
            
            if strcmpi(obj.settings.name,'hedging_r2g')
                next_settings.rew_multi = obj.settings.rew_multi;
                next_settings.oneside_prob = obj.settings.oneside_prob;
                next_settings.double_prob = obj.settings.double_prob;
                next_settings.block_length = obj.settings.block_length;
                next_settings.flash_timer = obj.settings.flash_timer;
                next_settings.sigma_low = obj.settings.sigma_low;
                next_settings.sigma_high = obj.settings.sigma_high;
            end
            
            if strcmpi(obj.settings.name,'hedging_multi')
                next_settings.rew_multi = obj.settings.rew_multi;
                next_settings.sigma_s = obj.settings.sigma_s;
                next_settings.oneside_prob = obj.settings.oneside_prob;
                next_settings.double_prob = obj.settings.double_prob;
                next_settings.flash_prob = obj.settings.flash_prob;
                next_settings.block_length = obj.settings.block_length;
            end
        end
    end
end


function new_port = switch_side(current_port)
if strcmpi(current_port, 'BotL')
    new_port = 'BotR';
elseif strcmpi(current_port, 'BotR')
    new_port = 'BotL';
end
end