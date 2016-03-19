`include "timescale.v"

module RegisterStatusTable(readIndexA, readValueA, readIndexB, readValueB, writeIndex, writeValue, reset, clk);
	`include "Utility.v"

	input wire[REGISTER_NUMBER_LOG - 1: 0]              readIndexA;
	output wire[REORDER_BUFFER_SIZE_LOG - 1: 0]        readValueA;

	input wire[REGISTER_NUMBER_LOG - 1: 0]              readIndexB;
	output wire[REORDER_BUFFER_SIZE_LOG - 1: 0]        readValueB;

	input wire[REGISTER_NUMBER_LOG - 1: 0]              writeIndex;
	input wire[REORDER_BUFFER_SIZE_LOG - 1: 0]         writeValue;
	input wire                                          reset;
	input wire                                          clk;

	reg[REORDER_BUFFER_SIZE_LOG - 1: 0]                status[31: 0];

	assign readValueA = status[readIndexA];
	assign readValueB = status[readIndexB];

	always @ (posedge reset)
	begin: doReset
		integer i;
		for (i = 0; i < 32; ++i)
			status[i] = 'bx;
	end

	always @ (writeIndex or writeValue)
	begin: resetOrWriteStatus
		if (writeIndex !== 5'bx)
		begin
			status[writeIndex] = writeValue;
		end
	end

endmodule
