module first_2_on #(
  parameter int WIDTH = 64,
  localparam int INDEX_WIDTH = (WIDTH > 1) ? $clog2(WIDTH) : 1
) (
  input logic [WIDTH - 1:0] in,
  output logic [1:0][INDEX_WIDTH - 1:0] out,
  output logic [1:0] valid
);

  always_comb begin
    out   = '0;
    valid = '0;

    for (int i = 1; i < WIDTH; i++) begin //don't select reg0
      if (in[i]) begin
        if (!valid[0]) begin
          out[0]   = INDEX_WIDTH'(i);
          valid[0] = 1'b1;
        end else if (!valid[1]) begin
          out[1]   = INDEX_WIDTH'(i);
          valid[1] = 1'b1;
        end
      end
    end
  end

endmodule