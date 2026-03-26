%% 对比可视化脚本：基础版本 vs 改进版本
% 本脚本用于在同一图上可视化两个版本的MPPT数据

clear; close all; clc;

%% 数据定义说明
% 列1：运行时间（ms）
% 列2：电磁转矩实际值（百分数）
% 列3：风速（m/s）
% 列4：电磁转矩指令值百分数
% 列5：高速侧转速（rpm）
% 列6：Cp值

%% 加载数据
data_raw = readmatrix('Wind1Var基础.txt');      % 基础版本
data_enhance = readmatrix('Wind1Var改进.txt');  % 改进版本

%% 数据提取（保持原单位，不进行转换）
% 基础版本
idx_raw = (1:length(data_raw))';
torque_actual_raw = data_raw(:, 2);      % 电磁转矩实际值
windspeed_raw = data_raw(:, 3);          % 风速
torque_cmd_raw = data_raw(:, 4);         % 电磁转矩指令值
rotspeed_raw = data_raw(:, 5);           % 高速侧转速
cp_raw = data_raw(:, 6);                 % Cp值

% 改进版本
idx_enhance = (1:length(data_enhance))';
torque_actual_enhance = data_enhance(:, 2);   % 电磁转矩实际值
windspeed_enhance = data_enhance(:, 3);       % 风速
torque_cmd_enhance = data_enhance(:, 4);      % 电磁转矩指令值
rotspeed_enhance = data_enhance(:, 5);        % 高速侧转速
cp_enhance = data_enhance(:, 6);              % Cp值

%% 可视化
figure('Name', 'MPPT性能对比：基础版本 vs 改进版本', 'NumberTitle', 'off', 'Position', [100 100 1400 1000]);

% 子图1：电磁转矩实际值对比
subplot(3,2,1);
plot(idx_raw, torque_actual_raw, 'b-', 'LineWidth', 1.5, 'DisplayName', '基础版本');
hold on;
plot(idx_enhance, torque_actual_enhance, 'r--', 'LineWidth', 1.5, 'DisplayName', '改进版本');
xlabel('数据点编号', 'FontSize', 10);
ylabel('电磁转矩实际值', 'FontSize', 10);
title('(a) 电磁转矩实际值对比', 'FontSize', 11, 'FontWeight', 'bold');
legend('FontSize', 9);
grid on;

% 子图2：风速对比
subplot(3,2,2);
plot(idx_raw, windspeed_raw, 'b-', 'LineWidth', 1.5, 'DisplayName', '基础版本');
hold on;
plot(idx_enhance, windspeed_enhance, 'r--', 'LineWidth', 1.5, 'DisplayName', '改进版本');
xlabel('数据点编号', 'FontSize', 10);
ylabel('风速 (m/s)', 'FontSize', 10);
title('(b) 风速对比', 'FontSize', 11, 'FontWeight', 'bold');
legend('FontSize', 9);
grid on;

% 子图3：电磁转矩指令值对比
subplot(3,2,3);
plot(idx_raw, torque_cmd_raw, 'b-', 'LineWidth', 1.5, 'DisplayName', '基础版本');
hold on;
plot(idx_enhance, torque_cmd_enhance, 'r--', 'LineWidth', 1.5, 'DisplayName', '改进版本');
xlabel('数据点编号', 'FontSize', 10);
ylabel('电磁转矩指令值', 'FontSize', 10);
title('(c) 电磁转矩指令值对比', 'FontSize', 11, 'FontWeight', 'bold');
legend('FontSize', 9);
grid on;

% 子图4：高速侧转速对比
subplot(3,2,4);
plot(idx_raw, rotspeed_raw, 'b-', 'LineWidth', 1.5, 'DisplayName', '基础版本');
hold on;
plot(idx_enhance, rotspeed_enhance, 'r--', 'LineWidth', 1.5, 'DisplayName', '改进版本');
xlabel('数据点编号', 'FontSize', 10);
ylabel('高速侧转速 (rpm)', 'FontSize', 10);
title('(d) 高速侧转速对比', 'FontSize', 11, 'FontWeight', 'bold');
legend('FontSize', 9);
grid on;

% 子图5：Cp值对比
subplot(3,2,5);
plot(idx_raw, cp_raw, 'b-', 'LineWidth', 1.5, 'DisplayName', '基础版本');
hold on;
plot(idx_enhance, cp_enhance, 'r--', 'LineWidth', 1.5, 'DisplayName', '改进版本');
xlabel('数据点编号', 'FontSize', 10);
ylabel('Cp值', 'FontSize', 10);
title('(e) Cp值对比', 'FontSize', 11, 'FontWeight', 'bold');
legend('FontSize', 9);
grid on;

% 子图6：转矩指令值与实际值误差对比
subplot(3,2,6);
error_raw = torque_actual_raw - torque_cmd_raw;
error_enhance = torque_actual_enhance - torque_cmd_enhance;
plot(idx_raw, error_raw, 'b-', 'LineWidth', 1.5, 'DisplayName', '基础版本');
hold on;
plot(idx_enhance, error_enhance, 'r--', 'LineWidth', 1.5, 'DisplayName', '改进版本');
xlabel('数据点编号', 'FontSize', 10);
ylabel('转矩误差（实际-指令）', 'FontSize', 10);
title('(f) 转矩控制误差对比', 'FontSize', 11, 'FontWeight', 'bold');
legend('FontSize', 9);
grid on;

sgtitle('MPPT性能对比：基础版本 vs 改进版本', 'FontSize', 13, 'FontWeight', 'bold');

%% 统计信息输出
fprintf('\n========== 数据统计对比 ==========\n');
fprintf('\n【基础版本】\n');
fprintf('  数据点数: %d\n', length(data_raw));
fprintf('  平均转矩实际值: %.2f\n', mean(torque_actual_raw));
fprintf('  平均风速: %.2f m/s\n', mean(windspeed_raw));
fprintf('  平均转矩指令值: %.2f\n', mean(torque_cmd_raw));
fprintf('  平均转速: %.2f rpm\n', mean(rotspeed_raw));
fprintf('  平均Cp: %.4f\n', mean(cp_raw));

fprintf('\n【改进版本】\n');
fprintf('  数据点数: %d\n', length(data_enhance));
fprintf('  平均转矩实际值: %.2f\n', mean(torque_actual_enhance));
fprintf('  平均风速: %.2f m/s\n', mean(windspeed_enhance));
fprintf('  平均转矩指令值: %.2f\n', mean(torque_cmd_enhance));
fprintf('  平均转速: %.2f rpm\n', mean(rotspeed_enhance));
fprintf('  平均Cp: %.4f\n', mean(cp_enhance));

fprintf('\n【性能对比】\n');
torque_improvement = (mean(torque_actual_enhance) - mean(torque_actual_raw)) / mean(torque_actual_raw) * 100;
cp_improvement = (mean(cp_enhance) - mean(cp_raw)) / mean(cp_raw) * 100;
fprintf('  转矩改善: %.2f %%\n', torque_improvement);
fprintf('  Cp改善: %.2f %%\n', cp_improvement);
fprintf('\n===================================\n');
