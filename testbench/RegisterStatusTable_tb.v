`include "RegisterStatusTable.v"
module RegisterStatusTable_tb;
	`include "Utility.v"
	reg[REGISTER_NUMBER_LOG - 1: 0]          readIndexA = 5'b0;
	wire[REORDER_BUFFER_SIZE_LOG - 1: 0]     readValueA;
	reg[REGISTER_NUMBER_LOG - 1: 0]          readIndexB = 5'b1;
	wire[REORDER_BUFFER_SIZE_LOG - 1: 0]     readValueB;
	reg[REGISTER_NUMBER_LOG - 1: 0]          writeIndex;
	reg[REORDER_BUFFER_SIZE_LOG - 1: 0]      writeValue;
	reg clk, reset;
	RegisterStatusTable regStatus(readIndexA, readValueA, readIndexB, readValueB, writeIndex, writeValue, reset, clk);
	
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
		repeat(10) begin
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
