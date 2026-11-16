module committed_map #(
  parameter int NUM_REGISTERS = 64,
  localparam int REG_WIDTH = $clog2(NUM_REGISTERS)
) (
    input logic clk, nRST,

    //ROB
    input logic [1:0] valid,
    input logic [1:0][4:0] areg,
    input logic [1:0][REG_WIDTH - 1:0] preg,

    //spec map
    output logic [NUM_REGISTERS - 1:0] free,
    output logic [31:0][REG_WIDTH - 1:0] map
);

  logic [31:0][REG_WIDTH - 1:0] next_map;
  logic [NUM_REGISTERS - 1:0] next_free;

  always_comb begin
    next_map = map;
    next_free = free;

    for (int i = 0; i < 2; ++i) begin
      if (valid[i] && |areg[i]) begin
        next_free[next_map[areg[i]]] = 1'b1;
        next_map[areg[i]] = preg[i];
        next_free[preg[i]] = 1'b0;
      end
    end
  end

  always_ff @(posedge clk, negedge nRST) begin
    if (!nRST) begin
      free <= '1;
      map <= '0;
    end else begin
      free <= next_free;
      map <= next_map;
    end
  end

endmodule

