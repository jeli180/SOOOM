`include "type_pkg.vh"
import type_pkg::*;

module decode (
  input logic [1:0][31:0] in, pc, pc_next,
  output decoded_instruction_t [1:0] out
);

  always_comb begin
    out = '0;
    for (int i = 0; i < 2; ++i) begin
      out[i].pc = pc[i];
      out[i].pc_next = pc_next[i];
      out[i].rs1 = in[i][19:15];
      out[i].rs2 = in[i][24:20];
      out[i].rd = in[i][11:7];
      case (in[i][6:0])
        7'b0110011: begin //r
          out[i].regwrite = 1'b1;
          case (in[i][14:12])
            3'd0: out[i].aluop = in[i][30] ? SUB : ADD;
            3'd1: out[i].aluop = SLL;
            3'd2: out[i].aluop = SLT;
            3'd3: out[i].aluop = SLTU;
            3'd4: out[i].aluop = XOR;
            3'd5: out[i].aluop = in[i][30] ? SRA : SRL;
            3'd6: out[i].aluop = OR;
            3'd7: out[i].aluop = AND;
            default:;
          endcase

        end
        7'b0010011: begin //i
          out[i].regwrite = 1'b1;
          out[i].alusrc = 1'b1;
          out[i].imm = {{21{in[i][31]}}, in[i][30:20]};
          case (in[i][14:12])
            3'd0: out[i].aluop = ADD;
            3'd1: begin 
              out[i].aluop = SLL;
              out[i].imm = {27'b0, in[i][24:20]};
            end
            3'd2: out[i].aluop = SLT;
            3'd3: out[i].aluop = SLTU;
            3'd4: out[i].aluop = XOR;
            3'd5: begin
              out[i].aluop = in[i][30] ? SRA : SRL;
              out[i].imm = {27'b0, in[i][24:20]};
            end
            3'd6: out[i].aluop = OR;
            3'd7: out[i].aluop = AND;
            default:;
          endcase
        end
        7'b0000011: begin //load
          out[i].regwrite = 1'b1;
          out[i].alusrc = 1'b1; //doesn't matter
          out[i].memtoreg = 1'b1;
          out[i].aluop = ADD; //doesn't matter
          out[i].imm = {{21{in[i][31]}}, in[i][30:20]};
        end
        7'b0100011: begin //store
          out[i].alusrc = 1'b1; //doesn't matter
          out[i].memstore = 1'b1;
          out[i].aluop = ADD; //doesn't matter
          out[i].imm = {{21{in[i][31]}}, in[i][30:25], in[i][11:7]};
        end
        7'b1100011: begin //branch
          out[i].alusrc = 1'b1; //use alu to PC + imm
          out[i].branch = 1'b1;
          out[i].aluop = ADD;
          out[i].imm = {{20{in[i][31]}}, in[i][7], in[i][30:25], in[i][11:8], 1'b0};
          case (in[i][14:12])
            3'd0: out[i].btype = BEQ;
            3'd1: out[i].btype = BNE;
            3'd4: out[i].btype = BLT;
            3'd5: out[i].btype = BGE;
            3'd6: out[i].btype = BLTU;
            3'd7: out[i].btype = BGEU;
            default:;
          endcase
        end
        7'b1101111: begin //jal
          out[i].alusrc = 1'b1; //use alu to PC + imm
          out[i].regwrite = 1'b1;
          out[i].jal = 1'b1;
          out[i].aluop = ADD;
          out[i].imm = {{12{in[i][31]}}, in[i][19:12], in[i][20], in[i][30:21], 1'b0};
        end
        7'b1100111: begin //jalr
          out[i].alusrc = 1'b1; //use alu to rs1 + imm
          out[i].regwrite = 1'b1;
          out[i].jalr = 1'b1;
          out[i].aluop = ADD;
          out[i].imm = {{21{in[i][31]}}, in[i][30:20]};
        end
        7'b0110111: begin //lui
          out[i].regwrite = 1'b1;
          out[i].lui = 1'b1;
          out[i].imm = {in[i][31:12], 12'b0};
        end
        7'b0010111: begin //auipc
          out[i].regwrite = 1'b1;
          out[i].auipc = 1'b1;
          out[i].alusrc = 1'b1;
          out[i].aluop = ADD;
          out[i].imm = {in[i][31:12], 12'b0};
        end
        default:;
      endcase
    end
  end
  
endmodule