# FPGA UART TEST

This repository contains a simple FPGA UART communication and arithmetic operation code and it's simulation test environment using python scripts and VHDL textio

### Architectural Design

This project involves the development of a hardware module designed in VHDL, 
which performs addition or subtraction on two 16-bit numbers received via the UART protocol, 
verifies the message integrity using checksum validation, and transmit the result via UART.

### The incoming message is structured as: 
| Header | Num1 | Num2 | Opcode | Checksum |
| -----: | :----: | :--- | :----: | :--- |
| 2 Bytes| 2 Bytes | 2 Bytes | 1 Bytes | 1 Bytes |


#### Opcode:
* If 0, perform <mark> Num1 + Num2 </mark>.
* If 1, perform <mark> Num1 - Num2 </mark>.

#### Checksum: 
The checksum calculation ensures that the sum of the entire packet, including the checksum itself, modulo 256 (last 8 bits of the sum), is 0x00.

```
Example incoming message: BACD001000200049
BACD  [header] 
0010  [Num1] (decimal 16) 
0020  [Num2] (decimal 32)
00    [opcode] 
49    [checksum] 
```

When this message is received, the desired operation is performed, and the response is returned in the following format:

### The Response message format is structured as:

| Header | Result | Checksum |
| -----: | :----: | :--- |
| 2 Bytes| 2 Bytes | 1 Bytes |

```
Response Message: ABCD003058
ABCD  [header] 
0030  [result] 
58    [checksum] 
```

---
```
Example datas:

Incoming Message : BACD001000200049 
Response Message : ABCD003058

Incoming Message : BACD001000200148 
Response Message : ABCDFFF099

Incoming Message : BACDC3B83CDE00E4
Response Message : ABCD0096F2
```
---
Additional video link on similar topic:  
https://www.youtube.com/watch?v=ECLJU3-0SzU&list=PLZyLAHn509339oyv3vi-3Gdyb8bfPx7Ro&index=22

---

<p align="left"><img src="images/waveform.png?raw=true"></p>