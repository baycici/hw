// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 


module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid,index_w);
    
	parameter index_selection=2;
	parameter bw = 4;
	parameter psum_bw = 16;
	parameter col = 8;
	parameter row = 8;

	input  clk, reset;
	output [psum_bw*col-1:0] out_s;
	input  [row*bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
	input  [1:0] inst_w;
	input  [psum_bw*col-1:0] in_n;
	output [col-1:0] valid;

	input   [row/index_selection-1:0]index_w;

	wire [(row/index_selection)*col-1:0] temp_v;
	wire [(row/index_selection+1)*col*psum_bw-1:0] temp_in_n;
	reg [(row/index_selection)*2-1:0] temp_inst;

	

	assign valid = temp_v[col*(row/index_selection)-1:col*((row/index_selection)-1)];
	assign temp_in_n[psum_bw*col-1:0] = in_n;
	assign out_s = temp_in_n[psum_bw*col*((row/index_selection)+1)-1 : psum_bw*col*((row/index_selection))];

	genvar i;
  	for (i=1; i < (row/index_selection)+1 ; i=i+1) begin : row_num
		mac_row #(.bw(bw), .psum_bw(psum_bw)) mac_row_instance (
      		.clk(clk),
	  		.reset(reset),
	  		.inst_w(temp_inst[2*i-1 : 2*(i-1)]),
			.in_w({in_w[bw*(i*index_selection+2)-1 : bw*(i*index_selection+1)],in_w[bw*i*index_selection-1 : bw*(i*index_selection-1)]}),
			.index_w(index_w[i-1]),
	  		.valid(temp_v[col*i-1 : col*(i-1)]),
	  		.in_n(temp_in_n[psum_bw*col*i-1 : psum_bw*col*(i-1)]),
	  		.out_s(temp_in_n[psum_bw*col*(i+1)-1 : psum_bw*col*(i)])
      	);
  	end

	always @ (posedge clk) begin
    	temp_inst[1:0] <= inst_w[1:0]; 
   		temp_inst[3:2] <= temp_inst[1:0]; 
   		temp_inst[5:4] <= temp_inst[3:2]; 
   		temp_inst[7:6] <= temp_inst[5:4]; 
	end

endmodule
