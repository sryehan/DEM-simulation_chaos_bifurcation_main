# DEM Simulation: Chaos, Bifurcation & Solitons in Granular Metamaterials

**Repository Name:** `DEM-simulation_chaos_bifurcation_main`

Simulation codes, data, and analysis scripts for the research paper:  
**"From Hertzian Contact to Pochhammer-Chree Dynamics: Solitons, Chaos, and Bifurcation in Granular Metamaterials"** *Submitted to: Chaos, Solitons & Fractals*

---

## 📌 Overview
This repository contains the **Discrete Element Method (DEM)** simulation files and **MATLAB/Python** analysis scripts used to validate the analytical predictions of solitary wave propagation in 1D granular metamaterials.

The project investigates two distinct dynamic regimes:
1.  **Stable Soliton Regime:** Optimized soft-acoustic parameters ($K_n = 5.0 \times 10^7$ N/m$^{3/2}$) demonstrating robust, coherent solitary wave propagation with negligible energy drift.
2.  **Unstable/Chaotic Regime:** High-stiffness configurations showing sensitivity to initial conditions and positive Lyapunov exponents.

---

## 📂 File Structure

### 1. LAMMPS Simulation Files
* `in.soliton_final`: Main LAMMPS input script for generating stable solitary waves using a soft-acoustic metamaterial model.
* `log.lammps`: Simulation log file containing thermodynamic data (Step, Kinetic Energy, Potential Energy, Total Energy).
* `dump.soliton_final`: Particle trajectory dump file used for space-time visualization.

### 2. MATLAB Analysis Scripts
* `final_soliton_one.m`: Script for **Energy Conservation Analysis**. Calculates relative drift and plots energy stability metrics.
* `soliton_ig_2.m`: Script for **Soliton Validation**. Overlays DEM simulation data (Red dots) with the Analytical Bell-shaped solution (Blue line) derived from the Pochhammer-Chree equation.
* `final_soliton_heat_map.m`: Generates the **Space-Time Heatmap** (Waterfall plot) of kinetic energy propagation.
* `main_lyoponyv.m`: Main script for calculating the **Maximal Lyapunov Exponent ($\lambda_{max}$)** to quantify chaos in the unstable regime.
* `fourth.m`: Auxiliary plotting or analysis script.

### 3. Python Scripts
* `lyponiv.py`: Python utility for phase-space reconstruction and Rosenstein algorithm implementation (helper for chaos analysis).

### 4. Generated Figures (Results)
* `Soliton_Validation_Analysis_3_3_16.png`: Validation of the Bell-shaped soliton showing excellent agreement ($R^2 \approx 0.99$).
* `Energy_Conservation_Analysis.png`: Proof of numerical stability (Drift $< 0.005\%$).
* `Soliton_Wave_Propagation.png`: Space-time evolution of the pulse showing linear propagation.
* `image_d5e422.png`: Lyapunov exponent analysis graph ($\lambda \approx 1.9515$) for the unstable regime.

---

## 🚀 How to Run

### Prerequisites
* **LAMMPS** (Large-scale Atomic/Molecular Massively Parallel Simulator)
* **MATLAB** (R2021a or later recommended)
* **Python 3.x** (Optional, for specific scripts)

### Step 1: Run the DEM Simulation
Execute the input script using LAMMPS to generate the data:
```bash
lmp -in in.soliton_final


This will create/update log.lammps and dump.soliton_final.Step 2: Analyze Results in MATLABCheck Stability: Run final_soliton_one.m.Output: Plots total energy conservation and relative deviation.Validate Soliton: Run soliton_ig_2.m.Output: Compares numerical particle velocities with the theoretical Pochhammer-Chree solution.Visualize Propagation: Run final_soliton_heat_map.m.Output: Generates the 2D space-time energy contour plot.Step 3: Chaos Analysis (Optional)To reproduce the instability analysis for the high-stiffness regime:Run main_lyoponyv.m to compute the divergence of trajectories and estimate $\lambda_{max}$.📊 Key Results SummaryMetricResultSignificanceSoliton Fit ($R^2$)0.99Excellent agreement with analytical theory.Relative Error ($E_{L2}$)~1.2%High-fidelity numerical validation.Energy Drift< 0.005%Confirms exceptional numerical stability.Lyapunov Exponent~1.9515(In unstable regime) confirms sensitivity to initial conditions.📜 LicenseThis project is licensed under the MIT License - see the LICENSE file for details.
