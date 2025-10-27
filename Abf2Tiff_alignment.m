clear
clc
close all
%% Set the paths to the files
ephys_file = "\\NASFATIN-1\Olga\alinement\Current clamp\2024_11_08_sl3_cell1_0002.abf" ;
video_file = "\\NASFATIN-1\Olga\alinement\Current clamp\CC.csv";
%add the second file, we can start with the video and then move to the csv
%btw consider that the csv of the ca imaging will be downsampled
%% Load the files and find the TTL channel
[abf, si, h] = abfload("\\NASFATIN-1\Olga\Voltron2_RawRecords_ON\23sep2024_P57_male_THcre_ON\Ephys_records_23sep2024\Slice2\2024_09_23_0006.abf");
TTL_ch = "Camera";

if any(h.recChNames==TTL_ch)
    camera_TTL = abf(:, h.recChNames==TTL_ch);
else
    answer_idx = listdlg('ListString',h.recChNames);
    camera_TTL = abf(:, h.answer_idx);
end
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
%% Build a timeline knowing the Sampling Interval SI
ephys_time = linspace(0, size(abf,1)*si*1e-6, size(abf,1));
%%
[~,loc] = findpeaks(clean_TTL);
%%
tiff = tiffreadVolume(video_file); 
%%
if size(loc,1) == size(tiff,3)
    aligned_indx = loc;
else
    answer_rf = inputdlg("Enter frames deleted from the beginning of the video: ", "Removed frames"); %note: there is no trivial way to deal with deleted frames if they are in the middle of the video
    answer_rf = str2double(answer_rf{1});
    alligned = [abf nan(size(abf,1),1)];
    s = answer_rf + 1;

    if size(tiff,3) <= size(loc,1)-answer_rf
        e = answer_rf + size(tiff,3);
    else
        e = size(loc,1);
    end
    aligned_indx = loc(s:e);
end
%%
abf_cut = abf(aligned_indx(1):aligned_indx(end),1);
aligned_indx_cut = aligned_indx-aligned_indx(1)+1;

f = figure;
p1 = subplot(3,1,1);
p2 = subplot(3,1,2);
p3 = subplot(3,1,3);
h = animatedline(p2, 'Color', "#0072BD", 'LineWidth',1);
h2 = animatedline(p3);
for i = 1:size(abf,1)
    if any(i==aligned_indx)
        imshow(tiff(:,:,i==aligned_indx), [], Colormap=gray, Parent=p1)

    end
    addpoints(h, ephys_time(i), abf(i,1))
    addpoints(h2, ephys_time(i), abf(i,6))
    drawnow limitrate 
end
%%
plot(diff(aligned_indx_cut))