module speculative_map #(parameter NUM_REGISTERS = 64) (
  input logic clk, nRST,

  //haz
  input logic flush,

  //rename
  input logic rename_valid,
  output logic rename_ready,
  input logic [1:0][4:0] rs1, rs2, rd,
  output logic [1:0][$clog2(NUM_REGISTERS) - 1:0] ps1, ps2, pd, pd_old,

  //committed map
  input logic [31:0][$clog2(NUM_REGISTERS) - 1:0] committed_map,
  input logic [NUM_REGISTERS - 1:0] committed_free,

  //RoB
  input logic [1:0] rob_valid,
  input logic [1:0][$clog2(NUM_REGISTERS) - 1:0] retired_reg,

  //ready broadcast
  input logic [2:0] broadcast_valid,
  input logic [2:0][$clog2(NUM_REGISTERS) - 1:0] broadcast_reg,
  output logic [NUM_REGISTERS - 1:0] ready_registers
);

  localparam REG_WIDTH = $clog2(NUM_REGISTERS);

  logic [31:0][REG_WIDTH - 1:0] map, next_map;
  logic [NUM_REGISTERS - 1:0] free, next_free, next_ready_registers;
  logic [1:0][REG_WIDTH - 1:0] free_regs;
  logic [1:0] free_valids;

  //find first 2 free regs from the free bus, return the encoded regs and 2 valid bits
  first_2_on #(NUM_REGISTERS) find_free (
    .in(free),
    .out(free_regs),
    .valid(free_valids)
  );

  assign rename_ready = &free_valids;

  always_comb begin
    //output defaults
    pd = '0;
    for (int i = 0; i < 2; ++i) begin
      ps1[i] = map[rs1[i]];
      ps2[i] = map[rs2[i]];
      pd_old[i] = map[rd[i]];
    end
    //internals
    next_map = map;
    next_free = free;
    next_ready_registers = ready_registers;

    if (!flush) begin
      //map logic, driven by rename interface
      //account for dependency
      if (rename_ready && rename_valid) begin
        if (rd[0] != 5'b0) begin
          pd[0] = free_regs[0]; //drive pd
          next_map[rd[0]] = free_regs[0]; //change map
          next_free[free_regs[0]] = 1'b0; //turn off free bit
          next_ready_registers[free_regs[0]] = 1'b0;
          if (rd[1] != 5'b0) begin
            pd[1] = free_regs[1];
            next_map[rd[1]] = free_regs[1];
            next_free[free_regs[1]] = 1'b0;
            next_ready_registers[free_regs[1]] = 1'b0;
          end
        end else if (rd[1] != 5'b0) begin
          pd[1] = free_regs[0];
          next_map[rd[1]] = free_regs[0];
          next_free[free_regs[0]] = 1'b0; 
          next_ready_registers[free_regs[0]] = 1'b0;
        end
      end

      //handle register dependency
      if (rs1[1] != '0 && rs1[1] == rd[0]) ps1[1] = free_regs[0];
      if (rs2[1] != '0 && rs2[1] == rd[0]) ps2[1] = free_regs[0];
      if (rd[1] != '0 && rd[1] == rd[0]) pd_old[1] = free_regs[0];

      //RoB free logic
      if (rob_valid[0]) next_free[retired_reg[0]] = 1'b1;
      if (rob_valid[1]) next_free[retired_reg[1]] = 1'b1;

      //ready broadcast logic
      if (broadcast_valid[0]) next_ready_registers[broadcast_reg[0]] = 1'b1;
      if (broadcast_valid[1]) next_ready_registers[broadcast_reg[1]] = 1'b1;
      if (broadcast_valid[2]) next_ready_registers[broadcast_reg[2]] = 1'b1;
    end else begin //on flush
      next_map = committed_map;
      next_free = committed_free;
    end
  end

  always_ff @(posedge clk, negedge nRST) begin
    if (!nRST) begin
      map <= '0;
      free <= '1;
      ready_registers <= {{NUM_REGISTERS - 1{1'b0}}, 1'b1}; //reg 0 always ready
    end else begin
      map <= next_map;
      free <= next_free;
      ready_registers <= next_ready_registers;
    end
  end

endmodule