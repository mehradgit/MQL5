//+------------------------------------------------------------------+
//| SignalExecutor.mq5                                               |
//| Expert Advisor: Signal Execution from JSON File                 |
//| Version: 1.86 (Enhanced Execution Logic)                        |
//+------------------------------------------------------------------+
#property copyright "Generated for mehradgit"
#property version "1.86"
#property strict

#include <Trade\Trade.mqh>

// ================ INPUT PARAMETERS ================

input group "General Settings" input int PollIntervalSeconds = 2; // Poll Interval (seconds)
input string SignalFileName = "output";                           // Filename
input string DefaultSymbol = "XAUUSD";                            // Default Symbol
input bool EnableLogging = true;                                  // Enable Journal Logging
input long ExpertMagicNumber = 123456;                            // Base Magic Number

input group "Risk Management" input double RiskPercentPerSignal = 1.0; // Risk per Signal (%)
input bool EnableGlobalRiskLimit = true;                               // فعال‌سازی محدودیت ریسک کلی
input double MaxTotalRiskPercent = 30.0;                               // حداکثر ریسک کل پوزیشن‌ها (%)

input group "Execution Settings - GOLD (XAUUSD, GOLD)" input double MaxLotSize_GOLD = 10.0; // Max lot size for GOLD
input double DefaultStopPips_GOLD = 200;                                                    // Default SL for GOLD (pips)
input double DefaultTpForOpenPips_GOLD = 200;                                               // Default TP for GOLD (pips)
input int MaxSlippageForMarketPips_GOLD = 50;                                               // Max slippage for GOLD
input int PendingOrderDistanceFromSL_GOLD = 200;                                            // Pending distance for GOLD

input group "Execution Settings - DOW JONES (US30, DOW)" input double MaxLotSize_DOW = 10.0; // Max lot size for DOW
input double DefaultStopPips_DOW = 300;                                                      // Default SL for DOW (pips)
input double DefaultTpForOpenPips_DOW = 300;                                                 // Default TP for DOW (pips)
input int MaxSlippageForMarketPips_DOW = 100;                                                // Max slippage for DOW
input int PendingOrderDistanceFromSL_DOW = 300;                                              // Pending distance for DOW

input group "Execution Settings - NASDAQ (NAS100, NAS)" input double MaxLotSize_NAS = 10.0; // Max lot size for NASDAQ
input double DefaultStopPips_NAS = 400;                                                     // Default SL for NASDAQ (pips)
input double DefaultTpForOpenPips_NAS = 400;                                                // Default TP for NASDAQ (pips)
input int MaxSlippageForMarketPips_NAS = 150;                                               // Max slippage for NASDAQ
input int PendingOrderDistanceFromSL_NAS = 400;                                             // Pending distance for NASDAQ

input group "Execution Settings - OTHER PAIRS (EURUSD, GBPUSD, etc)" input double MaxLotSize_FOREX = 10.0; // Max lot size for FOREX
input double DefaultStopPips_FOREX = 100;                                                                  // Default SL for FOREX (pips)
input double DefaultTpForOpenPips_FOREX = 100;                                                             // Default TP for FOREX (pips)
input int MaxSlippageForMarketPips_FOREX = 30;                                                             // Max slippage for FOREX
input int PendingOrderDistanceFromSL_FOREX = 100;                                                          // Pending distance for FOREX

// ================ ADVANCED RISK MANAGEMENT SETTINGS ================

input group "Risk Management Stages - GOLD" input int Gold_Stage1_Pips = 10; // Stage 1: Profit pips for partial close
input double Gold_Stage1_ClosePercent = 10.0;                                // % to close at stage 1
input int Gold_Stage2_Pips = 20;                                             // Stage 2: Profit pips
input double Gold_Stage2_ClosePercent = 15.0;                                // % to close at stage 2
input int Gold_Stage2_BreakEvenPips = 5;                                     // SL to break-even (+5 pips)
input int Gold_Stage3_Pips = 25;                                             // Stage 3: Profit pips
input double Gold_Stage3_ClosePercent = 20.0;                                // % to close at stage 3
input int Gold_TrailingStopPips = 10;                                        // Trailing stop distance
input int Gold_GlobalRiskFreePips = 30;                                      // Global risk-free level
input int Gold_RiskFreeDistance = 10;                                        // Risk-free SL distance from entry
input int Gold_ClosePendingAtProfit = 15;                                    // Close pending orders when profit reaches X pips

input group "Risk Management Stages - DOW JONES" input int Dow_Stage1_Pips = 15;
input double Dow_Stage1_ClosePercent = 10.0;
input int Dow_Stage2_Pips = 30;
input double Dow_Stage2_ClosePercent = 15.0;
input int Dow_Stage2_BreakEvenPips = 8;
input int Dow_Stage3_Pips = 40;
input double Dow_Stage3_ClosePercent = 20.0;
input int Dow_TrailingStopPips = 15;
input int Dow_GlobalRiskFreePips = 45;
input int Dow_RiskFreeDistance = 15;
input int Dow_ClosePendingAtProfit = 20;

input group "Risk Management Stages - NASDAQ" input int Nas_Stage1_Pips = 20;
input double Nas_Stage1_ClosePercent = 10.0;
input int Nas_Stage2_Pips = 40;
input double Nas_Stage2_ClosePercent = 15.0;
input int Nas_Stage2_BreakEvenPips = 10;
input int Nas_Stage3_Pips = 50;
input double Nas_Stage3_ClosePercent = 20.0;
input int Nas_TrailingStopPips = 20;
input int Nas_GlobalRiskFreePips = 60;
input int Nas_RiskFreeDistance = 20;
input int Nas_ClosePendingAtProfit = 30;

input group "Risk Management Stages - FOREX" input int Forex_Stage1_Pips = 8;
input double Forex_Stage1_ClosePercent = 10.0;
input int Forex_Stage2_Pips = 15;
input double Forex_Stage2_ClosePercent = 15.0;
input int Forex_Stage2_BreakEvenPips = 3;
input int Forex_Stage3_Pips = 20;
input double Forex_Stage3_ClosePercent = 20.0;
input int Forex_TrailingStopPips = 5;
input int Forex_GlobalRiskFreePips = 25;
input int Forex_RiskFreeDistance = 8;
input int Forex_ClosePendingAtProfit = 10;

input group "Other Settings" input bool CloseOthersOnFirstTP = false; // Close other positions if one hits TP
input bool DeletePendingOnTP = true;                                  // Delete pending orders if one hits TP
input bool EnableRiskManagement = true;                               // Enable advanced risk management
input bool ClosePendingOnProfit = true;                               // Close pending orders when profit target reached
input int RiskCheckInterval = 5;                                      // Check risk every N seconds

input group "Telegram Settings" input string TelegramBotToken = "7988454640:AAFv_VAwdn_DZZnqtUaU48iGq8Y3IMTTuPI";
input string TelegramChatID = "-4708601845";
input bool EnableTelegram = true;
input int TelegramTimeout = 5000;

// ================ TP/SL ADJUSTMENT SETTINGS ================

// گروه 1: تنظیمات GOLD (XAUUSD, GOLD)
input group "TP/SL Adjustment - GOLD (MARKET)" input double Gold_BuyMarketTP_AdjustPips = 0.0; // Buy Market TP adjustment (pips)
input double Gold_BuyMarketSL_AdjustPips = 0.0;                                                // Buy Market SL adjustment (pips)
input double Gold_SellMarketTP_AdjustPips = 0.0;                                               // Sell Market TP adjustment (pips)
input double Gold_SellMarketSL_AdjustPips = 0.0;                                               // Sell Market SL adjustment (pips)

input group "TP/SL Adjustment - GOLD (PENDING)" input double Gold_BuyPendingTP_AdjustPips = 0.0; // Buy Pending TP adjustment (pips)
input double Gold_BuyPendingSL_AdjustPips = 0.0;                                                 // Buy Pending SL adjustment (pips)
input double Gold_SellPendingTP_AdjustPips = 0.0;                                                // Sell Pending TP adjustment (pips)
input double Gold_SellPendingSL_AdjustPips = 0.0;                                                // Sell Pending SL adjustment (pips)

// گروه 2: تنظیمات DOW JONES (US30, DOW)
input group "TP/SL Adjustment - DOW JONES (MARKET)" input double Dow_BuyMarketTP_AdjustPips = 0.0; // Buy Market TP adjustment (pips)
input double Dow_BuyMarketSL_AdjustPips = 0.0;                                                     // Buy Market SL adjustment (pips)
input double Dow_SellMarketTP_AdjustPips = 0.0;                                                    // Sell Market TP adjustment (pips)
input double Dow_SellMarketSL_AdjustPips = 0.0;                                                    // Sell Market SL adjustment (pips)

input group "TP/SL Adjustment - DOW JONES (PENDING)" input double Dow_BuyPendingTP_AdjustPips = 0.0; // Buy Pending TP adjustment (pips)
input double Dow_BuyPendingSL_AdjustPips = 0.0;                                                      // Buy Pending SL adjustment (pips)
input double Dow_SellPendingTP_AdjustPips = 0.0;                                                     // Sell Pending TP adjustment (pips)
input double Dow_SellPendingSL_AdjustPips = 0.0;                                                     // Sell Pending SL adjustment (pips)

// گروه 3: تنظیمات NASDAQ (NAS100, NAS)
input group "TP/SL Adjustment - NASDAQ (MARKET)" input double Nas_BuyMarketTP_AdjustPips = 0.0; // Buy Market TP adjustment (pips)
input double Nas_BuyMarketSL_AdjustPips = 0.0;                                                  // Buy Market SL adjustment (pips)
input double Nas_SellMarketTP_AdjustPips = 0.0;                                                 // Sell Market TP adjustment (pips)
input double Nas_SellMarketSL_AdjustPips = 0.0;                                                 // Sell Market SL adjustment (pips)

input group "TP/SL Adjustment - NASDAQ (PENDING)" input double Nas_BuyPendingTP_AdjustPips = 0.0; // Buy Pending TP adjustment (pips)
input double Nas_BuyPendingSL_AdjustPips = 0.0;                                                   // Buy Pending SL adjustment (pips)
input double Nas_SellPendingTP_AdjustPips = 0.0;                                                  // Sell Pending TP adjustment (pips)
input double Nas_SellPendingSL_AdjustPips = 0.0;                                                  // Sell Pending SL adjustment (pips)

// گروه 4: تنظیمات FOREX (EURUSD, GBPUSD, etc)
input group "TP/SL Adjustment - FOREX (MARKET)" input double Forex_BuyMarketTP_AdjustPips = 0.0; // Buy Market TP adjustment (pips)
input double Forex_BuyMarketSL_AdjustPips = 0.0;                                                 // Buy Market SL adjustment (pips)
input double Forex_SellMarketTP_AdjustPips = 0.0;                                                // Sell Market TP adjustment (pips)
input double Forex_SellMarketSL_AdjustPips = 0.0;                                                // Sell Market SL adjustment (pips)

input group "TP/SL Adjustment - FOREX (PENDING)" input double Forex_BuyPendingTP_AdjustPips = 0.0; // Buy Pending TP adjustment (pips)
input double Forex_BuyPendingSL_AdjustPips = 0.0;                                                  // Buy Pending SL adjustment (pips)
input double Forex_SellPendingTP_AdjustPips = 0.0;                                                 // Sell Pending TP adjustment (pips)
input double Forex_SellPendingSL_AdjustPips = 0.0;                                                 // Sell Pending SL adjustment (pips)

// ================ STRUCTURES AND ENUMS ================

enum ENUM_SYMBOL_TYPE
{
  SYMBOL_TYPE_GOLD,   // 0: Gold
  SYMBOL_TYPE_DOW,    // 1: Dow Jones
  SYMBOL_TYPE_NASDAQ, // 2: Nasdaq
  SYMBOL_TYPE_FOREX,  // 3: Forex pairs
  SYMBOL_TYPE_UNKNOWN // 4: Unknown
};

struct SymbolSettings
{
  double max_lot;
  double default_sl_pips;
  double default_tp_pips;
  int max_slippage_pips;
  int pending_distance_pips;

  // Risk management settings
  int stage1_pips;
  double stage1_close_percent;
  int stage2_pips;
  double stage2_close_percent;
  int stage2_breakeven_pips;
  int stage3_pips;
  double stage3_close_percent;
  int trailing_stop_pips;
  int global_riskfree_pips;
  int riskfree_distance;
  int close_pending_at_profit;
};

struct PositionRiskData
{
  ulong ticket;
  string signal_id;
  double entry_price;
  double original_sl;
  double original_tp;
  double current_sl;
  int stage_completed; // 0=none, 1=stage1, 2=stage2, 3=stage3
  bool risk_free_active;
  double best_price; // For trailing stop
  datetime last_check;
  bool pending_closed; // Track if pending orders already closed
};

struct SignalData
{
  string currency;
  string order_type;
  double prices_list[];
  bool prices_isMarket[];
  int prices_count;
  double tp_list[];
  int tp_count;
  double sl_list[];
  int sl_count;
  string signal_id;
  string status;
};

// ================ GLOBAL VARIABLES ================

CTrade trade;
bool g_initialized = false;
datetime last_history_check = 0;
datetime last_risk_check = 0;
SymbolSettings gold_settings, dow_settings, nas_settings, forex_settings;
PositionRiskData risk_data_array[100];
int risk_data_count = 0;

// ================ FUNCTION PROTOTYPES ================

// Main Functions
void ProcessSignalFile();
void ManageOpenPositions();
void ManageRiskForOpenPositions();
void CloseGroupOrders(string signalID);
void ClosePendingOrdersForSignal(string signalID, string reason);

// Risk Management Functions
void InitializeRiskDataForPosition(ulong ticket, string signalID, double entryPrice, double slPrice, double tpPrice);
void UpdateRiskDataForPosition(ulong ticket, double currentPrice);
void ApplyRiskManagement(ulong ticket, string symbol, ENUM_SYMBOL_TYPE symType);
void ClosePartialPosition(ulong ticket, double percent, string reason);
void MoveToBreakEven(ulong ticket, double entryPrice, int breakEvenPips, bool isBuy, string symbol);
void ApplyTrailingStop(ulong ticket, double currentPrice, int trailingPips, bool isBuy, string symbol);
void ApplyGlobalRiskFree(ulong ticket, double entryPrice, int riskFreePips, int riskFreeDistance, bool isBuy, string symbol);
SymbolSettings GetRiskManagementSettings(ENUM_SYMBOL_TYPE symType);
void InitializeRiskManagementSettings();

// JSON Processing
bool ParseJsonContent(string content, SignalData &out);
string ExtractJsonValue(string json, string key);
bool ExtractJsonArray(string json, string arrayKey, double &outArray[], int &outCount);
string NormalizeContentLines(string content);

// Symbol Management
ENUM_SYMBOL_TYPE GetSymbolType(string symbol);
SymbolSettings GetSymbolSettings(ENUM_SYMBOL_TYPE symType);
string GetSymbolTypeName(ENUM_SYMBOL_TYPE symType);
void InitializeSymbolSettings();
double CalculatePendingPrice(string orderType, double slPrice, double currentPrice, string symbol, int distancePips, ENUM_SYMBOL_TYPE symType, bool isBuy);
double CalculateDefaultSL(string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings, double currentPrice, bool isBuy);
double CalculatePositionSize(string symbol, double totalRiskMoney, double distSL);
double GetFirstTP(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings, double referencePrice, bool isBuy, string orderType = "", bool isMarketOrder = false, bool isPendingOrder = false);

// Order Management
bool SendOrder(string symbol, string order_type, bool isMarket, double entryPrice, double sl_price, double tp_price, double lot, string signalID);
bool SendMarketOrder(string symbol, string order_type, double sl_price, double tp_price, double lot, string signalID);
bool SendPendingOrder(string symbol, string order_type, double entryPrice, double sl_price, double tp_price, double lot, string signalID);
void ProcessSignalWithSmartLogic(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings,
                                 double totalRiskMoney, string signalID, int &successCount, double &totalVolume);

// Telegram Functions
bool SendTelegramMessage(string message);
bool SendTelegramFarsi(string message);
bool CheckTelegramSettings();
void SendExecutionReport(string signalID, string symbol, string orderType, int totalOrders, int successfulOrders,
                         double totalVolume, bool singleOrderMode, bool pendingMode, double pendingPrice, ENUM_SYMBOL_TYPE symType);
void SendRiskManagementAlert(string symbol, string signalID, int stage, string action, double profitPips);
void SendSignalAlert(string signalID, string symbol, string message);

// Helper Functions
void PrintLog(string message);
string StringTrimCustom(string str);
string StringToLowerCustom(string str);
bool StringContains(string str, string substr);
double EstimatePipValuePerLot(string symbol);
double NormalizeLotToSymbol(double lot, string symbol);
double CalculatePipsProfit(double entryPrice, double currentPrice, bool isBuy, string symbol, ENUM_SYMBOL_TYPE symType);
int CountOpenPositionsForSignal(string signalID);
int CountPendingOrdersForSignal(string signalID);

