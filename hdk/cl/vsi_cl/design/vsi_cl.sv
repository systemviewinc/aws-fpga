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

`include "unused_flr_template.inc"
`include "unused_ddr_a_b_d_template.inc"
`include "unused_ddr_c_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_hmc_template.inc"
`include "unused_aurora_template.inc"
`include "unused_sh_bar1_template.inc"
   
   
   //-------------------------------------------------
   // ID Values (cl_hello_world_defines.vh)
   //-------------------------------------------------
   assign cl_sh_id0[31:0] = `CL_SH_ID0;
   assign cl_sh_id1[31:0] = `CL_SH_ID1;
   
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
//-------------------------------------------------
// instantiate design generated by VSI
//-------------------------------------------------
   wire [63:0] cl_sh_pcim_araddr_out;
   wire [63:0] cl_sh_pcim_awaddr_out;
   wire [31:0] gpio_tri_o;
   wire        irq_o;
   // need to chop the upper bits
   assign cl_sh_pcim_araddr = {32'b0,cl_sh_pcim_araddr_out[31:0]}; 
   assign cl_sh_pcim_awaddr = {32'b0,cl_sh_pcim_awaddr_out[31:0]};
   
   aws_fpga_wrapper 
     aws_fpga (.DMA_1_araddr	(cl_sh_pcim_araddr_out),
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
	       
	       .S_AXI_1_araddr	(sh_ocl_araddr_q),
	       .S_AXI_1_arprot	('0),
	       .S_AXI_1_arready	(ocl_sh_arready_q),
	       .S_AXI_1_arvalid	(sh_ocl_arvalid_q),
	       .S_AXI_1_awaddr	(sh_ocl_awaddr_q),
	       .S_AXI_1_awprot	('0),
	       .S_AXI_1_awready	(ocl_sh_awready_q),
	       .S_AXI_1_awvalid	(sh_ocl_awvalid_q),
	       .S_AXI_1_bready	(sh_ocl_bready_q),
	       .S_AXI_1_bresp	(ocl_sh_bresp_q),
	       .S_AXI_1_bvalid	(ocl_sh_bvalid_q),
	       .S_AXI_1_rdata	(ocl_sh_rdata_q),
	       .S_AXI_1_rready	(sh_ocl_rready_q),
	       .S_AXI_1_rresp	(ocl_sh_rresp_q),
	       .S_AXI_1_rvalid	(ocl_sh_rvalid_q),
	       .S_AXI_1_wdata	(sh_ocl_wdata_q),
	       .S_AXI_1_wready	(ocl_sh_wready_q),
	       .S_AXI_1_wstrb	(sh_ocl_wstrb_q),
	       .S_AXI_1_wvalid	(sh_ocl_wvalid_q),
	       
	       .S_AXI_2_araddr	(sh_cl_dma_pcis_araddr),
	       .S_AXI_2_arburst (2'b01),
	       .S_AXI_2_arcache ('d0),
	       .S_AXI_2_arid	(sh_cl_dma_pcis_arid),
	       .S_AXI_2_arlen	(sh_cl_dma_pcis_arlen),
	       .S_AXI_2_arlock  ('d0),
	       .S_AXI_2_arprot	('d0),
	       .S_AXI_2_arqos	('d0),
	       .S_AXI_2_arready	(cl_sh_dma_pcis_arready),
	       .S_AXI_2_arsize	(sh_cl_dma_pcis_arsize),
	       .S_AXI_2_arvalid	(sh_cl_dma_pcis_arvalid),
	       .S_AXI_2_awaddr	(sh_cl_dma_pcis_awaddr),
	       .S_AXI_2_awburst	(2'b01),
	       .S_AXI_2_awcache ('d0),
	       .S_AXI_2_awid	(sh_cl_dma_pcis_awid),
	       .S_AXI_2_awlen	(sh_cl_dma_pcis_awlen),
	       .S_AXI_2_awlock	('d0),
	       .S_AXI_2_awprot	('d0),
	       .S_AXI_2_awqos	('d0),
	       .S_AXI_2_awready	(cl_sh_dma_pcis_awready),
	       .S_AXI_2_awsize	(sh_cl_dma_pcis_arsize),
	       .S_AXI_2_awvalid (sh_cl_dma_pcis_awvalid),
	       .S_AXI_2_bid	(cl_sh_dma_pcis_bid),
	       .S_AXI_2_bready	(sh_cl_dma_pcis_bready),
	       .S_AXI_2_bresp	(cl_sh_dma_pcis_bresp),
	       .S_AXI_2_bvalid	(cl_sh_dma_pcis_bvalid),
	       .S_AXI_2_rdata	(cl_sh_dma_pcis_rdata),
	       .S_AXI_2_rid	(cl_sh_dma_pcis_rid),
	       .S_AXI_2_rlast   (ch_sh_dma_pcis_rlast),
	       .S_AXI_2_rready	(sh_cl_dma_pcis_rready),
	       .S_AXI_2_rresp	(cl_sh_dma_pcis_rresp),
	       .S_AXI_2_rvalid	(cl_sh_dma_pcis_rvalid),
	       .S_AXI_2_wdata	(sh_cl_dma_pcis_wdata),	       
	       .S_AXI_2_wlast	(sh_cl_dma_pcis_wlast),
	       .S_AXI_2_wready	(cl_sh_dma_pcis_wready),
	       .S_AXI_2_wstrb	(sh_cl_dma_pcis_wstrb),
	       .S_AXI_2_wvalid	(sh_cl_dma_pcis_wvalid),
	       .irq_o		(irq_o));
   assign cl_sh_apppf_irq_req = {15'b0,irq_o};
   
   //-------------------------------------------
   // Tie-Off Global Signals
   //-------------------------------------------
`ifndef CL_VERSION
 `define CL_VERSION 32'hee_ee_ee_00
`endif  
   
   
   assign cl_sh_status0[31:0] =  32'h0000_0FF0;
   assign cl_sh_status1[31:0] = `CL_VERSION;
   
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
                   .probe0 (sh_ocl_awvalid_q),
                   .probe1 (sh_ocl_awaddr_q ),
                   .probe2 (ocl_sh_awready_q),
                   .probe3 (sh_ocl_arvalid_q),
                   .probe4 (sh_ocl_araddr_q ),
                   .probe5 (ocl_sh_arready_q)
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





