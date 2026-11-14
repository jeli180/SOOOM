`ifndef TYPE_PKG_VH
`define TYPE_PKG_VH

package type_pkg;

  //==== branch predictor
  typedef enum logic [1:0] {
    STRONG_NOT_TAKEN,
    WEAK_NOT_TAKEN,
    WEAK_TAKEN,
    STRONG_TAKEN
  } bp_state_t;

  typedef struct packed {
    bp_state_t state;
    logic [31:0] target;
  } bp_entry_t;

  //==== decode
  typedef enum logic [3:0] {
    ADD,
    SUB,
    XOR,
    OR,
    AND,
    SLL,
    SRL,
    SRA,
    SLT,
    SLTU
  } aluop_t;

  typedef enum logic [2:0] {
    BEQ,
    BNE,
    BLT,
    BGE,
    BLTU,
    BGEU
  } branch_t;

  typedef struct packed {
    logic memtoreg;
    logic memstore;
    logic regwrite;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic alusrc;
    logic branch;
    logic jal;
    logic jalr;
    logic lui;
    logic auipc;
    logic [31:0] pc_next;
    logic [31:0] pc;
    logic [31:0] imm;
    aluop_t aluop;
    branch_t btype;
  } decoded_instruction_t;

endpackage

`endif