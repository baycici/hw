// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps
`define RANDOM_INPUTS

`include "../verilog/core.sv"
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

wire [36:0] inst_q; 

reg [1:0]  inst_w_q = 0; 
reg [psum_bw*row-1:0] D_xmem_q = 0;
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
reg os_mode_q = 0;
reg flush_q = 0;
reg acc = 0;
reg relu = 0;
reg os_mode = 0;
reg flush = 0;

reg [1:0]  inst_w; 
reg [psum_bw*row-1:0] D_xmem;
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

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij, k1, k2, tile;
integer error, seed;

assign inst_q[36] = flush_q;
assign inst_q[35] = os_mode_q;
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
	.reset(reset)); 

integer temp[16][8];
always begin
	#5 clk <= 0;
	#5 clk <= 1;
end

task set_reset;
	begin
		@(negedge clk)  reset = 1;
		repeat(10) @(negedge clk);
		reset = 0;
    seed=10;
 	end
endtask

logic [3:0]	weight_array [0:row-1][0:col-1];
logic [3:0]	act_array [0:35][0:7];
logic [3:0]	act_ostat	[0:15][0:8][0:7];
logic signed [3:0]	weight_ostat [0:8][0:7][0:7];	//[0:kij][0:ichannel][0:ochannel];
integer row_i;
integer col_i;
integer row_j;
integer col_j;
integer counter;
logic[127:0] tb_checker_output[2*row];
logic [4*8-1:0]	act_ostat_to_l0;
logic [16*8-1:0]	weight_ostat_to_l0;
logic[127:0] output_check[row];

integer counter_act_ostat [0:15];
initial begin 
   for(i=0; i<16; i=i+1) begin
        for(j=0; j<8; j=j+1) begin
            temp[i][j] = 0;
        end
    end

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

`ifndef RANDOM_INPUTS
  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);

  x_file = $fopen("../sim/activation.txt", "r");
  // Following three lines are to remove the first three comment lines of the file
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
`else
	$display("Design configuration set to random inputs");
`endif

	set_reset();

  /////////////////////////////////////////////////
  $display("Implementing Weight Stationary");
  /////////////////////////////////////////////////
  /////// Activation data writing to memory ///////
  for (t=0; t<len_nij; t=t+1) begin  
		@(negedge clk);
		`ifdef RANDOM_INPUTS
		D_xmem = $random;
		`else
		x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
		`endif
		for(col_i=0 ; col_i<col; col_i=col_i+1) begin
			act_array[t][col_i] = D_xmem[4*col_i+:4];
		end
		WEN_xmem = 0; 
		CEN_xmem = 0; 
		if (t>0) 
			A_xmem = A_xmem + 1;
       
  end
  @(negedge clk);  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
`ifndef RANDOM_INPUTS
  $fclose(x_file);
`endif
  /////////////////////////////////////////////////

//Populating the act_ostat
for(i=0 ;i <16; i=i+1)
	counter_act_ostat[i] = 0;

for(i=0; i < 36 ; i=i+1)
begin
	row_i = i /6;
	col_i = i %6;
	for (j = 0; j < 16; j=j+1)
	begin
		row_j = j /4;
		col_j = j %4;
		if( (row_i>=row_j && row_i<= (row_j+2)) &&
			(col_i>=col_j && col_i<= (col_j+2)) )
		begin
			for(k=0 ; k<8; k=k+1)
			begin
				act_ostat[j][counter_act_ostat[j]][k] = act_array[i][k];
        //$display("Act ostat: %0h", act_ostat[j][counter_act_ostat[j]][k]);
			end
			counter_act_ostat[j] = counter_act_ostat[j] + 1;
		end
	end
end

  for (kij=0; kij<9; kij=kij+1) begin  // kij loop

