// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`include "../verilog/mac_row.sv"

module mac_array (clk, reset, os_mode, out_s, flush, 
`ifdef DEBUG_ENABLE
c_q_out, 
`endif
in_w, in_n, inst_w, valid);

	parameter bw = 4;
	parameter psum_bw = 16;
	parameter col = 8;
	parameter row = 8;

	input  clk, reset, os_mode;
	output [psum_bw*col-1:0] out_s;
`ifdef DEBUG_ENABLE
	output	[psum_bw-1:0]	c_q_out	[0:row-1][0:col-1];
`endif

	input  [row*bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
	input  [1:0] inst_w;
	input  [psum_bw*col-1:0] in_n;
	input  flush;
	output [col-1:0] valid;

	wire [row*col-1:0] temp_v;
	wire [(row+1)*col*psum_bw-1:0] temp_in_n;
	reg [row*2-1:0] temp_inst;

	assign valid = temp_v[col*row-1:col*(row-1)];
	assign temp_in_n[psum_bw*col-1:0] = in_n;
	assign out_s = temp_in_n[psum_bw*col*(row+1)-1 : psum_bw*col*(row)];

	genvar i;
  	for (i=1; i < row+1 ; i=i+1) begin : row_num
		mac_row #(.bw(bw), .psum_bw(psum_bw)) mac_row_instance (
      		.clk(clk),
	  		.reset(reset),
			.os_mode(os_mode),
	  		.inst_w(temp_inst[2*i-1 : 2*(i-1)]),
	  		.in_w(in_w[bw*i-1 : bw*(i-1)]),
	  		.valid(temp_v[col*i-1 : col*(i-1)]),
	  		.in_n(temp_in_n[psum_bw*col*i-1 : psum_bw*col*(i-1)]),
			.flush(flush),
			`ifdef DEBUG_ENABLE
			.c_q_out(c_q_out[i-1]),
			`endif

	  		.out_s(temp_in_n[psum_bw*col*(i+1)-1 : psum_bw*col*(i)])
      	);
  	end

	always @ (posedge clk) begin
    	temp_inst[1:0] <= inst_w[1:0]; 
   		temp_inst[3:2] <= temp_inst[1:0]; 
   		temp_inst[5:4] <= temp_inst[3:2]; 
   		temp_inst[7:6] <= temp_inst[5:4]; 
   		temp_inst[9:8] <= temp_inst[7:6]; 
   		temp_inst[11:10] <= temp_inst[9:8]; 
   		temp_inst[13:12] <= temp_inst[11:10]; 
   		temp_inst[15:14] <= temp_inst[13:12]; 
	end

endmodule
