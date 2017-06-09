// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.

module vsi_cl
  
  (
`include "cl_ports.vh" // Fixed port definition
   );
   
`include "cl_common_defines.vh"      // CL Defines for all examples
`include "cl_id_defines.vh"          // Defines for ID0 and ID1 (PCI ID's)
`include "vsi_cl_defines.vh" 	     // CL Defines for vsi_cl
   
   logic rst_main_n_sync;
   
   
   //--------------------------------------------0
   // Start with Tie-Off of Unused Interfaces
   //---------------------------------------------
   // the developer should use the next set of `include
   // to properly tie-off any unused interface
   // The list is put in the top of the module
   // to avoid cases where developer may forget to
   // remove it from the end of the file
   //`include "unused_pcim_template.inc"
   //`include "unused_apppf_irq_template.inc"
   //`include "unused_dma_pcis_template.inc"
   //`include "unused_ddr_a_b_d_template.inc"

`include "unused_flr_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_hmc_template.inc"
`include "unused_aurora_template.inc"
`include "unused_sh_bar1_template.inc"
`include "unused_ddr_c_template.inc"
   
   // Defining local parameters that will instantiate the
   // 3 DRAM controllers inside the CL
  
   localparam DDR_A_PRESENT = 1;
   localparam DDR_B_PRESENT = 1;
   localparam DDR_D_PRESENT = 1;

   // Define the addition pipeline stag
   // needed to close timing for the various
   // place where ATG (Automatic Test Generator)
   // is defined
   
   localparam NUM_CFG_STGS_CL_DDR_ATG = 4;
   localparam NUM_CFG_STGS_SH_DDR_ATG = 4;
   localparam NUM_CFG_STGS_PCIE_ATG = 4;
`ifdef SIM
   localparam DDR_SCRB_MAX_ADDR = 64'h1FFF;
`else   
   localparam DDR_SCRB_MAX_ADDR = 64'h3FFFFFFFF; //16GB 
`endif
   localparam DDR_SCRB_BURST_LEN_MINUS1 = 15;

`ifdef NO_CL_TST_SCRUBBER
   localparam NO_SCRB_INST = 1;
`else
   localparam NO_SCRB_INST = 0;
`endif   
   logic sync_rst_n;

   //-------------------------------------------------
   // ID Values (cl_hello_world_defines.vh)
   //-------------------------------------------------
//   assign cl_sh_id0[31:0] = `CL_SH_ID0;
//   assign cl_sh_id1[31:0] = `CL_SH_ID1;
   
   //-------------------------------------------------
   // Reset Synchronization
   //-------------------------------------------------
   logic pre_sync_rst_n;
   
   always_ff @(negedge rst_main_n or posedge clk_main_a0)
     if (!rst_main_n)
       begin
	  pre_sync_rst_n  <= 0;
	  rst_main_n_sync <= 0;
       end
     else
       begin
	  pre_sync_rst_n  <= 1;
	  rst_main_n_sync <= pre_sync_rst_n;
       end
   
   //-------------------------------------------------
   // PCIe OCL AXI-L (SH to CL) Timing Flops
   //-------------------------------------------------
   
   // Write address                                                                                                              
   logic        sh_ocl_awvalid_q;
   logic [31:0] sh_ocl_awaddr_q;
   logic        ocl_sh_awready_q;
   
   // Write data                                                                                                                
   logic        sh_ocl_wvalid_q;
   logic [31:0] sh_ocl_wdata_q;
   logic [ 3:0] sh_ocl_wstrb_q;
   logic        ocl_sh_wready_q;
   
   // Write response                                                                                                            
   logic        ocl_sh_bvalid_q;
   logic [ 1:0] ocl_sh_bresp_q;
   logic        sh_ocl_bready_q;
   
   // Read address                                                                                                              
   logic        sh_ocl_arvalid_q;
   logic [31:0] sh_ocl_araddr_q;
   logic        ocl_sh_arready_q;
   
   // Read data/response                                                                                                        
   logic        ocl_sh_rvalid_q;
   logic [31:0] ocl_sh_rdata_q;
   logic [ 1:0] ocl_sh_rresp_q;
   logic        sh_ocl_rready_q;
   
   axi_register_slice_light AXIL_OCL_REG_SLC (
					      .aclk          (clk_main_a0),
					      .aresetn       (rst_main_n_sync),
					      .s_axi_awaddr  (sh_ocl_awaddr+32'h82000000),
					      .s_axi_awprot   (2'h0),
					      .s_axi_awvalid (sh_ocl_awvalid),
					      .s_axi_awready (ocl_sh_awready),
					      .s_axi_wdata   (sh_ocl_wdata),
					      .s_axi_wstrb   (sh_ocl_wstrb),
					      .s_axi_wvalid  (sh_ocl_wvalid),
					      .s_axi_wready  (ocl_sh_wready),
					      .s_axi_bresp   (ocl_sh_bresp),
					      .s_axi_bvalid  (ocl_sh_bvalid),
					      .s_axi_bready  (sh_ocl_bready),
					      .s_axi_araddr  (sh_ocl_araddr+32'h82000000),
					      .s_axi_arvalid (sh_ocl_arvalid),
					      .s_axi_arready (ocl_sh_arready),
					      .s_axi_rdata   (ocl_sh_rdata),
					      .s_axi_rresp   (ocl_sh_rresp),
					      .s_axi_rvalid  (ocl_sh_rvalid),
					      .s_axi_rready  (sh_ocl_rready),
					      .m_axi_awaddr  (sh_ocl_awaddr_q),
					      .m_axi_awprot  (),
					      .m_axi_awvalid (sh_ocl_awvalid_q),
					      .m_axi_awready (ocl_sh_awready_q),
					      .m_axi_wdata   (sh_ocl_wdata_q),
					      .m_axi_wstrb   (sh_ocl_wstrb_q),
					      .m_axi_wvalid  (sh_ocl_wvalid_q),
					      .m_axi_wready  (ocl_sh_wready_q),
					      .m_axi_bresp   (ocl_sh_bresp_q),
					      .m_axi_bvalid  (ocl_sh_bvalid_q),
					      .m_axi_bready  (sh_ocl_bready_q),
					      .m_axi_araddr  (sh_ocl_araddr_q),
					      .m_axi_arvalid (sh_ocl_arvalid_q),
					      .m_axi_arready (ocl_sh_arready_q),
					      .m_axi_rdata   (ocl_sh_rdata_q),
					      .m_axi_rresp   (ocl_sh_rresp_q),
					      .m_axi_rvalid  (ocl_sh_rvalid_q),
					      .m_axi_rready  (sh_ocl_rready_q)
					      );
   // Temporal workaround until these signals removed from the shell
   
   assign cl_sh_pcim_awuser = 18'h0;
   assign cl_sh_pcim_aruser = 18'h0;

   axi_bus_t lcl_cl_sh_ddra();
   axi_bus_t lcl_cl_sh_ddrb();
   axi_bus_t lcl_cl_sh_ddrd();
   //-------------------------------------------------
   // instantiate design generated by VSI
   //-------------------------------------------------
   wire [63:0] 	cl_sh_pcim_araddr_out;
   wire [63:0] 	cl_sh_pcim_awaddr_out;
   wire [31:0] 	gpio_tri_o;
   wire 	irq_o;
   // need to chop the upper bits
   assign cl_sh_pcim_araddr = {32'b0,cl_sh_pcim_araddr_out[31:0]}; 
   assign cl_sh_pcim_awaddr = {32'b0,cl_sh_pcim_awaddr_out[31:0]};
   
   aws_fpga_wrapper 
     aws_fpga (.DDR_A_araddr	(lcl_cl_sh_ddra.araddr),
	       .DDR_A_arburst	(),
	       .DDR_A_arcache	(),
	       .DDR_A_arid	(lcl_cl_sh_ddra.arid),
	       .DDR_A_arlen	(lcl_cl_sh_ddra.arlen),
	       .DDR_A_arlock	(),
	       .DDR_A_arprot	(),
	       .DDR_A_arqos	(),
	       .DDR_A_arready	(lcl_cl_sh_ddra.arready),
	       .DDR_A_arregion	(),
	       .DDR_A_arsize	(lcl_cl_sh_ddra.arsize),
	       .DDR_A_arvalid	(lcl_cl_sh_ddra.arvalid),
	       .DDR_A_awaddr	(lcl_cl_sh_ddra.awaddr),
	       .DDR_A_awburst	(),
	       .DDR_A_awcache	(),
	       .DDR_A_awid	(lcl_cl_sh_ddra.awid),
	       .DDR_A_awlen	(lcl_cl_sh_ddra.awlen),
	       .DDR_A_awlock	(),
	       .DDR_A_awprot	(),
	       .DDR_A_awqos	(),
	       .DDR_A_awready	(lcl_cl_sh_ddra.awready),
	       .DDR_A_awregion	(),
	       .DDR_A_awsize	(lcl_cl_sh_ddra.awsize),
	       .DDR_A_awvalid	(lcl_cl_sh_ddra.awvalid),
	       .DDR_A_bid	(lcl_cl_sh_ddra.bid),
	       .DDR_A_bready	(lcl_cl_sh_ddra.bready),
	       .DDR_A_bresp	(lcl_cl_sh_ddra.bresp),
	       .DDR_A_bvalid	(lcl_cl_sh_ddra.bvalid),
	       .DDR_A_rdata	(lcl_cl_sh_ddra.rdata),
	       .DDR_A_rid	(lcl_cl_sh_ddra.rid),
	       .DDR_A_rlast	(lcl_cl_sh_ddra.rlast),
	       .DDR_A_rready	(lcl_cl_sh_ddra.rready),
	       .DDR_A_rresp	(lcl_cl_sh_ddra.rresp),
	       .DDR_A_rvalid	(lcl_cl_sh_ddra.rvalid),
	       .DDR_A_wdata	(lcl_cl_sh_ddra.wdata),
	       .DDR_A_wlast	(lcl_cl_sh_ddra.wlast),
	       .DDR_A_wready	(lcl_cl_sh_ddra.wready),
	       .DDR_A_wstrb	(lcl_cl_sh_ddra.wstrb),
	       .DDR_A_wvalid	(lcl_cl_sh_ddra.wvalid),
	       
	       .DMA_1_araddr	(cl_sh_pcim_araddr_out),
	       .DMA_1_arburst	(),
	       .DMA_1_arcache	(),
	       .DMA_1_arid      (cl_sh_pcim_arid[0]),
	       .DMA_1_arlen	(cl_sh_pcim_arlen),
	       .DMA_1_arlock	(),
	       .DMA_1_arprot	(),
	       .DMA_1_arqos	(),
	       .DMA_1_arready	(sh_cl_pcim_arready),
	       .DMA_1_arregion	(),
	       .DMA_1_arsize	(cl_sh_pcim_arsize),
	       .DMA_1_arvalid	(cl_sh_pcim_arvalid),
	       .DMA_1_awaddr	(cl_sh_pcim_awaddr_out),
	       .DMA_1_awburst	(),
	       .DMA_1_awcache	(),
	       .DMA_1_awid	(cl_sh_pcim_awid[0]),
	       .DMA_1_awlen	(cl_sh_pcim_awlen),
	       .DMA_1_awlock	(),
	       .DMA_1_awprot	(),
	       .DMA_1_awqos	(),
	       .DMA_1_awready	(sh_cl_pcim_awready),
	       .DMA_1_awregion	(),
	       .DMA_1_awsize	(cl_sh_pcim_awsize),
	       .DMA_1_awvalid	(cl_sh_pcim_awvalid),
	       .DMA_1_bid       (sh_cl_pcim_bid[0]),
	       .DMA_1_bready	(cl_sh_pcim_bready),
	       .DMA_1_bresp	(sh_cl_pcim_bresp),
	       .DMA_1_bvalid	(sh_cl_pcim_bvalid),
	       .DMA_1_rdata	(sh_cl_pcim_rdata),
	       .DMA_1_rid	(sh_cl_pcim_rid[0]),
	       .DMA_1_rlast	(sh_cl_pcim_rlast),
	       .DMA_1_rready	(cl_sh_pcim_rready),
	       .DMA_1_rresp	(sh_cl_pcim_rresp),
	       .DMA_1_rvalid	(sh_cl_pcim_rvalid),
	       .DMA_1_wdata	(cl_sh_pcim_wdata),
	       .DMA_1_wlast	(cl_sh_pcim_wlast),
	       .DMA_1_wready	(sh_cl_pcim_wready),
	       .DMA_1_wstrb	(cl_sh_pcim_wstrb),
	       .DMA_1_wvalid	(cl_sh_pcim_wvalid),
	       .DMA_ACLK	(clk_main_a0),
	       .DMA_ARESETN	(rst_main_n_sync),
	       
	       .OCL_araddr	(sh_ocl_araddr_q),
	       .OCL_arprot	('0),
	       .OCL_arready	(ocl_sh_arready_q),
	       .OCL_arvalid	(sh_ocl_arvalid_q),
	       .OCL_awaddr	(sh_ocl_awaddr_q),
	       .OCL_awprot	('0),
	       .OCL_awready	(ocl_sh_awready_q),
	       .OCL_awvalid	(sh_ocl_awvalid_q),
	       .OCL_bready	(sh_ocl_bready_q),
	       .OCL_bresp	(ocl_sh_bresp_q),
	       .OCL_bvalid	(ocl_sh_bvalid_q),
	       .OCL_rdata	(ocl_sh_rdata_q),
	       .OCL_rready	(sh_ocl_rready_q),
	       .OCL_rresp	(ocl_sh_rresp_q),
	       .OCL_rvalid	(ocl_sh_rvalid_q),
	       .OCL_wdata	(sh_ocl_wdata_q),
	       .OCL_wready	(ocl_sh_wready_q),
	       .OCL_wstrb	(sh_ocl_wstrb_q),
	       .OCL_wvalid	(sh_ocl_wvalid_q),
	       
	       .DMA_PCIS_araddr		(sh_cl_dma_pcis_araddr),
	       .DMA_PCIS_arburst 	(2'b01),
	       .DMA_PCIS_arcache 	('d0),
	       .DMA_PCIS_arid		(sh_cl_dma_pcis_arid),
	       .DMA_PCIS_arlen		(sh_cl_dma_pcis_arlen),
	       .DMA_PCIS_arlock  	('d0),
	       .DMA_PCIS_arprot		('d0),
	       .DMA_PCIS_arqos		('d0),
	       .DMA_PCIS_arready	(cl_sh_dma_pcis_arready),
	       .DMA_PCIS_arsize		(sh_cl_dma_pcis_arsize),
	       .DMA_PCIS_arvalid	(sh_cl_dma_pcis_arvalid),
	       .DMA_PCIS_awaddr		(sh_cl_dma_pcis_awaddr),
	       .DMA_PCIS_awburst	(2'b01),
	       .DMA_PCIS_awcache 	('d0),
	       .DMA_PCIS_awid		(sh_cl_dma_pcis_awid),
	       .DMA_PCIS_awlen		(sh_cl_dma_pcis_awlen),
	       .DMA_PCIS_awlock		('d0),
	       .DMA_PCIS_awprot		('d0),
	       .DMA_PCIS_awqos		('d0),
	       .DMA_PCIS_awready	(cl_sh_dma_pcis_awready),
	       .DMA_PCIS_awsize		(sh_cl_dma_pcis_arsize),
	       .DMA_PCIS_awvalid 	(sh_cl_dma_pcis_awvalid),
	       .DMA_PCIS_bid		(cl_sh_dma_pcis_bid),
	       .DMA_PCIS_bready		(sh_cl_dma_pcis_bready),
	       .DMA_PCIS_bresp		(cl_sh_dma_pcis_bresp),
	       .DMA_PCIS_bvalid		(cl_sh_dma_pcis_bvalid),
	       .DMA_PCIS_rdata		(cl_sh_dma_pcis_rdata),
	       .DMA_PCIS_rid		(cl_sh_dma_pcis_rid),
	       .DMA_PCIS_rlast   	(ch_sh_dma_pcis_rlast),
	       .DMA_PCIS_rready		(sh_cl_dma_pcis_rready),
	       .DMA_PCIS_rresp		(cl_sh_dma_pcis_rresp),
	       .DMA_PCIS_rvalid		(cl_sh_dma_pcis_rvalid),
	       .DMA_PCIS_wdata		(sh_cl_dma_pcis_wdata),	       
	       .DMA_PCIS_wlast		(sh_cl_dma_pcis_wlast),
	       .DMA_PCIS_wready		(cl_sh_dma_pcis_wready),
	       .DMA_PCIS_wstrb		(sh_cl_dma_pcis_wstrb),
	       .DMA_PCIS_wvalid		(sh_cl_dma_pcis_wvalid),
	       .irq_o			(irq_o));
   assign cl_sh_apppf_irq_req = {15'b0,irq_o};
   
   ///////////////////////////////////////////////////////////////////////
   ///////////////// Scrubber enable and status //////////////////////////
   ///////////////////////////////////////////////////////////////////////
   
   
   axi_bus_t sh_cl_dma_pcis_bus();
   axi_bus_t sh_cl_dma_pcis_q();
   
   axi_bus_t cl_sh_pcim_bus();
   axi_bus_t cl_sh_ddr_bus();
   
   axi_bus_t sda_cl_bus();
   axi_bus_t sh_ocl_bus();
   
   cfg_bus_t pcim_tst_cfg_bus();
   cfg_bus_t ddra_tst_cfg_bus();
   cfg_bus_t ddrb_tst_cfg_bus();
   cfg_bus_t ddrc_tst_cfg_bus();
   cfg_bus_t ddrd_tst_cfg_bus();
   cfg_bus_t int_tst_cfg_bus();
   
   scrb_bus_t ddra_scrb_bus();
   scrb_bus_t ddrb_scrb_bus();
   scrb_bus_t ddrc_scrb_bus();
   scrb_bus_t ddrd_scrb_bus();
   
   // Bit 31: Debug enable (for cl_sh_id0 and cl_sh_id1)
   // Bit 30:28: Debug Scrb memory select
   
   // Bit 3 : DDRC Scrub enable
   // Bit 2 : DDRD Scrub enable
   // Bit 1 : DDRB Scrub enable
   // Bit 0 : DDRA Scrub enable
   logic [3:0] 	all_ddr_scrb_done;
   logic [3:0] 	all_ddr_is_ready;
   logic [2:0] 	lcl_sh_cl_ddr_is_ready;
   
   logic 	dbg_scrb_en;
   logic [2:0] 	dbg_scrb_mem_sel;
   logic [31:0] sh_cl_ctl0_q;
   always_ff @(posedge clk_main_a0 or negedge sync_rst_n)
     if (!sync_rst_n)
       sh_cl_ctl0_q <= 32'd0;
     else
       sh_cl_ctl0_q <= sh_cl_ctl0;
   
   assign ddra_scrb_bus.enable = sh_cl_ctl0_q[0];
   assign ddrb_scrb_bus.enable = sh_cl_ctl0_q[1];
   assign ddrd_scrb_bus.enable = sh_cl_ctl0_q[2];
   assign ddrc_scrb_bus.enable = sh_cl_ctl0_q[3];
   

   assign dbg_scrb_en = sh_cl_ctl0_q[31];
   assign dbg_scrb_mem_sel[2:0] = sh_cl_ctl0_q[30:28];
   
`ifndef CL_VERSION
 `define CL_VERSION 32'hee_ee_ee_00
`endif  
   
   always_ff @(posedge clk_main_a0)
     cl_sh_status0 <= dbg_scrb_en ? {1'b0, ddrc_scrb_bus.state, 
                                     1'b0, ddrd_scrb_bus.state, 
                                     1'b0, ddrb_scrb_bus.state, 
                                     1'b0, ddra_scrb_bus.state,
                                     4'b0, 4'hf, all_ddr_scrb_done, all_ddr_is_ready} :
                      {20'ha111_1, 4'hf, all_ddr_scrb_done, all_ddr_is_ready};
   assign cl_sh_status1 = `CL_VERSION;
   
   
   always_ff @(posedge clk_main_a0)
     cl_sh_id0 <= dbg_scrb_en ? (dbg_scrb_mem_sel == 3'd3 ? ddrc_scrb_bus.addr[31:0] :
                                 dbg_scrb_mem_sel == 3'd2 ? ddrd_scrb_bus.addr[31:0] :
                                 dbg_scrb_mem_sel == 3'd1 ? ddrb_scrb_bus.addr[31:0] : ddra_scrb_bus.addr[31:0]) :
                  `CL_SH_ID0; 
   always_ff @(posedge clk_main_a0)
     cl_sh_id1 <= dbg_scrb_en ? (dbg_scrb_mem_sel == 3'd3 ? ddrc_scrb_bus.addr[63:32] :
                                 dbg_scrb_mem_sel == 3'd2 ? ddrd_scrb_bus.addr[63:32] :
                                 dbg_scrb_mem_sel == 3'd1 ? ddrb_scrb_bus.addr[63:32] : ddra_scrb_bus.addr[63:32]) :
                  `CL_SH_ID1;
   
   logic 	sh_cl_ddr_is_ready_q;
   always_ff @(posedge clk_main_a0 or negedge sync_rst_n)
     if (!sync_rst_n) begin
	  sh_cl_ddr_is_ready_q <= 1'b0;
     end else begin
	sh_cl_ddr_is_ready_q <= sh_cl_ddr_is_ready;
     end  
   
   assign all_ddr_is_ready = {lcl_sh_cl_ddr_is_ready[2], sh_cl_ddr_is_ready_q, lcl_sh_cl_ddr_is_ready[1:0]};
   
   assign all_ddr_scrb_done = {ddrc_scrb_bus.done, ddrd_scrb_bus.done, ddrb_scrb_bus.done, ddra_scrb_bus.done};
   
   
   
   //----------------------------------------- 
   // DDR controller instantiation   
   //-----------------------------------------
   logic [7:0] sh_ddr_stat_addr_q[2:0];
   logic [2:0] sh_ddr_stat_wr_q;
   logic [2:0] sh_ddr_stat_rd_q; 
   logic [31:0] sh_ddr_stat_wdata_q[2:0];
   logic [2:0] 	ddr_sh_stat_ack_q;
   logic [31:0] ddr_sh_stat_rdata_q[2:0];
   logic [7:0] 	ddr_sh_stat_int_q[2:0];
   
   
   lib_pipe #(.WIDTH(1+1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT0 (.clk(clk_main_a0), .rst_n(sync_rst_n),
										  .in_bus({sh_ddr_stat_wr0, sh_ddr_stat_rd0, sh_ddr_stat_addr0, sh_ddr_stat_wdata0}),
										  .out_bus({sh_ddr_stat_wr_q[0], sh_ddr_stat_rd_q[0], sh_ddr_stat_addr_q[0], sh_ddr_stat_wdata_q[0]})
										  );
   
   
   lib_pipe #(.WIDTH(1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT_ACK0 (.clk(clk_main_a0), .rst_n(sync_rst_n),
										    .in_bus({ddr_sh_stat_ack_q[0], ddr_sh_stat_int_q[0], ddr_sh_stat_rdata_q[0]}),
										    .out_bus({ddr_sh_stat_ack0, ddr_sh_stat_int0, ddr_sh_stat_rdata0})
										    );
   
   
   lib_pipe #(.WIDTH(1+1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT1 (.clk(clk_main_a0), .rst_n(sync_rst_n),
										  .in_bus({sh_ddr_stat_wr1, sh_ddr_stat_rd1, sh_ddr_stat_addr1, sh_ddr_stat_wdata1}),
										  .out_bus({sh_ddr_stat_wr_q[1], sh_ddr_stat_rd_q[1], sh_ddr_stat_addr_q[1], sh_ddr_stat_wdata_q[1]})
										  );
   
   
   lib_pipe #(.WIDTH(1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT_ACK1 (.clk(clk_main_a0), .rst_n(sync_rst_n),
										    .in_bus({ddr_sh_stat_ack_q[1], ddr_sh_stat_int_q[1], ddr_sh_stat_rdata_q[1]}),
										    .out_bus({ddr_sh_stat_ack1, ddr_sh_stat_int1, ddr_sh_stat_rdata1})
										    );
   
   lib_pipe #(.WIDTH(1+1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT2 (.clk(clk_main_a0), .rst_n(sync_rst_n),
										  .in_bus({sh_ddr_stat_wr2, sh_ddr_stat_rd2, sh_ddr_stat_addr2, sh_ddr_stat_wdata2}),
										  .out_bus({sh_ddr_stat_wr_q[2], sh_ddr_stat_rd_q[2], sh_ddr_stat_addr_q[2], sh_ddr_stat_wdata_q[2]})
										  );
   
   
   lib_pipe #(.WIDTH(1+8+32), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_DDR_STAT_ACK2 (.clk(clk_main_a0), .rst_n(sync_rst_n),
										    .in_bus({ddr_sh_stat_ack_q[2], ddr_sh_stat_int_q[2], ddr_sh_stat_rdata_q[2]}),
										    .out_bus({ddr_sh_stat_ack2, ddr_sh_stat_int2, ddr_sh_stat_rdata2})
										    ); 
   
   //convert to 2D 
   logic [15:0] cl_sh_ddr_awid_2d[2:0];
   logic [63:0] cl_sh_ddr_awaddr_2d[2:0];
   logic [7:0] 	cl_sh_ddr_awlen_2d[2:0];
   logic [2:0] 	cl_sh_ddr_awsize_2d[2:0];
   logic 	cl_sh_ddr_awvalid_2d [2:0];
   logic [2:0] 	sh_cl_ddr_awready_2d;
   
   logic [15:0] cl_sh_ddr_wid_2d[2:0];
   logic [511:0] cl_sh_ddr_wdata_2d[2:0];
   logic [63:0]  cl_sh_ddr_wstrb_2d[2:0];
   logic [2:0] 	 cl_sh_ddr_wlast_2d;
   logic [2:0] 	 cl_sh_ddr_wvalid_2d;
   logic [2:0] 	 sh_cl_ddr_wready_2d;
   
   logic [15:0]  sh_cl_ddr_bid_2d[2:0];
   logic [1:0] 	 sh_cl_ddr_bresp_2d[2:0];
   logic [2:0] 	 sh_cl_ddr_bvalid_2d;
   logic [2:0] 	 cl_sh_ddr_bready_2d;
   
   logic [15:0]  cl_sh_ddr_arid_2d[2:0];
   logic [63:0]  cl_sh_ddr_araddr_2d[2:0];
   logic [7:0] 	 cl_sh_ddr_arlen_2d[2:0];
   logic [2:0] 	 cl_sh_ddr_arsize_2d[2:0];
   logic [2:0] 	 cl_sh_ddr_arvalid_2d;
   logic [2:0] 	 sh_cl_ddr_arready_2d;
   
   logic [15:0]  sh_cl_ddr_rid_2d[2:0];
   logic [511:0] sh_cl_ddr_rdata_2d[2:0];
   logic [1:0] 	 sh_cl_ddr_rresp_2d[2:0];
   logic [2:0] 	 sh_cl_ddr_rlast_2d;
   logic [2:0] 	 sh_cl_ddr_rvalid_2d;
   logic [2:0] 	 cl_sh_ddr_rready_2d;
   
   assign cl_sh_ddr_awid_2d 	= '{lcl_cl_sh_ddrd.awid, lcl_cl_sh_ddrb.awid, lcl_cl_sh_ddra.awid};
   assign cl_sh_ddr_awaddr_2d 	= '{lcl_cl_sh_ddrd.awaddr, lcl_cl_sh_ddrb.awaddr, lcl_cl_sh_ddra.awaddr};
   assign cl_sh_ddr_awlen_2d 	= '{lcl_cl_sh_ddrd.awlen, lcl_cl_sh_ddrb.awlen, lcl_cl_sh_ddra.awlen};
   assign cl_sh_ddr_awsize_2d 	= '{lcl_cl_sh_ddrd.awsize, lcl_cl_sh_ddrb.awsize, lcl_cl_sh_ddra.awsize};
   assign cl_sh_ddr_awvalid_2d 	= '{lcl_cl_sh_ddrd.awvalid, lcl_cl_sh_ddrb.awvalid, lcl_cl_sh_ddra.awvalid};
   assign {lcl_cl_sh_ddrd.awready, lcl_cl_sh_ddrb.awready, lcl_cl_sh_ddra.awready} = sh_cl_ddr_awready_2d;
   
   assign cl_sh_ddr_wid_2d 	= '{lcl_cl_sh_ddrd.wid, lcl_cl_sh_ddrb.wid, lcl_cl_sh_ddra.wid};
   assign cl_sh_ddr_wdata_2d 	= '{lcl_cl_sh_ddrd.wdata, lcl_cl_sh_ddrb.wdata, lcl_cl_sh_ddra.wdata};
   assign cl_sh_ddr_wstrb_2d 	= '{lcl_cl_sh_ddrd.wstrb, lcl_cl_sh_ddrb.wstrb, lcl_cl_sh_ddra.wstrb};
   assign cl_sh_ddr_wlast_2d 	= {lcl_cl_sh_ddrd.wlast, lcl_cl_sh_ddrb.wlast, lcl_cl_sh_ddra.wlast};
   assign cl_sh_ddr_wvalid_2d 	= {lcl_cl_sh_ddrd.wvalid, lcl_cl_sh_ddrb.wvalid, lcl_cl_sh_ddra.wvalid};
   assign {lcl_cl_sh_ddrd.wready, lcl_cl_sh_ddrb.wready, lcl_cl_sh_ddra.wready} = sh_cl_ddr_wready_2d;
   
   assign {lcl_cl_sh_ddrd.bid, lcl_cl_sh_ddrb.bid, lcl_cl_sh_ddra.bid} 		= {sh_cl_ddr_bid_2d[2], sh_cl_ddr_bid_2d[1], sh_cl_ddr_bid_2d[0]};
   assign {lcl_cl_sh_ddrd.bresp, lcl_cl_sh_ddrb.bresp, lcl_cl_sh_ddra.bresp} 	= {sh_cl_ddr_bresp_2d[2], sh_cl_ddr_bresp_2d[1], sh_cl_ddr_bresp_2d[0]};
   assign {lcl_cl_sh_ddrd.bvalid, lcl_cl_sh_ddrb.bvalid, lcl_cl_sh_ddra.bvalid} = sh_cl_ddr_bvalid_2d;
   assign cl_sh_ddr_bready_2d = {lcl_cl_sh_ddrd.bready, lcl_cl_sh_ddrb.bready, lcl_cl_sh_ddra.bready};
   
   assign cl_sh_ddr_arid_2d 	= '{lcl_cl_sh_ddrd.arid, lcl_cl_sh_ddrb.arid, lcl_cl_sh_ddra.arid};
   assign cl_sh_ddr_araddr_2d 	= '{lcl_cl_sh_ddrd.araddr, lcl_cl_sh_ddrb.araddr, lcl_cl_sh_ddra.araddr};
   assign cl_sh_ddr_arlen_2d 	= '{lcl_cl_sh_ddrd.arlen, lcl_cl_sh_ddrb.arlen, lcl_cl_sh_ddra.arlen};
   assign cl_sh_ddr_arsize_2d 	= '{lcl_cl_sh_ddrd.arsize, lcl_cl_sh_ddrb.arsize, lcl_cl_sh_ddra.arsize};
   assign cl_sh_ddr_arvalid_2d 	= {lcl_cl_sh_ddrd.arvalid, lcl_cl_sh_ddrb.arvalid, lcl_cl_sh_ddra.arvalid};
   assign {lcl_cl_sh_ddrd.arready, lcl_cl_sh_ddrb.arready, lcl_cl_sh_ddra.arready} = sh_cl_ddr_arready_2d;
   
   assign {lcl_cl_sh_ddrd.rid, lcl_cl_sh_ddrb.rid, lcl_cl_sh_ddra.rid} 		= {sh_cl_ddr_rid_2d[2], sh_cl_ddr_rid_2d[1], sh_cl_ddr_rid_2d[0]};
   assign {lcl_cl_sh_ddrd.rresp, lcl_cl_sh_ddrb.rresp, lcl_cl_sh_ddra.rresp} 	= {sh_cl_ddr_rresp_2d[2], sh_cl_ddr_rresp_2d[1], sh_cl_ddr_rresp_2d[0]};
   assign {lcl_cl_sh_ddrd.rdata, lcl_cl_sh_ddrb.rdata, lcl_cl_sh_ddra.rdata} 	= {sh_cl_ddr_rdata_2d[2], sh_cl_ddr_rdata_2d[1], sh_cl_ddr_rdata_2d[0]};
   assign {lcl_cl_sh_ddrd.rlast, lcl_cl_sh_ddrb.rlast, lcl_cl_sh_ddra.rlast} 	= sh_cl_ddr_rlast_2d;
   assign {lcl_cl_sh_ddrd.rvalid, lcl_cl_sh_ddrb.rvalid, lcl_cl_sh_ddra.rvalid} = sh_cl_ddr_rvalid_2d;
   assign cl_sh_ddr_rready_2d = {lcl_cl_sh_ddrd.rready, lcl_cl_sh_ddrb.rready, lcl_cl_sh_ddra.rready};
   
   logic 	 sh_ddr_sync_rst_n;
   lib_pipe #(.WIDTH(1), .STAGES(4)) SH_DDR_SLC_RST_N (.clk(clk_main_a0), .rst_n(1'b1), .in_bus(sync_rst_n), .out_bus(sh_ddr_sync_rst_n));
   sh_ddr #(
            .DDR_A_PRESENT(DDR_A_PRESENT),
            .DDR_A_IO(1),
            .DDR_B_PRESENT(DDR_B_PRESENT),
            .DDR_D_PRESENT(DDR_D_PRESENT)
	    ) SH_DDR
     (
      .clk		(clk_main_a0),
      .rst_n		(sh_ddr_sync_rst_n),
      
      .stat_clk		(clk_main_a0),
      .stat_rst_n	(sh_ddr_sync_rst_n),
      
      
      .CLK_300M_DIMM0_DP(CLK_300M_DIMM0_DP),
      .CLK_300M_DIMM0_DN(CLK_300M_DIMM0_DN),
      .M_A_ACT_N	(M_A_ACT_N),
      .M_A_MA		(M_A_MA),
      .M_A_BA		(M_A_BA),
      .M_A_BG		(M_A_BG),
      .M_A_CKE		(M_A_CKE),
      .M_A_ODT		(M_A_ODT),
      .M_A_CS_N		(M_A_CS_N),
      .M_A_CLK_DN	(M_A_CLK_DN),
      .M_A_CLK_DP	(M_A_CLK_DP),
      .M_A_PAR		(M_A_PAR),
      .M_A_DQ		(M_A_DQ),
      .M_A_ECC		(M_A_ECC),
      .M_A_DQS_DP	(M_A_DQS_DP),
      .M_A_DQS_DN	(M_A_DQS_DN),
      .cl_RST_DIMM_A_N	(cl_RST_DIMM_A_N),
      
      
      .CLK_300M_DIMM1_DP(CLK_300M_DIMM1_DP),
      .CLK_300M_DIMM1_DN(CLK_300M_DIMM1_DN),
      .M_B_ACT_N	(M_B_ACT_N),
      .M_B_MA		(M_B_MA),
      .M_B_BA		(M_B_BA),
      .M_B_BG		(M_B_BG),
      .M_B_CKE		(M_B_CKE),
      .M_B_ODT		(M_B_ODT),
      .M_B_CS_N		(M_B_CS_N),
      .M_B_CLK_DN	(M_B_CLK_DN),
      .M_B_CLK_DP	(M_B_CLK_DP),
      .M_B_PAR		(M_B_PAR),
      .M_B_DQ		(M_B_DQ),
      .M_B_ECC		(M_B_ECC),
      .M_B_DQS_DP	(M_B_DQS_DP),
      .M_B_DQS_DN	(M_B_DQS_DN),
      .cl_RST_DIMM_B_N	(cl_RST_DIMM_B_N),
      
      .CLK_300M_DIMM3_DP(CLK_300M_DIMM3_DP),
      .CLK_300M_DIMM3_DN(CLK_300M_DIMM3_DN),
      .M_D_ACT_N	(M_D_ACT_N),
      .M_D_MA		(M_D_MA),
      .M_D_BA		(M_D_BA),
      .M_D_BG		(M_D_BG),
      .M_D_CKE		(M_D_CKE),
      .M_D_ODT		(M_D_ODT),
      .M_D_CS_N		(M_D_CS_N),
      .M_D_CLK_DN	(M_D_CLK_DN),
      .M_D_CLK_DP	(M_D_CLK_DP),
      .M_D_PAR		(M_D_PAR),
      .M_D_DQ		(M_D_DQ),
      .M_D_ECC		(M_D_ECC),
      .M_D_DQS_DP	(M_D_DQS_DP),
      .M_D_DQS_DN	(M_D_DQS_DN),
      .cl_RST_DIMM_D_N	(cl_RST_DIMM_D_N),
      
      //------------------------------------------------------
      // DDR-4 Interface from CL (AXI-4)
      //------------------------------------------------------
      .cl_sh_ddr_awid	(cl_sh_ddr_awid_2d),
      .cl_sh_ddr_awaddr	(cl_sh_ddr_awaddr_2d),
      .cl_sh_ddr_awlen	(cl_sh_ddr_awlen_2d),
      .cl_sh_ddr_awsize	(cl_sh_ddr_awsize_2d),
      .cl_sh_ddr_awvalid(cl_sh_ddr_awvalid_2d),
      .sh_cl_ddr_awready(sh_cl_ddr_awready_2d),
      
      .cl_sh_ddr_wid	(cl_sh_ddr_wid_2d),
      .cl_sh_ddr_wdata	(cl_sh_ddr_wdata_2d),
      .cl_sh_ddr_wstrb	(cl_sh_ddr_wstrb_2d),
      .cl_sh_ddr_wlast	(cl_sh_ddr_wlast_2d),
      .cl_sh_ddr_wvalid	(cl_sh_ddr_wvalid_2d),
      .sh_cl_ddr_wready	(sh_cl_ddr_wready_2d),
      
      .sh_cl_ddr_bid	(sh_cl_ddr_bid_2d),
      .sh_cl_ddr_bresp	(sh_cl_ddr_bresp_2d),
      .sh_cl_ddr_bvalid	(sh_cl_ddr_bvalid_2d),
      .cl_sh_ddr_bready	(cl_sh_ddr_bready_2d),
      
      .cl_sh_ddr_arid	(cl_sh_ddr_arid_2d),
      .cl_sh_ddr_araddr	(cl_sh_ddr_araddr_2d),
      .cl_sh_ddr_arlen	(cl_sh_ddr_arlen_2d),
      .cl_sh_ddr_arsize	(cl_sh_ddr_arsize_2d),
      .cl_sh_ddr_arvalid(cl_sh_ddr_arvalid_2d),
      .sh_cl_ddr_arready(sh_cl_ddr_arready_2d),
      
      .sh_cl_ddr_rid	(sh_cl_ddr_rid_2d),
      .sh_cl_ddr_rdata	(sh_cl_ddr_rdata_2d),
      .sh_cl_ddr_rresp	(sh_cl_ddr_rresp_2d),
      .sh_cl_ddr_rlast	(sh_cl_ddr_rlast_2d),
      .sh_cl_ddr_rvalid	(sh_cl_ddr_rvalid_2d),
      .cl_sh_ddr_rready	(cl_sh_ddr_rready_2d),
      
      .sh_cl_ddr_is_ready(lcl_sh_cl_ddr_is_ready),
      
      .sh_ddr_stat_addr0  (sh_ddr_stat_addr_q[0]) ,
      .sh_ddr_stat_wr0    (sh_ddr_stat_wr_q[0]     ) , 
      .sh_ddr_stat_rd0    (sh_ddr_stat_rd_q[0]     ) , 
      .sh_ddr_stat_wdata0 (sh_ddr_stat_wdata_q[0]  ) , 
      .ddr_sh_stat_ack0   (ddr_sh_stat_ack_q[0]    ) ,
      .ddr_sh_stat_rdata0 (ddr_sh_stat_rdata_q[0]  ),
      .ddr_sh_stat_int0   (ddr_sh_stat_int_q[0]    ),
      
      .sh_ddr_stat_addr1  (sh_ddr_stat_addr_q[1]) ,
      .sh_ddr_stat_wr1    (sh_ddr_stat_wr_q[1]     ) , 
      .sh_ddr_stat_rd1    (sh_ddr_stat_rd_q[1]     ) , 
      .sh_ddr_stat_wdata1 (sh_ddr_stat_wdata_q[1]  ) , 
      .ddr_sh_stat_ack1   (ddr_sh_stat_ack_q[1]    ) ,
      .ddr_sh_stat_rdata1 (ddr_sh_stat_rdata_q[1]  ),
      .ddr_sh_stat_int1   (ddr_sh_stat_int_q[1]    ),
      
      .sh_ddr_stat_addr2  (sh_ddr_stat_addr_q[2]) ,
      .sh_ddr_stat_wr2    (sh_ddr_stat_wr_q[2]     ) , 
      .sh_ddr_stat_rd2    (sh_ddr_stat_rd_q[2]     ) , 
      .sh_ddr_stat_wdata2 (sh_ddr_stat_wdata_q[2]  ) , 
      .ddr_sh_stat_ack2   (ddr_sh_stat_ack_q[2]    ) ,
      .ddr_sh_stat_rdata2 (ddr_sh_stat_rdata_q[2]  ),
      .ddr_sh_stat_int2   (ddr_sh_stat_int_q[2]    ) 
      );
   
   //-------------------------------------------
   // Tie-Off Global Signals
   //-------------------------------------------
`ifndef CL_VERSION
 `define CL_VERSION 32'hee_ee_ee_00
`endif  
   
   
   //assign cl_sh_status0[31:0] =  32'h0000_0FF0;
   //assign cl_sh_status1[31:0] = `CL_VERSION;
   
   //-----------------------------------------------
   // Debug bridge, used if need chipscope
   //-----------------------------------------------
`ifndef DISABLE_CHIPSCOPE_DEBUG
   
   // Flop for timing global clock counter
   logic[63:0] sh_cl_glcount0_q;
   
   always_ff @(posedge clk_main_a0)
     if (!rst_main_n_sync)
       sh_cl_glcount0_q <= 0;
     else
       sh_cl_glcount0_q <= sh_cl_glcount0;
   
   
   // Integrated Logic Analyzers (ILA)
   ila_0 CL_ILA_0 (
                   .clk    (clk_main_a0),
                   .probe0 (lcl_sh_cl_ddr_is_ready[0]),
                   .probe1 (sh_ocl_awaddr_q ),
                   .probe2 (lcl_sh_cl_ddr_is_ready[1]),
                   .probe3 (lcl_sh_cl_ddr_is_ready[2]),
                   .probe4 (sh_ocl_araddr_q),
                   .probe5 (lcl_cl_sh_ddra.awready)
                   );
   
   ila_0 CL_ILA_1 (
                   .clk    (clk_main_a0),
                   .probe0 (irq_o),
                   .probe1 ({sh_cl_apppf_irq_ack,cl_sh_apppf_irq_req}),
                   .probe2 (sh_cl_pcim_awready),
                   .probe3 (cl_sh_pcim_arvalid),
                   .probe4 (cl_sh_pcim_araddr),
                   .probe5 (sh_cl_pcim_arready)
                   );
   ila_1 CL_ILA_2 (.clk    (clk_main_a0),
		   .probe0 (cl_sh_dma_pcis_wready),
		   .probe1 (sh_cl_dma_pcis_awaddr),
		   .probe2 (cl_sh_dma_pcis_bresp),
		   .probe3 (cl_sh_dma_pcis_bvalid),
		   .probe4 (sh_cl_dma_pcis_bready),
		   .probe5 (sh_cl_dma_pcis_araddr),
		   .probe6 (sh_cl_dma_pcis_rready),
		   .probe7 (sh_cl_dma_pcis_wvalid),
		   .probe8 (cl_sh_dma_pcis_rvalid),
		   .probe9 (cl_sh_dma_pcis_arready),
		   .probe10(cl_sh_dma_pcis_rdata),
		   .probe11(sh_cl_dma_pcis_awvalid),
		   .probe12(cl_sh_dma_pcis_awready),
		   .probe13(cl_sh_dma_pcis_rresp),
		   .probe14(sh_cl_dma_pcis_wdata),
		   .probe15(sh_cl_dma_pcis_wstrb),
		   .probe16(sh_cl_dma_pcis_arvalid),
		   .probe17('d0),
		   .probe18('d0),
		   .probe19(sh_cl_dma_pcis_awid),
		   .probe20(cl_sh_dma_pcis_bid),
		   .probe21(sh_cl_dma_pcis_awlen),
		   .probe22('d0),
		   .probe23(sh_cl_dma_pcis_awsize),
		   .probe24('d0),
		   .probe25(sh_cl_dma_pcis_arid),
		   .probe26('d0),
		   .probe27(sh_cl_dma_pcis_arlen),
		   .probe28(sh_cl_dma_pcis_arsize),
		   .probe29('d0),
		   .probe30('d0),
		   .probe31('d0),
		   .probe32('d0),
		   .probe33('d0),
		   .probe34('d0),
		   .probe35('d0),
		   .probe36('d0),
		   .probe37('d0),
		   .probe38(cl_sh_dma_pcis_rid),
		   .probe39('d0),
		   .probe40('d0),
		   .probe41(cl_sh_dma_pcis_rlast),
		   .probe42('d0),
		   .probe43(sh_cl_dma_pcis_wlast));
   
   ila_1 CL_ILA_3 (.clk    (clk_main_a0),
		   .probe0 (lcl_cl_sh_ddra.wready),
		   .probe1 (lcl_cl_sh_ddra.awaddr),
		   .probe2 (lcl_cl_sh_ddra.bresp),
		   .probe3 (lcl_cl_sh_ddra.bvalid),
		   .probe4 (lcl_cl_sh_ddra.bready),
		   .probe5 (lcl_cl_sh_ddra.araddr),
		   .probe6 (lcl_cl_sh_ddra.rready),
		   .probe7 (lcl_cl_sh_ddra.wvalid),
		   .probe8 (lcl_cl_sh_ddra.rvalid),
		   .probe9 (lcl_cl_sh_ddra.arready),
		   .probe10(lcl_cl_sh_ddra.rdata),
		   .probe11(lcl_cl_sh_ddra.awvalid),
		   .probe12(lcl_cl_sh_ddra.awready),
		   .probe13(lcl_cl_sh_ddra.rresp),
		   .probe14(lcl_cl_sh_ddra.wdata),
		   .probe15(lcl_cl_sh_ddra.wstrb),
		   .probe16(lcl_cl_sh_ddra.arvalid),
		   .probe17('d0),
		   .probe18('d0),
		   .probe19(lcl_cl_sh_ddra.awid),
		   .probe20(lcl_cl_sh_ddra.bid),
		   .probe21(lcl_cl_sh_ddra.awlen),
		   .probe22('d0),
		   .probe23(lcl_cl_sh_ddra.awsize),
		   .probe24('d0),
		   .probe25(lcl_cl_sh_ddra.arid),
		   .probe26('d0),
		   .probe27(lcl_cl_sh_ddra.arlen),
		   .probe28(lcl_cl_sh_ddra.arsize),
		   .probe29('d0),
		   .probe30('d0),
		   .probe31('d0),
		   .probe32('d0),
		   .probe33('d0),
		   .probe34('d0),
		   .probe35('d0),
		   .probe36('d0),
		   .probe37('d0),
		   .probe38(lcl_cl_sh_ddra.rid),
		   .probe39('d0),
		   .probe40('d0),
		   .probe41(lcl_cl_sh_ddra.rlast),
		   .probe42('d0),
		   .probe43(lcl_cl_sh_ddra.wlast));
		   
   // Debug Bridge 
 cl_debug_bridge CL_DEBUG_BRIDGE (
      .clk(clk_main_a0),
      .S_BSCAN_VEC_drck(drck),
      .S_BSCAN_VEC_shift(shift),
      .S_BSCAN_VEC_tdi(tdi),
      .S_BSCAN_VEC_update(update),
      .S_BSCAN_VEC_sel(sel),
      .S_BSCAN_VEC_tdo(tdo),
      .S_BSCAN_VEC_tms(tms),
      .S_BSCAN_VEC_tck(tck),
      .S_BSCAN_VEC_runtest(runtest),
      .S_BSCAN_VEC_reset(reset),
      .S_BSCAN_VEC_capture(capture),
      .S_BSCAN_VEC_bscanid(bscanid)
   );
   //-----------------------------------------------
   // VIO Example - Needs Chipscope
   //-----------------------------------------------
   // Counter running at 125MHz
   
   logic       vo_cnt_enable;
   logic       vo_cnt_load;
   logic       vo_cnt_clear;
   logic       vo_cnt_oneshot;
   logic [7:0] vo_tick_value;
   logic [15:0] vo_cnt_load_value;
   logic [15:0] vo_cnt_watermark;
   
   logic 	vo_cnt_enable_q = 0;
   logic 	vo_cnt_load_q = 0;
   logic 	vo_cnt_clear_q = 0;
   logic 	vo_cnt_oneshot_q = 0;
   logic [7:0] 	vo_tick_value_q = 0;
   logic [15:0] vo_cnt_load_value_q = 0;
   logic [15:0] vo_cnt_watermark_q = 0;
   
   logic        vi_tick;
   logic        vi_cnt_ge_watermark;
   logic [7:0] 	vi_tick_cnt = 0;
   logic [15:0] vi_cnt = 0;
   
   // Tick counter and main counter
   always @(posedge clk_extra_a1) begin
      
      vo_cnt_enable_q     <= vo_cnt_enable    ;
      vo_cnt_load_q       <= vo_cnt_load      ;
      vo_cnt_clear_q      <= vo_cnt_clear     ;
      vo_cnt_oneshot_q    <= vo_cnt_oneshot   ;
      vo_tick_value_q     <= vo_tick_value    ;
      vo_cnt_load_value_q <= vo_cnt_load_value;
      vo_cnt_watermark_q  <= vo_cnt_watermark ;
      
      vi_tick_cnt = vo_cnt_clear_q ? 0 :
                    ~vo_cnt_enable_q ? vi_tick_cnt :
                    (vi_tick_cnt >= vo_tick_value_q) ? 0 :
                    vi_tick_cnt + 1;
      
      vi_cnt = vo_cnt_clear_q ? 0 :
               vo_cnt_load_q ? vo_cnt_load_value_q :
               ~vo_cnt_enable_q ? vi_cnt :
               (vi_tick_cnt >= vo_tick_value_q) && (~vo_cnt_oneshot_q || (vi_cnt <= 16'hFFFF)) ? vi_cnt + 1 :
               vi_cnt;
      
      vi_tick = (vi_tick_cnt >= vo_tick_value_q);
      
      vi_cnt_ge_watermark = (vi_cnt >= vo_cnt_watermark_q);
      
   end // always @ (posedge clk_extra_a1)
   
   
   vio_0 CL_VIO_0 (
                   .clk    (clk_main_a0),
                   .probe_in0  (vi_tick),
                   .probe_in1  (vi_cnt_ge_watermark),
                   .probe_in2  (vi_tick_cnt),
                   .probe_in3  (vi_cnt),
                   .probe_out0 (vo_cnt_enable),
                   .probe_out1 (vo_cnt_load),
                   .probe_out2 (vo_cnt_clear),
                   .probe_out3 (vo_cnt_oneshot),
                   .probe_out4 (vo_tick_value),
                   .probe_out5 (vo_cnt_load_value),
                   .probe_out6 (vo_cnt_watermark)
                   );
   
   ila_vio_counter CL_VIO_ILA (
			       .clk     (clk_main_a0),
			       .probe0  (vi_tick),
			       .probe1  (vi_cnt_ge_watermark),
			       .probe2  (vi_tick_cnt),
			       .probe3  (vi_cnt),
			       .probe4  (vo_cnt_enable_q),
			       .probe5  (vo_cnt_load_q),
			       .probe6  (vo_cnt_clear_q),
			       .probe7  (vo_cnt_oneshot_q),
			       .probe8  (vo_tick_value_q),
			       .probe9  (vo_cnt_load_value_q),
			       .probe10 (vo_cnt_watermark_q)
			       );
   
`endif //  `ifndef DISABLE_CHIPSCOPE_DEBUG

endmodule





