%%% TRACKING PARAMETERS %%%

%%% Miscellaneous %%%
params.K = 500;                         % Number of time steps
params.dt = 0.1;                        % Sampling time (this should only be used for generating data. Otherwise, use sampling times provided)
params.T = params.dt*params.K;          % Time of last observation
params.min_speed = 50;                 % Minimum speed allowed

% Starting point distribution (assumed known by algorithm)
% start_state is used by the data generation function (i.e. it's part of the model)
% start_var is used to initiialise particles (i.e. it's part of the algorithm)
if flags.space_dim == 3
    params.start_state = [50; 50; 50; 5; 0; 0];
    params.start_var = diag([10, 10, 10, 1, 1, 1]);
elseif flags.space_dim == 2
	params.start_state = [50; 50; 5; 0];
    params.start_var = diag([10, 10, 1, 1]);
else
    error('unhandled option');
end

%%% Model %%%

% Accelerations
aT = (5)^2;
aN = (50)^2;
aX = (50)^2;
aY = (50)^2;
aZ = (50)^2;

% Jump times
params.rate_shape = 4;%6;                  % State time gamma distribution shape parameter (this is "a", or "k")
params.rate_scale = 20/3;%4;                  % State time gamma distribution scale parameter (this is "b", or "theta")

% Observations
range_var = (200)^2;
bear_var = (pi/180)^2;
elev_var = (pi/1440)^2;
% range_var = (500)^2;
% bear_var = (pi/720)^2;
% elev_var = (pi/720)^2;
range_rate_var = (10)^2;
bear_rate_var = (pi/360)^2;
elev_rate_var = (pi/360)^2;
x_var = (1000)^2;
x_rate_var = (10)^2;

%%% Algorithm 
params.Np = 50;                         % Target number of filtering particles
params.S = 50;                          % Number of smoothing trajectories
params.M = 1;
params.ppsl_move_time_sd = ...          % Standard deviation for proposal distribution for moving jump times
    0.1*(params.rate_shape*params.rate_scale);
params.min_num_ppsl_frames = 20;         % Minimum number of frames over which the UKF-approximated OID proposal is constructed
params.max_num_ppsl_frames = inf;
params.prop_ppsl_frames = 1;          % Proportion of frames in a window used for acceleration proposal



%%% Set up secondary parameters - don't edit this bit

% Set state dimensionality
if flags.space_dim == 2
    params.state_dim = 4;
elseif flags.space_dim == 3
    params.state_dim = 6;
else
    error('unhandled option');
end

% Set observation dimensionality
if flags.obs_vel
    params.obs_dim = params.state_dim;
else
    params.obs_dim = params.state_dim/2;
end

% set random variable dimensionality
if flags.dyn_mod == 2
    params.rnd_dim = params.state_dim;
elseif flags.dyn_mod == 1
    params.rnd_dim = params.state_dim/2;
elseif flags.dyn_mod == 3
    params.rnd_dim = params.state_dim/2;
else
    error('unhandled option');
end

% Set covariance matrix for random variables
if flags.space_dim == 2
    if flags.dyn_mod == 1
        cov = [aT, aN];
    elseif flags.dyn_mod == 2
        cov = [aT, aN, aX, aY];
    elseif flags.dyn_mod == 3
        cov = [aX, aY];
    else
        error('unhandled option');
    end
elseif flags.space_dim == 3
    if flags.dyn_mod == 1
        cov = [aT, aN, aN];
    elseif flags.dyn_mod == 2
        cov = [aT, aN, aN, aX, aY, aZ];
    elseif flags.dyn_mod == 3
        cov = [aX, aY, aZ];
    else
        error('unhandled option');
    end
else
    error('unhandled option');
end
params.Q = diag(cov);

% Set covariance matrix for observations
if flags.space_dim == 2
    if flags.obs_mod == 1
        if ~flags.obs_vel
            cov = [x_var, x_var];
        else
            cov = [x_var, x_var, x_rate_var, x_rate_var];
        end
    elseif flags.obs_mod== 2
        if ~flags.obs_vel
            cov = [bear_var, range_var];
        else
            cov = [bear_var, range_var, bear_rate_var, range_rate_var];
        end
    else
        error('unhandled option');
    end
elseif flags.space_dim == 3
    if flags.obs_mod == 1
        if ~flags.obs_vel
            cov = [x_var, x_var, x_var];
        else
            cov = [x_var, x_var, x_var, x_rate_var, x_rate_var, x_rate_var];
        end
    elseif flags.obs_mod== 2
        if ~flags.obs_vel
            cov = [bear_var, elev_var range_var];
        else
            cov = [bear_var, elev_var, range_var, bear_rate_var, elev_rate_var, range_rate_var];
        end
    else
        error('unhandled option');
    end
else
    error('unhandled option');
end
params.R = diag(cov);