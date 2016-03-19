`include "RegisterFile.v"
module RegisterFile_tb;
	`include "Utility.v"
	reg[REGISTER_NUMBER_LOG - 1: 0]          readIndexA = 5'b0;
	wire[31: 0]                              readValueA;
	reg[REGISTER_NUMBER_LOG - 1: 0]          readIndexB = 5'b1;
	wire[31: 0]                              readValueB;
	reg[REGISTER_NUMBER_LOG - 1: 0]          writeIndex;
	reg[31: 0]                               writeValue;
	reg clk, reset;
	RegisterFile regFile(readIndexA, readValueA, readIndexB, readValueB, writeIndex, writeValue, reset, clk);
	
	always #0.5 clk = ~clk;
	initial
	begin
		clk = 0;
		reset = 1;
		#0.5 reset = 0;
	end
	always begin
		writeIndex = 2;
		writeValue = 2;
		#0.01;
		$display("readIndexA= %d, readValueA = %d, readIndexB = %d, readValueB = %d", readIndexA, readValueA, readIndexB, readValueB);
		repeat(30) begin
			   	 readIndexA = readIndexA + 1;
				 readIndexB = readIndexB + 1;
				 writeIndex = writeIndex + 1;
				 writeValue =  writeValue + 1;
				 #0.01;
				 $display("readIndexA= %d, readValueA = %d, readIndexB = %d, readValueB = %d", readIndexA, readValueA, readIndexB, readValueB);
		end
		$finish;
	end

endmodule
