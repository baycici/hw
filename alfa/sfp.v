// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sfp (
   // Outputs:
   out,
   // Inputs:
   clk, acc, relu, reset, in
   );

parameter bw = 4;
parameter psum_bw = 16;

input clk;
input acc;
input relu;
input reset;

input signed [psum_bw-1:0] in;
//input signed [psum_bw-1:0] thres;

output  signed [psum_bw-1:0] out;

reg  signed [psum_bw-1:0] psum_q;

assign out = (psum_q < 0) ? 0 : psum_q; // Apply ReLU: set to 0 if negative

always @(posedge clk) begin
	if(reset) psum_q <= 0;

	else begin

		if(acc) psum_q <= psum_q + in;

		//else if(~acc) psum_q <= ( psum_q > 0 ) ? psum_q : 0;

        else psum_q <= psum_q;

	end
end

endmodule
