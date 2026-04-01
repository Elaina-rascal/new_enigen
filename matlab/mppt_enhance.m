function [Te, debug1, debug2] = mppt_enhance_pi(Wg)
    % 核心逻辑：
    % 1. 变 K_opt：在 [W_gbgn, Wk_max] 之间线性插值，从 0.0325 变到 0.0525。
    % 2. 加速段 (dw > 0)：累积积分项，用于计算减载量 T_pi。
    % 3. 保护机制：2s窗口加速度判定，若持续减速则清空积分。
    % 4. 动态限幅：转矩锁定在 Te_base 的 (1±a) 倍。

    % --- 1. 状态存储 ---
    persistent error_integral Wg_old decel_timer sum_dw;
    if isempty(error_integral)
        error_integral = 0;
        Wg_old = Wg;
        decel_timer = 0;
        sum_dw = 0;
    end

    % --- 2. 核心参数 ---
    W_gbgn = 53;         % 起转转速
    Wk_max = 90;         % 变系数终止转速
    K_start = 0.0425;    % 起始 K 值
    K_end = 0.0425;      % 终止 K 值
    
    dt = 0.01;           
    T_window = 2.0;      
    Kp = 10;              
    Ki = 0;            
    a = 0.3;             

    % --- 3. 计算变系数 K_opt (线性插值) ---
    if Wg <= W_gbgn
        K_opt = K_start;
    elseif Wg >= Wk_max
        K_opt = K_end;
    else
        % 在 [53, 80] 之间线性插值：y = y0 + (x - x0) * (y1 - y0) / (x1 - x0)
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
        decel_timer = 0;
        sum_dw = 0;
    else
        % A. 积分累加
        if dw > 0
            error_integral = error_integral + dw * dt;
        end

        % B. 减速判定
        if dw < 0
            decel_timer = decel_timer + dt;
            sum_dw = sum_dw + dw; 
        else
            decel_timer = 0;
            sum_dw = 0;
        end

        if decel_timer >= T_window
            if sum_dw < 0
                error_integral = 0; 
            end
            decel_timer = 0; 
            sum_dw = 0;
        end

        % C. 计算补偿与限幅
        error_integral = max(0, min(error_integral, 500)); 
        T_pi = Kp * dw + Ki * (error_integral);
        
        Te_raw = Te_base - T_pi;
        
        % D. 动态限幅
        Te_min = (1 - a) * Te_base;
        Te_max = (1 + a) * Te_base;
        Te_raw = max(Te_min, min(Te_raw, Te_max))-100;
    end

    % --- 7. 安全硬限幅 ---
    Te = max(0, min(Te_raw, 12000));

    % --- 8. 调试输出 ---
    debug1 = dw;             
    debug2 = error_integral; 
end