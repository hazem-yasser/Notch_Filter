# ==============================================================================
# Makefile for Notch Filter Simulation
# Tools: Icarus Verilog (iverilog), VVP, GTKWave
# ==============================================================================

# ----------------------------------------------------------------------
# Copy source files from new directories
# ----------------------------------------------------------------------
SRC_DIR = ./Sources
SIM_DIR = ./Sim
PY_DIR  = ./python_script

# Copy files to current directory

# Tools
COMPILER = iverilog
SIMULATOR = vvp
VIEWER = surfer
PYTHON = python3

# Files
SRC = notch_filter.sv tb_notch_filter.sv
OUT = notch_sim.out
VCD = notch_filter.vcd
TXT = notch_io.txt
SCRIPT = plot_notch_io.py

# Flags
FLAGS = -g2012 -Wall

# Targets ----------------------------------------------------------------------

.PHONY: all compile run view plot clean

all: COPY_FILES compile run view plot

COPY_FILES:
	@echo "Copying SystemVerilog and Python files..."
	cp $(SRC_DIR)/notch_filter.sv ./
	cp $(SIM_DIR)/tb_notch_filter.sv ./
	cp "$(PY_DIR)/plot_notch_io.py" ./

# 1. Compile Verilog
compile: COPY_FILES
	@echo "Compiling SystemVerilog files..."
	$(COMPILER) $(FLAGS) -o $(OUT) $(SRC)

# 2. Run Simulation
run: compile
	@echo "Running Simulation..."
	$(SIMULATOR) $(OUT)

# 3. View Waveform (GTKWave)
view: run
	@echo "Opening Waveform Viewer..."
	$(VIEWER) $(VCD) &

# 4. Run Python Analysis
plot: run
	@echo "Running Python Analysis..."
	$(PYTHON) $(SCRIPT)

# 5. Clean up
clean:
	@echo "Cleaning up..."
	rm -f $(OUT) $(VCD) $(TXT) *.png notch_filter.sv tb_notch_filter.sv plot_notch_io.py