function [Te, Ta, debug] = mppt_enhance(Wg)
    persistent prev_Wg Te_smooth acc_filt is_initialized
    
    % --- 1. 参数定义 ---
    dt = 0.05; 
    i_ratio = 43; 
    K_opt = 0.026;    
    J_HSS = 504740 / (i_ratio^2); 
    
    % 新增：最小工作转速 (例如设定为 60 rad/s，根据实际机组切入转速调整)
    % 低于此转速时，发电机卸载，允许风轮空转加速
    Wg_min = 60; 
    
    if isempty(is_initialized)
        prev_Wg = Wg;
        Te_smooth = K_opt * (Wg^2);
        acc_filt = 0;
        is_initialized = true;
    end
    
    % --- 2. 信号处理 ---
    d_Wg_raw = (Wg - prev_Wg) / dt;
    alpha_acc = 0.15; 
    acc_filt = (1 - alpha_acc) * acc_filt + alpha_acc * d_Wg_raw;
    
    % --- 3. 基础理想转矩与最小风速逻辑 ---
    if Wg < Wg_min
        % 情况 C: 转速低于切入阈值
        % 这种情况下，我们要让转矩尽快归零，给风轮加速空间
        Te_ideal = 0;
        K_acc_local = 0; % 在启动阶段关闭补偿，避免加速度噪声干扰
        K_acc_dec=0.0;
    else
        % 情况 D: 正常 MPPT 区
        Te_ideal = K_opt * (Wg^2);
        K_acc_local = 0.4; 
        K_acc_dec=0.0;
    end
    
    % --- 4. 动态补偿逻辑 ---
    compensation = 0;
    
    % 仅在正常工作区进行动态补偿
    if Wg >= Wg_min
        if acc_filt < 0
            % 转速下降 -> 减少转矩 (正反馈救速)
            compensation = K_acc_dec * J_HSS * acc_filt; 
        elseif acc_filt > 0
            % 转速上升 -> 增加转矩 (T_acc 提取)
            compensation = K_acc_local * J_HSS * acc_filt; 
        end
        
        % 安全限幅 (30% 限制)
        max_comp = 0.5 * Te_ideal; 
        compensation = max(-max_comp, min(compensation, max_comp));
    end
    
    % 计算原始目标值
    Te_raw = Te_ideal + compensation; 
    
    % --- 5. 平滑处理与输出 ---
    % 当处于切入转速边缘时，平滑系数可以略微调大，保证切入平稳
    alpha_te = 0.4; 
    Te_smooth = (1 - alpha_te) * Te_smooth + alpha_te * Te_raw;
    
    Ta = 0;
    % 额定转矩限幅
    Te = max(0, min(Te_smooth, 12000));
    
    % --- 6. 状态更新与 Debug ---
    prev_Wg = Wg;
    debug = compensation; 
end