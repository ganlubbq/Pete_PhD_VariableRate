function [ mNs, mospa, rmse, MAP_rmse ] = performance_measures( flags, params, pts, times, true_tau, true_intx )
%PERFORMANCE_MEASURES Calculates various performance measures for VRPF/S
%output

sd = flags.space_dim;

mospa = [];
rmse = [];
MAP_rmse = [];

% Count particles
Np = length(pts);

% Calculate mean number of jumps
mNs = mean(cat(1,pts.Ns));

% Calculate mean OSPA between particle jump sequences and real sequence
if ~isempty(true_tau)
    ospas = zeros(Np,1);
    for ii = 1:Np
        ospas(ii) = OSPA(true_tau, pts(ii).tau(1:pts(ii).Ns), 1, 2);
    end
    mospa = mean(ospas);
end

% Calculate RMSEs for MMSE estimate
if ~isempty(true_intx)
    intx = cat(3, pts.intx);
    error = abs(bsxfun(@minus, true_intx, intx));
    rmse.pos_over_time = sqrt(mean( sum(error(1:sd,:,:).^2,1), 3));
    rmse.vel_over_time = sqrt(mean( sum(error(sd+1:2*sd,:,:).^2,1), 3));
    rmse.pos = sqrt(mean(rmse.pos_over_time.^2));
    rmse.vel = sqrt(mean(rmse.vel_over_time.^2));
end

% Find MAP particle
prob = zeros(Np,1);
for ii = 1:Np
    prob(ii) = sum(pts(ii).tau_prob) + sum(pts(ii).w_prob) + sum(pts(ii).lhood); % There should be P(x_0) term in this.
end
[~, MAP_ind] = max(prob);

% Calculate RMSEs for MAP estimate
if ~isempty(true_intx)
    intx = pts(MAP_ind).intx;
    error = abs(bsxfun(@minus, true_intx, intx));
    MAP_rmse.pos_over_time = sqrt(mean( sum(error(1:sd,:,:).^2,1), 3));
    MAP_rmse.vel_over_time = sqrt(mean( sum(error(sd+1:2*sd,:,:).^2,1), 3));
    MAP_rmse.pos = sqrt(mean(MAP_rmse.pos_over_time.^2));
    MAP_rmse.vel = sqrt(mean(MAP_rmse.vel_over_time.^2));
end

% figure, plot(times, rmse_over_time)

end

