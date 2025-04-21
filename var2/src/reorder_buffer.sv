module reorder_buffer #(
    parameter  DATA_WIDTH = 8,
    parameter  ID_WIDTH   = 4
 )(
    input  logic                  clk,
    input  logic                  rst_n,
    //AR slave interface
    input  logic [ID_WIDTH-1:0]   s_arid_i,
    input  logic                  s_arvalid_i,
    output logic                  s_arready_o,
    //R slave interface
    output logic [DATA_WIDTH-1:0] s_rdata_o,
    output logic [ID_WIDTH-1:0]   s_rid_o,
    output logic                  s_rvalid_o,
    input  logic                  s_rready_i,
    //AR master interface
    output logic [ID_WIDTH-1:0]   m_arid_o,
    output logic                  m_arvalid_o,
    input  logic                  m_arready_i,
    //R master interface
    input  logic [DATA_WIDTH-1:0] m_rdata_i,
    input  logic [ID_WIDTH-1:0]   m_rid_i,
    input  logic                  m_rvalid_i,
    output logic                  m_rready_o
 );

  localparam AMMOUNT_OF_UNIQUE_ID = 2**ID_WIDTH;

  assign m_arid_o    = s_arid_i;
  assign m_arvalid_o = s_arvalid_i;
  assign s_arready_o = m_arready_i;

  logic                                          push;
  logic                                          pop;
  logic                           [ID_WIDTH-1:0] first_id_in_queue;
  logic [AMMOUNT_OF_UNIQUE_ID-1:0][DATA_WIDTH:0] data_buf; // DATA_WIDTH is flag of activness, [DATA_WIDTH-1:0] is data
  logic [AMMOUNT_OF_UNIQUE_ID-1:0][DATA_WIDTH:0] data_buf_next;
  logic                           [DATA_WIDTH:0] buf_out;

  assign push = s_arvalid_i && s_arready_o;
  assign pop  = s_rvalid_o && s_rready_i;

  fifo #( //saving id order
    .DATA_WIDTH(ID_WIDTH)
  ) dut(
  .clk_i   ( clk               ),
  .rstn_i  ( rst_n             ),
  .full_o  (                   ),
  .empty_o (                   ),
  .data_i  ( s_arid_i          ),
  .push_i  ( push              ),
  .data_o  ( first_id_in_queue ),
  .pop_i   ( pop               )
  );

  always_comb begin //demux
    data_buf_next = '0;
    for (int i = 0; i < AMMOUNT_OF_UNIQUE_ID; i++) begin
      data_buf_next[i] = ( m_rid_i == i ) ? {m_rvalid_i && m_rready_o,m_rdata_i} : '0;
    end
  end

  always_ff @( posedge clk or negedge rst_n ) begin // buffer for data
    for (int i = 0; i < AMMOUNT_OF_UNIQUE_ID; i++) begin
      if ( !rst_n ) data_buf[i] <= '0;
      if ( pop && (first_id_in_queue == i))    data_buf[i] <= '0;
      else if ((m_rid_i == i ) && ( m_rvalid_i && m_rready_o )) data_buf[i] <= data_buf_next[i];
    end
  end

  always_comb begin // output mux + valid logic
    buf_out    = '0;
    m_rready_o = 1'b0;
    for (int i = 0; i < AMMOUNT_OF_UNIQUE_ID; i++) begin
      buf_out    |= {DATA_WIDTH+1{( first_id_in_queue == i )}} & data_buf[i];
      m_rready_o |= ~data_buf[i][DATA_WIDTH];
    end
    s_rvalid_o = buf_out[DATA_WIDTH];
    s_rdata_o  = buf_out[DATA_WIDTH-1:0];
    s_rid_o    = first_id_in_queue;
  end

endmodule