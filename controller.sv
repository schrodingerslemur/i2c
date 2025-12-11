module controller #(
    parameter CLOCK_FREQ_HZ = 50_000_000,
    parameter I2C_FREQ_HZ   = 100_000,
    parameter ADDR_WIDTH = 7,
    parameter DATA_WIDTH = 8
) (
    input  logic clock, reset,

    // Shared I2C lines
    inout  tri   sda, scl,

    // Controller interface
    input  logic rw, // read = 1, write = 0
    input  logic [ADDR_WIDTH-1:0] slave_addr,

    // For write
    input  logic [DATA_WIDTH-1:0] tx_data,

    // For read
    output logic [DATA_WIDTH-1:0] rx_data,
    output logic valid, // for read

    // Control 
    input  logic ready, // for read and write

    // Status
    output logic busy, // for read and write
    output logic ack_error
);

    // Local parameters ---------------
    // Clock 
    localparam int CLOCKS_PER_TICK = CLOCK_FREQ_HZ / I2C_FREQ_HZ;
    // SDA and SCL low
    localparam int SDA_LOW_TIME = 3;
    localparam int SCL_LOW_TIME = 5;

    // Clock signals
    int clock_count;
    assign FULL_TICK = (clock_count == CLOCKS_PER_TICK - 1);

    // Clock logic
    always_ff @(posedge clock, posedge reset) begin
        if (reset or state == IDLE) begin
            clock_count <= 0;
        end
        else begin
            if (FULL_TICK) begin
                clock_count <= 0;
            end
            else begin
                clock_count <= clock_count + 1;
            end
        end
    end

    // Registers
    logic [DATA_WIDTH-1:0] tx_buffer;
    logic [DATA_WIDTH-1:0] rx_buffer;
    logic rw_flag;
    logic [3:0] addr_count;
    logic [3:0] bit_count;

    // States
    typedef enum logic [2:0] {
        IDLE,
        START,
        ADDR,
        READ,
        WRITE,
        STOP
    } state_t;

    state_t state;

    // Status signals: busy, valid, ack_error
    // State machine
    always_ff @(posedge clock, posedge reset) begin
        if (reset)
            state <= IDLE;
        else begin
            case (state) 
                IDLE: begin
                    busy <= 0;
                    valid <= 0;
                    ack_error <= 0;
                    scl <= 1;
                    sda <= 1;
                    if (ready) begin
                        rw_flag <= rw;
                        if (~rw_flag) // write
                            tx_buffer <= tx_data;
                        state <= START;
                    end
                    else
                        state <= IDLE;
                end

                START: begin
                    busy <= 1;
                    // Generate start condition
                    sda <= 0;
                    scl <= 1;
                    if (FULL_TICK) begin
                        state <= ADDR;
                    end
                end

                ADDR: begin
                    
                end

            endcase
        end
    end

endmodule: controller

