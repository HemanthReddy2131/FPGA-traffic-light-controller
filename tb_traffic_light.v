// =========================================================
// Testbench: tb_traffic_light
// Automatically drives clock, reset, and emergency signals,
// and dumps a VCD waveform for viewing in EDA Playground /
// GTKWave / any VCD viewer.
// =========================================================

`timescale 1ns/1ps

module tb_traffic_light;

    reg clk;
    reg rst;
    reg emergency;

    wire roadA_red, roadA_yellow, roadA_green;
    wire roadB_red, roadB_yellow, roadB_green;

    // ---------------------------------------------------
    // Instantiate the Design Under Test (DUT)
    // ---------------------------------------------------
    traffic_light DUT (
        .clk(clk),
        .rst(rst),
        .emergency(emergency),
        .roadA_red(roadA_red),
        .roadA_yellow(roadA_yellow),
        .roadA_green(roadA_green),
        .roadB_red(roadB_red),
        .roadB_yellow(roadB_yellow),
        .roadB_green(roadB_green)
    );

    // ---------------------------------------------------
    // Clock generation: 10ns period (toggle every 5ns)
    // ---------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------
    // Waveform dump setup
    // ---------------------------------------------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_traffic_light);
    end

    // ---------------------------------------------------
    // Test sequence
    // ---------------------------------------------------
    initial begin
        // 1. Apply reset
        rst = 1;
        emergency = 0;
        #12;              // hold reset for a bit more than one clock cycle
        rst = 0;

        // 2. Let the FSM run through normal operation
        //    (A_GREEN -> A_YELLOW -> B_GREEN -> B_YELLOW)
        #200;

        // 3. Activate emergency priority
        emergency = 1;
        #60;               // keep emergency active for a few cycles

        // 4. Remove emergency, controller should return to normal sequence
        emergency = 0;
        #200;

        // 5. End simulation
        $display("Simulation finished at time %0t", $time);
        $finish;
    end

    // ---------------------------------------------------
    // Optional: print state changes to the console log
    // ---------------------------------------------------
    initial begin
        $monitor("time=%0t rst=%b emergency=%b | A: R=%b Y=%b G=%b | B: R=%b Y=%b G=%b",
                  $time, rst, emergency,
                  roadA_red, roadA_yellow, roadA_green,
                  roadB_red, roadB_yellow, roadB_green);
    end

endmodule
