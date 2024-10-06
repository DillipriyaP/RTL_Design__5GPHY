module Data_Pak_header_Footer #(
    parameter integer IN_WIDTH = 32,
    parameter integer OUT_WIDTH = 32,
    parameter integer DEPTH = 512,
    parameter integer MAX_LEN = 381
     )(
    input clock,
    input resetn,
    input [IN_WIDTH-1 : 0]dataIn,
    input validIn,
    input lastIn,
    output reg [OUT_WIDTH -1 : 0]dataOut,
    output reg validOut,
    output reg lastOut,
    output reg overflow
    );
    //Address length for the depth.
    localparam Addr_Length = $clog2(DEPTH);
    localparam Addr_pac = $clog2(MAX_LEN/3);
    //Defining STATES
    localparam START = 2'd0;
    localparam HEADER = 2'd1;
    localparam PAYLOAD = 2'd2;
    localparam FOOTER = 2'd3;
    //declaring state variable and next state variable
    reg [1:0]state;
    reg [1:0]next_state;
    //Declaring the memory.
    reg [IN_WIDTH -1 :0]ram[0:DEPTH-1];
    //Declaring the write pointer for indexing memory for writing data
    reg [Addr_Length-1 :0]wr_ptr;
    //Declaring the read pointer for indexing memory for reading data
    reg [Addr_Length-1 :0]rd_ptr;
    //Counter to payload_count packet length
    reg [Addr_Length-1 :0]Pak_Count;
    reg [Addr_Length-1 :0]Pak_Len;
    reg [15 :0]pac_len_store[0:MAX_LEN/3];
    reg [Addr_pac:0]wr_pac;
    //Using for both packet payload_count accessing and last acceessing.
    reg [Addr_pac:0]rd_pac;
    reg [Addr_Length-1:0]payload_count; 
    reg [15:0]seq_num;
    reg validIn_reg;
    reg lastIn_reg;
    integer i;
    //registerig the valid and last signal
    always@(posedge clock)begin
        if(~resetn)begin
            validIn_reg <= 0;
            lastIn_reg <= 0;
        end else begin
            validIn_reg <= validIn;
            lastIn_reg <= lastIn;
        end    
    end
    //writing data in to the memory.
    always@(posedge clock)begin
        if(~resetn)begin
           for(i=0;i<DEPTH;i=i+1)begin
            ram[i]<=0;
           end
        end else begin
            ram[wr_ptr]<= validIn?dataIn:ram[wr_ptr];
        end
    end
    //Incrementing the write address
    always@(posedge clock)begin
        if(~resetn)begin
            wr_ptr <= 0;
        end else begin
            if(wr_ptr==(DEPTH-1))begin
                wr_ptr <= 0;
            end else if(validIn && Pak_Len < MAX_LEN)begin
                wr_ptr <= wr_ptr + 1;
            end else if(validIn && (Pak_Len >= MAX_LEN) && ~lastIn )begin
                wr_ptr <= wr_ptr;
            end else if(validIn && (Pak_Len >= MAX_LEN) && lastIn )begin
                wr_ptr <= wr_ptr + 1;
            end else begin
                wr_ptr <= wr_ptr;
            end
        end
    end

    //For counting the packet length
    integer j;
    always@(posedge clock)begin
        if(~resetn)begin
            Pak_Count <= 1;
            Pak_Len <= 0;
            wr_pac <= 0;
            for(j=0;j <= MAX_LEN/3;j=j+1)begin
                pac_len_store[j]<=0;
            end
        end else begin
            if((Pak_Count == MAX_LEN)&&(~lastIn && validIn))begin
                Pak_Count <= MAX_LEN;
                pac_len_store[wr_pac] <= MAX_LEN;
            end else if((Pak_Count <= MAX_LEN) && (~lastIn && validIn))begin
                Pak_Count <= Pak_Count + 1;
                pac_len_store[wr_pac] <= pac_len_store[wr_pac];
            end else if(lastIn && validIn && Pak_Count <= MAX_LEN)begin
                Pak_Count <= 1;
                pac_len_store[wr_pac] <= Pak_Count;
            end else if(~lastIn && validIn && Pak_Count >= MAX_LEN)begin
                Pak_Count <= 1;
                pac_len_store[wr_pac] <= MAX_LEN;
            end else begin
                Pak_Count <= Pak_Count;
                pac_len_store[wr_pac] <= pac_len_store[wr_pac];
            end
            //Logic for input packet length
                if(lastIn && validIn)begin
                    Pak_Len <= 0;
                end else begin
                    if(validIn)begin
                        Pak_Len <= Pak_Len + 1;
                    end else begin
                        Pak_Len <= Pak_Len;
                    end
                end
            //Pointer for packet writing
            if(wr_pac == DEPTH/3)begin
                wr_pac <= 0;
            end else begin
                if(lastIn && validIn)begin
                    wr_pac <= wr_pac + 1;
                end else begin
                    wr_pac <= wr_pac;
                end
            end
        end
    end
    //state logic
    always@(posedge clock)begin
        if(~resetn)begin
            state <= START;
        end else begin
            state <= next_state;
        end
    end
    //next state logic 
    always@(*)begin
        
        case(state)
        START:begin
            if(validIn_reg)begin
                next_state = HEADER;
            end
        end
        HEADER:begin
                  next_state = PAYLOAD;
               end
        PAYLOAD:begin
                  if((Pak_Len !=0) && (((payload_count )  == (pac_len_store[rd_pac]-1)) || (payload_count>=MAX_LEN-1)))begin
                    next_state = FOOTER;
                  end
                end
        FOOTER:begin
                    next_state = HEADER;
               end
        default:begin
                next_state = START;
                end
        endcase
    end
    //ouput assignments and rd-pac pointer change assignments
    always@(posedge clock)begin
        if(~resetn)begin
            seq_num <= 0;
            validOut <= 0;
            lastOut <= 0;
            overflow <= 0;
            dataOut <= 0;
            rd_ptr <= 0;
            rd_pac <= 0;
            payload_count <=0;
        end else begin
            case(state)
            START:begin
                    seq_num <= 0;
                    validOut <= 0;
                    lastOut <= 0;
                    overflow <= 0;
                    dataOut <= 0;
                    rd_ptr <= 0;
                    rd_pac <= 0;
                    payload_count <=0;
                  end
            HEADER:begin
                     seq_num <= seq_num + 1;
                     validOut <= 1'b1;
                     dataOut <= 32'hFFFFFFFF;
                     lastOut <= 0;
                     overflow <= 0;
                     rd_ptr <= rd_ptr;
                     rd_pac <= rd_pac;
                     payload_count <= 0;
                   end
            PAYLOAD:begin
                     if(rd_ptr == wr_ptr)begin
                        validOut <= 1'b0;
                        dataOut <= ram[rd_ptr];
                        lastOut <= 0;
                        overflow <= 0;
                        payload_count <= payload_count;
                     end else begin
                        validOut <= 1'b1;
                        dataOut <= ram[rd_ptr];
                        lastOut <= 0;
                        overflow <= 0;
                        payload_count <= payload_count+1;
                     end
                     if(rd_ptr == DEPTH -1)begin
                        rd_ptr <= 0;
                     end else begin
                        if(rd_ptr == wr_ptr)begin
                          rd_ptr <= rd_ptr;
                        end else begin
                            rd_ptr <= rd_ptr + 1;
                        end
                     end
                      seq_num <= seq_num;
                      rd_pac <= rd_pac;
                    end
            FOOTER:begin
                     seq_num <= seq_num;
                     rd_ptr <= rd_ptr;
                     validOut <= 1'b1;
                     dataOut <= {seq_num,pac_len_store[rd_pac]};
                     lastOut <= 1'b1;
                     overflow <= (payload_count>=MAX_LEN)?1:0;
                     payload_count <= payload_count;
                     rd_pac <= rd_pac + 1;
                   end
            endcase
        end
    end
endmodule
