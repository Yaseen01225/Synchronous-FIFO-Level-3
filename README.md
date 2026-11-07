# Level 3 – Parameterized Synchronous FIFO with Status Monitoring

A parameterized, single-clock **synchronous FIFO** in Verilog-2001 with advanced status monitoring: full / empty /
almost-full / almost-empty flags, a live occupancy count, and saturating counters for rejected writes and reads.

| | |
|---|---|
| **Developer** | Ghulam Yaseen Nangraj |
| **Date** | 07 November 2026 |
| **Design level** | Level 3 – FIFO with advanced status monitoring |
| **Language** | Verilog HDL (IEEE 1364 / Verilog-2001) |
| **Tools** | Xilinx Vivado 2025.2.1, Vivado Simulator (XSim) |

---

## Features

- Single clock domain, active-high **synchronous** reset
- Configurable data width, depth and almost-full / almost-empty thresholds
- `full`, `empty`, `almost_full`, `almost_empty` flags decoded from an occupancy counter
- `count` output: number of valid words currently stored
- Simultaneous read and write support (occupancy unchanged)
- **Explicit pointer wraparound** – works for power-of-two and non-power-of-two depths
- Rejected-write and rejected-read monitoring with **saturating** counters
- Registered read-data output

## Repository Contents

| File | Description |
|---|---|
| `status_fifo.v` | FIFO design (module `status_fifo`) |
| `tb_status_fifo.v` | Self-checking testbench (module `tb_status_fifo`) |
| `Level3_Status_FIFO_Report.docx` | Detailed project report |
| `README.md` | This file |

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `DATA_WIDTH` | `8` | Bits per FIFO word |
| `DEPTH` | `8` | Number of storage locations |
| `ADDR_WIDTH` | `3` | Pointer width (must address `DEPTH` locations) |
| `COUNT_WIDTH` | `4` | Occupancy counter width (must represent 0 … `DEPTH`) |
| `ALMOST_FULL_LEVEL` | `6` | `almost_full` is HIGH when `count >=` this value |
| `ALMOST_EMPTY_LEVEL` | `2` | `almost_empty` is HIGH when `count <=` this value |
| `ERROR_WIDTH` | `8` | Width of the rejected-operation counters |

## Ports

| Port | Dir | Width | Description |
|---|---|---|---|
| `clk` | in | 1 | Clock (rising edge) |
| `rst` | in | 1 | Active-high synchronous reset |
| `wr_en` | in | 1 | Write request |
| `data_in` | in | `DATA_WIDTH` | Write data |
| `rd_en` | in | 1 | Read request |
| `data_out` | out | `DATA_WIDTH` | Registered read data |
| `full` | out | 1 | `count == DEPTH` |
| `empty` | out | 1 | `count == 0` |
| `almost_full` | out | 1 | `count >= ALMOST_FULL_LEVEL` |
| `almost_empty` | out | 1 | `count <= ALMOST_EMPTY_LEVEL` |
| `count` | out | `COUNT_WIDTH` | Number of stored words |
| `rejected_writes` | out | `ERROR_WIDTH` | Saturating count of rejected writes |
| `rejected_reads` | out | `ERROR_WIDTH` | Saturating count of rejected reads |

## How It Works

```
          wr_en/data_in                         rd_en
               │                                  │
   full ──► wr_accept = wr_en && !full     rd_accept = rd_en && !empty ◄── empty
               │                                  │
        ┌──────▼──────┐   memory[0:DEPTH-1]  ┌────▼───────┐
        │ write block │ ───────────────────► │ read block │──► data_out
        │ wr_ptr      │                      │ rd_ptr     │
        │ rej_writes  │                      │ rej_reads  │
        └──────┬──────┘                      └────┬───────┘
               └─────────────┐        ┌───────────┘
                       ┌─────▼────────▼─────┐
                       │ occupancy counter  │──► count ──► flag decode
                       └────────────────────┘
```

- A write is **accepted** when `wr_en && !full`: `data_in` goes to `memory[wr_ptr]` and `wr_ptr` advances (wrapping from `DEPTH-1` to 0).
- A read is **accepted** when `rd_en && !empty`: `memory[rd_ptr]` is loaded into `data_out` and `rd_ptr` advances (wrapping).
- `count`: write only → +1, read only → −1, both or none → unchanged.
- A write on a full FIFO / read on an empty FIFO is **rejected** and increments the corresponding counter until it saturates at `{ERROR_WIDTH{1'b1}}`.

