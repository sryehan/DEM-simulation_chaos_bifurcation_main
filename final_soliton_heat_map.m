clc; clear; close all;

% ==========================================
% ১. সেটিংস
% ==========================================
filename = 'dump.soliton_final'; % আপনার লেটেস্ট ফাইলের নাম দিন
dt = 1e-8; % LAMMPS এর timestep যা ছিল তাই দিন (1e-8 বা 1e-9)

if ~isfile(filename), error('Error: %s ফাইলটি পাওয়া যাচ্ছে না!', filename); end

% ==========================================
% ২. ডাটা রিড করা
% ==========================================
fid = fopen(filename, 'r');
timesteps = [];
data_matrix = []; 
current_step_data = [];
atom_ids = [];

fprintf('Reading Space-Time data from %s...\n', filename);

while ~feof(fid)
    line = strtrim(fgetl(fid));
    
    if contains(line, 'ITEM: TIMESTEP')
        % আগের স্টেপের ডাটা প্রসেস ও সেভ করা
        if ~isempty(current_step_data)
            [~, sort_idx] = sort(current_step_data(:, 1)); % ID অনুযায়ী সর্ট
            velocities = current_step_data(sort_idx, 2);
            
            % Energy Calculation
            ke = 0.5 * 1.0 * velocities.^2; 
            data_matrix = [data_matrix, ke]; 
            
            if isempty(atom_ids)
                atom_ids = current_step_data(sort_idx, 1);
            end
        end
        
        % নতুন স্টেপ শুরু
        timesteps = [timesteps; str2double(fgetl(fid))];
        current_step_data = []; 
        for k = 1:7; fgetl(fid); end % Header skip
        continue;
    end
    
    % এটম ডাটা পড়া
    if length(line) > 1 && ~contains(line, 'ITEM')
        vals = str2num(line); 
        if length(vals) >= 3
            % ফরম্যাট ছিল: id x vx v_vis_r
            % তাই vals(1) = id, vals(3) = vx (ভেলোসিটি)
            current_step_data = [current_step_data; vals(1), vals(3)];
        end
    end
end
fclose(fid);

% শেষের ব্লকটি যোগ করা
if ~isempty(current_step_data)
    [~, sort_idx] = sort(current_step_data(:, 1));
    velocities = current_step_data(sort_idx, 2);
    data_matrix = [data_matrix, 0.5 * velocities.^2];
end

% ==========================================
% ৩. প্রফেশনাল হিটম্যাপ প্লট
% ==========================================
figure('Color', 'w', 'Position', [100, 100, 900, 600]);

real_time = timesteps * dt; 
% imagesc(x, y, C) -> x=Time, y=Atoms
imagesc(real_time, atom_ids, data_matrix);

set(gca, 'YDir', 'normal'); % নিচ থেকে উপরে ১, ২, ৩...

% --- Styling ---
% 'hot' বা 'jet' কালারম্যাপ এনার্জির জন্য ভালো
colormap(hot); 
% এনার্জি খুব কম হলে নীল দেখাবে, বেশি হলে হলুদ/সাদা
caxis([0 max(data_matrix(:))*0.8]); % কন্টহ্রাস্ট বাড়ানোর জন্য একটু লিমিট কমালাম

c = colorbar;
c.Label.String = 'Kinetic Energy ($E_k$)';
c.Label.Interpreter = 'latex';
c.Label.FontSize = 14;

xlabel('Time (s)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Atom Index ($n$)', 'Interpreter', 'latex', 'FontSize', 14, 'FontWeight', 'bold');
title('Space-Time Evolution of Soliton Propagation', 'FontSize', 16, 'FontWeight', 'bold');

% ফন্ট সাইজ ফিক্স
set(gca, 'FontSize', 12, 'LineWidth', 1.2);

fprintf('Space-Time Map generated!\n');