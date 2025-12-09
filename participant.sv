module participant #(
    parameter ADDR_WIDTH = 7,
    parameter DATA_WIDTH = 8
) (
    input  logic                     clock,
    input  logic                     reset,
    inout  logic                     sda,
    inout  logic                     scl,
    input  logic  [ADDR_WIDTH-1:0]   own_addr,
    output logic  [DATA_WIDTH-1:0]   rx_data,
    output logic                     valid,
    input  logic [DATA_WIDTH-1:0]    tx_data,
    input  logic                     ready,
    output logic                     ack_error
);
endmodule: participant