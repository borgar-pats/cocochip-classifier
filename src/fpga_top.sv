module fpga_top (
    input  logic        CLOCK_50,       // 50MHz clock
    input  logic [2:0]  KEY,            // KEY[0]=reset, KEY[1]=start, KEY[2]=data_valid
    input  logic [7:0]  SW,             // 8 switches for ADC data
    output logic [9:0]  LEDR            // LEDR[0:2] for classification, LEDR[8:9] for channel select
);

    // Internal signals
    logic reset_n;
    logic start;
    logic adc_data_valid;
    logic [1:0] adc_channel_sel;
    
    // Debounced buttons
    logic key0_debounced, key1_debounced, key2_debounced;
    
    // Edge detection for buttons
    logic key0_prev, key1_prev, key2_prev;
    logic reset_pulse, start_pulse, data_valid_pulse;

    // Debounce all buttons
    debouncer debounce_key0 (
        .clk(CLOCK_50),
        .reset_n(1'b1),
        .button_in(KEY[0]),
        .button_out(key0_debounced)
    );

    debouncer debounce_key1 (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .button_in(KEY[1]),
        .button_out(key1_debounced)
    );

    debouncer debounce_key2 (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .button_in(KEY[2]),
        .button_out(key2_debounced)
    );

    // Edge detection for reset button (KEY[0])
    always_ff @(posedge CLOCK_50) begin
        key0_prev <= key0_debounced;
    end

    // Generate reset pulse on rising edge (button release)
    assign reset_pulse = !key0_prev && key0_debounced;

    // Reset signal - active when KEY[0] is pressed then released
    logic reset_n_reg;
    always_ff @(posedge CLOCK_50) begin
        if (reset_pulse) begin
            reset_n_reg <= 1'b0;  // Activate reset
        end else begin
            reset_n_reg <= 1'b1;  // Normal operation
        end
    end

    assign reset_n = reset_n_reg;

    // Edge detection for start button (KEY[1])
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            key1_prev <= 1'b1;
        end else begin
            key1_prev <= key1_debounced;
        end
    end

    // Generate start pulse on falling edge (button press)
    assign start_pulse = key1_prev && !key1_debounced;

    // Start signal latch
    logic start_latched;
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            start_latched <= 1'b0;
        end else if (start_pulse) begin
            start_latched <= 1'b1;
        end else begin
            start_latched <= 1'b0;
        end
    end

    // Edge detection for data valid button (KEY[2])
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            key2_prev <= 1'b1;
        end else begin
            key2_prev <= key2_debounced;
        end
    end

    // Generate data valid pulse on falling edge (button press)
    assign data_valid_pulse = key2_prev && !key2_debounced;

    // Data valid signal
    logic data_valid_latched;
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            data_valid_latched <= 1'b0;
        end else if (data_valid_pulse) begin
            data_valid_latched <= 1'b1;
        end else begin
            data_valid_latched <= 1'b0;
        end
    end

    // Internal signal for classifier output
    logic [2:0] classification_result;
    logic [2:0] classification_held;

    // Instantiate the cocochip classifier
    cocochip_classifier classifier (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .start(start_latched),
        .adc_data(SW[7:0]),
        .adc_data_valid(data_valid_latched),
        .adc_channel_sel(adc_channel_sel),
        .ledr(classification_result)
    );

    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            classification_held <= 3'b000;
        end else if (classification_result != 3'b000) begin
            classification_held <= classification_result;
        end
    end

    // LED Output Assignments
    always_comb begin
        LEDR = 10'b0000000000;
        if (reset_n) begin
            LEDR[9:8] = adc_channel_sel;  
            LEDR[2:0] = classification_held;
        end
    end

endmodule