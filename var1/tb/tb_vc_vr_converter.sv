module tb_vc_vr_converter();
  localparam DATA_WIDTH = 8;
  localparam CREDIT_NUM = 2;
  localparam CNT_WIDTH  = $clog2(CREDIT_NUM);

  logic                  clk_i = 0;
  logic                  rstn_i;
  logic [DATA_WIDTH-1:0] s_data_i;
  logic                  s_valid_i;
  logic                  s_credit_o;
  logic [DATA_WIDTH-1:0] m_data_o;
  logic                  m_valid_o;
  logic                  m_ready_i;

  vc_vr_converter #(
    .DATA_WIDTH(DATA_WIDTH),
    .CREDIT_NUM(CREDIT_NUM)
  ) dut(
    .clk          ( clk_i      ),
    .rst_n        ( rstn_i     ),
    .s_data_i     ( s_data_i   ),
    .s_valid_i    ( s_valid_i  ),
    .s_credit_o   ( s_credit_o ),
    .m_data_o     ( m_data_o   ),
    .m_valid_o    ( m_valid_o  ),
    .m_ready_i    ( m_ready_i  )
  );

  always #20 clk_i = ~clk_i;

task send_data(input logic [7:0] data);
  @(posedge clk_i);
  s_data_i  <= data;
  s_valid_i <= 1'b1;
  @(posedge clk_i);
  s_valid_i <= 1'b0;
endtask

  initial begin
    rstn_i    <= 1'b0;
    m_ready_i <= 1'b0;
    @( posedge clk_i );
    rstn_i    <= 1'b1;
    repeat(CREDIT_NUM) @( posedge clk_i );
    send_data(8'hAA);
    m_ready_i <= 1'b1;
    @( posedge clk_i );
    s_data_i  <= 8'hFF;
    s_valid_i <= 1'b1;
    s_data_i  <= 8'hAA;
    s_valid_i <= 1'b1;
    send_data(8'hBB);
    // m_ready_i <= 1'b0;
    @( posedge clk_i );
    send_data(8'hCC);
    @( posedge clk_i );
    s_valid_i <= 1'b0;
    @( posedge clk_i );
    send_data(8'hDD);
    send_data(8'hEE);
    s_valid_i <= 1'b1;
    @( posedge clk_i );
    s_valid_i <= 1'b0;
    repeat(3) @( posedge clk_i );
    m_ready_i <= 1'b1;
    repeat(3) @( posedge clk_i );
    m_ready_i <= 1'b1;

  end
  
endmodule