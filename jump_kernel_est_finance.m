function [t_grid, jump_1_kdest, jump_2_kdest] = jump_kernel_est_finance(T, pts_tau, pts_type)
%JUMP_KERNEL_EST Make a kernel density estimate of the jump times from the
% particle output

Np = size(pts_tau,1);

% Make a finely spaced time grid
t_grid = linspace(0,T,1001)';

% Set the standard deviation equal to the spacing
sd = 2*(t_grid(2)-t_grid(1));

% Make a vector list of all the jump times
jump_list = pts_tau(:);
jump_list(jump_list==0)=[];
type_list = pts_type(:);
type_list(type_list==0)=[];

% Loop through and make the kd estimate
jump_1_kdest = zeros(size(t_grid));
jump_2_kdest = zeros(size(t_grid));
for tt = 1:length(jump_list)
    if type_list(tt)==1
        jump_1_kdest = jump_1_kdest + exp(-0.5*(t_grid-jump_list(tt)).^2/(sd^2))/Np;
    elseif type_list(tt)==2
        jump_2_kdest = jump_2_kdest + exp(-0.5*(t_grid-jump_list(tt)).^2/(sd^2))/Np;
    end
%     jump_kdest = jump_kdest + normpdf(t_grid,jump_list(tt),sd)/Np;
end

end

