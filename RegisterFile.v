`include "timescale.v"

module RegisterFile(readIndexA, readValueA, readIndexB, readValueB, writeIndex, writeValue, reset, clk);
	`include "Utility.v"

	input wire[REGISTER_NUMBER_LOG - 1: 0]          readIndexA;
	output wire[31: 0]                              readValueA;
	input wire[REGISTER_NUMBER_LOG - 1: 0]          readIndexB;
	output wire[31: 0]                              readValueB;
	input wire[REGISTER_NUMBER_LOG - 1: 0]          writeIndex;
	input wire[31: 0]                               writeValue;
	input wire                                      reset;
	input wire                                      clk;

	reg[31: 0]                                      registers[0: REGISTER_NUMBER - 1];

	assign readValueA = registers[readIndexA];
	assign readValueB = registers[readIndexB];

	always @ (posedge reset)
	begin: doReset
		integer i;
		for (i = 0; i < 32; ++i)
			registers[i] = 'b0;
	end
	
	always @ (writeIndex or writeValue)
	begin: writeRegister
		if (writeIndex !== 5'bx && writeIndex !== 'b0) // $0 should not be rewrited
		begin
			registers[writeIndex] = writeValue;
		end
	end
	
endmodule
