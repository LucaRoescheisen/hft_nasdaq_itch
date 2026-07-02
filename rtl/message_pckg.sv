package message_pckg;

  parameter [7:0] DEFAULT = 8'hFF;

  typedef enum logic [7:0] {
    //NASDAQ Market
    NASDAQ_GLOBAL_SELECT_MARKET = "Q",
    NASDAQ_GLOBAL_MARKET        = "G",
    NASDAQ_CAPTIAL_MARKET       = "S",
    //Non-NASDAQ instruments
    NYSE                        = "N",
    NYSE_AMERICAN               = "A",
    NYSE_ARCA                   = "P",
    BATS_Z_EXCHANGE             = "Z",
    INVERSTORS_EXCHANGE         = "V",
    UNKNOWN                     = "?"

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
    SST_RESTRICTED     = "Y",
    SST_NOT_RESTRICTED = "N"
  } dir_short_sale_threshold_indicator_e;

  typedef enum logic [7:0] {
    IPO_SECURITY    = "Y",
    NO_IPO_SECURITY = "N"
  } dir_ipo_flag_e;

  typedef enum logic [7:0] {
    TIER_1 = "1",
    TIER_2 = "2"
  } dir_LULUDReference_Price_Tier_e;

  typedef enum logic [7:0] {
    INSTRUMENT_ETP     = "Y",
    INSTRUMENT_NOT_ETP = "N"
  } dir_ETP_flag_e;

  typedef enum logic [7:0] {
    ETP_INVERSE_ETP     = "Y",
    ETP_NOT_INVERSE_ETP = "N"
  } dir_ETP_inverse_indicator_e;

  typedef enum logic [7:0] {
    BUY  = "B",
    SELL = "S"
  } buy_or_sell_e;


  //Functions
  function dir_market_category_e parse_market_category(input logic [7:0] b);
    begin
      case (b)
        "Q": return NASDAQ_GLOBAL_SELECT_MARKET;
        "G": return NASDAQ_GLOBAL_MARKET;
        "S": return NASDAQ_CAPTIAL_MARKET;
        "N": return NYSE;
        "A": return NYSE_AMERICAN;
        "P": return NYSE_ARCA;
        "Z": return BATS_Z_EXCHANGE;
        "V": return INVERSTORS_EXCHANGE;
        default: return UNKNOWN;
      endcase
    end
  endfunction

  function dir_financial_status_indicator_e parse_financial_status(input logic [7:0] b);
    begin
      case (b)
        "D": return DEFICIENT;
        "E": return DELINQUENT;
        "Q": return BANKRUPT;
        "S": return SUSPENDED;
        "G": return DEFICIENT_BANKRUPT;
        "H": return DEFICIENT_DELINQUENT;
        "J": return DELINQUENT_BANKRUPT;
        "K": return DEFICIENT_DELINQUENT_BANKRUPT;
        "C": return SUSPENDED_FOR_ETP;
        "N": return NORMAL;
        default: return dir_financial_status_indicator_e'(DEFAULT);
      endcase
    end
  endfunction

  function dir_round_lot_size_e parse_round_lots_only(input logic [7:0] b);
    begin
      case (b)
        "Y": return ACCEPTS_ROUND_LOTS;
        "N": return NO_ORDER_SIZE_RESTRICTION;
        default: return dir_round_lot_size_e'(DEFAULT);
      endcase
    end
  endfunction

  function dir_authenticity_e parse_authenticity(input logic [7:0] b);
    begin
      case (b)
        "P": return LIVE_PRODUCTION;
        "T": return TEST;
        default: return dir_authenticity_e'(DEFAULT);
      endcase
    end
  endfunction

  function dir_short_sale_threshold_indicator_e parse_SST_Indicator(input logic [7:0] b);
    begin
      case (b)
        "P": return SST_RESTRICTED;
        "T": return SST_NOT_RESTRICTED;
        default: return dir_short_sale_threshold_indicator_e'(DEFAULT);
      endcase
    end
  endfunction

  function dir_ipo_flag_e parse_IPO_Flag(input logic [7:0] b);
    begin
      case (b)
        "Y": return IPO_SECURITY;
        "N": return NO_IPO_SECURITY;
        default: return dir_ipo_flag_e'(DEFAULT);
      endcase
    end
  endfunction

  function dir_LULUDReference_Price_Tier_e parse_Price_Tier(input logic [7:0] b);
    begin
      case (b)
        "1": return TIER_1;
        "2": return TIER_2;
        default: return dir_LULUDReference_Price_Tier_e'(DEFAULT);
      endcase
    end
  endfunction

  function dir_ETP_flag_e parse_ETP_Flag(input logic [7:0] b);
    begin
      case (b)
        "Y": return INSTRUMENT_ETP;
        "N": return INSTRUMENT_NOT_ETP;
        default: return dir_ETP_flag_e'(DEFAULT);
      endcase
    end
  endfunction

  function dir_ETP_inverse_indicator_e parse_ETP_inverse_indicator(input logic [7:0] b);
    begin
      case (b)
        "Y": return ETP_INVERSE_ETP;
        "N": return ETP_NOT_INVERSE_ETP;
        default: return dir_ETP_inverse_indicator_e'(DEFAULT);
      endcase
    end
  endfunction

  //-----------------------------------------------------------------------------------------//


  typedef enum logic [7:0] {
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


  typedef enum logic [4:0] {SYSTEM_EVENT_MESSAGE_LENGTH = 12} message_lengths;

  //SYSTEM MESSAGE

  typedef struct packed {
    logic [7:0]  sys_message_type;
    logic [15:0] sys_stock_locate;
    logic [15:0] sys_tracking_number;
    logic [47:0] sys_time_stamp;
    logic [7:0]  sys_event_code;
  } System_Event_Message;

  typedef enum logic [7:0] {
    EVENT_START_MESSAGES = "O",
    EVENT_START_SYSTEM   = "S",
    EVENT_START_MARKET   = "Q",
    EVENT_END_MARKET     = "M",
    EVENT_END_SYSTEM     = "E",
    EVENT_END_MESSAGES   = "C"

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

  //ORDER EXECUTED WITH PRICE
  typedef struct packed {
    logic [7:0] message_type;
    logic [15:0] stock_locate;
    logic [15:0] tracking_number;
    logic [47:0] time_stamp;
    logic [63:0] order_reference_number;
    logic [31:0] shares;
    logic [63:0] match_number;
    logic [7:0] printable;
    logic [31:0] price;  //4dec
  } Order_Executed_With_Price_Message;

  //ORDER CANCEL MESSAGE
  typedef struct packed {
    logic [7:0]  message_type;
    logic [15:0] stock_locate;
    logic [15:0] tracking_number;
    logic [47:0] time_stamp;
    logic [63:0] order_reference_number;
    logic [31:0] shares;
  } Order_Cancel_Message;

  //ORDER DELETE MESSAGE
  typedef struct packed {
    logic [7:0]  message_type;
    logic [15:0] stock_locate;
    logic [15:0] tracking_number;
    logic [47:0] time_stamp;
    logic [63:0] order_reference_number;
  } Order_Delete_Message;

  //ORDER REPLACE MESSAGE
  typedef struct packed {
    logic [7:0] message_type;
    logic [15:0] stock_locate;
    logic [15:0] tracking_number;
    logic [47:0] time_stamp;
    logic [63:0] original_order_reference_number;
    logic [63:0] new_order_reference_number;
    logic [31:0] shares;
    logic [31:0] price;  //4dec
  } Order_Replace_Message;




 typedef struct packed {
   //logic orm_ready; As there is already begin_processing variable
    logic new_orm_ready;
    logic buy_sell_ready;
    logic shares_ready;
    logic price_ready;
    logic match_number_ready;

   } Message_Content_Ready;


endpackage
