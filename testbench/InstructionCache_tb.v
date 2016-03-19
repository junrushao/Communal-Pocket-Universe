`include "InstructionCache.v"
module InstructionCache_tb;
	`include "Utility.v"
	reg[31: 0]       readPtr;
	wire[31: 0]      readValue;
	wire             readSuccess;
	wire[NUMBER_OF_BLOCKS_IN_CACHE - 1: 0] busy;
	reg clk, reset;
	InstructionCache iCache(readPtr, readValue, readSuccess, busy, reset, clk);
	always #0.5 clk = ~clk;
	initial
	begin
		clk = 0;
		reset = 1;
		#0.5 reset = 0;
	end
	always begin
		readPtr = 0;
		while (readPtr < 5)
		begin
			#2;
			while (readSuccess !== 1'b1)#1;
			$display("time = %g, readPtr = %d, readValue = %b\n", $realtime, readPtr, readValue);
			readPtr = readPtr + 1;
		end
		$finish;
	end
	
endmodule
