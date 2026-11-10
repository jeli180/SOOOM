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

endpackage

`endif