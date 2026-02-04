`include "define.sv"
module apb_master (
                  input  PCLK,PRESETn,
                  input  PREADY,PSLVERR,
                  input [`DATA_WIDTH-1:0]PRDATA,
                  input [`ADDR_WIDTH-1:0]apb_wr_addr,apb_rd_addr,
                  input [`DATA_WIDTH-1:0]apb_wr_data,
                  input logic READ_WRITE,transfer,
                  output reg PENABLE,PWRITE,
                  output reg PSELx,
                  output reg[`ADDR_WIDTH-1:0]PADDR,
                  output reg[`DATA_WIDTH-1:0]PWDATA,apb_rd_data_out);

  typedef enum logic [1:0]{IDLE=2'b00,SETUP=2'b01,ACCESS=2'b10} state_t;
  state_t state,next_state;


  always@(posedge PCLK or negedge PRESETn) begin
      if(!PRESETn)
        state<=IDLE;
      else
        state<=next_state;
    end


  always@(*) begin
     if(!PRESETn)
       begin
         PSELx = 1'b0;
         PENABLE = 1'b0;
         PWDATA =32'h0;
         PADDR =32'h0;
         PWRITE=1'b0;
         apb_rd_data_out=32'h0;
       end
    else
      begin
      case(state)
      IDLE: begin
              PSELx=1'b0;
              PENABLE=1'b0;
              
              next_state=(transfer)? SETUP:IDLE;
             end
      SETUP:begin
               PENABLE=0;
               PSELx=1'b1;
               PWRITE=READ_WRITE;
              if(READ_WRITE)
                begin
                  PWDATA=apb_wr_data;
                  PADDR=apb_wr_addr;
               end                                  
              else
               begin
                PADDR=apb_rd_addr; 
               end
               next_state=ACCESS;
             end
ACCESS: begin
          PENABLE = 1'b1;
          PSELx   = 1'b1;
        
             if (PREADY)
               begin

                  // -------- READ --------
                 if(!READ_WRITE)
                    begin
                       apb_rd_data_out = PRDATA;
                       if (PSLVERR)
                         begin
                           next_state = IDLE;   // error on read
                         end
                      else if (transfer) 
                         begin
                           next_state = SETUP;   // more transfers
                         end
                      else
                         begin
                          next_state = IDLE;    // done
                         end
                   end
  
                // -------- WRITE --------
                else 
                  begin
                    // PSLVERR intentionally ignored in state logic for write
                     if (transfer)
                       begin
                         next_state = SETUP;
                       end
                     else 
                       begin
                         next_state = IDLE;
                       end

                 end 
            end
          else //(PREADY == 0) : stay in ACCESS
              begin
                next_state = ACCESS;
              end
       end        
   default:next_state=IDLE;
   endcase
  end
end

endmodule


