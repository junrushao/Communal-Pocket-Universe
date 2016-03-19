# OurCPU

## Overview
Communal Pocket Universe, a simple CPU implementing Tomasulo's Algorithm with reorder buffer.

See ./report/main.pdf for more details.

The project is by Junru Shao and Xinyun Chen (@Jungyhuk).

## System Requirements
* Ubuntu >= 14.04
* [iverilog](https://github.com/steveicarus/iverilog) >= 0.10.0 (devel) 
* Java: Oracle JRE >= 1.8
* gtkwave >= v3.3.65

## How to Test
First, Place the assembly file input.in in the directory assembler, and the data file data.hex at the current directory.

Second, execute instruction “make”.

To run the simulation, execute instruction “run”.

To view wave file, execute instruction “gtkwave CPU.lxt”.

To run testbench, execute the corresponding instructions

~~~{bash}
make testALUReservationStation
make testDataCache
make testInstructionCache
make testLoadReservationStation
make testRegisterFile
make testRegisterStatusTable
make testStoreReservationStation

make testAll
~~~

