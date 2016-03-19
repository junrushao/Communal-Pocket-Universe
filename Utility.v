parameter DATA_MEMORY_SIZE = 65536;
parameter INSTRUCTION_MEMORY_SIZE = 65536;
parameter DATA_MEMORY_SIZE_LOG = 16;
parameter INSTRUCTION_MEMORY_SIZE_LOG = 16;

parameter REORDER_BUFFER_SIZE = 16;
parameter REORDER_BUFFER_SIZE_LOG = 4;

parameter REGISTER_NUMBER = 32;
parameter REGISTER_NUMBER_LOG = 5;

parameter OPCODE_LENGTH = 6;
parameter OPCODE_ADD  = 6'b000000;
parameter OPCODE_ADDI = 6'b000001;
parameter OPCODE_SUB  = 6'b000010;
parameter OPCODE_SUBI = 6'b000011;
parameter OPCODE_MUL  = 6'b000100;
parameter OPCODE_LW   = 6'b000101;
parameter OPCODE_SW   = 6'b000110;
parameter OPCODE_BGE  = 6'b000111;
parameter OPCODE_SHL  = 6'b001000;
parameter OPCODE_SHR  = 6'b001001;
parameter OPCODE_HALT = 6'b001010;

parameter ADD_1_ID = 0;
parameter ADD_2_ID = 1;
parameter ADD_3_ID = 2;
parameter MUL_1_ID = 3;
parameter MUL_2_ID = 4;
parameter MUL_3_ID = 5;
parameter BGE_1_ID = 6;
parameter BGE_2_ID = 7;
parameter LW_1_ID  = 8;
parameter LW_2_ID  = 9;
parameter LW_3_ID  = 10;
parameter SW_1_ID  = 11;
parameter SW_2_ID  = 12;
parameter SW_3_ID  = 13;
parameter SHL_1_ID = 14;
parameter SHR_1_ID = 15;

parameter FUNCTION_UNIT_NUMBER = 16; // (add + mul + branch) + load + store
parameter FUNCTION_UNIT_NUMBER_LOG = 4; // (add + mul + branch) + load + store

parameter NUMBER_OF_BLOCKS_IN_CACHE = 4;
parameter NUMBER_OF_BLOCKS_IN_CACHE_LOG = 2;
parameter CACHE_SIZE = 64;
parameter BLOCK_SIZE = 16;
parameter BLOCK_SIZE_LOG = 4;
parameter TAG_SIZE = DATA_MEMORY_SIZE_LOG - NUMBER_OF_BLOCKS_IN_CACHE_LOG - BLOCK_SIZE_LOG;
parameter TAG_INVALID = 10'bx;

parameter MEMORY_ACCESS_DELAY = 200;

