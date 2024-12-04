// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sfp (out, in, os_mode, acc, relu, clk, reset);

parameter bw = 4;
parameter psum_bw = 16;

input clk;
input acc;
input relu;
input reset;
input signed [psum_bw-1:0] in;
input os_mode;
output signed [psum_bw-1:0] out;

reg signed [psum_bw-1:0] psum_q;

///////////////////////////////
//i,j,k
//0,0,0 0,1,1 0,2,2			0,1,0 0,2,1 0,3,2			0,2,0 0,3,1 0,4,2			0,3,0 0,4,1 0,5,2
//1,0,3 1,1,4 1,2,5			1,1,3 1,2,4 1,3,5			1,2,3 1,3,4 1,4,5			1,3,3 1,4,4 1,5,5
//2,0,6 2,1,7 2,2,8     2,1,6 2,2,7 2,3,8			2,2,6 2,3,7 2,4,8			2,3,6 2,4,7 2,5,8
//
//1,0,0 1,1,1 1,2,2			1,1,0 1,2,1 1,3,2			1,2,0 1,3,1 1,4,2			1,3,0 1,4,1 1,5,2
//2,0,3 2,1,4 2,2,5			2,1,3 2,2,4 2,3,5			2,2,3 2,3,4 2,4,5			2,3,3 2,4,4 2,5,5
//3,0,6 3,1,7 3,2,8     3,1,6 3,2,7 3,3,8			3,2,6 3,3,7 3,4,8			3,3,6 3,4,7 3,5,8
//
//2,0,0 2,1,1 2,2,2			2,1,0 2,2,1 2,3,2			2,2,0 2,3,1 2,4,2			2,3,0 2,4,1 2,5,2
//3,0,3 3,1,4 3,2,5			3,1,3 3,2,4 3,3,5			3,2,3 3,3,4 3,4,5			3,3,3 3,4,4 3,5,5
//4,0,6 4,1,7 4,2,8     4,1,6 4,2,7 4,3,8			4,2,6 4,3,7 4,4,8			4,3,6 4,4,7 4,5,8
//
//3,0,0 3,1,1 3,2,2			3,1,0 3,2,1 3,3,2			3,2,0 3,3,1 3,4,2			3,3,0 3,4,1 3,5,2
//4,0,3 4,1,4 4,2,5			4,1,3 4,2,4 4,3,5			4,2,3 4,3,4 4,4,5			4,3,3 4,4,4 4,5,5
//5,0,6 5,1,7 5,2,8     5,1,6 5,2,7 5,3,8			5,2,6 5,3,7 5,4,8			5,3,6 5,4,7 5,5,8
///////////////////////////////
always @(posedge clk) begin
  if (reset == 1)
		psum_q <= 0;
  else begin
	if(os_mode==0) begin
		if (acc == 1)
			psum_q <= psum_q + in;
		else if (relu == 1)
			psum_q <= (psum_q>0)? psum_q : 0;
		else
			psum_q <= psum_q;
	end
	else begin
		if(relu)
			psum_q <= (in>0)? in : 0;
	end
  end
end

assign out = psum_q;

endmodule
