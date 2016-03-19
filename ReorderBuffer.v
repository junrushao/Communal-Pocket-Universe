`include "timescale.v"

`include "DataCache.v"
`include "InstructionCache.v"
`include "RegisterFile.v"
`include "RegisterStatusTable.v"
`include "ALUReservationStation.v"
`include "LoadReservationStation.v"
`include "StoreReservationStation.v"

module ReorderBuffer(reset, clk);
	`include "Utility.v"

	input wire                                  reset;
	input wire                                  clk;

	// PC
	reg[31: 0]                                  pc;

	// branchPredictor
	reg[1: 0]                                   branchPredictor;

	// CDB
	reg[FUNCTION_UNIT_NUMBER * 32 - 1: 0]       commonDataBus;

	// used for decoding an instruction
	reg[31: 0]                                  instruction;
	wire[OPCODE_LENGTH: 0]                      instruction_opcode = instruction[31: 26];
	wire[REGISTER_NUMBER_LOG - 1: 0]            instruction_rd = instruction[25: 21];
	wire[REGISTER_NUMBER_LOG - 1: 0]            instruction_rs = instruction[20: 16];
	wire[REGISTER_NUMBER_LOG - 1: 0]            instruction_rt = instruction[15: 11];
	wire[15: 0]                                 _instruction_immediate = instruction[15: 0];
	reg[31: 0]                                  instruction_immediate;

	// issueBus
	reg[OPCODE_LENGTH - 1: 0]                   issueBus_opcode[0: FUNCTION_UNIT_NUMBER - 1];
	reg[REORDER_BUFFER_SIZE_LOG - 1: 0]         issueBus_position[0: FUNCTION_UNIT_NUMBER - 1];
	reg[FUNCTION_UNIT_NUMBER_LOG - 1: 0]        issueBus_qi[0: FUNCTION_UNIT_NUMBER - 1];
	reg[31: 0]                                  issueBus_vi[0: FUNCTION_UNIT_NUMBER - 1];
	reg[FUNCTION_UNIT_NUMBER_LOG - 1: 0]        issueBus_qj[0: FUNCTION_UNIT_NUMBER - 1];
	reg[31: 0]                                  issueBus_vj[0: FUNCTION_UNIT_NUMBER - 1];
	reg[FUNCTION_UNIT_NUMBER_LOG - 1: 0]        issueBus_qk[0: FUNCTION_UNIT_NUMBER - 1];
	reg[31: 0]                                  issueBus_vk[0: FUNCTION_UNIT_NUMBER - 1];

	// reorderBuffer
	reg[REORDER_BUFFER_SIZE_LOG - 1: 0]         reorderBuffer_head;
	reg[REORDER_BUFFER_SIZE_LOG - 1: 0]         reorderBuffer_tail;
	reg[REORDER_BUFFER_SIZE_LOG - 1: 0]         reorderBuffer_size;
	reg[OPCODE_LENGTH - 1: 0]                   reorderBuffer_opcode[0: REORDER_BUFFER_SIZE - 1];
	reg[FUNCTION_UNIT_NUMBER_LOG - 1: 0]        reorderBuffer_fu[0: REORDER_BUFFER_SIZE - 1];
	reg[REGISTER_NUMBER_LOG - 1: 0]             reorderBuffer_rd[0: REORDER_BUFFER_SIZE - 1];
	reg[31: 0]                                  reorderBuffer_rs[0: REORDER_BUFFER_SIZE - 1];
	reg[31: 0]                                  reorderBuffer_extraInfo[0: REORDER_BUFFER_SIZE - 1];
	reg                                         reorderBuffer_hasHalt;

	// data cache
	reg                                         writingDCache;
	wire[31: 0]                                 dCache_readPtrA;
	wire[31: 0]                                 dCache_readValueA;
	wire                                        dCache_readSuccessA;
	wire[31: 0]                                 dCache_readPtrB;
	wire[31: 0]                                 dCache_readValueB;
	wire                                        dCache_readSuccessB;
	wire[31: 0]                                 dCache_readPtrC;
	wire[31: 0]                                 dCache_readValueC;
	wire                                        dCache_readSuccessC;
	reg                                         dCache_writeEnable;
	reg[31: 0]                                  dCache_writePtr;
	reg[31: 0]                                  dCache_writeValue;
	wire                                        dCache_writeSuccess;
	reg                                         dCache_allWriteBack;
	wire                                        dCache_allWriteBackSuccess;
	wire[NUMBER_OF_BLOCKS_IN_CACHE - 1: 0]      dCache_busy;
	DataCache                                   dCache(
	                                                .readPtrA(dCache_readPtrA),
	                                                .readValueA(dCache_readValueA),
	                                                .readSuccessA(dCache_readSuccessA),
	                                                .readPtrB(dCache_readPtrB),
	                                                .readValueB(dCache_readValueB),
	                                                .readSuccessB(dCache_readSuccessB),
	                                                .readPtrC(dCache_readPtrC),
	                                                .readValueC(dCache_readValueC),
	                                                .readSuccessC(dCache_readSuccessC),
	                                                .writeEnable(dCache_writeEnable),
	                                                .writePtr(dCache_writePtr),
	                                                .writeValue(dCache_writeValue),
	                                                .writeSuccess(dCache_writeSuccess),
													.allWriteBack(dCache_allWriteBack),
													.allWriteBackSuccess(dCache_allWriteBackSuccess),
	                                                .busy(dCache_busy),
	                                                .reset(reset),
	                                                .clk(clk)
	                                            );

	// instruction cache
	reg                                         readingICache;
	reg[31: 0]                                  iCache_readPtr;
	wire[31: 0]                                 iCache_readValue;
	wire                                        iCache_readSuccess;
	InstructionCache                            iCache(
	                                                .readPtr(iCache_readPtr),
	                                                .readValue(iCache_readValue),
	                                                .readSuccess(iCache_readSuccess),
	                                                .reset(reset),
	                                                .clk(clk)
                                                );

	// register status table
	reg[REGISTER_NUMBER_LOG - 1: 0]             regStatus_readIndexA;
	wire[FUNCTION_UNIT_NUMBER_LOG - 1: 0]       regStatus_readValueA;
	reg[REGISTER_NUMBER_LOG - 1: 0]             regStatus_readIndexB;
	wire[FUNCTION_UNIT_NUMBER_LOG - 1: 0]       regStatus_readValueB;
	reg[REGISTER_NUMBER_LOG - 1: 0]             regStatus_writeIndex;
	reg[FUNCTION_UNIT_NUMBER_LOG - 1: 0]        regStatus_writeValue;
	reg                                         regStatus_reset;
	RegisterStatusTable                         regStatus(
                                                    .readIndexA(regStatus_readIndexA),
                                                    .readValueA(regStatus_readValueA),
                                                    .readIndexB(regStatus_readIndexB),
                                                    .readValueB(regStatus_readValueB),
                                                    .writeIndex(regStatus_writeIndex),
                                                    .writeValue(regStatus_writeValue),
                                                    .reset(regStatus_reset),
                                                    .clk(clk)
                                                );

	// register file
	reg[REGISTER_NUMBER_LOG - 1: 0]             regFile_readIndexA;
	wire[31: 0]                                 regFile_readValueA;
	reg[REGISTER_NUMBER_LOG - 1: 0]             regFile_readIndexB;
	wire[31: 0]                                 regFile_readValueB;
	reg[REGISTER_NUMBER_LOG - 1: 0]             regFile_writeIndex;
	reg[31: 0]                                  regFile_writeValue;
	RegisterFile                                regFile(
	                                                .readIndexA(regFile_readIndexA),
	                                                .readValueA(regFile_readValueA),
	                                                .readIndexB(regFile_readIndexB),
	                                                .readValueB(regFile_readValueB),
	                                                .writeIndex(regFile_writeIndex),
	                                                .writeValue(regFile_writeValue),
	                                                .reset(reset),
	                                                .clk(clk)
	                                            );

	wire[REORDER_BUFFER_SIZE_LOG - 1: 0]        writeBuffer_position[0: FUNCTION_UNIT_NUMBER - 1];
	wire[31: 0]                                 writeBuffer_value[0: FUNCTION_UNIT_NUMBER - 1];
	wire[31: 0]                                 writeBuffer_storeValue[0: FUNCTION_UNIT_NUMBER - 1];
	reg                                         resetBus[0: FUNCTION_UNIT_NUMBER - 1];
	wire                                        busy[0: FUNCTION_UNIT_NUMBER - 1];

	`define ALUWire(id) \
		.issueBus_opcode(issueBus_opcode[``id]), \
		.issueBus_position(issueBus_position[``id]), \
		.issueBus_qi(issueBus_qi[``id]), \
		.issueBus_vi(issueBus_vi[``id]), \
		.issueBus_qj(issueBus_qj[``id]), \
		.issueBus_vj(issueBus_vj[``id]), \
		.issueBus_qk(issueBus_qk[``id]), \
		.issueBus_vk(issueBus_vk[``id]), \
		.commonDataBus(commonDataBus), \
		.busy(busy[``id]), \
		.writeBuffer_position(writeBuffer_position[``id]), \
		.writeBuffer_value(writeBuffer_value[``id]), \
		.reset(resetBus[``id]), \
		.clk(clk)

	`define LoadWire(id, readPtr, readValue, readSuccess) \
		.issueBus_opcode(issueBus_opcode[``id]), \
		.issueBus_position(issueBus_position[``id]), \
		.issueBus_qi(issueBus_qi[``id]), \
		.issueBus_vi(issueBus_vi[``id]), \
		.issueBus_qj(issueBus_qj[``id]), \
		.issueBus_vj(issueBus_vj[``id]), \
		.issueBus_qk(issueBus_qk[``id]), \
		.issueBus_vk(issueBus_vk[``id]), \
		.commonDataBus(commonDataBus), \
		.busy(busy[``id]), \
		.writeBuffer_position(writeBuffer_position[``id]), \
		.writeBuffer_value(writeBuffer_value[``id]), \
		.dCache_readPtr(``readPtr), \
		.dCache_readValue(``readValue), \
		.dCache_readSuccess(``readSuccess), \
		.dCache_busy(dCache_busy), \
		.reset(resetBus[``id]), \
		.clk(clk)

	`define StoreWire(id) \
		.issueBus_opcode(issueBus_opcode[``id]), \
		.issueBus_position(issueBus_position[``id]), \
		.issueBus_qi(issueBus_qi[``id]), \
		.issueBus_vi(issueBus_vi[``id]), \
		.issueBus_qj(issueBus_qj[``id]), \
		.issueBus_vj(issueBus_vj[``id]), \
		.issueBus_qk(issueBus_qk[``id]), \
		.issueBus_vk(issueBus_vk[``id]), \
		.commonDataBus(commonDataBus), \
		.busy(busy[``id]), \
		.writeBuffer_position(writeBuffer_position[``id]), \
		.writeBuffer_value(writeBuffer_value[``id]), \
		.writeBuffer_storeValue(writeBuffer_storeValue[``id]), \
		.reset(resetBus[``id]), \
		.clk(clk)

	ALUReservationStation                       add1(`ALUWire(ADD_1_ID));
	ALUReservationStation                       add2(`ALUWire(ADD_2_ID));
	ALUReservationStation                       add3(`ALUWire(ADD_3_ID));
	ALUReservationStation                       mul1(`ALUWire(MUL_1_ID));
	ALUReservationStation                       mul2(`ALUWire(MUL_2_ID));
	ALUReservationStation                       mul3(`ALUWire(MUL_3_ID));
	ALUReservationStation                       bge1(`ALUWire(BGE_1_ID));
	ALUReservationStation                       bge2(`ALUWire(BGE_2_ID));
	LoadReservationStation                      lw1(`LoadWire(LW_1_ID, dCache_readPtrA, dCache_readValueA, dCache_readSuccessA));
	LoadReservationStation                      lw2(`LoadWire(LW_2_ID, dCache_readPtrB, dCache_readValueB, dCache_readSuccessB));
	LoadReservationStation                      lw3(`LoadWire(LW_3_ID, dCache_readPtrC, dCache_readValueC, dCache_readSuccessC));
	StoreReservationStation                     sw1(`StoreWire(SW_1_ID));
	StoreReservationStation                     sw2(`StoreWire(SW_2_ID));
	StoreReservationStation                     sw3(`StoreWire(SW_3_ID));
	ALUReservationStation                       shl(`ALUWire(SHL_1_ID));
	ALUReservationStation                       shr(`ALUWire(SHR_1_ID));

	`undef ALUWire
	`undef LoadWire
	`undef StoreWire

	always @ (posedge reset)
	begin: doReset
		integer i;
		pc = 'b0;
		branchPredictor = 2'b11;
		commonDataBus = 'bx;
		instruction = 'bx;
		for (i = 0; i < FUNCTION_UNIT_NUMBER; ++i)
		begin
			issueBus_opcode[i] = 'bx;
			issueBus_position[i] = 'bx;
			issueBus_qi[i] = 'bx;
			issueBus_vi[i] = 'bx;
			issueBus_qj[i] = 'bx;
			issueBus_vj[i] = 'bx;
			issueBus_qk[i] = 'bx;
			issueBus_vk[i] = 'bx;
		end

		reorderBuffer_head = 'b0;
		reorderBuffer_tail = 'b0;
		reorderBuffer_size = 'b0;
		reorderBuffer_hasHalt = 'b0;
		for (i = 0; i < REORDER_BUFFER_SIZE; ++i)
		begin
			reorderBuffer_opcode[i] = 'bx;
			reorderBuffer_fu[i] = 'bx;
			reorderBuffer_rd[i] = 'bx;
			reorderBuffer_rs[i] = 'bx;
			reorderBuffer_extraInfo[i] = 'bx;
		end
		dCache_writeEnable = 'b0;
		dCache_writePtr = 'bx;
		dCache_writeValue = 'bx;
		dCache_allWriteBack = 'b0;
		iCache_readPtr = 'bx;
		regStatus_readIndexA = 'bx;
		regStatus_readIndexB = 'bx;
		regStatus_writeIndex = 'bx;
		regStatus_writeValue = 'bx;
		regFile_readIndexA = 'bx;
		regFile_readIndexB = 'bx;
		regFile_writeIndex = 'bx;
		regFile_writeValue = 'bx;

		readingICache = 1'b0;
		writingDCache = 1'b0;

		for (i = 0; i < FUNCTION_UNIT_NUMBER; ++i)
		begin
			resetBus[i] = 'b1;
		end
		regStatus_reset = 1;

		#0.01 // wait for regFile & reservation stations to reset
		for (i = 0; i < FUNCTION_UNIT_NUMBER; ++i)
		begin
			resetBus[i] = 'b0;
		end
		regStatus_reset = 0;
	end

	always @ (posedge clk)
	begin: writeBuffer
		integer i, j;
		#0.5;
		commonDataBus = 'b0;
		for (i = 0; i < FUNCTION_UNIT_NUMBER; ++i)
		begin
			if (writeBuffer_position[i] !== 4'bx)
			begin
				reorderBuffer_rs[ writeBuffer_position[i] ] = writeBuffer_value[i];
				if (i === SW_1_ID || i === SW_2_ID || i === SW_3_ID)
					reorderBuffer_extraInfo[ writeBuffer_position[i] ] = writeBuffer_storeValue[i];
				commonDataBus = commonDataBus | (writeBuffer_value[i] << (i << 5)); // assign [i * 32 + 31, i * 32]
			end
			else
			begin
				for (j = (i << 5); j < ((i + 1) << 5); ++j)
					commonDataBus[j] = 1'bx;
			end
		end
	end

	always @ (posedge clk)
	begin: commit
		integer i;
		#0.6;
		
		while (reorderBuffer_size > 0 && reorderBuffer_rs[reorderBuffer_head] !== 'bx)
		begin
			if (reorderBuffer_opcode[reorderBuffer_head] === OPCODE_HALT)
			begin
				while (writingDCache === 1'b1)#1;
				$display("halt, time = %g\n",$realtime);
				dCache_allWriteBack = 1'b1;
				while (dCache_allWriteBackSuccess === 1'b0) #1;
				$finish;
			end
			//TODO:DELETE
			if (reorderBuffer_opcode[reorderBuffer_head] === OPCODE_BGE)
			$display("commit: branch res = %d, time = %g\n", reorderBuffer_rs[reorderBuffer_head], $realtime);
			else if (reorderBuffer_opcode[reorderBuffer_head] !== OPCODE_SW)
			$display("commit: opcode = %b, reg = %d, res = %d, time = %g\n", reorderBuffer_opcode[reorderBuffer_head], reorderBuffer_rd[reorderBuffer_head], reorderBuffer_rs[reorderBuffer_head], $realtime);
			else $display("commit: opcode = %b, mem = %d, res = %d, time = %g\n", reorderBuffer_opcode[reorderBuffer_head], reorderBuffer_rs[reorderBuffer_head], reorderBuffer_extraInfo[reorderBuffer_head], $realtime);
			if (reorderBuffer_opcode[reorderBuffer_head] === OPCODE_BGE && reorderBuffer_rs[reorderBuffer_head] !== ((branchPredictor >> 1) & 1))
			begin
				pc = reorderBuffer_extraInfo[reorderBuffer_head];
				// TODO:delete
				$display("branch predicate failure: jump to pc : %d\n", pc);

				// clear reservation station
				for (i = 0; i < FUNCTION_UNIT_NUMBER; ++i)
					resetBus[i] = 1'b1;
				regStatus_reset = 1'b1;
				#0.01
				for (i = 0; i < FUNCTION_UNIT_NUMBER; ++i)
					resetBus[i] = 1'b0;
				regStatus_reset = 1'b0;

				// clear reorder buffer
				reorderBuffer_head = 'b0;
				reorderBuffer_tail = 'b0;
				reorderBuffer_size = 'b0;
				reorderBuffer_hasHalt = 'b0;

				iCache_readPtr = 'bx;
				readingICache = 'b0;
				
				if (branchPredictor === 2'b00)
				begin
					branchPredictor = 2'b01;
				end
				else if (branchPredictor === 2'b01)
				begin
					branchPredictor = 2'b11;
				end
				else if (branchPredictor === 2'b10)
				begin
					branchPredictor = 2'b00;
				end
				else if (branchPredictor === 2'b11)
				begin
					branchPredictor = 2'b10;
				end
				
//				reorderBuffer_head = incPointer(reorderBuffer_head);
			end
			else if (reorderBuffer_opcode[reorderBuffer_head] === OPCODE_BGE)
			begin
				if (branchPredictor === 2'b00)
				begin
					branchPredictor = 2'b00;
				end
				else if (branchPredictor === 2'b01)
				begin
					branchPredictor = 2'b00;
				end
				else if (branchPredictor === 2'b10)
				begin
					branchPredictor = 2'b11;
				end
				else if (branchPredictor === 2'b11)
				begin
					branchPredictor = 2'b11;
				end

				reorderBuffer_head = incPointer(reorderBuffer_head);
				--reorderBuffer_size;
			end
			else if (reorderBuffer_opcode[reorderBuffer_head] === OPCODE_SW && writingDCache === 1'b0)
			begin
				while (dCache_busy[(reorderBuffer_rs[reorderBuffer_head] >> BLOCK_SIZE_LOG) & ((1 << NUMBER_OF_BLOCKS_IN_CACHE_LOG) - 1)] 
					=== 1'b1)
					#1;
				writingDCache = 1'b1;
				dCache_writePtr = reorderBuffer_rs[reorderBuffer_head];
				dCache_writeValue = reorderBuffer_extraInfo[reorderBuffer_head];
				dCache_writeEnable = 1'b1;
				reorderBuffer_head = incPointer(reorderBuffer_head);
				--reorderBuffer_size;
			end
			else // normal ALU operation & load
			begin
				regFile_writeIndex = reorderBuffer_rd[reorderBuffer_head];
				regFile_writeValue = reorderBuffer_rs[reorderBuffer_head];
				
				regStatus_readIndexA = reorderBuffer_rd[reorderBuffer_head];
				#0.01;
				if (regStatus_readValueA === reorderBuffer_head)
				begin
					regStatus_writeIndex = reorderBuffer_rd[reorderBuffer_head];
					regStatus_writeValue = 'bx;
				end
				reorderBuffer_head = incPointer(reorderBuffer_head);
				--reorderBuffer_size;
			end
		end
		regFile_writeIndex = 'bx;
		regFile_writeValue = 'bx;
	end

	always @ (posedge dCache_writeSuccess)
	begin: writeCacheSuccess
		writingDCache <= 1'b0;
		dCache_writeEnable <= 1'b0;
		dCache_writePtr <= 'bx;
		dCache_writeValue <= 'bx;
	end

	`define parseR(station) \
		parseRTypeInstruction(instruction_opcode, instruction_rs, instruction_rt, instruction_rd, \
			reorderBuffer_head, reorderBuffer_tail, \
			issueBus_opcode[``station], issueBus_position[``station], \
			issueBus_qi[``station], issueBus_vi[``station], \
			issueBus_qj[``station], issueBus_vj[``station], \
			issueBus_qk[``station], issueBus_vk[``station] \
		);

	`define parseI(station) \
		parseITypeInstruction(instruction_opcode, instruction_rs, instruction_rd, instruction_immediate, reorderBuffer_head, reorderBuffer_tail, \
			issueBus_opcode[``station], issueBus_position[``station], \
			issueBus_qi[``station], issueBus_vi[``station], \
			issueBus_qj[``station], issueBus_vj[``station], \
			issueBus_qk[``station], issueBus_vk[``station] \
		);

	`define parseR3(k1, k2, k3) \
		if (!busy[``k1]) \
		begin \
			`parseR(``k1); \
			rb_fu = ``k1; \
		end \
		else if (!busy[``k2]) \
		begin \
			`parseR(``k2); \
			rb_fu = ``k2; \
		end \
		else if (!busy[``k3]) \
		begin \
			`parseR(``k3); \
			rb_fu = ``k3; \
		end

	`define parseI3(k1, k2, k3) \
		if (!busy[``k1]) \
		begin \
			`parseI(``k1); \
			rb_fu = ``k1; \
		end \
		else if (!busy[``k2]) \
		begin \
			`parseI(``k2); \
			rb_fu = ``k2; \
		end \
		else if (!busy[``k3]) \
		begin \
			`parseI(``k3); \
			rb_fu = ``k3; \
		end

	always @ (posedge iCache_readSuccess)
	begin: issue
		reg[31: 0]                                  sPc;
		reg[31: 0]                                  fPc;
		reg[FUNCTION_UNIT_NUMBER_LOG - 1: 0]        rb_fu;
		reg[31: 0]                                  rb_extraInfo;

		rb_fu = 'bx;
		rb_extraInfo = 'bx;
		sPc = pc + 1;

		instruction = iCache_readValue;
		iCache_readPtr = 'bx;
		#0.01;
		$display("if pc = %d, instruction = %b, opcode = %b, time = %g\n", pc, instruction, instruction_opcode,  $realtime);
		instruction_immediate = _instruction_immediate;
		if (instruction_immediate >= 32768)
			instruction_immediate = instruction_immediate - 65536;
		if (instruction_opcode === OPCODE_HALT)
		begin
			reorderBuffer_opcode[reorderBuffer_tail] = instruction_opcode;
			reorderBuffer_rs[reorderBuffer_tail] = 'b0;
			reorderBuffer_tail = incPointer(reorderBuffer_tail);
			++reorderBuffer_size;
			reorderBuffer_hasHalt = 1'b1;
			$display("issue halt, time = %g\n",$realtime);
		end
		else if (instruction_opcode === OPCODE_ADD || instruction_opcode === OPCODE_SUB)
		begin
			`parseR3(ADD_1_ID, ADD_2_ID, ADD_3_ID);
		end
		else if (instruction_opcode === OPCODE_ADDI || instruction_opcode === OPCODE_SUBI)
		begin
			`parseI3(ADD_1_ID, ADD_2_ID, ADD_3_ID);
		end
		else if (instruction_opcode === OPCODE_MUL)
		begin
			`parseR3(MUL_1_ID, MUL_2_ID, MUL_3_ID);
		end
		else if (instruction_opcode === OPCODE_LW)
		begin
