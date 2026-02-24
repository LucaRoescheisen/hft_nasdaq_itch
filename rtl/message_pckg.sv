package message_pckg

typedef enum logic [7:0] {
    //NASDAQ Market
    NASDAQ_GLOBAL_SELECT_MARKET = "Q" ,
    NASDAQ_GLOBAL_MARKET        = "G" ,
    NASDAQ_CAPTIAL_MARKET       = "S" ,
    //Non-NASDAQ instruments
    NYSE                   = "N" ,
    NYSE_AMERICAN          = "A" ,
    NYSE_ARCA              = "P" ,
    BATS_Z_EXCHANGE        = "Z" ,
    INVERSTORS_EXCHANGE    = "V",
    UNKNOWN                = "?"

  } dir_market_category_e;

  typedef enum logic [7:0] {
    DEFICIENT                     = "D",
    DELINQUENT                    = "E",
    BANKRUPT                      = "Q",
    SUSPENDED                     = "S",
    DEFICIENT_BANKRUPT            = "G",
    DEFICIENT_DELINQUENT          = "H",
    DELINQUENT_BANKRUPT           = "J",
    DEFICIENT_DELINQUENT_BANKRUPT = "K",
    SUSPENDED_FOR_ETP             = "C",
    NORMAL                        = "N"
  } dir_financial_status_indicator_e;

  typedef enum logic [7:0] {
    ACCEPTS_ROUND_LOTS = "Y",
    NO_ORDER_SIZE_RESTRICTION = "N"
  } dir_round_lot_size_e;

  typedef enum logic [7:0] {
    LIVE_PRODUCTION = "P",
    TEST            = "T"
  } dir_authenticity_e;

  typedef enum logic [7:0] {
    SST_RESTRICTED      = "Y",
    SST_NOT_RESTRICTED  = "N"
  } dir_short_sale_threshold_indicator_e;

  typedef enum logic [7:0] {
    IPO_SECURITY      = "Y",
    NO_IPO_SECURITY   = "N"
  } dir_ipo_flag_e;

  typedef enum logic [7:0] {
    TIER_1      = "1",
    TIER_2      = "2"
  } dir_LULUDReference_Price_Tier_e;

  typedef enum logic [7:0] {
    INSTRUMENT_ETP      = "Y",
    INSTRUMENT_NOT_ETP  = "N"
  } dir_ETP_flag_e;

  typedef enum logic [7:0] {
    ETP_INVERSE_ETP      = "Y",
    ETP_NOT_INVERSE_ETP  = "N"
  } dir_ETP_inverse_indicator_e;


//Functions
  function dir_market_category_e parse_market_category(logic[7:0] byte)
    case(byte)
      "Q" : return NASDAQ_GLOBAL_SELECT_MARKET;
      "G" : return NASDAQ_GLOBAL_MARKET;
      "S" : return NASDAQ_CAPTIAL_MARKET;
      "N" : return NYSE;
      "A" : return NYSE_AMERICAN;
      "P" : return NYSE_ARCA;
      "Z" : return BATS_Z_EXCHANGE;
      "V" : return INVERSTORS_EXCHANGE;
      default: return UNKNOWN_MARKET;
    endcase
  endfunction

  function dir_financial_status_indicator_e parse_financial_status(logic[7:0] byte)
    case(byte)
      "D" : return DEFICIENT;
      "E" : return DELINQUENT;
      "Q" : return BANKRUPT;
      "S" : return SUSPENDED;
      "G" : return DEFICIENT_BANKRUPT;
      "H" : return DEFICIENT_DELINQUENT;
      "H" : return DELINQUENT_BANKRUPT;
      "J" : return DELINQUENT_BANKRUPT;
      "K" : return DEFICIENT_DELINQUENT_BANKRUPT;
      "C" : return SUSPENDED_FOR_ETP;
      "N" : return NORMAL;
      default : return " ";
    endcase
  endfunction

  function dir_financial_status_indicator_e parse_round_lots_only(logic[7:0] byte)
    case(byte)
      "Y" : return ACCEPTS_ROUND_LOTS;
      "N" : return NO_ORDER_SIZE_RESTRICTION;
    endcase
  endfunction

  function dir_authenticity_e parse_authenticity(logic[7:0] byte)
    case(byte)
      "P" : return LIVE_PRODUCTION;
      "T" : return TEST;
    endcase
  endfunction

    function dir_short_sale_threshold_indicator_e parse_SST_Indicator(logic[7:0] byte)
    case(byte)
      "P" : return SST_RESTRICTED;
      "T" : return SST_NOT_RESTRICTED;
    endcase
  endfunction

  function dir_ipo_flag_e parse_IPO_Flag(logic[7:0] byte)
    case(byte)
      "Y" : return IPO_SECURITY;
      "N" : return NO_IPO_SECURITY;
    endcase
  endfunction

  function dir_LULUDReference_Price_Tier_e parse_Price_Tier(logic[7:0] byte)
    case(byte)
      "1" : return TIER_1;
      "2" : return TIER_2;
    endcase
  endfunction

  function dir_ETP_flag_e parse_ETP_Flag(logic[7:0] byte)
    case(byte)
      "Y" : return INSTRUMENT_ETP;
      "N" : return INSTRUMENT_NOT_ETP;
    endcase
  endfunction

    function dir_ETP_inverse_indicator_e parse_ETP_inverse_indicator(logic[7:0] byte)
    case(byte)
      "Y" : return ETP_INVERSE_ETP;
      "N" : return ETP_NOT_INVERSE_ETP;
    endcase
  endfunction

