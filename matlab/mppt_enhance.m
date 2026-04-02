function [Te, debug1, debug2] = mppt_enhance_pi(Wg)
    % 核心逻辑修改：
    % 1. 去掉 2s 窗口定时器。
    % 2. 引入 dw_last，当 sign(dw) ~= sign(dw_last) 时，立即清空积分项。
    % 3. 保持原有的线性插值 K_opt 和动态限幅逻辑。

    % --- 1. 状态存储 ---
    persistent error_integral Wg_old dw_last;
    if isempty(error_integral)
        error_integral = 0;
        Wg_old = Wg;
        dw_last = 0; % 初始化上一次加速度
    end

    % --- 2. 核心参数 ---
    W_gbgn = 56;         % 起转转速
    Wk_max = 85;         % 变系数终止转速
    K_start = 0.0325;    % 起始 K 值
    K_end = 0.0625;      % 终止 K 值
    
    dt = 0.05;           
    Kp = 0;              
    Ki = 10;              % 注意：当前 Ki 为 0，积分项在计算 T_pi 时实际上不起作用，除非后续修改参数
    a = 0.5;             

    % --- 3. 计算变系数 K_opt ---
    if Wg <= W_gbgn
        K_opt = K_start;
    elseif Wg >= Wk_max
        K_opt = K_end;
    else
        K_opt = K_start + (Wg - W_gbgn) * (K_end - K_start) / (Wk_max - W_gbgn);
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
        % 如果当前加速度与上一时刻方向不同（即发生转折），清空积分
        if sign(dw) ~= sign(dw_last) && dw_last ~= 0
            error_integral = 0;
        end
        
        % 积分累加逻辑（仅在加速段累加）
        
        error_integral = error_integral + dw * dt;
        

        % 限制积分范围
        error_integral = max(0, min(error_integral, 500)); 
        
        % 计算补偿项
        T_pi = Kp * dw + Ki * error_integral;
        
        Te_raw = Te_base - T_pi;
        
        % 动态限幅
        Te_min = (1 - a) * Te_base;
        Te_max = (1 + a) * Te_base;
        Te_raw = max(Te_min, min(Te_raw, Te_max)) ;
    end

    % --- 7. 更新状态变量 ---
    dw_last = dw; 

    % --- 8. 安全硬限幅与输出 ---
    Te = max(0, min(Te_raw, 12000));
    debug1 = dw;             
    debug2 = error_integral; 
end