// ================ MAIN FUNCTIONS ================

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
  int poll = PollIntervalSeconds;
  if (poll < 1)
    poll = 1;

  EventSetTimer(poll);
  trade.SetExpertMagicNumber(ExpertMagicNumber);
  trade.SetTypeFilling(ORDER_FILLING_FOK);

  InitializeSymbolSettings();
  InitializeRiskManagementSettings();

  PrintLog("SignalExecutor v1.85 with Enhanced Execution Logic initialized.");

  if (EnableTelegram)
  {
    if (!CheckTelegramSettings())
      PrintLog("Warning: Telegram settings invalid.");
    else
      SendTelegramFarsi("🤖 *SignalExecutor v1.85 Started*\n" +
                        "Symbol: " + DefaultSymbol + "\n" +
                        "Risk Management: ACTIVE\n" +
                        "Close Pending on Profit: " + (ClosePendingOnProfit ? "YES" : "NO") + "\n" +
                        "Time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
  }

  last_history_check = TimeCurrent();
  last_risk_check = TimeCurrent();
  g_initialized = true;
  return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  EventKillTimer();
  if (EnableTelegram)
    SendTelegramFarsi("🔴 *SignalExecutor Stopped*");
  PrintLog("SignalExecutor deinitialized.");
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
  ProcessSignalFile();
  ManageOpenPositions();
  // مانیتور ریسک کلی (هر 30 ثانیه)
  static datetime lastRiskMonitor = 0;
  if (TimeCurrent() - lastRiskMonitor >= 30)
  {
    if (EnableGlobalRiskLimit)
    {
      double currentRiskPercent = CalculateTotalRiskPercentage();
      if (currentRiskPercent > MaxTotalRiskPercent * 0.8) // اگر بیش از 80% حد مجاز
      {
        PrintLog("⚠️ WARNING: Total risk approaching limit: " +
                 DoubleToString(currentRiskPercent, 1) + "%");

        if (EnableTelegram && currentRiskPercent > MaxTotalRiskPercent * 0.9)
        {
          SendTelegramFarsi("⚠️ *Risk Warning*\n" +
                            "Total risk: " + DoubleToString(currentRiskPercent, 1) + "%\n" +
                            "Limit: " + DoubleToString(MaxTotalRiskPercent, 1) + "%\n" +
                            "Approaching maximum limit!");
        }
      }
    }
    lastRiskMonitor = TimeCurrent();
  }
  // Check risk management at specified interval
  if (EnableRiskManagement && (TimeCurrent() - last_risk_check >= RiskCheckInterval))
  {
    ManageRiskForOpenPositions();
    last_risk_check = TimeCurrent();
  }
}

//+------------------------------------------------------------------+
//| Main Processing Function                                         |
//+------------------------------------------------------------------+
void ProcessSignalFile()
{
  string file1 = SignalFileName + ".txt";
  string file2 = SignalFileName;

  int handle = INVALID_HANDLE;
  handle = FileOpen(file1, FILE_READ | FILE_TXT | FILE_ANSI);
  if (handle == INVALID_HANDLE)
  {
    handle = FileOpen(file2, FILE_READ | FILE_TXT | FILE_ANSI);
    if (handle == INVALID_HANDLE)
      return;
  }

  string content = "";
  while (!FileIsEnding(handle))
  {
    string line = FileReadString(handle);
    content = content + line;
  }
  FileClose(handle);

  FileDelete(file1);
  FileDelete(file2);

  content = NormalizeContentLines(content);
  content = StringTrimCustom(content);

  if (StringLen(content) < 5)
    return;

  PrintLog("Read Content: " + StringSubstr(content, 0, MathMin(100, StringLen(content))) + "...");

  SignalData sig;
  if (!ParseJsonContent(content, sig))
  {
    PrintLog("Failed to parse JSON content.");
    return;
  }

  // Validate parsed data
  PrintLog("Parsed Data Summary:");
  PrintLog("  Prices count: " + IntegerToString(sig.prices_count));
  PrintLog("  TP count: " + IntegerToString(sig.tp_count));
  PrintLog("  SL count: " + IntegerToString(sig.sl_count));
  if (sig.prices_count == 0)
  {
    PrintLog("ERROR: No prices parsed from JSON!");
    return;
  }

  // If no TPs, add a default
  if (sig.tp_count == 0)
  {
    PrintLog("WARNING: No TPs found, adding default TP");
    sig.tp_count = 1;
    ArrayResize(sig.tp_list, 1);
    sig.tp_list[0] = 0; // Will be calculated later
  }
  if (StringLen(sig.order_type) == 0)
    return;

  string symbol = sig.currency;
  if (StringLen(symbol) == 0 || symbol == "null")
    symbol = DefaultSymbol;
  StringReplace(symbol, "\"", "");
  StringReplace(symbol, "'", "");
  symbol = StringTrimCustom(symbol);

  if (!SymbolSelect(symbol, true))
  {
    PrintLog("Symbol " + symbol + " not found. Using default: " + DefaultSymbol);
    symbol = DefaultSymbol;
    SymbolSelect(symbol, true);
  }

  if (StringLen(sig.signal_id) == 0)
  {
    long currentTime = (long)TimeCurrent(); // تبدیل صریح برای جلوگیری از هشدار
    sig.signal_id = IntegerToString(currentTime);
  }

  PrintLog("Processing Signal ID: " + sig.signal_id + " on " + symbol);

  ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);

  // ارسال گزارش سیگنال ورودی به تلگرام - بعد از تعریف symbol و symType
  if (EnableTelegram)
  {
    SendSignalEntryReport(sig, symbol, symType);
  }

  SymbolSettings settings = GetSymbolSettings(symType);

  double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
  double totalRiskMoney = accountBalance * RiskPercentPerSignal / 100.0;

  // اضافه کردن چک ریسک کلی:
  if (EnableGlobalRiskLimit)
  {
    if (!CheckGlobalRiskLimit(totalRiskMoney))
    {
      PrintLog("Signal execution CANCELLED due to global risk limit");
      return; // سیگنال اجرا نمی‌شود
    }
  }

  if (sig.prices_count == 0)
  {
    ArrayResize(sig.prices_list, 1);
    ArrayResize(sig.prices_isMarket, 1);
    sig.prices_list[0] = 0.0;
    sig.prices_isMarket[0] = true;
    sig.prices_count = 1;
  }

  int successCount = 0;
  double totalExecutedVolume = 0;

  // Process signal with smart logic
  ProcessSignalWithSmartLogic(sig, symbol, symType, settings, totalRiskMoney, sig.signal_id, successCount, totalExecutedVolume);

  if (EnableTelegram && successCount > 0)
  {
    SendExecutionReport(sig.signal_id, symbol, sig.order_type, sig.tp_count, successCount,
                        totalExecutedVolume, false, false, 0, symType);
  }
}

// ================ ENHANCED EXECUTION LOGIC ================

//+------------------------------------------------------------------+
//| Process Signal with Smart Logic - COMPLETE REWRITE              |
//+------------------------------------------------------------------+
void ProcessSignalWithSmartLogic(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings,
                                 double totalRiskMoney, string signalID, int &successCount, double &totalVolume)
{
  // ================ INITIAL VALIDATION ================
  PrintLog("=== SIGNAL PROCESSING STARTED ===");
  PrintLog("Signal ID: " + signalID + ", Symbol: " + symbol + ", Order Type: " + sig.order_type);

  if (sig.prices_count == 0)
  {
    PrintLog("❌ ERROR: No prices found in signal!");
    return;
  }

  if (sig.tp_count == 0)
  {
    PrintLog("⚠️ WARNING: No TPs found. Using default TP.");
    sig.tp_count = 1;
    ArrayResize(sig.tp_list, 1);
    sig.tp_list[0] = 0;
  }

  PrintLog("Signal Details: " + IntegerToString(sig.prices_count) + " prices, " +
           IntegerToString(sig.tp_count) + " TPs, " + IntegerToString(sig.sl_count) + " SLs");

  // ================ ORDER TYPE ANALYSIS ================
  string orderTypeLower = StringToLowerCustom(sig.order_type);

  bool isBuyOrder = (StringFind(orderTypeLower, "buy") >= 0);
  bool isSellOrder = (StringFind(orderTypeLower, "sell") >= 0);
  bool isMarketOrder = false;
  bool isLimitOrder = false;
  bool isStopOrder = false;

  // Analyze order type
  if (isBuyOrder || isSellOrder)
  {
    if (StringFind(orderTypeLower, "limit") >= 0)
      isLimitOrder = true;
    else if (StringFind(orderTypeLower, "stop") >= 0)
      isStopOrder = true;
    else if (StringFind(orderTypeLower, "market") >= 0 ||
             orderTypeLower == "buy" ||
             orderTypeLower == "sell")
      isMarketOrder = true;
    else
      isMarketOrder = true; // Default to market
  }
  else
  {
    PrintLog("❌ ERROR: Invalid order type: " + sig.order_type);
    return;
  }

  bool isBuy = isBuyOrder;

  PrintLog("Order Analysis:");
  PrintLog("  Direction: " + (isBuyOrder ? "BUY" : "SELL"));
  PrintLog("  Type: " + (isMarketOrder ? "MARKET" : (isLimitOrder ? "LIMIT" : (isStopOrder ? "STOP" : "UNKNOWN"))));

  // ================ MARKET DATA ================
  double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
  double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
  double currentMarketPrice = isBuyOrder ? ask : bid;
  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

  PrintLog("Market Data:");
  PrintLog("  Bid: " + DoubleToString(bid, 2));
  PrintLog("  Ask: " + DoubleToString(ask, 2));
  PrintLog("  Using: " + DoubleToString(currentMarketPrice, 2));
  PrintLog("  Point: " + DoubleToString(point, 5));

  // ================ STOP LOSS CALCULATION ================
  double sl_price = 0;

  if (sig.sl_count > 0 && sig.sl_list[0] > 0)
  {
    sl_price = sig.sl_list[0];
    PrintLog("SL from signal: " + DoubleToString(sl_price, 2));
  }
  else
  {
    // Calculate default SL based on symbol type
    double pips = settings.default_sl_pips;

    // Adjust pips for symbol type
    if (symType == SYMBOL_TYPE_GOLD)
      pips = pips * 10.0;
    else if (symType == SYMBOL_TYPE_FOREX)
      pips = pips / 10.0;
    // For indices (DOW/NASDAQ), use as is

    double dist = pips * point;
    sl_price = isBuy ? currentMarketPrice - dist : currentMarketPrice + dist;
    PrintLog("Default SL calculated: " + DoubleToString(sl_price, 2) +
             " (" + DoubleToString(pips, 1) + " pips from price)");
  }

  // ================ POSITION SIZE CALCULATION ================
  double distSL = MathAbs(currentMarketPrice - sl_price);
  double totalLot = CalculatePositionSize(symbol, totalRiskMoney, distSL);
  totalLot = NormalizeLotToSymbol(totalLot, symbol);

  // Apply maximum lot limit
  if (totalLot > settings.max_lot)
  {
    PrintLog("⚠️ Lot size limited from " + DoubleToString(totalLot, 3) +
             " to max: " + DoubleToString(settings.max_lot, 3));
    totalLot = settings.max_lot;
  }

  double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
  if (minLot <= 0)
    minLot = 0.01;

  PrintLog("Position Sizing:");
  PrintLog("  Risk Money: $" + DoubleToString(totalRiskMoney, 2));
  PrintLog("  Total Lot: " + DoubleToString(totalLot, 3));
  PrintLog("  Min Lot: " + DoubleToString(minLot, 3));
  PrintLog("  SL Distance: " + DoubleToString(distSL, 5) + " (" +
           DoubleToString(distSL / point, 1) + " points)");

  // ================ MARKET PRICE DETECTION ================
  int firstMarketIndex = -1;
  int marketEntries = 0;
  int pendingEntries = 0;

  // Only check for market orders
  if (isMarketOrder)
  {
    PrintLog("Checking prices for market execution...");

    for (int i = 0; i < sig.prices_count; i++)
    {
      double entryPrice = sig.prices_list[i];
      if (entryPrice <= 0)
        continue;

      // Calculate gap in market points
      double gapPoints = MathAbs(entryPrice - currentMarketPrice) / point;

      // Adjust for symbol type (convert to pips)
      double gapPips = gapPoints;
      if (symType == SYMBOL_TYPE_GOLD)
        gapPips = gapPoints / 10.0;
      else if (symType == SYMBOL_TYPE_FOREX)
        gapPips = gapPoints / 10.0;
      // For indices, already in pips

      PrintLog("Price[" + IntegerToString(i) + "]: " + DoubleToString(entryPrice, 2) +
               " - Gap: " + DoubleToString(gapPips, 1) + " pips" +
               " (Max: " + IntegerToString(settings.max_slippage_pips) + " pips)");

      if (gapPips <= settings.max_slippage_pips)
      {
        if (firstMarketIndex == -1) // First market price found
        {
          firstMarketIndex = i;
          PrintLog("  ✓ First market price found at index " + IntegerToString(i));
        }
        marketEntries++;
      }
      else
      {
        pendingEntries++;
        PrintLog("  ✗ Outside slippage range - will be pending");
      }
    }

    PrintLog("Market Analysis: " + IntegerToString(marketEntries) + " market entries, " +
             IntegerToString(pendingEntries) + " pending entries");
  }
  else
  {
    // For limit/stop orders, all are pending
    pendingEntries = sig.prices_count;
    PrintLog("Limit/Stop order detected - all " + IntegerToString(pendingEntries) + " entries will be pending");
  }

  // ================ POSITION COUNT CALCULATION ================
  int totalExpectedPositions = 0;
  string executionMode = "";

  if (isMarketOrder && firstMarketIndex >= 0)
  {
    // We have at least one market price
    int marketPositions = sig.tp_count;                           // For the first market price
    int pendingPositions = (sig.prices_count - 1) * sig.tp_count; // For other prices

    totalExpectedPositions = marketPositions + pendingPositions;

    if (pendingPositions > 0)
    {
      executionMode = "Mixed: Market + Pending";
      PrintLog("Execution Mode: " + executionMode);
      PrintLog("  Market Positions: " + IntegerToString(marketPositions) +
               " (first price × " + IntegerToString(sig.tp_count) + " TPs)");
      PrintLog("  Pending Positions: " + IntegerToString(pendingPositions) +
               " (" + IntegerToString(sig.prices_count - 1) + " prices × " +
               IntegerToString(sig.tp_count) + " TPs)");
    }
    else
    {
      executionMode = "All Market";
      PrintLog("Execution Mode: " + executionMode);
      PrintLog("  All positions will be market orders");
    }
  }
  else
  {
    // All pending orders
    totalExpectedPositions = sig.prices_count * sig.tp_count;

    if (isLimitOrder)
      executionMode = "All Pending (Limit Orders)";
    else if (isStopOrder)
      executionMode = "All Pending (Stop Orders)";
    else
      executionMode = "All Pending";

    PrintLog("Execution Mode: " + executionMode);
    PrintLog("  Total Positions: " + IntegerToString(sig.prices_count) +
             " prices × " + IntegerToString(sig.tp_count) + " TPs = " +
             IntegerToString(totalExpectedPositions));
  }

  // ================ LOT SPLITTING VALIDATION ================
  if (totalExpectedPositions <= 0)
  {
    PrintLog("❌ ERROR: Cannot calculate position count!");
    return;
  }

  double lotPerPosition = NormalizeLotToSymbol(totalLot / totalExpectedPositions, symbol);
  bool validSplitVolume = (lotPerPosition >= minLot);

  PrintLog("Lot Splitting:");
  PrintLog("  Positions: " + IntegerToString(totalExpectedPositions));
  PrintLog("  Lot/Position: " + DoubleToString(lotPerPosition, 3));
  PrintLog("  Valid Split: " + (validSplitVolume ? "YES ✓" : "NO ✗"));

  // ================ SPECIAL CASE: INVALID SPLIT ================
  if (!validSplitVolume)
  {
    PrintLog("⚠️ ENTERING SPECIAL EXECUTION MODE");
    PrintLog("Reason: Lot per position (" + DoubleToString(lotPerPosition, 3) +
             ") < minimum (" + DoubleToString(minLot, 3) + ")");

    // Create one pending order with full volume
    double pendingPrice = 0;

    if (sig.prices_count > 0 && sig.prices_list[0] > 0)
    {
      pendingPrice = sig.prices_list[0];
      PrintLog("Using first signal price: " + DoubleToString(pendingPrice, 2));
    }
    else
    {
      // Calculate based on SL distance
      double pips = settings.pending_distance_pips;
      double multiplier = 1.0;

      if (symType == SYMBOL_TYPE_GOLD)
        multiplier = 10.0;
      else if (symType == SYMBOL_TYPE_FOREX)
        multiplier = 10.0;

      double distance = pips * point * multiplier;
      pendingPrice = isBuy ? sl_price + distance : sl_price - distance;
      PrintLog("Calculated pending price: " + DoubleToString(pendingPrice, 2) +
               " (" + IntegerToString(pips) + " pips from SL)");
    }

    // Get TP - اصلاح شده: فقط 9 پارامتر
    double firstTP = GetFirstTP(sig, symbol, symType, settings, currentMarketPrice, isBuy,
                                sig.order_type, false, true);

    PrintLog("Creating single pending order:");
    PrintLog("  Price: " + DoubleToString(pendingPrice, 2));
    PrintLog("  SL: " + DoubleToString(sl_price, 2));
    PrintLog("  TP: " + (firstTP > 0 ? DoubleToString(firstTP, 2) : "OPEN"));
    PrintLog("  Lot: " + DoubleToString(totalLot, 3));

    if (SendPendingOrder(symbol, sig.order_type, pendingPrice, sl_price, firstTP, totalLot, signalID))
    {
      successCount = 1;
      totalVolume = totalLot;

      if (EnableTelegram)
      {
        SendSignalAlert(signalID, symbol,
                        "⚡ *Special Execution Mode*\n" +
                            "Lot too small to split\n" +
                            "Created 1 pending order\n" +
                            "Price: " + DoubleToString(pendingPrice, 2) + "\n" +
                            "Lot: " + DoubleToString(totalLot, 3));
      }
    }

    return;
  }

  // ================ NORMAL EXECUTION ================
  PrintLog("✅ PROCEEDING WITH NORMAL EXECUTION");

  int marketOrdersCreated = 0;
  int pendingOrdersCreated = 0;
  int skippedOrders = 0;

  // Process each price
  for (int priceIndex = 0; priceIndex < sig.prices_count; priceIndex++)
  {
    double entryPrice = sig.prices_list[priceIndex];
    if (entryPrice <= 0)
    {
      PrintLog("Skipping Price[" + IntegerToString(priceIndex) + "]: Invalid price");
      skippedOrders++;
      continue;
    }

    PrintLog("--- Processing Price[" + IntegerToString(priceIndex) + "]: " +
             DoubleToString(entryPrice, 2) + " ---");

    // Check if this should be a market order
    bool isThisMarketOrder = (isMarketOrder && priceIndex == firstMarketIndex);

    // Process each TP for this price
    for (int tpIndex = 0; tpIndex < sig.tp_count; tpIndex++)
    {
      double tp_val = sig.tp_list[tpIndex];

      // Calculate TP if needed
      if (tp_val <= 0)
      {
        tp_val = GetFirstTP(sig, symbol, symType, settings, currentMarketPrice, isBuy,
                            sig.order_type, isThisMarketOrder, !isThisMarketOrder);
      }

      string tpStr = (tp_val == 0) ? "OPEN" : DoubleToString(tp_val, 2);

      if (isThisMarketOrder)
      {
        // Send market order
        PrintLog("Market Order " + IntegerToString(tpIndex + 1) + "/" + IntegerToString(sig.tp_count) +
                 " - TP: " + tpStr + ", Lot: " + DoubleToString(lotPerPosition, 3));

        if (SendMarketOrder(symbol, sig.order_type, sl_price, tp_val, lotPerPosition, signalID))
        {
          successCount++;
          totalVolume += lotPerPosition;
          marketOrdersCreated++;
          PrintLog("  ✓ Market order successful");
        }
        else
        {
          PrintLog("  ✗ Market order failed");
          skippedOrders++;
        }
      }
      else
      {
        // Send pending order
        string pendingType = "Pending";
        if (isLimitOrder)
          pendingType = "Limit";
        if (isStopOrder)
          pendingType = "Stop";

        PrintLog(pendingType + " Order " + IntegerToString(tpIndex + 1) + "/" + IntegerToString(sig.tp_count) +
                 " - Price: " + DoubleToString(entryPrice, 2) +
                 ", TP: " + tpStr + ", Lot: " + DoubleToString(lotPerPosition, 3));

        if (SendPendingOrder(symbol, sig.order_type, entryPrice, sl_price, tp_val, lotPerPosition, signalID))
        {
          successCount++;
          totalVolume += lotPerPosition;
          pendingOrdersCreated++;
          PrintLog("  ✓ " + pendingType + " order successful");
        }
        else
        {
          PrintLog("  ✗ " + pendingType + " order failed");
          skippedOrders++;
        }
      }
    }
  }

  // ================ EXECUTION SUMMARY ================
  PrintLog("=========================================");
  PrintLog("✅ EXECUTION COMPLETED");
  PrintLog("=========================================");
  PrintLog("Signal ID: " + signalID);
  PrintLog("Symbol: " + symbol);
  PrintLog("Order Type: " + sig.order_type);
  PrintLog("Execution Mode: " + executionMode);
  PrintLog("");
  PrintLog("POSITION SUMMARY:");
  PrintLog("  Expected: " + IntegerToString(totalExpectedPositions) + " positions");
  PrintLog("  Created: " + IntegerToString(successCount) + " positions");
  PrintLog("  Market Orders: " + IntegerToString(marketOrdersCreated));
  PrintLog("  Pending Orders: " + IntegerToString(pendingOrdersCreated));
  PrintLog("  Skipped/Failed: " + IntegerToString(skippedOrders));
  PrintLog("");
  PrintLog("VOLUME SUMMARY:");
  PrintLog("  Total Volume: " + DoubleToString(totalVolume, 3) + " lots");
  PrintLog("  Lot per Position: " + DoubleToString(lotPerPosition, 3) + " lots");
  PrintLog("  Risk per Signal: $" + DoubleToString(totalRiskMoney, 2));
  PrintLog("");
  PrintLog("PRICE LEVELS:");
  PrintLog("  Current Market: " + DoubleToString(currentMarketPrice, 2));
  PrintLog("  Stop Loss: " + DoubleToString(sl_price, 2));
  if (firstMarketIndex >= 0)
    PrintLog("  First Market Price: " + DoubleToString(sig.prices_list[firstMarketIndex], 2) +
             " (index " + IntegerToString(firstMarketIndex) + ")");
  PrintLog("=========================================");

  // ================ TELEGRAM NOTIFICATION ================
  if (EnableTelegram && successCount > 0)
  {
    string telegramMsg = "📊 *Execution Report*\n\n";
    telegramMsg += "🆔 Signal: `" + signalID + "`\n";
    telegramMsg += "🏷️ Symbol: " + symbol + "\n";
    telegramMsg += "📈 Type: " + sig.order_type + "\n";
    telegramMsg += "🎯 Mode: " + executionMode + "\n\n";

    telegramMsg += "✅ Positions: " + IntegerToString(successCount) + "/" +
                   IntegerToString(totalExpectedPositions) + "\n";

    if (marketOrdersCreated > 0)
      telegramMsg += "🟢 Market: " + IntegerToString(marketOrdersCreated) + "\n";

    if (pendingOrdersCreated > 0)
      telegramMsg += "🟡 Pending: " + IntegerToString(pendingOrdersCreated) + "\n";

    if (skippedOrders > 0)
      telegramMsg += "🔴 Failed: " + IntegerToString(skippedOrders) + "\n";

    telegramMsg += "\n💰 Volume: " + DoubleToString(totalVolume, 3) + " lots\n";
    telegramMsg += "🔻 SL: " + DoubleToString(sl_price, 2) + "\n";

    if (firstMarketIndex >= 0)
      telegramMsg += "🎯 First Market: " + DoubleToString(sig.prices_list[firstMarketIndex], 2) + "\n";

    telegramMsg += "\n⏰ " + TimeToString(TimeCurrent(), TIME_SECONDS);

    SendSignalAlert(signalID, symbol, telegramMsg);
  }
}

