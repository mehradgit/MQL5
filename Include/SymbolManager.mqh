//+------------------------------------------------------------------+
//| SymbolManager.mqh - مدیریت انواع نمادها و تنظیمات               |
//+------------------------------------------------------------------+
#property library
#property strict

// --- ENUM FOR SYMBOL TYPES ---
enum ENUM_SYMBOL_TYPE
  {
   SYMBOL_TYPE_GOLD,      // 0: Gold
   SYMBOL_TYPE_DOW,       // 1: Dow Jones
   SYMBOL_TYPE_NASDAQ,    // 2: Nasdaq
   SYMBOL_TYPE_FOREX,     // 3: Forex pairs
   SYMBOL_TYPE_UNKNOWN    // 4: Unknown
  };

// --- STRUCTURES ---
struct SymbolSettings
  {
   double max_lot;
   double default_sl_pips;
   double default_tp_pips;
   int    max_slippage_pips;
   int    pending_distance_pips;
  };

// --- GLOBAL SETTINGS ---
SymbolSettings gold_settings, dow_settings, nas_settings, forex_settings;

// --- FUNCTION PROTOTYPES ---
void InitializeSymbolSettings();
ENUM_SYMBOL_TYPE GetSymbolType(string symbol);
SymbolSettings GetSymbolSettings(ENUM_SYMBOL_TYPE symType);
string GetSymbolTypeName(ENUM_SYMBOL_TYPE symType);
double CalculatePendingPrice(string orderType, double slPrice, string symbol, int distancePips, ENUM_SYMBOL_TYPE symType);
double CalculateDefaultSL(string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings settings, double currentPrice, bool isBuy);
double CalculatePositionSize(string symbol, double totalRiskMoney, double distSL);
double GetFirstTP(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings settings, double currentPrice, bool isBuy, double pendingPrice = 0);

//+------------------------------------------------------------------+
//| Initialize Symbol Settings                                       |
//+------------------------------------------------------------------+
void InitializeSymbolSettings()
  {
   gold_settings.max_lot = MaxLotSize_GOLD;
   gold_settings.default_sl_pips = DefaultStopPips_GOLD;
   gold_settings.default_tp_pips = DefaultTpForOpenPips_GOLD;
   gold_settings.max_slippage_pips = MaxSlippageForMarketPips_GOLD;
   gold_settings.pending_distance_pips = PendingOrderDistanceFromSL_GOLD;
   
   dow_settings.max_lot = MaxLotSize_DOW;
   dow_settings.default_sl_pips = DefaultStopPips_DOW;
   dow_settings.default_tp_pips = DefaultTpForOpenPips_DOW;
   dow_settings.max_slippage_pips = MaxSlippageForMarketPips_DOW;
   dow_settings.pending_distance_pips = PendingOrderDistanceFromSL_DOW;
   
   nas_settings.max_lot = MaxLotSize_NAS;
   nas_settings.default_sl_pips = DefaultStopPips_NAS;
   nas_settings.default_tp_pips = DefaultTpForOpenPips_NAS;
   nas_settings.max_slippage_pips = MaxSlippageForMarketPips_NAS;
   nas_settings.pending_distance_pips = PendingOrderDistanceFromSL_NAS;
   
   forex_settings.max_lot = MaxLotSize_FOREX;
   forex_settings.default_sl_pips = DefaultStopPips_FOREX;
   forex_settings.default_tp_pips = DefaultTpForOpenPips_FOREX;
   forex_settings.max_slippage_pips = MaxSlippageForMarketPips_FOREX;
   forex_settings.pending_distance_pips = PendingOrderDistanceFromSL_FOREX;
  }

//+------------------------------------------------------------------+
//| Get Symbol Type                                                  |
//+------------------------------------------------------------------+
ENUM_SYMBOL_TYPE GetSymbolType(string symbol)
  {
   string symLower = StringToLowerCustom(symbol);
   
   // Check for GOLD
   if(StringFind(symLower, "xau") >= 0 || StringFind(symLower, "gold") >= 0)
      return SYMBOL_TYPE_GOLD;
   
   // Check for DOW JONES
   if(StringFind(symLower, "us30") >= 0 || StringFind(symLower, "dow") >= 0 || 
      StringFind(symLower, "dj") >= 0 || StringFind(symLower, "yinusd") >= 0)
      return SYMBOL_TYPE_DOW;
   
   // Check for NASDAQ
   if(StringFind(symLower, "nas100") >= 0 || StringFind(symLower, "nas") >= 0 || 
      StringFind(symLower, "nq") >= 0 || StringFind(symLower, "ustec") >= 0)
      return SYMBOL_TYPE_NASDAQ;
   
   // Default to FOREX for other symbols
   return SYMBOL_TYPE_FOREX;
  }

//+------------------------------------------------------------------+
//| Get Symbol Settings                                              |
//+------------------------------------------------------------------+
SymbolSettings GetSymbolSettings(ENUM_SYMBOL_TYPE symType)
  {
   SymbolSettings settings;
   
   switch(symType)
     {
      case SYMBOL_TYPE_GOLD:
         settings.max_lot = gold_settings.max_lot;
         settings.default_sl_pips = gold_settings.default_sl_pips;
         settings.default_tp_pips = gold_settings.default_tp_pips;
         settings.max_slippage_pips = gold_settings.max_slippage_pips;
         settings.pending_distance_pips = gold_settings.pending_distance_pips;
         break;
         
      case SYMBOL_TYPE_DOW:
         settings.max_lot = dow_settings.max_lot;
         settings.default_sl_pips = dow_settings.default_sl_pips;
         settings.default_tp_pips = dow_settings.default_tp_pips;
         settings.max_slippage_pips = dow_settings.max_slippage_pips;
         settings.pending_distance_pips = dow_settings.pending_distance_pips;
         break;
         
      case SYMBOL_TYPE_NASDAQ:
         settings.max_lot = nas_settings.max_lot;
         settings.default_sl_pips = nas_settings.default_sl_pips;
         settings.default_tp_pips = nas_settings.default_tp_pips;
         settings.max_slippage_pips = nas_settings.max_slippage_pips;
         settings.pending_distance_pips = nas_settings.pending_distance_pips;
         break;
         
      case SYMBOL_TYPE_FOREX:
      default:
         settings.max_lot = forex_settings.max_lot;
         settings.default_sl_pips = forex_settings.default_sl_pips;
         settings.default_tp_pips = forex_settings.default_tp_pips;
         settings.max_slippage_pips = forex_settings.max_slippage_pips;
         settings.pending_distance_pips = forex_settings.pending_distance_pips;
         break;
     }
   
   return settings;
  }

