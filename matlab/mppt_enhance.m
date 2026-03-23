function [Te, Ta_estout,debug] = mppt_enhance(Wg)
    % 修正版：考虑齿轮箱变比的 Ta 观测器
    % Wg: 发电机转速 (rad/s)
    % Te: 发电机电磁转矩 (N·m)
    
    persistent prev_Wg prev_Te Ta_est
    dt = 0.05; 
    i_ratio = 43; % 减速比
    
    % --- 1. 参数定义 ---
    K_opt = 0.0626;    
    % 重要：如果 504740 是风轮侧惯量，折算到发电机侧需除以 i^2
    J_LSS = 504740; 
    J_HSS = J_LSS / (i_ratio^2); % 折算后的等效惯量
    
    L_obs = 0.5;       
    W_gbgn = 56;       
    
    if isempty(prev_Wg)
        prev_Wg = Wg;
        prev_Te = 0;
        Ta_est = K_opt * (Wg^2); 
    end
    
    % --- 2. 机械转矩 (Ta) 观测器 (在发电机轴侧进行计算) ---
    % 此时观测到的是“折算到高速轴的机械转矩”
    d_Wg = (Wg - prev_Wg) / dt;
    Ta_HSS_instant = J_HSS * d_Wg + prev_Te; 
    Ta_est = (1 - L_obs) * Ta_est + L_obs * Ta_HSS_instant;
    
    % --- 3. 计算最优转矩与补偿 ---
    Te_ideal = K_opt * (Wg^2);
    delta_Wg = Wg - prev_Wg;
    
    if Wg < W_gbgn
        Te_raw = 0;
    else
        if delta_Wg > 0
            % 【上升阶段】
            K_acc_gain = 1.0; % 既然有了准确的观测，可以适当调大补偿
            % 如果 Ta_est > Te_ideal，说明风能输入大于当前发电机吸收，支持加速
            Te_raw = Te_ideal - K_acc_gain * (Ta_est - Te_ideal);
        else
            % 【下降阶段】
            fall_rate = 0.95; 
            Te_raw = prev_Te * fall_rate + Te_ideal * (1 - fall_rate);
        end
    end
    
    % --- 4. 限幅与更新 ---
    Te = max(0, min(Te_raw, 12000));
    
    % 如果你想输出风轮端的实际转矩 Ta，则需要乘以 i_ratio
    Ta_estout = Ta_est * i_ratio; 
    
    prev_Wg = Wg;
    prev_Te = Te;
    debug=Ta_est-Te_ideal;
end