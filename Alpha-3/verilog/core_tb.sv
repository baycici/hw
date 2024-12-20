// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps

`include "../verilog/core.v"
module core_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_onij = 16;
parameter col = 8;
parameter row = 8;
parameter len_nij = 36;

reg clk = 0;
reg reset = 1;

wire [34:0] inst_q; 

reg [1:0]  inst_w_q = 0; 
reg [bw*row-1:0] D_xmem_q = 0;
reg CEN_xmem = 1;
reg WEN_xmem = 1;
reg [10:0] A_xmem = 0;
reg [10:0] W_mem_base = 11'h400;
reg CEN_xmem_q = 1;
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;
reg CEN_pmem = 1;
reg WEN_pmem = 1;
reg [10:0] A_pmem = -1;
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg [10:0] A_pmem_q = 0;
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg relu_q = 0;
reg acc = 0;
reg relu = 0;

reg [1:0]  inst_w; 
reg [bw*row-1:0] D_xmem;
reg [psum_bw*col-1:0] answer;


reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;
reg [8*30:1] stringvar;
reg [8*30:1] w_file_name;
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;
wire ecc_error_out;

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij;
integer error;

assign inst_q[34] = relu_q;
assign inst_q[33] = acc_q;
assign inst_q[32] = CEN_pmem_q;
assign inst_q[31] = WEN_pmem_q;
assign inst_q[30:20] = A_pmem_q;
assign inst_q[19]   = CEN_xmem_q;
assign inst_q[18]   = WEN_xmem_q;
assign inst_q[17:7] = A_xmem_q;
assign inst_q[6]   = ofifo_rd_q;
assign inst_q[5]   = ififo_wr_q;
assign inst_q[4]   = ififo_rd_q;
assign inst_q[3]   = l0_rd_q;
assign inst_q[2]   = l0_wr_q;
assign inst_q[1]   = execute_q; 
assign inst_q[0]   = load_q; 


core  #(.bw(bw), .col(col), .row(row)) core_instance (
	.clk(clk), 
	.inst(inst_q),
	.ofifo_valid(ofifo_valid),
        .D_xmem(D_xmem_q), 
        .sfp_out(sfp_out), 
	.reset(reset),
  .ecc_error_out(ecc_error_out)); 

always begin
	#5 clk <= 0;
	#5 clk <= 1;
end

task set_reset;
	begin
		@(negedge clk)  reset = 1;
		repeat(10) @(negedge clk);
		reset = 0;
	end
endtask

always @(posedge clk) begin
    if(ecc_error_out) begin
        $display("Error in SRAM data!!\n Resetting system!");
        set_reset();
    end
end

initial begin 

  inst_w   = 0; 
  D_xmem   = 0;
  CEN_xmem = 1;
  WEN_xmem = 1;
  A_xmem   = 0;
  ofifo_rd = 0;
  ififo_wr = 0;
  ififo_rd = 0;
  l0_rd    = 0;
  l0_wr    = 0;
  execute  = 0;
  load     = 0;

  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);

  x_file = $fopen("../sim/activation.txt", "r");
  // Following three lines are to remove the first three comment lines of the file
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);

	set_reset();

  /////// Activation data writing to memory ///////
  for (t=0; t<len_nij; t=t+1) begin  
		@(negedge clk);
    x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
		WEN_xmem = 0; 
		CEN_xmem = 0; 
		if (t>0) 
			A_xmem = A_xmem + 1;
       
  end
  @(negedge clk);  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
  $fclose(x_file);
  /////////////////////////////////////////////////


  for (kij=0; kij<9; kij=kij+1) begin  // kij loop

    case(kij)
     0: w_file_name = "../sim/weight0.txt";
     1: w_file_name = "../sim/weight1.txt";
     2: w_file_name = "../sim/weight2.txt";
     3: w_file_name = "../sim/weight3.txt";
     4: w_file_name = "../sim/weight4.txt";
     5: w_file_name = "../sim/weight5.txt";
     6: w_file_name = "../sim/weight6.txt";
     7: w_file_name = "../sim/weight7.txt";
     8: w_file_name = "../sim/weight8.txt";
    endcase
    
    w_file = $fopen(w_file_name, "r");
    // Following three lines are to remove the first three comment lines of the file
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);

		set_reset();

    /////// Kernel data writing to memory ///////
    for (t=0; t<col; t=t+1) begin  
      @(negedge clk);  
			w_scan_file = $fscanf(w_file,"%32b", D_xmem); 
			WEN_xmem = 0; 
			CEN_xmem = 0; 
			A_xmem = W_mem_base + t; 
    end

    @(negedge clk);  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
    /////////////////////////////////////

    /////// Kernel data writing to L0 ///////
    for (t=0; t<col; t=t+1) begin  
			@(negedge clk);  
			l0_wr = 0; 	
			WEN_xmem = 1; // read
			CEN_xmem = 0;
			A_xmem = W_mem_base + t;
			@(negedge clk);
			CEN_xmem = 1;
			l0_wr = 1; 	
    end
		@(negedge clk);  
		CEN_xmem = 1;
		l0_wr = 0;
    /////////////////////////////////////

    /////// Kernel loading to PEs ///////
    for (t=0; t<col; t=t+1) begin  
			@(negedge clk);
			l0_rd = 1;
			load = 1;
		end
    ////// provide some intermission to clear up the kernel loading ///
    @(negedge clk);  load = 0; l0_rd = 0;
  
		repeat(10) @(negedge clk);
		/////////////////////////////////////

    /////// Activation data writing to L0 ///////
    for (t=0; t<len_nij; t=t+1) begin  
			@(negedge clk);  
			l0_wr = 0; 	
			WEN_xmem = 1; // read
			CEN_xmem = 0;
			A_xmem = t;
			@(negedge clk);
			CEN_xmem = 1;
			l0_wr = 1; 	
    end
		@(negedge clk);  
		CEN_xmem = 1;
		l0_wr = 0;
    /////////////////////////////////////

    /////// Execution ///////
		for (t=0; t<len_nij; t=t+1) begin  
			@(negedge clk);
			l0_rd = 1;
			execute = 1;
		end
    ////// provide some intermission to clear up the  execution ///
    @(negedge clk);  execute = 0; l0_rd = 0;
		repeat(10) @(negedge clk);
		/////////////////////////////////////

    //////// OFIFO READ ////////
		for(t=0; t<len_nij; t++) begin
			ofifo_rd = 1;
			CEN_pmem = 0;
			WEN_pmem = 0;
			A_pmem = A_pmem + 1;
			@(negedge clk);
			CEN_pmem = 1;
			ofifo_rd = 0;
			@(negedge clk);
		end
		CEN_pmem = 1;
    /////////////////////////////////////
		repeat(10) @(negedge clk);

  end  // end of kij loop


  ////////// Accumulation /////////
  out_file = $fopen("../sim/output.txt", "r");  
	acc_file = $fopen("../sim/acc_address.txt", "r");

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;

  $display("############ Verification Start during accumulation #############"); 

  for (i=0; i<len_onij+1; i=i+1) begin 

		@(negedge clk);

    if (i>0) begin
     out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
       if (sfp_out == answer)
         $display("%2d-th output featuremap Data matched! :D", i); 
       else begin
         $display("%2d-th output featuremap Data ERROR!!", i); 
         $display("sfpout: %128b", sfp_out);
         $display("answer: %128b", answer);
         error = 1;
       end
    end
   
 		set_reset();

    for (j=0; j<len_kij+1; j=j+1) begin 

			@(negedge clk);
        if (j<len_kij) begin CEN_pmem = 0; WEN_pmem = 1; acc_scan_file = $fscanf(acc_file,"%d", A_pmem); end
                       else  begin CEN_pmem = 1; WEN_pmem = 1; end

        if (j>0)  acc = 1;  
    end

    @(negedge clk); acc = 0; relu = 1;
		@(negedge clk); relu = 0;
  end


  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 

  end

  $fclose(acc_file);
  //////////////////////////////////
	repeat(10) @(negedge clk);
  #10 $finish;

end

always @ (posedge clk) begin
   inst_w_q   <= inst_w; 
   D_xmem_q   <= D_xmem;
   CEN_xmem_q <= CEN_xmem;
   WEN_xmem_q <= WEN_xmem;
   A_pmem_q   <= A_pmem;
   CEN_pmem_q <= CEN_pmem;
   WEN_pmem_q <= WEN_pmem;
   A_xmem_q   <= A_xmem;
   ofifo_rd_q <= ofifo_rd;
   acc_q      <= acc;
   relu_q     <= relu;
   ififo_wr_q <= ififo_wr;
   ififo_rd_q <= ififo_rd;
   l0_rd_q    <= l0_rd;
   l0_wr_q    <= l0_wr ;
   execute_q  <= execute;
   load_q     <= load;
end


endmodule




