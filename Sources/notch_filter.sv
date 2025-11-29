`timescale 1ns / 1ps

module notch_filter #(
    parameter int DATA_WIDTH = 16
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    valid_i,
    input  logic signed [DATA_WIDTH-1:0] data_i,
    
    output logic                    valid_o,
    output logic signed [DATA_WIDTH-1:0] data_o
);

    // =========================================================================
    // Coefficients (Q2.14)
    // =========================================================================
    localparam signed [15:0] B0 = 16'd15725; 
    localparam signed [15:0] B1 = 16'd25443; 
    localparam signed [15:0] B2 = 16'd15725; 
    localparam signed [15:0] A1 = 16'd25443; 
    localparam signed [15:0] A2 = 16'd15066; 

    // =========================================================================
    // Internal State
    // =========================================================================
    logic signed [31:0] s1, s2;
    logic signed [DATA_WIDTH-1:0] x_reg; // Latch input
    logic signed [31:0] y_reg;           // Latch intermediate output
    
    // State Machine
    typedef enum logic { ST_CALC_OUT, ST_UPDATE_STATE } state_t;
    state_t state;

    // =========================================================================
    // Processing Logic (Split into 2 Cycles)
    // =========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_o <= 0;
            data_o  <= 0;
            s1      <= 0;
            s2      <= 0;
            x_reg   <= 0;
            y_reg   <= 0;
            state   <= ST_CALC_OUT;
        end else begin
            valid_o <= 0; // Default low

            case (state)
                // -------------------------------------------------------------
                // State 0: Wait for Input -> Calculate Output (y)
                // -------------------------------------------------------------
                ST_CALC_OUT: begin
                    if (valid_i) begin
                        // 1. Latch Input
                        x_reg <= data_i;
                        
                        // 2. Calculate Feed-Forward (Part A)
                        // y[n] = b0*x[n] + s1[n-1]
                        // We register this result to break the timing path.
                        y_reg <= (data_i * B0) + s1;
                        
                        // Move to next step immediately
                        state <= ST_UPDATE_STATE;
                    end
                end

                // -------------------------------------------------------------
                // State 1: Calculate Feedback -> Update States (s1, s2)
                // -------------------------------------------------------------
                ST_UPDATE_STATE: begin
                    // 1. Output the result calculated in previous cycle
                    data_o  <= y_reg[29:14]; // Scale Q2.29 -> Q1.15
                    valid_o <= 1;            // Signal valid output

                    // 2. Calculate Feedback Terms (Using registered y_reg)
                    // This splits the math load: Multiply A1/A2 happens here.
                    // s1[n] = b1*x - a1*y + s2[n-1]
                    s1 <= (x_reg * B1) - ((y_reg >>> 14) * A1) + s2;
                    
                    // s2[n] = b2*x - a2*y
                    s2 <= (x_reg * B2) - ((y_reg >>> 14) * A2);

                    // Done, go back to wait for next sample
                    state <= ST_CALC_OUT;
                end
            endcase
        end
    end

endmodule