// ================ ORDER MANAGEMENT FUNCTIONS ================

//+------------------------------------------------------------------+
//| Send Market Order                                               |
//+------------------------------------------------------------------+
bool SendMarketOrder(string symbol, string order_type, double sl_price, double tp_price, double lot, string signalID)
{
  MqlTradeRequest request;
  MqlTradeResult result;
  ZeroMemory(request);
  ZeroMemory(result);

  int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
  double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
  if (tickSize == 0)
    tickSize = SymbolInfoDouble(symbol, SYMBOL_POINT);

  if (sl_price > 0)
    sl_price = MathRound(sl_price / tickSize) * tickSize;
  if (tp_price > 0)
    tp_price = MathRound(tp_price / tickSize) * tickSize;

  ENUM_ORDER_TYPE type = (StringCompare(order_type, "sell", false) == 0) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;

  request.symbol = symbol;
  request.volume = lot;
  request.deviation = 50;
  request.magic = ExpertMagicNumber;
  request.comment = "SID:" + signalID;
  request.type_time = ORDER_TIME_GTC;
  request.type_filling = ORDER_FILLING_FOK;

  double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
  double bid = SymbolInfoDouble(symbol, SYMBOL_BID);

  request.action = TRADE_ACTION_DEAL;
  request.type = type;
  request.price = (type == ORDER_TYPE_BUY) ? ask : bid;
  // Adjust TP if exists
  if (tp_price > 0)
  {
    ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);
    tp_price = AdjustTPPrice(tp_price, symbol, symType, order_type, true, false);
  }

  // Adjust SL if exists
  if (sl_price > 0)
  {
    ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);
    sl_price = AdjustSLPrice(sl_price, symbol, symType, order_type, true, false);
  }
  if (sl_price > 0)
    request.sl = sl_price;
  if (tp_price > 0)
    request.tp = tp_price;

  bool sent = OrderSend(request, result);

  if (sent)
  {
    PrintLog("Market Order Successful: Ticket #" + IntegerToString(result.order) +
             " Volume: " + DoubleToString(lot, 2));

    // Initialize risk data for this position
    if (EnableRiskManagement)
      InitializeRiskDataForPosition(result.order, signalID, request.price, sl_price, tp_price);
  }
  else
  {
    PrintLog("Market Order Failed: " + IntegerToString(result.retcode) + " " + result.comment);
    if (EnableTelegram)
      SendTelegramFarsi("⚠️ *Market Order Error*\n#SID_" + signalID +
                        "\nCode: " + IntegerToString(result.retcode) + "\n" + result.comment);
  }

  return sent;
}

//+------------------------------------------------------------------+
//| Send Pending Order - COMPLETE REWRITE                          |
//+------------------------------------------------------------------+
bool SendPendingOrder(string symbol, string order_type, double entryPrice, double sl_price, double tp_price, double lot, string signalID)
{
  PrintLog("=========================================");
  PrintLog("🔄 SENDING PENDING ORDER");
  PrintLog("=========================================");

  // Adjust TP if exists
  if (tp_price > 0)
  {
    ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);
    tp_price = AdjustTPPrice(tp_price, symbol, symType, order_type, false, true);
  }

  // Adjust SL if exists
  if (sl_price > 0)
  {
    ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);
    sl_price = AdjustSLPrice(sl_price, symbol, symType, order_type, false, true);
  }
  // ================ INPUT VALIDATION ================
  PrintLog("Input Validation:");

  if (symbol == "")
  {
    PrintLog("❌ ERROR: Symbol is empty!");
    return false;
  }

  if (order_type == "")
  {
    PrintLog("❌ ERROR: Order type is empty!");
    return false;
  }

  if (entryPrice <= 0)
  {
    PrintLog("❌ ERROR: Invalid entry price: " + DoubleToString(entryPrice, 2));
    return false;
  }

  if (lot <= 0)
  {
    PrintLog("❌ ERROR: Invalid lot size: " + DoubleToString(lot, 3));
    return false;
  }

  PrintLog("  Symbol: " + symbol);
  PrintLog("  Order Type: " + order_type);
  PrintLog("  Entry Price: " + DoubleToString(entryPrice, 5));
  PrintLog("  SL: " + (sl_price > 0 ? DoubleToString(sl_price, 5) : "Not set"));
  PrintLog("  TP: " + (tp_price > 0 ? DoubleToString(tp_price, 5) : (tp_price == 0 ? "OPEN" : "Not set")));
  PrintLog("  Lot: " + DoubleToString(lot, 2));
  PrintLog("  Signal ID: " + signalID);

  // ================ SYMBOL SELECTION ================
  PrintLog("\nSymbol Selection:");
  if (!SymbolSelect(symbol, true))
  {
    PrintLog("❌ ERROR: Cannot select symbol " + symbol);
    return false;
  }
  PrintLog("  ✓ Symbol selected successfully");

  // ================ MARKET DATA ================
  PrintLog("\nMarket Data:");
  double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
  double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

  if (bid <= 0 || ask <= 0 || point <= 0)
  {
    PrintLog("❌ ERROR: Invalid market data!");
    PrintLog("  Bid: " + DoubleToString(bid, 5));
    PrintLog("  Ask: " + DoubleToString(ask, 5));
    PrintLog("  Point: " + DoubleToString(point, 5));
    return false;
  }

  PrintLog("  Bid: " + DoubleToString(bid, digits));
  PrintLog("  Ask: " + DoubleToString(ask, digits));
  PrintLog("  Point: " + DoubleToString(point, 5));
  PrintLog("  Digits: " + IntegerToString(digits));

  // ================ ORDER TYPE ANALYSIS ================
  PrintLog("\nOrder Type Analysis:");
  string orderTypeLower = StringToLowerCustom(order_type);

  bool isBuyOrder = false;
  bool isSellOrder = false;
  bool isLimitOrder = false;
  bool isStopOrder = false;

  // Determine order direction and type
  if (StringFind(orderTypeLower, "buy") >= 0)
  {
    isBuyOrder = true;
    PrintLog("  Direction: BUY");

    if (StringFind(orderTypeLower, "limit") >= 0)
    {
      isLimitOrder = true;
      PrintLog("  Type: LIMIT");
    }
    else if (StringFind(orderTypeLower, "stop") >= 0)
    {
      isStopOrder = true;
      PrintLog("  Type: STOP");
    }
    else
    {
      PrintLog("  Type: GENERIC (will auto-detect)");
    }
  }
  else if (StringFind(orderTypeLower, "sell") >= 0)
  {
    isSellOrder = true;
    PrintLog("  Direction: SELL");

    if (StringFind(orderTypeLower, "limit") >= 0)
    {
      isLimitOrder = true;
      PrintLog("  Type: LIMIT");
    }
    else if (StringFind(orderTypeLower, "stop") >= 0)
    {
      isStopOrder = true;
      PrintLog("  Type: STOP");
    }
    else
    {
      PrintLog("  Type: GENERIC (will auto-detect)");
    }
  }
  else
  {
    PrintLog("❌ ERROR: Invalid order direction!");
    return false;
  }

  // ================ PRICE VALIDATION ================
  PrintLog("\nPrice Validation:");

  // Normalize prices
  double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
  if (tickSize <= 0)
    tickSize = point;

  double normalizedEntry = NormalizePrice(entryPrice, tickSize, digits);
  double normalizedSL = (sl_price > 0) ? NormalizePrice(sl_price, tickSize, digits) : 0;
  double normalizedTP = (tp_price > 0) ? NormalizePrice(tp_price, tickSize, digits) : 0;

  if (normalizedEntry != entryPrice)
    PrintLog("  Entry normalized: " + DoubleToString(entryPrice, digits) + " → " + DoubleToString(normalizedEntry, digits));

  if (normalizedSL != sl_price && sl_price > 0)
    PrintLog("  SL normalized: " + DoubleToString(sl_price, digits) + " → " + DoubleToString(normalizedSL, digits));

  if (normalizedTP != tp_price && tp_price > 0)
    PrintLog("  TP normalized: " + DoubleToString(tp_price, digits) + " → " + DoubleToString(normalizedTP, digits));

  // Validate entry price against market
  if (isBuyOrder)
  {
    if (isLimitOrder)
    {
      // Buy Limit must be BELOW current ask
      if (normalizedEntry >= ask)
      {
        PrintLog("❌ ERROR: Buy Limit price must be BELOW Ask!");
        PrintLog("  Entry: " + DoubleToString(normalizedEntry, digits));
        PrintLog("  Ask: " + DoubleToString(ask, digits));
        return false;
      }
      PrintLog("  ✓ Buy Limit: Entry < Ask (valid)");
    }
    else if (isStopOrder)
    {
      // Buy Stop must be ABOVE current ask
      if (normalizedEntry <= ask)
      {
        PrintLog("❌ ERROR: Buy Stop price must be ABOVE Ask!");
        PrintLog("  Entry: " + DoubleToString(normalizedEntry, digits));
        PrintLog("  Ask: " + DoubleToString(ask, digits));
        return false;
      }
      PrintLog("  ✓ Buy Stop: Entry > Ask (valid)");
    }
  }
  else if (isSellOrder)
  {
    if (isLimitOrder)
    {
      // Sell Limit must be ABOVE current bid
      if (normalizedEntry <= bid)
      {
        PrintLog("❌ ERROR: Sell Limit price must be ABOVE Bid!");
        PrintLog("  Entry: " + DoubleToString(normalizedEntry, digits));
        PrintLog("  Bid: " + DoubleToString(bid, digits));
        return false;
      }
      PrintLog("  ✓ Sell Limit: Entry > Bid (valid)");
    }
    else if (isStopOrder)
    {
      // Sell Stop must be BELOW current bid
      if (normalizedEntry >= bid)
      {
        PrintLog("❌ ERROR: Sell Stop price must be BELOW Bid!");
        PrintLog("  Entry: " + DoubleToString(normalizedEntry, digits));
        PrintLog("  Bid: " + DoubleToString(bid, digits));
        return false;
      }
      PrintLog("  ✓ Sell Stop: Entry < Bid (valid)");
    }
  }

  // ================ AUTO-DETECT ORDER TYPE IF NEEDED ================
  ENUM_ORDER_TYPE orderTypeEnum;
  string orderTypeStr = "";

  if (isBuyOrder)
  {
    if (isLimitOrder)
    {
      orderTypeEnum = ORDER_TYPE_BUY_LIMIT;
      orderTypeStr = "ORDER_TYPE_BUY_LIMIT";
    }
    else if (isStopOrder)
    {
      orderTypeEnum = ORDER_TYPE_BUY_STOP;
      orderTypeStr = "ORDER_TYPE_BUY_STOP";
    }
    else
    {
      // Auto-detect: if entry > ask → Stop, else → Limit
      if (normalizedEntry > ask)
      {
        orderTypeEnum = ORDER_TYPE_BUY_STOP;
        orderTypeStr = "ORDER_TYPE_BUY_STOP (auto)";
        PrintLog("  Auto-detected: BUY STOP (Entry > Ask)");
      }
      else
      {
        orderTypeEnum = ORDER_TYPE_BUY_LIMIT;
        orderTypeStr = "ORDER_TYPE_BUY_LIMIT (auto)";
        PrintLog("  Auto-detected: BUY LIMIT (Entry < Ask)");
      }
    }
  }
  else // isSellOrder
  {
    if (isLimitOrder)
    {
      orderTypeEnum = ORDER_TYPE_SELL_LIMIT;
      orderTypeStr = "ORDER_TYPE_SELL_LIMIT";
    }
    else if (isStopOrder)
    {
      orderTypeEnum = ORDER_TYPE_SELL_STOP;
      orderTypeStr = "ORDER_TYPE_SELL_STOP";
    }
    else
    {
      // Auto-detect: if entry < bid → Stop, else → Limit
      if (normalizedEntry < bid)
      {
        orderTypeEnum = ORDER_TYPE_SELL_STOP;
        orderTypeStr = "ORDER_TYPE_SELL_STOP (auto)";
        PrintLog("  Auto-detected: SELL STOP (Entry < Bid)");
      }
      else
      {
        orderTypeEnum = ORDER_TYPE_SELL_LIMIT;
        orderTypeStr = "ORDER_TYPE_SELL_LIMIT (auto)";
        PrintLog("  Auto-detected: SELL LIMIT (Entry > Bid)");
      }
    }
  }

  // ================ STOP LEVELS VALIDATION ================
  PrintLog("\nStop Levels Validation:");

  // Get minimum stop distance
  double stopsLevel = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL) * point;
  double freezeLevel = SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL) * point;

  PrintLog("  Stops Level: " + DoubleToString(stopsLevel, digits) + " (" +
           DoubleToString(stopsLevel / point, 0) + " points)");
  PrintLog("  Freeze Level: " + DoubleToString(freezeLevel, digits) + " (" +
           DoubleToString(freezeLevel / point, 0) + " points)");

  // Validate SL distance
  if (normalizedSL > 0)
  {
    double slDistance = MathAbs(normalizedEntry - normalizedSL);

    if (slDistance < stopsLevel)
    {
      PrintLog("❌ ERROR: SL is too close to entry!");
      PrintLog("  Distance: " + DoubleToString(slDistance, digits));
      PrintLog("  Required: " + DoubleToString(stopsLevel, digits));
      return false;
    }

    if (slDistance < freezeLevel)
    {
      PrintLog("⚠️ WARNING: SL is within freeze level!");
      PrintLog("  Distance: " + DoubleToString(slDistance, digits));
      PrintLog("  Freeze Level: " + DoubleToString(freezeLevel, digits));
    }

    PrintLog("  ✓ SL distance: " + DoubleToString(slDistance, digits) + " (OK)");
  }

  // Validate TP distance (if set)
  if (normalizedTP > 0)
  {
    double tpDistance = MathAbs(normalizedEntry - normalizedTP);

    if (tpDistance < stopsLevel)
    {
      PrintLog("❌ ERROR: TP is too close to entry!");
      PrintLog("  Distance: " + DoubleToString(tpDistance, digits));
      PrintLog("  Required: " + DoubleToString(stopsLevel, digits));
      return false;
    }

    PrintLog("  ✓ TP distance: " + DoubleToString(tpDistance, digits) + " (OK)");
  }

  // ================ VOLUME VALIDATION ================
  PrintLog("\nVolume Validation:");

  double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
  double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
  double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

  PrintLog("  Min Lot: " + DoubleToString(minLot, 2));
  PrintLog("  Max Lot: " + DoubleToString(maxLot, 2));
  PrintLog("  Lot Step: " + DoubleToString(lotStep, 2));
  PrintLog("  Requested Lot: " + DoubleToString(lot, 2));

  // Normalize lot size
  double normalizedLot = lot;
  if (lotStep > 0)
  {
    normalizedLot = MathFloor(lot / lotStep) * lotStep;
    normalizedLot = MathMax(normalizedLot, minLot);
    normalizedLot = MathMin(normalizedLot, maxLot);

    if (normalizedLot != lot)
      PrintLog("  Lot normalized: " + DoubleToString(lot, 2) + " → " + DoubleToString(normalizedLot, 2));
  }

  if (normalizedLot < minLot)
  {
    PrintLog("❌ ERROR: Lot size is below minimum!");
    PrintLog("  Current: " + DoubleToString(normalizedLot, 2));
    PrintLog("  Minimum: " + DoubleToString(minLot, 2));
    return false;
  }

  if (normalizedLot > maxLot)
  {
    PrintLog("❌ ERROR: Lot size exceeds maximum!");
    PrintLog("  Current: " + DoubleToString(normalizedLot, 2));
    PrintLog("  Maximum: " + DoubleToString(maxLot, 2));
    return false;
  }

  PrintLog("  ✓ Final Lot: " + DoubleToString(normalizedLot, 2) + " (valid)");

  // ================ PREPARE ORDER REQUEST ================
  PrintLog("\nPreparing Order Request:");

  MqlTradeRequest request;
  MqlTradeResult result;
  ZeroMemory(request);
  ZeroMemory(result);

  // Fill request structure
  request.action = TRADE_ACTION_PENDING;
  request.symbol = symbol;
  request.volume = normalizedLot;
  request.price = normalizedEntry;
  request.type = orderTypeEnum;
  request.magic = ExpertMagicNumber;
  request.sl = normalizedSL;
  request.tp = normalizedTP;
  request.deviation = 10;
  request.type_time = ORDER_TIME_GTC;
  request.type_filling = ORDER_FILLING_FOK;
  request.comment = "SID:" + signalID;

  PrintLog("  Symbol: " + request.symbol);
  PrintLog("  Type: " + orderTypeStr);
  PrintLog("  Volume: " + DoubleToString(request.volume, 2));
  PrintLog("  Price: " + DoubleToString(request.price, digits));
  PrintLog("  SL: " + (request.sl > 0 ? DoubleToString(request.sl, digits) : "None"));
  PrintLog("  TP: " + (request.tp > 0 ? DoubleToString(request.tp, digits) : (tp_price == 0 ? "OPEN" : "None")));
  PrintLog("  Magic: " + IntegerToString(request.magic));
  PrintLog("  Comment: " + request.comment);

  // ================ CHECK MARGIN ================
  PrintLog("\nMargin Check:");

  double margin = 0;
  if (OrderCalcMargin((ENUM_ORDER_TYPE)request.type, symbol, request.volume, request.price, margin))
  {
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

    PrintLog("  Required Margin: " + DoubleToString(margin, 2));
    PrintLog("  Free Margin: " + DoubleToString(freeMargin, 2));

    if (margin > freeMargin)
    {
      PrintLog("❌ ERROR: Insufficient margin!");
      PrintLog("  Required: " + DoubleToString(margin, 2));
      PrintLog("  Available: " + DoubleToString(freeMargin, 2));
      return false;
    }

    PrintLog("  ✓ Sufficient margin available");
  }
  else
  {
    PrintLog("  ⚠️ Could not calculate margin (proceeding anyway)");
  }

  // ================ SEND ORDER ================
  PrintLog("\nSending Order to Server...");

  ResetLastError();
  bool orderSent = OrderSend(request, result);

  // ================ PROCESS RESULTS ================
  PrintLog("\nOrder Send Results:");

  if (orderSent)
  {
    PrintLog("✅ ORDER SUCCESSFULLY PLACED!");
    PrintLog("  Ticket: #" + IntegerToString(result.order));
    PrintLog("  Volume: " + DoubleToString(result.volume, 2));
    PrintLog("  Price: " + DoubleToString(result.price, digits));
    PrintLog("  Bid: " + DoubleToString(result.bid, digits));
    PrintLog("  Ask: " + DoubleToString(result.ask, digits));
    PrintLog("  Comment: " + result.comment);
    PrintLog("  Request ID: " + IntegerToString(result.request_id));
    PrintLog("  Retcode: " + IntegerToString(result.retcode));

    // Log order details for debugging
    if (OrderSelect(result.order))
    {
      PrintLog("  Order Details:");
      PrintLog("    Open Time: " + TimeToString(OrderGetInteger(ORDER_TIME_SETUP)));
      PrintLog("    State: " + EnumToString((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)));
      PrintLog("    Time Expiration: " + (OrderGetInteger(ORDER_TIME_EXPIRATION) > 0 ? TimeToString(OrderGetInteger(ORDER_TIME_EXPIRATION)) : "None"));
    }

    return true;
  }
  else
  {
    PrintLog("❌ ORDER FAILED!");
    PrintLog("  Retcode: " + IntegerToString(result.retcode));
    PrintLog("  Error: " + result.comment);

    // Detailed error analysis
    string errorDescription = GetTradeErrorDescription(result.retcode);
    if (errorDescription != "")
      PrintLog("  Description: " + errorDescription);

    // Check for specific common errors
    switch (result.retcode)
    {
    case 10004: // TRADE_RETCODE_REQUOTE
      PrintLog("  Suggestion: Try again with updated prices");
      break;

    case 10006: // TRADE_RETCODE_REJECT
      PrintLog("  Suggestion: Check order parameters and try again");
      break;

    case 10010: // TRADE_RETCODE_INVALID_PRICE
      PrintLog("  Suggestion: Check price normalization and try again");
      break;

    case 10011: // TRADE_RETCODE_INVALID_STOPS
      PrintLog("  Suggestion: Adjust SL/TP levels and try again");
      break;

    case 10012: // TRADE_RETCODE_INVALID_VOLUME
      PrintLog("  Suggestion: Check volume constraints and try again");
      break;

    case 10014: // TRADE_RETCODE_NO_MONEY
      PrintLog("  Suggestion: Increase account balance or reduce position size");
      break;

    case 10019: // TRADE_RETCODE_TOO_MANY_REQUESTS
      PrintLog("  Suggestion: Wait and try again");
      break;
    }

    // Send Telegram alert for critical errors
    if (EnableTelegram && result.retcode >= 10006)
    {
      string errorMsg = "⚠️ *Pending Order Error*\n\n";
      errorMsg += "Signal: " + signalID + "\n";
      errorMsg += "Symbol: " + symbol + "\n";
      errorMsg += "Type: " + order_type + "\n";
      errorMsg += "Error: " + IntegerToString(result.retcode) + "\n";
      errorMsg += result.comment + "\n";

      if (errorDescription != "")
        errorMsg += "Description: " + errorDescription + "\n";

      errorMsg += "Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);

      SendTelegramFarsi(errorMsg);
    }

    return false;
  }
}

