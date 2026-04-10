%% 600kW 风电系统自动化评价程序 (修复兼容版)
clear; clc; close all;
use_raw_flag=true;
%% 1. 核心参数 (必须平铺，Simulink 才能直接读取)
rho = 1.225; R = 20; ng = 43.165;
Jr = 400650; Jg = 34.4; 
J_total = Jr + (ng^2) * Jg  % 修复 (u(1)-u(2))/J_total 报错
lambda_opt = 7.95; 
Cp_max = 0.411;
Ini_Omega = 1.59;            % 修复 Integrator 报错
K = 0.0626;

%% 2. 风速数据处理 (修复 From Workspace 报错)
load('windspeed7.mat'); 
% 模型在找变量名 'windspeed'，必须精确匹配
T_end = 600;
dt = 0.05;
t = (0:dt:T_end)';

% 确保 windspeedlist 只取前 12001 行
% 或者如果它不够长，你需要调整 T_end
windspeed = [t, windspeed6(1:length(t), 1)];
disp('数据加载成功。');


%% 3. 运行双方案仿真（raw 与改进）
model = 'fangzheng_run_2024a';
if ~bdIsLoaded(model), load_system(model); end

% 3.1 raw 算法
clear mppt_raw mppt_enhance;
use_raw_flag = true;
simOut_raw = sim(model, 'StopTime', '600');

% 3.2 改进算法
clear mppt_raw mppt_enhance;
use_raw_flag = false;
simOut_enh = sim(model, 'StopTime', '600');

%% 4. 数据提取 (raw 与改进)
% 时间轴（两次仿真时长相同，取 raw 的时间轴即可）
t = simOut_raw.tout;

% raw 输出
Te_raw = simOut_raw.get('Te');   if isa(Te_raw,'timeseries'), Te_raw = Te_raw.Data; end
Wg_raw = simOut_raw.get('Wg');   if isa(Wg_raw,'timeseries'), Wg_raw = Wg_raw.Data; end
P_raw  = simOut_raw.get('Power'); if isa(P_raw, 'timeseries'), P_raw = P_raw.Data; end
Pi_raw = simOut_raw.get('IdeaPower'); if isa(Pi_raw,'timeseries'), Pi_raw = Pi_raw.Data; end

% 改进输出
Te_enh = simOut_enh.get('Te');   if isa(Te_enh,'timeseries'), Te_enh = Te_enh.Data; end
Wg_enh = simOut_enh.get('Wg');   if isa(Wg_enh,'timeseries'), Wg_enh = Wg_enh.Data; end
P_enh  = simOut_enh.get('Power'); if isa(P_enh, 'timeseries'), P_enh = P_enh.Data; end
Pi_enh = simOut_enh.get('IdeaPower'); if isa(Pi_enh,'timeseries'), Pi_enh = Pi_enh.Data; end

Te_max_raw = max(abs(Te_raw));
Te_max_enh = max(abs(Te_enh));
Te_nominal = 12000;
Load_Factor_raw = Te_max_raw / Te_nominal;
Load_Factor_enh = Te_max_enh / Te_nominal;

%% 5. 指标计算与绘图
v_sim = interp1(windspeed(:,1), windspeed(:,2), t);
Wg_opt = (lambda_opt * v_sim * ng) / R;

Te_mean_raw = mean(Te_raw);
Te_mean_enh = mean(Te_enh);
if abs(Te_mean_raw) < 1e-9
    torque_ratio_pct = NaN;
    torque_improve_pct = NaN;
else
    torque_ratio_pct = (Te_mean_enh / Te_mean_raw) * 100;
    torque_improve_pct = ((Te_mean_enh - Te_mean_raw) / Te_mean_raw) * 100;
end

fprintf('\n=== 仿真成绩单 ===\n');
fprintf('【raw】最大传动链载荷 (T_max): %.2f N·m (额定占比: %.1f%%)\n', Te_max_raw, Load_Factor_raw*100);
fprintf('【raw】传动链载荷 (σ): %.2f N·m\n', std(Te_raw));
fprintf('【raw】捕获效率 (η): %.2f %%\n', (mean(P_raw)/mean(Pi_raw))*100);

fprintf('【改进】最大传动链载荷 (T_max): %.2f N·m (额定占比: %.1f%%)\n', Te_max_enh, Load_Factor_enh*100);
fprintf('【改进】传动链载荷 (σ): %.2f N·m\n', std(Te_enh));
fprintf('【改进】捕获效率 (η): %.2f %%\n', (mean(P_enh)/mean(Pi_enh))*100);

fprintf('\n=== 转矩平均值百分比对比 ===\n');
fprintf('raw 基准: 100.00%%\n');
fprintf('改进 / raw: %.2f %%\n', torque_ratio_pct);
fprintf('相对 raw 变化: %.2f %%\n', torque_improve_pct);

if std(Te_raw) < 1e-9
    std_ratio = NaN;
else
    std_ratio = std(Te_enh) / std(Te_raw);
end
fprintf('转矩标准差之比(改进/raw): %.4f\n', std_ratio);

% 快速绘图（保持原可视化风格）
figure('Color', 'w', 'Name', 'MPPT 性能分析');
subplot(3,1,1); plot(t, v_sim, 'c'); title('风速 (m/s)'); grid on;
subplot(3,1,2); plot(t, Wg_opt, 'r-', t, Wg_raw, 'k--', t, Wg_enh, 'b-'); title('转速跟踪'); legend('目标','改进前(虚线)','改进后(实线)'); grid on;
subplot(3,1,3); plot(t, Te_raw, 'k', t, Te_enh, 'm'); title('电磁转矩对比 (N·m)'); legend('原始','改进'); xlabel('时间 (s)'); grid on;