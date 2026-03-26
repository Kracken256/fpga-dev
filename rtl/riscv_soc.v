module riscv_soc (
    input wire clk,
    output wire [31:0] gpio_out
);

localparam [31:0] GPIO_ADDR = 32'h4000_0000;

reg [15:0] reset_cnt = 16'd0;
wire reset = ~&reset_cnt;

wire [31:0] instr_addr;
wire [31:0] instr_rdata;
wire data_re;
wire data_we;
wire [31:0] data_addr;
wire [31:0] data_wdata;
wire [31:0] data_rdata;

reg [31:0] gpio_reg;

assign gpio_out = gpio_reg;
assign data_rdata = (data_re && (data_addr == GPIO_ADDR)) ? gpio_reg : 32'd0;

always @(posedge clk) begin
    if (!&reset_cnt)
        reset_cnt <= reset_cnt + 16'd1;

    if (reset)
        gpio_reg <= 32'd0;
    else if (data_we && (data_addr == GPIO_ADDR))
        gpio_reg <= data_wdata;
end

riscv_core u_riscv_core (
    .clk(clk),
    .reset(reset),
    .instr_addr(instr_addr),
    .instr_rdata(instr_rdata),
    .data_re(data_re),
    .data_we(data_we),
    .data_addr(data_addr),
    .data_wdata(data_wdata),
    .data_rdata(data_rdata)
);

firmware_rom u_firmware_rom (
    .addr(instr_addr),
    .data(instr_rdata)
);

endmodule
