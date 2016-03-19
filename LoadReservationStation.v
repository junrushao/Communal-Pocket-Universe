`include "timescale.v"

module LoadReservationStation(
	issueBus_opcode, issueBus_position, issueBus_qi, issueBus_vi, issueBus_qj, issueBus_vj, issueBus_qk, issueBus_vk, 
	commonDataBus, busy, 
	writeBuffer_position, writeBuffer_value, 
	dCache_readPtr, dCache_readValue, dCache_readSuccess, dCache_busy,
	reset, clk);
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

	output reg[31: 0]                                   dCache_readPtr;
	input wire[31: 0]                                   dCache_readValue;
	input wire                                          dCache_readSuccess;
	input wire[NUMBER_OF_BLOCKS_IN_CACHE - 1: 0]        dCache_busy;
	
	input wire                                          reset;
	input wire                                          clk;

	reg[5: 0]                                           opcode;
	reg[FUNCTION_UNIT_NUMBER_LOG - 1: 0]                qj;
	reg[FUNCTION_UNIT_NUMBER_LOG - 1: 0]                qk;
	reg[31: 0]                                          vj;
	reg[31: 0]                                          vk;
	reg[REORDER_BUFFER_SIZE_LOG - 1: 0]                 position;
	reg                                                 loading;

	always @ (posedge reset)
	begin: doReset
		busy <= 1'b0;
		writeBuffer_position <= 'bx;
		writeBuffer_value <= 'bx;
		dCache_readPtr <= 'bx;
		position <= 'bx;
		opcode <= 'bx;
		qj <= 'bx;
		vj <= 'bx;
		qk <= 'bx;
		vk <= 'bx;
		loading <= 'b0;
	end

	always @ (posedge clk)
	begin: fetchIssue
		#0.1
		if (!busy)
		begin
			if (issueBus_position !== 4'bx)
			begin
				busy <= 1'b1;
				position <= issueBus_position;
				opcode <= issueBus_opcode;
				qj <= issueBus_qj;
				vj <= issueBus_vj;
				qk <= issueBus_qk;
				vk <= issueBus_vk;
				loading <= 'b0;
			end
		end
	end

	always @ (posedge clk)
	begin: doCalculation
		reg[31: 0] result;
		if (busy && loading === 1'b0)
		begin
			#0.2;
			checkCommonDataBus(qj, vj, commonDataBus);
			checkCommonDataBus(qk, vk, commonDataBus);
			if (vj !== 'bx && vk !== 'bx)
			begin
				calculate(opcode, vj, vk, result);
				#1;
				loading = 1'b1;
				while (dCache_busy[(result >> BLOCK_SIZE_LOG) & ((1 << NUMBER_OF_BLOCKS_IN_CACHE_LOG) - 1)] === 1'b1) // result[5: 4]
					#1;
				dCache_readPtr = result;
			end
		end
	end

	always @ (posedge dCache_readSuccess)
	begin: fetchReturn
		writeBuffer_value = dCache_readValue;
		dCache_readPtr = 'bx;
		writeBuffer_position = position;
		loading = 1'b0;
		busy = 1'b0;
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