//-----------------------------------------------------------------------------------------//


   typedef enum logic [3:0] {
    SYSTEM                = "S",
    STOCK_DIR             = "R",
    ADD_ORDER_NO_MPID     = "A",
    ADD_ORDER_MPID        = "F",
    ORDER_EXEC            = "E",
    ORDER_EXEC_WITH_PRICE = "C",
    ORDER_CANCEL          = "X",
    ORDER_DELETE          = "D",
    ORDER_REPLACE         = "U"
  } message_states_e;


  typedef enum logic [2:0] {
    SYSTEM_EVENT_MESSAGE_LENGTH  = 12,
    ...

  } message_lengths;

  //SYSTEM MESSAGE

  typedef struct packed {
    logic [7:0]  sys_message_type;
    logic [15:0] sys_stock_locate;
    logic [15:0] sys_tracking_number;
    logic [47:0] sys_time_stamp;
    logic [7:0]  sys_event_code;
  } System_Event_Message;
  System_Event_Message system_event_message;

  typedef enum logic [7:0] {
    EVENT_START_MESSAGES = "O" ,
    EVENT_START_SYSTEM   = "S" ,
    EVENT_START_MARKET   = "Q" ,
    EVENT_END_MARKET     = "M" ,
    EVENT_END_SYSTEM     = "E" ,
    EVENT_END_MESSAGES   = "C" ,

  } system_event_codes_e;





    //STOCK DIRECTORY MESSAGE

  typedef struct packed {
    logic [7:0]  message_type;
    logic [15:0] stock_locate;
    logic [15:0] tracking_number;
    logic [47:0] time_stamp;
    logic [63:0] stock_symbol;
    logic [7:0]  market_category;
    logic [7:0]  financial_status_indicator;
    logic [31:0] round_lot_size;
    logic [7:0]  round_lots_only;
    logic [7:0]  issue_classification;
    logic [7:0]  authenticity;
    logic [7:0]  short_sale_threshold_indicator;
    logic [7:0]  ipo_flag;
    logic [7:0]  LULUDReference_Price_Tier;
    logic [7:0]  ETP_flag;
    logic [7:0]  ETP_leverage_factor;
    logic [7:0]  ETP_inverse_indicator;
  } Stock_Directory_Message;
  Stock_Directory_Message stock_directory_message;

//ADD-ORDER NO MPID
    typedef struct packed {
    logic [7:0]  message_type;
    logic [15:0] stock_locate;
    logic [15:0] tracking_number;
    logic [47:0] time_stamp;
    logic [63:0] order_reference_number;
    logic [7:0]  buy_sell_indicator;
    logic [31:0] shares;
    logic [63:0] stock;
    logic [31:0] price;
    } Add_Order_NoMPID_Message;
  Add_Order_NoMPID_Message add_order_noMPID_message;

  //ADD-ORDER MPID
    typedef struct packed {
    logic [7:0]  message_type;
    logic [15:0] stock_locate;
    logic [15:0] tracking_number;
    logic [47:0] time_stamp;
    logic [63:0] order_reference_number;
    logic [7:0]  buy_sell_indicator;
    logic [31:0] shares;
    logic [63:0] stock;
    logic [31:0] price;
    logic [31:0] attribution;
    } Add_Order_MPID_Message;
  Add_Order_MPID_Message add_order_MPID_message;

    //ORDER EXECUTED
    typedef struct packed {
    logic [7:0]  message_type;
    logic [15:0] stock_locate;
    logic [15:0] tracking_number;
    logic [47:0] time_stamp;
    logic [63:0] order_reference_number;
    logic [31:0] shares;
    logic [63:0] match_number;

    } Order_Executed_Message;
  Order_Executed_Message order_executed_message;

  //ORDER EXECUTED WITH PRICE
  typedef struct packed {
    logic [7:0]  message_type;
    logic [15:0] stock_locate;
    logic [15:0] tracking_number;
    logic [47:0] time_stamp;
    logic [63:0] order_reference_number;
    logic [31:0] shares;
    logic [63:0] match_number;
    logic [7:0]  printable;
    logic [31:0] price; //4dec
    } Order_Executed_With_Price_Message;
  Order_Executed_With_Price_Message order_executed_with_price_message;

  //ORDER CANCEL MESSAGE
  typedef struct packed {
    logic [7:0]  message_type;
    logic [15:0] stock_locate;
    logic [15:0] tracking_number;
    logic [47:0] time_stamp;
    logic [63:0] order_reference_number;
    logic [31:0] shares;
  } Order_Cancel_Message;
  Order_Cancel_Message order_cancel_message;

    //ORDER DELETE MESSAGE
  typedef struct packed {
    logic [7:0]  message_type;
    logic [15:0] stock_locate;
    logic [15:0] tracking_number;
    logic [47:0] time_stamp;
    logic [63:0] order_reference_number;
  } Order_Delete_Message;
  Order_Delete_Message order_delete_message;

    //ORDER REPLACE MESSAGE
  typedef struct packed {
    logic [7:0]  message_type;
    logic [15:0] stock_locate;
    logic [15:0] tracking_number;
    logic [47:0] time_stamp;
    logic [63:0] original_price_order_reference_number;
    logic [63:0] new_price_order_reference_number;
    logic [31:0] shares;
    logic [31:0] price; //4dec
  } Order_Replace_Message;
  Order_Replace_Message order_replace_message;







endpackage