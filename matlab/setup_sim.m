%% 600kW 风电系统参数加载脚本 (调试专用)
clear; clc;

%% 1. 核心物理参数 (直接注入工作区)
rho = 1.225;            % 空气密度
R = 20;                 % 风轮半径
ng = 43.165;            % 齿轮箱变速比
Jr = 440650;            % 风轮转动惯量
Jg = 34.4;              % 发电机转动惯量
J_total = Jr + (ng^2) * Jg; 

lambda_opt = 7.95;      % 最佳叶尖速比
Cp_max = 0.411;         % 最大功率系数
K = 0.0626;             % MPPT 控制增益
Ini_Omega = 1.59;       % 积分器初始转速 (rad/s)

%% 2. 加载并预处理风速数据
mat_file = 'windspeed2.mat';
if exist(mat_file, 'file')
    data = load(mat_file);
    % 寻找变量 (兼容你 mat 文件里可能的不同变量名)
    if isfield(data, 'windspeedlist')
        raw_v = data.windspeedlist(:,1);
    else
        % 如果变量名就是 windspeed，直接取值
        fn = fieldnames(data);
        raw_v = data.(fn{1});
    end
    
    % 构造 From Workspace 格式: [时间, 数据]
    % 假设步长 0.05s，总长 600s
    t_vector = (0:0.05:(length(raw_v)-1)*0.05)';
    windspeed = [t_vector, raw_v]; 
    
    fprintf('✅ 数据加载成功：变量 "windspeed" 已就绪。\n');
else
    warning('❌ 未找到 %s，请检查路径。', mat_file);
end

%% 3. 打开并配置 Simulink 模型
model_name = 'fangzheng_run_2024a';

% 修正后的 exist 用法：检查是否存在该名称的文件
if exist(model_name, 'file') || exist([model_name, '.slx'], 'file') || exist([model_name, '.mdl'], 'file')
    load_system(model_name); % 加载到内存
    open_system(model_name); % 打开图形界面
    
    % 设置仿真时长 (与数据长度对齐，防止报错)
    if exist('t_vector', 'var')
        set_param(model_name, 'StopTime', num2str(max(t_vector)));
    end
    
    fprintf('🚀 模型 "%s" 已打开。\n', model_name);
    fprintf('------------------------------------------\n');
    fprintf('👉 现在你可以在 Simulink 界面观察模型并点击 [▶] 运行了。\n');
else
    error('❌ 找不到模型文件 "%s"，请确保 .slx 或 .mdl 文件在当前文件夹下。', model_name);
end