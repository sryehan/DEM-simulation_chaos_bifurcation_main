clc; clear; close all;

% ==========================================
% ১. সেটিংস
% ==========================================
filename = 'log.lammps'; % ল্যাম্পস লগ ফাইল

% ফাইল চেক
if ~isfile(filename)
    error('Error: %s ফাইলটি পাওয়া যাচ্ছে না! (in.ref রান করলে এটি তৈরি হবে)', filename);
end

% ==========================================
% ২. ডাটা রিড করা (log.lammps থেকে)
% ==========================================
fprintf('Reading energy data from %s...\n', filename);

steps = [];
etot = [];
reading_data = false;
idx_step = 0;
idx_etot = 0;

fid = fopen(filename, 'r');
while ~feof(fid)
    line = strtrim(fgetl(fid));
    
    % হেডার খোঁজা (যেখানে Step এবং TotEng আছে)
    if contains(line, 'Step') && contains(line, 'TotEng')
        parts = strsplit(line);
        % কলাম ইনডেক্স খুঁজে বের করা
        idx_step = find(contains(parts, 'Step'));
        idx_etot = find(contains(parts, 'TotEng'));
        
        if ~isempty(idx_step) && ~isempty(idx_etot)
            reading_data = true;
            steps = []; etot = []; % আগের রান থাকলে মুছে নতুন শুরু
            continue;
        end
    end
    
    % ডাটা পড়া শেষ হলে থামা
    if contains(line, 'Loop time')
        reading_data = false;
    end
    
    % ডাটা রিড করা
    if reading_data
        vals = str2num(line);
        if length(vals) >= max([idx_step, idx_etot])
            steps = [steps; vals(idx_step)];
            etot = [etot; vals(idx_etot)];
        end
    end
end
fclose(fid);

if isempty(etot)
    error('Error: লগ ফাইলে এনার্জি ডাটা পাওয়া যায়নি। আপনার in.ref ফাইলে "thermo_style custom ... etotal" আছে কিনা চেক করুন।');
end

% ==========================================
% ৩. ক্যালকুলেশন
% ==========================================
% Time conversion (timestep = 1e-6 ধরে)
time = steps * 0.000001; 

% Statistics
mean_E = mean(etot);
if mean_E == 0; mean_E = 1; end % Div by zero protection

% Relative Deviation (%)
rel_dev = ((etot - mean_E) / abs(mean_E)) * 100;

% Linear Drift (Slope)
p = polyfit(time, etot, 1);
slope = p(1);
drift_line = polyval(p, time);

% Max Deviation
max_dev = max(abs(rel_dev));

fprintf('Stats: Mean E = %.4e, Slope = %.2e, Max Dev = %.4f%%\n', mean_E, slope, max_dev);

% ==========================================
% ৪. গ্রাফ প্লট (Dual Subplot)
% ==========================================
figure('Color', 'w', 'Position', [100, 100, 800, 700]);

% --- Top Panel: Total Energy & Drift ---
subplot(2, 1, 1);
hold on;
plot(time, etot, 'Color', [0.2, 0.6, 0.8], 'LineWidth', 2, 'DisplayName', 'Total Energy (E_{tot})');
plot(time, drift_line, 'r--', 'LineWidth', 1.5, 'DisplayName', sprintf('Drift trend (slope=%.2e)', slope));
yline(mean_E, 'g--', 'LineWidth', 1.5, 'DisplayName', sprintf('Mean: %.4e', mean_E));

ylabel('Total Energy (E_{tot})', 'FontSize', 12, 'FontWeight', 'bold');
title('NVE Ensemble: Energy Conservation Analysis', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best');
grid on;
ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 0.5;

% Info Box
dim = [0.65 0.55 0.2 0.2];
str = {sprintf('Rel Drift: %.4f%%', max_dev), ...
       sprintf('Slope: %.2e', slope), ...
       sprintf('Mean E: %.3e', mean_E)};
annotation('textbox', dim, 'String', str, 'FitBoxToText', 'on', ...
    'BackgroundColor', 'w', 'FaceAlpha', 0.8, 'EdgeColor', 'k');

% --- Bottom Panel: Relative Deviation ---
subplot(2, 1, 2);
plot(time, rel_dev, 'Color', [0.6, 0.4, 0.8], 'LineWidth', 1.5, 'DisplayName', 'Relative Deviation');
yline(0, 'k--');

ylabel('Deviation \DeltaE / E (%)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Time (s)', 'FontSize', 12, 'FontWeight', 'bold');
title('Relative Energy Deviation from Mean', 'FontSize', 11, 'FontWeight', 'bold');
grid on;
ax = gca; ax.GridLineStyle = ':'; ax.GridAlpha = 0.5;

fprintf('Graph generated successfully!\n');