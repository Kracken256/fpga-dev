module top (
    input wire clk50,
    output wire led0,
    output wire led1
);

wire [31:0] gpio_out;

riscv_soc u_riscv_soc (
    .clk(clk50),
    .gpio_out(gpio_out)
);

assign led0 = gpio_out[0];
assign led1 = ~gpio_out[0];

endmodule
