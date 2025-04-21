module vc_vr_converter #(
  parameter DATA_WIDTH = 8,
            CREDIT_NUM = 2
)(
  input  logic                  clk,
  input  logic                  rst_n,
  //valid/credit interface
  input  logic [DATA_WIDTH-1:0] s_data_i,
  input  logic                  s_valid_i,
  output logic                  s_credit_o,
  //valid/ready interface
  output logic [DATA_WIDTH-1:0] m_data_o,
  output logic                  m_valid_o,
  input  logic                  m_ready_i
);
  localparam CNT_WIDTH = $clog2(CREDIT_NUM);

  logic [CNT_WIDTH:0] credit_cnt;
  logic [CNT_WIDTH:0] credit_cnt_next;
  logic               full;
  logic               empty;

  assign credit_cnt_next = credit_cnt + 1'b1;
  assign s_credit_o      = (credit_cnt <= CREDIT_NUM) && (credit_cnt != '0) || m_ready_i && m_valid_o;
  assign m_valid_o       = !empty;

  always_ff @(posedge clk or negedge rst_n) begin
    if      (!rst_n)                     credit_cnt <= '0;
    else if ( credit_cnt <= CREDIT_NUM ) credit_cnt <= credit_cnt_next;
  end

  fifo #( //saving id order
  .DATA_WIDTH(DATA_WIDTH),
  .LENGTH    (CREDIT_NUM)
  ) dut(
    .clk_i   ( clk                    ),
    .rstn_i  ( rst_n                  ),
    .full_o  ( full                   ),
    .empty_o ( empty                  ),
    .data_i  ( s_data_i               ),
    .push_i  ( s_valid_i              ),
    .data_o  ( m_data_o               ),
    .pop_i   ( m_ready_i && m_valid_o )
  );
endmodule