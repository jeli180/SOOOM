`include "include/type_pkg.vh"

import type_pkg::*;

module branch_predictor #(
  parameter DEPTH = 16 //number of BLOCKs, each has 4 instructions
) (
  input logic clk, nRST,

  //update signals
  input logic [1:0][31:0] update_target, update_pc,
  input logic [1:0] update_taken, update_valid,

  //predict interface
  input logic [31:0] predict_block,
  output logic [31:0] predict_target,
  output logic predict_taken,
  output logic [1:0] slot
);

  //pc = 24 tag bits | BLOCK_WIDTH(4) block bits | 2 offset bits | 2'b0

  localparam BLOCK_WIDTH = $clog2(DEPTH);
  localparam TAG_WIDTH = 32 - BLOCK_WIDTH - 4;

  typedef struct packed {
    logic valid;
    logic [TAG_WIDTH - 1:0] tag;
    bp_entry_t [3:0] entry;
  } bp_block_t;

  bp_block_t [DEPTH - 1:0] block, next_block;

  logic [3:0] taken_bits;
  assign taken_bits = {block[predict_block[4+:BLOCK_WIDTH]].entry[3].state[1], 
                       block[predict_block[4+:BLOCK_WIDTH]].entry[2].state[1],
                       block[predict_block[4+:BLOCK_WIDTH]].entry[1].state[1],
                       block[predict_block[4+:BLOCK_WIDTH]].entry[0].state[1]};

  always_comb begin
    next_block = block;

    predict_taken = 1'b0;
    predict_target = '0;
    slot = '0;

    //update logic 
    for (int i = 0; i < 2; ++i) begin
      if (update_valid[i]) begin
        next_block[update_pc[i][4+:BLOCK_WIDTH]].valid = 1'b1;
        next_block[update_pc[i][4+:BLOCK_WIDTH]].tag = update_pc[i][31:32 - TAG_WIDTH];
        if (block[update_pc[i][4+:BLOCK_WIDTH]].tag != update_pc[i][31:32 - TAG_WIDTH]) begin //tag mismatch, reset entries to default
          for (int j = 0; j < 4; ++j) begin
            next_block[update_pc[i][4+:BLOCK_WIDTH]].entry[j].state = WEAK_NOT_TAKEN;
            next_block[update_pc[i][4+:BLOCK_WIDTH]].entry[j].target = '0;
          end
          next_block[update_pc[i][4+:BLOCK_WIDTH]].entry[update_pc[i][3:2]].target = update_target[i];
          next_block[update_pc[i][4+:BLOCK_WIDTH]].entry[update_pc[i][3:2]].state = update_taken[i] ? WEAK_TAKEN : STRONG_NOT_TAKEN;
        end else begin
          next_block[update_pc[i][4+:BLOCK_WIDTH]].entry[update_pc[i][3:2]].target = update_target[i];
          case (block[update_pc[i][4+:BLOCK_WIDTH]].entry[update_pc[i][3:2]].state)
            STRONG_NOT_TAKEN: begin
              next_block[update_pc[i][4+:BLOCK_WIDTH]].entry[update_pc[i][3:2]].state = update_taken[i] ? WEAK_NOT_TAKEN : STRONG_NOT_TAKEN;
            end
            WEAK_NOT_TAKEN: begin
              next_block[update_pc[i][4+:BLOCK_WIDTH]].entry[update_pc[i][3:2]].state = update_taken[i] ? WEAK_TAKEN : STRONG_NOT_TAKEN;
            end
            WEAK_TAKEN: begin
              next_block[update_pc[i][4+:BLOCK_WIDTH]].entry[update_pc[i][3:2]].state = update_taken[i] ? STRONG_TAKEN : WEAK_NOT_TAKEN;
            end
            STRONG_TAKEN: begin
              next_block[update_pc[i][4+:BLOCK_WIDTH]].entry[update_pc[i][3:2]].state = update_taken[i] ? STRONG_TAKEN : WEAK_TAKEN;
            end
            default:;
          endcase
        end
      end
    end

    //prediction logic
    if (block[predict_block[4+:BLOCK_WIDTH]].valid && block[predict_block[4+:BLOCK_WIDTH]].tag == predict_block[31:32 - TAG_WIDTH]) begin
      case (predict_block[3:2])
        2'b11: begin
          casez (taken_bits[3])
            1'b1: begin
              predict_taken = 1'b1;
              predict_target = block[predict_block[4+:BLOCK_WIDTH]].entry[3].target;
              slot = 2'b11;
            end
            default:;
          endcase
        end
        2'b10: begin
          casez (taken_bits[3:2])
            2'b?1: begin
              predict_taken = 1'b1;
              predict_target = block[predict_block[4+:BLOCK_WIDTH]].entry[2].target;
              slot = 2'b10;
            end
            2'b10: begin
              predict_taken = 1'b1;
              predict_target = block[predict_block[4+:BLOCK_WIDTH]].entry[3].target;
              slot = 2'b11;
            end
            default:;
          endcase
        end
        2'b01: begin
          casez (taken_bits[3:1])
            3'b??1: begin
              predict_taken = 1'b1;
              predict_target = block[predict_block[4+:BLOCK_WIDTH]].entry[1].target;
              slot = 2'b01;
            end
            3'b?10: begin
              predict_taken = 1'b1;
              predict_target = block[predict_block[4+:BLOCK_WIDTH]].entry[2].target;
              slot = 2'b10;
            end
            3'b100: begin
              predict_taken = 1'b1;
              predict_target = block[predict_block[4+:BLOCK_WIDTH]].entry[3].target;
              slot = 2'b11;
            end
            default:;
          endcase
        end
        2'b00: begin
          casez (taken_bits[3:0])
            4'b???1: begin
              predict_taken = 1'b1;
              predict_target = block[predict_block[4+:BLOCK_WIDTH]].entry[0].target;
              slot = 2'b00;
            end
            4'b??10: begin
              predict_taken = 1'b1;
              predict_target = block[predict_block[4+:BLOCK_WIDTH]].entry[1].target;
              slot = 2'b01;
            end
            4'b?100: begin
              predict_taken = 1'b1;
              predict_target = block[predict_block[4+:BLOCK_WIDTH]].entry[2].target;
              slot = 2'b10;
            end
            4'b1000: begin
              predict_taken = 1'b1;
              predict_target = block[predict_block[4+:BLOCK_WIDTH]].entry[3].target;
              slot = 2'b11;
            end
            default:;
          endcase
        end
        default:;
      endcase
    end
  end

  always_ff @(posedge clk, negedge nRST) begin
    if (!nRST) begin
      for (int i = 0; i < DEPTH; ++i) begin
        block[i].valid <= 1'b0;
        block[i].tag <= '0;
        for (int j = 0; j < 4; ++j) begin
          block[i].entry[j].state <= WEAK_NOT_TAKEN;
          block[i].entry[j].target <= '0;
        end
      end
    end else begin
      block <= next_block;
    end
  end

endmodule