### Behavior for every request combination

| State | `wr_en` | `rd_en` | Result | `count` | Counters |
|---|:-:|:-:|---|:-:|---|
| Empty | 1 | 0 | Write accepted | 0 → 1 | – |
| Empty | 0 | 1 | Read rejected | 0 → 0 | `rejected_reads` + 1 |
| Empty | 1 | 1 | Write accepted, read ignored | 0 → 1 | – |
| Partly full (4) | 1 | 0 | Write accepted | 4 → 5 | – |
| Partly full (4) | 0 | 1 | Read accepted | 4 → 3 | – |
| Partly full (4) | 1 | 1 | Both accepted | 4 → 4 | – |
| Full | 1 | 0 | Write rejected | 8 → 8 | `rejected_writes` + 1 |
| Full | 0 | 1 | Read accepted | 8 → 7 | – |
| Full | 1 | 1 | Read accepted, **write dropped** | 8 → 7 | – (not counted) |

## Testbench

`tb_status_fifo.v` uses the default parameters and a 10 ns clock (100 MHz), changing inputs on falling edges.

| Step | Action | Check |
|---|---|---|
| 1 | Reset for 12 ns | – |
| 2 | Write words 0 … 7 | – |
| 3 | Stop writing | `full`, `almost_full`, `count == 8` |
| 4–5 | Try one more write (`EE`) | `rejected_writes != 0` |
| 6 | Read eight words | – |
| 7 | Stop reading | `empty`, `almost_empty` |
| 8–9 | Try one more read | `rejected_reads != 0` |
| 10 | Print `LEVEL 3 PASS`, `$finish` | – |

Expected output:

```
LEVEL 3 PASS
```

Key events from a cycle-accurate analysis of the design and testbench timing: first write at 25 ns; `almost_empty` falls at 45 ns;
`almost_full` rises at 75 ns; `full` at 95 ns; rejected write at 105 ns; first read at 115 ns; `empty` at 185 ns;
rejected read at 205 ns; test ends at 210 ns.

## How to Run

### Vivado / XSim (GUI)

1. Create an RTL project and add `status_fifo.v` as a design source.
2. Add `tb_status_fifo.v` as a simulation source and set `tb_status_fifo` as the simulation top.
3. **Run Simulation → Run Behavioral Simulation**, then `run all`.
4. Look for `LEVEL 3 PASS` in the Tcl Console and inspect `count`, the flags and the rejection counters in the waveform.

### Vivado command line

```bash
xvlog status_fifo.v tb_status_fifo.v    # add -sv if $fatal is rejected
xelab tb_status_fifo -debug typical -s tb_sim
xsim  tb_sim -runall
```

### Icarus Verilog

```bash
iverilog -g2012 -o fifo_sim status_fifo.v tb_status_fifo.v
vvp fifo_sim
```

## Design Notes and Limitations

- **Simultaneous request corner cases.** When the FIFO is full and both `wr_en` and `rd_en` are HIGH, the read is served but the write is neither stored nor counted as rejected (`wr_accept` uses `!full`, while the error condition excludes cases with a valid read). A read on an empty FIFO that coincides with a write is likewise ignored without being counted. Consider `wr_accept = wr_en && (!full || rd_accept)` or counting the dropped request.
- **Testbench does not check data.** `data_out` is never compared with the written values, so data ordering is only visible in the waveform. The first word written is `0`, equal to the reset value of `data_out`.
- Not exercised by the testbench: simultaneous read/write, intermediate flag levels, counter saturation, multiple pointer wraps, non-power-of-two depth, reset during operation.
- `COUNT_WIDTH` must be large enough for `DEPTH` (e.g. 4 bits for 8); parameters are not cross-checked.
- `almost_full` / `almost_empty` are inclusive of `full` / `empty`.
- Read data is registered: valid one clock after an accepted read; no first-word-fall-through mode or valid flag.
- `$fatal` is a SystemVerilog task; use `-sv` or replace with `$display` + `$finish` if the tool rejects it in a `.v` file.

## Possible Improvements

- Fix the simultaneous read/write corner cases above.
- Add a scoreboard (reference queue) and randomized tests for read/write mix, wraparound and saturation.
- Make thresholds programmable inputs; add sticky overflow/underflow flags.
- Move on to the next level: an asynchronous FIFO with Gray-coded pointers.
