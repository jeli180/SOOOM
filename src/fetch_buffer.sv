module fetch_buffer #(parameter DEPTH = 16) (
  input logic clk, nRST,

  //fetch interface
  input logic fetch_valid,
  input logic [3:0][31:0] instructions_in,
  input logic [3:0] mask,
  output logic fetch_ready,

  //hazard
  input logic flush,

  //decode interface
  output logic [1:0][31:0] instructions_out,

  //decode buffer interface
  output logic decode_valid,
  input logic decode_ready
);

  localparam PTR_WIDTH = $clog2(DEPTH);

  logic [PTR_WIDTH:0] wptr, next_wptr, rptr, next_rptr, free_entries, used_entries;

  logic [DEPTH - 1:0][31:0] frames, next_frames;

  assign used_entries = wptr - rptr;
  assign free_entries = DEPTH - used_entries;
  assign fetch_ready = (free_entries >= $countones(mask) || (free_entries >= 2 && decode_ready)) && !flush;
  assign decode_valid = (used_entries >= 2) && !flush;

  assign instructions_out[0] = frames[rptr[PTR_WIDTH - 1:0]];
  assign instructions_out[1] = frames[rptr[PTR_WIDTH - 1:0] + 1];

  always_comb begin
    //internal
    next_wptr = wptr;
    next_rptr = rptr;
    next_frames = frames;

    if (!flush) begin
      //write logic
      if (fetch_ready && fetch_valid) begin
        for (int i = 0; i < 4; ++i) begin
          if (mask[i]) begin
            next_frames[next_wptr[PTR_WIDTH - 1:0]] = instructions_in[i];
            next_wptr = next_wptr + 1;
          end
        end
      end

      //read logic 
      if (decode_ready && decode_valid) next_rptr = rptr + 2;
    end else begin
      next_rptr = '0;
      next_wptr = '0;
    end
  end

  always_ff @(posedge clk, negedge nRST) begin
    if (!nRST) begin
      wptr <= '0;
      rptr <= '0;
      frames <= '0;
    end else begin
      wptr <= next_wptr;
      rptr <= next_rptr;
      frames <= next_frames;
    end
  end

endmodule