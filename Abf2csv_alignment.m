clear
clc
close all
%% Set the paths to the files
ephys_file = "\\NASFATIN-1\Olga\alinement\Current clamp\2024_11_08_sl3_cell1_0002.abf";
catrace_file = "\\NASFATIN-1\Olga\alinement\Current clamp\CC.csv";
%% Load the files and find the TTL channel
[abf, si, h] = abfload(ephys_file);
TTL_ch = "Camera";

if any(h.recChNames==TTL_ch)
    camera_TTL = abf(:, h.recChNames==TTL_ch);
else
    answer_idx = listdlg('ListString',h.recChNames);
    camera_TTL = abf(:, h.answer_idx);
end
%% Load csv file
calcium = readtable(catrace_file);
[root, file] = fileparts(catrace_file);
struct = dir(fullfile(root ,'/*props.csv'));
props = readtable(fullfile(struct.folder, struct.name));
%% Check if in the camera_TTL there are any TTLs expecting a ~+5V TTL, change code if this assumption is broken
TTL_on = 5; %in Volt
TTL_off = 0;%in Volt
tolerance = 1.5; %in Volts

diff_signal = max(camera_TTL) - min(camera_TTL);

if diff_signal<TTL_on-tolerance || diff_signal>TTL_on+tolerance
    warning(['The selected signal does not seem to contain a ' num2str(TTL_on) 'V TTL'])
end
%% Cleaning and symplifing TTL signal
clean_TTL = camera_TTL;
clean_TTL(camera_TTL>=TTL_on-tolerance) = TTL_on;
clean_TTL(camera_TTL<=TTL_on-tolerance) = TTL_off;
%% Find index of TTLs on ephys signal 
[~,loc] = findpeaks(clean_TTL);
%% Build a timeline knowing the Sampling Interval SI
ephys_time = linspace(0, size(abf,1)*si*1e-6, size(abf,1))';
%% Create a list of indexes to match the ephys signal with the calcium trace
if size(loc,1) == size(calcium,1)
    aligned_indx = loc;
else
    answer_rf = inputdlg("Enter frames deleted from the beginning of the video: ", "Removed frames"); %note: there is no trivial way to deal with deleted frames if they are in the middle of the video
    answer_rf = str2double(answer_rf{1});
    s = answer_rf + 1;

    if size(calcium,1) <= size(loc,1)-answer_rf
        e = answer_rf + size(calcium,1);
    else
        e = size(loc,1);
    end
    aligned_indx = loc(s:e);
end
%%
merged = [abf nan(size(abf,1), size(calcium,2)-1)];

for i = 1:size(aligned_indx,1)
    merged(aligned_indx(i), size(abf,2)+1:size(abf,2) + size(calcium,2)-1) = table2array(calcium(i, 2:end));
end
%% Create a table with all  the signals and approapriate names and save it in csv 
whole_table = [array2table(ephys_time) array2table(merged)];

whole_table = renamevars(whole_table, "ephys_time", 'Time (s)');
for i = 1:size(whole_table,2)
    if i<=size(abf,2) && i>1
        whole_table = renamevars(whole_table, whole_table.Properties.VariableNames{i}, [h.recChNames{i-1} ' (' h.recChUnits{i-1} ')']);
    elseif i>size(abf,2)
        n = i-size(abf,2);
        whole_table = renamevars(whole_table, whole_table.Properties.VariableNames{i}, calcium.Properties.VariableNames{n});
    end
end
%% Select ephys signals for further plotting
f1 = figure('WindowState','maximized');
t1 = tiledlayout('vertical');
for i = 1:size(abf,2)
    ax = nexttile(t1);
    plot(ax, ephys_time, abf(:,i))
    ylabel(ax, {h.recChNames{i} h.recChUnits{i}}, 'Interpreter','none')
end
xlabel(t1, 'Time (s)')
title(t1, 'Ephys Traces')
linkaxes(t1.Children, 'x')
anw = listdlg('ListString', h.recChNames, 'PromptString', 'Select the ephys channels to keep');
abf_selected = abf(:, anw);
close(f1)
%% New merge for plotting
merged4plot = [abf_selected nan(size(abf_selected,1), size(calcium,2)-1)];

