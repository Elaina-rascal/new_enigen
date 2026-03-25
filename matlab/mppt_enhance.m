function [Te,debug1,debug2] = mppt_enhance(Wg)
    % 改进版：基于转速区间的“加速空间预留”法
    % 思路：在低转速段主动降低转矩，预留加速度空间，利用二次函数实现低速段“减载”更多
    
    % --- 1. 核心参数 ---
    W_gbgn = 53;      % 切入转速
    K_opt = 0.0626;   % 标准最优转矩系数
    
    % --- 2. 空间预留参数 (关键调优区) ---
    W_high_limit = 120;   % 加速空间作用上限 (rad/s)
    % 减载深度系数 (0~1)，值越大，低速时转矩减得越多，加速空间越大
    K_space = 0.4;       
    
    % --- 3. 基础转矩计算 ---
    Te_base = K_opt * (Wg^2);
    
    % --- 4. 预留空间逻辑 (不依赖加速度) ---
    if Wg < W_gbgn
        Te_raw = 0;
    elseif Wg < W_high_limit
        % 定义归一化的转速位置 (0 at W_gbgn, 1 at W_high_limit)
        % x 越小（转速越低），加速空间需求越大
        x = (W_high_limit - Wg) / (W_high_limit - W_gbgn);
        
        % 使用二次函数构造减载比例：Ratio = K_space * x^2
        % 这样在转速较小时(x靠近1)，减载量很大；随着转速升高，减载量迅速平滑消失
        reduction_ratio = K_space * (x^2);
        
        % 最终转矩 = 基础转矩 * (1 - 减载比例)
        Te_raw = Te_base * (1 - reduction_ratio);
    else
        % 超过上限后，完全恢复到标准 OTC 曲线
        Te_raw = Te_base;
    end
    
    % --- 5. 安全限幅 ---
    Te = max(0, min(Te_raw, 12000));
    
    % --- 6. 调试输出 ---
    debug1 = Te_base;             % 原始 OTC 指令
    debug2 = Te_base - Te_raw;    % 预留出来的转矩空间 (N·m)
end