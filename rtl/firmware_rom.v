module firmware_rom (
    input wire [31:0] addr,
    output reg [31:0] data
);

wire [4:0] word_addr = addr[6:2];

always @(*) begin
    data = 32'h0000_0013; // nop

    case (word_addr)
        5'd0: data = 32'h4000_01B7; // lui  x3, 0x40000
        5'd1: data = 32'h0000_0113; // addi x2, x0, 0
        5'd2: data = 32'h0400_00B7; // lui  x1, 0x04000
        5'd3: data = 32'hFFF0_8093; // addi x1, x1, -1
        5'd4: data = 32'hFE00_9EE3; // bne  x1, x0, -4
        5'd5: data = 32'h0021_A023; // sw   x2, 0(x3)
        5'd6: data = 32'h0011_0113; // addi x2, x2, 1
        5'd7: data = 32'hFEDF_F06F; // jal  x0, -20
        default: data = 32'h0000_0013;
    endcase
end

endmodule
