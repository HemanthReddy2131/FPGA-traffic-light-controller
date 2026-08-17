# FPGA-Based Traffic Light Controller with Priority System
### Complete EDA Playground Mini-Project (Verilog, Icarus Verilog, No Hardware)

---

## PART 0 — Project Summary

This is a two-road traffic light controller built as a Finite State Machine (FSM) in Verilog. It cycles through GREEN → YELLOW → RED for each road in sequence, and includes an emergency override that forces Road A to GREEN and Road B to RED whenever `emergency = 1`. Everything is simulated in your browser using EDA Playground + Icarus Verilog — no board, no Vivado, no ModelSim.

---

## PART 1 — Main Verilog Design

Save this as your **design file** (e.g. `traffic_light.v`).

```verilog
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
```

---

## PART 2 — Testbench

Save this as your **testbench file** (e.g. `tb_traffic_light.v`).

```verilog
// =========================================================
// Testbench: tb_traffic_light
// Automatically drives clock, reset, and emergency signals,
// and dumps a VCD waveform for viewing in EDA Playground.
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
    // Waveform dump setup (required for EDA Playground)
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
```

---

## PART 3 — Exact EDA Playground Instructions

1. **Open EDA Playground**: Go to `https://www.edaplayground.com` in your browser. Sign in (Google/GitHub login works, or use it as guest if allowed).

2. **Select Verilog**: On the left panel, find the language/testbench dropdown. Set it to **Verilog** (not SystemVerilog/VHDL).

3. **Select the simulator**: In the "Tools & Simulators" section (usually top-left dropdown), choose **Icarus Verilog (icarus)**. It's free and requires no setup.

4. **Create the design file**:
   - Look at the left panel — there are two main code boxes: **"Testbench"** (top) and **"Design"** (bottom, sometimes labeled with a file icon).
   - Click the **design.v** box (bottom editor).
   - Paste the **Part 1 code** (the `traffic_light` module) into it.

5. **Create the testbench file**:
   - Click the **testbench.v** box (top editor).
   - Paste the **Part 2 code** (the `tb_traffic_light` module) into it.

6. **Paste the code into correct locations**: Double-check — design module (`traffic_light`) goes in the Design box, testbench module (`tb_traffic_light`) goes in the Testbench box. EDA Playground compiles both together.

7. **Enable waveform generation**: Look for a checkbox on the left panel labeled **"Open EPWave after run"** (sometimes near the Run button). Check this box — it lets you view the VCD waveform after simulation. (Our testbench already creates `dump.vcd` via `$dumpfile`/`$dumpvars`, so this checkbox will auto-load it.)

8. **Run the simulation**: Click the green **"Run"** button at the top. Icarus Verilog will compile both files and execute the testbench.

9. **Open and understand the waveform**:
   - After the run finishes, click **"EPWave"** (or it opens automatically if you checked the box in step 7).
   - On the left side of the EPWave window, you'll see a signal list (`clk`, `rst`, `emergency`, `roadA_red`, `roadA_green`, etc.). Click each signal to add it to the waveform view.
   - The waveform shows time on the X-axis and signal value (0/1) on the Y-axis as colored traces.

10. **Verify normal operation**: Look at the region after reset goes low (`rst = 0`) and before `emergency` goes high. You should see `roadA_green` high first, then `roadA_yellow`, then `roadB_green`, then `roadB_yellow`, cycling in that order — each held for `HOLD_TIME` (4) clock cycles.

11. **Verify emergency operation**: Find where `emergency` goes high (1). Immediately after that clock edge, `roadA_green` should go high and `roadB_red` should go high, staying that way for as long as `emergency = 1`. When `emergency` returns to 0, the FSM should restart the normal sequence from `A_GREEN`.

---

## PART 4 — FSM Explanation

| State      | Road A | Road B | Notes |
|------------|--------|--------|-------|
| A_GREEN    | GREEN  | RED    | Road A has right of way |
| A_YELLOW   | YELLOW | RED    | Road A preparing to stop |
| B_GREEN    | RED    | GREEN  | Road B has right of way |
| B_YELLOW   | RED    | YELLOW | Road B preparing to stop |
| EMERGENCY  | GREEN  | RED    | Forced state, overrides normal cycle |

**Normal sequence:** `A_GREEN → A_YELLOW → B_GREEN → B_YELLOW → A_GREEN → ...` (repeats forever), each state held for 4 clock cycles using the internal `timer` counter.

**Emergency behavior:** The `next_state` logic checks `emergency` **first**, before anything else. So no matter which state the FSM is currently in, the very next clock edge takes it straight to the `EMERGENCY` state (Road A green, Road B red) — this models an emergency vehicle immediately getting a clear path on Road A. While `emergency` stays high, the FSM stays parked in `EMERGENCY`. The moment `emergency` goes back to 0, the FSM's next-state logic falls through to the `EMERGENCY: next_state = A_GREEN;` line, so it restarts the normal cycle cleanly from `A_GREEN` rather than resuming mid-cycle.

---

## PART 5 — 30-Minute Build Plan

