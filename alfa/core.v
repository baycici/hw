module core #(
    parameter row = 8,                
    parameter col = 8,                
    parameter psum_bw = 16,          
    parameter bw = 4                 
)(
    input clk,                       
    input reset,                      
    input [33:0] inst,                
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
       
		//inputs:
		.clk(clk),
        .reset(reset),
        .inst(inst),
       // .sfp_2(sfp_2),		
        .data_in(weight_data_out),      
        .sfp_in(sfp_in[psum_bw*col-1:0]),
		//outputs:		
        .psum_out(psum_data_out[psum_bw*col-1:0]),
		.sfp_psum_out(sfp_out[psum_bw*col-1:0]),
		.ofifo_valid	(ofifo_valid)
      
    );
	
	


endmodule
