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
wire [3:0] data_wstrb;
wire [31:0] data_rdata;
wire [31:0] data_rom_rdata;

reg [31:0] gpio_reg;
reg [7:0] uart_wdata;
wire uart_tx_ready;
wire gpio_sel = (data_addr[31:2] == GPIO_ADDR[31:2]);
wire uart_sel = (data_addr[31:2] == UART_ADDR[31:2]);
wire uart_tx_valid = data_we && uart_sel && (|data_wstrb);

assign gpio_out = gpio_reg;
assign data_rdata = (data_re && gpio_sel) ? gpio_reg :
                    (data_re && uart_sel) ? {31'd0, uart_tx_ready} :
                    (data_re && (data_addr[31:7] == 25'd0)) ? data_rom_rdata :
                    32'd0;

always @(posedge clk) begin
    if (!&reset_cnt)
        reset_cnt <= reset_cnt + 16'd1;

    if (reset) begin
        gpio_reg <= 32'd0;
        uart_wdata <= 8'd0;
    end
    else begin
        if (data_we && gpio_sel) begin
            if (data_wstrb[0]) gpio_reg[7:0]   <= data_wdata[7:0];
            if (data_wstrb[1]) gpio_reg[15:8]  <= data_wdata[15:8];
            if (data_wstrb[2]) gpio_reg[23:16] <= data_wdata[23:16];
            if (data_wstrb[3]) gpio_reg[31:24] <= data_wdata[31:24];
        end

        if (data_we && uart_sel && (|data_wstrb)) begin
            case (data_addr[1:0])
                2'b00: uart_wdata <= data_wdata[7:0];
                2'b01: uart_wdata <= data_wdata[15:8];
                2'b10: uart_wdata <= data_wdata[23:16];
                default: uart_wdata <= data_wdata[31:24];
            endcase
        end
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
    .data_wstrb(data_wstrb),
    .data_rdata(data_rdata)
);

firmware_rom u_firmware_rom (
    .addr(instr_addr),
    .data(instr_rdata)
);

firmware_rom u_firmware_rom_data (
    .addr(data_addr),
    .data(data_rom_rdata)
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
