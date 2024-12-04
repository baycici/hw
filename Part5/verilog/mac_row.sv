// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`include "mac_tile.sv"

module mac_row (clk, os_mode, out_s, in_w, in_n, valid, flush, 
`ifdef DEBUG_ENABLE
c_q_out, 
`endif
inst_w, reset);

	parameter bw = 4;
  	parameter psum_bw = 16;
  	parameter col = 8;

  	input  clk, reset, os_mode;
  	output [psum_bw*col-1:0] out_s;
  	output [col-1:0] valid;
`ifdef DEBUG_ENABLE
	output	[psum_bw-1:0]	c_q_out	[0:col-1];
`endif

  	input  [bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
  	input  [1:0] inst_w;
  	input  [psum_bw*col-1:0] in_n;
	input  flush;

  	wire 	[(col+1)*bw-1:0] temp_in;
	wire	[(col+1)*2-1:0] temp_inst;

  	assign temp_in[bw-1:0]  = in_w;
	assign temp_inst[1:0]	= inst_w;

  	genvar i;
  	for (i=1; i < col+1 ; i=i+1) begin : col_num
		mac_tile #(.bw(bw), .psum_bw(psum_bw)) mac_tile_instance (
    		.clk(clk),
    		.reset(reset),
			.os_mode(os_mode),
	    	.in_w( temp_in[bw*i-1:bw*(i-1)]),
	    	.out_e(temp_in[bw*(i+1)-1:bw*i]),
	    	.inst_w(temp_inst[2*i-1:2*(i-1)]),
	    	.inst_e(temp_inst[2*(i+1)-1:2*i]),
	    	.in_n(in_n[(psum_bw*i)-1:psum_bw*(i-1)]),
			.flush(flush),
			`ifdef DEBUG_ENABLE
			.c_q_out(c_q_out[i-1]),
			`endif
	    	.out_s(out_s[(psum_bw*i)-1:psum_bw*(i-1)])
		);
		assign valid[i-1] = temp_inst[2*(i+1)-1];
  	end

endmodule
