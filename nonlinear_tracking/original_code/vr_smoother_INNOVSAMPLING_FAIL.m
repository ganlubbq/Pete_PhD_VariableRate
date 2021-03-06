function [ pts ] = vr_smoother( flags, params, filt_part_sets, filt_weight_sets, times, observ )
%VR_SMOOTHER Smoother for variable rate models using direct sampling method.

% Set some local variables
K = params.K; S = params.S; Np = params.Np;
ds = params.state_dim; dr = params.rnd_dim; do = params.obs_dim;

% Create a cell array for the smoothed particles
% pts = cell(S,1);
pts = initialise_particles(flags, params, S, observ);

% Loop through smoothing particles
for ii = 1:S
    
    % Initialise particle with a random final frame filtering particle
    pt = filt_part_sets{K}(unidrnd(Np));
    
    % Append a state just after the final time
    pt.Ns = pt.Ns+1;
    pt.tau = [pt.tau, times(end)+eps(times(end))];
    pt.x = [pt.x, pt.intx(:,end)];
    pt.w = [pt.w, zeros(dr,1)];
    pt.tau_prob = [];
    pt.w_prob = [];
    
    % Loop backwards through time
    for k = K:-1:2
        
        k
        
        t = times(k);
        
        % Create an array of bacward sampling weights
        back_weights = zeros(Np,1);
        fut_lhood_arr = zeros(Np,1);
        jump_trans_prob_arr = zeros(Np,1);
        accel_prob_arr = zeros(Np,1);
        
        % Find indexes
        stop_tau_idx = find_nearest(pt.tau, t, true);
        stop_t_idx = find_nearest(times, pt.tau(stop_tau_idx), false);
        
        % Loop through filtering particles
        for jj = 1:Np
            
            filt_pt = filt_part_sets{k}(jj);
            
            % Find indexes
            start_tau_idx = find_nearest(filt_pt.tau, t, false);
            start_t_idx = find_nearest(times, filt_pt.tau(start_tau_idx), true);
            
            % Calculate last state backwards
            prev_x = previous_state(flags, params, pt.x(:,stop_tau_idx), filt_pt.w(:,start_tau_idx), pt.tau(stop_tau_idx)-filt_pt.tau(start_tau_idx));
            
            % Calculate future likelihood
            [~, fut_lhood] = interpolate_state(flags, params, filt_pt.tau(start_tau_idx), prev_x, filt_pt.w(:,start_tau_idx), times(k+1:stop_t_idx), observ(:, k+1:stop_t_idx));
            fut_lhood_arr(jj) = sum(fut_lhood);
            
            % Calculate transition probability
            [~, jump_trans_prob_arr(jj)] = sample_jump_time(flags, params, filt_pt.tau(start_tau_idx), [], pt.tau(stop_tau_idx));
            accel_prob_arr(jj) = log(mvnpdf(filt_pt.w(:,start_tau_idx)', zeros(1,dr), params.Q));
            
            if k == 460
                [new_intx, ~] = interpolate_state(flags, params, filt_pt.tau(start_tau_idx), prev_x, filt_pt.w(:,start_tau_idx), times(start_t_idx:stop_t_idx), observ(:, start_t_idx:stop_t_idx));
                figure(2), hold on
                plot(new_intx(1,:), new_intx(2,:), 'color', [rand, rand, rand]);
            end
            
        end
        
        % Calculate weights
        back_weights = filt_weight_sets{k} + fut_lhood_arr + jump_trans_prob_arr + accel_prob_arr;
        
        % Sample weights
        back_weights = back_weights - max(back_weights);
        jj = randsample(Np, 1, true, exp(back_weights));
        filt_pt = filt_part_sets{k}(jj);
        start_tau_idx = find_nearest(filt_pt.tau, t, false);
        start_t_idx = find_nearest(times, filt_pt.tau(start_tau_idx), true);
        prev_x = previous_state(flags, params, pt.x(:,stop_tau_idx), filt_pt.w(:,start_tau_idx), pt.tau(stop_tau_idx)-filt_pt.tau(start_tau_idx));
        
        % Update particle
        pt.tau = [filt_pt.tau(1:start_tau_idx) pt.tau(stop_tau_idx:end)];
        pt.Ns = size(pt.tau,2);
        pt.w = [filt_pt.w(:,1:start_tau_idx) pt.w(:,stop_tau_idx:end)];
        pt.x = [zeros(params.state_dim,start_tau_idx-1) prev_x pt.x(:,stop_tau_idx:end)];
        [pt.intx(:,k:stop_t_idx), ~] = interpolate_state(flags, params, pt.tau(start_tau_idx), prev_x, pt.w(:,start_tau_idx), times(k:stop_t_idx), observ(:, k:stop_t_idx));
        
    end
    
    % Output
    fprintf('*** Completed trajectory %d.\n', ii);
    
end


end

