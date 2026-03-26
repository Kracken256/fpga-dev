// Simple UART transmitter for 115200 baud @ 50 MHz clock
// 50_000_000 / 115_200 = 434 clock cycles per bit

module uart_tx (
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire tx_valid,
    output reg tx_ready,
    output reg tx
);

    // Baud rate: divisor = clock_freq / baud_rate
    localparam DIVISOR = 434;
    localparam DIVISOR_WIDTH = 9;

    reg [3:0] bit_cnt;
    reg [DIVISOR_WIDTH-1:0] clk_cnt;
    reg [9:0] shift_reg;  // 1 start + 8 data + 1 stop

    always @(posedge clk) begin
        if (reset) begin
            tx_ready <= 1'b1;
            tx <= 1'b1;
            bit_cnt <= 4'd0;
            clk_cnt <= {DIVISOR_WIDTH{1'b0}};
            shift_reg <= 10'b11_1111_1111;
        end else if (tx_ready && tx_valid) begin
            // Start transmission: load shift register with start bit (0) + 8 data bits + stop bit (1)
            shift_reg <= {1'b1, data_in, 1'b0};
            bit_cnt <= 4'd10;
            clk_cnt <= {DIVISOR_WIDTH{1'b0}};
            tx_ready <= 1'b0;
        end else if (!tx_ready) begin
            // Transmission in progress
            if (clk_cnt == (DIVISOR - 1)) begin
                clk_cnt <= {DIVISOR_WIDTH{1'b0}};
                shift_reg <= {1'b1, shift_reg[9:1]};
                tx <= shift_reg[0];
                bit_cnt <= bit_cnt - 1'b1;
                if (bit_cnt == 1) begin
                    tx_ready <= 1'b1;
                    tx <= 1'b1;
                end
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end
        end
    end

endmodule
