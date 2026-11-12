module fetch #(parameter logic [31:0] PC_START = '0) (
  input logic clk, nRST,

  //branch predictor interface
  output logic [31:0] predict_block,
  input logic predict_taken, 
  input logic [1:0] predict_slot,
  input logic [31:0] predict_target,

  //icache interface
  output logic iREN,
  output logic [31:0] iaddr,
  input logic ihit,
  input logic [3:0][31:0] idata,

  //hazard
  input logic flush,
  input logic [31:0] flush_target,

  //fetch buffer
  output logic [3:0][31:0] instructions,
  output logic [3:0] mask, 
  output logic valid,
  input logic ready
);

  typedef enum {
    REQ,
    WAIT_BUFFER
  } state_t;
  state_t state, next_state;

  logic [31:0] pc, next_pc;

  logic [3:0][31:0] latched_instructions, next_latched_instructions;

  logic [3:0] head_mask, combined_mask, tail_mask;
  
  mask_decoder #(0, 4) md0(.pivot(pc[3:2]), .mask(head_mask));
  mask_decoder #(1, 4) md1(.pivot(predict_slot), .mask(tail_mask));
  assign combined_mask = head_mask & tail_mask;

  always_comb begin
    predict_block = '0;

    iREN = 1'b0;
    iaddr = '0;

    instructions = '0;
    mask = '0;
    valid = 0;

    //internals
    next_pc = pc;
    next_latched_instructions = latched_instructions;
    next_state = state;

    case (state)
      REQ: begin
        if (!flush) begin
          //req cache
          iREN = 1'b1;
          iaddr = {pc[31:4], 4'b0};

          //req branch predictor
          predict_block = pc;

          if (ihit) begin
            valid = 1'b1;
            instructions = idata;
            mask = predict_taken ? combined_mask : head_mask;
            if (ready) begin
              next_pc = predict_taken ? predict_target : ({pc[31:4], 4'b0} + 32'd16);
            end else begin
              next_latched_instructions = instructions;
              next_state = WAIT_BUFFER;
            end
          end
        end else begin
          next_pc = flush_target;
        end 
      end
      WAIT_BUFFER: begin
        if (!flush) begin
          predict_block = pc;
          valid = 1'b1;
          instructions = latched_instructions;
          mask = predict_taken ? combined_mask : head_mask;
          if (ready) begin
            next_pc = predict_taken ? predict_target : ({pc[31:4], 4'b0} + 32'd16);
            next_state = REQ;
          end
        end else begin
          next_state = REQ;
          next_pc = flush_target;
        end
      end
      default:;
    endcase
  end

  always_ff @(posedge clk, negedge nRST) begin
    if (!nRST) begin
      state <= REQ;
      pc <= PC_START;
      latched_instructions <= '0;
    end else begin
      state <= next_state;
      pc <= next_pc;
      latched_instructions <= next_latched_instructions;
    end
  end

endmodule