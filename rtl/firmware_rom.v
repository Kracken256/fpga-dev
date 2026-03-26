// Auto-generated firmware ROM from main.bin
// Contains 14 words (56 bytes)

module firmware_rom (
    input wire [31:0] addr,
    output reg [31:0] data
);

    wire [4:0] word_addr = addr[6:2];

    always @(*) begin
        data = 32'h0000_0013; // nop

        case (word_addr)
            5'd0:  data = 32'h00000537;
            5'd1:  data = 32'h02850513;
            5'd2:  data = 32'h400005b7;
            5'd3:  data = 32'h00e50613;
            5'd4:  data = 32'h00050693;
            5'd5:  data = 32'h0006c703;
            5'd6:  data = 32'h00168693;
            5'd7:  data = 32'h00e5a223;
            5'd8:  data = 32'hfec69ae3;
            5'd9:  data = 32'hfedff06f;
            5'd10:  data = 32'h6c6c6548;
            5'd11:  data = 32'h57202c6f;
            5'd12:  data = 32'h646c726f;
            5'd13:  data = 32'h00000a21;

            default: data = 32'h0000_0013;
        endcase
    end

endmodule
