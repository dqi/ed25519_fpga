# Ed25519_fpga

For my research internship I wrote some code to explore the design space of
Ed25519 implementations. Intended for the CrypTech HSM.

We are able to compute signatures on 256-bit messages, given some private key
and the corresponding public key.

The code synthesises, maps, and routes at 50MHz.

TODO: run on the actual hardware, requires defining the pins etc etc.

## Quick HOWTO

- Install Xilinx ISE 14.7
- Add a new project:
```
Family: Artix7
Device: XC7A200T
Package: FBG484
Language: Verilog
```
- Add source: `src/rtl/ed25519_sign.v` (all),
  `src/tb/tb_ed25519_sign.v` (simulation) and if you want to do synthesis
  `ed25519_sign.ucf`.
- Generate test cases: `python gensigs.py` in the folder `src/model`
- Now you can run the simulation (in the simulation tab select the testbench and
  `Simulate Behavioral Model`). All tests *should* pass. Else you may create an
  issue.

For synthesis select the top module in the implementations window and
doubleclick `synthesise XST` and when it is done `implement design`.

Computing a signature takes ~5000 clock cycles.

