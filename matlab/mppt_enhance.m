function [Te, debug1, debug2] = mppt_enhance_pi(Wg)
    % 核心逻辑：
    % 1. 加速段 (dw > 0)：累积积分项，用于计算减载量 T_pi。
    % 2. 减速段 (dw < 0)：不累积积分，并启动 2s 定时器。
    % 3. 保护机制：若 2s 内累计加速度为负，清零积分，恢复标准 OTC。

    % --- 1. 状态存储 ---
    persistent error_integral Wg_old decel_timer sum_dw;
    if isempty(error_integral)
        error_integral = 0;
        Wg_old = Wg;
        decel_timer = 0; % 减速计时器 (秒)
        sum_dw = 0;      % 2s窗口内的加速度累加值
    end

    % --- 2. 核心参数 ---
    W_gbgn = 55;      
    K_opt = 0.0526;   
    dt = 0.01;           % 仿真步长
    T_window = 2.0;      % 减速判定窗口时长
    
    Kp = 0;              
    Ki = 3.2;            

    % --- 3. 计算加速度 dw ---
    dw = (Wg - Wg_old) / dt;
    Wg_old = Wg;

    % --- 4. 基础转矩 ---
    Te_base = K_opt * (Wg^2);

    % --- 5. 逻辑判断与积分器控制 ---
    if Wg < W_gbgn
        Te_raw = 0;
        error_integral = 0;
        decel_timer = 0;
        sum_dw = 0;
    else
        % --- A. 积分累加逻辑 ---
        if dw > 0
            % 仅在加速时累积积分（误差为 dw）
            error_integral = error_integral + dw * dt;
        end

        % --- B. 减速判定逻辑 (2s 定时器) ---
        if dw < 0
            decel_timer = decel_timer + dt;
            sum_dw = sum_dw + dw; % 记录减速的“剧烈程度”
        else
            % 如果当前在加速，可以考虑缓慢重置定时器或直接清零
            decel_timer = 0;
            sum_dw = 0;
        end

        % 如果持续减速达到 2 秒，且总趋势确实是下降的
        if decel_timer >= T_window
            if sum_dw < 0
                error_integral = 0; % 【关键】清零积分，恢复基础转矩
            end
            decel_timer = 0; % 重置窗口
            sum_dw = 0;
        end

        % --- C. 计算补偿转矩 ---
        error_integral = max(0, min(error_integral, 500)); % 确保补偿不为负
        
        % 根据你之前的公式：Ki * error_integral^2
        T_pi = Kp * dw + Ki * (error_integral);
        
        Te_raw = Te_base - T_pi;
    end

    % --- 6. 安全限幅 ---
    Te = max(0, min(Te_raw, 12000));

    % --- 7. 调试输出 ---
    debug1 = dw;             
    debug2 = error_integral; % 观察积分项在 2s 后的复位情况
end