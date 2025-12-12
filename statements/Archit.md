# Personal Statement - Archit

## Overview
This repository outlines the SystemVerilog implementation and comprehensive C++ verification suite for our processor. My primary contribution to this project was the **Verification and Integration infrastructure**, ensuring functional correctness from the block level up to full system program execution.

## Summary of Contributions

As the **Verification and Integration Lead**, I was responsible for the reliability of the CPU design and ensuring it met all requirements. I built the automated testing framework, developed the testbenches with GoogleTest integration, and integrated all the required tests with the infrastructure - showing output also on Vbuddy where applicable. I adapted the test software so it correctly interfaces with our modules across different branches and implementations of the processor.

Skeleton code for parts of the software was provided: `verify.cpp`, `cpu_testbench.h`, etc. and I adapted these to our implementation where required.

| Module Group | Specific Modules | Role |
| :--- | :--- | :--- |
| **Verification Infrastructure** | `doit.sh`, `verify.cpp`, `execute_pdf.cpp`, `execute_f1.cpp` | **Lead** |
| **Unit Testing** | `tb/unit_tests` | **Lead** |
| **Hardware Interface** | Vbuddy integration | **Lead** |

---

## Technical Implementation Details

### 1. Automated Regression Testing Framework (`doit.sh`)
To streamline the development cycle, I engineered a robust bash automation script that handles compilation, linking, and execution of tests.

At a high level:
* **Dynamic Test Selection:** Implemented a menu-driven system to run specific suites (**Unit**, **Program**, or **VBuddy**), reducing iteration time during targeted debugging.
* **Targeted Module Testing:** The script allows for further debugging by targeting any specific testbench script.
* **Output Management:** Integrated logic to capture Verilator output, using **GoogleTest** to display results in terminal, dumping waveforms to inspect using waveform viewing software, and passing output to display on Vbuddy.

In order to implement this technically:
* **Environment & Input Handling:** The script initializes by dynamically resolving directory paths relative to the script location (`dirname`, `realpath`) to ensure portability across different development environments. It implements an argument parser that accepts specific testbench files for targeted debugging or defaults to an interactive read/case menu for batch execution of Unit, Program, or VBuddy test suites.

* **Compilation & Linkage:** Inside the execution loop, the script derives the Device Under Test (DUT) name from the testbench filename using string manipulation. It invokes the verilator toolchain with specific configuration flags: --trace to enable VCD waveform dumping, and -LDFLAGS to link the generated C++ model against the GoogleTest and pthread libraries.

* **CI Compatibility:** The script tracks the cumulative pass/fail state of the batch and terminates with a specific exit code (exit 0 or 1), ensuring the test suite can be integrated into Continuous Integration (CI) pipelines.

### 2. GoogleTest Integration & Base Class Design
I replaced ad-hoc verification with the **GoogleTest** framework.
* **`BaseTestbench` Class:** This handles Verilator boilerplate (clock generation, trace dumping, signal initialization), streamlining the process of writing other unit tests and verification scripts, allowing them to focus purely on logic verification.

### 3. Control Unit Verification Strategy
I developed `controlunit_tb.cpp` to validate strict adherence to the RISC-V ISA.
* **Signal Mapping:** Identified and resolved discrepancies between the Decoder implementation and Datapath requirements (e.g., enforcing correct `Op1Src` vs `ALUSrc` distinctions).

### 4. Visual Hardware Verification (VBuddy)
I implemented the C++ driver logic for the `execute_f1` and `execute_pdf` tests to interface with the VBuddy peripheral.

---

## Reflection & Design Decisions

### Design Decision: Segregation of Test Suites
**Rationale:** I explicitly separated **Unit Tests** from **Program Tests**. In the project, debugging top-level failures was inefficient. By enforcing passing Unit Tests first, we ensured that individual modules were initially compliant to the RISC-V ISA and each provided the expected outputs, so top-level debugging was focused solely on integration issues, significantly speeding up the development cycle.

---

## Mistakes & Challenges
* **Initially, I did not write robust and future-proof** execution scripts and testbench execution helper files. My code did not offer the flexibility to work with different versions of the CPU, different types of tests (unit tests, full program executions etc.) and additionally, it was then a challenge to integrate Vbuddy hardware later on. **This led to heavy code refactoring** and multiple rewrites of the testing directory and structure to make it suitable for all requirements, which could have been avoided by keeping future requirements in mind while writing code to meet current requirements.

* **Naively copying unit tests and other testbench files between different branches containing different versions of the CPU does not work.** This is usually because of mismatched ports and logically expecting different module output results to handle additional functionality. I instead had to rewrite testbenches in order to be bespoke to the CPU version of the branch they were in.

## Learnings

* **Scalability in Test Automation:** I learned that test infrastructure must be designed with **extensibility** in mind. Anticipating future requirements—such as distinct test modes (Unit vs. System) or hardware integration—reduces technical debt and prevents the need for complete rewrites later in the project lifecycle.

* **Tight Coupling of Verification and Design:** Verification is tightly coupled to the module interface. I learned that while test *logic* can be reused, the test *harness* must evolve alongside the hardware design. This reinforced the importance of maintaining version-specific testbenches rather than relying on a more general approach.

* **The Value of Interface Specifications:**
The friction we experienced when integrating the Control Unit (mismatched signal names like `Op1Src` vs `ALUSrcA`) highlighted a critical lesson in system integration. A testbench requires complete understanding of the specification. I learned that defining clear interface control, or naming convention at the start of a project is as crucial as the code itself, as it aligns the expectations of the Design Team and the Verification Team.

* **Conducting unit testing:** This is a skill I have developed throughout this project. Despite often requiring high volume code, attention to detail is vital and each line must be manually verified. Issues with the testbench may falsely indicate problems with the modules being tested. This can drastically slow down progress.

## Potential Future Work
* **FPGA Prototyping:** Adapt the design for synthesis on an FPGA. This would require replacing the C++ testbench input/output with physical UART or GPIO interfaces to verify the processor runs correctly on real silicon hardware.
* **Fuzz Testing:** Implement a randomized instruction generator to catch edge cases against a Golden Reference model.
* **Continuous Integration (CI):** Configure a GitHub Actions workflow to automatically execute the `doit.sh` regression script on every repository push. This would ensure immediate feedback on whether new changes impact existing functionality (regression testing).