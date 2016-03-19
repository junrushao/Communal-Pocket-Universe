
/**
 * tag : index : offset = 10 : 2 : 4
 *
 * BLOCK_SIZE = 16
 * MEMORY_SIZE = 65536 words
 * CACHE_SIZE = 64 words
 *
 * NUMBER_OF_BLOCKS_IN_MEMORY = 4096
 * NUMBER_OF_BLOCKS_IN_CACHE = 4
 */
module InstructionCache(readPtr, readValue, readSuccess, busy, reset, clk);

	`include "Utility.v"

	input wire[31: 0]       readPtr;
	output reg[31: 0]       readValue;
	output reg              readSuccess;

	output reg[NUMBER_OF_BLOCKS_IN_CACHE - 1: 0]        busy;

	input wire              reset;
	input wire              clk;

	reg[31: 0]              memory[0: INSTRUCTION_MEMORY_SIZE - 1];
	reg[31: 0]              cache[0: CACHE_SIZE - 1];
	reg[TAG_SIZE - 1: 0]               cacheBlock_tag[0: NUMBER_OF_BLOCKS_IN_CACHE - 1];
	reg                     cacheBlock_dirty[0: NUMBER_OF_BLOCKS_IN_CACHE - 1];

	initial
	begin: __init__
		integer i;
		for (i = 0; i < INSTRUCTION_MEMORY_SIZE; ++i)
			memory[i] = 0;
		$readmemb("code.bin", memory);
	end

	always @ (posedge reset)
	begin: doReset
		integer i;
		readValue = 'bx;
		readSuccess = 'b0;
		busy = 'b0;
		for (i = 0; i < CACHE_SIZE; ++i)
			cache[i] = 'bx;
		for (i = 0; i < NUMBER_OF_BLOCKS_IN_CACHE_LOG; ++i)
			cacheBlock_tag[i] = 'bx;
		for (i = 0; i < NUMBER_OF_BLOCKS_IN_CACHE_LOG; ++i)
			cacheBlock_dirty[i] = 'b0;
	end

	always @ (posedge clk)
	begin: shutdownSignal
		#0.8;
		readSuccess = 1'b0;
	end

	always @ (readPtr)
	begin: memoryRead
		reg[TAG_SIZE - 1: 0]              tag;
		reg[NUMBER_OF_BLOCKS_IN_CACHE_LOG - 1: 0]              index;
		reg[BLOCK_SIZE_LOG - 1: 0]              offset;

		tag = readPtr >> (BLOCK_SIZE_LOG + NUMBER_OF_BLOCKS_IN_CACHE_LOG);
		index = readPtr >> BLOCK_SIZE_LOG;
		offset = readPtr;

		if (readPtr !== 'bx)
		begin
			#0.01;
			touchAddress(tag, index, offset);
			readValue = cache[{index, offset}];
			if (readPtr !== 'bx)
				readSuccess = 1'b1;
		end
	end

	task touchAddress;
		input[TAG_SIZE - 1: 0] tag;
		input[NUMBER_OF_BLOCKS_IN_CACHE_LOG - 1: 0] index;
		input[BLOCK_SIZE_LOG - 1: 0] offset;
		begin
			if (cacheBlock_tag[index] !== tag)
			begin
				busy[index] = 1'b1;
				#MEMORY_ACCESS_DELAY;
				writeBackBlock(index);
				readInBlock(tag, index);
				busy[index] = 1'b0;
			end
		end
	endtask

	task writeBackBlock;
		input[NUMBER_OF_BLOCKS_IN_CACHE_LOG - 1: 0] index;
		begin: doWriteBack
			reg[TAG_SIZE - 1: 0] tag;
			reg[BLOCK_SIZE_LOG - 1: 0] offset;
			integer i;
			tag = cacheBlock_tag[index];
			//writeBackMemory
			if (tag !== TAG_INVALID && cacheBlock_dirty[index] !== 'b0)
			begin
				for (i = 0; i <= BLOCK_SIZE - 1; ++i)
				begin
					offset = i;
					memory[{tag, index, offset}] = cache[{index, offset}];
				end
				cacheBlock_tag[index] = 'bx;
				cacheBlock_dirty[index] = 'b0;
			end
		end
	endtask

	task readInBlock;
		input[TAG_SIZE - 1: 0] tag;
		input[NUMBER_OF_BLOCKS_IN_CACHE_LOG - 1: 0] index;
		begin: doReadIn
			reg[BLOCK_SIZE_LOG - 1: 0] offset;
			integer i;
			for (i = 0; i <= BLOCK_SIZE - 1; ++i)
			begin
				offset = i;
				cache[{index, offset}] = memory[{tag, index, offset}];
			end
			cacheBlock_tag[index] = tag;
			cacheBlock_dirty[index] = 'b0;
		end
	endtask

endmodule