//			if ({busy[SW_1_ID], busy[SW_2_ID], busy[SW_3_ID],busy[LW_1_ID], busy[LW_2_ID], busy[LW_3_ID]} === 6'b000000)
			if ({busy[SW_1_ID], busy[SW_2_ID], busy[SW_3_ID]} === 3'b000)
			begin
				`parseI3(LW_1_ID, LW_2_ID, LW_3_ID);
			end
		end
		else if (instruction_opcode === OPCODE_SW)
		begin
//			if ({busy[SW_1_ID], busy[SW_2_ID], busy[SW_3_ID],busy[LW_1_ID], busy[LW_2_ID], busy[LW_3_ID]} === 6'b000000)
			if ({busy[LW_1_ID], busy[LW_2_ID], busy[LW_3_ID]} === 3'b000)
			begin
				`parseI3(SW_1_ID, SW_2_ID, SW_3_ID);
			end
		end
		else if (instruction_opcode === OPCODE_BGE)
		begin
			if (branchPredictor === 2'b00 || branchPredictor === 2'b01)
			begin // not taken
				sPc = pc + 1;
				fPc = pc + instruction_immediate;
			end
			else
			begin // taken
				sPc = pc + instruction_immediate;
				fPc = pc + 1;
			end
			if (!busy[BGE_1_ID])
			begin
				`parseI(BGE_1_ID);
				rb_fu = BGE_1_ID;
				rb_extraInfo = fPc;
			end
			else if (!busy[BGE_2_ID])
			begin
				`parseI(BGE_2_ID);
				rb_fu = BGE_2_ID;
				rb_extraInfo = fPc;
			end
		end
		else if (instruction_opcode === OPCODE_SHL)
		begin
			if (!busy[SHL_1_ID])
			begin
				`parseR(SHL_1_ID);
				rb_fu = SHL_1_ID;
			end
		end
		else if (instruction_opcode === OPCODE_SHR)
		begin
			if (!busy[SHR_1_ID])
			begin
				`parseR(SHR_1_ID);
				rb_fu = SHR_1_ID;
			end
		end
		else
		begin
			$display("pc = %d, issue opcode error %b\n", pc, instruction_opcode);
			$finish;
		end
		if (rb_fu !== 4'bx)
		begin
			//TODO:DELETE
			$display("issue pc = %d, instruction = %b, opcode = %b, time = %g\n", pc, instruction, instruction_opcode, $realtime);
			if (instruction_opcode !== OPCODE_BGE && instruction_opcode !== OPCODE_SW)
			begin
				regStatus_writeIndex = instruction_rd;
				regStatus_writeValue = reorderBuffer_tail;
				#0.01;
				regStatus_writeIndex = 'bx;
				regStatus_writeValue = 'bx;
			end

			reorderBuffer_opcode[reorderBuffer_tail] = instruction_opcode;
			reorderBuffer_fu[reorderBuffer_tail] = rb_fu;
			reorderBuffer_rd[reorderBuffer_tail] = instruction_rd;
			reorderBuffer_rs[reorderBuffer_tail] = 'bx;
			reorderBuffer_extraInfo[reorderBuffer_tail] = rb_extraInfo;
			
			reorderBuffer_tail = incPointer(reorderBuffer_tail);
			++reorderBuffer_size;
			pc = sPc;
		end
		readingICache = 1'b0;
	end

	always @ (posedge clk)
	begin: fetchInstruction
		if (reorderBuffer_size < REORDER_BUFFER_SIZE && reorderBuffer_hasHalt === 1'b0 && readingICache === 1'b0)
		begin
			readingICache = 1'b1;
			iCache_readPtr = pc;
		end
	end

	`undef parseI
	`undef parseR
	`undef parseI3
	`undef parseR3

	always @ (posedge clk)
	begin: shutdownSignal
		integer i;
		#0.8;
		for (i = 0; i < FUNCTION_UNIT_NUMBER; ++i)
		begin
			issueBus_opcode[i] = 'bx;
			issueBus_position[i] = 'bx;
			issueBus_qi[i] = 'bx;
			issueBus_vi[i] = 'bx;
			issueBus_qj[i] = 'bx;
			issueBus_vj[i] = 'bx;
			issueBus_qk[i] = 'bx;
			issueBus_vk[i] = 'bx;
		end
	end

	task parseRTypeInstruction;
		input[OPCODE_LENGTH - 1: 0]                    opcode;
		input[REGISTER_NUMBER_LOG - 1: 0]              rs;
		input[REGISTER_NUMBER_LOG - 1: 0]              rt;
		input[REGISTER_NUMBER_LOG - 1: 0]              rd;
		input[REORDER_BUFFER_SIZE_LOG - 1: 0]          head;
		input[REORDER_BUFFER_SIZE_LOG - 1: 0]          tail;
		output[OPCODE_LENGTH - 1: 0]                   _opcode;
		output[REORDER_BUFFER_SIZE_LOG - 1: 0]         position;
		output[FUNCTION_UNIT_NUMBER_LOG - 1: 0]        qi;
		output[31: 0]                                  vi;
		output[FUNCTION_UNIT_NUMBER_LOG - 1: 0]        qj;
		output[31: 0]                                  vj;
		output[FUNCTION_UNIT_NUMBER_LOG - 1: 0]        qk;
		output[31: 0]                                  vk;

		reg[REORDER_BUFFER_SIZE_LOG - 1: 0]            i;
		reg[REORDER_BUFFER_SIZE_LOG - 1: 0]            j;
		begin
			_opcode = opcode;
			position = tail;
			qi = 'bx;
			qj = 'bx;
			qk = 'bx;
			vi = 'bx;
			vj = 'bx;
			vk = 'bx;

			regStatus_readIndexA = rs;
			regStatus_readIndexB = rt;

			#0.01;
			// find value of rs
			if (regStatus_readValueA === 4'bx)
			begin
				regFile_readIndexA = rs;
				#0.01;
				vj = regFile_readValueA;
			end
			else
			begin
				if (reorderBuffer_rs[regStatus_readValueA] === 'bx)
				begin
					qj = reorderBuffer_fu[regStatus_readValueA];
				end
				else
				begin
					vj = reorderBuffer_rs[regStatus_readValueA];
				end
			end

			// find value of rt
			if (regStatus_readValueB === 4'bx)
			begin
				regFile_readIndexB = rt;
				#0.01
				vk = regFile_readValueB;
			end
			else
			begin
				if (reorderBuffer_rs[regStatus_readValueB] === 'bx)
				begin
					qk = reorderBuffer_fu[regStatus_readValueB];
				end
				else
				begin
					vk = reorderBuffer_rs[regStatus_readValueB];
				end
			end
		end
	endtask

	task parseITypeInstruction;
//	TODO: negative immediate
		input[OPCODE_LENGTH - 1: 0]                    opcode;
		input[REGISTER_NUMBER_LOG - 1: 0]              rs;
		input[REGISTER_NUMBER_LOG - 1: 0]              rd;
		input[31: 0]                                   immediate;
		input[REORDER_BUFFER_SIZE_LOG - 1: 0]          head;
		input[REORDER_BUFFER_SIZE_LOG - 1: 0]          tail;
		output[OPCODE_LENGTH - 1: 0]                   _opcode;
		output[REORDER_BUFFER_SIZE_LOG - 1: 0]         position;
		output[FUNCTION_UNIT_NUMBER_LOG - 1: 0]        qi;
		output[31: 0]                                  vi;
		output[FUNCTION_UNIT_NUMBER_LOG - 1: 0]        qj;
		output[31: 0]                                  vj;
		output[FUNCTION_UNIT_NUMBER_LOG - 1: 0]        qk;
		output[31: 0]                                  vk;

		reg[REORDER_BUFFER_SIZE_LOG - 1: 0]            i;
		reg[REORDER_BUFFER_SIZE_LOG - 1: 0]            j;
		begin
			_opcode = opcode;
			position = tail;
			qi = 'bx;
			qj = 'bx;
			qk = 'bx;
			vi = 'bx;
			vj = 'bx;
			vk = immediate;
			regStatus_readIndexA = rs;
			regStatus_readIndexB = rd;
			#0.01;
			
			// find value of rs
			if (regStatus_readValueA === 4'bx)
			begin
				regFile_readIndexA = rs;
				#0.01
				vj = regFile_readValueA;
			end
			else
			begin
				if (reorderBuffer_rs[regStatus_readValueA] === 'bx)
				begin
					qj = reorderBuffer_fu[regStatus_readValueA];
				end
				else
				begin
					vj = reorderBuffer_rs[regStatus_readValueA];
				end
			end
			// find value of rd
			if (regStatus_readValueB === 4'bx)
			begin
				regFile_readIndexB = rd;
				#0.01
				vi = regFile_readValueB;

			end
			else
			begin

				if (reorderBuffer_rs[regStatus_readValueB] === 'bx)
				begin
					qi = reorderBuffer_fu[regStatus_readValueB];
				end
				else
				begin
					vi = reorderBuffer_rs[regStatus_readValueB];
				end
			end
		end
	endtask

	function[REORDER_BUFFER_SIZE_LOG - 1: 0] incPointer;
		input[REORDER_BUFFER_SIZE_LOG - 1: 0] ptr;
	begin
		if (ptr + 1 < REORDER_BUFFER_SIZE)
		begin
			incPointer = ptr + 1;
		end
		else
		begin
			incPointer = 0;
		end
	end
	endfunction

	function[REORDER_BUFFER_SIZE_LOG - 1: 0] decPointer;
		input[REORDER_BUFFER_SIZE_LOG - 1: 0] ptr;
	begin
		if (ptr !== 'b0)
		begin
			decPointer = ptr - 1;
		end
		else
		begin
			decPointer = REORDER_BUFFER_SIZE;
		end
	end
	endfunction

endmodule
