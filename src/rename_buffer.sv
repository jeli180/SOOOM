`include "type_pkg.vh"
import type_pkg::*;

module rename_buffer (
  input logic clk, nRST,

  //haz
  input logic flush,

  //rename
  input logic rename_valid,
  output logic rename_ready,
  input renamed_instruction_t [1:0] in,

  //dispatch
  input logic dispatch_ready,
  output logic dispatch_valid,
  output renamed_instruction_t [1:0] out
);

  renamed_instruction_t [1:0] next_out;

  typedef enum {
    EMPTY,
    FULL
  } state_t;
  state_t state, next_state;

  always_comb begin
    next_state = state;
    next_out = out;

    rename_ready = 1'b0;
    dispatch_valid = 1'b0;
    
    if (!flush) begin 
      case (state)
        EMPTY: begin
          rename_ready = 1'b1;
          if (rename_valid) begin
            next_state = FULL;
            next_out = in;
          end
        end
        FULL: begin
          dispatch_valid = 1'b1;
          if (dispatch_ready) begin
            rename_ready = 1'b1;
            if (rename_valid) next_out = in;
            else next_state = EMPTY;
          end
        end
        default:;
      endcase
    end else next_state = EMPTY;
  end

  always_ff @(posedge clk, negedge nRST) begin
    if (!nRST) begin
      out <= '0;
      state <= EMPTY;
    end else begin
      out <= next_out;
      state <= next_state;
    end
  end

endmodule