//+------------------------------------------------------------------+
//| Helper: Normalize Price                                         |
//+------------------------------------------------------------------+
double NormalizePrice(double price, double tickSize, int digits)
{
  if (tickSize <= 0)
    return NormalizeDouble(price, digits);

  double normalized = MathRound(price / tickSize) * tickSize;
  return NormalizeDouble(normalized, digits);
}

//+------------------------------------------------------------------+
//| Helper: Get Trade Error Description                             |
//+------------------------------------------------------------------+
string GetTradeErrorDescription(int retcode)
{
  switch (retcode)
  {
  case 10004:
    return "Requote";
  case 10006:
    return "Request rejected";
  case 10007:
    return "Request canceled by trader";
  case 10008:
    return "Order placed";
  case 10009:
    return "Request completed";
  case 10010:
    return "Invalid price";
  case 10011:
    return "Invalid stops";
  case 10012:
    return "Invalid trade volume";
  case 10013:
    return "Market is closed";
  case 10014:
    return "Insufficient funds";
  case 10015:
    return "Price changed";
  case 10016:
    return "Off quotes";
  case 10017:
    return "Broker is busy";
  case 10018:
    return "Requote";
  case 10019:
    return "Order is locked";
  case 10020:
    return "Long positions only allowed";
  case 10021:
    return "Too many requests";
  case 10022:
    return "Modification denied because order is too close to market";
  case 10023:
    return "Trade context is busy";
  case 10024:
    return "Expiration denied";
  case 10025:
    return "Too many pending orders";
  case 10026:
    return "Hedging prohibited";
  case 10027:
    return "Prohibited by FIFO rule";
  case 10028:
    return "Incorrect order type";
  case 10029:
    return "Incorrect order state";
  case 10030:
    return "Incorrect filling type";
  case 10031:
    return "Incorrect expiration type";
  case 10032:
    return "Incorrect order volume";
  case 10033:
    return "Incorrect price";
  case 10034:
    return "Incorrect stops";
  case 10035:
    return "Trade is disabled";
  case 10036:
    return "Market is closed";
  case 10037:
    return "Position not found";
  case 10038:
    return "Position not opened";
  case 10039:
    return "Close volume exceeds position volume";
  case 10040:
    return "One-click trading mode is disabled";
  default:
    return "";
  }
} // ================ RISK MANAGEMENT FUNCTIONS ================

//+------------------------------------------------------------------+
//| Initialize Risk Management Settings                              |
//+------------------------------------------------------------------+
void InitializeRiskManagementSettings()
{
  // Gold settings
  gold_settings.stage1_pips = Gold_Stage1_Pips;
  gold_settings.stage1_close_percent = Gold_Stage1_ClosePercent;
  gold_settings.stage2_pips = Gold_Stage2_Pips;
  gold_settings.stage2_close_percent = Gold_Stage2_ClosePercent;
  gold_settings.stage2_breakeven_pips = Gold_Stage2_BreakEvenPips;
  gold_settings.stage3_pips = Gold_Stage3_Pips;
  gold_settings.stage3_close_percent = Gold_Stage3_ClosePercent;
  gold_settings.trailing_stop_pips = Gold_TrailingStopPips;
  gold_settings.global_riskfree_pips = Gold_GlobalRiskFreePips;
  gold_settings.riskfree_distance = Gold_RiskFreeDistance;
  gold_settings.close_pending_at_profit = Gold_ClosePendingAtProfit;

  // Dow Jones settings
  dow_settings.stage1_pips = Dow_Stage1_Pips;
  dow_settings.stage1_close_percent = Dow_Stage1_ClosePercent;
  dow_settings.stage2_pips = Dow_Stage2_Pips;
  dow_settings.stage2_close_percent = Dow_Stage2_ClosePercent;
  dow_settings.stage2_breakeven_pips = Dow_Stage2_BreakEvenPips;
  dow_settings.stage3_pips = Dow_Stage3_Pips;
  dow_settings.stage3_close_percent = Dow_Stage3_ClosePercent;
  dow_settings.trailing_stop_pips = Dow_TrailingStopPips;
  dow_settings.global_riskfree_pips = Dow_GlobalRiskFreePips;
  dow_settings.riskfree_distance = Dow_RiskFreeDistance;
  dow_settings.close_pending_at_profit = Dow_ClosePendingAtProfit;

  // NASDAQ settings
  nas_settings.stage1_pips = Nas_Stage1_Pips;
  nas_settings.stage1_close_percent = Nas_Stage1_ClosePercent;
  nas_settings.stage2_pips = Nas_Stage2_Pips;
  nas_settings.stage2_close_percent = Nas_Stage2_ClosePercent;
  nas_settings.stage2_breakeven_pips = Nas_Stage2_BreakEvenPips;
  nas_settings.stage3_pips = Nas_Stage3_Pips;
  nas_settings.stage3_close_percent = Nas_Stage3_ClosePercent;
  nas_settings.trailing_stop_pips = Nas_TrailingStopPips;
  nas_settings.global_riskfree_pips = Nas_GlobalRiskFreePips;
  nas_settings.riskfree_distance = Nas_RiskFreeDistance;
  nas_settings.close_pending_at_profit = Nas_ClosePendingAtProfit;

  // Forex settings
  forex_settings.stage1_pips = Forex_Stage1_Pips;
  forex_settings.stage1_close_percent = Forex_Stage1_ClosePercent;
  forex_settings.stage2_pips = Forex_Stage2_Pips;
  forex_settings.stage2_close_percent = Forex_Stage2_ClosePercent;
  forex_settings.stage2_breakeven_pips = Forex_Stage2_BreakEvenPips;
  forex_settings.stage3_pips = Forex_Stage3_Pips;
  forex_settings.stage3_close_percent = Forex_Stage3_ClosePercent;
  forex_settings.trailing_stop_pips = Forex_TrailingStopPips;
  forex_settings.global_riskfree_pips = Forex_GlobalRiskFreePips;
  forex_settings.riskfree_distance = Forex_RiskFreeDistance;
  forex_settings.close_pending_at_profit = Forex_ClosePendingAtProfit;
}

//+------------------------------------------------------------------+
//| Get Risk Management Settings                                     |
//+------------------------------------------------------------------+
SymbolSettings GetRiskManagementSettings(ENUM_SYMBOL_TYPE symType)
{
  SymbolSettings settings;

  switch (symType)
  {
  case SYMBOL_TYPE_GOLD:
    settings.max_lot = gold_settings.max_lot;
    settings.default_sl_pips = gold_settings.default_sl_pips;
    settings.default_tp_pips = gold_settings.default_tp_pips;
    settings.max_slippage_pips = gold_settings.max_slippage_pips;
    settings.pending_distance_pips = gold_settings.pending_distance_pips;
    settings.stage1_pips = gold_settings.stage1_pips;
    settings.stage1_close_percent = gold_settings.stage1_close_percent;
    settings.stage2_pips = gold_settings.stage2_pips;
    settings.stage2_close_percent = gold_settings.stage2_close_percent;
    settings.stage2_breakeven_pips = gold_settings.stage2_breakeven_pips;
    settings.stage3_pips = gold_settings.stage3_pips;
    settings.stage3_close_percent = gold_settings.stage3_close_percent;
    settings.trailing_stop_pips = gold_settings.trailing_stop_pips;
    settings.global_riskfree_pips = gold_settings.global_riskfree_pips;
    settings.riskfree_distance = gold_settings.riskfree_distance;
    settings.close_pending_at_profit = gold_settings.close_pending_at_profit;
    break;

  case SYMBOL_TYPE_DOW:
    settings.max_lot = dow_settings.max_lot;
    settings.default_sl_pips = dow_settings.default_sl_pips;
    settings.default_tp_pips = dow_settings.default_tp_pips;
    settings.max_slippage_pips = dow_settings.max_slippage_pips;
    settings.pending_distance_pips = dow_settings.pending_distance_pips;
    settings.stage1_pips = dow_settings.stage1_pips;
    settings.stage1_close_percent = dow_settings.stage1_close_percent;
    settings.stage2_pips = dow_settings.stage2_pips;
    settings.stage2_close_percent = dow_settings.stage2_close_percent;
    settings.stage2_breakeven_pips = dow_settings.stage2_breakeven_pips;
    settings.stage3_pips = dow_settings.stage3_pips;
    settings.stage3_close_percent = dow_settings.stage3_close_percent;
    settings.trailing_stop_pips = dow_settings.trailing_stop_pips;
    settings.global_riskfree_pips = dow_settings.global_riskfree_pips;
    settings.riskfree_distance = dow_settings.riskfree_distance;
    settings.close_pending_at_profit = dow_settings.close_pending_at_profit;
    break;

  case SYMBOL_TYPE_NASDAQ:
    settings.max_lot = nas_settings.max_lot;
    settings.default_sl_pips = nas_settings.default_sl_pips;
    settings.default_tp_pips = nas_settings.default_tp_pips;
    settings.max_slippage_pips = nas_settings.max_slippage_pips;
    settings.pending_distance_pips = nas_settings.pending_distance_pips;
    settings.stage1_pips = nas_settings.stage1_pips;
    settings.stage1_close_percent = nas_settings.stage1_close_percent;
    settings.stage2_pips = nas_settings.stage2_pips;
    settings.stage2_close_percent = nas_settings.stage2_close_percent;
    settings.stage2_breakeven_pips = nas_settings.stage2_breakeven_pips;
    settings.stage3_pips = nas_settings.stage3_pips;
    settings.stage3_close_percent = nas_settings.stage3_close_percent;
    settings.trailing_stop_pips = nas_settings.trailing_stop_pips;
    settings.global_riskfree_pips = nas_settings.global_riskfree_pips;
    settings.riskfree_distance = nas_settings.riskfree_distance;
    settings.close_pending_at_profit = nas_settings.close_pending_at_profit;
    break;

  case SYMBOL_TYPE_FOREX:
  default:
    settings.max_lot = forex_settings.max_lot;
    settings.default_sl_pips = forex_settings.default_sl_pips;
    settings.default_tp_pips = forex_settings.default_tp_pips;
    settings.max_slippage_pips = forex_settings.max_slippage_pips;
    settings.pending_distance_pips = forex_settings.pending_distance_pips;
    settings.stage1_pips = forex_settings.stage1_pips;
    settings.stage1_close_percent = forex_settings.stage1_close_percent;
    settings.stage2_pips = forex_settings.stage2_pips;
    settings.stage2_close_percent = forex_settings.stage2_close_percent;
    settings.stage2_breakeven_pips = forex_settings.stage2_breakeven_pips;
    settings.stage3_pips = forex_settings.stage3_pips;
    settings.stage3_close_percent = forex_settings.stage3_close_percent;
    settings.trailing_stop_pips = forex_settings.trailing_stop_pips;
    settings.global_riskfree_pips = forex_settings.global_riskfree_pips;
    settings.riskfree_distance = forex_settings.riskfree_distance;
    settings.close_pending_at_profit = forex_settings.close_pending_at_profit;
    break;
  }

  return settings;
}

