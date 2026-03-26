// Auto-generated firmware ROM from main.bin
// Contains 18 words (72 bytes)

module firmware_rom (
    input wire [31:0] addr,
    output reg [31:0] data
);

    wire [4:0] word_addr = addr[6:2];

    always @(*) begin
        data = 32'h0000_0013; // nop

        case (word_addr)
            5'd0:  data = 32'h40000537;
            5'd1:  data = 32'h000005b7;
            5'd2:  data = 32'h03858593;
            5'd3:  data = 32'h00f00613;
            5'd4:  data = 32'h00000693;
            5'd5:  data = 32'h00d58733;
            5'd6:  data = 32'h00074703;
            5'd7:  data = 32'h00452783;
            5'd8:  data = 32'h0017f793;
            5'd9:  data = 32'hfe078ce3;
            5'd10:  data = 32'h00168693;
            5'd11:  data = 32'h00e52223;
            5'd12:  data = 32'hfec680e3;
            5'd13:  data = 32'hfe1ff06f;
            5'd14:  data = 32'h6c6c6548;
            5'd15:  data = 32'h57202c6f;
            5'd16:  data = 32'h646c726f;
            5'd17:  data = 32'h000a0d21;

            default: data = 32'h0000_0013;
        endcase
    end

endmodule
