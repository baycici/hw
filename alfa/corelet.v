//Corelet module contains the MAC array, L0, output FIFO and SFU

//? clk - Master clock
//? reset - Master reset, high enable
//? inst[33:0] - All extra signals
//?     6 - ofifo_rd
//?     5 - ififo_wr
//?     4 - ififo_rd
//?     3 - l0_rd
//?     2 - l0_wr
//?     1 - execute
//?     0 - load

`include "l0.v"
`include "mac_array.v"
`include "ofifo.v"
`include "sfp.v"

module corelet #(
    parameter row = 8,
    parameter col = 8,
    parameter psum_bw = 16,
    parameter bw = 4
)(
    input clk,
    input reset,
    input [33:0] inst,
    input [bw*row-1:0] data_in,
    input [psum_bw*col-1:0] sfp_in,
	//input sfp_2,
    output [psum_bw*col-1:0] psum_out,
    output [psum_bw*col-1:0] sfp_psum_out,
	output ofifo_valid
	
);

    



wire sfp2;
// L0 signals
wire [psum_bw*col-1:0] in_n;
assign in_n = 128'b0;
//wire L0_clk;
wire L0_wr;
assign L0_wr = inst[2];
wire L0_rd;
assign L0_rd = inst[3];
//wire L0_reset;
//wire [bw*row-1:0] L0_in;
wire [bw*row-1:0] L0_out;
wire L0_o_full;
wire L0_o_ready;

//assign L0_clk = clk;
//assign L0_reset = reset;


//assign L0_reset = reset;
//assign L0_in = data_in;
//assign L0_o_full_out = L0_o_full;
//assign L0_o_ready_out = L0_o_ready;

// Instantiate L0
l0 #(
    .row(row),
    .bw(bw)
) L0_inst (
	//Inputs:
    .clk(clk),
    .wr(L0_wr),
    .rd(L0_rd),
    .reset(reset),
    .in(data_in[row*bw-1:0]),
	//Outputs:
    .out(L0_out[row*bw-1:0]),
    .o_full(L0_o_full),
    .o_ready(L0_o_ready)
);

// MAC signals
wire mac_clk;
wire mac_reset;
wire [psum_bw*col-1:0] mac_out_s;
wire [bw*row-1:0] mac_in_w;
wire [1:0] mac_inst_w;
//wire [psum_bw*col-1:0] mac_in_n;
wire [col-1:0] mac_valid;

assign mac_clk = clk;
assign mac_reset = reset;
assign mac_in_w = L0_out[row*bw-1:0];
assign mac_inst_w = inst[1:0];
//assign mac_in_n = 0;

 
// Instantiate MAC
mac_array #(
    .bw(bw),
    .psum_bw(psum_bw),
    .col(col),
    .row(row)
) mac_array_inst (
    //inputs:
    .clk(clk),
    .reset(reset),
    .in_w(mac_in_w),
    .inst_w(mac_inst_w),
    .in_n(in_n[psum_bw*col-1:0]),
	//outputs:
	.out_s(mac_out_s[psum_bw*col-1:0]),
	.valid(mac_valid[col-1:0])
    );

// OFIFO signals
//wire ofifo_clk;
//wire ofifo_reset;
wire [col-1:0] ofifo_wr;
wire ofifo_rd;
wire [psum_bw*col-1:0] ofifo_in;
wire [psum_bw*col-1:0] ofifo_out;
wire ofifo_o_full;
wire ofifo_o_ready;
wire ofifo_o_valid;

assign ofifo_wr = mac_valid;
assign ofifo_rd = inst[6];
assign ofifo_in = mac_out_s[psum_bw*col-1:0];
assign psum_out = ofifo_out;

// Instantiate OFIFO
ofifo #(
    .col(col),
    .psum_bw(psum_bw)
) ofifo_inst (
	//Inputs:
    .clk(clk),
    .reset(reset),
    .wr(ofifo_wr),
    .rd(ofifo_rd),
    .in(ofifo_in),
	//Outputs:
    .out(ofifo_out[col*psum_bw-1:0]),
    .o_full(ofifo_o_full),
    .o_ready(ofifo_o_ready),
    .o_valid(ofifo_o_valid)
);



	
//wire sfp_clk;
//wire sfp_acc;
//wire sfp_2;
wire sfp_reset;
//wire [psum_bw*col-1:0] sfp_in;
wire [psum_bw*col-1:0] sfp_out;

//assign sfp_clk = clk;
assign sfp_acc = inst[33];
//assign sfp_relu = 0;
//assign sfp_reset = reset;
//assign sfp_in = sfp_in;
assign sfp_psum_out = sfp_out;


assign sfp_2 = 1'b0;//(accumulation_counter == 7) ? 1'b1 : 1'b0;

genvar i;
generate
for (i = 1; i <= col; i = i + 1) begin : sfp_num
    
    sfp #(
        .bw(bw),
        .psum_bw(psum_bw)
    ) sfp_inst (
        //Inputs:
        .clk(clk),
        .acc(sfp_acc),
        //.relu(sfp_2),  // Use the relu_signal here
        .reset(reset),
        .in(sfp_in[psum_bw*i-1:psum_bw*(i-1)]),
        //Outputs:
        .out(sfp_out[psum_bw*i-1:psum_bw*(i-1)])
    );
end
endgenerate


endmodule