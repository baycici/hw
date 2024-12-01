`timescale 1ns / 1ps

module mac_array_tb;

    // Parameters
    parameter bw = 4;
    parameter psum_bw = 16;
    parameter col = 8;
    parameter row = 8;
    parameter index_selection = 2;
    parameter total_activation_rows = 36;
    parameter total_weight_files = 9;

    // Clock and reset
    reg clk;
    reg reset;

    // Inputs to mac_array
    reg [row*bw-1:0] in_w;            // Activation or weight inputs
    reg [psum_bw*col-1:0] in_n;       // Partial sums
    reg [1:0] inst_w;                 // Control signals
    reg [row/index_selection-1:0] index_w; // Indexing for weight selection

    // Outputs from mac_array
    wire [psum_bw*col-1:0] out_s;     // Output partial sums
    wire [col-1:0] valid;             // Valid signals

    // Instantiate mac_array
    mac_array #(
        .bw(bw),
        .psum_bw(psum_bw),
        .col(col),
        .row(row),
        .index_selection(index_selection)
    ) uut (
        .clk(clk),
        .reset(reset),
        .out_s(out_s),
        .in_w(in_w),
        .in_n(in_n),
        .inst_w(inst_w),
        .valid(valid),
        .index_w(index_w)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // Clock period of 10 ns

    // File handlers
    integer act_file;
    integer weight_file[0:total_weight_files-1];
    integer psum_file[0:total_weight_files-1];

    // Variables to store data from files
    reg [31:0] activation_data[0:total_activation_rows-1]; // 36 rows of 32 bits
    reg [31:0] weight_data[0:total_weight_files-1][0:7];   // 9 files, each with 8 rows
    reg [psum_bw*col-1:0] psum_expected[0:total_weight_files-1]; // Expected partial sums
    reg [psum_bw-1:0] psum_actual[col-1:0];                // Actual partial sums for comparison

    integer i, j, k;
    integer scan_status;

    initial begin
        $dumpfile("mac_array_tb.vcd");
        $dumpvars(0, mac_array_tb);

        // Initialize inputs
        clk = 0;
        reset = 1;
        in_w = 0;
        in_n = 0;
        inst_w = 0;
        index_w = 0;

        // Wait for reset to be released
        #20 reset = 0;

        // Open activation file
        act_file = $fopen("activation.txt", "r");
        if (act_file == 0) begin
            $display("Error: Could not open activation.txt");
            $finish;
        end

        // Open weight and psum files
        for (i = 0; i < total_weight_files; i = i + 1) begin
            weight_file[i] = $fopen($sformatf("weight%d.txt", i), "r");
            if (weight_file[i] == 0) begin
                $display("Error: Could not open weight%d.txt", i);
                $finish;
            end

            psum_file[i] = $fopen($sformatf("psum%d.txt", i), "r");
            if (psum_file[i] == 0) begin
                $display("Error: Could not open psum%d.txt", i);
                $finish;
            end
        end

        // Read activation data
        for (i = 0; i < total_activation_rows; i = i + 1) begin
            scan_status = $fscanf(act_file, "%b\n", activation_data[i]);
            if (scan_status != 1) begin
                $display("Error: Failed to read activation.txt at line %d", i + 1);
                $finish;
            end
        end
        $fclose(act_file);

        // Read weight data
        for (i = 0; i < total_weight_files; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                scan_status = $fscanf(weight_file[i], "%b\n", weight_data[i][j]);
                if (scan_status != 1) begin
                    $display("Error: Failed to read weight%d.txt at line %d", i, j + 1);
                    $finish;
                end
            end
            $fclose(weight_file[i]);
        end

        // Read expected psum data
        for (i = 0; i < total_weight_files; i = i + 1) begin
            scan_status = $fscanf(psum_file[i], "%h\n", psum_expected[i]);
            if (scan_status != 1) begin
                $display("Error: Failed to read psum%d.txt", i);
                $finish;
            end
            $fclose(psum_file[i]);
        end

        // ---------------------------------------------------------
        // Phase 1: Load weights into the mac_array
        // ---------------------------------------------------------
        $display("---------- Loading Weights into MAC Array ----------");

        inst_w = 2'b01; // Instruction to load weights

        for (i = 0; i < row / index_selection; i = i + 1) begin
            // Prepare in_w for current index selection
            // Concatenate weights for index_selection rows
            in_w = 0;
            for (j = 0; j < index_selection; j = j + 1) begin
                k = i * index_selection + j; // Row index
                in_w = {in_w[(row - (k + 1)) * bw - 1:0], weight_data[k][0][bw * col - 1:0]};
            end
            // Set index_w
            index_w = i % 2; // Adjust as per your indexing requirement

            #10; // Wait for inputs to be registered at the rising edge
        end

        // ---------------------------------------------------------
        // Phase 2: Perform MAC operations with activations
        // ---------------------------------------------------------
        $display("---------- Performing MAC Operations ----------");

        inst_w = 2'b10; // Instruction to execute

        for (i = 0; i < total_activation_rows; i = i + 1) begin
            // Provide activation inputs
            in_w = activation_data[i];

            // Provide partial sums if needed (set to zero in this example)
            in_n = 0;

            // Set index_w as needed (adjust based on your design)
            index_w = i % 2; // Example indexing

            #10; // Wait for inputs to be registered at the rising edge
        end

        // Wait for computation to complete
        #100;

        // ---------------------------------------------------------
        // Phase 3: Compare outputs with expected psum values
        // ---------------------------------------------------------
        $display("---------- Comparing Outputs with Expected PSUMs ----------");

        // Extract actual psum outputs
        for (i = 0; i < col; i = i + 1) begin
            psum_actual[i] = out_s[psum_bw * (i + 1) - 1 -: psum_bw];
        end

        // Compare with expected values
        for (i = 0; i < col; i = i + 1) begin
            if (psum_actual[i] !== psum_expected[i][psum_bw * (i + 1) - 1 -: psum_bw]) begin
                $display("Mismatch at Column %0d: Expected %h, Got %h", i, psum_expected[i][psum_bw * (i + 1) - 1 -: psum_bw], psum_actual[i]);
            end else begin
                $display("Column %0d: PASSED (Value: %h)", i, psum_actual[i]);
            end
        end

        $display("---------- Test Completed ----------");
        $finish;
    end

endmodule
