module top (
    input wire clk50,
    output wire led0,
    output wire led1
);

// Tang Primer 25K provides a 50 MHz oscillator on the primary clock pin.
// Keep this in one place so all timing math is easy to verify.
localparam integer CLK_HZ = 50_000_000;

// Toggle once every 5 seconds.
// Note: this is toggle time, so one full on->off->on cycle is 10 seconds.
localparam integer TOGGLE_TICKS = 5 * CLK_HZ;

// 250,000,000 requires 28 bits (2^28 = 268,435,456).
// Counter runs from 0 to TOGGLE_TICKS-1 then wraps.
reg [27:0] tick_counter = 28'd0;

// Shared LED state so led1 can simply invert led0.
reg led_state = 1'b0;

// Synchronous tick counter and LED toggle logic.
// This style is friendly to synthesis and timing analysis.
always @(posedge clk50) begin
    if (tick_counter == TOGGLE_TICKS - 1) begin
        // Reached 5-second boundary: wrap counter and toggle output state.
        tick_counter <= 28'd0;
        led_state <= ~led_state;
    end else begin
        // Keep counting toward the next toggle event.
        tick_counter <= tick_counter + 28'd1;
    end
end

// Drive both LEDs from one state bit to make polarity obvious.
assign led0 = led_state;
assign led1 = ~led_state;

endmodule
