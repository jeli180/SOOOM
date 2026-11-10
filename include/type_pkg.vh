`ifndef TYPE_PKG_VH
`define TYPE_PKG_VH

package type_pkg;

  localparam BP_BLOCK_WIDTH = 4;
  localparam BP_TAG_WIDTH = 32 - BP_BLOCK_WIDTH - 4;

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

  typedef struct packed {
    logic valid;
    logic [BP_TAG_WIDTH - 1:0] tag;
    bp_entry_t [3:0] entry;
  } bp_block_t;

endpackage

`endif