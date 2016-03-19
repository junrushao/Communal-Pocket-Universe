
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
module DataCache(
	readPtrA, readValueA, readSuccessA,
	readPtrB, readValueB, readSuccessB,
	readPtrC, readValueC, readSuccessC,
	writeEnable, writePtr, writeValue, writeSuccess,
	allWriteBack, allWriteBackSuccess, busy, reset, clk);

	`include "Utility.v"

	input wire[31: 0]       readPtrA;
	output reg[31: 0]       readValueA;
	output reg              readSuccessA;

	input wire[31: 0]       readPtrB;
	output reg[31: 0]       readValueB;
	output reg              readSuccessB;

	input wire[31: 0]       readPtrC;
	output reg[31: 0]       readValueC;
	output reg              readSuccessC;

	input wire              writeEnable;
	input wire[31: 0]       writePtr;
	input wire[31: 0]       writeValue;
	output reg              writeSuccess;

	input wire              allWriteBack;
	output reg              allWriteBackSuccess;
	output reg[NUMBER_OF_BLOCKS_IN_CACHE - 1: 0]        busy; // busy substituting block

	input wire              reset;
	input wire              clk;

	reg[31: 0]              memory[0: DATA_MEMORY_SIZE - 1];
	reg[31: 0]              cache[0: CACHE_SIZE - 1];
	reg[TAG_SIZE - 1: 0]               cacheBlock_tag[0: NUMBER_OF_BLOCKS_IN_CACHE - 1];
	reg                     cacheBlock_dirty[0: NUMBER_OF_BLOCKS_IN_CACHE - 1];

	initial
	begin: __init__
		integer i;
		for (i = 0; i < DATA_MEMORY_SIZE; ++i)
			memory[i] = 0;
		$readmemh("data.hex", memory);
	end

	always @ (posedge allWriteBack)
	begin: writeBackAllBlocks
		integer i,j;
		reg[BLOCK_SIZE_LOG - 1: 0] offset;
	 	reg[TAG_SIZE - 1: 0] tag;
		for (i = 0; i < NUMBER_OF_BLOCKS_IN_CACHE; ++i)
		begin
			while (busy[i] === 1'b1)
				#1;
			busy[i] = 1'b1;
			
			//writeBackMemory
				tag = cacheBlock_tag[i];

				if (tag !== TAG_INVALID && cacheBlock_dirty[i] !== 'b0)
				begin
					#MEMORY_ACCESS_DELAY;
					for (j = 0; j <= BLOCK_SIZE - 1; ++j)
					begin
						offset = j;
						memory[{tag, i, offset}] = cache[{i, offset}];
					end
					cacheBlock_tag[i] = 'bx;
					cacheBlock_dirty[i] = 'b0;
				end
			busy[i] = 1'b0;
		end
		allWriteBackSuccess = 1'b1;
	end

	always @ (posedge reset)
	begin: doReset
		integer i;
		readValueA = 'bx;
		readSuccessA = 1'b0;
		readValueB = 'bx;
		readSuccessB = 1'b0;
		readValueC = 'bx;
		readSuccessC = 1'b0;
		writeSuccess = 1'b0;
		allWriteBackSuccess = 1'b0;
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
		readSuccessA = 1'b0;
		readSuccessB = 1'b0;
		readSuccessC = 1'b0;
		writeSuccess = 1'b0;
	end

	always @ (readPtrA)
	begin: memoryReadA
	 	integer i;
	 	reg[BLOCK_SIZE_LOG - 1: 0] offset;
	 	reg[TAG_SIZE - 1: 0] tag;

		reg[TAG_SIZE - 1: 0] tagA;
		reg[NUMBER_OF_BLOCKS_IN_CACHE_LOG - 1: 0] indexA;
		reg[BLOCK_SIZE_LOG - 1: 0] offsetA;

		tagA = readPtrA >> (BLOCK_SIZE_LOG + NUMBER_OF_BLOCKS_IN_CACHE_LOG);
		indexA = readPtrA >> BLOCK_SIZE_LOG;
		offsetA = readPtrA;

		if (readPtrA !== 'bx)
		begin
			#0.01;
			while (busy[indexA] === 1'b1)#1;
			if (cacheBlock_tag[indexA] !== tagA)
			begin
				busy[indexA] = 1'b1;
				#MEMORY_ACCESS_DELAY;
				//writeBackMemory
				tag = cacheBlock_tag[indexA];
				
				if (tag !== TAG_INVALID && cacheBlock_dirty[indexA] !== 'b0)
				begin
					#MEMORY_ACCESS_DELAY;
					for (i = 0; i <= BLOCK_SIZE - 1; ++i)
					begin
						offset = i;
						memory[{tag, indexA, offset}] = cache[{indexA, offset}];
					end
					cacheBlock_tag[indexA] = 'bx;
					cacheBlock_dirty[indexA] = 'b0;
				end
				
				//loadMemory
				for (i = 0; i <= BLOCK_SIZE - 1; ++i)
				begin
					offset = i;
					cache[{indexA, offset}] = memory[{tagA, indexA, offset}];
				end
				cacheBlock_tag[indexA] = tagA;
				cacheBlock_dirty[indexA] = 'b0;
				busy[indexA] = 1'b0;
			end
			readValueA = cache[{indexA, offsetA}];
			if (readPtrA !== 'bx)
				readSuccessA = 1'b1;
		end
	end

	always @ (readPtrB)
	begin: memoryReadB
	 	integer i;
	 	reg[BLOCK_SIZE_LOG - 1: 0] offset;
	 	reg[TAG_SIZE - 1: 0] tag;

		reg[TAG_SIZE - 1: 0] tagB;
		reg[NUMBER_OF_BLOCKS_IN_CACHE_LOG - 1: 0] indexB;
		reg[BLOCK_SIZE_LOG - 1: 0] offsetB;

		tagB = readPtrB >> (BLOCK_SIZE_LOG + NUMBER_OF_BLOCKS_IN_CACHE_LOG);
		indexB = readPtrB >> BLOCK_SIZE_LOG;
		offsetB = readPtrB;

		if (readPtrB !== 'bx)
		begin
			#0.01;
			while (busy[indexB] === 1'b1)#1;
			if (cacheBlock_tag[indexB] !== tagB)
			begin
				busy[indexB] = 1'b1;
				#MEMORY_ACCESS_DELAY;
				tag = cacheBlock_tag[indexB];
				
				//writeBackMemory
				if (tag !== TAG_INVALID && cacheBlock_dirty[indexB] !== 'b0)
				begin
					#MEMORY_ACCESS_DELAY;
					for (i = 0; i <= BLOCK_SIZE - 1; ++i)
					begin
						offset = i;
						memory[{tag, indexB, offset}] = cache[{indexB, offset}];
					end
					cacheBlock_tag[indexB] = 'bx;
					cacheBlock_dirty[indexB] = 'b0;
				end
				
				//loadMemory
				for (i = 0; i <= BLOCK_SIZE - 1; ++i)
				begin
					offset = i;
					cache[{indexB, offset}] = memory[{tagB, indexB, offset}];
				end
				cacheBlock_tag[indexB] = tagB;
				cacheBlock_dirty[indexB] = 'b0;
				busy[indexB] = 1'b0;
			end
			readValueB = cache[{indexB, offsetB}];
			if (readPtrB !== 'bx)
				readSuccessB = 1'b1;
		end
	end

	always @ (readPtrC)
	begin: memoryReadC
	 	integer i;
	 	reg[BLOCK_SIZE_LOG - 1: 0] offset;
	 	reg[TAG_SIZE - 1: 0] tag;

		reg[TAG_SIZE - 1: 0] tagC;
		reg[NUMBER_OF_BLOCKS_IN_CACHE_LOG - 1: 0] indexC;
		reg[BLOCK_SIZE_LOG - 1: 0] offsetC;

		tagC = readPtrC >> (BLOCK_SIZE_LOG + NUMBER_OF_BLOCKS_IN_CACHE_LOG);
		indexC = readPtrC >> BLOCK_SIZE_LOG;
		offsetC = readPtrC;

		if (readPtrC !== 'bx)
		begin
			#0.01;
			while (busy[indexC] === 1'b1)#1;
			if (cacheBlock_tag[indexC] !== tagC)
			begin
				busy[indexC] = 1'b1;
				#MEMORY_ACCESS_DELAY;
				tag = cacheBlock_tag[indexC];
				
				//writeBackMemory
				if (tag !== TAG_INVALID && cacheBlock_dirty[indexC] !== 'b0)
				begin
					#MEMORY_ACCESS_DELAY;
					for (i = 0; i <= BLOCK_SIZE - 1; ++i)
					begin
						offset = i;
						memory[{tag, indexC, offset}] = cache[{indexC, offset}];
					end
					cacheBlock_tag[indexC] = 'bx;
					cacheBlock_dirty[indexC] = 'b0;
				end
				
				//loadMemory
				for (i = 0; i <= BLOCK_SIZE - 1; ++i)
				begin
					offset = i;
					cache[{indexC, offset}] = memory[{tagC, indexC, offset}];
				end
				cacheBlock_tag[indexC] = tagC;
				cacheBlock_dirty[indexC] = 'b0;
				busy[indexC] = 1'b0;
			end
			readValueC = cache[{indexC, offsetC}];
			if (readPtrC !== 'bx)
				readSuccessC = 1'b1;
		end
	end

	always @ (posedge writeEnable)
	begin: memoryWrite
		integer i;
	 	reg[BLOCK_SIZE_LOG - 1: 0] offset;
	 	reg[TAG_SIZE - 1: 0] tag;

		reg[TAG_SIZE - 1: 0] tagW;
		reg[NUMBER_OF_BLOCKS_IN_CACHE_LOG - 1: 0] indexW;
		reg[BLOCK_SIZE_LOG - 1: 0] offsetW;

		tagW = writePtr >> (BLOCK_SIZE_LOG + NUMBER_OF_BLOCKS_IN_CACHE_LOG);
		indexW = writePtr >> BLOCK_SIZE_LOG;
		offsetW = writePtr;

		if (writePtr !== 'bx)
		begin
			#0.01;
			while (busy[indexW] === 1'b1)#1;
			if (cacheBlock_tag[indexW] !== tagW)
			begin
				busy[indexW] = 1'b1;
				#MEMORY_ACCESS_DELAY;
				tag = cacheBlock_tag[indexW];
				
				//writeBackMemory
				if (tag !== TAG_INVALID && cacheBlock_dirty[indexW] !== 'b0)
				begin
					#MEMORY_ACCESS_DELAY;
					for (i = 0; i <= BLOCK_SIZE - 1; ++i)
					begin
						offset = i;
						memory[{tag, indexW, offset}] = cache[{indexW, offset}];
					end
					cacheBlock_tag[indexW] = 'bx;
					cacheBlock_dirty[indexW] = 'b0;
				end
				
				//loadMemory
				for (i = 0; i <= BLOCK_SIZE - 1; ++i)
				begin
					offset = i;
					cache[{indexW, offset}] = memory[{tagW, indexW, offset}];
				end
				cacheBlock_tag[indexW] = tagW;
				cacheBlock_dirty[indexW] = 'b0;
				busy[indexW] = 1'b0;
			end
			if (writeValue !== cache[{indexW, offsetW}])
			begin
				cache[{indexW, offsetW}] = writeValue;
				cacheBlock_dirty[indexW] = 'b1;
			end
			writeSuccess = 1'b1;
		end
	end

endmodule

