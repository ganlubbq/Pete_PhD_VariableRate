function [ rmse, MAP_rmse, corr_rmse ] = filter_errors( flags, params, filt_part_sets, filt_weight_sets, times_array, true_tau, true_w, true_intx )
%FILTER_ERRORS Calculate MMSE and MAP errors of filtering estimates

sd = flags.space_dim;
K = length(times_array);

rmse.pos_over_time = zeros(1, K);
rmse.vel_over_time = zeros(1, K);
corr_rmse.pos_over_time = zeros(1, K);
corr_rmse.vel_over_time = zeros(1, K);
MAP_rmse.pos_over_time = zeros(1, K);
MAP_rmse.vel_over_time = zeros(1, K);


for k = 2:K
    
    pts = filt_part_sets{k};
    wts = filt_weight_sets{k};
%     if k == 1
%         Np = length(pts); wts = log(ones(1,Np)/Np);
%     end
    
    % Count particles
    Np = length(pts);
    
    % Calculate RMSEs for MMSE estimate
%     intx = mean(cat(3, pts.intx),3);
    intx = squeeze(sum(bsxfun(@times, permute(cat(3, pts.intx),[3,1,2]), exp(wts)), 1));
    error = abs(true_intx(:,k) - intx(:,k));
    rmse.pos_over_time(k) = sqrt(mean( sum(error(1:sd,:,:).^2,1), 3));
    rmse.vel_over_time(k) = sqrt(mean( sum(error(sd+1:2*sd,:,:).^2,1), 3));
    
    % Add drift to velocity and work out RMSE
    if (flags.dyn_mod == 2)
        % Inferred
        pts_intx = cat(3, pts.intx);
        for ii = 1:Np
            cpi = find(pts(ii).tau==max(pts(ii).tau(pts(ii).tau<times_array(k))));
            pts_intx(sd+1:2*sd, k, ii) = pts_intx(sd+1:2*sd, k, ii) + pts(ii).w(sd+1:2*sd,cpi);
        end
%         intx = mean(pts_intx, 3);
        intx = squeeze(sum(bsxfun(@times, permute(pts_intx,[3,1,2]), exp(wts)), 1));
        
        % True
        mod_true_intx = true_intx(:,k);
        if ~isempty(true_w)
            cpi = find(true_tau==max(true_tau(true_tau<times_array(k))));
            mod_true_intx(sd+1:2*sd) = mod_true_intx(sd+1:2*sd) + true_w(sd+1:2*sd,cpi);
        end
        
        error = abs(mod_true_intx - intx(:,k));
        corr_rmse.pos_over_time(k) = sqrt( sum(error(1:sd,:).^2,1));
        corr_rmse.vel_over_time(k) = sqrt( sum(error(sd+1:2*sd,:).^2,1));
    end
    
    % Find MAP particle
    prob = zeros(Np,1);
    for ii = 1:Np
        prob(ii) = sum(pts(ii).tau_prob(1:pts(ii).Ns)) + sum(pts(ii).w_prob(1:pts(ii).Ns)) + sum(pts(ii).lhood(1:k)); % There should be P(x_0) term in this.
    end
    [~, MAP_ind] = max(prob);
    
    % Calculate RMSEs for MAP estimate
    intx = pts(MAP_ind).intx;
    error = abs(bsxfun(@minus, true_intx(:,k,:), intx(:,k,:)));
    MAP_rmse.pos_over_time(k) = sqrt(mean( sum(error(1:sd,:,:).^2,1), 3));
    MAP_rmse.vel_over_time(k) = sqrt(mean( sum(error(sd+1:2*sd,:,:).^2,1), 3));

end

rmse.pos = sqrt(mean(rmse.pos_over_time.^2));
rmse.vel = sqrt(mean(rmse.vel_over_time.^2));
MAP_rmse.pos = sqrt(mean(MAP_rmse.pos_over_time.^2));
MAP_rmse.vel = sqrt(mean(MAP_rmse.vel_over_time.^2));
corr_rmse.pos = sqrt(mean(corr_rmse.pos_over_time.^2));
corr_rmse.vel = sqrt(mean(corr_rmse.vel_over_time.^2));



% figure, plot(times, rmse_over_time)

end

