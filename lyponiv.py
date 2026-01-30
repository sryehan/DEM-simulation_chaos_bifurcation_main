import os
import subprocess

lammps_executable = "lmp" 

# ==========================================
# 1. REFERENCE RUN (Periodic Boundary)
# ==========================================
ref_content = """
# --- Chaotic Granular Chain (Periodic Boundary) ---
units           si
atom_style      sphere
boundary        p p p  # Periodic in all directions
newton          off
comm_modify     vel yes

# --- Geometry ---
region          box block 0 1.0 -0.05 0.05 -0.05 0.05 units box
create_box      1 box
lattice         sc 0.010 
region          chain block 0 100 0 1 0 1 units lattice
create_atoms    1 region chain

# --- Material (Softened for Chaos) ---
set             group all density 2500.0
set             group all diameter 0.010 

# --- Interaction ---
pair_style      gran/hertz/history 1.0e8 0.0 0.0 0.0 0.5 0
pair_coeff      * *

# --- External Force (Forcing Term) ---
# Apply sinusoidal force to first particle instead of wall
group           first id 1
variable        omega equal 2*PI/0.05
variable        force equal 1000.0*sin(v_omega*time)  # 1000N force

fix             external_force first addforce v_force 0 0

# --- Integration ---
fix             1 all nve/sphere

# --- Output ---
timestep        0.000002 
dump            1 all custom 2000 dump.ref_chaos id vx
dump_modify     1 format line "%d %.15e"
thermo          10000
run             5000000  # 10 seconds
"""

# ==========================================
# 2. PERTURBED RUN
# ==========================================
pert_content = """
# --- Chaotic Granular Chain (Perturbed) ---
units           si
atom_style      sphere
boundary        p p p
newton          off
comm_modify     vel yes

region          box block 0 1.0 -0.05 0.05 -0.05 0.05 units box
create_box      1 box
lattice         sc 0.010 
region          chain block 0 100 0 1 0 1 units lattice
create_atoms    1 region chain

set             group all density 2500.0
set             group all diameter 0.010 

pair_style      gran/hertz/history 1.0e8 0.0 0.0 0.0 0.5 0
pair_coeff      * *

# --- External Force ---
group           first id 1
variable        omega equal 2*PI/0.05
variable        force equal 1000.0*sin(v_omega*time)

fix             external_force first addforce v_force 0 0

# --- PERTURBATION ---
# Tiny velocity difference (0.5 m/s vs 0.500001 m/s)
velocity        first set 0.500001 0 0

# --- Integration ---
fix             1 all nve/sphere

# --- Output ---
timestep        0.000002 
dump            1 all custom 2000 dump.pert_chaos id vx
dump_modify     1 format line "%d %.15e"
thermo          10000
run             5000000  # 10 seconds
"""

# Write Files
files = {"in.ref_chaos": ref_content, "in.pert_chaos": pert_content}
for name, content in files.items():
    with open(name, "w", newline='\n') as f:
        f.write(content)

print("Running Chaos Simulation (Periodic Boundary + External Force)...")
try:
    print("-> Running Reference...")
    subprocess.run([lammps_executable, "-in", "in.ref_chaos"], check=True)
    print("-> Running Perturbed...")
    subprocess.run([lammps_executable, "-in", "in.pert_chaos"], check=True)
    print("\n✅ DONE! Files ready: 'dump.ref_chaos', 'dump.pert_chaos'")
except Exception as e:
    print(f"\n❌ Error: {e}")
    print("LAMMPS manual run commands:")
    print("lmp -in in.ref_chaos")
    print("lmp -in in.pert_chaos")