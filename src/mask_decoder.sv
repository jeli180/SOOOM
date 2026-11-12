module mask_decoder #(
  parameter DIRECTION = 0,
  parameter MASK_WIDTH = 4
) (
  input logic [$clog2(MASK_WIDTH) - 1:0] pivot,
  output logic [MASK_WIDTH - 1:0] mask
);

  // 1111 10 -> 1111 << (10 + 1) = 1000 inv = 0111    DIRECTION = 1
  // 1111 10 -> 1111 << 10 = 1100            DIRECTION = 0

  logic [MASK_WIDTH - 1:0] temp;

  always_comb begin
    temp = '1;
    if (DIRECTION == 0) begin
      mask = temp << pivot;
    end else begin
      mask = pivot == '1 ? '1 : ~(temp << (pivot + 1));
    end
  end

endmodule