// =========================================================
// Module: traffic_light
// Description: Two-road traffic light controller with an
//              emergency priority override, implemented as
//              a simple Finite State Machine (FSM).
// =========================================================
//
// INPUTS:
//   clk        - system clock
//   rst        - active-high synchronous reset
//   emergency  - active-high emergency priority request
//
// OUTPUTS:
//   roadA_red, roadA_yellow, roadA_green - Road A lights
//   roadB_red, roadB_yellow, roadB_green - Road B lights
//
// =========================================================

module traffic_light (
    input  wire clk,
    input  wire rst,
    input  wire emergency,
    output reg  roadA_red,
    output reg  roadA_yellow,
    output reg  roadA_green,
    output reg  roadB_red,
    output reg  roadB_yellow,
    output reg  roadB_green
);

    // ---------------------------------------------------
    // FSM STATE ENCODING
    // Normal sequence: A_GREEN -> A_YELLOW -> B_GREEN -> B_YELLOW -> repeat
    // Emergency state: EMERGENCY (forces Road A green, Road B red)
    // ---------------------------------------------------
    parameter A_GREEN   = 3'b000;
    parameter A_YELLOW  = 3'b001;
    parameter B_GREEN   = 3'b010;
    parameter B_YELLOW  = 3'b011;
    parameter EMERGENCY = 3'b100;

    reg [2:0] state, next_state;

    // ---------------------------------------------------
    // SIMPLE CLOCK DIVIDER / TIMER
    // Counts clock cycles so each state holds for a short,
    // simulation-friendly number of cycles (4 cycles here).
    // ---------------------------------------------------
    reg [2:0] timer;
    parameter HOLD_TIME = 4; // cycles per state (kept small for fast simulation)

    wire timer_done = (timer == HOLD_TIME - 1);

    always @(posedge clk) begin
        if (rst)
            timer <= 0;
        else if (timer_done || state != next_state)
            timer <= 0;   // reset timer whenever we change state
        else
            timer <= timer + 1;
    end

    // ---------------------------------------------------
    // FSM STATE REGISTER (sequential logic)
    // ---------------------------------------------------
    always @(posedge clk) begin
        if (rst)
            state <= A_GREEN;
        else
            state <= next_state;
    end

    // ---------------------------------------------------
    // FSM NEXT-STATE LOGIC (combinational logic)
    // Emergency has top priority: if emergency=1, jump to
    // the EMERGENCY state immediately regardless of current state.
    // ---------------------------------------------------
    always @(*) begin
        if (emergency) begin
            next_state = EMERGENCY;
        end
        else begin
            case (state)
                A_GREEN:    next_state = timer_done ? A_YELLOW  : A_GREEN;
                A_YELLOW:   next_state = timer_done ? B_GREEN   : A_YELLOW;
                B_GREEN:    next_state = timer_done ? B_YELLOW  : B_GREEN;
                B_YELLOW:   next_state = timer_done ? A_GREEN   : B_YELLOW;
                EMERGENCY:  next_state = A_GREEN; // when emergency clears, restart normal cycle
                default:    next_state = A_GREEN;
            endcase
        end
    end

    // ---------------------------------------------------
    // OUTPUT LOGIC (combinational)
    // Decides which LEDs are ON based on current state.
    // ---------------------------------------------------
    always @(*) begin
        // default all lights off
        roadA_red = 0; roadA_yellow = 0; roadA_green = 0;
        roadB_red = 0; roadB_yellow = 0; roadB_green = 0;

        case (state)
            A_GREEN: begin
                roadA_green = 1;
                roadB_red   = 1;
            end
            A_YELLOW: begin
                roadA_yellow = 1;
                roadB_red    = 1;
            end
            B_GREEN: begin
                roadA_red   = 1;
                roadB_green = 1;
            end
            B_YELLOW: begin
                roadA_red    = 1;
                roadB_yellow = 1;
            end
            EMERGENCY: begin
                // Emergency: Road A gets GREEN, Road B is RED
                roadA_green = 1;
                roadB_red   = 1;
            end
            default: begin
                roadA_red = 1;
                roadB_red = 1;
            end
        endcase
    end

endmodule
