# APB3 Master Formal Verification

## Overview

This project demonstrates **formal verification of an APB3 Master design** using **SystemVerilog Assertions (SVA)**.
The APB3 master is verified by **assuming correct APB3 slave behavior** and proving that the master complies with the APB3 protocol and functional requirements under all valid scenarios.

The verification is **exhaustive**, covering all legal APB3 slave responses without relying on simulation-based test stimulus.

---

## Verification Approach

* The **APB3 Master** is treated as the **Design Under Test (DUT)**
* The **APB3 Slave behavior is constrained using assumptions**
* Formal tools explore **all legal slave responses**
* Assertions are used to prove correctness of master behavior

This ensures the APB3 master behaves correctly in all valid environments.

---

## Assumed APB3 Slave Behavior

The slave is constrained using assumptions to model legal APB3 responses:

* `PREADY` asserted only during access phase
* Slave responds within allowed wait-state limits
* `PRDATA` valid only for read transactions
* `PSLVERR` asserted only for error responses
* No protocol-violating signal behavior

These assumptions define a **legal APB3 slave environment** for formal analysis.

---

## Verified Properties

The following properties of the APB3 master are formally verified:

### Protocol Compliance

* Correct setup and access phase sequencing
* Proper assertion and deassertion of `PSEL` and `PENABLE`
* Stable address and control signals during access
* Correct sampling of `PREADY`

### Functional Correctness

* Correct initiation of read and write transfers
* Proper handling of wait states
* Correct completion of back-to-back transfers

### Error Handling

* Correct handling of `PSLVERR`
* No spurious or missed error responses

### Reset Behavior

* Master starts in a known idle state after reset
* No bus activity during reset

---

## Assertions and Coverage

* **SystemVerilog Assertions (SVA)** used to prove:

  * Protocol rules
  * Functional properties
* **Formal coverage** used to confirm:

  * Read and write paths are reachable
  * Wait-state scenarios are explored
  * Error and non-error responses are exercised

---

## Benefits of Formal Verification

* Exhaustive verification of all legal APB3 slave behaviors
* Detection of corner-case protocol bugs
* No dependency on directed or random stimulus
* Increased confidence in master correctness

---

## Tools & Technology

* **Language**: SystemVerilog
* **Methodology**: Formal Property Verification
* **Assertions**: SystemVerilog Assertions (SVA)
* **Applicable Tools**: JasperGold / VC Formal

---

## Status

* APB3 master formally verified
* Slave behavior fully constrained using assumptions
* All protocol and functional properties proven

---
