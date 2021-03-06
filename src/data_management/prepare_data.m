% Read in the data from the original data files and prepare them for use
% across differents modules of this project.

%% Path settings

% If you do not use waf you can comment out the project_paths line and use
% the relative path instead.
output_path = project_paths('OUT_DATA');
% output_path = '../../bld/out/data/';
path_original_data = project_paths('IN_DATA');
% path_original_data = '../original_data/';

path_financial_accounts = strcat(path_original_data, ...
                                 'Financial_accounts_original.csv');
path_business_gdp = strcat(path_original_data, ...
                           'business_value_added_nipa_original.csv');
path_business_prices = strcat(path_original_data, ...
                              'business_prices_nipa_original.csv');
path_real_gdp = strcat(path_original_data, 'real_gdp_nipa_original.csv');
path_working_hours = strcat(path_original_data, ...
                            'index_hours_bea_original.csv');

%% Read in data
financial_accounts_original = csvread(path_financial_accounts, 6, 1);
corporate_equities = financial_accounts_original(:, 1);
corporate_dividends = financial_accounts_original(:, 2);
farm_dividends = financial_accounts_original(:, 3);
prop_invest = financial_accounts_original(:, 4);
corporate_debt = financial_accounts_original(:, 5);
corporate_capital_consumption = financial_accounts_original(:, 6);
noncorporate_capital_consumption = financial_accounts_original(:, 7);
capital_expenditures = financial_accounts_original(:, 8);

business_gdp = (csvread(path_business_gdp, 7, 2, 'C8..IW8'))';
business_prices = (csvread(path_business_prices, 7, 2, 'C8..IW8'))';
real_gdp = (csvread(path_real_gdp, 6, 2, 'C7..IW7'))';

timeline.full_sample = 1952:0.25:2015.5;
start_date = 1984.0;
start_index = find(timeline.full_sample == start_date);
end_date = 2015.5;
end_index = find(timeline.full_sample == end_date);
timeline.estimation_sample = timeline.full_sample(start_index:end_index);

%% Equity payout and debt repurchase

% Equity Payout is calculated as net dividends farm and nonfarm sector minus
% net increase in corporate equitiesminus proprietors’ net investment and
% normalized by Business GDP times 10 (to meet scale in the paper).
equity_payout.full_sample = (corporate_dividends ...
                             + farm_dividends - ...
                             corporate_equities - ...
                             prop_invest)./(business_gdp ...
                                            * 10);

% Debt Repurchase is the negative of net increase in debt, normalized by
% Business GDP times 10.
debt_repurchase.full_sample = (- corporate_debt)./(business_gdp * 10);

% Cyclical components for debt and equity for the subset from 1984 to 2015
% received from band pass filtering the original data on that subperiod.

% Calculate linearly detrended series for equity payout and debt repurchase
% from 1984 onwards as they are used for comparing both model simulations to
% the data.
equity_payout.detrended = ...
    detrend(equity_payout.full_sample(start_index:end_index));

debt_repurchase.detrended = ...
    detrend(debt_repurchase.full_sample(start_index:end_index));


%% Capital

% Capital construction for the whole sample. 
capital.full_sample = NaN(length(timeline.full_sample), 1);

% Find initial value for capital such that there is no trend in the ratio of
% capital to real business gdp over the entire sample.
capital_init = 22.53;

for idx = 1:length(capital.full_sample)
    if idx == 1
        capital.full_sample(idx, 1) = capital_init + (capital_expenditures(idx) - ...
                                                      corporate_capital_consumption(idx) ...
                                                      - noncorporate_capital_consumption(idx)) ...
            * 0.00025/business_prices(idx);
        
    else
        capital.full_sample(idx, 1) = capital.full_sample(idx - 1, 1) + ...
            (capital_expenditures(idx) - corporate_capital_consumption(idx) ...
             - noncorporate_capital_consumption(idx)) * 0.00025/business_prices(idx);
    end
end

% Calculate proportional deviations of capital via log differencing and
% demeaning for the 1984-2015 subsample. Note that here the trend is not
% necessarily zero, so a difference between linearly detrending and
% demeaning might exist.
capital.log_diff = detrend(log(capital.full_sample(start_index:end_index)));

%% Debt

% Debt construction for the whole sample
nom_debt = NaN(length(timeline.full_sample), 1);
debt_init = 94.12;

for idx = 1:length(nom_debt)
    if idx == 1
        nom_debt(idx) = debt_init + corporate_debt(idx) * 0.00025;
    else
        nom_debt(idx) = nom_debt(idx - 1) + corporate_debt(idx) * 0.00025;
    end
end

real_debt.full_sample = nom_debt./business_prices;

% Calculate proportional deviations of debt by the same procedure described
% for capital.
real_debt.log_diff = detrend(log(real_debt.full_sample(start_index:end_index)));

%% Output

% Real business value added calculated for whole sample by dividing the series
% for business value added by the business price index.
business_output.full_sample = business_gdp ./ business_prices;

% Proportional deviations as described above
business_output.log_diff = ...
    detrend(log(business_output.full_sample(start_index:end_index)));

% Real total gdp for the entire sample.
total_output.full_sample = real_gdp;

% Proportional deviations for subsample as above.
total_output.log_diff = ...
    detrend(log(total_output.full_sample(start_index:end_index)));

%% Working hours

% Import working hours for estimation sample only
working_hours.original = csvread(path_working_hours, 1, 1);

% Proportional deviations for subsample as above
working_hours.log_diff = detrend(log(working_hours.original));


%% Save series to matlab dataset

if ~exist(output_path, 'dir')
    mkdir(output_path)
end

save(strcat(output_path, 'dataset.mat'), 'equity_payout', 'debt_repurchase', ...
    'capital', 'real_debt', 'business_output', 'total_output', ...
    'working_hours', 'timeline')