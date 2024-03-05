module top_tb;

  parameter NUMBER_OF_TEST_RUNS = 1;
  parameter TIMEOUT             = 100;
  parameter TR_OVERHEAD         = 4;
  parameter MAX_RND_DELAY       = 100;
  parameter MIN_RND_DELAY       = 0;

  parameter DWIDTH              = 16;
  parameter AWIDTH              = 8;
  parameter ALMOST_FULL         = 2;
  parameter ALMOST_EMPTY        = 2;

  parameter ERROR_LIMITS_USEDW  = 1;
  parameter ERROR_LIMITS_EMPTY  = 2;
  parameter ERROR_LIMITS_FULL   = 1;
  parameter ERROR_LIMITS_ALMF   = 1;
  parameter ERROR_LIMITS_ALME   = 1;
  parameter ERROR_LIMITS_READ   = 10;

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
    .wrreq_i        ( wrreq        ),
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

  typedef enum int {
    RD_WOUT_DELAY    = 0,
    RD_WONE_DELAY    = 1,
    RD_WRND_DELAY    = 2,
    WR_WOUT_DELAY    = 3,
    WR_WONE_DELAY    = 4,
    WR_WRND_DELAY    = 5,
    TR_OF_ONE_LENGTH = 6,
    TR_OF_EXC_LENGTH = 7,
    TR_OF_RND_LENGTH = 8,
    TR_OF_MAX_LENGTH = 9
  } conf_t;

  class Transaction;
  // This class represents whole transaction:
  // data in it, delays between requests and flag
  // that tells driver if we should make lifo full before start reading or
  // write over limits and only then start reading
    
    data_t  data;
    delay_t rd_delays;
    delay_t wr_delays;
    conf_t  rd_conf;
    conf_t  wr_conf;
    conf_t  len_conf;
    int     tr_len;
    bit     read_after_full;
    bit     read_after_write;

    function new( input conf_t rd_conf,
                  input conf_t wr_conf,
                  input conf_t len_conf,
                  input bit    read_after_full  = 1'b0,
                  input bit    read_after_write = 1'b0
                );

      this.wr_conf          = wr_conf;
      this.rd_conf          = rd_conf;
      this.len_conf         = len_conf;
      this.read_after_full  = read_after_full;
      this.read_after_write = read_after_write;
      
      this.data             = {};
      this.rd_delays        = {};
      this.wr_delays        = {}; 

      set_len();
      set_delays();
      set_data();

    endfunction

    function void set_data;
      
      for ( int i = 0; i < this.tr_len; i++ )
        begin
          this.data.push_back( $urandom_range( 2**DWIDTH, 0 ) );
        end

    endfunction

    function void set_len;

      case (this.len_conf)
        
        TR_OF_ONE_LENGTH: begin
          this.tr_len = 1;
        end

        TR_OF_EXC_LENGTH: begin
          this.tr_len = $urandom_range( 2**AWIDTH * TR_OVERHEAD, 2**AWIDTH );
        end

        TR_OF_RND_LENGTH: begin
          this.tr_len = $urandom_range( 2**AWIDTH * TR_OVERHEAD, 1 );
        end

        TR_OF_MAX_LENGTH: begin
          this.tr_len = 2**AWIDTH;
        end

        default: begin
          $display("Unknown type of length configuration!!!!");
          return;
        end

      endcase

    endfunction

    function void set_delays;
      
      case (this.rd_conf)

        RD_WOUT_DELAY: begin
          for ( int i = 0; i < this.tr_len; i++ )
            begin
              this.rd_delays.push_back( 0 ); 
            end
        end

        RD_WONE_DELAY: begin
          for ( int i = 0; i < this.tr_len; i++ )
            begin
              this.rd_delays.push_back( 1 ); 
            end
        end

        RD_WRND_DELAY: begin
          for ( int i = 0; i < this.tr_len; i++ )
            begin
              this.rd_delays.push_back( $urandom_range( MAX_RND_DELAY, MIN_RND_DELAY ) ); 
            end
        end 

        default: begin
          $display("Unknown type of reading configuration!!!!");
          return;
        end

      endcase

      case (this.wr_conf)

        WR_WOUT_DELAY: begin
          for ( int i = 0; i < this.tr_len; i++ )
            begin
              this.wr_delays.push_back( 0 ); 
            end
        end

        WR_WONE_DELAY: begin
          for ( int i = 0; i < this.tr_len; i++ )
            begin
              this.wr_delays.push_back( 1 ); 
            end
        end

        WR_WRND_DELAY: begin
          for ( int i = 0; i < this.tr_len; i++ )
            begin
              this.wr_delays.push_back( $urandom_range( MAX_RND_DELAY, MIN_RND_DELAY ) ); 
            end
        end 

        default: begin
          $display("Unknown type of writing configuration!!!!");
          return;
        end

      endcase

    endfunction

    function void print;
    // This function will print transaction info at start of every transaction
      $display("\n\n\n");

      $display( "Current transaction parameters:" );
      $display( "Time of transaction start: %d", $time() );
      $display( "Read configuration: %d. Write configuration: %d", rd_conf.name(), wr_conf.name() );
      $display( "Transaction length: %d", tr_len );

      $display("\n");

    endfunction

  endclass

  class Driver;
  // This class will drive both reading 
  // and writing commands to DUT
    mailbox #( Transaction ) generated_transactions;
    event                    transaction_started;
    
    function new ( input mailbox #( Transaction ) generated_transactions,
                   input event                    tr_started
                 );

      this.generated_transactions = generated_transactions;
      transaction_started         = tr_started;

    endfunction

    task run;

      Transaction tr_to_send;

      while ( generated_transactions.num() )
        begin
          generated_transactions.get( tr_to_send );
          tr_to_send.print();

          ->transaction_started;

          fork
            write(tr_to_send);
            read(tr_to_send);
          join

        end        
    endtask

    task read( input Transaction tr_to_send );
      
      if ( tr_to_send.read_after_full )
        begin
          wait ( full );
          ##1;
        end
      else  if ( tr_to_send.read_after_write )
        begin
          wait ( tr_to_send.wr_delays.size() == 0 );
          ##1;
        end
        
      while ( tr_to_send.rd_delays.size() )
        begin
          rdreq = 1'b1;
          ##1;
          rdreq = 1'b0;
          ##(tr_to_send.rd_delays.pop_back() );
        end

    endtask

    task write( input Transaction tr_to_send );

      while ( tr_to_send.wr_delays.size() )
        begin
          wrreq = 1'b1;
          data  = tr_to_send.data.pop_back();
          ##1;
          wrreq = 1'b0;
          ##(tr_to_send.wr_delays.pop_back());
        end
      
    endtask

  endclass

  class Monitor;
  // This class will analyse input and output singals of
  // DUT and raise errors in case of their mismatch

    logic [2**AWIDTH - 1:0][DWIDTH - 1:0] ref_mem;
    int                                   ref_ptr;
    bit                                   reading_delay;      // valid data appeares at q with delay of 1 clk cycle
    int                                   timeout_counter;
    event                                 transaction_started;

    // These counters will restrict number of error risings
    int usedw_err_cnt;
    int empty_err_cnt;
    int full_err_cnt;
    int almf_err_cnt;
    int alme_err_cnt;
    int read_err_cnt;

    function new( input event tr_start );

      ref_ptr         = 0;
      ref_mem         = '0;
      reading_delay   = 1'b0;
      timeout_counter = 0;
      usedw_err_cnt = ERROR_LIMITS_USEDW;
      empty_err_cnt = ERROR_LIMITS_EMPTY;
      full_err_cnt  = ERROR_LIMITS_FULL;
      almf_err_cnt  = ERROR_LIMITS_ALMF;
      alme_err_cnt  = ERROR_LIMITS_ALME;
      read_err_cnt  = ERROR_LIMITS_READ;

      transaction_started = tr_start;

    endfunction

    task run;

      fork
        check();
        reload_counters();
      join

    endtask

    task check;

      forever
        begin
          @( posedge clk );
          timeout_counter += 1;

          if ( rdreq === 1'b1 || wrreq === 1'b1 )
            timeout_counter = 0;
          else if ( timeout_counter == TIMEOUT + 1 )
            $stop();

          if ( usedw !== ref_ptr && usedw_err_cnt > 0 )
            begin
              raise_error("Usedw error");
              usedw_err_cnt -= 1;
            end
          if ( ref_ptr === 0 && empty !== 1'b1 && empty_err_cnt > 0 )
            begin
              raise_error("Empty error");
              empty_err_cnt -= 1;
            end
          if ( ref_ptr === (AWIDTH + 1)'(2**AWIDTH) && full !== 1'b1 && full_err_cnt > 0 )
            begin
              raise_error("Full error");
              full_err_cnt -= 1;
            end
          if ( ref_ptr <= ALMOST_EMPTY && almost_empty !== 1'b1 && almf_err_cnt > 0 )
            begin
              raise_error("Almost empty error");
              almf_err_cnt -= 1;
            end
          if ( ref_ptr >= ALMOST_FULL && almost_full !== 1'b1 && alme_err_cnt > 0 )
            begin
              raise_error("Almost full error");
              alme_err_cnt -= 1;
            end
          if ( reading_delay )
            begin
              if ( ref_mem[ref_ptr] !== q && read_err_cnt > 0 )
                begin
                  raise_error("Wrong read");
                  $display("expected value:%d, real value:%d, index:%d", ref_mem[ref_ptr], q, ref_ptr);
                  read_err_cnt -= 1;
                end
            end

          if ( rdreq === 1'b1 && ref_ptr > 0 )
            begin
              ref_ptr       -= 1; 
              reading_delay  = 1'b1;
            end 
          else 
            reading_delay = 1'b0;

          if ( wrreq === 1'b1 && ref_ptr != 2**AWIDTH )
            begin
              ref_mem[ref_ptr] = data;
              ref_ptr         += 1;
              reading_delay    = 1'b0;
            end  
        end

    endtask

    task reload_counters;
      forever
        begin
          ##1;
          wait ( transaction_started.triggered )
            begin
              usedw_err_cnt = ERROR_LIMITS_USEDW;
              empty_err_cnt = ERROR_LIMITS_EMPTY;
              full_err_cnt  = ERROR_LIMITS_FULL;
              almf_err_cnt  = ERROR_LIMITS_ALMF;
              alme_err_cnt  = ERROR_LIMITS_ALME;
              read_err_cnt  = ERROR_LIMITS_READ;
            end
        end

    endtask

    function void raise_error( string error_message );
      $error("time:%d, error type:%s", $time(), error_message);
    endfunction 

  endclass

  class Generator;
  // This class will generate different configurations of transactions

    mailbox #( Transaction ) generated_transactions;

    function new( input mailbox #( Transaction ) generated_transactions );
      
      this.generated_transactions = generated_transactions;

    endfunction

    task run;

      Transaction tr;

      // repeat ( NUMBER_OF_TEST_RUNS )
      //   begin
      //     tr = new( RD_WRND_DELAY, WR_WRND_DELAY, TR_OF_RND_LENGTH );
      //     this.generated_transactions.put(tr);
      //   end

      tr = new( RD_WONE_DELAY, WR_WOUT_DELAY, TR_OF_EXC_LENGTH, .read_after_full(1'b1) );
      this.generated_transactions.put(tr);

      tr = new( RD_WONE_DELAY, WR_WOUT_DELAY, TR_OF_EXC_LENGTH, .read_after_write(1'b1) );
      this.generated_transactions.put(tr);

      // tr = new( RD_WONE_DELAY, WR_WONE_DELAY, TR_OF_MAX_LENGTH );
      // this.generated_transactions.put(tr);

      tr = new( RD_WOUT_DELAY, WR_WOUT_DELAY, TR_OF_MAX_LENGTH );
      this.generated_transactions.put(tr);

      tr = new( RD_WONE_DELAY, WR_WONE_DELAY, TR_OF_MAX_LENGTH );
      this.generated_transactions.put(tr);  

      // tr = new( RD_WOUT_DELAY, WR_WRND_DELAY, TR_OF_MAX_LENGTH );
      // this.generated_transactions.put(tr);

      // tr = new( RD_WRND_DELAY, WR_WOUT_DELAY, TR_OF_MAX_LENGTH );
      // this.generated_transactions.put(tr);

      // tr = new( RD_WOUT_DELAY, WR_WOUT_DELAY, TR_OF_ONE_LENGTH );
      // this.generated_transactions.put(tr);

    endtask

  endclass


  class Environment;
  // This class will hold all parts of tb

    mailbox #( Transaction ) generated_tansactions;

    event     transaction_started; 

    Generator generator;
    Driver    driver;
    Monitor   monitor;

    function new;
      generated_tansactions = new();

      generator             = new( generated_tansactions ); 
      driver                = new( generated_tansactions, transaction_started );
      monitor               = new( transaction_started );

    endfunction

    task run;

      generator.run();
      
      fork
        driver.run();
        monitor.run();
      join

    endtask

  endclass

  initial
    begin
      Environment env;
      env   = new();

      data  = '0;
      wrreq = 1'b0;
      rdreq = 1'b0;

      wait( srst_done );   

      env.run();

    end

endmodule