// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps

`include "core.sv"
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
integer t, i, j, k, kij;
integer error;

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

logic [3:0]	weight_array [0:row-1][0:col-1];
logic [3:0]	act_array [0:35][0:7];
logic [3:0]	act_ostat	[0:15][0:8][0:7];
logic [3:0]	weight_ostat [0:8][0:7][0:7];	//[0:kij][0:ichannel][0:ochannel];
int row_i;
int col_i;
int row_j;
int col_j;
int counter;
int temp[8][8];
logic [4*8-1:0]	act_ostat_to_l0;
logic [16*8-1:0]	weight_ostat_to_l0;
logic[127:0] output_check[2*row];

int counter_act_ostat [0:15];
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
		x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
		for(int col_i=0 ; col_i<col; col_i++) begin
			act_array[t][col_i] = D_xmem[4*col_i+:4];
		end
  end
  $fclose(x_file);
  /////////////////////////////////////////////////

//Populating the act_ostat
for(int i=0 ;i <16; i++)
	counter_act_ostat[i] = 0;

for(int i=0; i < 36 ; i++)
begin
	row_i = i /6;
	col_i = i %6;
	for (int j = 0; j < 16; j++)
	begin
		row_j = j /4;
		col_j = j %4;
		if( (row_i>=row_j && row_i<= (row_j+2)) &&
			(col_i>=col_j && col_i<= (col_j+2)) )
		begin
			for(int k=0 ; k<8; k++)
			begin
				act_ostat[j][counter_act_ostat[j]][k] = act_array[i][k];
				//if(j==0 && k==1)
					//$display("i:%d, row_i:%d, col_i:%d", i, row_i, col_i);;
			end
			counter_act_ostat[j]++;
		end
	end
end

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
	//row_i = iterates over different output channels 
	//t = iterates over different input channels
	//kij - iterates over different kij(0,9) 
    for (t=0; t<col; t=t+1) begin  
			w_scan_file = $fscanf(w_file,"%32b", D_xmem); 
			for(int row_i=0 ; row_i<row; row_i++) begin
				weight_array[t][row_i] = D_xmem[4*row_i+:4];
				weight_ostat[kij][row_i][t] = weight_array[t][row_i]; 
			end	
			//if(kij==0)
				//$display("kij=%d, t=%d, weight_ostat=%b", kij, t, weight_ostat[kij][][]);
    end

    /////////////////////////////////////
		$fclose(w_file);
  end  // end of kij loop
  
  ////////////////////////////////////
  /////Starting Output Stationary/////
  ////////////////////////////////////
  
  /////////////////////////////////////////////////
  $display("Implementing Output Stationary");
  /////////////////////////////////////////////////
	repeat(10) @(negedge clk);
	
	counter = 0 ;
	for(int k1=0; k1<8; k1++) begin
		for(int k2=0; k2<8; k2++) begin
			for  (int i=0; i<9; i++)
			begin
				for (int j=0; j<8; j++)
				begin
					temp[k1][k2] = $signed(temp[k1][k2]) + $signed({1'b0,act_ostat[k1][i][j]})* $signed(weight_ostat[i][j][k2]);
					counter++;
					@(negedge clk);
				end
			end
		end
	end
	
	//Output Stationary loading of L0 and IFIFO
	os_mode = 1;
	repeat(10) @(negedge clk);
	set_reset();
	// logic [3:0]	act_ostat	[0:15][0:8][0:7];
	for(counter=0; counter < 36; counter++)
	begin
		@(negedge clk);
		act_ostat_to_l0 = act_ostat[7][counter/8][counter%8];
		for(int i=6; i>=0; i--)
		begin
			act_ostat_to_l0 = act_ostat_to_l0<<4 | act_ostat[i][counter/8][counter%8];
			D_xmem = act_ostat_to_l0;
			l0_wr = 1;
		end
	end
	@(negedge clk);
	l0_wr = 0;
	
	// logic [3:0]	weight_ostat [0:8][0:7][0:7];	//[0:kij][0:ichannel][0:ochannel];
	for(counter=0; counter < 36; counter++)
	begin
		@(negedge clk);
		weight_ostat_to_l0 = weight_ostat[counter/8][counter%8][7];
		for(int i=6; i>=0; i--)
		begin
			weight_ostat_to_l0 = weight_ostat_to_l0<<16 | weight_ostat[counter/8][counter%8][i];
			D_xmem = weight_ostat_to_l0;
			ififo_wr = 1;
		end
	end
	@(negedge clk);
	ififo_wr = 0;
	
	for(counter=0; counter < 36; counter++)
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
	for(counter=36; counter < 72; counter++)
	begin
		@(negedge clk);
		act_ostat_to_l0 = act_ostat[7][counter/8][counter%8];
		for(int i=6; i>=0; i--)
		begin
			act_ostat_to_l0 = act_ostat_to_l0<<4 | act_ostat[i][counter/8][counter%8];
			D_xmem = act_ostat_to_l0;
			l0_wr = 1;
		end
	end
	@(negedge clk);
	l0_wr = 0;
	
	
	// logic [3:0]	weight_ostat [0:8][0:7][0:7];	//[0:kij][0:ichannel][0:ochannel];
	for(counter=36; counter < 72; counter++)
	begin
		@(negedge clk);
		weight_ostat_to_l0 = weight_ostat[counter/8][counter%8][7];
		for(int i=6; i>=0; i--)
		begin
			weight_ostat_to_l0 = weight_ostat_to_l0<<16 | weight_ostat[counter/8][counter%8][i];
			D_xmem = weight_ostat_to_l0;
			ififo_wr = 1;
		end
	end
	@(negedge clk);
	ififo_wr = 0;
	
	
	for(counter=0; counter < 36; counter++)
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
	
	  out_file = $fopen("../sim/psum.txt", "r");  

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;

  $display("############ Verification Start for Output Stationary #############"); 

  for(i=row-1; i>=0; i--) begin
    out_scan_file = $fscanf(out_file,"%128b", output_check[i]); // reading from out file to answer
	//$display("%d",answer);
  end

  flush = 1;
  @(negedge clk);
  for (i=0; i<row; i=i+1) begin 

	@(negedge clk);
    if (sfp_out == output_check[i])
		$display("%2d-th output featuremap Data matched! :D", i); 
    else begin
        $display("%2d-th output featuremap Data ERROR!!", i); 
        $display("sfpout: %128b", sfp_out);
        $display("answer: %128b", output_check[i]);
        error = 1;
    end
  end

  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 
  end

  $fclose(out_file);
	
  repeat(5) @(negedge clk);
	
  #10 $stop;
  
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