//+------------------------------------------------------------------+
//| Initialize Risk Data for New Position                            |
//+------------------------------------------------------------------+
void InitializeRiskDataForPosition(ulong ticket, string signalID, double entryPrice, double slPrice, double tpPrice)
{
  // Check if already exists
  for (int i = 0; i < risk_data_count; i++)
  {
    if (risk_data_array[i].ticket == ticket)
    {
      // Update existing entry
      risk_data_array[i].entry_price = entryPrice;
      risk_data_array[i].original_sl = slPrice;
      risk_data_array[i].original_tp = tpPrice;
      risk_data_array[i].current_sl = slPrice;
      risk_data_array[i].stage_completed = 0;
      risk_data_array[i].risk_free_active = false;
      risk_data_array[i].best_price = entryPrice;
      risk_data_array[i].last_check = TimeCurrent();
      risk_data_array[i].pending_closed = false;
      return;
    }
  }

  // Add new entry if there's space
  if (risk_data_count < ArraySize(risk_data_array))
  {
    risk_data_array[risk_data_count].ticket = ticket;
    risk_data_array[risk_data_count].signal_id = signalID;
    risk_data_array[risk_data_count].entry_price = entryPrice;
    risk_data_array[risk_data_count].original_sl = slPrice;
    risk_data_array[risk_data_count].original_tp = tpPrice;
    risk_data_array[risk_data_count].current_sl = slPrice;
    risk_data_array[risk_data_count].stage_completed = 0;
    risk_data_array[risk_data_count].risk_free_active = false;
    risk_data_array[risk_data_count].best_price = entryPrice;
    risk_data_array[risk_data_count].last_check = TimeCurrent();
    risk_data_array[risk_data_count].pending_closed = false;

    risk_data_count++;
    PrintLog("Risk data initialized for ticket: " + IntegerToString((long)ticket) + " Signal: " + signalID);
  }
  else
  {
    PrintLog("Warning: Risk data array is full. Cannot add ticket: " + IntegerToString((long)ticket));
  }
}

//+------------------------------------------------------------------+
//| Update Risk Data for Position                                    |
//+------------------------------------------------------------------+
void UpdateRiskDataForPosition(ulong ticket, double currentPrice)
{
  for (int i = 0; i < risk_data_count; i++)
  {
    if (risk_data_array[i].ticket == ticket)
    {
      // Get position type
      if (PositionSelectByTicket(ticket))
      {
        long position_type = PositionGetInteger(POSITION_TYPE);

        // Update best price for trailing stop
        if (position_type == POSITION_TYPE_BUY)
        {
          if (currentPrice > risk_data_array[i].best_price)
            risk_data_array[i].best_price = currentPrice;
        }
        else if (position_type == POSITION_TYPE_SELL)
        {
          if (currentPrice < risk_data_array[i].best_price)
            risk_data_array[i].best_price = currentPrice;
        }

        risk_data_array[i].last_check = TimeCurrent();
      }
      break;
    }
  }
}

//+------------------------------------------------------------------+
//| Manage Risk for All Open Positions                               |
//+------------------------------------------------------------------+
void ManageRiskForOpenPositions()
{
  if (!EnableRiskManagement)
    return;

  for (int i = PositionsTotal() - 1; i >= 0; i--)
  {
    ulong ticket = PositionGetTicket(i);
    if (ticket <= 0)
      continue;

    long magic = PositionGetInteger(POSITION_MAGIC);
    if (magic != ExpertMagicNumber)
      continue;

    string symbol = PositionGetString(POSITION_SYMBOL);
    ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);

    ApplyRiskManagement(ticket, symbol, symType);
  }
}

//+------------------------------------------------------------------+
//| Apply Risk Management to Position                                |
//+------------------------------------------------------------------+
void ApplyRiskManagement(ulong ticket, string symbol, ENUM_SYMBOL_TYPE symType)
{
  if (!PositionSelectByTicket(ticket))
    return;

  double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
  double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
  double currentSL = PositionGetDouble(POSITION_SL);
  long position_type = PositionGetInteger(POSITION_TYPE);
  bool isBuy = (position_type == POSITION_TYPE_BUY);

  // Get signal ID from comment
  string comment = PositionGetString(POSITION_COMMENT);
  string signalID = "";
  int sidPos = StringFind(comment, "SID:");
  if (sidPos >= 0)
  {
    string idPart = StringSubstr(comment, sidPos + 4);
    int space = StringFind(idPart, " ");
    if (space > 0)
      signalID = StringSubstr(idPart, 0, space);
    else
      signalID = idPart;
  }

  if (StringLen(signalID) == 0)
    return;

  // محاسبه سود بر حسب پیپ
  ENUM_SYMBOL_TYPE symTypeLocal = GetSymbolType(symbol);
  double profitPips = CalculatePipsProfit(entryPrice, currentPrice, isBuy, symbol, symTypeLocal);
  if (profitPips <= 0)
    return; // پوزیشن در ضرر است - مدیریت ریسک اعمال نشود
  // Get risk management settings
  SymbolSettings riskSettings = GetRiskManagementSettings(symType);

  // Update risk data
  UpdateRiskDataForPosition(ticket, currentPrice);

  // Find risk data for this position
  int riskIndex = -1;
  for (int i = 0; i < risk_data_count; i++)
  {
    if (risk_data_array[i].ticket == ticket)
    {
      riskIndex = i;
      break;
    }
  }

  if (riskIndex == -1)
  {
    // Initialize risk data if not exists
    InitializeRiskDataForPosition(ticket, signalID, entryPrice, currentSL, PositionGetDouble(POSITION_TP));
    // Find it again
    for (int i = 0; i < risk_data_count; i++)
    {
      if (risk_data_array[i].ticket == ticket)
      {
        riskIndex = i;
        break;
      }
    }
  }

  if (riskIndex == -1)
    return;

  // Check if we should close pending orders
  if (ClosePendingOnProfit && !risk_data_array[riskIndex].pending_closed &&
      profitPips >= riskSettings.close_pending_at_profit)
  {
    // Close all pending orders for this signal
    ClosePendingOrdersForSignal(signalID, "Profit target reached: " + DoubleToString(profitPips, 1) + " pips");
    risk_data_array[riskIndex].pending_closed = true;
  }

  // Check global risk-free condition
  if (profitPips >= riskSettings.global_riskfree_pips && !risk_data_array[riskIndex].risk_free_active)
  {
    ApplyGlobalRiskFree(ticket, entryPrice, riskSettings.global_riskfree_pips, riskSettings.riskfree_distance, isBuy, symbol);
    risk_data_array[riskIndex].risk_free_active = true;
    risk_data_array[riskIndex].stage_completed = 3;

    if (EnableTelegram)
      SendRiskManagementAlert(symbol, signalID, 4, "Global Risk-Free Activated", profitPips);

    return;
  }

  // Stage 3: 25+ pips profit
  if (profitPips >= riskSettings.stage3_pips && risk_data_array[riskIndex].stage_completed < 3)
  {
    // Close 20% of position
    ClosePartialPosition(ticket, riskSettings.stage3_close_percent, "Stage 3 Profit Taking");

    // Apply trailing stop
    ApplyTrailingStop(ticket, currentPrice, riskSettings.trailing_stop_pips, isBuy, symbol);

    risk_data_array[riskIndex].stage_completed = 3;

    if (EnableTelegram)
      SendRiskManagementAlert(symbol, signalID, 3, "Stage 3: Partial Close + Trailing Stop", profitPips);
  }
  // Stage 2: 20+ pips profit
  else if (profitPips >= riskSettings.stage2_pips && risk_data_array[riskIndex].stage_completed < 2)
  {
    // Close 15% of position
    ClosePartialPosition(ticket, riskSettings.stage2_close_percent, "Stage 2 Profit Taking");

    // Move to break-even +5 pips
    MoveToBreakEven(ticket, entryPrice, riskSettings.stage2_breakeven_pips, isBuy, symbol);

    risk_data_array[riskIndex].stage_completed = 2;

    if (EnableTelegram)
      SendRiskManagementAlert(symbol, signalID, 2, "Stage 2: Partial Close + Break-Even", profitPips);
  }
  // Stage 1: 10+ pips profit
  else if (profitPips >= riskSettings.stage1_pips && risk_data_array[riskIndex].stage_completed < 1)
  {
    // Close 10% of position
    ClosePartialPosition(ticket, riskSettings.stage1_close_percent, "Stage 1 Profit Taking");

    risk_data_array[riskIndex].stage_completed = 1;

    if (EnableTelegram)
      SendRiskManagementAlert(symbol, signalID, 1, "Stage 1: Partial Close", profitPips);
  }

  // Apply trailing stop if stage 3 is active
  if (risk_data_array[riskIndex].stage_completed >= 3)
  {
    ApplyTrailingStop(ticket, risk_data_array[riskIndex].best_price, riskSettings.trailing_stop_pips, isBuy, symbol);
  }
}

//+------------------------------------------------------------------+
//| Close Pending Orders for Signal                                  |
//+------------------------------------------------------------------+
void ClosePendingOrdersForSignal(string signalID, string reason)
{
  if (StringLen(signalID) == 0)
    return;

  int deletedOrders = 0;

  for (int i = OrdersTotal() - 1; i >= 0; i--)
  {
    ulong ticket = OrderGetTicket(i);
    if (ticket <= 0)
      continue;

    long magic = OrderGetInteger(ORDER_MAGIC);
    if (magic != ExpertMagicNumber)
      continue;

    string cmt = OrderGetString(ORDER_COMMENT);
    if (StringFind(cmt, "SID:" + signalID) >= 0)
    {
      trade.OrderDelete(ticket);
      deletedOrders++;
      PrintLog("Deleted Pending Order " + IntegerToString((long)ticket) + " for Signal " + signalID + " - Reason: " + reason);
    }
  }

  if (deletedOrders > 0 && EnableTelegram)
  {
    string message = "🗑️ *Pending Orders Closed*\n\n";
    message += "#SID_" + signalID + "\n";
    message += "🔸 Reason: " + reason + "\n";
    message += "🔸 Orders Deleted: " + IntegerToString(deletedOrders) + "\n";
    message += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);

    SendTelegramFarsi(message);
  }
}

//+------------------------------------------------------------------+
//| Close Partial Position                                           |
//+------------------------------------------------------------------+
void ClosePartialPosition(ulong ticket, double percent, string reason)
{
  if (!PositionSelectByTicket(ticket))
    return;

  double volume = PositionGetDouble(POSITION_VOLUME);
  double closeVolume = volume * percent / 100.0;

  // Normalize volume
  string symbol = PositionGetString(POSITION_SYMBOL);
  closeVolume = NormalizeLotToSymbol(closeVolume, symbol);

  if (closeVolume <= 0)
    return;

  // Check if we can close partial position
  double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
  if (closeVolume < minLot)
  {
    PrintLog("Cannot close partial: " + DoubleToString(closeVolume, 2) + " < min lot " + DoubleToString(minLot, 2));
    return;
  }

  // Close partial position using CTrade
  trade.PositionClosePartial(ticket, closeVolume);

  PrintLog("Partial close: " + DoubleToString(closeVolume, 2) + " lots (" + DoubleToString(percent, 1) + "%) - " + reason);
}

// ================ TELEGRAM FUNCTIONS ================

//+------------------------------------------------------------------+
//| Send Signal Alert                                                |
//+------------------------------------------------------------------+
void SendSignalAlert(string signalID, string symbol, string message)
{
  if (!EnableTelegram)
    return;

  string fullMessage = "📢 *Signal Alert*\n\n";
  fullMessage += "#SID_" + signalID + "\n";
  fullMessage += "🏷️ Symbol: " + symbol + "\n";
  fullMessage += message + "\n";
  fullMessage += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);

  SendTelegramFarsi(fullMessage);
}

//+------------------------------------------------------------------+
//| Move to Break-Even                                               |
//+------------------------------------------------------------------+
void MoveToBreakEven(ulong ticket, double entryPrice, int breakEvenPips, bool isBuy, string symbol)
{
  if (!PositionSelectByTicket(ticket))
    return;

  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);

  // Adjust pips to points
  double breakEvenPoints = breakEvenPips * point;
  if (symType == SYMBOL_TYPE_GOLD)
    breakEvenPoints = breakEvenPips * point * 10.0;
  else if (symType == SYMBOL_TYPE_FOREX)
    breakEvenPoints = breakEvenPips * point * 10.0;

  double newSL = 0;
  if (isBuy)
  {
    newSL = entryPrice + breakEvenPoints; // For BUY, SL above entry
  }
  else
  {
    newSL = entryPrice - breakEvenPoints; // For SELL, SL below entry
  }

  // Modify position
  trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));

  PrintLog("Break-even SL set: " + DoubleToString(newSL, 5) + " (" + IntegerToString(breakEvenPips) + " pips from entry)");
}

//+------------------------------------------------------------------+
//| Apply Trailing Stop                                              |
//+------------------------------------------------------------------+
void ApplyTrailingStop(ulong ticket, double currentPrice, int trailingPips, bool isBuy, string symbol)
{
  if (!PositionSelectByTicket(ticket))
    return;

  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);
  double currentSL = PositionGetDouble(POSITION_SL);

  // Adjust pips to points
  double trailingPoints = trailingPips * point;
  if (symType == SYMBOL_TYPE_GOLD)
    trailingPoints = trailingPips * point * 10.0;
  else if (symType == SYMBOL_TYPE_FOREX)
    trailingPoints = trailingPips * point * 10.0;

  double newSL = currentSL;

  if (isBuy)
  {
    // For BUY: SL = currentPrice - trailingPips
    double proposedSL = currentPrice - trailingPoints;
    if (proposedSL > currentSL && proposedSL > PositionGetDouble(POSITION_PRICE_OPEN))
    {
      newSL = proposedSL;
    }
  }
  else
  {
    // For SELL: SL = currentPrice + trailingPips
    double proposedSL = currentPrice + trailingPoints;
    if (proposedSL < currentSL && proposedSL < PositionGetDouble(POSITION_PRICE_OPEN))
    {
      newSL = proposedSL;
    }
  }

  // Modify if SL changed
  if (newSL != currentSL)
  {
    trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
    PrintLog("Trailing stop updated: " + DoubleToString(newSL, 5));
  }
}

//+------------------------------------------------------------------+
//| Apply Global Risk-Free                                           |
//+------------------------------------------------------------------+
void ApplyGlobalRiskFree(ulong ticket, double entryPrice, int riskFreePips, int riskFreeDistance, bool isBuy, string symbol)
{
  if (!PositionSelectByTicket(ticket))
    return;

  // Check if position is in profit
  double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
  double profit = PositionGetDouble(POSITION_PROFIT);

  if (profit <= 0)
    return; // Only apply risk-free if in profit

  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);

  // Adjust pips to points
  double riskFreePoints = riskFreeDistance * point;
  if (symType == SYMBOL_TYPE_GOLD)
    riskFreePoints = riskFreeDistance * point * 10.0;
  else if (symType == SYMBOL_TYPE_FOREX)
    riskFreePoints = riskFreeDistance * point * 10.0;

  double newSL = 0;
  if (isBuy)
  {
    newSL = entryPrice + riskFreePoints; // For BUY, SL 10 pips above entry
  }
  else
  {
    newSL = entryPrice - riskFreePoints; // For SELL, SL 10 pips below entry
  }

  // Modify position
  trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));

  PrintLog("Global Risk-Free Activated: SL = " + DoubleToString(newSL, 5) +
           " (Profit: " + DoubleToString(profit, 2) + ")");
}