for i = 1:size(aligned_indx,1)
    merged4plot(aligned_indx(i), size(abf_selected,2)+1:size(abf_selected,2) + size(calcium,2)-1) = table2array(calcium(i, 2:end));
end
%% Plot merged files
f2 = figure('WindowState','maximized');
t2 = tiledlayout(f2, "vertical");
for i = 1:size(merged4plot,2)
    nexttile;
    plot( ephys_time(isfinite(merged4plot(:,i))), merged4plot(isfinite(merged4plot(:,i)), i) )
    
    if i<=size(abf_selected,2)
        ylabel({h.recChNames{anw(i)}, h.recChUnits{anw(i)}}, 'Interpreter','none')
        plot( ephys_time(isfinite(merged4plot(:,i))), merged4plot(isfinite(merged4plot(:,i)), i) )
    else
        n = i-size(abf_selected,2);
        col_props = size(props,2);
        ylabel({props.(col_props){n}, calcium.Properties.VariableNames{n+1}, '\DeltaF/F'})
    end
end
linkaxes(t2.Children,'x')
xlabel(t2, 'Time (s)')
title(t2, 'Ephys and Calcium Traces')
%% This part below takes the selected signals (only the portion with ephys and calcium traces) and upsample the calcium trace to the same freq as the ephys for further signal processing

cut_merged = merged4plot(aligned_indx(1):aligned_indx(end), :);

cut_merged_interp = fillmissing(cut_merged(), 'spline');
%% Quick test to check the alignment between patched cell and signal and its cross correlation
ephys_patched = 1; %index of the ephys trace coloumn
ca_patched = 4; %index of the ephys trace coloumn

figure;
plot(xcov(cut_merged_interp(:,ephys_patched), cut_merged_interp(:,ca_patched), 'normalized'))

figure;
yyaxis left
plot( cut_merged_interp(:,ephys_patched)) 
hold on
yyaxis right
plot( cut_merged_interp(:,ca_patched))
hold off

%% Plotting of the calcium imaging signal aligned to spikes (this part is good but needs to be better at generalizing)
sample_cut = 1300000; %sample number where to stop the spike to calcium alignment
min_heigth = 10; %min height for detecting AP in mV
window_size_L = 2000; %in samples
window_size_R = 5000; %in samples

[~, spike_loc] = findpeaks(cut_merged_interp(1:sample_cut,1), 'MinPeakHeight',min_heigth);
b1 = spike_loc - window_size_L; %window size
e2 = spike_loc + window_size_R; %window size

f = figure;
p0 = subplot(4,2,[1 3 5 7], 'NextPlot', 'add');
p1 = subplot(4,2,[2 4], 'NextPlot', 'add');
p2 = subplot(4,2,[6 8], 'NextPlot', 'add');

plot(p0, cut_merged_interp(1:sample_cut,1));
plot(p0, spike_loc, cut_merged_interp(spike_loc,1), 'ro')

av_ca_spike_aligned = [];
av_ephys_spike_aligned = [];
for i = 1:numel(spike_loc)
    if b1(i)>0 && e2(i)<=length(cut_merged_interp)
        plot(p1,cut_merged_interp(b1(i):e2(i), ca_patched)-mean(cut_merged_interp(b1(i):spike_loc(i), ca_patched)), 'Color',[.75 .75 .75])
        plot(p2, cut_merged_interp(b1(i):e2(i), ephys_patched)-mean(cut_merged_interp(b1(i):spike_loc(i), ephys_patched)), 'Color',[.75 .75 .75])
        av_ca_spike_aligned = [av_ca_spike_aligned cut_merged_interp(b1(i):e2(i), ca_patched)-mean(cut_merged_interp(b1(i):spike_loc(i), ca_patched))];
        av_ephys_spike_aligned = [av_ephys_spike_aligned cut_merged_interp(b1(i):e2(i), ephys_patched)-mean(cut_merged_interp(b1(i):spike_loc(i), ephys_patched))];
    end
    hold on
end
plot(p1, mean(av_ca_spike_aligned, 2), 'r')
plot(p2, mean(av_ephys_spike_aligned, 2), 'r')
hold off
pbaspect(p1, [1 1 1])
pbaspect(p2, [1 1 1])
linkaxes([p1, p2],'x')
