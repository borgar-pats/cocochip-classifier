module cocochip_classifier (
    input  logic        clk,            // 50MHz system clock
    input  logic        reset_n,        // Active-low reset
    input  logic        start,          // Start classification process
    input  logic [7:0]  adc_data,       // SINGLE ADC data bus (8 bits)
    input  logic        adc_data_valid, // ADC data ready signal
    output logic [1:0]  adc_channel_sel, // MUX channel select (00=high, 01=mid, 10=low)
    output logic [2:0]  ledr            // LED outputs: [Mala-Uhog, Malakanin, Malatenga]
);

    // Synchronize ADC inputs
    logic [7:0] adc_data_sync;
    logic adc_data_valid_sync;
    
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            adc_data_sync <= 8'b0;
            adc_data_valid_sync <= 1'b0;
        end else begin
            adc_data_sync <= adc_data;
            adc_data_valid_sync <= adc_data_valid;
        end
    end

    // Storage for the three peak values
    logic [7:0] peak_high, peak_mid, peak_low;
    logic [1:0] current_channel;
    logic sampling_done;
    
    // State machine
    typedef enum logic [1:0] {
        IDLE,
        SAMPLING,
        CLASSIFY,
        DISPLAY
    } state_t;
    
    state_t current_state, next_state;
    
    // State register
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Next state logic
    always_comb begin
        case (current_state)
            IDLE:     next_state = start ? SAMPLING : IDLE;
            SAMPLING: next_state = (current_channel == 2'b10 && adc_data_valid_sync) ? CLASSIFY : SAMPLING;
            CLASSIFY: next_state = DISPLAY;
            DISPLAY:  next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end
    
    // Sampling control logic
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            peak_high <= 8'b0;
            peak_mid <= 8'b0;
            peak_low <= 8'b0;
            current_channel <= 2'b00;
            adc_channel_sel <= 2'b00;
            sampling_done <= 1'b0;
        end else begin
            case (current_state)
                IDLE: begin
                    current_channel <= 2'b00;
                    adc_channel_sel <= 2'b00;
                    sampling_done <= 1'b0;
                end
                
                SAMPLING: begin
                    if (adc_data_valid_sync) begin
                        case (current_channel)
                            2'b00: peak_high <= adc_data_sync;
                            2'b01: peak_mid <= adc_data_sync;
                            2'b10: peak_low <= adc_data_sync;
                        endcase
                        
                        if (current_channel == 2'b10) begin
                            sampling_done <= 1'b1;
                            current_channel <= 2'b00;
                        end else begin
                            current_channel <= current_channel + 1;
                        end
                        
                        adc_channel_sel <= current_channel + 1;
                    end
                end
                
                default: ;
            endcase
        end
    end
    
    // Classification logic
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ledr <= 3'b000;
        end else begin
            case (current_state)
                CLASSIFY: begin
                    if ((peak_high >= peak_mid) && (peak_high >= peak_low)) begin
                        ledr <= 3'b001;
                    end else if ((peak_mid >= peak_high) && (peak_mid >= peak_low)) begin
                        ledr <= 3'b010;
                    end else begin
                        ledr <= 3'b100;
                    end
                end
                
                IDLE: begin
                    ledr <= 3'b000;
                end
                
                default: ;
            endcase
        end
    end

endmodule