//+------------------------------------------------------------------+
//| Calculate Pips Profit CORRECTED                                  |
//+------------------------------------------------------------------+
double CalculatePipsProfit(double entryPrice, double currentPrice, bool isBuy, string symbol, ENUM_SYMBOL_TYPE symType)
{
  // Get point value correctly
  double point = 0;
  if (!SymbolInfoDouble(symbol, SYMBOL_POINT, point))
  {
    PrintLog("ERROR: Cannot get point value for " + symbol);
    return 0;
  }

  // محاسبه صحیح سود/ضرر بر اساس جهت پوزیشن
  double priceDiff = 0;

  if (isBuy) // برای پوزیشن Buy
  {
    priceDiff = currentPrice - entryPrice; // اگر مثبت → سود، اگر منفی → ضرر
  }
  else // برای پوزیشن Sell
  {
    priceDiff = entryPrice - currentPrice; // اگر مثبت → سود، اگر منفی → ضرر
  }

  double pips = priceDiff / point;

  // Adjust for symbol type
  if (symType == SYMBOL_TYPE_GOLD)
    pips = pips / 10.0; // For gold, 0.10 = 1 pip
  else if (symType == SYMBOL_TYPE_DOW || symType == SYMBOL_TYPE_NASDAQ)
    pips = pips; // For indices, 1 point = 1 pip
  else
    pips = pips / 10.0; // For forex, 0.00010 = 1 pip

  PrintLog("Profit Calc: Entry=" + DoubleToString(entryPrice, 2) +
           ", Current=" + DoubleToString(currentPrice, 2) +
           ", isBuy=" + (isBuy ? "true" : "false") +
           ", RawDiff=" + DoubleToString(priceDiff, 2) +
           ", Pips=" + DoubleToString(pips, 1));

  return pips;
}
// ================ TELEGRAM ALERT FUNCTIONS ================

//+------------------------------------------------------------------+
//| Send Risk Management Alert                                       |
//+------------------------------------------------------------------+
void SendRiskManagementAlert(string symbol, string signalID, int stage, string action, double profitPips)
{
  if (!EnableTelegram)
    return;

  string stageNames[] = {"", "Stage 1", "Stage 2", "Stage 3", "Global Risk-Free"};

  string message = "🛡️ *Risk Management Alert*\n\n";
  message += "🏷️ Symbol: " + symbol + "\n";
  message += "🆔 Signal ID: `" + signalID + "`\n";
  message += "📈 Profit: " + DoubleToString(profitPips, 1) + " pips\n";
  message += "🔰 Stage: " + stageNames[stage] + "\n";
  message += "✅ Action: " + action + "\n";
  message += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);

  SendTelegramFarsi(message);
}

// ================ SYMBOL MANAGEMENT FUNCTIONS ================

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

  if (StringFind(symLower, "xau") >= 0 || StringFind(symLower, "gold") >= 0 ||
      StringFind(symLower, "XAUUSD") >= 0 || StringFind(symLower, "XAUUSD_o") >= 0)
    return SYMBOL_TYPE_GOLD;

  if (StringFind(symLower, "us30") >= 0 || StringFind(symLower, "dow") >= 0 ||
      StringFind(symLower, "dj") >= 0 || StringFind(symLower, "yinusd") >= 0 || StringFind(symLower, "ym") >= 0)
    return SYMBOL_TYPE_DOW;

  if (StringFind(symLower, "nas100") >= 0 || StringFind(symLower, "nas") >= 0 ||
      StringFind(symLower, "nq") >= 0 || StringFind(symLower, "ustec") >= 0)
    return SYMBOL_TYPE_NASDAQ;

  return SYMBOL_TYPE_FOREX;
}

//+------------------------------------------------------------------+
//| Get Symbol Settings                                              |
//+------------------------------------------------------------------+
SymbolSettings GetSymbolSettings(ENUM_SYMBOL_TYPE symType)
{
  SymbolSettings settings;

  switch (symType)
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
  switch (symType)
  {
  case SYMBOL_TYPE_GOLD:
    return "GOLD";
  case SYMBOL_TYPE_DOW:
    return "DOW JONES";
  case SYMBOL_TYPE_NASDAQ:
    return "NASDAQ";
  case SYMBOL_TYPE_FOREX:
    return "FOREX";
  default:
    return "UNKNOWN";
  }
}

//+------------------------------------------------------------------+
//| Calculate Pending Price                                          |
//+------------------------------------------------------------------+
double CalculatePendingPrice(string orderType, double slPrice, double currentPrice, string symbol, int distancePips, ENUM_SYMBOL_TYPE symType, bool isBuy)
{
  // Get point value correctly
  double point = 0;
  if (!SymbolInfoDouble(symbol, SYMBOL_POINT, point))
  {
    PrintLog("ERROR: Cannot get point value for " + symbol);
    return 0;
  }

  double multiplier = 1.0;

  switch (symType)
  {
  case SYMBOL_TYPE_GOLD:
    multiplier = 10.0;
    break;
  case SYMBOL_TYPE_DOW:
  case SYMBOL_TYPE_NASDAQ:
    multiplier = 1.0;
    break;
  case SYMBOL_TYPE_FOREX:
    multiplier = 10.0;
    break;
  default:
    multiplier = 10.0;
    break;
  }

  double distancePoints = distancePips * point * multiplier;

  if (isBuy)
  {
    return slPrice + distancePoints;
  }
  else
  {
    return slPrice - distancePoints;
  }
}

//+------------------------------------------------------------------+
//| Calculate Default SL                                             |
//+------------------------------------------------------------------+
double CalculateDefaultSL(string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings, double currentPrice, bool isBuy)
{
  // Get point value correctly
  double point = 0;
  if (!SymbolInfoDouble(symbol, SYMBOL_POINT, point))
  {
    PrintLog("ERROR: Cannot get point value for " + symbol);
    return 0;
  }

  double pips = settings.default_sl_pips;

  if (symType == SYMBOL_TYPE_GOLD)
    pips = pips * 10.0;
  else if (symType == SYMBOL_TYPE_DOW || symType == SYMBOL_TYPE_NASDAQ)
    pips = pips;
  else
    pips = pips / 10.0;

  double dist = pips * point;
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

  if (distSL > 0 && ptVal > 0 && ptSize > 0)
  {
    double distPoints = distSL / ptSize;
    lot = totalRiskMoney / (distPoints * ptVal);
  }

  return lot;
}

//+------------------------------------------------------------------+
//| Get First TP (Simplified version)                               |
//+------------------------------------------------------------------+
double GetFirstTP(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType,
                  SymbolSettings &settings, double referencePrice, bool isBuy,
                  string orderType = "", bool isMarketOrder = false, bool isPendingOrder = false)
{
  double firstTP = (sig.tp_count > 0) ? sig.tp_list[0] : 0;

  // اگر TP در سیگنال وجود داشت
  if (firstTP > 0)
  {
    // اعمال تعدیل اگر لازم باشد
    if (orderType != "" && (isMarketOrder || isPendingOrder))
    {
      firstTP = AdjustTPPrice(firstTP, symbol, symType, orderType, isMarketOrder, isPendingOrder);
    }
    return firstTP;
  }

  // محاسبه TP پیش‌فرض
  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  double pips = settings.default_tp_pips;

  // Adjust for symbol type
  if (symType == SYMBOL_TYPE_GOLD)
    pips = pips * 10.0;
  else if (symType == SYMBOL_TYPE_FOREX)
    pips = pips / 10.0;

  double dist = pips * point;
  firstTP = isBuy ? referencePrice + dist : referencePrice - dist;

  // اعمال تعدیل روی TP پیش‌فرض
  if (orderType != "" && (isMarketOrder || isPendingOrder))
  {
    firstTP = AdjustTPPrice(firstTP, symbol, symType, orderType, isMarketOrder, isPendingOrder);
  }

  return firstTP;
}
// ================ ORDER MANAGEMENT FUNCTIONS ================

//+------------------------------------------------------------------+
//| Send Order                                                       |
//+------------------------------------------------------------------+
bool SendOrder(string symbol, string order_type, bool isMarket, double entryPrice, double sl_price, double tp_price, double lot, string signalID)
{
  MqlTradeRequest request;
  MqlTradeResult result;
  ZeroMemory(request);
  ZeroMemory(result);

  int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
  double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
  if (tickSize == 0)
    tickSize = SymbolInfoDouble(symbol, SYMBOL_POINT);

  if (entryPrice > 0)
    entryPrice = MathRound(entryPrice / tickSize) * tickSize;
  if (sl_price > 0)
    sl_price = MathRound(sl_price / tickSize) * tickSize;
  if (tp_price > 0)
    tp_price = MathRound(tp_price / tickSize) * tickSize;

  ENUM_ORDER_TYPE type = (StringCompare(order_type, "sell", false) == 0) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;

  request.symbol = symbol;
  request.volume = lot;
  request.deviation = 50;
  request.magic = ExpertMagicNumber;
  request.comment = "SID:" + signalID;
  request.type_time = ORDER_TIME_GTC;
  request.type_filling = ORDER_FILLING_FOK;

  double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
  double bid = SymbolInfoDouble(symbol, SYMBOL_BID);

  if (isMarket)
  {
    request.action = TRADE_ACTION_DEAL;
    request.type = type;
    request.price = (type == ORDER_TYPE_BUY) ? ask : bid;
  }
  else
  {
    request.action = TRADE_ACTION_PENDING;
    request.price = entryPrice;

    if (type == ORDER_TYPE_BUY)
    {
      if (entryPrice > ask)
        request.type = ORDER_TYPE_BUY_STOP;
      else
        request.type = ORDER_TYPE_BUY_LIMIT;
    }
    else
    {
      if (entryPrice < bid)
        request.type = ORDER_TYPE_SELL_STOP;
      else
        request.type = ORDER_TYPE_SELL_LIMIT;
    }
  }

  if (sl_price > 0)
    request.sl = sl_price;
  if (tp_price > 0)
    request.tp = tp_price;

  bool sent = OrderSend(request, result);

  if (!sent)
  {
    PrintLog("Order Failed: " + IntegerToString(result.retcode) + " " + result.comment);
    if (EnableTelegram)
      SendTelegramFarsi("⚠️ *Order Error*\nCode: " + IntegerToString(result.retcode) + "\n" + result.comment);
  }
  else
  {
    PrintLog("Order Successful: Ticket #" + IntegerToString(result.order));
  }

  return sent;
}

//+------------------------------------------------------------------+
//| Process Multiple TPs                                             |
//+------------------------------------------------------------------+
void ProcessMultipleTPs(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings, bool executeAsMarket, double entryPrice, double sl_price,
                        double currentPrice, bool isBuy, double lot, double minLot, int &successCount, double &totalVolume, bool &singleOrderMode, string signalID)
{
  double splitLot = NormalizeLotToSymbol(lot / sig.tp_count, symbol);

  if (splitLot >= minLot)
  {
    PrintLog("Normal Mode: Creating " + IntegerToString(sig.tp_count) + " positions with volume " + DoubleToString(splitLot, 2) + " lots");

    for (int t = 0; t < sig.tp_count; t++)
    {
      double tp_val = sig.tp_list[t];
      if (tp_val <= 0)
      {
        double pt = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double pips = settings.default_tp_pips;

        if (symType == SYMBOL_TYPE_GOLD)
          pips = pips * 10.0;
        else if (symType == SYMBOL_TYPE_DOW || symType == SYMBOL_TYPE_NASDAQ)
          pips = pips;
        else
          pips = pips / 10.0;

        double dist = pips * pt;
        tp_val = isBuy ? currentPrice + dist : currentPrice - dist;
      }

      if (SendOrder(symbol, sig.order_type, executeAsMarket, entryPrice, sl_price, tp_val, splitLot, signalID))
      {
        // Initialize risk data for this position
        if (EnableRiskManagement)
          InitializeRiskDataForPosition(trade.ResultOrder(), signalID, entryPrice, sl_price, tp_val);

        successCount++;
        totalVolume += splitLot;
      }
    }
  }
  else
  {
    singleOrderMode = true;
    PrintLog("Special Mode: Invalid split volume. Creating one position with full volume");

    double firstTP = sig.tp_list[0];
    if (firstTP <= 0)
    {
      firstTP = GetFirstTP(sig, symbol, symType, settings, currentPrice, isBuy);
    }

    if (SendOrder(symbol, sig.order_type, executeAsMarket, entryPrice, sl_price, firstTP, lot, signalID))
    {
      // Initialize risk data for this position
      if (EnableRiskManagement)
        InitializeRiskDataForPosition(trade.ResultOrder(), signalID, entryPrice, sl_price, firstTP);

      successCount++;
      totalVolume += lot;
    }
  }
}

//+------------------------------------------------------------------+
//| Process Single TP                                                |
//+------------------------------------------------------------------+
void ProcessSingleTP(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings, bool executeAsMarket, double entryPrice, double sl_price,
                     double currentPrice, bool isBuy, double lot, int &successCount, double &totalVolume, string signalID)
{
  double tp_val = (sig.tp_count > 0) ? sig.tp_list[0] : 0;

  if (tp_val <= 0)
  {
    tp_val = GetFirstTP(sig, symbol, symType, settings, currentPrice, isBuy);
  }

  if (SendOrder(symbol, sig.order_type, executeAsMarket, entryPrice, sl_price, tp_val, lot, signalID))
  {
    // Initialize risk data for this position
    if (EnableRiskManagement)
      InitializeRiskDataForPosition(trade.ResultOrder(), signalID, entryPrice, sl_price, tp_val);

    successCount++;
    totalVolume += lot;
  }
}

// ================ TELEGRAM FUNCTIONS ================

//+------------------------------------------------------------------+
//| Check Telegram Settings                                          |
//+------------------------------------------------------------------+
bool CheckTelegramSettings()
{
  return (StringLen(TelegramBotToken) > 20 && StringLen(TelegramChatID) > 5);
}

//+------------------------------------------------------------------+
//| Send Telegram Message                                            |
//+------------------------------------------------------------------+
bool SendTelegramMessage(string message)
{
  if (!EnableTelegram || StringLen(TelegramBotToken) < 10)
    return false;

  string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";

  string cleanMsg = message;
  StringReplace(cleanMsg, "\"", "\\\"");
  StringReplace(cleanMsg, "\n", "\\n");
  StringReplace(cleanMsg, "\r", "");

  string json = "{\"chat_id\": \"" + TelegramChatID + "\", \"text\": \"" + cleanMsg + "\"}";

  char post[], res[];
  StringToCharArray(json, post, 0, WHOLE_ARRAY, CP_UTF8);
  if (ArraySize(post) > 0)
    ArrayResize(post, ArraySize(post) - 1);

  string headers = "Content-Type: application/json\r\n";
  string res_headers;

  int code = WebRequest("POST", url, headers, TelegramTimeout, post, res, res_headers);

  if (code != 200)
  {
    PrintLog("Telegram Error: " + IntegerToString(code));
    return false;
  }
  return true;
}

//+------------------------------------------------------------------+
//| Send Telegram Farsi Message                                      |
//+------------------------------------------------------------------+
bool SendTelegramFarsi(string message)
{
  if (!EnableTelegram)
    return false;

  // اضافه کردن هدر و فوتر استاندارد
  string formattedMsg = message;

  // اگر پیام خیلی طولانی باشد، آن را تقسیم می‌کنیم
  if (StringLen(message) > 4000)
  {
    PrintLog("Warning: Message too long for Telegram, truncating...");
    formattedMsg = StringSubstr(message, 0, 3900) + "\n\n... [Message truncated due to length limit]";
  }

  string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";

  // فرار کردن کاراکترهای خاص برای JSON
  string cleanMsg = formattedMsg;
  StringReplace(cleanMsg, "\\", "\\\\");
  StringReplace(cleanMsg, "\"", "\\\"");
  StringReplace(cleanMsg, "\n", "\\n");
  StringReplace(cleanMsg, "\r", "");
  StringReplace(cleanMsg, "\t", "\\t");

  string json = "{\"chat_id\": \"" + TelegramChatID + "\", " +
                "\"text\": \"" + cleanMsg + "\", " +
                "\"parse_mode\": \"Markdown\", " +
                "\"disable_web_page_preview\": true, " +
                "\"disable_notification\": false}";

  char post[], res[];
  StringToCharArray(json, post, 0, WHOLE_ARRAY, CP_UTF8);
  if (ArraySize(post) > 0)
    ArrayResize(post, ArraySize(post) - 1);

  string headers = "Content-Type: application/json\r\n";
  string res_headers;

  int code = WebRequest("POST", url, headers, TelegramTimeout, post, res, res_headers);

  if (code != 200)
  {
    PrintLog("Telegram Farsi Error: " + IntegerToString(code));
    if (code == -1)
      PrintLog("Check Internet connection and URL");
    else if (code == 400)
      PrintLog("Bad request - check bot token and chat ID");
    else if (code == 401)
      PrintLog("Unauthorized - invalid bot token");
    else if (code == 404)
      PrintLog("Not found - check bot token");
    return false;
  }
  return true;
}
//+------------------------------------------------------------------+
//| Send Execution Report                                            |
//+------------------------------------------------------------------+
void SendExecutionReport(string signalID, string symbol, string orderType, int totalOrders, int successfulOrders,
                         double totalVolume, bool singleOrderMode, bool pendingMode, double pendingPrice, ENUM_SYMBOL_TYPE symType)
{
  string report = "📊 *Signal Execution Report*\n\n";

  report += "🆔 Signal ID: `" + signalID + "`\n";
  report += "🏷️ Symbol: " + symbol + "\n";
  report += "📋 Type: " + GetSymbolTypeName(symType) + "\n";
  report += "📈 Order Type: " + orderType + "\n";
  report += "💰 Total Volume: " + DoubleToString(totalVolume, 2) + " lots\n";
  report += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\n\n";

  if (pendingMode)
  {
    SymbolSettings settings = GetSymbolSettings(symType);
    report += "⚡ *Special Pending Mode*\n";
    report += "🔸 Reason: Large price gap\n";
    report += "🔸 Symbol Type: " + GetSymbolTypeName(symType) + "\n";
    report += "🔸 Pending Price: " + DoubleToString(pendingPrice, 2) + "\n";
    report += "🔸 Distance from SL: " + IntegerToString(settings.pending_distance_pips) + " pips\n";
    report += "🔸 Max Slippage: " + IntegerToString(settings.max_slippage_pips) + " pips\n";
    report += "✅ 1 pending order created\n";
  }
  else if (singleOrderMode)
  {
    report += "⚠️ *Special Execution Mode*\n";
    report += "Due to small calculated volume, only 1 position with first target created.\n";
  }
  else
  {
    report += "✅ Positions created: " + IntegerToString(successfulOrders) + " of " + IntegerToString(totalOrders) + "\n";
  }

  if (successfulOrders > 0)
  {
    if (pendingMode)
      report += "\n🎯 *Pending order successfully placed!*";
    else if (successfulOrders == totalOrders)
      report += "\n🎯 *Signal successfully executed!*";
    else
      report += "\n⚠️ *Signal partially executed*";
  }
  else
  {
    report += "\n❌ *Error executing signal*";
  }

  SendTelegramFarsi(report);
}

