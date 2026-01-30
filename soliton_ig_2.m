clc; clear; close all;

% ==========================================
% ১. সেটিংস
% ==========================================
filename = 'dump.soliton_final'; 
target_time = 0.0025; % 2.5ms (Wave মাঝখানে থাকার কথা)

% ==========================================
% ২. ডাটা রিড করা (Specific Snapshot)
% ==========================================
fid = fopen(filename, 'r');
atom_ids = [];
ke = [];
found_time = -1;
min_diff = inf;

fprintf('Searching for snapshot at t = %.4f s...\n', target_time);

while ~feof(fid)
    line = fgetl(fid);
    if contains(line, 'ITEM: TIMESTEP')
        step = str2double(fgetl(fid));
        time = step * 1e-7; % Timestep 1e-7 used in python script
        
        if abs(time - target_time) < min_diff
            min_diff = abs(time - target_time);
            found_time = time;
            
            for k=1:7; fgetl(fid); end % Skip header
            
            % Read Atoms
            temp_ids = []; temp_vx = [];
            while ~feof(fid)
                pos = ftell(fid); line = fgetl(fid);
                if contains(line, 'ITEM:'), fseek(fid, pos, 'bof'); break; end
                val = sscanf(line, '%f %f %f'); % id x vx
                if length(val) >= 3
                    temp_ids = [temp_ids; val(1)];
                    temp_vx = [temp_vx; val(3)];
                end
            end
            
            % Sort by ID (Spatial order)
            [atom_ids, idx] = sort(temp_ids);
            ke = 0.5 * 1 * (temp_vx(idx)).^2; % Mass = 1 (normalized) or real mass
        else
            for k=1:7; fgetl(fid); end
            while ~feof(fid)
                pos = ftell(fid); line = fgetl(fid);
                if contains(line, 'ITEM:'), fseek(fid, pos, 'bof'); break; end
            end
        end
    end
end
fclose(fid);

if isempty(atom_ids)
    error('Target time এর ডাটা পাওয়া যায়নি। run time বাড়ান বা target_time কমান।');
end

% ==========================================
% ৩. Analytical Fit (Bell-Shaped Soliton)
% ==========================================
% Model: A * sech((x-x0)/w)^2
ft = fittype('A * (sech((x-x0)/w))^2', 'independent', 'x', 'coefficients', {'A', 'x0', 'w'});

[max_ke, max_idx] = max(ke);
start_points = [max_ke, atom_ids(max_idx), 2.0];

% Fitting
[fitresult, gof] = fit(atom_ids, ke, ft, 'StartPoint', start_points);
ke_analytical = fitresult(atom_ids);
rmse = gof.rmse;

% ==========================================
% ৪. গ্রাফ প্লট (Figure 18 Style)
% ==========================================
figure('Color', 'w', 'Position', [100, 100, 800, 600]);

% Top Panel: Profile
subplot(3, 1, [1 2]);
hold on;
plot(atom_ids, ke, 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'r', 'DisplayName', 'DEM Simulation');
plot(atom_ids, ke_analytical, 'b-', 'LineWidth', 2, 'DisplayName', 'Analytical (Eq. 3.3.16)');
fill(atom_ids, ke_analytical, 'b', 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'HandleVisibility', 'off');

title(sprintf('Soliton Profile Validation at t=%.4f s', found_time), 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Kinetic Energy (E_k)', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'northeast'); grid on;

% Stats Box
dim = [0.15 0.6 0.2 0.2];
str = {sprintf('R^2 = %.4f', gof.rsquare), ...
       sprintf('RMSE = %.4f', rmse), ...
       sprintf('Width (w) = %.2f', fitresult.w)};
annotation('textbox', dim, 'String', str, 'FitBoxToText', 'on', 'BackgroundColor', 'w');

% Bottom Panel: Residuals
subplot(3, 1, 3);
plot(atom_ids, ke - ke_analytical, 'g-', 'LineWidth', 1.5);
yline(0, 'k--');
xlabel('Atom Index', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Residuals', 'FontSize', 10, 'FontWeight', 'bold');
grid on;

fprintf('Graph Generated! Check figure window.\n');