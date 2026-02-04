// -------------------------------------------------
// Copyright(c) LUBIS EDA GmbH, All rights reserved
// Contact: contact@lubis-eda.com
// -------------------------------------------------

// Note on the import command:
// When placing the import outside of the module declaration,
// then the package content(s) are placed in the global namespace.
// This can cause some modules to through a warning whenever the
// same package is imported another time.

`default_nettype none
`include "define.sv"
module fv_apb_master
(
    // DUV interface
    input logic                   PCLK,           // Input
    input logic                   PRESETn,        // Input
    input logic                   READ_WRITE,     // Input
    input logic                   transfer,       // Input
    input logic                   PSLVERR,        // Input
    input logic[`ADDR_WIDTH-1:0]  apb_wr_addr,    // Input
    input logic[`ADDR_WIDTH-1:0]  apb_rd_addr,    // Input
    input logic[`DATA_WIDTH-1:0]  apb_wr_data,    // Input
    input logic[`DATA_WIDTH-1:0]  PRDATA,         // Input
    input logic PREADY,
    input logic                   PENABLE,        //Output      
    input logic                   PWRITE,         //Output   
    input logic                   PSELx,          //Output   
    input logic[`ADDR_WIDTH-1:0]  PADDR,          //Output   
    input logic[`DATA_WIDTH-1:0]  PWDATA,         //Output   
    input logic[`DATA_WIDTH-1:0]  apb_rd_data_out //Output
 );



    // Define default clock for every property
    default clocking default_clk @(posedge PCLK); endclocking

   ////////////////////// ASSUMPTIONS (to assume APB slave behavior)//////////////////////////////////////
  
   property asm_pready;
      disable iff(!PRESETn)
        PSELx && PENABLE && !PREADY |-> ##[0:`MAX_WAIT] PREADY;
   endproperty
   ASSM_PREADY:assume property(asm_pready);


   property asm_pslverr_1;
     disable iff(!PRESETn)
        PREADY && PSELx && PENABLE && (PADDR > `VALID_ADDR) && !PWRITE
         |-> PSLVERR;
   endproperty
   ASSM_PSLVERR_1:assume property(asm_pslverr_1);

    property asm_pslverr_0;
     disable iff(!PRESETn)
        PREADY && PENABLE && PSELx && PWRITE
         |-> !PSLVERR;
   endproperty
   ASSM_PSLVERR_0:assume property(asm_pslverr_0);

  property asm_prdata;
    disable iff(!PRESETn)
      PREADY && PENABLE && (PADDR <= `VALID_ADDR) && !PWRITE
       |-> (PRDATA !=0);
  endproperty
  //ASSM_PRDATA:assume property(asm_prdata);



 ///////////////// ASSERTIONS( to verify the APB MASTER Behavior) ///////////////////////////////////////////

//=============================== verify reset ================================================//
property reset_check;
   // disable iff(PRESETn)
!PRESETn |->    (apb_master.state == apb_master.IDLE)
                 && PWRITE==1'b0
                 && PSELx==1'b0
                 && PENABLE==1'b0
                 && PWDATA ==32'h0
                 && PADDR == 32'h0
                 && apb_rd_data_out==32'h0

  ;endproperty
AST_RESET_CHECK:assert property(reset_check);

 //======================================== check state output behaviors =====================================//


// 1)***************************** IDLE state output behavior **********************************//
 property idle_op;
     disable iff(!PRESETn) (apb_master.state==apb_master.IDLE) |-> !PSELx && !PENABLE                                   
  ;endproperty
 AST_IDLE_OP :assert property(idle_op);

                       
 // 2)***************************** SETUP state output behavior **********************************//
 property setup_op;
     disable iff(!PRESETn) (apb_master.state==apb_master.SETUP) |->  PSELx && !PENABLE;
  endproperty
 AST_SETUP_OP :assert property(setup_op);

                        
 // 3)***************************** ACCESS state output behavior **********************************//
 property access_op;
     disable iff(!PRESETn) (apb_master.state==apb_master.ACCESS) |->  PSELx && PENABLE;
  endproperty
 AST_ACCESS_OP :assert property(access_op);

// 4)**************************** PSELx is high, then the state should be either SETUP or ACCESS ******************//
 property pselx_state;
     disable iff(!PRESETn) (PSELx===1) |-> (apb_master.state==apb_master.ACCESS)||(apb_master.state==apb_master.SETUP)
  ;endproperty
 AST_PSELx_state :assert property(pselx_state);

//5)**************************** PSELx is high, then the state should be either SETUP or ACCESS ******************//
 property penable_state;
     disable iff(!PRESETn) (PENABLE===1) |-> (apb_master.state==apb_master.ACCESS)
  ;endproperty
 AST_PENABLE_state :assert property(penable_state);


//============================= state transitions ==============================================//
sequence idle;
    !PSELx && !PENABLE;
 endsequence

sequence setup;
    PSELx && !PENABLE;
 endsequence

sequence access;
    PSELx && PENABLE;
 endsequence


// 1)*************************** IDLE to SETUP ********************************//
 property idle_to_setup;
          disable iff(!PRESETn) 
            idle ##0 transfer |-> ##1 setup;
 endproperty
 AST_IDLE_TO_SETUP :assert property(idle_to_setup);

// 2)************************ SETUP to ACCESS ********************************//
 property setup_to_access;
       disable iff(!PRESETn) 
         setup |-> ##1 access;
 endproperty
 AST_SETUP_TO_ACCESS:assert property(setup_to_access);

// 3)********************* ACCESS TO SETUP ************************************//
 property access_to_setup;
    disable iff(!PRESETn) 
      access ##0( !PSLVERR && PREADY && transfer)|-> ##1 setup;
 endproperty
 AST_ACCESS_TO_SETUP :assert property(access_to_setup);


// 4)********************** ACCESS TO IDLE 1 *************************************//
property access_to_idle_1;
    disable iff(!PRESETn)  
     access ##0(PREADY && !transfer)|-> ##1 idle;
 endproperty
 AST_ACCESS_TO_IDLE_1 :assert property(access_to_idle_1);
                        

// 5)********************* ACCESS TO IDLE 2 ***************************************//
property access_to_idle_2;
    disable iff(!PRESETn) 
      access ##0 (PSLVERR && PREADY && !READ_WRITE ) |-> ##1 idle;
 endproperty
 AST_ACCESS_TO_IDLE_2 :assert property(access_to_idle_2);
                        

// 6)******************* STAY IN ACCESS *********************************************//
 property stay_in_access;
    disable iff(!PRESETn) 
      access ##0 !PREADY |-> ##1 access;
 endproperty
 AST_STAY_IN_ACCESS :assert property(stay_in_access);
                        
// 7)******************* STAY IN IDLE ************************************************//
    property stay_in_idle;
    disable iff(!PRESETn) 
      idle ##0 !transfer |-> ##1 idle;
    endproperty
 AST_STAY_IN_IDLE :assert property(stay_in_idle);

//==================================== check control,data and addr signals are stable from SETUP to ACCESS =================================//
   property stable_from_setup_to_access;
     disable iff(!PRESETn) (setup) |-> ##1 (access)
                                       ##0( PSELx == $past(PSELx,1))
                                       ##0( PADDR == $past(PADDR,1))
                                       ##0( PWDATA == $past(PWDATA,1))
                                       ##0( PWRITE == $past(PWRITE,1))
 ; endproperty                         
 AST_STABLE_FROM_SETUP_TO_ACCESS :assert property(stable_from_setup_to_access);
                                      
//===================================check control,data and addr signals are stable when PREADY is not there in ACCESS ============================//

  property stable_in_access;
     disable iff(!PRESETn) (access) ##0 !PREADY |-> ##1(access)
                                                    ##0( PSELx == $past(PSELx,1))
                                                    ##0( PENABLE == $past(PENABLE,1))
                                                    ##0( PADDR == $past(PADDR,1))
                                                    ##0( PWDATA == $past(PWDATA,1))
                                                    ##0( PWRITE == $past(PWRITE,1))
  ;endproperty

 AST_STABLE_IN_ACCESS :assert property(stable_in_access);
                                    
//================================================= Additional checkers =========================================================================//


//********************************** check PSELx=1 in SETUP and ACCESS*****************************************//
 property pselx_high;
    disable iff(!PRESETn) (setup or access )|-> (PSELx === 1'b1)
 ;endproperty
AST_PSELX_HIGH:assert property(pselx_high);
                        

//********************************* check PENABLE=1 in ACCESS ************************************************//
 property penable_high;
    disable iff(!PRESETn) (access) |-> (PENABLE ===1'b1);
 endproperty
AST_PENABLE_HIGH:assert property(penable_high);
                               

//********************************check PWRITE is updating with READ_WRITE in SETUP state**************************************//
property pwrite_update;
   disable iff(!PRESETn) (setup) |-> (PWRITE === READ_WRITE);
endproperty
AST_PWRITE_UPDATE:assert property(pwrite_update);
                                
property pwrite_update_with_0;
   disable iff(!PRESETn) (setup ##0 (PWRITE === 0)) |-> (PWRITE === READ_WRITE);
endproperty
AST_PWRITE_UPDATE_WITH_0:assert property(pwrite_update);

//***************************** check PADDR is updated with apb_rd_addr,when PWRITE=0 in SETUP state **************************//
property read_paddr_update;
   disable iff(!PRESETn) (setup) ##0 (PWRITE == 0) |-> (PADDR === apb_rd_addr);
endproperty
AST_READ_PADDR_UPDATE:assert property(read_paddr_update);
                             
    
//***************************** check PADDR is updated with apb_wr_addr,when PWRITE=1 in SETUP state **************************//
property write_paddr_update;
   disable iff(!PRESETn) (setup) ##0 (PWRITE == 1) |-> (PADDR === apb_wr_addr);
endproperty
AST_WRITE_PADDR_UPDATE:assert property(write_paddr_update);
                            
     
//****************************** check PWDATA is updated with apb_wr_data,when PWRITE=1 in SETUP state **************************//
property write_data_update;
   disable iff(!PRESETn) (setup) ##0 (PWRITE == 1) |-> (PWDATA === apb_wr_data);
endproperty
AST_WRITE_DATA_UPDATE:assert property(write_data_update);


//*************************** check PADDR,PWRITE and PWDATA are known and valid in the SETUP state ********************************//
 property valid_info_in_setup;
   disable iff(!PRESETn) (setup)  |-> ( !$isunknown(PADDR) && !$isunknown(PWDATA) && !$isunknown(PWRITE));
endproperty
AST_VALID_INFO_IN_SETUP : assert property(valid_info_in_setup);
                       
       
//************************** check if a transaction completed in ACCESS, master must have PSELx and PENABLE *************************//
 property trans_done;
   disable iff(!PRESETn) (access) ##0 PREADY  |-> (PSELx===1) && (PENABLE ===1);
endproperty
AST_TRANS_DONE : assert property(trans_done);
                  
              
//************************ check if apb_rd_data_out is updated with PRDATA after the read transfer*************************************//

property apb_rd_data_out_update;
   disable iff(!PRESETn) (access) ##0 ( PREADY && !READ_WRITE) |-> (apb_rd_data_out === PRDATA );
endproperty
AST_APB_RD_DATA_OUT_UPDATE : assert property(apb_rd_data_out_update);
                   
             
//************************ check apb_rd_data_out is stable,if PREADY=0 in SETUP state ************************************************//

property apb_rd_data_out_stable;
   disable iff(!PRESETn || PREADY) (access) ##0 (!PWRITE && !$isunknown(PRDATA))|-> ##1 (apb_rd_data_out === $past(apb_rd_data_out,1));
endproperty
AST_APB_RD_DATA_OUT_STABLE : assert property(apb_rd_data_out_stable);
                               

endmodule



// Bind assertion module to DUV
bind apb_master fv_apb_master fv_apbm_i(.PCLK(PCLK),
	        .PRESETn(PRESETn),
                .PADDR(PADDR),
	        .PSELx(PSELx),
	        .PENABLE(PENABLE),
	       	.PWRITE(PWRITE),
		.PWDATA(PWDATA),
		.PRDATA(PRDATA),
		.PREADY(PREADY),
		.PSLVERR(PSLVERR),
		.apb_wr_addr(apb_wr_addr), 
		.apb_wr_data(apb_wr_data),
		.apb_rd_addr(apb_rd_addr),
	        .apb_rd_data_out(apb_rd_data_out),
		.READ_WRITE(READ_WRITE),
	        .transfer(transfer));