// ================ JSON PROCESSING FUNCTIONS ================

//+------------------------------------------------------------------+
//| Parse JSON Content - FIXED VERSION                              |
//+------------------------------------------------------------------+
bool ParseJsonContent(string content, SignalData &out)
{
  PrintLog("=== Parsing JSON Content ===");

  // Reset arrays and counters
  ArrayResize(out.prices_list, 0);
  ArrayResize(out.prices_isMarket, 0);
  out.prices_count = 0;
  ArrayResize(out.tp_list, 0);
  out.tp_count = 0;
  ArrayResize(out.sl_list, 0);
  out.sl_count = 0;

  // Extract basic fields
  out.currency = ExtractJsonValue(content, "currency");
  out.order_type = ExtractJsonValue(content, "order_type");
  out.signal_id = ExtractJsonValue(content, "signal_id");
  out.status = ExtractJsonValue(content, "status");

  PrintLog("Currency: " + out.currency);
  PrintLog("Order Type: " + out.order_type);
  PrintLog("Signal ID: " + out.signal_id);

  // Parse prices array - SIMPLIFIED VERSION
  int priceStart = StringFind(content, "\"prices\":[");
  if (priceStart >= 0)
  {
    priceStart += 10; // Length of "\"prices\":["
    int priceEnd = StringFind(content, "]", priceStart);
    if (priceEnd > priceStart)
    {
      string pricesStr = StringSubstr(content, priceStart, priceEnd - priceStart);
      PrintLog("Prices string: " + pricesStr);

      // Simple parsing - find all numbers in quotes
      int pos = 0;
      int priceCount = 0;

      while (true)
      {
        // Find next price value
        int numStart = StringFind(pricesStr, "\"", pos);
        if (numStart < 0)
          break;

        int numEnd = StringFind(pricesStr, "\"", numStart + 1);
        if (numEnd < 0)
          break;

        string numStr = StringSubstr(pricesStr, numStart + 1, numEnd - numStart - 1);

        // Check if it's a number (not "price" text)
        if (StringLen(numStr) > 0 && numStr != "price")
        {
          double price = StringToDouble(numStr);

          if (price > 0)
          {
            // Add to arrays
            ArrayResize(out.prices_list, priceCount + 1);
            ArrayResize(out.prices_isMarket, priceCount + 1);
            out.prices_list[priceCount] = price;
            out.prices_isMarket[priceCount] = false;
            priceCount++;

            PrintLog("Found price " + IntegerToString(priceCount) + ": " + DoubleToString(price, 2));
          }
        }

        pos = numEnd + 1;
        if (pos >= StringLen(pricesStr))
          break;
      }

      out.prices_count = priceCount;
      PrintLog("Total prices found: " + IntegerToString(out.prices_count));
    }
  }

  // Parse TP array - SIMPLIFIED VERSION
  int tpStart = StringFind(content, "\"tp\":[");
  if (tpStart >= 0)
  {
    tpStart += 6; // Length of "\"tp\":["
    int tpEnd = StringFind(content, "]", tpStart);
    if (tpEnd > tpStart)
    {
      string tpStr = StringSubstr(content, tpStart, tpEnd - tpStart);
      PrintLog("TP string: " + tpStr);

      // Simple parsing - find all tp_item values
      int pos = 0;
      int tpCount = 0;

      while (true)
      {
        // Find next tp_item value
        int itemStart = StringFind(tpStr, "\"tp_item\":\"", pos);
        if (itemStart < 0)
          break;

        itemStart += 11; // Length of "\"tp_item\":\""
        int itemEnd = StringFind(tpStr, "\"", itemStart);
        if (itemEnd < 0)
          break;

        string itemStr = StringSubstr(tpStr, itemStart, itemEnd - itemStart);

        // Check if it's OPEN or a number
        if (StringCompare(itemStr, "OPEN", true) == 0)
        {
          ArrayResize(out.tp_list, tpCount + 1);
          out.tp_list[tpCount] = 0; // 0 means OPEN
          tpCount++;
          PrintLog("Found TP " + IntegerToString(tpCount) + ": OPEN");
        }
        else
        {
          double tpVal = StringToDouble(itemStr);
          if (tpVal > 0)
          {
            ArrayResize(out.tp_list, tpCount + 1);
            out.tp_list[tpCount] = tpVal;
            tpCount++;
            PrintLog("Found TP " + IntegerToString(tpCount) + ": " + DoubleToString(tpVal, 2));
          }
        }

        pos = itemEnd + 1;
        if (pos >= StringLen(tpStr))
          break;
      }

      out.tp_count = tpCount;
      PrintLog("Total TPs found: " + IntegerToString(out.tp_count));

      // Check if OPEN is missing (only 3 TPs in your example)
      if (out.tp_count == 3)
      {
        PrintLog("Adding OPEN as 4th TP");
        ArrayResize(out.tp_list, 4);
        out.tp_list[3] = 0; // OPEN
        out.tp_count = 4;
      }
    }
  }

  // Parse SL array - SIMPLIFIED VERSION
  int slStart = StringFind(content, "\"sl\":[");
  if (slStart >= 0)
  {
    slStart += 6; // Length of "\"sl\":["
    int slEnd = StringFind(content, "]", slStart);
    if (slEnd > slStart)
    {
      string slStr = StringSubstr(content, slStart, slEnd - slStart);
      PrintLog("SL string: " + slStr);

      // Find sl_item value
      int itemStart = StringFind(slStr, "\"sl_item\":\"");
      if (itemStart >= 0)
      {
        itemStart += 11; // Length of "\"sl_item\":\""
        int itemEnd = StringFind(slStr, "\"", itemStart);
        if (itemEnd > itemStart)
        {
          string slValStr = StringSubstr(slStr, itemStart, itemEnd - itemStart);
          double slVal = StringToDouble(slValStr);

          ArrayResize(out.sl_list, 1);
          out.sl_list[0] = slVal;
          out.sl_count = 1;

          PrintLog("Found SL: " + DoubleToString(slVal, 2));
        }
      }
    }
  }

  // If no SL found, check for simple SL value
  if (out.sl_count == 0)
  {
    string slSimple = ExtractJsonValue(content, "sl");
    if (StringLen(slSimple) > 0)
    {
      double slVal = StringToDouble(slSimple);
      if (slVal > 0)
      {
        ArrayResize(out.sl_list, 1);
        out.sl_list[0] = slVal;
        out.sl_count = 1;
        PrintLog("Found SL (simple): " + DoubleToString(slVal, 2));
      }
    }
  }

  PrintLog("=== Parsing Complete ===");
  PrintLog("Prices: " + IntegerToString(out.prices_count));
  PrintLog("TPs: " + IntegerToString(out.tp_count));
  PrintLog("SLs: " + IntegerToString(out.sl_count));

  // Debug output
  for (int i = 0; i < out.prices_count; i++)
  {
    PrintLog("Price[" + IntegerToString(i) + "] = " + DoubleToString(out.prices_list[i], 2));
  }
  for (int i = 0; i < out.tp_count; i++)
  {
    if (out.tp_list[i] == 0)
      PrintLog("TP[" + IntegerToString(i) + "] = OPEN");
    else
      PrintLog("TP[" + IntegerToString(i) + "] = " + DoubleToString(out.tp_list[i], 2));
  }

  return (out.prices_count > 0);
}
//+------------------------------------------------------------------+
//| Extract Value from JSON string - SIMPLIFIED                     |
//+------------------------------------------------------------------+
string ExtractJsonValue(string json, string key)
{
  string search = "\"" + key + "\":\"";
  int pos = StringFind(json, search);
  if (pos < 0)
  {
    // Try without quotes around value
    search = "\"" + key + "\":";
    pos = StringFind(json, search);
    if (pos < 0)
      return "";
  }

  pos += StringLen(search);

  int endPos = pos;
  while (endPos < StringLen(json))
  {
    ushort c = StringGetCharacter(json, endPos);
    if (c == '"' || c == ',' || c == '}')
      break;
    endPos++;
  }

  string res = StringSubstr(json, pos, endPos - pos);
  StringReplace(res, "\"", "");
  return StringTrimCustom(res);
}

//+------------------------------------------------------------------+
//| Extract Array from JSON string                                   |
//+------------------------------------------------------------------+
bool ExtractJsonArray(string json, string arrayKey, double &outArray[], int &outCount)
{
  outCount = 0;
  ArrayResize(outArray, 0);
  string search = "\"" + arrayKey + "\":";
  int pos = StringFind(json, search);
  if (pos < 0)
    return false;

  int start = StringFind(json, "[", pos);
  if (start < 0)
    return false;

  int end = -1;
  int depth = 0;
  for (int i = start; i < StringLen(json); i++)
  {
    ushort c = StringGetCharacter(json, i);
    if (c == '[')
      depth++;
    if (c == ']')
    {
      depth--;
      if (depth == 0)
      {
        end = i;
        break;
      }
    }
  }
  if (end < 0)
    return false;

  string inner = StringSubstr(json, start + 1, end - start - 1);
  string items[];
  int cnt = StringSplit(inner, ',', items);

  for (int i = 0; i < cnt; i++)
  {
    string s = items[i];
    StringReplace(s, "\"", "");
    StringReplace(s, "{", "");
    StringReplace(s, "}", "");
    StringReplace(s, "tp_item", "");
    StringReplace(s, "sl_item", "");
    StringReplace(s, ":", "");
    s = StringTrimCustom(s);

    if (StringFind(StringToLowerCustom(s), "open") >= 0)
    {
      ArrayResize(outArray, outCount + 1);
      outArray[outCount] = 0;
      outCount++;
    }
    else
    {
      double val = StringToDouble(s);
      if (val > 0 || s == "0")
      {
        ArrayResize(outArray, outCount + 1);
        outArray[outCount] = val;
        outCount++;
      }
    }
  }
  return (outCount > 0);
}

// ================ POSITION MANAGEMENT FUNCTIONS ================

//+------------------------------------------------------------------+
//| Management: Check History for TP Hits                            |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
  if (!CloseOthersOnFirstTP && !DeletePendingOnTP)
    return;

  if (!HistorySelect(last_history_check - 60, TimeCurrent()))
    return;

  int total = HistoryDealsTotal();
  for (int i = 0; i < total; i++)
  {
    ulong ticket = HistoryDealGetTicket(i);
    if (ticket <= 0)
      continue;

    long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
    if (magic != ExpertMagicNumber)
      continue;

    long reason = HistoryDealGetInteger(ticket, DEAL_REASON);
    if (reason == DEAL_REASON_TP)
    {
      string comment = HistoryDealGetString(ticket, DEAL_COMMENT);
      int sidPos = StringFind(comment, "SID:");
      if (sidPos >= 0)
      {
        string idPart = StringSubstr(comment, sidPos + 4);
        string signalID = idPart;
        int space = StringFind(signalID, " ");
        if (space > 0)
          signalID = StringSubstr(signalID, 0, space);

        PrintLog("TP Detected for Signal ID: " + signalID);

        if (EnableTelegram)
        {
          string tpMessage = "🎯 *Target Reached!*\n\n";
          tpMessage += "🆔 Signal ID: `" + signalID + "`\n";
          tpMessage += "💰 Profit: " + DoubleToString(HistoryDealGetDouble(ticket, DEAL_PROFIT), 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + "\n";
          tpMessage += "⏰ Time: " + TimeToString(HistoryDealGetInteger(ticket, DEAL_TIME), TIME_DATE | TIME_SECONDS);

          SendTelegramFarsi(tpMessage);
        }

        CloseGroupOrders(signalID);
      }
    }
  }
  last_history_check = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Management: Close/Delete group orders                            |
//+------------------------------------------------------------------+
void CloseGroupOrders(string signalID)
{
  if (StringLen(signalID) == 0)
    return;

  int closedPositions = 0;
  int deletedOrders = 0;

  // 1. Delete Pending Orders
  if (DeletePendingOnTP)
  {
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
      ulong ticket = OrderGetTicket(i);
      if (ticket > 0 && OrderGetInteger(ORDER_MAGIC) == ExpertMagicNumber)
      {
        string cmt = OrderGetString(ORDER_COMMENT);
        if (StringFind(cmt, "SID:" + signalID) >= 0)
        {
          trade.OrderDelete(ticket);
          deletedOrders++;
          PrintLog("Deleted Pending Order " + IntegerToString((long)ticket) + " for Group " + signalID);
        }
      }
    }
  }

  // 2. Close Positions
  if (CloseOthersOnFirstTP)
  {
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
      ulong ticket = PositionGetTicket(i);
      if (ticket > 0 && PositionGetInteger(POSITION_MAGIC) == ExpertMagicNumber)
      {
        string cmt = PositionGetString(POSITION_COMMENT);
        if (StringFind(cmt, "SID:" + signalID) >= 0)
        {
          trade.PositionClose(ticket);
          closedPositions++;
          PrintLog("Closed Position " + IntegerToString((long)ticket) + " for Group " + signalID);
        }
      }
    }
  }

  if (EnableTelegram && (closedPositions > 0 || deletedOrders > 0))
  {
    string closeReport = "🗑️ *Group Close Report*\n\n";
    closeReport += "🆔 Signal ID: `" + signalID + "`\n";
    closeReport += "🔴 Positions closed: " + IntegerToString(closedPositions) + "\n";
    closeReport += "✂️ Orders deleted: " + IntegerToString(deletedOrders) + "\n";
    closeReport += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);

    SendTelegramFarsi(closeReport);
  }
}

// ================ HELPER FUNCTIONS ================

//+------------------------------------------------------------------+
//| Normalize Content Lines                                          |
//+------------------------------------------------------------------+
string NormalizeContentLines(string content)
{
  if (StringLen(content) == 0)
    return content;
  string parts[];
  int cnt = StringSplit(content, '\n', parts);
  if (cnt <= 1)
    return content;

  int singleChars = 0;
  for (int i = 0; i < cnt; i++)
  {
    string s = parts[i];
    StringTrimLeft(s);
    StringTrimRight(s);
    if (StringLen(s) <= 1)
      singleChars++;
  }

  if (cnt >= 5 && ((double)singleChars / cnt > 0.6))
  {
    string joined = "";
    for (int i = 0; i < cnt; i++)
    {
      string s = parts[i];
      StringReplace(s, "\r", "");
      joined += s;
    }
    return joined;
  }
  return content;
}

//+------------------------------------------------------------------+
//| Print Log                                                        |
//+------------------------------------------------------------------+
void PrintLog(string message)
{
  if (EnableLogging)
    Print(message);
}

//+------------------------------------------------------------------+
//| String Trim Custom                                               |
//+------------------------------------------------------------------+
string StringTrimCustom(string str)
{
  string s = str;
  StringTrimLeft(s);
  StringTrimRight(s);
  return s;
}

//+------------------------------------------------------------------+
//| String To Lower Custom                                           |
//+------------------------------------------------------------------+
string StringToLowerCustom(string str)
{
  string s = str;
  StringToLower(s);
  return s;
}

//+------------------------------------------------------------------+
//| String Contains                                                  |
//+------------------------------------------------------------------+
bool StringContains(string str, string substr)
{
  return (StringFind(str, substr) >= 0);
}

//+------------------------------------------------------------------+
//| Estimate Pip Value Per Lot                                       |
//+------------------------------------------------------------------+
double EstimatePipValuePerLot(string symbol)
{
  double tickValue = 0;
  double tickSize = 0;

  if (!SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE, tickValue))
  {
    PrintLog("ERROR: Cannot get tick value for " + symbol);
    return 10.0;
  }

  if (!SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE, tickSize))
  {
    PrintLog("ERROR: Cannot get tick size for " + symbol);
    return 10.0;
  }

  if (tickValue > 0 && tickSize > 0)
    return tickValue / tickSize;

  return 10.0;
}

//+------------------------------------------------------------------+
//| Normalize Lot to Symbol                                          |
//+------------------------------------------------------------------+
double NormalizeLotToSymbol(double lot, string symbol)
{
  double min = 0;
  double max = 0;
  double step = 0;

  if (!SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN, min))
    min = 0.01;

  if (!SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX, max))
    max = 100.0;

  if (!SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP, step))
    step = 0.01;

  if (min <= 0)
    min = 0.01;
  if (step <= 0)
    step = 0.01;

  if (lot < min)
    lot = min;
  if (lot > max)
    lot = max;

  double steps = MathFloor(lot / step + 0.000001);
  lot = steps * step;

  return NormalizeDouble(lot, 2);
}
//+------------------------------------------------------------------+
//| Count Open Positions for Signal                                  |
//+------------------------------------------------------------------+
int CountOpenPositionsForSignal(string signalID)
{
  int count = 0;
  for (int i = PositionsTotal() - 1; i >= 0; i--)
  {
    ulong ticket = PositionGetTicket(i);
    if (ticket <= 0)
      continue;

    long magic = PositionGetInteger(POSITION_MAGIC);
    if (magic != ExpertMagicNumber)
      continue;

    string cmt = PositionGetString(POSITION_COMMENT);
    if (StringFind(cmt, "SID:" + signalID) >= 0)
      count++;
  }
  return count;
}

