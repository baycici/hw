

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
    output ofifo_valid               
);
    
    wire [bw*row-1:0] weight_data_out;  
    wire [psum_bw*col-1:0] psum_data_out; 
	wire [psum_bw*col-1:0] sfp_in; 

  
    // Input Sram
    sram_32b_w2048 #(.num(2048))
	input_sram (
        .CLK(clk),
        .A(inst[17:7]),        
        .D(D_xmem),     
		.CEN(inst[19]),
        .WEN(inst[18]), 
        .Q(weight_data_out)  
    );

    // Output SRAM 
    sram_128b_w2048 #(.num(2048))
	output_sram (
        .CLK(clk),
        .A(inst[30:20]),       
        .D(psum_data_out),         
		.CEN(inst[32]),
        .WEN(inst[31]),  
        .Q(sfp_in)                
    );

    // Corelet 
    corelet 
	corelet_inst (
        .clk(clk),
        .reset(reset),
        .inst(inst),                     
        .data_in(weight_data_out),      
        .data_in_acc(sfp_in),            
        .data_out(psum_data_out),
				.ofifo_o_valid(ofifo_valid),
	.sfp_data_out(sfp_out)
    );


endmodule
