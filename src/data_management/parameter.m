% Initialize parameter that are used in the model

%% Path settings

path_to_model_specs = project_paths('IN_MODEL_SPECS', 'parameters.mat');
% path_to_model_specs = '../model_specs/parameters.mat';

%% Set parameters
param.discount_factor = 0.9825
param.tax_advantage   = 0.35
param.alpha           = 1.8834
param.theta           = 0.36
param.delta           = 0.025
param.xi_bar          = 0.1634
param.kappa           = 0.146
param.sigma_z         = 0.0045
param.sigma_xi        = 0.0098

%% Save parameters to model specs folder
save(path_to_model_specs, 'param');