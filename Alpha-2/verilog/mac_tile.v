// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 


module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset,index_w,index_e);

parameter index_selection=2;
parameter bw = 4;
parameter psum_bw = 16;

output [psum_bw-1:0] out_s;
input  [bw*index_selection-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
output [bw*index_selection-1:0] out_e; 
input  [1:0] inst_w;
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;

input   [1:0] index_w;
output  [1:0] index_e;


reg [1:0] inst_q;
reg [bw*index_selection-1:0] a_q;
reg [bw-1:0] b_q;
reg [psum_bw-1:0] c_q;
wire [psum_bw-1:0] mac_out;
reg load_ready_q;

reg  index_q;
reg  [1:0]index_out;
assign index_e=index_out;



wire selection;
assign selection =!(index_q ? index_w[1]:index_w[0]);
reg [bw-1:0] tomac;



mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
    .a(tomac), 
    .b(b_q),
    .c(c_q),
	.out(mac_out)
);

assign out_e = a_q;
assign inst_e = inst_q;
assign out_s = (index_q ? index_out[1]:index_out[0]) ? c_q: mac_out;

always @ (posedge clk) begin
	if (reset == 1) begin
		inst_q <= 0;
		load_ready_q <= 1'b1;
		a_q <= 0;
		b_q <= 0;
		c_q <= 0;
	end
	else begin
		inst_q[1] <= inst_w[1];
		c_q <= in_n;
		if (inst_w[1] | inst_w[0]) begin

			if(selection) begin tomac<=(index_q ? in_w[7:4]:in_w[3:0]); end 
			a_q <= in_w;
			index_out<=index_w;
		end
	
		if (inst_w[0] & load_ready_q) begin
			b_q <= index_w[0] ? in_w[7:4]:in_w[3:0];
			index_q<=index_w[0];
			load_ready_q <= 1'b0;
		end
		if (load_ready_q == 1'b0) begin
			inst_q[0] <= inst_w[0];
		end
	end
end

endmodule