`ifndef RANDOM_INPUTS
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
`endif

		set_reset();

    /////// Kernel data writing to memory ///////
	//row_i = iterates over different output channels 
	//t = iterates over different input channels
	//kij - iterates over different kij(0,9) 
    for (t=0; t<col; t=t+1) begin  
      @(negedge clk);  
	  `ifdef RANDOM_INPUTS
		D_xmem = $random;
		`else
			w_scan_file = $fscanf(w_file,"%32b", D_xmem);
		`endif
			for(row_i=0 ; row_i<row; row_i=row_i+1) begin
				weight_array[t][row_i] = D_xmem[4*row_i+:4];
				weight_ostat[kij][row_i][t] = weight_array[t][row_i]; 
			end	
			//if(kij==0)
				//$display("kij=%d, t=%d, weight_ostat=%b", kij, t, weight_ostat[kij][][]);
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
		for(t=0; t<len_nij; t=t+1) begin
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

		`ifndef RANDOM_INPUTS
		$fclose(w_file);
		`endif
  end  // end of kij loop


	///////////////// TB automated output generation based on inputs /////////////
	counter = 0 ;
	for(k1=0; k1<16; k1=k1+1) begin
		for(k2=0; k2<8; k2=k2+1) begin
			for  (i=0; i<9; i=i+1)
			begin
				for (j=0; j<8; j=j+1)
				begin
					temp[k1][k2] = $signed(temp[k1][k2]) + $signed({1'b0,act_ostat[k1][i][j]})* $signed(weight_ostat[i][j][k2]);
					//$display("temp: %0h, act_ostat: %0h, weight_ostat: %0h", temp[k1][k2], act_ostat[k1][i][j], weight_ostat[i][j][k2]);
          counter=counter+1;
					@(negedge clk);
				end
			end
		end
	end
	for(k1=0; k1<16; k1=k1+1) begin
    tb_checker_output[k1] = 0;
		for(k2=7; k2>=0; k2=k2-1) begin
			if(temp[k1][k2]<0)
				temp[k1][k2]=0;
			//tb_checker_output[k1][16*k2+:16] = temp[k1][k2];
			tb_checker_output[k1] = {tb_checker_output[k1], temp[k1][k2][15:0]};
      //$display("TB checker %0h \n", tb_checker_output[k1]);
		end
	end
	
  ////////// Accumulation /////////
  acc_file = $fopen("../sim/acc_address.txt", "r");
  
  `ifndef RANDOM_INPUTS
  out_file = $fopen("../sim/psum.txt", "r");  

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  `endif

  error = 0;

  $display("############ Verification Start during accumulation #############"); 

  for (i=0; i<len_onij+1; i=i+1) begin 

		@(negedge clk);

    if (i>0) begin
	   `ifdef RANDOM_INPUTS
	   if(sfp_out==tb_checker_output[i-1])
	   `else
	   out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
       if (sfp_out == answer)
	   `endif
         $display("%2d-th output featuremap Data matched! :D", i); 
       else begin
         $display("%2d-th output featuremap Data ERROR!!", i); 
         $display("sfpout: %128b", sfp_out);
	   `ifdef RANDOM_INPUTS
         $display("answer: %128b", tb_checker_output[i-1]);
     `else
         $display("answer: %128b", answer);
     `endif
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

//act_ostat[k][i][j];
  $fclose(acc_file);
  `ifndef RANDOM_INPUTS
  $fclose(out_file);
  `endif
  
  ////////////////////////////////////
  /////Starting Output Stationary/////
  ////////////////////////////////////
  
  /////////////////////////////////////////////////
  $display("Implementing Output Stationary");
  /////////////////////////////////////////////////
	repeat(10) @(negedge clk);
	
	//Output Stationary loading of L0 and IFIFO
	for(tile = 0; tile<2; tile=tile+1) begin
	os_mode = 0;
	flush = 0;
	repeat(10) @(negedge clk);
	set_reset();
	os_mode = 1;
	// logic [3:0]	act_ostat	[0:15][0:8][0:7];
	for(counter=0; counter < 36; counter=counter+1)
	begin
		@(negedge clk);
		act_ostat_to_l0 = act_ostat[7+(tile*8)][counter/8][counter%8];
		for(i=6; i>=0; i=i-1)
		begin
			act_ostat_to_l0 = act_ostat_to_l0<<4 | act_ostat[i+(tile*8)][counter/8][counter%8];
			D_xmem = act_ostat_to_l0;
			l0_wr = 1;
		end
	end
	@(negedge clk);
	l0_wr = 0;
	
	// logic [3:0]	weight_ostat [0:8][0:7][0:7];	//[0:kij][0:ichannel][0:ochannel];
	for(counter=0; counter < 36; counter=counter+1)
	begin
		@(negedge clk);
		weight_ostat_to_l0 = weight_ostat[counter/8][counter%8][7];
		for(i=6; i>=0; i=i-1)
		begin
			weight_ostat_to_l0 = weight_ostat_to_l0<<16 | weight_ostat[counter/8][counter%8][i];
			D_xmem = weight_ostat_to_l0;
			ififo_wr = 1;
		end
	end
	@(negedge clk);
	ififo_wr = 0;
	
	for(counter=0; counter < 36; counter=counter+1)
	begin
		@(negedge clk);
		execute =1;
		ififo_rd = 1;
		l0_rd = 1;
	end
	@(negedge clk);
	execute =0;
	ififo_rd = 0;
	l0_rd = 0;
	
	//Split into 0-35 and 36-71 due to limits of L0 and IFIFO size
	// logic [3:0]	act_ostat	[0:15][0:8][0:7];
	for(counter=36; counter < 72; counter=counter+1)
	begin
		@(negedge clk);
		act_ostat_to_l0 = act_ostat[7+(tile*8)][counter/8][counter%8];
		for(i=6; i>=0; i=i-1)
		begin
			act_ostat_to_l0 = act_ostat_to_l0<<4 | act_ostat[i+(tile*8)][counter/8][counter%8];
			D_xmem = act_ostat_to_l0;
			l0_wr = 1;
		end
	end
	@(negedge clk);
	l0_wr = 0;
	
	
	// logic [3:0]	weight_ostat [0:8][0:7][0:7];	//[0:kij][0:ichannel][0:ochannel];
	for(counter=36; counter < 72; counter=counter+1)
	begin
		@(negedge clk);
		weight_ostat_to_l0 = weight_ostat[counter/8][counter%8][7];
		for(i=6; i>=0; i=i-1)
		begin
			weight_ostat_to_l0 = weight_ostat_to_l0<<16 | weight_ostat[counter/8][counter%8][i];
			D_xmem = weight_ostat_to_l0;
			ififo_wr = 1;
		end
	end
	@(negedge clk);
	ififo_wr = 0;
	
	
	for(counter=0; counter < 36; counter=counter+1)
	begin
		@(negedge clk);
		execute =1;
		ififo_rd = 1;
		l0_rd = 1;
	end
	@(negedge clk);
	execute =1;
	ififo_rd = 0;
	l0_rd = 0;
	@(negedge clk);
	execute =0;
	
	repeat(25) @(negedge clk);
	
	`ifndef RANDOM_INPUTS
	  out_file = $fopen("../sim/psum.txt", "r");  

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;

  $display("############ Verification Start for Output Stationary Tile %0d #############", tile); 
  //ignore lines of psum.txt thta are not computed in this tile
  for(i=0;i<tile*8;i=i+1) begin
	out_scan_file = $fscanf(out_file,"%128b", answer);
  end
  //save outputs in array
  for(i=row-1; i>=0; i=i-1) begin
    out_scan_file = $fscanf(out_file,"%128b", output_check[i]); // reading from out file to answer
	//$display("%d",answer);
  end
  `endif
 
  flush = 1;
  @(negedge clk);
  for (i=0; i<row; i=i+1) begin 

	@(negedge clk);
	`ifdef RANDOM_INPUTS
	if(sfp_out==tb_checker_output[tile*8 + 7 - i])
	`else
    if (sfp_out == output_check[i])
	`endif
		$display("%2d-th output featuremap Data matched! :D", i+tile*8); 
    else begin
        $display("%2d-th output featuremap Data ERROR!!", i+tile*8); 
        $display("sfpout: %128b", sfp_out);
	`ifdef RANDOM_INPUTS
        $display("answer: %128b", tb_checker_output[tile*8 + 7 -i]);
	`else
        $display("answer: %128b", output_check[i]);
	`endif
        error = 1;
    end
  end
  $display("############ Tile %0d computation done! ##############", tile); 

  `ifndef RANDOM_INPUTS
  $fclose(out_file);
  `endif
	
  repeat(5) @(negedge clk);
  end
  
  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 
  end
  
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
   flush_q    <= flush;
   os_mode_q  <= os_mode;
   ififo_wr_q <= ififo_wr;
   ififo_rd_q <= ififo_rd;
   l0_rd_q    <= l0_rd;
   l0_wr_q    <= l0_wr ;
   execute_q  <= execute;
   load_q     <= load;
end


endmodule




