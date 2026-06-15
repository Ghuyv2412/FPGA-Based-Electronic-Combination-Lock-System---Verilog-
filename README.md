# FPGA-Based Electronic Combination Lock System (Altera DE2)

This repository contains the design and hardware implementation of a **Secure Electronic Combination Lock System (4-digit PIN)** deployed on the **Altera DE2 (Cyclone II FPGA)** development kit. Built entirely from scratch using **Verilog HDL**, the system features a hardware-centric, multi-layered architectural design leveraging Finite State Machines (FSM) and high-speed parallel processing.

---
## Authors
Gia Huy Vo @Ghuyv2412

---

## Key Features

* **Flexible User Interface:** Supports 4-digit PIN entry with active hardware implementations for backspacing (`Backspace` key) to correct individual digits or erasing the entire buffer (`Clear` key).
* **Hardware-Level Security:** Incorporates a symmetric **XOR Masking** technique (`16'h9554`) to obscure the master password before storing it in registers, preventing raw memory extraction.
* **Secure PIN Alteration:** Allows authenticated users to update and configure a new password directly on the system after successfully verifying the current password.
* **Intelligent Alarm & Security Lockout:** Automatically triggers a continuous 2Hz flashing alert sequence (Red LEDs and an active buzzer) upon 3 consecutive invalid authentication attempts.
* **Real-time Status Feed:** Displays operational statuses, clear user prompts, and visual cues via a 16x2 character LCD and a multiplexed 4-digit 7-segment LED display cluster.
* **Global Hardware Reset:** Includes a dedicated asynchronous physical override to restore the entire network to a safe initial state instantly in case of an emergency.

---

## Hardware Requirements

1.  **Core Processor:** Altera DE2 Board - Cyclone II FPGA (running on a base 50 MHz clock oscillator for zero-latency execution).
2.  **Input Peripheral:** 4x4 Matrix Keypad.
3.  **Display Modules:** 16x2 LCD (driven by the HD44780 controller) & 4 Common-Anode 7-Segment displays.
4.  **Indicators & Alarms:** Physical 3V Active/Passive Buzzer & Discrete Red LEDs.

---

## Verilog Module Architecture

### 1. Input Preprocessing Block (`TOP_INPUT`)
* `chia_xung.v` (Clock Divider): Steps down the onboard 50MHz oscillator to generate specialized frequencies: 1kHz for keypad matrix scanning and 100Hz for debouncing logic.
* `quetkeypad.v` (Keypad Scanner): Executes time-division multiplexed matrix scanning across rows and columns to resolve the exact 4-bit Hex value of pressed keys.
* `chongnhieu.v` (Debouncer): Employs a low-pass sampling filter (20ms window) coupled with a Falling-Edge Detector to eliminate mechanical button bouncing and prevent duplicate inputs.
* `top_input.v`: The master wrapper that synchronizes and pipes clean, debounced input triggers to the core system.

### 2. Core Logic & Datapath (`LOGIC_TOP`)
* `shiftbuffer.v`: Manages a 16-bit right-to-left shift register for live password inputs. It handles blanking states (`4'hF`) to turn off unused display modules smoothly.
* `passdatapath.v`: The hardware "vault." It securely retains the password and executes bitwise verification using a high-speed XNOR-AND gate matrix combined with an XOR mask.
* `fsm_controller.v`: The central controller managing execution flows across 6 distinct states: Idle (`S_IDLE`), Input (`S_INPUT`), Compare (`S_COMPARE`), Open (`S_OPEN`), Wrong/Alarm (`S_WRONG`), and Change Password.
* `logic_top.v`: The top-level wrapper linking the controller, security datapath, and shift registers together.

### 3. Output Processing Block (`OUTPUT_TOP`)
* `led_7_doan.v`: Decodes binary register variables into 7-segment display patterns mapped specifically for common-anode hardware.
* `warning_buzzer.v`: Uses an overflow counter (driven by a 12.5M factor) to toggle the buzzer and red alarm LEDs synchronously at a crisp 2Hz frequency.
* `lcd_controller.v`: Governs parallel 8-bit communication buses and exact timing sequences to write dynamic ASCII instruction strings onto the HD44780 LCD panel.
* `output_top.v`: Final packaging wrapper that physically routes synthesized logic ports straight to the FPGA pin assignments.