//+------------------------------------------------------------------+
//| Get Symbol Type Name                                             |
//+------------------------------------------------------------------+
string GetSymbolTypeName(ENUM_SYMBOL_TYPE symType)
  {
   switch(symType)
     {
      case SYMBOL_TYPE_GOLD:    return "GOLD";
      case SYMBOL_TYPE_DOW:     return "DOW JONES";
      case SYMBOL_TYPE_NASDAQ:  return "NASDAQ";
      case SYMBOL_TYPE_FOREX:   return "FOREX";
      default:                  return "UNKNOWN";
     }
  }

//+------------------------------------------------------------------+
//| Calculate Pending Price Based on SL                              |
//+------------------------------------------------------------------+
double CalculatePendingPrice(string orderType, double slPrice, string symbol, int distancePips, ENUM_SYMBOL_TYPE symType)
  {
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   // Adjust multiplier based on symbol type
   double multiplier = 1.0;
   switch(symType)
     {
      case SYMBOL_TYPE_GOLD:
         multiplier = 10.0; // For gold, every 0.01 = 1 pip
         break;
      case SYMBOL_TYPE_DOW:
      case SYMBOL_TYPE_NASDAQ:
         multiplier = 1.0; // For indices, 1 point = 1 pip
         break;
      case SYMBOL_TYPE_FOREX:
         multiplier = 10.0; // For forex, 0.0001 = 1 pip
         break;
     }
   
   double distancePoints = distancePips * point * multiplier;
   
   if(StringCompare(orderType, "buy", false) == 0)
     {
      // For BUY: Pending price = SL + distance
      return slPrice + distancePoints;
     }
   else // sell
     {
      // For SELL: Pending price = SL - distance
      return slPrice - distancePoints;
     }
  }

//+------------------------------------------------------------------+
//| Calculate Default SL                                             |
//+------------------------------------------------------------------+
double CalculateDefaultSL(string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings settings, double currentPrice, bool isBuy)
  {
   double pt = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double pips = settings.default_sl_pips;
   
   // Adjust for symbol type
   if(symType == SYMBOL_TYPE_GOLD) 
      pips = pips * 10.0; // Convert to points
   else if(symType == SYMBOL_TYPE_DOW || symType == SYMBOL_TYPE_NASDAQ)
      pips = pips; // Already in points
   else
      pips = pips / 10.0; // Convert to points
   
   double dist = pips * pt;
   return isBuy ? currentPrice - dist : currentPrice + dist;
  }

//+------------------------------------------------------------------+
//| Calculate Position Size                                          |
//+------------------------------------------------------------------+
double CalculatePositionSize(string symbol, double totalRiskMoney, double distSL)
  {
   double lot = 0.01;
   double ptVal = EstimatePipValuePerLot(symbol);
   double ptSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   if(distSL > 0 && ptVal > 0 && ptSize > 0)
     {
      double distPoints = distSL / ptSize;
      lot = totalRiskMoney / (distPoints * ptVal);
     }
   
   return lot;
  }

//+------------------------------------------------------------------+
//| Get First TP                                                     |
//+------------------------------------------------------------------+
double GetFirstTP(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings settings, double currentPrice, bool isBuy, double pendingPrice = 0)
  {
   double firstTP = (sig.tp_count > 0) ? sig.tp_list[0] : 0;
   
   if(firstTP <= 0)
     {
      double pt = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double pips = settings.default_tp_pips;
      
      // Adjust for symbol type
      if(symType == SYMBOL_TYPE_GOLD) 
         pips = pips * 10.0;
      else if(symType == SYMBOL_TYPE_DOW || symType == SYMBOL_TYPE_NASDAQ)
         pips = pips;
      else
         pips = pips / 10.0;
         
      double dist = pips * pt;
      double priceRef = (pendingPrice > 0) ? pendingPrice : currentPrice;
      firstTP = isBuy ? priceRef + dist : priceRef - dist;
     }
   
   return firstTP;
  }

//+------------------------------------------------------------------+
//| Estimate Pip Value Per Lot                                       |
//+------------------------------------------------------------------+
double EstimatePipValuePerLot(string symbol)
  {
   double v = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double s = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   if(v > 0 && s > 0) return v/s;
   return 10.0;
  }

//+------------------------------------------------------------------+
//| Normalize Lot to Symbol                                          |
//+------------------------------------------------------------------+
double NormalizeLotToSymbol(double lot, string symbol)
  {
   double min = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double max = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   if(min <= 0) min = 0.01;
   if(step <= 0) step = 0.01;
   
   if(lot < min) lot = min;
   if(lot > max) lot = max;
   
   double steps = MathFloor(lot/step + 0.000001);
   lot = steps * step;
   
   return NormalizeDouble(lot, 2);
  }
//+------------------------------------------------------------------+