`timescale 1ns / 1ps

module tb_notch_filter;

    // =========================================================================
    // Header
    // =========================================================================
    // Author: Hazem Yasser Mahmoud Mohamed
    // Description: Testbench for Notch Filter with Valid every 4 cycles

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam int DATA_WIDTH = 16;
    localparam real FS = 6.0e6;       // Sampling Frequency: 6 MHz
    localparam int NUM_SAMPLES = 2048; // Number of samples to simulate

    // =========================================================================
    // Signals
    // =========================================================================
    logic                    clk;
    logic                    rst_n;
    logic                    valid_i;
    logic signed [DATA_WIDTH-1:0] data_i;
    logic                    valid_o;
    logic signed [DATA_WIDTH-1:0] data_o;

    // File Handle
    int fd;
    
    // Simulation Variables
    real t;
    real val_1_0m, val_2_4m, val_total;
    integer i;
    
    // Temporary integer for conversion
    int temp_val;

    // =========================================================================
    // DUT Instantiation
    // =========================================================================
    notch_filter #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .valid_i (valid_i),
        .data_i  (data_i),
        .valid_o (valid_o),
        .data_o  (data_o)
    );

    // =========================================================================
    // Clock Generation
    // =========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz System Clock
    end

    // =========================================================================
    // VCD Dump (Waveform Generation)
    // =========================================================================
    initial begin
        $dumpfile("notch_filter.vcd");
        $dumpvars(0, tb_notch_filter);
    end

    // =========================================================================
    // Stimulus Generation
    // =========================================================================
    initial begin
        // 1. Initialize
        rst_n   = 0;
        valid_i = 0;
        data_i  = 0;
        fd      = $fopen("notch_io.txt", "w");
        
        if (fd == 0) begin
            $display("Error: Could not open output file.");
            $finish;
        end

        // 2. Reset Sequence
        repeat(10) @(posedge clk);
        rst_n = 1;
        repeat(10) @(posedge clk);

        $display("Starting Simulation...");

        // 3. Drive Data (Valid High for 1 cycle, Low for 3 cycles)
        for (i = 0; i < NUM_SAMPLES; i++) begin
            
            // Calculate time 't'
            t = real'(i) / FS;

            // Tone 1: 1.0 MHz (Passband)
            val_1_0m = $sin(2.0 * 3.14159 * 1.0e6 * t);
            
            // Tone 2: 2.4 MHz (Notch Frequency)
            val_2_4m = $sin(2.0 * 3.14159 * 2.4e6 * t);

            // Combine: 1MHz + 0.2 DC + 2.4MHz
            val_total = val_1_0m + 0.2 + val_2_4m;

            // Scale to fit Q1.15 Fixed Point
            // Scaling factor 0.4 to keep within range (-1.0 to 1.0)
            temp_val = $rtoi(val_total * 0.4 * 32767.0);
            
            // Clamp to 16-bit range
            if (temp_val > 32767) temp_val = 32767;
            if (temp_val < -32768) temp_val = -32768;

            // --- DRIVE DATA ---
            valid_i <= 1'b1;
            data_i  <= temp_val[15:0];
            
            // Wait 1 clock cycle (Active Cycle)
            @(posedge clk);

            // --- IDLE GAP ---
            valid_i <= 1'b0;
            // Wait 3 clock cycles (Idle Cycles) -> Total period = 4 clocks
            repeat(3) @(posedge clk);
        end

        @(posedge clk);
        valid_i = 0;
        data_i  = 0;

        // Allow pipeline to flush
        repeat(50) @(posedge clk);

        $display("Simulation Finished. Waveform dumped to notch_filter.vcd");
        $display("Data written to notch_io.txt");
        $fclose(fd);
        $finish;
    end

    // =========================================================================
    // Text Output (CSV Style)
    // =========================================================================
    always @(posedge clk) begin
        if (rst_n) begin
            // Only write to file when valid_i or valid_o is active to save space/readability
            // Or keep it continuous to see the gaps. Keeping continuous based on previous code.
            $fdisplay(fd, "%d, %d, %d, %d", valid_i, data_i, valid_o, data_o);
        end
    end

endmodule
