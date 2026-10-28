# Hamming (7,4) error check

Verilog that encodes 4 data bits into 7 bits and corrects one flipped bit, but not two.

## How it works

Positions 1/2/4 are parity bits and 3/5/6/7 are data. `data_in[3:0]` maps to positions 3/5/6/7 in order. Parity is even. P1 covers 1/3/5/7, P2 covers 2/3/6/7, and P4 covers 4/5/6/7. Position 7 is written first, so `1011` encodes to `1100110`.

With at most one flipped bit, syndrome 0 means no error. Values 1 to 7 name the flipped bit, and the decoder flips it back. With two flipped bits, the decoder flips the wrong bit and the data stays wrong.

## Run it on EDA Playground

Open the [saved playground](https://edaplayground.com/x/Dczm), titled "Hamming (7,4) error check", or copy in the [design](rtl/hamming74.v) and [testbench](tb/tb_hamming74.v), with `tb_hamming74` as top. In Tools & Simulators, pick Cadence Xcelium 25.03, using the SystemVerilog design/testbench editors. Set Compile Options to `-timescale 1ns/1ns -sysv` and Run Options to `-access +rw`. Tick Open EPWave after run, then click Run.

In EPWave, click Get Signals, open `tb_hamming74`, and pick signals. `$dumpfile("dump.vcd")` and `$dumpvars` are already set for Cadence.

## Results

All 128 checks pass, 16 clean plus 112 single-bit errors, and the two-bit example returns wrong data as expected. Files: [VCD](sim/waveform.vcd), [raw xrun.log](sim/xrun.log).

![EPWave waveform](images/waveform.png)

*EPWave, binary, about 0 to 172 ns. First 100 ns are directed tests, then exhaustive tests. Leading zeros are omitted, so `11` on `data_out[3:0]` means `0011`.*

![Cadence run log](images/output.png)

*Cadence Xcelium 25.03 log in Chrome, code and simulator selection visible.*
