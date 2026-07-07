# FPGA Design Library

![Language](https://img.shields.io/badge/Language-VHDL-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![FPGA](https://img.shields.io/badge/Target-FPGA-orange)
![Status](https://img.shields.io/badge/Status-Active-success)

A curated collection of reusable, synthesizable, and production-quality FPGA IP cores written in VHDL.

This repository is a continuously growing library of parameterizable RTL building blocks, verification environments, and reference designs developed to promote clean, maintainable, and high-performance FPGA design. The library ranges from fundamental digital logic components to complete communication interfaces, DSP architectures, and system-level FPGA infrastructure.

Every module is developed with a strong emphasis on:

Reusability
Parameterization and scalability
Synthesizable, FPGA-friendly RTL
Production-quality coding practices
Timing-aware design
Comprehensive documentation
Self-checking testbenches
Verification-driven development
Portability across FPGA families

The long-term goal of this repository is to provide a comprehensive FPGA design library that reflects industry best practices and serves as a reference for both learning and professional FPGA development.
---

# Repository Structure

```
FPGA-Design-Library
│
├── Counters
│   ├── Binary Counter
│   ├── Mod-M Counter
│   ├── Ring Counter
│   ├── Johnson Counter
│   ├── Gray Counter
│   └── Timer
│
├── Shift Registers
│   ├── Universal Shift Register
│   ├── LFSR
│   ├── SISO
│   ├── SIPO
│   ├── PISO
│   └── PIPO
│
├── Arithmetic
│   ├── Adder
│   ├── Subtractor
│   ├── Multiplier
│   ├── Divider
│   ├── Comparator
│   └── ALU
│
├── Memory
│   ├── Single Port RAM
│   ├── Dual Port RAM
│   ├── ROM
│   ├── Register File
│   └── FIFO
│
├── PWM
│
├── UART
│
├── SPI
│
├── I2C
│
├── AXI
│   ├── AXI Lite
│   ├── AXI Stream
│   ├── AXI DMA Examples
│   └── AXI Interconnect
│
├── DSP
│   ├── FIR Filter
│   ├── Moving Average
│   ├── MAC
│   ├── DDS
│   ├── NCO
│   └── CORDIC
│
├── CNN
│
├── Video Processing
│
├── Ethernet
│
├── PCIe
│
├── Utility
│
├── Common Packages
│
├── Testbenches
│
└── Documentation
```

---

# Design Philosophy

Every IP in this repository follows a common design philosophy.

## RTL Design

- Fully synthesizable
- Vendor-independent where possible
- Generic and reusable
- Single clock domain whenever practical
- FPGA resource optimized
- Readable coding style
- Consistent naming conventions

---

## Verification

Each module includes a dedicated self-checking VHDL testbench.

Verification typically covers:

- Reset behaviour
- Normal operation
- Corner cases
- Boundary conditions
- Error conditions
- Functional assertions

Whenever applicable, simulation-only debug interfaces are used to enable exhaustive verification without impacting synthesized hardware.

---

## Documentation

Each IP contains:

- Design overview
- Interface description
- Timing behaviour
- Functional description
- Architecture explanation
- Verification notes
- Usage examples

---

# Coding Guidelines

The following conventions are used throughout the repository.

### Naming

| Item | Convention |
|-------|------------|
| Entity | lower_case |
| Architecture | rtl |
| Signals | snake_case |
| Processes | descriptive_name_pr |
| Constants | UPPER_CASE |
| Generics | UPPER_CASE |

---

### Reset Strategy

Unless otherwise specified:

- Synchronous reset
- Active High
- Single clock domain

---

### Numeric Types

Arithmetic operations use:

```
IEEE.NUMERIC_STD
```

Avoid use of:

```
std_logic_unsigned
std_logic_arith
```

---

# Current IPs

## Counters

| Module | Status |
|---------|--------|
| Binary Counter | ✅ |
| Mod-M Counter | ✅ |
| Ring Counter | ✅ |
| Gray Counter | ✅ |
| Timer | ✅ |
| Johnson Counter | 🚧 |

---

## Shift Registers

| Module | Status |
|---------|--------|
| Universal Shift Register | ✅ |
| SISO | 🚧 |
| SIPO | 🚧 |
| PISO | 🚧 |
| PIPO | 🚧 |

---

## Upcoming Modules

- UART
- SPI
- I2C
- AXI Lite Master
- AXI Stream Master
- AXI Stream FIFO
- AXI DMA
- FIFOs
- PWM
- CORDIC
- FIR Filter
- Sobel Filter
- Line Buffer
- CNN Accelerator Components

---

# Target Tools

The RTL has been developed and verified using:

- AMD Vivado
- ModelSim / QuestaSim (where applicable)

The designs are intended to remain portable across FPGA vendors whenever possible.

---

# Goals

The long-term goal of this repository is to build a comprehensive FPGA IP library covering:

- Basic RTL Components
- Communication Interfaces
- Memory Architectures
- DSP Algorithms
- Image Processing
- AI Accelerators
- High-Speed Digital Design
- Verification Examples

The repository is intended to be useful for:

- FPGA Engineers
- Students
- Researchers
- Interview Preparation
- RTL Design Learning
- Rapid FPGA Development

---

# Contributing

Suggestions, improvements and bug reports are always welcome.

If you discover an issue or have an idea for improvement, feel free to open an issue or submit a pull request.

---

# License

This project is released under the MIT License.

---

# Author

**Shekhar Mishra**

FPGA Design Engineer

Building reusable FPGA IP one module at a time.
