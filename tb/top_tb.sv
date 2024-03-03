module top_tb;

  parameter NUMBER_OF_TEST_RUNS = 10;
  parameter TIMEOUT             = 100;
  parameter TR_OVERHEAD         = 4;
  parameter MAX_RND_DELAY       = 100;
  parameter MIN_RND_DELAY       = 0;

  parameter DWIDTH              = 16;
  parameter AWIDTH              = 8;
  parameter ALMOST_FULL         = 2;
  parameter ALMOST_EMPTY        = 2;

  bit                  clk;
  logic                srst;

  logic [DWIDTH - 1:0] data;
  logic                wrreq;
  logic                rdreq;

  logic [DWIDTH - 1:0] q;
  logic                empty;
  logic                full;
  logic [AWIDTH:0]     usedw;
  logic                almost_full;
  logic                almost_empty;

  bit                  srst_done;


  initial forever #5 clk = !clk;

  default clocking cb @( posedge clk );
  endclocking

  initial 
    begin
      srst      <= 1'b0;
      ##1;
      srst      <= 1'b1;
      ##1;
      srst      <= 1'b0;
      srst_done <= 1'b1;
    end      

  lifo #(
    .DWIDTH         ( DWIDTH       ),          
    .AWIDTH         ( AWIDTH       ),            
    .ALMOST_FULL    ( ALMOST_FULL  ), 
    .ALMOST_EMPTY   ( ALMOST_EMPTY )
  ) lifo_inst (
    .clk_i          ( clk          ),
    .srst_i         ( srst         ),
    .data_i         ( data         ),
    .wrreq_i        ( wrreq_i      ),
    .rdreq_i        ( rdreq        ),
    .q_o            ( q            ),
    .empty_o        ( empty        ),
    .full_o         ( full         ),
    .usedw_o        ( usedw        ),
    .almost_full_o  ( almost_full  ),
    .almost_empty_o ( almost_empty ) 
  );

  typedef logic [DWIDTH - 1:0] data_t[$];
  typedef int                  delay_t[$];

  int enum {
    RD_WOUT_DELAY,
    RD_WONE_DELAY,
    RD_WRND_DELAY,
    WR_WOUT_DELAY,
    WR_WONE_DELAY,
    WR_WRND_DELAY,
    TR_OF_ONE_LENGTH,
    TR_OF_EXC_LENGTH,
    TR_OF_RND_LENGTH,
    TR_OF_MAX_LENGTH
  } configurations;

  class Environment

    mailbox #( Transaction ) generated_tansactions, input_transactions; 
    mailbox #( data_t )      output_data;

    Generator generator;
    Sender    sender;
    Monitor   monitor;
    Checker   checker;

    function new;
      this.output_data           = new();
      this.generated_tansactions = new();
      this.input_transactions    = new();

      this.generator             = new( generated_tansactions ); 
      this.sender                = new( generated_tansactions, input_transactions );
      this.monitor               = new( output_transactions );
      this.checker               = new( input_transactions, output_transactions );

    endfunction

    task run;
      
      generator.run();
      sender.run();
      monitor.run();

    endtask

  endclass

  class Transaction
  // This class represents whole transaction:
  // data in it, delays between requests and flag
  // that tells sender if we should make lifo full before start reading
    
    data_t  data;
    delay_t rd_delays;
    delay_t wr_delays;
    int     rd_conf;
    int     wr_conf;
    int     len_conf;
    int     tr_len;
    bit     read_after_full;
    bit     read_after_write;

    function new( input int rd_conf,
                  input int wr_conf,
                  input int len_conf,
                  input bit read_after_full  = 1'b0,
                  input bit read_after_write = 1'b0
                );

      this.wr_conf         = wr_conf;
      this.rd_conf         = rd_conf;
      this.read_after_full = read_after_full;

      set_len();
      set_delays();
      set_data();

    endfunction

    task set_data;

    data_t tr_data;
      
      for ( int i = 0; i < tr_len; i++ )
        begin
          tr_data.push_back( $urandom( 2**DWIDTH, 0 ) );
        end

    endtask

    task set_len;
      
      case (len_conf)
        
        TR_OF_ONE_LENGTH: begin
          this.tr_len = 1;
        end

        TR_OF_EXC_LENGTH: begin
          this.tr_len = $urandom( 2**AWIDTH * TR_OVERHEAD, 2**AWIDTH );
        end

        TR_OF_RND_LENGTH: begin
          this.tr_len = $urandom( 2**AWIDTH * TR_OVERHEAD, 0 );
        end

        TR_OF_MAX_LENGTH: begin
          this.tr_len = 2**AWIDTH;
        end

      endcase

    endtask

    task set_delays;
      
      case (rd_conf)

        RD_WOUT_DELAY: begin
          for ( int i = 0; i < tr_len; i++ )
            begin
              rd_delays.push_back( 0 ); 
            end
        end

        RD_WONE_DELAY: begin
          for ( int i = 0; i < tr_len; i++ )
            begin
              rd_delays.push_back( 1 ); 
            end
        end

        RD_WRND_DELAY: begin
          for ( int i = 0; i < tr_len; i++ )
            begin
              rd_delays.push_back( $urandom( MAX_RND_DELAY, MIN_RND_DELAY ) ); 
            end
        end 

      endcase

      case (wr_conf)

        WR_WOUT_DELAY: begin
          for ( int i = 0; i < tr_len; i++ )
            begin
              wr_delays.push_back( 0 ); 
            end
        end

        WR_WONE_DELAY: begin
          for ( int i = 0; i < tr_len; i++ )
            begin
              wr_delays.push_back( 1 ); 
            end
        end

        WR_WRND_DELAY: begin
          for ( int i = 0; i < tr_len; i++ )
            begin
              wr_delays.push_back( $urandom( MAX_RND_DELAY, MIN_RND_DELAY ) ); 
            end
        end 

      endcase

    endtask

    function print;
    // This function will print transaction info at start of every transaction

      $display( "Current transaction parameters:" );
      $display( "Time of transaction start: %d", $time() );
      $display( "Read configuration: %d. Write configuration: %d", rd_conf, wr_conf );
      $display( "Transaction length: %d", tr_len );
      $display( "Transaction data: %d", data );

    endfunction

  endclass

  class Sender
    mailbox #( Transaction ) generated_transactions;
    
    function new ( input mailbox #( Transaction ) generated_transactions,
                   input mailbox #( Transaction ) input_transactions 
                 );

      this.generated_transactions = generated_transactions;
      this.input_transactions     = input_transactions;

    endfunction

    task run;

      Transaction tr_to_send;

      while ( generated_transactions.num() )
        begin
          generated_transactions.get( tr_to_send );

          fork
            this.send(tr_to_send);
            this.read(tr_to_send);
          join

        end        
    endtask

    task read( input Transaction tr_to_send );
      
      if ( tr_to_send.read_after_full )
        wait ( full );
      else  if ( tr_to_send.read_after_write )
        wait ( tr_to_send.wr_delays.size() == 0 );
        
      while ( rd_delays.size() )
        begin
          rdreq = 1'b1;
          ##1;
          rdreq = 1'b0;
          ##(rd_delays.pop_back() );
        end

    endtask

    task send( input Transaction tr_to_send );

      while ( tr_to_send.wr_delays.size() )
        begin
          wr_req = 1'b1;
          data   = tr_to_send.data.pop_back();
          ##1;
          wr_req = 1'b0;
          ##(tr_to_send.wr_delays.pop_back());
        end
      
    endtask

  endclass

  class Monitor

    mailbox #( data_t ) output_data;

    logic [DWIDTH - 1:0] ref_mem [2**AWIDTH - 1:0];
    int                  ref_ptr;
    bit                  reading_delay; // valid data appeares at q with 1 clk cycle delay

    function new;

      this.ref_ptr       = '0;
      this.ref_mem       = '0;
      this.reading_delay = '0;

    endfunction

    task run;

      forever
        begin
          ##1;

          if ( wrreq === 1'b1 )
            begin
              if ( ref_ptr != 2**AWIDTH )
                begin
                  ref_mem[ref_ptr] = data;
                  ref_ptr          += 1;
                end
            end

          if ( reading_delay && ref_ptr != -1 )
            begin
              ref_ptr -= 1;
            end
          if ( rdreq === 1'b1 )
            begin
              if ( ref_ptr != -1 )
                begin
                  reading_delay    = 1'b1;
                end
            end
          else
            reading_delay = 1'b0;

        end

    endtask

  endclass

  class Checker

    mailbox #( data_t )      output_data;
    mailbox #( Transaction ) input_transactions;

    function new( mailbox #( data_t)      output_data,
                  mailbox #( Transaction) input_transactions 
                );
       
       this.output_data        = output_data;
       this.input_transactions = input_transactions;

    endfunction

  endclass

  class Generator

    mailbox #( Transaction ) generated_transactions;

    function new( input mailbox #( Transaction ) generated_transactions );
      
      this.generated_transactions = generated_transactions;

    endfunction

    task run;

      Transaction tr;

      repeat ( NUMBER_OF_TEST_RUNS )
        begin
          tr = new( RD_WRND_DELAY, WR_WRND_DELAY, TR_OF_RND_LENGTH );
          generated_transactions.put(tr);
        end

      tr = new( RD_WONE_DELAY, WR_WONE_DELAY, TR_OF_MAX_LENGTH );
      generated_transactions.put(tr);

      tr = new( RD_WOUT_DELAY, WR_WOUT_DELAY, TR_OF_MAX_LENGTH );
      generated_transactions.put(tr); 

      tr = new( RD_WOUT_DELAY, WR_WRND_DELAY, TR_OF_MAX_LENGTH );
      generated_transactions.put(tr);

      tr = new( RD_WRND_DELAY, WR_WOUT_DELAY, TR_OF_MAX_LENGTH );
      generated_transactions.put(tr);

      tr = new( RD_WOUT_DELAY, WR_WOUT_DELAY, TR_OF_ONE_LENGTH );
      generated_transactions.put(tr);

      tr = new( RD_WRND_DELAY, WR_WOUT_DELAY, TR_OF_EXC_LENGTH, read_after_full = 1'b1 );
      generated_transactions.put(tr);

      tr = new( RD_WRND_DELAY, WR_WOUT_DELAY, TR_OF_EXC_LENGTH, read_after_write = 1'b1 );
      generated_transactions.put(tr);

    endtask

  endclass

  initial
    begin
      data    = '0;
      wrreq_i = 1'b0;
      rdreq   = 1'b0;

      wait( srst_done );   

      Environment env = new();

      env.run();

    end

endmodule