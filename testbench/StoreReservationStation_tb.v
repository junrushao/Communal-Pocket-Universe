`include "StoreReservationStation.v"
module StoreReservationStation_tb;
	`include "Utility.v"
	wire[OPCODE_LENGTH - 1: 0] op;
	wire[31: 0] vj,vk;
	wire[31: 0] res;
	wire[31: 0] vi;
	wire[REORDER_BUFFER_SIZE_LOG - 1: 0] pos;
	wire[FUNCTION_UNIT_NUMBER_LOG - 1: 0] qi,qj,qk;
	wire[FUNCTION_UNIT_NUMBER * 32 - 1: 0] commonDataBus;
	reg clk, reset;
	wire busy;
	wire[REORDER_BUFFER_SIZE_LOG - 1: 0] writeBuffer_position;
	wire[31: 0] writeBuffer_value;
	wire[31: 0] writeBuffer_storeValue;
	StoreReservationStation storeRs(op,pos,qi,vi,qj,vj,qk,vk,commonDataBus,busy,writeBuffer_position,writeBuffer_value,writeBuffer_storeValue,reset,clk);
	
	always #0.5 clk = ~clk;
	initial
	begin
		clk = 0;
		reset = 1;
		#0.5 reset = 0;
	end
	wire [661: 0] data [1:0];
    	assign data[0] = { OPCODE_SW, 4'd0, 4'd0, 32'd0, 4'bx, 32'd5, 4'bx, 32'd7, 512'bx, 32'd12};
    	assign data[1] = { OPCODE_SW, 4'd0, 4'd0, 32'd1, 4'b0, 32'bx, 4'bx, 32'd7, 512'd5, 32'd12};
    	assign { op,pos,qi,vi,qj,vj,qk,vk,commonDataBus, res} = data[num];

	integer num = 0;
	
	always @ (posedge clk)
	begin 
		#3.71;
		if (num < 2)
   		begin
			$display("op = %d, pos = %d, qi = %d, vi = %d, qj = %d, vj = %d, qk = %d, vk = %d, commonDataBus = %b, writeBuffer_storeValue = %d, pos = %d, AC = %d",
                   		 op, pos, qi, vi, qj, vj, qk, vk, commonDataBus, writeBuffer_storeValue, writeBuffer_value, (writeBuffer_value === res && vi === writeBuffer_storeValue));
		end
        else
            $finish;
        num = num + 1;
	end

endmodule
