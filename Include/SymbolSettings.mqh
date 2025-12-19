//+------------------------------------------------------------------+
//| SymbolSettings.mqh - تنظیمات جداگانه برای هر نوع نماد           |
//+------------------------------------------------------------------+
#property library
#property strict

input group "Execution Settings - GOLD (XAUUSD, GOLD)"
input double MaxLotSize_GOLD     = 10.0;  // Max lot size for GOLD
input double DefaultStopPips_GOLD = 200;  // Default SL for GOLD (pips)
input double DefaultTpForOpenPips_GOLD = 200;  // Default TP for GOLD (pips)
input int    MaxSlippageForMarketPips_GOLD = 50;  // Max slippage for GOLD
input int    PendingOrderDistanceFromSL_GOLD = 200;  // Pending distance for GOLD

input group "Execution Settings - DOW JONES (US30, DOW)"
input double MaxLotSize_DOW      = 10.0;  // Max lot size for DOW
input double DefaultStopPips_DOW = 300;   // Default SL for DOW (pips)
input double DefaultTpForOpenPips_DOW = 300;  // Default TP for DOW (pips)
input int    MaxSlippageForMarketPips_DOW = 100;  // Max slippage for DOW
input int    PendingOrderDistanceFromSL_DOW = 300;  // Pending distance for DOW

input group "Execution Settings - NASDAQ (NAS100, NAS)"
input double MaxLotSize_NAS      = 10.0;  // Max lot size for NASDAQ
input double DefaultStopPips_NAS = 400;   // Default SL for NASDAQ (pips)
input double DefaultTpForOpenPips_NAS = 400;  // Default TP for NASDAQ (pips)
input int    MaxSlippageForMarketPips_NAS = 150;  // Max slippage for NASDAQ
input int    PendingOrderDistanceFromSL_NAS = 400;  // Pending distance for NASDAQ

input group "Execution Settings - OTHER PAIRS (EURUSD, GBPUSD, etc)"
input double MaxLotSize_FOREX    = 10.0;  // Max lot size for FOREX
input double DefaultStopPips_FOREX = 100; // Default SL for FOREX (pips)
input double DefaultTpForOpenPips_FOREX = 100;  // Default TP for FOREX (pips)
input int    MaxSlippageForMarketPips_FOREX = 30;  // Max slippage for FOREX
input int    PendingOrderDistanceFromSL_FOREX = 100;  // Pending distance for FOREX