module fifo #(
    parameter DATA_WIDTH   = 4,
              LENGTH       = 2 // must be power of 2
)(
    input  logic                  clk_i,
    input  logic                  rstn_i,

    input  logic [DATA_WIDTH-1:0] data_i,
    input  logic                  push_i,
    output logic                  full_o,

    output logic [DATA_WIDTH-1:0] data_o,
    input  logic                  pop_i,
    output logic                  empty_o
);
localparam FIFO_LENGTH = $clog2(LENGTH);

    logic             [FIFO_LENGTH:0]  read_pointer_n, read_pointer_q, write_pointer_n, write_pointer_q;
    logic [LENGTH-1:0][DATA_WIDTH-1:0] mem_q;

    assign empty_o = write_pointer_q == read_pointer_q;
    assign full_o  = {!write_pointer_q[FIFO_LENGTH],write_pointer_q[FIFO_LENGTH-1:0]} == {read_pointer_q[FIFO_LENGTH],read_pointer_q[FIFO_LENGTH-1:0]};


    always_comb begin
        read_pointer_n  = read_pointer_q;
        write_pointer_n = write_pointer_q;
        data_o          = ( empty_o ) ? '0 : mem_q[read_pointer_q[FIFO_LENGTH-1:0]];

        if (push_i && ~full_o) write_pointer_n = write_pointer_q + 1;

        if (pop_i && ~empty_o) read_pointer_n = read_pointer_q + 1;
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(~rstn_i) begin
            read_pointer_q  <= '0;
            write_pointer_q <= '0;
        end
        else begin
            read_pointer_q  <= read_pointer_n;
            write_pointer_q <= write_pointer_n;
        end
    end

    always_ff @(posedge clk_i or negedge rstn_i) begin
        if(~rstn_i) begin
            mem_q <= '0;
        end else if ( push_i && ~full_o ) begin
            mem_q[write_pointer_q[FIFO_LENGTH-1:0]] <= data_i;
        end
    end


endmodule