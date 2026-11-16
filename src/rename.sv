`include "type_pkg.vh"
import type_pkg::*;

module rename #(parameter NUM_REGISTERS = 64) (
  //decode, ready valid directly to rename/dispatch latch
  input decoded_instruction_t [1:0] in,
  input logic decode_valid, 
  output logic decode_ready,

  //register map
  output logic rmap_valid,
  input logic rmap_ready,
  output logic [1:0][4:0] rs1, rs2, rd, 
  input logic [1:0][$clog2(NUM_REGISTERS) - 1:0] ps1, ps2, pd, pd_old,

  //rename/dispatch latch
  output renamed_instruction_t [1:0] out,
  input logic latch_ready,
  output logic latch_valid
);

  assign decode_ready = latch_ready && rmap_ready;
  assign latch_valid = decode_valid && rmap_ready;

  assign rmap_valid = decode_valid && decode_ready && latch_ready && latch_valid;

  always_comb begin
    for (int i = 0; i < 2; ++i) begin
      rs1[i] = in[i].rs1;
      rs2[i] = in[i].rs2;
      rd[i] = in[i].rd;
      out[i].decoded_instruction = in[i];
      out[i].ps1 = ps1[i];
      out[i].ps2 = ps2[i];
      out[i].pd = pd[i];
      out[i].pd_old = pd_old[i];
    end
  end

endmodule