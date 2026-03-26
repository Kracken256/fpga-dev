module riscv_soc (
    input wire clk,
    output wire [31:0] gpio_out,
    output wire uart_tx
);

localparam [31:0] GPIO_ADDR = 32'h4000_0000;
localparam [31:0] UART_ADDR = 32'h4000_0004;

reg [15:0] reset_cnt = 16'd0;
wire reset = ~&reset_cnt;

wire mem_re;
wire mem_we;
wire [31:0] mem_addr;
wire [31:0] mem_wdata;
wire [3:0] mem_wstrb;
wire [31:0] mem_rdata;
wire [31:0] rom_rdata;

reg [31:0] gpio_reg;
reg [7:0] uart_wdata;
wire uart_tx_ready;
wire gpio_sel = (mem_addr[31:2] == GPIO_ADDR[31:2]);
wire uart_sel = (mem_addr[31:2] == UART_ADDR[31:2]);
wire uart_tx_valid = mem_we && uart_sel && (|mem_wstrb);

assign gpio_out = gpio_reg;
assign mem_rdata = (mem_re && gpio_sel) ? gpio_reg :
                   (mem_re && uart_sel) ? {31'd0, uart_tx_ready} :
                   (mem_re && (mem_addr[31:7] == 25'd0)) ? rom_rdata :
                   32'd0;

always @(posedge clk) begin
    if (!&reset_cnt)
        reset_cnt <= reset_cnt + 16'd1;

    if (reset) begin
        gpio_reg <= 32'd0;
        uart_wdata <= 8'd0;
    end
    else begin
        if (mem_we && gpio_sel) begin
            if (mem_wstrb[0]) gpio_reg[7:0]   <= mem_wdata[7:0];
            if (mem_wstrb[1]) gpio_reg[15:8]  <= mem_wdata[15:8];
            if (mem_wstrb[2]) gpio_reg[23:16] <= mem_wdata[23:16];
            if (mem_wstrb[3]) gpio_reg[31:24] <= mem_wdata[31:24];
        end

        if (mem_we && uart_sel && (|mem_wstrb)) begin
            case (mem_addr[1:0])
                2'b00: uart_wdata <= mem_wdata[7:0];
                2'b01: uart_wdata <= mem_wdata[15:8];
                2'b10: uart_wdata <= mem_wdata[23:16];
                default: uart_wdata <= mem_wdata[31:24];
            endcase
        end
    end
end

riscv_core u_riscv_core (
    .clk(clk),
    .reset(reset),
    .mem_re(mem_re),
    .mem_we(mem_we),
    .mem_addr(mem_addr),
    .mem_wdata(mem_wdata),
    .mem_wstrb(mem_wstrb),
    .mem_rdata(mem_rdata)
);

firmware_rom u_firmware_rom (
    .addr(mem_addr),
    .data(rom_rdata)
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
