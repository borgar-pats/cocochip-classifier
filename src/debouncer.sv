module debouncer (
    input  logic clk,           // 50MHz clock
    input  logic reset_n,       // Active-low reset
    input  logic button_in,     // Raw button input (active-low on DE1-SoC)
    output logic button_out     // Debounced button output
);

    // Debounce counter (10ms at 50MHz = 500,000 cycles)
    localparam DEBOUNCE_COUNT = 1000;  // Reduced for efficiency
    logic [9:0] counter;
    logic button_sync;

    // Synchronize input
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            button_sync <= 1'b1;
        end else begin
            button_sync <= button_in;
        end
    end

    // Debounce logic
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 10'b0;
            button_out <= 1'b1;
        end else begin
            if (button_sync != button_out) begin
                if (counter == DEBOUNCE_COUNT) begin
                    button_out <= button_sync;
                    counter <= 10'b0;
                end else begin
                    counter <= counter + 1;
                end
            end else begin
                counter <= 10'b0;
            end
        end
    end

endmodule