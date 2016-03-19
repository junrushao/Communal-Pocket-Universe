`include "timescale.v"

module ALUReservationStation(issueBus_opcode, issueBus_position, issueBus_qi, issueBus_vi, issueBus_qj, issueBus_vj, issueBus_qk, issueBus_vk, commonDataBus, busy, writeBuffer_position, writeBuffer_value, reset, clk);
	`include "Utility.v"

	input wire[OPCODE_LENGTH - 1: 0]                    issueBus_opcode;
	input wire[REORDER_BUFFER_SIZE_LOG - 1: 0]          issueBus_position;
	input wire[FUNCTION_UNIT_NUMBER_LOG - 1: 0]         issueBus_qi;
	input wire[31: 0]                                   issueBus_vi;
	input wire[FUNCTION_UNIT_NUMBER_LOG - 1: 0]         issueBus_qj;
	input wire[31: 0]                                   issueBus_vj;
	input wire[FUNCTION_UNIT_NUMBER_LOG - 1: 0]         issueBus_qk;
	input wire[31: 0]                                   issueBus_vk;

	input wire[FUNCTION_UNIT_NUMBER * 32 - 1: 0]        commonDataBus;
	output reg                                          busy;
	output reg[REORDER_BUFFER_SIZE_LOG - 1: 0]          writeBuffer_position;
	output reg[31: 0]                                   writeBuffer_value;
	input wire                                          reset;
	input wire                                          clk;

	reg[5: 0]                                           opcode;
	reg[FUNCTION_UNIT_NUMBER_LOG - 1: 0]                qj;
	reg[FUNCTION_UNIT_NUMBER_LOG - 1: 0]                qk;
	reg[31: 0]                                          vj;
	reg[31: 0]                                          vk;
	reg[REORDER_BUFFER_SIZE_LOG - 1: 0]                 position;

	always @ (posedge reset)
	begin: doReset
		busy <= 1'b0;
		writeBuffer_position <= 'bx;
		writeBuffer_value <= 'bx;
		position <= 'bx;
		opcode <= 'bx;
		qj <= 'bx;
		vj <= 'bx;
		qk <= 'bx;
		vk <= 'bx;
	end

	always @ (posedge clk)
	begin: fetchIssue
		#0.1
		if (!busy)
		begin
			if (issueBus_position !== 4'bx)
			begin
				busy = 1'b1;
				position = issueBus_position;
				opcode = issueBus_opcode;
				if (opcode === OPCODE_BGE)
				begin
					qj = issueBus_qi;
					vj = issueBus_vi;
					qk = issueBus_qj;
					vk = issueBus_vj;
				end
				else
				begin
					qj = issueBus_qj;
					vj = issueBus_vj;
					qk = issueBus_qk;
					vk = issueBus_vk;
				end
			end
		end
	end

	always @ (posedge clk)
	begin: doCalculation
		reg[31: 0] result;
		if (busy)
		begin
			#0.2;
			checkCommonDataBus(qj, vj, commonDataBus);
			checkCommonDataBus(qk, vk, commonDataBus);
			if (vj !== 'bx && vk !== 'bx)
			begin
				calculate(opcode, vj, vk, result);
				#1;
				writeBuffer_value = result;
				writeBuffer_position = position;
				busy = 1'b0;
			end
		end
	end	

	always @ (posedge clk)
	begin: shutdownSignal
		#0.8;
		writeBuffer_value <= 'bx;
		writeBuffer_position <= 'bx;
	end

	task calculate;
		input[5: 0] opcode;
		input[31: 0] v1;
		input[31: 0] v2;
		output[31: 0] result;
		integer x,y;
		begin
			case (opcode)
			OPCODE_ADD:
				#1 result = v1 + v2;
			OPCODE_ADDI:
				#1 result = v1 + v2;
			OPCODE_SUB:
				#1 result = v1 - v2;
			OPCODE_SUBI:
				#1 result = v1 - v2;
			OPCODE_MUL:
				#1 result = v1 * v2;
			OPCODE_BGE:
				#1 
				begin
					x = v1;
					if (x>= 1<<31) x -= 1<<32;
					y = v2;
					if (y>= 1<<31) y -= 1<<32;
					result = x >= y;
				end
			OPCODE_LW:
				#1 result = v1 + v2;
			OPCODE_SW:
				#1 result = v1 + v2;
			OPCODE_SHL:
				#1 result = v1 << v2;
			OPCODE_SHR:
				#1 result = v1 >> v2;
			default:
				$display("Something wrong here.");
			endcase
		end
	endtask

	task checkCommonDataBus;
		integer i;
		input[FUNCTION_UNIT_NUMBER_LOG - 1: 0] q;
		inout[31: 0] v;
		input[FUNCTION_UNIT_NUMBER * 32 - 1: 0] commonDataBus;
		begin
			if (v === 'bx)
			begin
				i = q;
				v = commonDataBus >> (i << 5);
			end
		end
	endtask

endmodule

