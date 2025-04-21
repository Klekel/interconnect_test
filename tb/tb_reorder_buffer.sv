module tb_reorder_buffer();

  localparam DATA_WIDTH            = 8;
  localparam ID_WIDTH              = 4;
  localparam AMMOUNT_OF_UNIQUE_ID  = 2**ID_WIDTH;

  logic                  clk_i = 0;
  logic                  rstn_i;
  logic                  s_arready_o,m_arready_i,m_rready_o;
  logic                  s_arvalid_i,s_rvalid_o,m_arvalid_o,m_rvalid_i;
  logic [ID_WIDTH-1:0]   s_arid_i,s_rid_o,m_arid_o,m_rid_i;
  logic [DATA_WIDTH-1:0] s_rdata_o,m_rdata_i;


  reorder_buffer #(
    .DATA_WIDTH(8)
  ) dut(
    .clk         (clk_i),
    .rst_n       (rstn_i),

    .s_arid_i    (s_arid_i),
    .s_arvalid_i (s_arvalid_i),
    .s_arready_o (s_arready_o),

    .s_rdata_o   (s_rdata_o),
    .s_rid_o     (s_rid_o),
    .s_rvalid_o  (s_rvalid_o),
    .s_rready_i  (1'b1),

    .m_arid_o    (m_arid_o),
    .m_arvalid_o (m_arvalid_o),
    .m_arready_i (m_arready_i),

    .m_rdata_i   (m_rdata_i),
    .m_rid_i     (m_rid_i),
    .m_rvalid_i  (m_rvalid_i),
    .m_rready_o  (m_rready_o)
  );

  task ID_QUEUE ( logic [ID_WIDTH-1:0] id, logic valid, logic ready);
    s_arid_i    <= id;
    s_arvalid_i <= valid;
    m_arready_i <= ready;
    @(posedge clk_i);
    s_arvalid_i <= '0;
  endtask

  task DATA_QUEUE ( logic [ID_WIDTH-1:0] id, logic [DATA_WIDTH-1:0] data, logic valid);
    m_rid_i    <= id;
    m_rdata_i  <= data;
    m_rvalid_i <= valid;
    @(posedge clk_i);
    m_rvalid_i <= '0;
    m_rid_i    <= '0;
  endtask

  task one_by_one_one_increase;
    for (int i = 0; i < 16; i++) begin
      ID_QUEUE(i,1'b1,1'b1);
    end
    for (int i = 0; i < 16; i++) begin
      DATA_QUEUE(i,i+1,1'b1);
    end
  endtask

  task one_by_one_one_decraese;
    for (int i = 0; i < 16; i++) begin
      ID_QUEUE(i,1'b1,1'b1);
    end
    for (int i = 0; i < 16; i++) begin
      DATA_QUEUE(15-i,i+1,1'b1);
    end
  endtask

  task one_by_one_delay_decraese;
    logic [ID_WIDTH-1:0] id_list [0:15];
    logic [ID_WIDTH-1:0] temp;
    int idx;

    for (int i = 0; i < 16; i++) begin
      id_list[i] = i;
    end

    for (int i = 15; i > 0; i--) begin
      idx = $urandom_range(0, i);
      temp = id_list[i];
      id_list[i] = id_list[idx];
      id_list[idx] = temp;
    end

      for (int i = 0; i < 16; i++) begin
        ID_QUEUE(id_list[i], 1'b1, 1'b1);
        repeat($urandom_range(0, 2)) @(posedge clk_i);
      end

      for (int i = 0; i < 16; i++) begin
        DATA_QUEUE(15 - i, 15 - i, 1'b1);
      end
  endtask


  initial begin
    forever #30 clk_i <= ~clk_i;
  end

  initial begin
    rstn_i <= '1;
    m_rvalid_i <= '0;
    @(posedge clk_i);
    rstn_i <= '0;
    @(posedge clk_i);
    rstn_i <= '1;
    @(posedge clk_i);
    one_by_one_one_increase();
    @(posedge clk_i);
    one_by_one_one_decraese();
    repeat(16) @(posedge clk_i);
    one_by_one_delay_decraese();
  end

endmodule