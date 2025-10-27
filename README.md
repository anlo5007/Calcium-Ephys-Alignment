# 🔬 Electrophysiology–Calcium Imaging Alignment and Analysis

This repository contains MATLAB scripts for aligning **electrophysiological recordings (ABF files)** with either **calcium imaging videos (TIFF stacks)** or **extracted calcium traces (CSV files)** using **TTL synchronization signals**.

These tools are designed to assist in the synchronization, visualization, and quantitative analysis of **ex vivo or in vitro experiments** combining patch-clamp electrophysiology with simultaneous calcium imaging.

---

## 📁 Repository Contents

### 1. `align_ephys_video.m`

**Purpose:**  
Align electrophysiology (ABF) recordings with the corresponding imaging frames from a **TIFF video** using the camera TTL signal.

**Main features:**
- Loads ABF electrophysiology recordings (`abfload` function).
- Detects camera TTL pulses used to trigger each imaging frame.
- Aligns ephys data with video frames based on TTL events.
- Allows manual correction for deleted or missing frames.
- Displays a synchronized animation of:
  - the calcium imaging video,  
  - electrophysiological trace(s),  
  - TTL channel activity.

**Typical use case:**  
When the user wants to visually verify frame-to-frame correspondence between electrophysiological data and raw calcium imaging movies.

**Key inputs:**
```matlab
ephys_file = "\\path\\to\\your\\recording.abf";
video_file = "\\path\\to\\your\\video.tif";
```

**Key output:**  
Animated plot showing real-time alignment between imaging frames and ephys signals.

---

### 2. `align_ephys_caTrace.m`

**Purpose:**  
Align electrophysiology recordings (ABF) with **processed calcium traces (CSV)** extracted from imaging data.  
Generates a combined dataset suitable for further signal processing and quantitative analysis.

**Main features:**
- Loads electrophysiology data (`.abf`) and calcium signals (`.csv`).
- Uses TTL events to synchronize electrophysiological samples with imaging frames.
- Merges both datasets into a single table.
- Interactive channel selection for plotting ephys signals.
- Generates aligned plots of:
  - Electrophysiology signals,  
  - Calcium ΔF/F traces.
- Performs optional interpolation to match ephys sampling frequency.
- Includes basic analysis examples:
  - Cross-correlation between patched cell and calcium signal.  
  - Spike-triggered averaging of calcium responses.

**Typical use case:**  
When calcium traces have already been extracted (e.g., via Inscopix IDPS) and need to be aligned and compared to electrophysiological recordings.

**Key inputs:**
```matlab
ephys_file = "\\path\\to\\your\\recording.abf";
catrace_file = "\\path\\to\\your\\calcium_traces.csv";
```

**Key outputs:**
- Figures displaying:
  - Ephys channel selection and plotting,
  - Aligned ephys–calcium traces,
  - Spike-triggered calcium responses.

---

## ⚙️ Dependencies

These scripts rely on the following MATLAB functions and toolboxes:
- **[abfload.m](https://github.com/felix-halim/abfload)** — for reading `.abf` electrophysiology files.  
- **Signal Processing Toolbox** — for `findpeaks`, `xcov`, etc.  
- **Image Processing Toolbox** — for `imshow`, `tiffreadVolume`.

---

## 🧠 Workflow Summary

1. **Record synchronized ephys and imaging data** using a TTL line for the camera trigger.  
2. **Extract calcium traces**
3. **Run one of the scripts**:
   - `align_ephys_video.m` — for frame-by-frame video alignment.  
   - `align_ephys_caTrace.m` — for calcium trace alignment and quantitative analysis.  
4. **Inspect alignment and results** using the generated plots.  
5. **Export merged data** for further custom analysis.

---

## 📊 Example Outputs

- **Animated alignment plot**  
  Displays real-time synchronization between imaging frames and electrophysiology signal.

- **Merged ephys–calcium plots**  
  Shows ΔF/F traces aligned to the electrophysiological activity of the patched neuron.

- **Spike-triggered calcium response**  
  Computes average calcium signal around action potentials detected in the ephys trace.

---

## 🧩 Notes & Tips

- TTL amplitude is assumed to be **~5V**. Modify `TTL_on` and `tolerance` if your setup differs.  
- The script asks for manual correction if frames were removed at the **beginning** of the video.  
- Ensure your `.csv` calcium file includes frame-by-frame ΔF/F data (first column = frame number or time).  
- The `props.csv` file should contain ROI metadata (optional but recommended).

---

## 🧑‍🔬 Author

**Andrea Locarno, Ph.D.**  
_Postdoctoral Researcher in Christian Broberger´s Lab_  
Date: Oct-2025  
