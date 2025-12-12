module controller #(
    parameter int CLOCK_FREQ_HZ = 50_000_000,
    parameter int I2C_FREQ_HZ   = 100_000,
    parameter int ADDR_WIDTH = 7,
    parameter int DATA_WIDTH = 8
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
    localparam int CLOCKSPERTICK = CLOCK_FREQ_HZ / I2C_FREQ_HZ;
    // SDA  low
    localparam int SDALOWTIME = 3;

    // Clock signals
    int clock_count;
    assign FULL_TICK = (clock_count == CLOCKSPERTICK - 1);
    assign HALF_TICK = (clock_count == (CLOCKSPERTICK / 2) - 1);

    // Clock logic
    always_ff @(posedge clock, posedge reset) begin
        if (reset | (state == IDLE)) begin
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

    logic [$clog2(SDALOWTIME)-1:0] sda_low_count;

    //  Open-source drain for SDA and SCL
    logic sda_tx, sda_rx;
    logic scl_tx, scl_rx;

    assign sda = sda_tx ? 1'bz : 1'b0;
    assign scl = scl_tx ? 1'bz : 1'b0;
    assign sda_rx = sda;
    assign scl_rx = scl;

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
                    scl_tx <= 1;
                    sda_tx <= 1;
                    if (ready) begin
                        rw_flag <= rw;
                        if (~rw_flag) // write
                            tx_buffer <= tx_data;
                        sda_low_count <= 0;
                        state <= START;
                    end
                end

                START: begin
                    busy <= 1;
                    // Generate start condition
                    sda_tx <= 0;
                    scl_tx <= 1;
                    if (FULL_TICK) begin
                        if (sda_low_count < SDALOWTIME - 1) begin
                            sda_low_count <= sda_low_count + 1;
                        end
                        else
                            bit_count <= 0;
                            addr_count <= 0;
                            state <= ADDR;
                    end
                end

                ADDR: begin
                    // MSB first
                    // At half tick, set sda_tx, scl_tx go low
                    // At full tick, scl_tx go high

                    if (HALF_TICK) begin
                        scl_tx <= 0;
                        sda_tx <= slave_addr[ADDR_WIDTH - addr_count - 1];
                    end
                    else if (FULL_TICK) begin
                        scl_tx <= 1;
                        if (addr_count < ADDR_WIDTH) begin
                            addr_count <= addr_count + 1;
                        end
                        else if (addr_count == ADDR_WIDTH) begin
                            // R/W bit
                            sda_tx <= rw_flag;
                            addr_count <= addr_count + 1;
                        end
                        else begin
                            // ACK bit
                            scl_tx <= 0;
                            sda_tx <= 1; // release sda_tx for ACK

                            if (sda_rx) begin
                                ack_error <= 1;
                                state <= IDLE;
                            end

                            state <= rw_flag ? READ : WRITE;
                            bit_count <= 0;
                        end
                    end
                end

                READ: begin
                    if (HALF_TICK) begin
                        scl_tx <= 0;
                        sda_tx <= 1; // release sda_tx for reading
                    end
                    else if (FULL_TICK) begin
                        scl_tx <= 1;
                        if (bit_count < DATA_WIDTH) begin
                            rx_buffer[DATA_WIDTH - bit_count - 1] <= sda_rx;
                            bit_count <= bit_count + 1;
                        end
                        else begin
                            // ACK bit
                            scl_tx <= 0;
                            if (ack_error == 0) begin
                                sda_tx <= 0; // send ACK
                            end
                            else begin
                                sda_tx <= 1; // send NACK
                            end

                            state <= STOP;
                            rx_data <= rx_buffer;
                            valid <= 1;
                        end
                    end

                end

                WRITE: begin
                    if (HALF_TICK) begin
                        scl_tx <= 0;
                        sda_tx <= tx_buffer[DATA_WIDTH - bit_count - 1];
                    end
                    else if (FULL_TICK) begin
                        scl_tx <= 1;
                        if (bit_count < DATA_WIDTH) begin
                            bit_count <= bit_count + 1;
                        end
                        else begin
                            // ACK bit
                            scl_tx <= 0;
                            sda_tx <= 1; // release sda_tx for ACK

                            if (sda_rx) begin
                                ack_error <= 1;
                            end

                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    // Generate stop condition
                    if (HALF_TICK) begin
                        scl_tx <= 0;
                        sda_tx <= 0;
                    end
                    else if (FULL_TICK) begin
                        scl_tx <= 1;
                        sda_tx <= 1;
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule: controller

