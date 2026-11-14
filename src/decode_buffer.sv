`include "type_pkg.vh"
import type_pkg::*;

module decode_buffer (
  input logic clk, nRST,

  //haz
  input logic flush,

  //fetch
  input logic fetch_valid,
  output logic fetch_ready,
  input decoded_instruction_t [1:0] in,

  //dispatch
  input logic dispatch_ready,
  output logic dispatch_valid,
  output decoded_instruction_t [1:0] out
);

  decoded_instruction_t [1:0] next_out;

  typedef enum {
    EMPTY,
    FULL
  } state_t;
  state_t state, next_state;

  always_comb begin
    next_state = state;
    next_out = out;

    fetch_ready = 1'b0;
    dispatch_valid = 1'b0;
    
    if (!flush) begin 
      case (state)
        EMPTY: begin
          fetch_ready = 1'b1;
          if (fetch_valid) begin
            next_state = FULL;
            next_out = in;
          end
        end
        FULL: begin
          dispatch_valid = 1'b1;
          if (dispatch_ready) begin
            fetch_ready = 1'b1;
            if (fetch_valid) next_out = in;
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