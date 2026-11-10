module icache #(
  parameter DEPTH = 16
) (
  input logic clk, nRST,

  //core interface
  input logic req,
  input logic [31:0] addr,
  output logic hit,
  output logic [3:0][31:0] instructions,

  //memory interface
  output logic mem_ren,
  output logic [31:0] mem_addr,
  input logic mem_valid,
  input logic [31:0] mem_rdata
);

  localparam IDX_WIDTH = $clog2(DEPTH);
  localparam TAG_WIDTH = 32 - 4 - IDX_WIDTH;

  //==== frame
  typedef struct packed {
    logic valid;
    logic [TAG_WIDTH - 1:0] tag;
    logic [3:0][31:0] instructions;
  } frame_t;

  frame_t [DEPTH - 1:0] frames, next_frames;

  typedef enum {
    IDLE,
    MISS0,
    MISS1,
    MISS2,
    MISS3
  } state_t;
  
  state_t next_state, state;

  logic [IDX_WIDTH - 1:0] idx, idx_s;
  logic [TAG_WIDTH - 1:0] tag, tag_s;
  assign idx = addr[4+:IDX_WIDTH];
  assign idx_s = stored_addr[4+:IDX_WIDTH];
  assign tag = addr[31:32 - TAG_WIDTH];
  assign tag_s = stored_addr[31:32 - TAG_WIDTH];

  logic [31:0] stored_addr, next_stored_addr;

  always_comb begin
    hit = 1'b0;
    instructions = '0;

    mem_ren = 1'b0;
    mem_addr = '0;

    next_stored_addr = stored_addr;
    next_state = state;
    next_frames = frames;

    case (state)
      IDLE: begin
        if (req) begin
          if (frames[idx].valid && tag == frames[idx].tag) begin //hit
            hit = 1'b1;
            instructions = frames[idx].instructions;
          end else begin
            next_state = MISS0;
            next_stored_addr = addr;
          end
        end
      end
      MISS0: begin
        mem_ren = 1'b1;
        mem_addr = {tag_s, idx_s, 2'b00, 2'b0};
        if (mem_valid) begin
          if (!req || stored_addr != addr) begin
            next_state = IDLE;
            next_frames[idx_s].valid = 1'b0;
          end else begin 
            next_frames[idx_s].instructions[0] = mem_rdata;
            next_state = MISS1;
          end
        end
      end
      MISS1: begin
        mem_ren = 1'b1;
        mem_addr = {tag_s, idx_s, 2'b01, 2'b0};
        if (mem_valid) begin
          if (!req || stored_addr != addr) begin
            next_state = IDLE;
            next_frames[idx_s].valid = 1'b0;
          end else begin 
            next_frames[idx_s].instructions[1] = mem_rdata;
            next_state = MISS2;
          end
        end
      end
      MISS2: begin
        mem_ren = 1'b1;
        mem_addr = {tag_s, idx_s, 2'b10, 2'b0};
        if (mem_valid) begin
          if (!req || stored_addr != addr) begin
            next_state = IDLE;
            next_frames[idx_s].valid = 1'b0;
          end else begin 
            next_frames[idx_s].instructions[2] = mem_rdata;
            next_state = MISS3;
          end
        end
      end
      MISS3: begin
        mem_ren = 1'b1;
        mem_addr = {tag_s, idx_s, 2'b11, 2'b0};
        if (mem_valid) begin
          if (!req || stored_addr != addr) begin
            next_state = IDLE;
            next_frames[idx_s].valid = 1'b0;
          end else begin 
            next_frames[idx_s].instructions[3] = mem_rdata;
            next_state = IDLE;
            next_frames[idx_s].valid = 1'b1;
            next_frames[idx_s].tag = tag_s;
          end
        end
      end
      default:;
    endcase
  end

  always_ff @(posedge clk, negedge nRST) begin
    if (!nRST) begin
      state <= IDLE;
      frames <= '0;
      stored_addr <= '0;
    end else begin
      state <= next_state;
      frames <= next_frames;
      stored_addr <= next_stored_addr;
    end
  end
endmodule
