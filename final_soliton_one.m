clc; clear; close all;

% ==========================================
% 1. DATA EXTRACTION (From your dump file)
% ==========================================
filename = 'dump.soliton_final'; % আপনার ফাইলের নাম
target_atom_min = 40; 
target_atom_max = 60;

fid = fopen(filename, 'r');
if fid == -1, error('ফাইল পাওয়া যাচ্ছে না! run_soliton_final_lj.py রান করেছেন?'); end

found = false; best_time = -1; atom_ids = []; ke = [];
fprintf('Reading data...\n');

while ~feof(fid)
    line = fgetl(fid);
    if contains(line, 'ITEM: TIMESTEP')
        step = str2double(fgetl(fid));
        time = step;
        for k=1:7; fgetl(fid); end % Header skip
        
        temp_data = [];
        while ~feof(fid)
            pos = ftell(fid); line = fgetl(fid);
            if contains(line, 'ITEM:'), fseek(fid, pos, 'bof'); break; end
            vals = sscanf(line, '%f %f %f %f');
            if length(vals)>=3, temp_data = [temp_data; vals(1), vals(3)]; end
        end
        
        if ~isempty(temp_data)
            [sorted_ids, idx] = sort(temp_data(:,1));
            vels = temp_data(idx, 2);
            current_ke = 0.5 * 1.0 * vels.^2;
            [max_e, max_idx] = max(current_ke);
            peak_atom = sorted_ids(max_idx);
            
            if peak_atom >= target_atom_min && peak_atom <= target_atom_max
                atom_ids = sorted_ids; 
                ke = current_ke; 
                best_time = time; 
                found = true; 
                break;
            end
        end
    end
end
fclose(fid);

if ~found, error('Peak not found in target range.'); end

% ==========================================
% 2. ANALYTICAL SOLUTION (Equation 3.3.16)
% ==========================================

% --- Parameters form your text ---
sigma = 1;
mu = -0.051;
theta0 = 30;
eps0 = -1;
phi1 = 0;
rho1 = 0.5;

% Calculation helper
sqrt_minus_mu = sqrt(-mu); % sqrt(5) approx 2.236

% We create a high-resolution x axis for smooth curve
x_smooth = linspace(min(atom_ids), max(atom_ids), 1000);

% Find the peak position of simulation to center the analytical curve
[max_sim_ke, max_sim_idx] = max(ke);
x0 = atom_ids(max_sim_idx); % Center of the wave (s = x - x0)

% s represents the wave coordinate (x - vt or x - x0)
s = x_smooth - x0; 

% --- Implementing Eq (3.3.16) Exactly ---
% Numerator
num = -eps0 * sqrt_minus_mu * tanh(sqrt_minus_mu * s) + phi1;
% Denominator
den = -theta0 * sqrt_minus_mu * tanh(sqrt_minus_mu * s) + rho1;

% Raw Analytical Curve
S_raw = num ./ den;

% --- AMPLITUDE MATCHING (SCALING) ---
% Since S_raw represents the wave solution, we scale its absolute peak
% to match your simulation's kinetic energy peak.
S_raw_abs = abs(S_raw); % Use absolute if wave can be negative
scale_factor = max_sim_ke / max(S_raw_abs);
S_scaled = S_raw_abs * scale_factor;

% ==========================================
% 3. PLOTTING (Professional Style)
% ==========================================
figure('Color', 'w', 'Position', [100, 100, 900, 600]);
hold on; box on;

% -- Plot 1: Simulation Data (Red Dots) --
hSim = plot(atom_ids, ke, 'ro', 'MarkerSize', 7, 'MarkerFaceColor', 'r', ...
    'DisplayName', 'DEM Simulation');

% -- Plot 2: Analytical Solution (Blue Line) --
hAna = plot(x_smooth, S_scaled, 'b-', 'LineWidth', 2.5, ...
    'DisplayName', 'Analytical (Eq. 3.3.16)');

% Fill area for beauty
fill(x_smooth, S_scaled, 'b', 'FaceAlpha', 0.1, 'EdgeColor', 'none', ...
    'HandleVisibility', 'off');

% Labels and Title
xlabel('Atom Index ($x$)', 'Interpreter', 'latex', 'FontSize', 16, 'FontWeight', 'bold');
ylabel('Energy (Scaled)', 'Interpreter', 'latex', 'FontSize', 16, 'FontWeight', 'bold');
title(sprintf('Validation with Eq. 3.3.16 ($\\mu$=%d, $\\vartheta_0$=%d)', mu, theta0), ...
    'Interpreter', 'latex', 'FontSize', 18);

% Limits and Grid
xlim([0 100]);
ylim([0 max(ke)*1.2]);
grid on; set(gca, 'LineWidth', 1.2, 'FontSize', 12);

% --- FIXED LEGEND ---
legend([hSim, hAna], 'Location', 'northeast', 'FontSize', 14);

% % Parameter Box
% dim = [0.15 0.55 0.3 0.3];
% str = {
%     '\bf{Parameters:}', ...
%     sprintf('\\mu = %d', mu), ...
%     sprintf('\\sigma = %d', sigma), ...
%     sprintf('\\vartheta_0 = %d', theta0), ...
%     sprintf('\\epsilon_0 = %d', eps0), ...
%     sprintf('\\rho_1 = %.1f', rho1), ...
%     '----------------', ...
%     'Curve scaled to fit data amplitude'
% };
% annotation('textbox', dim, 'String', str, 'Interpreter', 'latex', ...
%     'FontSize', 12, 'BackgroundColor', 'w', 'EdgeColor', 'k');

hold off;
fprintf('Plot generated with Equation 3.3.16 parameters.\n');