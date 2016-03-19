`include "DataCache.v"
module DataCache_tb;
	`include "Utility.v"
	reg[31: 0]       readPtrA;
	wire[31: 0]      readValueA;
	wire             readSuccessA;
	reg[31: 0]       readPtrB;
	wire[31: 0]      readValueB;
	wire             readSuccessB;
	reg[31: 0]       readPtrC;
	wire[31: 0]      readValueC;
	wire             readSuccessC;
	reg             writeEnable;
	reg[31: 0]       writePtr;
	reg[31: 0]       writeValue;
	wire              writeSuccess;
	wire              allWriteBack = 1'b0;
	wire              allWriteBackSuccess;
	wire[NUMBER_OF_BLOCKS_IN_CACHE - 1: 0] busy;
	reg clk, reset;
	DataCache dCache(readPtrA, readValueA, readSuccessA,readPtrB, readValueB, readSuccessB,readPtrC, readValueC, readSuccessC,writeEnable,
	writePtr, writeValue, writeSuccess,allWriteBack, allWriteBackSuccess,busy, reset, clk);
	always #0.5 clk = ~clk;
	initial
	begin
		clk = 0;
		reset = 1;
		#0.5 reset = 0;
	end
	always begin
		readPtrA = 0;
		while (readSuccessA !== 1'b1)#1;
		$display("time = %g, readPtrA = %d, readValueA = %h\n", $realtime, readPtrA, readValueA);
		#2;
		readPtrB = 11;
		while (readSuccessB !== 1'b1)#1;
		$display("time = %g, readPtrB = %d, readValueB = %h\n", $realtime, readPtrB, readValueB);
		writePtr = 1;
		writeValue = 50;
		writeEnable = 1;
		while (writeSuccess !== 1'b1)#1;
		#2;
		readPtrB = 1;
		while (readSuccessB !== 1'b1)#1;
		$display("time = %g, readPtrB = %d, readValueB = %h\n", $realtime, readPtrB, readValueB);
		#2;
		readPtrB = 67;
		while (readSuccessB !== 1'b1)#1;
		$display("time = %g, readPtrB = %d, readValueB = %h\n", $realtime, readPtrB, readValueB);
		readPtrA = 9;
		while (readSuccessA !== 1'b1)#1;
		$display("time = %g, readPtrA = %d, readValueA = %h\n", $realtime, readPtrA, readValueA);
		#2;
		readPtrA = 1;
		while (readSuccessA !== 1'b1)#1;
		$display("time = %g, readPtrA = %d, readValueA = %h\n", $realtime, readPtrA, readValueA);
		$finish;
	end
	
endmodule
