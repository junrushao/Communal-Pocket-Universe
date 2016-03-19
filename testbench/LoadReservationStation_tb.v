`include "LoadReservationStation.v"
module LoadReservationStation_tb;
	`include "Utility.v"
	wire[OPCODE_LENGTH - 1: 0] op;
	wire[31: 0] vj,vk;
	wire[31: 0] storePos,storeValue;
	wire[31: 0] vi;
	wire[REORDER_BUFFER_SIZE_LOG - 1: 0] pos;
	wire[FUNCTION_UNIT_NUMBER_LOG - 1: 0] qi,qj,qk;
	wire[FUNCTION_UNIT_NUMBER * 32 - 1: 0] commonDataBus;
	reg clk, reset;
	wire busy;
	wire[REORDER_BUFFER_SIZE_LOG - 1: 0] writeBuffer_position;
	wire[31: 0] writeBuffer_value;
	wire[31: 0] dCache_readPtr;
	wire[31: 0] dCache_readValue;
	wire dCache_readSuccess;
	wire[NUMBER_OF_BLOCKS_IN_CACHE - 1: 0] dCache_busy;
	LoadReservationStation loadRs(op,pos,qi,vi,qj,vj,qk,vk,commonDataBus,busy,writeBuffer_position,writeBuffer_value,dCache_readPtr, dCache_readValue, dCache_readSuccess, dCache_busy,reset,clk);
	
	always #0.5 clk = ~clk;
	initial
	begin
		clk = 0;
		reset = 1;
		#0.5 reset = 0;
	end
	wire [727: 0] data [1:0];
    	assign data[0] = { OPCODE_LW, 4'd0, 4'bx, 32'bx, 4'b0, 32'bx, 4'bx, 32'd7, 512'bx, 32'd0, 1'b0, 4'b0000, 32'bx, 32'bx};
    	assign data[1] = { OPCODE_LW, 4'd0, 4'bx, 32'bx, 4'b0, 32'bx, 4'bx, 32'd7, 512'd5, 32'd1, 1'b0, 4'b0000, 32'd12, 32'bx};
    	assign { op,pos,qi,vi,qj,vj,qk,vk,commonDataBus, dCache_readValue, dCache_readSuccess, dCache_busy, storePos,storeValue} = data[num];

	integer num = 0;
	
	always @ (posedge clk)
	begin 
		#3.71;
		if (num < 2)
   		begin
			$display("time = %g, op = %d, pos = %d, qj = %d, vj = %d, qk = %d, vk = %d, commonDataBus = %b, writeBuffer_value = %d, dCache_readPtr = %d, AC = %d",
                   		 $realtime, op, pos, qj, vj, qk, vk, commonDataBus, writeBuffer_value, dCache_readPtr, (writeBuffer_value === storeValue && dCache_readPtr === storePos));
		end
        else
            $finish;
        num = num + 1;
	end

endmodule
