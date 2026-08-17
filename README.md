# FPGA-Based Traffic Light Controller with Priority System

A simple two-road traffic light controller designed in Verilog HDL, modeled as a Finite State Machine (FSM), with an **emergency vehicle priority override**. Built and simulated entirely on [EDA Playground](https://www.edaplayground.com) using the free Icarus Verilog simulator — no physical FPGA board or paid tools required.

## Project Overview

- **Road A** and **Road B** each have RED, YELLOW, and GREEN lights.
- Normal operation cycles through: `A_GREEN → A_YELLOW → B_GREEN → B_YELLOW → repeat`.
- An `emergency` input, when set high, immediately forces Road A to GREEN and Road B to RED, overriding the normal cycle. When `emergency` goes low again, the controller resumes the normal sequence from `A_GREEN`.

## Files

| File | Description |
|------|--------------|
| `traffic_light.v` | Main FSM design module |
| `tb_traffic_light.v` | Self-checking testbench (clock gen, reset, normal + emergency test cases, VCD waveform dump) |
| `Traffic_Light_Controller_Project.md` | Full project write-up: FSM table, build instructions, waveform explanation, troubleshooting, viva Q&A |

## FSM States

| State      | Road A | Road B |
|------------|--------|--------|
| A_GREEN    | GREEN  | RED    |
| A_YELLOW   | YELLOW | RED    |
| B_GREEN    | RED    | GREEN  |
| B_YELLOW   | RED    | YELLOW |
| EMERGENCY  | GREEN  | RED    |

## How to Simulate

1. Go to [EDA Playground](https://www.edaplayground.com).
2. Set language to **Verilog**, simulator to **Icarus Verilog**.
3. Paste `traffic_light.v` into the **Design** box.
4. Paste `tb_traffic_light.v` into the **Testbench** box.
5. Check **"Open EPWave after run"**, then click **Run**.
6. View the waveform in EPWave to confirm normal sequencing and emergency override behavior.

See `Traffic_Light_Controller_Project.md` for the full step-by-step guide, expected waveform behavior, and common troubleshooting tips.

## Tools Used

- Verilog HDL (Verilog-2001 style, synthesizable)
- Icarus Verilog (via EDA Playground) — free, browser-based simulation
- No physical FPGA board, Vivado, or ModelSim required

## Author

*(Add your name here)*
