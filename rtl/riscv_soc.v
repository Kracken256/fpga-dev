module riscv_soc (
    input wire clk,
    output wire [31:0] gpio_out,
    output wire uart_tx
);

localparam [31:0] GPIO_ADDR = 32'h4000_0000;
localparam [31:0] UART_ADDR = 32'h4000_0004;

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
reg [7:0] uart_wdata;
wire uart_tx_ready;

assign gpio_out = gpio_reg;
assign data_rdata = (data_re && (data_addr == GPIO_ADDR)) ? gpio_reg :
                    (data_re && (data_addr == UART_ADDR)) ? {31'd0, uart_tx_ready} :
                    32'd0;

wire uart_tx_valid = data_we && (data_addr == UART_ADDR);

always @(posedge clk) begin
    if (!&reset_cnt)
        reset_cnt <= reset_cnt + 16'd1;

    if (reset) begin
        gpio_reg <= 32'd0;
        uart_wdata <= 8'd0;
    end
    else begin
        if (data_we && (data_addr == GPIO_ADDR))
            gpio_reg <= data_wdata;
        if (data_we && (data_addr == UART_ADDR))
            uart_wdata <= data_wdata[7:0];
    end
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

uart_tx u_uart_tx (
    .clk(clk),
    .reset(reset),
    .data_in(uart_wdata),
    .tx_valid(uart_tx_valid),
    .tx_ready(uart_tx_ready),
    .tx(uart_tx)
);

endmodule
