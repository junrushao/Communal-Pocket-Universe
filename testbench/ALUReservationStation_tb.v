`include "ALUReservationStation.v"
module ALUReservationStation_tb;
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
	ALUReservationStation alu(op,pos,qi,vi,qj,vj,qk,vk,commonDataBus,busy,writeBuffer_position,writeBuffer_value,reset,clk);
	
	always #0.5 clk = ~clk;
	initial
	begin
		clk = 0;
		reset = 1;
		#0.5 reset = 0;
	end
	wire [661: 0] data [7:0];
    	assign data[0] = { OPCODE_ADD, 4'd0, 4'd0, 32'bx, 4'bx, 32'd5, 4'bx, 32'd7, 512'bx, 32'd12};
    	assign data[1] = { OPCODE_ADDI, 4'd0, 4'd0, 32'bx, 4'bx, 32'd5, 4'bx, 32'd7, 512'bx, 32'd12};
   	assign data[2] = { OPCODE_SUB, 4'd0, 4'd0, 32'bx, 4'bx, 32'd5, 4'bx, 32'd7, 512'bx, -32'd2};
	assign data[3] = { OPCODE_SUBI, 4'd0, 4'd0, 32'bx, 4'bx, 32'd5, 4'bx, 32'd7, 512'bx, -32'd2};
	assign data[4] = { OPCODE_MUL, 4'd0, 4'd0, 32'bx, 4'bx, 32'd5, 4'bx, 32'd7, 512'bx, 32'd35};
	assign data[5] = { OPCODE_BGE, 4'd0, 4'bx,32'd5,4'bx, 32'd7, 4'bx, 32'd1, 512'bx, 32'd0};
	assign data[6] = { OPCODE_SHL, 4'd0, 4'd0,32'bx, 4'bx, 32'd5, 4'bx, 32'd7, 512'bx, 32'd640};
	assign data[7] = { OPCODE_SHR, 4'd0, 4'd0,32'bx, 4'bx, 32'd5, 4'bx, 32'd1, 512'bx, 32'd2};
    	assign { op,pos,qi,vi,qj,vj,qk,vk,commonDataBus,res } = data[num];

	integer num = 0;
	
	always @ (posedge clk)
	begin
		#3.21; 
		if (num < 8)
   		begin
			$display("op = %d, pos = %d, qi = %d, vi = %d, qj = %d, vj = %d, qk = %d, vk = %d, commonDataBus = %d, res = %d, output = %d, AC = %d",
                   		 op, pos, qi, vi, qj, vj, qk, vk, commonDataBus, res, writeBuffer_value, (writeBuffer_value === res));
		end
        else
            $finish;
        num = num + 1;
	end

endmodule
