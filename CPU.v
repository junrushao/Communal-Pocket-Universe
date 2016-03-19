`include "timescale.v"
`include "ReorderBuffer.v"

module CPU;
	`include "Utility.v"

	reg clk;
	reg reset;

	always #(0.5) clk = ~clk;

	ReorderBuffer reorderBuffer(.reset(reset), .clk(clk));

	initial
	begin
		clk = 1;
		reset = 1;
		#0.5 reset = 0;
	end

	initial begin
		$dumpfile("CPU.lxt");
		$dumpvars(0, CPU);
	end

endmodule

