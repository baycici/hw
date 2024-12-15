
`include "../verilog/corelet.v"
`include "../verilog/sram_32b_w2048.v"
`include "../verilog/sram_128b_w2048.v"
`include "../verilog/ecc_encoder.sv"
`include "../verilog/ecc_decoder.sv"
module core #(
    parameter row = 8,                
    parameter col = 8,                
    parameter psum_bw = 16,          
    parameter bw = 4                 
)(
    input clk,                       
    input reset,                      
    input [34:0] inst,                
    input [bw*row-1:0] D_xmem,      
    //input [psum_bw*col-1:0] sfp_in,   
    output [psum_bw*col-1:0] sfp_out, 
    output ofifo_valid,
    output ecc_error_out
);
    
    wire [bw*row-1 + 7:0] weight_data_out;  
	wire [bw*row-1:0] weight_data_out_corrected;
    wire [psum_bw*col-1:0] psum_data_out;
	wire [8:0] psum_data_out_ecc;
	wire [psum_bw*col-1 + 9:0] sfp_in;
	wire [psum_bw*col-1:0] sfp_in_corrected;
    wire [6:0] D_xmem_ecc;
    wire input_single_error;
    wire input_double_error;
    wire input_fault_error;
    wire output_single_error;
    wire output_double_error;
    wire output_fault_error;

    // single error is fixed by decoder, so not included in error_out
    assign ecc_error_out = input_fault_error | input_double_error | output_fault_error | output_double_error;
  
	// ECC encoder at input SRAM inputs
	ecc_encoder #(.DAT_WIDTH(32), .ECC_WIDTH(7))
	input_ecc_enc (
		.data_in(D_xmem),
		.ecc_out(D_xmem_ecc)
	);
	
    // Input Sram
    sram_32b_w2048 #(.num(2048))
	input_sram (
        .CLK(clk),
        .A(inst[17:7]),        
        .D({D_xmem_ecc, D_xmem}),     
		.CEN(inst[19]),
        .WEN(inst[18]), 
        .Q(weight_data_out)  
    );

	// ECC decoder at input SRAM outputs
	ecc_decoder #(.DAT_WIDTH(32), .ECC_WIDTH(7)) 
	input_ecc_dec(
		.data_in(weight_data_out[31:0]), 
		.ecc_in(weight_data_out[38:32]), 
		.corrected_out(weight_data_out_corrected),
		.single_error(input_single_error),
		.double_error(input_double_error),
		.fault_error(input_fault_error)
	);

	// ECC encoder at output SRAM inputs
	ecc_encoder #(.DAT_WIDTH(128), .ECC_WIDTH(9))
	output_ecc_enc (
		.data_in(psum_data_out),
		.ecc_out(psum_data_out_ecc)
	);
	
    // Output SRAM 
    sram_128b_w2048 #(.num(2048))
	output_sram (
        .CLK(clk),
        .A(inst[30:20]),       
        .D({psum_data_out_ecc, psum_data_out}),         
		.CEN(inst[32]),
        .WEN(inst[31]),  
        .Q(sfp_in)                
    );
	
	// ECC decoder at output SRAM outputs
	ecc_decoder #(.DAT_WIDTH(128), .ECC_WIDTH(9)) 
	output_ecc_dec(
		.data_in(sfp_in[127:0]), 
		.ecc_in(sfp_in[136:128]), 
		.corrected_out(sfp_in_corrected),
		.single_error(output_single_error),
		.double_error(output_double_error),
		.fault_error(output_fault_error)
	);
	
    // Corelet 
    corelet 
	corelet_inst (
        .clk(clk),
        .reset(reset),
        .inst(inst),                     
        .data_in(weight_data_out_corrected),      
        .data_in_acc(sfp_in_corrected),            
        .data_out(psum_data_out),
				.ofifo_o_valid(ofifo_valid),
	.sfp_data_out(sfp_out)
    );


endmodule
