function [Te, debug1, debug2] = mppt_enhance_pi(Wg)
    % 核心逻辑修改：
    % 1. 去掉 2s 窗口定时器。
    % 2. 引入 dw_last，当 sign(dw) ~= sign(dw_last) 时，立即清空积分项。
    % 3. 保持原有的线性插值 K_opt 和动态限幅逻辑。
    % 4. 增加输出转矩变化率限制（Rate Limiter）。
    
    % --- 1. 状态存储 ---
    persistent error_integral Wg_old dw_last Te_old;
    if isempty(error_integral)
        error_integral = 0;
        Wg_old = Wg;
        dw_last = 0; % 初始化上一次加速度
        Te_old = 0;  % 初始化上一时刻转矩
    end
    
    % --- 2. 核心参数 ---
    W_gbgn = 56;          % 起转转速
    Wk_max = 80;          % 变系数终止转速
    K_start = 0.0425;     % 起始 K 值
    K_end = 0.0625;       % 终止 K 值
    
    dt = 0.05;            
    Kp = 0;               
    Ki = 5;              
    a = 0.5;              
    
    % --- 变化率限制参数 ---
    max_dTe_dt = 500;    % 最大允许变化率 (Nm/s)，根据实际需求调整
    max_step = max_dTe_dt * dt; % 每个采样周期的最大变化步长
    
    % --- 3. 计算变系数 K_opt ---
    if Wg <= W_gbgn
        K_opt = K_start;
    elseif Wg >= Wk_max
        K_opt = K_end;
    else
        K_opt = K_start + (Wg - W_gbgn) * (K_end - K_start) / (Wk_max - W_gbgn);
        K_opt=K_start;
    end
    
    % --- 4. 计算加速度 dw ---
    dw = (Wg - Wg_old) / dt;
    Wg_old = Wg;
    
    % --- 5. 基础转矩 (标准 OTC) ---
    Te_base = K_opt * (Wg^2);
    
    % --- 6. 逻辑判断与积分器控制 ---
    if Wg < W_gbgn
        Te_raw = 0;
        error_integral = 0;
    else
        % --- 关键修改：变号判定清零 ---
        if sign(dw) ~= sign(dw_last) && dw_last ~= 0
            error_integral = 0;
        end
        
        % 积分累加逻辑
        error_integral = error_integral + dw * dt;
        
        % 限制积分范围
        error_integral = max(0, min(error_integral, 500)); 
        
        % 计算补偿项
        T_pi = Kp * dw + Ki * error_integral;
        
        Te_raw = Te_base - T_pi;
        
        % 动态限幅
        Te_min = (1 - a) * Te_base;
        Te_max = (1 + a) * Te_base;
        Te_raw = max(Te_min, min(Te_raw, Te_max));
    end
    
    % --- 7. 更新状态变量 ---
    dw_last = dw; 
    
    % --- 8. 安全硬限幅与变化率限制 ---
    Te_temp = max(0, min(Te_raw, 12000));
    
    % 核心修改：转矩变化率限制 (Rate Limiter)
    Te = max(Te_old - max_step, min(Te_temp, Te_old + max_step));
    Te_old = Te; % 更新历史转矩
    
    debug1 = dw;              
    debug2 = error_integral;  
end