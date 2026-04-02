function [Te, K_opt,debug2] = mppt_enhance_pi(Wg)
    % 核心逻辑：仅保留变系数 K_opt 计算
    
    % --- 1. 状态存储 ---
    persistent Wg_old;
    if isempty(Wg_old)
        Wg_old = Wg;
    end
    
    % --- 2. 核心参数 ---
    W_gbgn = 60;          % 起转转速
    Wk_max = 95;          % 变系数终止转速
    K_start = 0.0225;     % 起始 K 值
    K_end = 0.0525;       % 终止 K 值
    
    % --- 3. 计算变系数 K_opt (线性插值) ---
    if Wg <= W_gbgn
        K_opt = K_start;
    elseif Wg >= Wk_max
        K_opt = K_end;
    else
        % 在 W_gbgn 到 Wk_max 之间进行线性插值
        K_opt = K_start + (Wg - W_gbgn) * (K_end - K_start) / (Wk_max - W_gbgn);
    end
    
    % --- 4. 计算输出转矩 ---
    % 标准 OTC (Optimal Torque Control) 公式: Te = K * w^2
    if Wg < W_gbgn
        Te = 0;
    else
        Te = K_opt * (Wg^2);
    end
    
    % --- 5. 限制最大转矩 (安全限幅) ---
    Te = max(0, min(Te, 12000));
    
    % 更新历史状态
    Wg_old = Wg;
    debug2=0;
end