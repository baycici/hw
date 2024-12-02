module l0 (clk, in, out, rd, wr, o_full, reset, o_ready);

	parameter row  = 8;
	parameter bw = 4;

	input  clk;
	input  wr;
	input  rd;
	input  reset;
	input  [row*bw-1:0] in;
	output [row*bw-1:0] out;
	output o_full;
	output o_ready;

	wire [row-1:0] empty;
	wire [row-1:0] full;
	reg [row-1:0] rd_en;

	wire [1:0] rd_sc;
	assign rd_sc= rd ? 2'b11:2'b00;
  
	genvar i;

	assign o_full  = |full;
	assign o_ready = ~o_full;

  	for (i=0; i<row ; i=i+1) begin : row_num
			fifo_depth64 #(.bw(bw)) fifo_instance (
	 		.rd_clk(clk),
	 		.wr_clk(clk),
	 		.rd(rd_en[i]),
	 		.wr(wr),
			.o_empty(empty[i]),
			.o_full(full[i]),
	 		.in(in[bw*(i+1)-1:bw*i]),
	 		.out(out[bw*(i+1)-1:bw*i]),
			.reset(reset)
		);end

  	always @ (posedge clk) begin
   		if (reset) begin
				rd_en <= 8'b00000000;
   		end
   		else begin
				rd_en <= {rd_en[5:0], rd_sc};
			end end

endmodule
