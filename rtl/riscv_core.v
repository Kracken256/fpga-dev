module riscv_core (
    input wire clk,
    input wire reset,
    output wire [31:0] instr_addr,
    input wire [31:0] instr_rdata,
    output reg data_re,
    output reg data_we,
    output reg [31:0] data_addr,
    output reg [31:0] data_wdata,
    output reg [3:0] data_wstrb,
    input wire [31:0] data_rdata
);

reg [31:0] regs [0:31];
reg [31:0] pc;

wire [31:0] instr = instr_rdata;
assign instr_addr = pc;

wire [6:0] opcode = instr[6:0];
wire [4:0] rd = instr[11:7];
wire [2:0] funct3 = instr[14:12];
wire [4:0] rs1 = instr[19:15];
wire [4:0] rs2 = instr[24:20];
wire [6:0] funct7 = instr[31:25];

wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
wire [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
wire [31:0] imm_u = {instr[31:12], 12'b0};
wire [31:0] imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

wire [31:0] rs1_val = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
wire [31:0] rs2_val = (rs2 == 5'd0) ? 32'd0 : regs[rs2];
wire signed [31:0] rs1_s = rs1_val;
wire signed [31:0] rs2_s = rs2_val;

wire [31:0] store_addr = rs1_val + imm_s;
wire [31:0] load_addr = rs1_val + imm_i;
wire [7:0] load_byte = (load_addr[1:0] == 2'b00) ? data_rdata[7:0] :
                       (load_addr[1:0] == 2'b01) ? data_rdata[15:8] :
                       (load_addr[1:0] == 2'b10) ? data_rdata[23:16] :
                                                   data_rdata[31:24];
wire [15:0] load_half = load_addr[1] ? data_rdata[31:16] : data_rdata[15:0];

reg [31:0] next_pc;
reg [31:0] wb_data;
reg wb_en;
reg branch_taken;

integer i;

always @(*) begin
    next_pc = pc + 32'd4;
    wb_data = 32'd0;
    wb_en = 1'b0;
    branch_taken = 1'b0;

    data_re = 1'b0;
    data_we = 1'b0;
    data_addr = 32'd0;
    data_wdata = 32'd0;
    data_wstrb = 4'b0000;

    case (opcode)
        7'b0110111: begin // LUI
            wb_en = 1'b1;
            wb_data = imm_u;
        end

        7'b0010111: begin // AUIPC
            wb_en = 1'b1;
            wb_data = pc + imm_u;
        end

        7'b1101111: begin // JAL
            wb_en = (rd != 5'd0);
            wb_data = pc + 32'd4;
            next_pc = pc + imm_j;
        end

        7'b1100111: begin // JALR
            wb_en = (rd != 5'd0);
            wb_data = pc + 32'd4;
            next_pc = (rs1_val + imm_i) & 32'hFFFF_FFFE;
        end

        7'b1100011: begin // Branches
            case (funct3)
                3'b000: branch_taken = (rs1_val == rs2_val); // BEQ
                3'b001: branch_taken = (rs1_val != rs2_val); // BNE
                3'b100: branch_taken = (rs1_s < rs2_s);      // BLT
                3'b101: branch_taken = (rs1_s >= rs2_s);     // BGE
                3'b110: branch_taken = (rs1_val < rs2_val);  // BLTU
                3'b111: branch_taken = (rs1_val >= rs2_val); // BGEU
                default: branch_taken = 1'b0;
            endcase
            if (branch_taken)
                next_pc = pc + imm_b;
        end

        7'b0000011: begin // Loads
            data_re = 1'b1;
            data_addr = load_addr;
            wb_en = (rd != 5'd0);
            case (funct3)
                3'b010: wb_data = data_rdata;                      // LW
                3'b000: wb_data = {{24{load_byte[7]}}, load_byte}; // LB
                3'b100: wb_data = {24'd0, load_byte};              // LBU
                3'b001: wb_data = {{16{load_half[15]}}, load_half}; // LH
                3'b101: wb_data = {16'd0, load_half};              // LHU
                default: begin
                    data_re = 1'b0;
                    wb_en = 1'b0;
                    wb_data = 32'd0;
                end
            endcase
        end

        7'b0100011: begin // Stores
            data_we = 1'b1;
            data_addr = store_addr;
            case (funct3)
                3'b000: begin // SB
                    data_wdata = {4{rs2_val[7:0]}};
                    data_wstrb = 4'b0001 << store_addr[1:0];
                end
                3'b001: begin // SH
                    data_wdata = {2{rs2_val[15:0]}};
                    data_wstrb = store_addr[1] ? 4'b1100 : 4'b0011;
                end
                3'b010: begin // SW
                    data_wdata = rs2_val;
                    data_wstrb = 4'b1111;
                end
                default: begin
                    data_we = 1'b0;
                    data_wdata = 32'd0;
                    data_wstrb = 4'b0000;
                end
            endcase
        end

        7'b0010011: begin // Immediate ALU ops
            wb_en = (rd != 5'd0);
            case (funct3)
                3'b000: wb_data = rs1_val + imm_i; // ADDI
                3'b010: wb_data = (rs1_s < $signed(imm_i)) ? 32'd1 : 32'd0; // SLTI
                3'b011: wb_data = (rs1_val < imm_i) ? 32'd1 : 32'd0; // SLTIU
                3'b100: wb_data = rs1_val ^ imm_i; // XORI
                3'b110: wb_data = rs1_val | imm_i; // ORI
                3'b111: wb_data = rs1_val & imm_i; // ANDI
                3'b001: wb_data = rs1_val << instr[24:20]; // SLLI
                3'b101: begin
                    if (funct7 == 7'b0100000)
                        wb_data = $signed(rs1_val) >>> instr[24:20]; // SRAI
                    else if (funct7 == 7'b0000000)
                        wb_data = rs1_val >> instr[24:20]; // SRLI
                    else begin
                        wb_en = 1'b0;
                        wb_data = 32'd0;
                    end
                end
                default: begin
                    wb_en = 1'b0;
                    wb_data = 32'd0;
                end
            endcase

            // RV32I shift-immediate funct7 legality.
            if (funct3 == 3'b001 && (funct7 != 7'b0000000)) begin
                wb_en = 1'b0;
                wb_data = 32'd0;
            end
        end

        7'b0110011: begin // Register ALU ops
            wb_en = (rd != 5'd0);
            case (funct3)
                3'b000: begin
                    if (funct7 == 7'b0100000)
                        wb_data = rs1_val - rs2_val; // SUB
                    else if (funct7 == 7'b0000000)
                        wb_data = rs1_val + rs2_val; // ADD
                    else begin
                        wb_en = 1'b0;
                        wb_data = 32'd0;
                    end
                end
                3'b001: begin
                    if (funct7 == 7'b0000000)
                        wb_data = rs1_val << rs2_val[4:0]; // SLL
                    else begin
                        wb_en = 1'b0;
                        wb_data = 32'd0;
                    end
                end
                3'b010: begin
                    if (funct7 == 7'b0000000)
                        wb_data = (rs1_s < rs2_s) ? 32'd1 : 32'd0; // SLT
                    else begin
                        wb_en = 1'b0;
                        wb_data = 32'd0;
                    end
                end
                3'b011: begin
                    if (funct7 == 7'b0000000)
                        wb_data = (rs1_val < rs2_val) ? 32'd1 : 32'd0; // SLTU
                    else begin
                        wb_en = 1'b0;
                        wb_data = 32'd0;
                    end
                end
                3'b100: begin
                    if (funct7 == 7'b0000000)
                        wb_data = rs1_val ^ rs2_val; // XOR
                    else begin
                        wb_en = 1'b0;
                        wb_data = 32'd0;
                    end
                end
                3'b101: begin
                    if (funct7 == 7'b0100000)
                        wb_data = $signed(rs1_val) >>> rs2_val[4:0]; // SRA
                    else if (funct7 == 7'b0000000)
                        wb_data = rs1_val >> rs2_val[4:0]; // SRL
                    else begin
                        wb_en = 1'b0;
                        wb_data = 32'd0;
                    end
                end
                3'b110: begin
                    if (funct7 == 7'b0000000)
                        wb_data = rs1_val | rs2_val; // OR
                    else begin
                        wb_en = 1'b0;
                        wb_data = 32'd0;
                    end
                end
                3'b111: begin
                    if (funct7 == 7'b0000000)
                        wb_data = rs1_val & rs2_val; // AND
                    else begin
                        wb_en = 1'b0;
                        wb_data = 32'd0;
                    end
                end
                default: begin
                    wb_en = 1'b0;
                    wb_data = 32'd0;
                end
            endcase
        end

        7'b0001111: begin
            // FENCE/FENCE.I are treated as no-ops in this simple in-order core.
            wb_en = 1'b0;
            wb_data = 32'd0;
        end

        7'b1110011: begin
            // SYSTEM (ECALL/EBREAK/CSR) is not trapped in this core yet.
            // Treat as no-op so software can continue executing.
            wb_en = 1'b0;
            wb_data = 32'd0;
        end

        default: begin
            wb_en = 1'b0;
            wb_data = 32'd0;
        end
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        pc <= 32'd0;
        for (i = 0; i < 32; i = i + 1)
            regs[i] <= 32'd0;
    end else begin
        if (wb_en && (rd != 5'd0))
            regs[rd] <= wb_data;

        regs[0] <= 32'd0;
        pc <= next_pc;
    end
end

endmodule