//+------------------------------------------------------------------+
//| Count Pending Orders for Signal                                  |
//+------------------------------------------------------------------+
int CountPendingOrdersForSignal(string signalID)
{
  int count = 0;
  for (int i = OrdersTotal() - 1; i >= 0; i--)
  {
    ulong ticket = OrderGetTicket(i);
    if (ticket <= 0)
      continue;

    long magic = OrderGetInteger(ORDER_MAGIC);
    if (magic != ExpertMagicNumber)
      continue;

    string cmt = OrderGetString(ORDER_COMMENT);
    if (StringFind(cmt, "SID:" + signalID) >= 0)
      count++;
  }
  return count;
}
//+------------------------------------------------------------------+
//| Calculate Position Risk in Money                                |
//+------------------------------------------------------------------+
double CalculatePositionRiskMoney(ulong ticket)
{
  if (!PositionSelectByTicket(ticket))
    return 0;

  string symbol = PositionGetString(POSITION_SYMBOL);
  double volume = PositionGetDouble(POSITION_VOLUME);
  double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
  double sl = PositionGetDouble(POSITION_SL);

  // اگر SL تنظیم نشده، ریسک را صفر در نظر بگیر
  if (sl <= 0)
    return 0;

  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
  double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
  if (tickSize <= 0)
    tickSize = point;

  ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

  // محاسبه فاصله SL از نقطه ورود
  double slDistance = 0;
  if (type == POSITION_TYPE_BUY)
    slDistance = (openPrice - sl) / tickSize; // تعداد تیک‌ها
  else
    slDistance = (sl - openPrice) / tickSize;

  // محاسبه ریسک پولی
  double riskMoney = (slDistance * tickValue * volume);

  return MathAbs(riskMoney);
}

//+------------------------------------------------------------------+
//| Calculate Total Risk of All Open Positions                      |
//+------------------------------------------------------------------+
double CalculateTotalOpenPositionsRiskMoney()
{
  double totalRiskMoney = 0;

  for (int i = PositionsTotal() - 1; i >= 0; i--)
  {
    ulong ticket = PositionGetTicket(i);
    if (ticket <= 0)
      continue;

    // فقط پوزیشن‌های این EA
    long magic = PositionGetInteger(POSITION_MAGIC);
    if (magic != ExpertMagicNumber)
      continue;

    double positionRisk = CalculatePositionRiskMoney(ticket);
    totalRiskMoney += positionRisk;
  }

  return totalRiskMoney;
}

//+------------------------------------------------------------------+
//| Calculate Total Risk Percentage                                 |
//+------------------------------------------------------------------+
double CalculateTotalRiskPercentage()
{
  double balance = AccountInfoDouble(ACCOUNT_BALANCE);
  if (balance <= 0)
    return 0;

  double totalRiskMoney = CalculateTotalOpenPositionsRiskMoney();
  double riskPercent = (totalRiskMoney / balance) * 100.0;

  return riskPercent;
}

//+------------------------------------------------------------------+
//| Check Global Risk Limit                                         |
//+------------------------------------------------------------------+
bool CheckGlobalRiskLimit(double signalRiskMoney)
{
  if (!EnableGlobalRiskLimit)
    return true; // اگر غیرفعال باشد، همیشه مجاز است

  double currentRiskMoney = CalculateTotalOpenPositionsRiskMoney();
  double balance = AccountInfoDouble(ACCOUNT_BALANCE);

  if (balance <= 0)
    return false;

  double potentialRiskMoney = currentRiskMoney + signalRiskMoney;
  double potentialRiskPercent = (potentialRiskMoney / balance) * 100.0;

  if (potentialRiskPercent > MaxTotalRiskPercent)
  {
    PrintLog("❌ GLOBAL RISK LIMIT VIOLATION!");
    PrintLog("   Balance: $" + DoubleToString(balance, 2));
    PrintLog("   Current Risk: $" + DoubleToString(currentRiskMoney, 2) +
             " (" + DoubleToString((currentRiskMoney / balance) * 100, 1) + "%)");
    PrintLog("   Signal Risk: $" + DoubleToString(signalRiskMoney, 2) +
             " (" + DoubleToString((signalRiskMoney / balance) * 100, 1) + "%)");
    PrintLog("   Potential Total: $" + DoubleToString(potentialRiskMoney, 2) +
             " (" + DoubleToString(potentialRiskPercent, 1) + "%)");
    PrintLog("   Max Allowed: " + DoubleToString(MaxTotalRiskPercent, 1) + "%");

    if (EnableTelegram)
    {
      SendTelegramFarsi("🚫 *Global Risk Limit Exceeded*\n\n" +
                        "💰 Balance: $" + DoubleToString(balance, 2) + "\n" +
                        "📊 Current Risk: " + DoubleToString((currentRiskMoney / balance) * 100, 1) + "%\n" +
                        "📈 Signal Risk: " + DoubleToString((signalRiskMoney / balance) * 100, 1) + "%\n" +
                        "⚠️ Potential: " + DoubleToString(potentialRiskPercent, 1) + "%\n" +
                        "🎯 Max: " + DoubleToString(MaxTotalRiskPercent, 1) + "%\n\n" +
                        "Signal execution BLOCKED");
    }

    return false;
  }

  PrintLog("✅ Global Risk Check PASSED");
  PrintLog("   Current: $" + DoubleToString(currentRiskMoney, 2) +
           " (" + DoubleToString((currentRiskMoney / balance) * 100, 1) + "%)");
  PrintLog("   With Signal: $" + DoubleToString(potentialRiskMoney, 2) +
           " (" + DoubleToString(potentialRiskPercent, 1) + "%)");
  PrintLog("   Limit: " + DoubleToString(MaxTotalRiskPercent, 1) + "%");

  return true;
}

//+------------------------------------------------------------------+
//| Get Adjustment Pips for Symbol Type                             |
//+------------------------------------------------------------------+
double GetTPAdjustPips(ENUM_SYMBOL_TYPE symType, bool isBuy, bool isMarketOrder, bool isPendingOrder)
{
  if (isMarketOrder)
  {
    if (isBuy)
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD:
        return Gold_BuyMarketTP_AdjustPips;
      case SYMBOL_TYPE_DOW:
        return Dow_BuyMarketTP_AdjustPips;
      case SYMBOL_TYPE_NASDAQ:
        return Nas_BuyMarketTP_AdjustPips;
      case SYMBOL_TYPE_FOREX:
        return Forex_BuyMarketTP_AdjustPips;
      default:
        return 0.0;
      }
    }
    else // Sell
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD:
        return Gold_SellMarketTP_AdjustPips;
      case SYMBOL_TYPE_DOW:
        return Dow_SellMarketTP_AdjustPips;
      case SYMBOL_TYPE_NASDAQ:
        return Nas_SellMarketTP_AdjustPips;
      case SYMBOL_TYPE_FOREX:
        return Forex_SellMarketTP_AdjustPips;
      default:
        return 0.0;
      }
    }
  }
  else if (isPendingOrder)
  {
    if (isBuy)
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD:
        return Gold_BuyPendingTP_AdjustPips;
      case SYMBOL_TYPE_DOW:
        return Dow_BuyPendingTP_AdjustPips;
      case SYMBOL_TYPE_NASDAQ:
        return Nas_BuyPendingTP_AdjustPips;
      case SYMBOL_TYPE_FOREX:
        return Forex_BuyPendingTP_AdjustPips;
      default:
        return 0.0;
      }
    }
    else // Sell
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD:
        return Gold_SellPendingTP_AdjustPips;
      case SYMBOL_TYPE_DOW:
        return Dow_SellPendingTP_AdjustPips;
      case SYMBOL_TYPE_NASDAQ:
        return Nas_SellPendingTP_AdjustPips;
      case SYMBOL_TYPE_FOREX:
        return Forex_SellPendingTP_AdjustPips;
      default:
        return 0.0;
      }
    }
  }

  return 0.0;
}

//+------------------------------------------------------------------+
//| Get SL Adjustment Pips for Symbol Type                          |
//+------------------------------------------------------------------+
double GetSLAdjustPips(ENUM_SYMBOL_TYPE symType, bool isBuy, bool isMarketOrder, bool isPendingOrder)
{
  if (isMarketOrder)
  {
    if (isBuy)
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD:
        return Gold_BuyMarketSL_AdjustPips;
      case SYMBOL_TYPE_DOW:
        return Dow_BuyMarketSL_AdjustPips;
      case SYMBOL_TYPE_NASDAQ:
        return Nas_BuyMarketSL_AdjustPips;
      case SYMBOL_TYPE_FOREX:
        return Forex_BuyMarketSL_AdjustPips;
      default:
        return 0.0;
      }
    }
    else // Sell
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD:
        return Gold_SellMarketSL_AdjustPips;
      case SYMBOL_TYPE_DOW:
        return Dow_SellMarketSL_AdjustPips;
      case SYMBOL_TYPE_NASDAQ:
        return Nas_SellMarketSL_AdjustPips;
      case SYMBOL_TYPE_FOREX:
        return Forex_SellMarketSL_AdjustPips;
      default:
        return 0.0;
      }
    }
  }
  else if (isPendingOrder)
  {
    if (isBuy)
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD:
        return Gold_BuyPendingSL_AdjustPips;
      case SYMBOL_TYPE_DOW:
        return Dow_BuyPendingSL_AdjustPips;
      case SYMBOL_TYPE_NASDAQ:
        return Nas_BuyPendingSL_AdjustPips;
      case SYMBOL_TYPE_FOREX:
        return Forex_BuyPendingSL_AdjustPips;
      default:
        return 0.0;
      }
    }
    else // Sell
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD:
        return Gold_SellPendingSL_AdjustPips;
      case SYMBOL_TYPE_DOW:
        return Dow_SellPendingSL_AdjustPips;
      case SYMBOL_TYPE_NASDAQ:
        return Nas_SellPendingSL_AdjustPips;
      case SYMBOL_TYPE_FOREX:
        return Forex_SellPendingSL_AdjustPips;
      default:
        return 0.0;
      }
    }
  }

  return 0.0;
}

//+------------------------------------------------------------------+
//| Adjust Price with Pips                                          |
//+------------------------------------------------------------------+
double AdjustPriceWithPips(double originalPrice, double adjustPips, string symbol,
                           ENUM_SYMBOL_TYPE symType, bool isBuy, bool isTP)
{
  if (adjustPips == 0.0)
    return originalPrice;
  if (originalPrice <= 0)
    return originalPrice;

  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  double multiplier = 1.0;

  // Convert pips to points based on symbol type
  if (symType == SYMBOL_TYPE_GOLD)
    multiplier = 10.0; // For Gold: 0.01 = 1 pip
  else if (symType == SYMBOL_TYPE_FOREX)
    multiplier = 10.0; // For Forex: 0.0001 = 1 pip
  // For indices: 1.0 = 1 pip

  double adjustmentPoints = adjustPips * point * multiplier;

  // Apply adjustment based on direction
  if (isBuy)
  {
    if (isTP) // Buy TP - اضافه کردن به قیمت
      return originalPrice + adjustmentPoints;
    else // Buy SL - کم کردن از قیمت
      return originalPrice - adjustmentPoints;
  }
  else // Sell
  {
    if (isTP) // Sell TP - کم کردن از قیمت
      return originalPrice - adjustmentPoints;
    else // Sell SL - اضافه کردن به قیمت
      return originalPrice + adjustmentPoints;
  }
}

//+------------------------------------------------------------------+
//| Adjust TP Price                                                 |
//+------------------------------------------------------------------+
double AdjustTPPrice(double originalTP, string symbol, ENUM_SYMBOL_TYPE symType,
                     string orderType, bool isMarketOrder, bool isPendingOrder)
{
  if (originalTP <= 0)
    return originalTP;

  string orderTypeLower = StringToLowerCustom(orderType);
  bool isBuy = (StringFind(orderTypeLower, "buy") >= 0);

  double adjustPips = GetTPAdjustPips(symType, isBuy, isMarketOrder, isPendingOrder);

  if (adjustPips == 0.0)
    return originalTP;

  double adjustedTP = AdjustPriceWithPips(originalTP, adjustPips, symbol, symType, isBuy, true);

  PrintLog("TP Adjustment: " + DoubleToString(originalTP, 5) + " → " +
           DoubleToString(adjustedTP, 5) + " (" +
           DoubleToString(adjustPips, 1) + " pips)");

  return adjustedTP;
}

//+------------------------------------------------------------------+
//| Adjust SL Price                                                 |
//+------------------------------------------------------------------+
double AdjustSLPrice(double originalSL, string symbol, ENUM_SYMBOL_TYPE symType,
                     string orderType, bool isMarketOrder, bool isPendingOrder)
{
  if (originalSL <= 0)
    return originalSL;

  string orderTypeLower = StringToLowerCustom(orderType);
  bool isBuy = (StringFind(orderTypeLower, "buy") >= 0);

  double adjustPips = GetSLAdjustPips(symType, isBuy, isMarketOrder, isPendingOrder);

  if (adjustPips == 0.0)
    return originalSL;

  double adjustedSL = AdjustPriceWithPips(originalSL, adjustPips, symbol, symType, isBuy, false);

  PrintLog("SL Adjustment: " + DoubleToString(originalSL, 5) + " → " +
           DoubleToString(adjustedSL, 5) + " (" +
           DoubleToString(adjustPips, 1) + " pips)");

  return adjustedSL;
}

//+------------------------------------------------------------------+
//| Send Signal Entry Report to Telegram                            |
//+------------------------------------------------------------------+
void SendSignalEntryReport(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType)
{
  if (!EnableTelegram)
    return;

  string report = "🚨 *NEW SIGNAL RECEIVED!* 🚨\n\n";

  report += "🆔 Signal ID: `" + sig.signal_id + "`\n";
  report += "🏷️ Symbol: " + symbol + "\n";
  report += "📊 Type: " + GetSymbolTypeName(symType) + "\n";
  report += "📈 Order Type: " + sig.order_type + "\n";

  report += "\n📋 *Signal Details:*\n";

  // قیمت‌ها
  if (sig.prices_count > 0)
  {
    report += "💰 *Entry Prices:*\n";
    for (int i = 0; i < MathMin(sig.prices_count, 5); i++) // حداکثر 5 قیمت نشان دهیم
    {
      report += "  " + IntegerToString(i + 1) + ". " + DoubleToString(sig.prices_list[i], 5) + "\n";
    }
    if (sig.prices_count > 5)
      report += "  ... + " + IntegerToString(sig.prices_count - 5) + " more\n";
  }

  // Take Profit ها
  if (sig.tp_count > 0)
  {
    report += "\n🎯 *Take Profit Levels:*\n";
    for (int i = 0; i < MathMin(sig.tp_count, 4); i++) // حداکثر 4 TP
    {
      if (sig.tp_list[i] == 0)
        report += "  TP" + IntegerToString(i + 1) + ": OPEN\n";
      else
        report += "  TP" + IntegerToString(i + 1) + ": " + DoubleToString(sig.tp_list[i], 5) + "\n";
    }
    if (sig.tp_count > 4)
      report += "  ... + " + IntegerToString(sig.tp_count - 4) + " more\n";
  }

  // Stop Loss
  if (sig.sl_count > 0 && sig.sl_list[0] > 0)
  {
    report += "\n🛡️ *Stop Loss:* " + DoubleToString(sig.sl_list[0], 5) + "\n";
  }
  else
  {
    ENUM_SYMBOL_TYPE symTypeLocal = GetSymbolType(symbol);
    SymbolSettings settings = GetSymbolSettings(symTypeLocal);
    double defaultSL = CalculateDefaultSL(symbol, symTypeLocal, settings,
                                          SymbolInfoDouble(symbol, SYMBOL_BID),
                                          StringFind(sig.order_type, "buy") >= 0);
    report += "\n🛡️ *Stop Loss (Auto):* " + DoubleToString(defaultSL, 5) + "\n";
  }

  // اطلاعات حساب
  double balance = AccountInfoDouble(ACCOUNT_BALANCE);
  double riskMoney = balance * RiskPercentPerSignal / 100.0;
  double maxTotalRisk = balance * MaxTotalRiskPercent / 100.0;
  double currentRisk = CalculateTotalOpenPositionsRiskMoney();
  double currentRiskPercent = (currentRisk / balance) * 100.0;

  report += "\n💰 *Account Info:*\n";
  report += "  Balance: $" + DoubleToString(balance, 2) + "\n";
  report += "  Signal Risk: $" + DoubleToString(riskMoney, 2) + " (" + DoubleToString(RiskPercentPerSignal, 1) + "%)\n";
  report += "  Current Risk: $" + DoubleToString(currentRisk, 2) + " (" + DoubleToString(currentRiskPercent, 1) + "%)\n";
  report += "  Max Total Risk: $" + DoubleToString(maxTotalRisk, 2) + " (" + DoubleToString(MaxTotalRiskPercent, 1) + "%)\n";

  // وضعیت ریسک
  if (EnableGlobalRiskLimit)
  {
    double potentialRisk = currentRisk + riskMoney;
    double potentialPercent = (potentialRisk / balance) * 100.0;

    if (potentialPercent > MaxTotalRiskPercent)
    {
      report += "\n⚠️ *Risk Status:* ❌ EXCEEDS LIMIT!\n";
      report += "  Potential: " + DoubleToString(potentialPercent, 1) + "%\n";
      report += "  Limit: " + DoubleToString(MaxTotalRiskPercent, 1) + "%\n";
      report += "  🔒 Signal execution may be blocked\n";
    }
    else if (potentialPercent > MaxTotalRiskPercent * 0.8)
    {
      report += "\n⚠️ *Risk Status:* ⚠️ APPROACHING LIMIT\n";
      report += "  Potential: " + DoubleToString(potentialPercent, 1) + "%\n";
      report += "  Limit: " + DoubleToString(MaxTotalRiskPercent, 1) + "%\n";
    }
    else
    {
      report += "\n✅ *Risk Status:* ✓ WITHIN LIMIT\n";
      report += "  Potential: " + DoubleToString(potentialPercent, 1) + "%\n";
      report += "  Limit: " + DoubleToString(MaxTotalRiskPercent, 1) + "%\n";
    }
  }

  report += "\n⏰ Time: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);

  SendTelegramFarsi(report);
}
//+------------------------------------------------------------------+