| Time | Task |
|------|------|
| 0–5 min | Open EDA Playground, sign in, set language to Verilog, select Icarus Verilog simulator |
| 5–10 min | Paste Part 1 code into the Design box; skim through comments to understand structure |
| 10–15 min | Paste Part 2 code into the Testbench box; check "Open EPWave after run" |
| 15–20 min | Click Run; fix any typos/copy-paste errors if compilation fails |
| 20–25 min | Open EPWave, add all signals to the waveform, scroll through reset/normal/emergency regions |
| 25–30 min | Read through the FSM table and emergency explanation above so you can explain it confidently |

---

## PART 6 — Expected Simulation Result

1. **Reset** (`rst = 1`, first ~12ns): All state forced to `A_GREEN` internally, but since `rst` is checked only in the state register, outputs will show `roadA_green = 1, roadB_red = 1` (the reset state's outputs) once `state` settles.

2. **Normal operation** (after `rst = 0`, before emergency): You'll see 4 repeating phases in order — `roadA_green` high → `roadA_yellow` high → `roadB_green` high → `roadB_yellow` high — each lasting 4 clock periods (40ns each), repeating in a loop.

3. **Emergency activated** (`emergency = 1`): On the very next clock edge, regardless of where the cycle was, `roadA_green` snaps to 1 and `roadB_red` snaps to 1, and stays there for the whole time `emergency` is held high.

4. **Emergency removed** (`emergency = 0`): On the next clock edge, the FSM jumps to `A_GREEN` and the normal `A_GREEN → A_YELLOW → B_GREEN → B_YELLOW` cycle resumes from the beginning.

**Example expected sequence (state names) over time:**
```
rst=1:  A_GREEN (reset state)
rst=0:  A_GREEN -> A_YELLOW -> B_GREEN -> B_YELLOW -> A_GREEN -> A_YELLOW ...
emergency=1 (mid B_GREEN, say): -> EMERGENCY -> EMERGENCY -> EMERGENCY (stays)
emergency=0: -> A_GREEN -> A_YELLOW -> B_GREEN -> B_YELLOW -> ...
```

---

## PART 7 — Troubleshooting: 5 Common Errors

1. **"Module not found" / compile error mentioning `traffic_light` or `tb_traffic_light`**
   Fix: Make sure Part 1 is pasted in the Design box and Part 2 in the Testbench box — not both in the same box, and not swapped.

2. **No waveform / EPWave shows blank**
   Fix: Confirm `$dumpfile("dump.vcd"); $dumpvars(0, tb_traffic_light);` is present in the testbench, and that "Open EPWave after run" was checked before clicking Run.

3. **Simulator dropdown shows SystemVerilog/VHDL errors**
   Fix: Double check the language dropdown is set to **Verilog**, not SystemVerilog or VHDL — Icarus Verilog needs the Verilog mode selected.

4. **Simulation runs forever / times out**
   Fix: Verify the testbench has `$finish;` at the end of the `initial` block — without it, Icarus Verilog won't know when to stop.

5. **Outputs all show "x" (unknown) at time 0**
   Fix: This is normal for the first few nanoseconds before `rst` takes effect — signals settle to real 0/1 values once the first clock edge with `rst=1` occurs. If it persists past reset, check that `clk` is toggling (the `always #5 clk = ~clk;` line must be present and un-commented).

---

## PART 8 — Viva Preparation: 10 Simple Q&A

1. **Q: What is an FPGA?**
   A: A Field-Programmable Gate Array is a reconfigurable digital chip made of programmable logic blocks that can be configured to implement any digital circuit, including this traffic light controller.

2. **Q: What is Verilog?**
   A: Verilog is a Hardware Description Language (HDL) used to describe the structure and behavior of digital circuits, which can then be simulated or synthesized onto hardware like an FPGA.

3. **Q: What is an FSM (Finite State Machine)?**
   A: An FSM is a digital circuit model that moves between a fixed number of states based on inputs and clock edges; here, the states are A_GREEN, A_YELLOW, B_GREEN, B_YELLOW, and EMERGENCY.

4. **Q: Why is a traffic light controller a good FSM example?**
   A: Because it naturally has a small number of distinct states (which lights are on) and clear rules for moving between them based on time and priority inputs.

5. **Q: What is the role of the clock in this design?**
   A: The clock (`clk`) provides regular timing pulses; the FSM changes state only on the rising edge of the clock, and the internal timer counts clock cycles to decide how long each light stays on.

6. **Q: What is the role of reset in this design?**
   A: The `rst` signal forces the FSM back to a known starting state (`A_GREEN`) and resets the timer, ensuring the circuit always starts from a predictable condition.

7. **Q: How does the emergency priority system work?**
   A: The next-state logic checks `emergency` before the normal case statement — if `emergency = 1`, the FSM immediately transitions to the EMERGENCY state (Road A green, Road B red), overriding the normal light sequence.

8. **Q: What is a testbench, and why is it needed?**
   A: A testbench is a separate Verilog module that generates stimulus (clock, reset, emergency signals) for the design under test and lets you observe its outputs, without needing physical hardware.

9. **Q: What is simulation versus synthesis?**
   A: Simulation runs the Verilog code on a computer to verify logical behavior over time (what we did here with Icarus Verilog); synthesis converts the Verilog code into an actual gate-level circuit that can be programmed onto real FPGA hardware.

10. **Q: Why did you use `$dumpfile` and `$dumpvars`?**
    A: These system tasks tell the simulator to record signal value changes into a VCD (Value Change Dump) waveform file, which can then be viewed graphically in EPWave to visually verify circuit behavior.
