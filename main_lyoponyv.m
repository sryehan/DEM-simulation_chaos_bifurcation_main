clc; clear; close all;

% ==========================================
% ১. সেটিংস (নতুন ফাইলের নাম)
% ==========================================
file_ref = 'dump.ref_chaos';
file_pert = 'dump.pert_chaos';
target_id = 50;          % মাঝখানের পার্টিকেল
time_conversion = 2e-6;  % 2 microseconds timestep

% ==========================================
% ২. ডাটা রিডিং
% ==========================================
fprintf('Reading Reference Data...\n');
[t_ref, v_ref] = read_lammps_velocity(file_ref, target_id, time_conversion);
fprintf('Reference Data Points: %d\n', length(t_ref));

fprintf('Reading Perturbed Data...\n');
[t_pert, v_pert] = read_lammps_velocity(file_pert, target_id, time_conversion);
fprintf('Perturbed Data Points: %d\n', length(t_pert));

if isempty(t_ref) || isempty(t_pert)
    error('❌ ডাটা পাওয়া যায়নি!');
end

% ==========================================
% ৩. ক্যালকুলেশন
% ==========================================
% ডাটা সাইজ ম্যাচ করানো
n = min(length(t_ref), length(t_pert));
time = t_ref(1:n);
v1 = v_ref(1:n);
v2 = v_pert(1:n);

% Velocity Difference
delta_v = abs(v1 - v2);

% Zero handling (avoid log(0))
min_val = min(delta_v(delta_v > 0));
if isempty(min_val)
    min_val = 1e-20;
end
delta_v(delta_v == 0) = min_val;

ln_delta_v = log(delta_v);

% ==========================================
% ৪. লিনিয়ার ফিটিং
% ==========================================
% প্রথম 0.5 সেকেন্ড বাদ (transient phase)
fit_start = 0.5;
fit_end = max(time);

mask = (time >= fit_start) & (time <= fit_end);

if sum(mask) > 10
    p = polyfit(time(mask), ln_delta_v(mask), 1);
    lambda = p(1);  % Lyapunov Exponent
    intercept = p(2);
    fit_line = polyval(p, time(mask));
    
    % R-squared calculation
    y_resid = ln_delta_v(mask) - fit_line;
    SSresid = sum(y_resid.^2);
    SStotal = (length(ln_delta_v(mask))-1) * var(ln_delta_v(mask));
    r_sq = 1 - SSresid/SStotal;
    
    fprintf('\n=================================\n');
    fprintf('Lyapunov Exponent (λ): %.6f\n', lambda);
    fprintf('R-squared: %.4f\n', r_sq);
    fprintf('Total Simulation Time: %.2f seconds\n', max(time));
    fprintf('=================================\n');
else
    lambda = 0;
    r_sq = 0;
    fit_line = [];
    warning('ফিটিং রেঞ্জে পর্যাপ্ত ডাটা নেই!');
end

% ==========================================
% ৫. গ্রাফ প্লট
% ==========================================
figure('Color', 'w', 'Position', [100, 100, 900, 600]);
hold on; box on;

% মেইন ডাটা
plot(time, ln_delta_v, 'Color', [0.2, 0.4, 0.8], 'LineWidth', 1.5, ...
    'DisplayName', 'ln|\Delta v_x|');

% ফিটিং লাইন
if ~isempty(fit_line)
    plot(time(mask), fit_line, 'r--', 'LineWidth', 2.5, ...
        'DisplayName', sprintf('Fit (λ = %.4f s^{-1})', lambda));
    
    % হাইলাইট করা রিজিয়ন
    yl = ylim;
    patch([fit_start, fit_end, fit_end, fit_start], ...
          [yl(1), yl(1), yl(2), yl(2)], ...
          'y', 'FaceAlpha', 0.1, 'EdgeColor', 'none', ...
          'DisplayName', 'Linear Region');
end

xlabel('Time (s)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('ln|\Delta v_x|', 'FontSize', 14, 'FontWeight', 'bold');
title('Lyapunov Exponent Analysis (Chaotic System)', ...
    'FontSize', 16, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 12, 'LineWidth', 1.2);

% টেক্সট বক্স
dim = [0.15 0.8 0.2 0.1];
str = {sprintf('λ = %.6f s^{-1}', lambda), ...
       sprintf('R^2 = %.4f', r_sq)};
annotation('textbox', dim, 'String', str, 'FitBoxToText', 'on', ...
    'BackgroundColor', 'w', 'FaceAlpha', 0.9, 'EdgeColor', 'k', ...
    'FontSize', 11);

% ==========================================
% হেল্পার ফাংশন
% ==========================================
function [times, vels] = read_lammps_velocity(fname, target_id, dt)
    times = []; 
    vels = [];
    
    if ~isfile(fname)
        fprintf('ফাইল নেই: %s\n', fname);
        return;
    end
    
    fid = fopen(fname, 'r');
    if fid == -1
        fprintf('ফাইল ওপেন করা যায়নি: %s\n', fname);
        return;
    end
    
    current_time = 0;
    
    while ~feof(fid)
        line = fgetl(fid);
        
        % টাইমস্টপ পড়া
        if contains(line, 'ITEM: TIMESTEP')
            step_line = fgetl(fid);
            step = str2double(step_line);
            current_time = step * dt;
        end
        
        % এটম ডাটা পড়া
        if contains(line, 'ITEM: ATOMS')
            % সাধারণত: id vx (2 কলাম)
            while ~feof(fid)
                pos = ftell(fid);
                data_line = fgetl(fid);
                
                % পরের সেকশন শুরু হলে থামা
                if contains(data_line, 'ITEM:')
                    fseek(fid, pos, 'bof');
                    break;
                end
                
                % ডাটা পার্স করা
                vals = sscanf(data_line, '%f');
                if length(vals) >= 2
                    atom_id = vals(1);
                    vx = vals(2);
                    
                    if atom_id == target_id
                        times = [times; current_time];
                        vels = [vels; vx];
                        break; % এই টাইমস্টেপে টার্গেট পাওয়া গেলে থামা
                    end
                end
            end
        end
    end
    
    fclose(fid);
    
    % NaN ভ্যালু রিমুভ করা
    valid_idx = ~isnan(times) & ~isnan(vels);
    times = times(valid_idx);
    vels = vels(valid_idx);
end