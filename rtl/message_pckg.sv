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





endpackage