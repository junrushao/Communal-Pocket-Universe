all:
	@echo "Compiling CPU.v"
	iverilog CPU.v -o CPU
	@echo "Compilation complete"
	
	@echo "Compiling assembly"
	cd ./assembler && java -jar NaiveAssembler.jar < input.in > ../code.bin
	@echo "Compilation complete"
	
run:
	vvp CPU -lxt2

testALUReservationStation:
	@echo "Compiling testbench for ALUReservationStation.v"
	iverilog ./testbench/ALUReservationStation_tb.v -o ALUReservationStation_tb
	@echo "Compilation complete"

	@echo "Running test"
	vvp ALUReservationStation_tb
	@echo "Done"

testDataCache:
	@echo "Compiling testbench for DataCache.v"
	iverilog ./testbench/DataCache_tb.v -o DataCache_tb
	@echo "Compilation complete"

	@echo "Running test"
	vvp DataCache_tb
	@echo "Done"

testInstructionCache:
	@echo "Compiling testbench for InstructionCache.v"
	iverilog ./testbench/InstructionCache_tb.v -o InstructionCache_tb
	@echo "Compilation complete"

	@echo "Running test"
	vvp InstructionCache_tb
	@echo "Done"

testLoadReservationStation:
	@echo "Compiling testbench for LoadReservationStation.v"
	iverilog ./testbench/LoadReservationStation_tb.v -o LoadReservationStation_tb
	@echo "Compilation complete"

	@echo "Running test"
	vvp LoadReservationStation_tb
	@echo "Done"

testRegisterFile:
	@echo "Compiling testbench for RegisterFile.v"
	iverilog ./testbench/RegisterFile_tb.v -o RegisterFile_tb
	@echo "Compilation complete"

	@echo "Running test"
	vvp RegisterFile_tb
	@echo "Done"

testRegisterStatusTable:
	@echo "Compiling testbench for RegisterStatusTable.v"
	iverilog ./testbench/RegisterStatusTable_tb.v -o RegisterStatusTable_tb
	@echo "Compilation complete"

	@echo "Running test"
	vvp RegisterStatusTable_tb
	@echo "Done"

testStoreReservationStation:
	@echo "Compiling testbench for StoreReservationStation.v"
	iverilog ./testbench/StoreReservationStation_tb.v -o StoreReservationStation_tb
	@echo "Compilation complete"

	@echo "Running test"
	vvp StoreReservationStation_tb
	@echo "Done"
	
testAll: testALUReservationStation testDataCache testInstructionCache testLoadReservationStation testRegisterFile testRegisterStatusTable testStoreReservationStation
	@echo "test done"
	

