%% 600kW 风电系统自动化评价程序 (修复兼容版)
clear; clc; close all;

%% 1. 核心参数 (必须平铺，Simulink 才能直接读取)
rho = 1.225; R = 20; ng = 43.165;
Jr = 440650; Jg = 34.4; 
J_total = Jr + (ng^2) * Jg;  % 修复 (u(1)-u(2))/J_total 报错
lambda_opt = 7.95; 
Cp_max = 0.411;
Ini_Omega = 1.59;            % 修复 Integrator 报错
K = 0.0626;

%% 2. 风速数据处理 (修复 From Workspace 报错)
try
    load('windspeed2.mat'); 
    % 模型在找变量名 'windspeed'，必须精确匹配
    windspeed = [(0:0.05:600)', windspeedlist(:,1)]; 
    disp('数据加载成功。');
catch
    error('未找到 windspeed2.mat，请确认文件在当前文件夹。');
end

%% 3. 运行仿真
model = 'fangzheng_run';
if ~bdIsLoaded(model), load_system(model); end
simOut = sim(model, 'StopTime', '600');

%% 4. 数据提取 (自动处理 Timeseries 或 结构体)
% 获取时间轴
t = simOut.tout;

% 辅助提取函数
fetch = @(name) simOut.findProp(name) ~= 0;
getVal = @(raw) feval(@(v) ifelse(isa(v,'timeseries'), v.Data, v), raw);

% 提取变量 (根据模型实际导出的名字)
Te = simOut.get('Te');   if isa(Te,'timeseries'), Te = Te.Data; end
Wg = simOut.get('Wg');   if isa(Wg,'timeseries'), Wg = Wg.Data; end
P  = simOut.get('Power'); if isa(P, 'timeseries'), P = P.Data; end
Pi = simOut.get('IdeaPower'); if isa(Pi,'timeseries'), Pi = Pi.Data; end

%% 5. 指标计算与绘图
v_sim = interp1(windspeed(:,1), windspeed(:,2), t);
Wg_opt = (lambda_opt * v_sim * ng) / R;

fprintf('\n=== 仿真成绩单 ===\n');
fprintf('▶ 传动链载荷 (σ): %.2f N·m\n', std(Te));
fprintf('▶ 捕获效率 (η):  %.2f %%\n', (mean(P)/mean(Pi))*100);

% 快速绘图
figure('Color', 'w', 'Name', 'MPPT 性能分析');
subplot(3,1,1); plot(t, v_sim, 'c'); title('风速 (m/s)'); grid on;
subplot(3,1,2); plot(t, Wg_opt, 'r--', t, Wg, 'b'); title('转速跟踪'); legend('目标','实际'); grid on;
subplot(3,1,3); plot(t, Te, 'k'); title('电磁转矩 (N·m)'); xlabel('时间 (s)'); grid on;