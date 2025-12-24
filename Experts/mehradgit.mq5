//+------------------------------------------------------------------+
//| SignalExecutor.mq5                                               |
//| Expert Advisor: Signal Execution from JSON File                 |
//| Version: 1.95 (Enhanced Risk Management with Retry Logic)       |
//+------------------------------------------------------------------+
#property copyright "Generated for mehradgit"
#property version "1.95"
#property strict

#include <Trade\Trade.mqh>
#include <DashboardUploader.mqh>

// ================ INPUT PARAMETERS ================

input group "General Settings" input int PollIntervalSeconds = 2; // Poll Interval (seconds)
input int DashboardRefreshRate = 10;                              // Dashboard Update (seconds)
input bool AutoOpenDashboard = false;                             // Auto-open Dashboard
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

input group "Execution Settings - BITCOIN (BTCUSD, BTC)" input double MaxLotSize_BTC = 1.0; // Max lot size for Bitcoin
input double DefaultStopPips_BTC = 500;                                                     // Default SL for Bitcoin (pips)
input double DefaultTpForOpenPips_BTC = 500;                                                // Default TP for Bitcoin (pips)
input int MaxSlippageForMarketPips_BTC = 200;                                               // Max slippage for Bitcoin
input int PendingOrderDistanceFromSL_BTC = 500;                                             // Pending distance for Bitcoin

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

input group "Risk Management Stages - BITCOIN" input int Btc_Stage1_Pips = 100; // Bitcoin has larger moves
input double Btc_Stage1_ClosePercent = 10.0;
input int Btc_Stage2_Pips = 200;
input double Btc_Stage2_ClosePercent = 15.0;
input int Btc_Stage2_BreakEvenPips = 50;
input int Btc_Stage3_Pips = 300;
input double Btc_Stage3_ClosePercent = 20.0;
input int Btc_TrailingStopPips = 50;
input int Btc_GlobalRiskFreePips = 400;
input int Btc_RiskFreeDistance = 100;
input int Btc_ClosePendingAtProfit = 150;

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

// گروه 4: تنظیمات BITCOIN (BTCUSD, BTC)
input group "TP/SL Adjustment - BITCOIN (MARKET)" input double Btc_BuyMarketTP_AdjustPips = 0.0; // Buy Market TP adjustment (pips)
input double Btc_BuyMarketSL_AdjustPips = 0.0;                                                   // Buy Market SL adjustment (pips)
input double Btc_SellMarketTP_AdjustPips = 0.0;                                                  // Sell Market TP adjustment (pips)
input double Btc_SellMarketSL_AdjustPips = 0.0;                                                  // Sell Market SL adjustment (pips)

input group "TP/SL Adjustment - BITCOIN (PENDING)" input double Btc_BuyPendingTP_AdjustPips = 0.0; // Buy Pending TP adjustment (pips)
input double Btc_BuyPendingSL_AdjustPips = 0.0;                                                    // Buy Pending SL adjustment (pips)
input double Btc_SellPendingTP_AdjustPips = 0.0;                                                   // Sell Pending TP adjustment (pips)
input double Btc_SellPendingSL_AdjustPips = 0.0;                                                   // Sell Pending SL adjustment (pips)

// گروه 5: تنظیمات FOREX (EURUSD, GBPUSD, etc)
input group "TP/SL Adjustment - FOREX (MARKET)" input double Forex_BuyMarketTP_AdjustPips = 0.0; // Buy Market TP adjustment (pips)
input double Forex_BuyMarketSL_AdjustPips = 0.0;                                                 // Buy Market SL adjustment (pips)
input double Forex_SellMarketTP_AdjustPips = 0.0;                                                // Sell Market TP adjustment (pips)
input double Forex_SellMarketSL_AdjustPips = 0.0;                                                // Sell Market SL adjustment (pips)

input group "TP/SL Adjustment - FOREX (PENDING)" input double Forex_BuyPendingTP_AdjustPips = 0.0; // Buy Pending TP adjustment (pips)
input double Forex_BuyPendingSL_AdjustPips = 0.0;                                                  // Buy Pending SL adjustment (pips)
input double Forex_SellPendingTP_AdjustPips = 0.0;                                                 // Sell Pending TP adjustment (pips)
input double Forex_SellPendingSL_AdjustPips = 0.0;                                                 // Sell Pending SL adjustment (pips)

// ================ RETRY SETTINGS ================

input group "Retry Settings" input int MaxRetryAttempts_Stage1 = 15; // افزایش از ۵ به ۱۵
input int MaxRetryAttempts_Stage2 = 15;                              // افزایش از ۵ به ۱۵
input int MaxRetryAttempts_Stage3 = 15;                              // افزایش از ۵ به ۱۵
input int RetryDelaySeconds = 45;                                    // افزایش از ۱۰ به ۴۵ ثانیه
// ================ STRUCTURES AND ENUMS ================

enum ENUM_SYMBOL_TYPE
{
  SYMBOL_TYPE_GOLD,    // 0: Gold
  SYMBOL_TYPE_DOW,     // 1: Dow Jones
  SYMBOL_TYPE_NASDAQ,  // 2: Nasdaq
  SYMBOL_TYPE_BITCOIN, // 3: Bitcoin
  SYMBOL_TYPE_FOREX,   // 4: Forex pairs
  SYMBOL_TYPE_UNKNOWN  // 5: Unknown
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

// ================ STRUCTURES ================

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
  double best_price;
  datetime last_check;
  bool pending_closed;

  // New fields for retry logic
  bool stage_in_progress[4];    // [0] unused, [1] stage1, [2] stage2, [3] stage3
  datetime stage_start_time[4]; // Start time for each stage attempt
  int stage_attempt_count[4];   // Attempt count for each stage
  int stage_max_attempts[4];    // Maximum attempts for each stage (از اینپوت‌ها پر می‌شود)
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
datetime last_dashboard_update = 0;
SymbolSettings gold_settings, dow_settings, nas_settings, btc_settings, forex_settings;
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
bool ClosePartialPosition(ulong ticket, double percent, string reason);
void MoveToBreakEven(ulong ticket, double entryPrice, int breakEvenPips, bool isBuy, string symbol);
void ApplyTrailingStop(ulong ticket, double currentPrice, int trailingPips, bool isBuy, string symbol);
void ApplyGlobalRiskFree(ulong ticket, double entryPrice, int riskFreePips, int riskFreeDistance, bool isBuy, string symbol);
SymbolSettings GetRiskManagementSettings(ENUM_SYMBOL_TYPE symType);
void InitializeRiskManagementSettings();
void ProcessStageWithRetry(ulong ticket, int riskIndex, int stage, double profitPips, double closePercent,
                           string reason, string symbol, bool isBuy, double currentPrice, double entryPrice,
                           string signalID, ENUM_SYMBOL_TYPE symType);

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
void SendRiskManagementAlert(string symbol, string signalID, int stage, string action, double profitPips, double closedPercent);
void SendSignalAlert(string signalID, string symbol, string message);
void SendStageAttemptAlert(string symbol, string signalID, int stage, int attempt, double profitPips, string status);
void SendStageRetryAlert(string symbol, string signalID, int stage, int attempt, double profitPips);

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
double CalculatePositionRiskMoney(ulong ticket);
double CalculateTotalOpenPositionsRiskMoney();
double CalculateTotalRiskPercentage();
bool CheckGlobalRiskLimit(double signalRiskMoney);
double GetTPAdjustPips(ENUM_SYMBOL_TYPE symType, bool isBuy, bool isMarketOrder, bool isPendingOrder);
double GetSLAdjustPips(ENUM_SYMBOL_TYPE symType, bool isBuy, bool isMarketOrder, bool isPendingOrder);
double AdjustPriceWithPips(double originalPrice, double adjustPips, string symbol,
                           ENUM_SYMBOL_TYPE symType, bool isBuy, bool isTP);
double AdjustTPPrice(double originalTP, string symbol, ENUM_SYMBOL_TYPE symType,
                     string orderType, bool isMarketOrder, bool isPendingOrder);
double AdjustSLPrice(double originalSL, string symbol, ENUM_SYMBOL_TYPE symType,
                     string orderType, bool isMarketOrder, bool isPendingOrder);
void SendSignalEntryReport(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType);

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

  PrintLog("SignalExecutor v1.90 with Enhanced Risk Management initialized.");
  PrintLog("Retry Settings:");
  PrintLog("  Stage 1 Max Attempts: " + IntegerToString(MaxRetryAttempts_Stage1));
  PrintLog("  Stage 2 Max Attempts: " + IntegerToString(MaxRetryAttempts_Stage2));
  PrintLog("  Stage 3 Max Attempts: " + IntegerToString(MaxRetryAttempts_Stage3));
  PrintLog("  Retry Delay: " + IntegerToString(RetryDelaySeconds) + " seconds");

  // ایجاد داشبورد اولیه
  CheckDashboardUpload();

  if (EnableTelegram)
  {
    if (!CheckTelegramSettings())
      PrintLog("Warning: Telegram settings invalid.");
    else
      SendTelegramFarsi("🤖 *SignalExecutor v1.90 Started*\n" +
                        "Symbol: " + DefaultSymbol + "\n" +
                        "Risk Management: ACTIVE with Retry Logic\n" +
                        "Retry Settings:\n" +
                        "  Stage 1: " + IntegerToString(MaxRetryAttempts_Stage1) + " attempts\n" +
                        "  Stage 2: " + IntegerToString(MaxRetryAttempts_Stage2) + " attempts\n" +
                        "  Stage 3: " + IntegerToString(MaxRetryAttempts_Stage3) + " attempts\n" +
                        "  Delay: " + IntegerToString(RetryDelaySeconds) + "s\n" +
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
      if (currentRiskPercent > MaxTotalRiskPercent * 0.8)
      {
        PrintLog("⚠️ WARNING: Total risk approaching limit: " +
                 DoubleToString(currentRiskPercent, 1) + "%");
      }
    }
    lastRiskMonitor = TimeCurrent();
  }
  // آپدیت داشبورد هر 10 ثانیه
  if (TimeCurrent() - last_dashboard_update >= DashboardRefreshRate)
  {
    CreateHtmlDashboard();
    last_dashboard_update = TimeCurrent();

    // آپلود داشبورد به سرور
    CheckDashboardUpload();
  }

  // Check risk management at specified interval
  if (EnableRiskManagement && (TimeCurrent() - last_risk_check >= RiskCheckInterval))
  {
    ManageRiskForOpenPositions();
    last_risk_check = TimeCurrent();
  }
}

// ================ RISK MANAGEMENT FUNCTIONS ================

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

  // Bitcoin settings
  btc_settings.stage1_pips = Btc_Stage1_Pips;
  btc_settings.stage1_close_percent = Btc_Stage1_ClosePercent;
  btc_settings.stage2_pips = Btc_Stage2_Pips;
  btc_settings.stage2_close_percent = Btc_Stage2_ClosePercent;
  btc_settings.stage2_breakeven_pips = Btc_Stage2_BreakEvenPips;
  btc_settings.stage3_pips = Btc_Stage3_Pips;
  btc_settings.stage3_close_percent = Btc_Stage3_ClosePercent;
  btc_settings.trailing_stop_pips = Btc_TrailingStopPips;
  btc_settings.global_riskfree_pips = Btc_GlobalRiskFreePips;
  btc_settings.riskfree_distance = Btc_RiskFreeDistance;
  btc_settings.close_pending_at_profit = Btc_ClosePendingAtProfit;

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

  case SYMBOL_TYPE_BITCOIN:
    settings.max_lot = btc_settings.max_lot;
    settings.default_sl_pips = btc_settings.default_sl_pips;
    settings.default_tp_pips = btc_settings.default_tp_pips;
    settings.max_slippage_pips = btc_settings.max_slippage_pips;
    settings.pending_distance_pips = btc_settings.pending_distance_pips;
    settings.stage1_pips = btc_settings.stage1_pips;
    settings.stage1_close_percent = btc_settings.stage1_close_percent;
    settings.stage2_pips = btc_settings.stage2_pips;
    settings.stage2_close_percent = btc_settings.stage2_close_percent;
    settings.stage2_breakeven_pips = btc_settings.stage2_breakeven_pips;
    settings.stage3_pips = btc_settings.stage3_pips;
    settings.stage3_close_percent = btc_settings.stage3_close_percent;
    settings.trailing_stop_pips = btc_settings.trailing_stop_pips;
    settings.global_riskfree_pips = btc_settings.global_riskfree_pips;
    settings.riskfree_distance = btc_settings.riskfree_distance;
    settings.close_pending_at_profit = btc_settings.close_pending_at_profit;
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

// ================ INITIALIZATION ================

//+------------------------------------------------------------------+
//| Initialize Risk Data for New Position                           |
//+------------------------------------------------------------------+
void InitializeRiskDataForPosition(ulong ticket, string signalID, double entryPrice, double slPrice, double tpPrice)
{
  // Check if already exists
  for (int i = 0; i < risk_data_count; i++)
  {
    if (risk_data_array[i].ticket == ticket)
    {
      risk_data_array[i].entry_price = entryPrice;
      risk_data_array[i].original_sl = slPrice;
      risk_data_array[i].original_tp = tpPrice;
      risk_data_array[i].current_sl = slPrice;
      risk_data_array[i].stage_completed = 0;
      risk_data_array[i].risk_free_active = false;
      risk_data_array[i].best_price = entryPrice;
      risk_data_array[i].last_check = TimeCurrent();
      risk_data_array[i].pending_closed = false;

      // Reset stage progress
      for (int s = 0; s < 4; s++)
      {
        risk_data_array[i].stage_in_progress[s] = false;
        risk_data_array[i].stage_start_time[s] = 0;
        risk_data_array[i].stage_attempt_count[s] = 0;
        // Set max attempts based on stage
        if (s == 1)
          risk_data_array[i].stage_max_attempts[s] = MaxRetryAttempts_Stage1;
        else if (s == 2)
          risk_data_array[i].stage_max_attempts[s] = MaxRetryAttempts_Stage2;
        else if (s == 3)
          risk_data_array[i].stage_max_attempts[s] = MaxRetryAttempts_Stage3;
        else
          risk_data_array[i].stage_max_attempts[s] = 5; // default
      }
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

    // Initialize stage progress arrays
    for (int s = 0; s < 4; s++)
    {
      risk_data_array[risk_data_count].stage_in_progress[s] = false;
      risk_data_array[risk_data_count].stage_start_time[s] = 0;
      risk_data_array[risk_data_count].stage_attempt_count[s] = 0;
      // Set max attempts based on stage
      if (s == 1)
        risk_data_array[risk_data_count].stage_max_attempts[s] = MaxRetryAttempts_Stage1;
      else if (s == 2)
        risk_data_array[risk_data_count].stage_max_attempts[s] = MaxRetryAttempts_Stage2;
      else if (s == 3)
        risk_data_array[risk_data_count].stage_max_attempts[s] = MaxRetryAttempts_Stage3;
      else
        risk_data_array[risk_data_count].stage_max_attempts[s] = 5; // default
    }

    risk_data_count++;
    PrintLog("Risk data initialized for ticket: " + (string)ticket + " Signal: " + signalID);
  }
  else
  {
    PrintLog("Warning: Risk data array is full. Cannot add ticket: " + (string)ticket);
  }
}

//+------------------------------------------------------------------+
//| Calculate Pips Profit - CORRECTED VERSION                        |
//+------------------------------------------------------------------+
double CalculatePipsProfit(double entryPrice, double currentPrice, bool isBuy, string symbol, ENUM_SYMBOL_TYPE symType)
{
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
  else if (symType == SYMBOL_TYPE_BITCOIN)
    pips = pips / 10.0; // For Bitcoin, usually 0.1 = 1 pip
  else
    pips = pips / 10.0; // For forex, 0.00010 = 1 pip

  // Debug log
  PrintLog("Profit Calc: Entry=" + DoubleToString(entryPrice, 2) +
           ", Current=" + DoubleToString(currentPrice, 2) +
           ", isBuy=" + (isBuy ? "true" : "false") +
           ", RawDiff=" + DoubleToString(priceDiff, 2) +
           ", Pips=" + DoubleToString(pips, 1));

  return pips;
}

//+------------------------------------------------------------------+
//| Apply Risk Management to Position (Corrected Version)            |
//+------------------------------------------------------------------+
void ApplyRiskManagement(ulong ticket, string symbol, ENUM_SYMBOL_TYPE symType)
{
  PrintLog("🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄");
  PrintLog("🔄 APPLY RISK MANAGEMENT CALLED - Time: " + TimeToString(TimeCurrent(), TIME_SECONDS));
  PrintLog("🔄 Ticket: " + (string)ticket);
  PrintLog("🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄🔄");

  if (!PositionSelectByTicket(ticket))
    return;

  double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
  double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
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
  double profitPips = CalculatePipsProfit(entryPrice, currentPrice, isBuy, symbol, symType);

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
    InitializeRiskDataForPosition(ticket, signalID, entryPrice,
                                  PositionGetDouble(POSITION_SL),
                                  PositionGetDouble(POSITION_TP));
    return;
  }

  // ================ لاگ دیباگ ================
  PrintLog("=== APPLY RISK MANAGEMENT ===");
  PrintLog("Ticket: " + (string)ticket + " | Signal: " + signalID);
  PrintLog("Profit: " + DoubleToString(profitPips, 1) + " pips | Current Stage: " +
           IntegerToString(risk_data_array[riskIndex].stage_completed));
  PrintLog("Targets: S1=" + IntegerToString(riskSettings.stage1_pips) +
           " | S2=" + IntegerToString(riskSettings.stage2_pips) +
           " | S3=" + IntegerToString(riskSettings.stage3_pips) + " pips");
  // ================ پایان لاگ ================

  // Reset stage progress if we're in loss
  if (profitPips <= 0)
  {
    int completedStage = risk_data_array[riskIndex].stage_completed;

    for (int s = completedStage + 1; s <= 3; s++)
    {
      if (risk_data_array[riskIndex].stage_in_progress[s])
      {
        risk_data_array[riskIndex].stage_in_progress[s] = false;
        risk_data_array[riskIndex].stage_attempt_count[s] = 0;
        PrintLog("Stage " + IntegerToString(s) + " reset due to loss");
      }
    }

    PrintLog("=== END (Loss) ===");
    PrintLog(" ");
    return;
  }

  // Check global risk-free condition
  if (profitPips >= riskSettings.global_riskfree_pips && !risk_data_array[riskIndex].risk_free_active)
  {
    ApplyGlobalRiskFree(ticket, entryPrice, riskSettings.global_riskfree_pips,
                        riskSettings.riskfree_distance, isBuy, symbol);
    risk_data_array[riskIndex].risk_free_active = true;
    risk_data_array[riskIndex].stage_completed = 3;

    if (EnableTelegram)
      SendRiskManagementAlert(symbol, signalID, 4, "Global Risk-Free Activated", profitPips, 0);

    PrintLog("=== END (Global Risk-Free) ===");
    PrintLog(" ");
    return;
  }

  // Check if we should close pending orders
  if (ClosePendingOnProfit && !risk_data_array[riskIndex].pending_closed &&
      profitPips >= riskSettings.close_pending_at_profit)
  {
    ClosePendingOrdersForSignal(signalID, "Profit target reached: " +
                                              DoubleToString(profitPips, 1) + " pips");
    risk_data_array[riskIndex].pending_closed = true;
  }

  // ================ سیستم اصلاح شده: هر استیج مستقل چک شود ================
  bool anyStageProcessed = false;

  // **اصلاح شده**: Stage 1 فقط زمانی اجرا شود که stage_completed == 0 باشد
  if (profitPips >= riskSettings.stage1_pips && risk_data_array[riskIndex].stage_completed == 0)
  {
    PrintLog("📊 Stage 1 Conditions MET: Profit(" + DoubleToString(profitPips, 1) +
             ") >= " + IntegerToString(riskSettings.stage1_pips) +
             " && StageCompleted(" + IntegerToString(risk_data_array[riskIndex].stage_completed) + ") == 0");

    if (EnableTelegram)
    {
      string msg = "🟢 *Stage 1 Triggered!*\n\n";
      msg += "🏷️ Symbol: " + symbol + "\n";
      msg += "🆔 Signal: `" + signalID + "`\n";
      msg += "📈 Profit: " + DoubleToString(profitPips, 1) + " pips\n";
      msg += "🎯 Target: " + IntegerToString(riskSettings.stage1_pips) + " pips\n";
      msg += "💰 Close %: " + DoubleToString(riskSettings.stage1_close_percent, 1) + "%\n";
      msg += "🔄 Retry Logic: " + IntegerToString(MaxRetryAttempts_Stage1) + " attempts\n";
      msg += "⏱️ Delay: " + IntegerToString(RetryDelaySeconds) + "s\n";
      msg += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);
      SendTelegramFarsi(msg);
    }

    ProcessStageWithRetry(ticket, riskIndex, 1, profitPips, riskSettings.stage1_close_percent,
                          "Stage 1 Profit Taking", symbol, isBuy, currentPrice, entryPrice,
                          signalID, symType);
    anyStageProcessed = true;
  }

  // **اصلاح شده**: Stage 2 فقط زمانی اجرا شود که stage_completed == 1 باشد
  if (profitPips >= riskSettings.stage2_pips && risk_data_array[riskIndex].stage_completed == 1)
  {
    PrintLog("📊 Stage 2 Conditions MET: Profit(" + DoubleToString(profitPips, 1) +
             ") >= " + IntegerToString(riskSettings.stage2_pips) +
             " && StageCompleted(" + IntegerToString(risk_data_array[riskIndex].stage_completed) + ") == 1");

    if (EnableTelegram)
    {
      string msg = "🟡 *Stage 2 Triggered!*\n\n";
      msg += "🏷️ Symbol: " + symbol + "\n";
      msg += "🆔 Signal: `" + signalID + "`\n";
      msg += "📈 Profit: " + DoubleToString(profitPips, 1) + " pips\n";
      msg += "🎯 Target: " + IntegerToString(riskSettings.stage2_pips) + " pips\n";
      msg += "💰 Close %: " + DoubleToString(riskSettings.stage2_close_percent, 1) + "%\n";
      msg += "⚖️ Break-even at: +" + IntegerToString(riskSettings.stage2_breakeven_pips) + " pips\n";
      msg += "🔄 Retry Logic: " + IntegerToString(MaxRetryAttempts_Stage2) + " attempts\n";
      msg += "⏱️ Delay: " + IntegerToString(RetryDelaySeconds) + "s\n";
      msg += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);
      SendTelegramFarsi(msg);
    }

    ProcessStageWithRetry(ticket, riskIndex, 2, profitPips, riskSettings.stage2_close_percent,
                          "Stage 2 Profit Taking", symbol, isBuy, currentPrice, entryPrice,
                          signalID, symType);
    anyStageProcessed = true;
  }

  // **اصلاح شده**: Stage 3 فقط زمانی اجرا شود که stage_completed == 2 باشد
  if (profitPips >= riskSettings.stage3_pips && risk_data_array[riskIndex].stage_completed == 2)
  {
    PrintLog("📊 Stage 3 Conditions MET: Profit(" + DoubleToString(profitPips, 1) +
             ") >= " + IntegerToString(riskSettings.stage3_pips) +
             " && StageCompleted(" + IntegerToString(risk_data_array[riskIndex].stage_completed) + ") == 2");

    if (EnableTelegram)
    {
      string msg = "🔴 *Stage 3 Triggered!*\n\n";
      msg += "🏷️ Symbol: " + symbol + "\n";
      msg += "🆔 Signal: `" + signalID + "`\n";
      msg += "📈 Profit: " + DoubleToString(profitPips, 1) + " pips\n";
      msg += "🎯 Target: " + IntegerToString(riskSettings.stage3_pips) + " pips\n";
      msg += "💰 Close %: " + DoubleToString(riskSettings.stage3_close_percent, 1) + "%\n";
      msg += "🎯 Trailing Stop: " + IntegerToString(riskSettings.trailing_stop_pips) + " pips\n";
      msg += "🔄 Retry Logic: " + IntegerToString(MaxRetryAttempts_Stage3) + " attempts\n";
      msg += "⏱️ Delay: " + IntegerToString(RetryDelaySeconds) + "s\n";
      msg += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);
      SendTelegramFarsi(msg);
    }

    ProcessStageWithRetry(ticket, riskIndex, 3, profitPips, riskSettings.stage3_close_percent,
                          "Stage 3 Profit Taking", symbol, isBuy, currentPrice, entryPrice,
                          signalID, symType);
    anyStageProcessed = true;
  }

  // اگر هیچ استیجی پردازش نشد ولی شرایط سود وجود دارد
  if (!anyStageProcessed && profitPips > 0)
  {
    PrintLog("📊 No stage processed. Current status:");
    PrintLog("   Profit: " + DoubleToString(profitPips, 1) + " pips");
    PrintLog("   Stage Completed: " + IntegerToString(risk_data_array[riskIndex].stage_completed));
    PrintLog("   Stage1 Target: " + IntegerToString(riskSettings.stage1_pips) +
             " | Met: " + (profitPips >= riskSettings.stage1_pips ? "YES" : "NO"));
    PrintLog("   Stage2 Target: " + IntegerToString(riskSettings.stage2_pips) +
             " | Met: " + (profitPips >= riskSettings.stage2_pips ? "YES" : "NO"));
    PrintLog("   Stage3 Target: " + IntegerToString(riskSettings.stage3_pips) +
             " | Met: " + (profitPips >= riskSettings.stage3_pips ? "YES" : "NO"));

    // لاگ اضافی برای دیباگ
    if (risk_data_array[riskIndex].stage_completed == 0)
      PrintLog("   Status: Waiting for Stage 1 target (" + IntegerToString(riskSettings.stage1_pips) + " pips)");
    else if (risk_data_array[riskIndex].stage_completed == 1)
      PrintLog("   Status: Waiting for Stage 2 target (" + IntegerToString(riskSettings.stage2_pips) + " pips)");
    else if (risk_data_array[riskIndex].stage_completed == 2)
      PrintLog("   Status: Waiting for Stage 3 target (" + IntegerToString(riskSettings.stage3_pips) + " pips)");
    else
      PrintLog("   Status: All stages completed");
  }

  // Apply trailing stop if stage 3 is active
  if (risk_data_array[riskIndex].stage_completed >= 3 && !risk_data_array[riskIndex].risk_free_active)
  {
    ApplyTrailingStop(ticket, risk_data_array[riskIndex].best_price,
                      riskSettings.trailing_stop_pips, isBuy, symbol);
  }

  PrintLog("=== END RISK MANAGEMENT CHECK ===");
  PrintLog(" ");
}

//+------------------------------------------------------------------+
//| Process Stage With Retry Logic (Fixed for All Stages)           |
//+------------------------------------------------------------------+
void ProcessStageWithRetry(ulong ticket, int riskIndex, int stage, double profitPips, double closePercent,
                           string reason, string symbol, bool isBuy, double currentPrice, double entryPrice,
                           string signalID, ENUM_SYMBOL_TYPE symType)
{
  // بررسی محدوده آرایه
  if (riskIndex < 0 || riskIndex >= risk_data_count)
    return;

  // **اصلاح شده**: بررسی دقیق‌تر
  if (risk_data_array[riskIndex].stage_completed >= stage)
  {
    PrintLog("⚠️ Stage " + IntegerToString(stage) + " already completed or higher");
    return;
  }

  SymbolSettings riskSettings = GetSymbolSettings(symType);

  // Get max attempts for this stage from input
  int maxAttempts = 5; // default
  if (stage == 1)
    maxAttempts = MaxRetryAttempts_Stage1;
  else if (stage == 2)
    maxAttempts = MaxRetryAttempts_Stage2;
  else if (stage == 3)
    maxAttempts = MaxRetryAttempts_Stage3;

  PrintLog("🚀 Stage " + IntegerToString(stage) + " Process Started" +
           " | Profit: " + DoubleToString(profitPips, 1) + " pips" +
           " | Current Stage: " + IntegerToString(risk_data_array[riskIndex].stage_completed) +
           " | Max Attempts: " + IntegerToString(maxAttempts) +
           " | Retry Delay: " + IntegerToString(RetryDelaySeconds) + "s");

  // اگر در حال تلاش برای این stage نیستیم، شروع کن
  if (!risk_data_array[riskIndex].stage_in_progress[stage])
  {
    risk_data_array[riskIndex].stage_in_progress[stage] = true;
    risk_data_array[riskIndex].stage_start_time[stage] = TimeCurrent();
    risk_data_array[riskIndex].stage_attempt_count[stage] = 0;

    PrintLog("🚀 Starting Stage " + IntegerToString(stage) +
             " at " + DoubleToString(profitPips, 1) + " pips profit" +
             " (Current stage_completed: " + IntegerToString(risk_data_array[riskIndex].stage_completed) + ")");

    if (EnableTelegram)
    {
      SendStageAttemptAlert(symbol, signalID, stage, 1, profitPips, "STARTING", maxAttempts);
    }
  }

  // Check if we should wait between retries
  if (risk_data_array[riskIndex].stage_attempt_count[stage] > 0 &&
      (TimeCurrent() - risk_data_array[riskIndex].stage_start_time[stage]) < RetryDelaySeconds)
  {
    PrintLog("⏳ Waiting for retry delay...");
    return;
  }

  // تلاش برای بستن جزئی
  risk_data_array[riskIndex].stage_attempt_count[stage]++;
  int attemptCount = risk_data_array[riskIndex].stage_attempt_count[stage];

  PrintLog("🔄 Stage " + IntegerToString(stage) + " Attempt #" +
           IntegerToString(attemptCount) + "/" + IntegerToString(maxAttempts) +
           " | Profit: " + DoubleToString(profitPips, 1) + " pips" +
           " | Time: " + TimeToString(TimeCurrent(), TIME_SECONDS));

  // بستن جزئی با حفظ کامنت
  bool success = ClosePartialPositionWithCommentPreservation(ticket, closePercent, reason,
                                                             "Stage " + IntegerToString(stage) +
                                                                 " (Attempt " + IntegerToString(attemptCount) +
                                                                 "/" + IntegerToString(maxAttempts) + ")",
                                                             signalID);

  if (success)
  {
    // موفق شدیم
    risk_data_array[riskIndex].stage_completed = stage; // **مهم: این خط مرحله را افزایش می‌دهد**
    risk_data_array[riskIndex].stage_in_progress[stage] = false;
    risk_data_array[riskIndex].stage_attempt_count[stage] = 0;

    PrintLog("🎉 STAGE " + IntegerToString(stage) + " COMPLETED SUCCESSFULLY!");
    PrintLog("   Old stage_completed: " + IntegerToString(stage - 1));
    PrintLog("   New stage_completed: " + IntegerToString(risk_data_array[riskIndex].stage_completed));

    // گزارش موفقیت به تلگرام
    if (EnableTelegram)
    {
      string emoji = "";
      string stageName = "";

      if (stage == 1)
      {
        emoji = "🟢";
        stageName = "Stage 1";
      }
      else if (stage == 2)
      {
        emoji = "🟡";
        stageName = "Stage 2";
      }
      else if (stage == 3)
      {
        emoji = "🔴";
        stageName = "Stage 3";
      }

      string successMsg = emoji + " *" + stageName + " Completed!*\n\n";
      successMsg += "🏷️ Symbol: " + symbol + "\n";
      successMsg += "🆔 Signal: `" + signalID + "`\n";
      successMsg += "📈 Profit: " + DoubleToString(profitPips, 1) + " pips\n";
      successMsg += "💰 Closed: " + DoubleToString(closePercent, 1) + "% of position\n";
      successMsg += "🔄 Attempt: " + IntegerToString(attemptCount) + "\n";

      if (stage == 2)
        successMsg += "⚖️ Stop Loss moved to break-even (+" +
                      IntegerToString(riskSettings.stage2_breakeven_pips) + " pips)\n";
      else if (stage == 3)
        successMsg += "🎯 Trailing stop activated (" +
                      IntegerToString(riskSettings.trailing_stop_pips) + " pips)\n";

      successMsg += "✅ Action: " + reason + "\n";
      successMsg += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);

      SendTelegramFarsi(successMsg);
    }

    // اعمال تغییرات مربوطه
    if (stage == 2)
    {
      MoveToBreakEven(ticket, entryPrice, riskSettings.stage2_breakeven_pips, isBuy, symbol);
    }
    else if (stage == 3)
    {
      ApplyTrailingStop(ticket, currentPrice, riskSettings.trailing_stop_pips, isBuy, symbol);
    }

    PrintLog("✅ Stage " + IntegerToString(stage) + " completed successfully after " +
             IntegerToString(attemptCount) + " attempts");
  }
  else
  {
    // موفق نشدیم - زمان شروع را برای تأخیر بعدی به روز کن
    risk_data_array[riskIndex].stage_start_time[stage] = TimeCurrent();

    PrintLog("⚠️ Stage " + IntegerToString(stage) + " attempt #" +
             IntegerToString(attemptCount) + "/" + IntegerToString(maxAttempts) +
             " failed. Profit: " + DoubleToString(profitPips, 1) + " pips");

    // اگر به حداکثر تلاش رسیدیم، صرف نظر کن
    if (attemptCount >= maxAttempts)
    {
      PrintLog("❌ MAX ATTEMPTS REACHED for Stage " + IntegerToString(stage) +
               " after " + IntegerToString(maxAttempts) + " failed attempts" +
               " | Profit: " + DoubleToString(profitPips, 1) + " pips");

      // ================ هشدار تلگرام ================
      if (EnableTelegram)
      {
        string maxAttemptMsg = "🛑 *Max Retry Attempts Reached!*\n\n";
        maxAttemptMsg += "🏷️ Symbol: " + symbol + "\n";
        maxAttemptMsg += "🆔 Signal: `" + signalID + "`\n";
        maxAttemptMsg += "🔰 Stage: " + IntegerToString(stage) + "\n";
        maxAttemptMsg += "📈 Profit: " + DoubleToString(profitPips, 1) + " pips\n";
        maxAttemptMsg += "🔄 Attempts: " + IntegerToString(maxAttempts) + "/" + IntegerToString(maxAttempts) + "\n";
        maxAttemptMsg += "⏱️ Delay: " + IntegerToString(RetryDelaySeconds) + "s\n";
        maxAttemptMsg += "⚠️ Stage will be skipped - moving to next stage\n";
        maxAttemptMsg += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);

        SendTelegramFarsi(maxAttemptMsg);
      }
      // ================ پایان هشدار ================

      risk_data_array[riskIndex].stage_in_progress[stage] = false;
      risk_data_array[riskIndex].stage_attempt_count[stage] = 0;

      // **اصلاح شده**: اگر به حداکثر تلاش رسید، مرحله را رد کن
      risk_data_array[riskIndex].stage_completed = stage;

      return;
    }
  }
}

//+------------------------------------------------------------------+
//| Close Partial Position with Comment Preservation                |
//+------------------------------------------------------------------+
bool ClosePartialPositionWithCommentPreservation(ulong ticket, double percent, string stageReason,
                                                 string attemptDetails, string signalID)
{
  if (!PositionSelectByTicket(ticket))
    return false;

  // ذخیره تمام اطلاعات پوزیشن قبل از بستن
  string symbol = PositionGetString(POSITION_SYMBOL);
  double volume = PositionGetDouble(POSITION_VOLUME);
  double sl = PositionGetDouble(POSITION_SL);
  double tp = PositionGetDouble(POSITION_TP);

  double closeVolume = volume * percent / 100.0;
  closeVolume = NormalizeLotToSymbol(closeVolume, symbol);

  if (closeVolume <= 0)
    return false;

  double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
  if (closeVolume < minLot)
  {
    PrintLog("Cannot close partial: " + DoubleToString(closeVolume, 2) +
             " < min lot " + DoubleToString(minLot, 2));
    return false;
  }

  // ساخت کامنت جدید که Signal ID را حفظ می‌کند
  string newComment = "SID:" + signalID;

  // اضافه کردن اطلاعات استیج به تاریخچه
  if (StringFind(stageReason, "Stage 1") >= 0)
    newComment += " [S1-" + IntegerToString((int)(percent)) + "%]";
  else if (StringFind(stageReason, "Stage 2") >= 0)
    newComment += " [S2-" + IntegerToString((int)(percent)) + "%]";
  else if (StringFind(stageReason, "Stage 3") >= 0)
    newComment += " [S3-" + IntegerToString((int)(percent)) + "%]";

  // بستن جزئی
  bool success = trade.PositionClosePartial(ticket, closeVolume);

  if (success)
  {
    PrintLog("✅ Partial close successful: " + DoubleToString(closeVolume, 2) +
             " lots (" + DoubleToString(percent, 1) + "%) - " + stageReason);

    Sleep(100); // تاخیر برای پردازش تراکنش

    // اگر پوزیشن هنوز وجود دارد، کامنت را به‌روزرسانی کن
    if (PositionSelectByTicket(ticket))
    {
      MqlTradeRequest request;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(result);

      request.action = TRADE_ACTION_SLTP;
      request.position = ticket;
      request.symbol = symbol;
      request.sl = sl;
      request.tp = tp;
      request.comment = newComment;
      request.magic = ExpertMagicNumber;

      ResetLastError();
      if (OrderSend(request, result))
      {
        PrintLog("✅ Comment updated: " + newComment);
      }
      else
      {
        PrintLog("⚠️ Could not update comment: " + (string)result.retcode + " - " + result.comment);

        // تلاش مجدد
        Sleep(100);
        ResetLastError();
        if (OrderSend(request, result))
        {
          PrintLog("✅ Comment updated on second attempt");
        }
      }
    }
  }
  else
  {
    PrintLog("❌ Partial close FAILED: " + IntegerToString(trade.ResultRetcode()) +
             " - " + trade.ResultComment());
  }

  return success;
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

  btc_settings.max_lot = MaxLotSize_BTC;
  btc_settings.default_sl_pips = DefaultStopPips_BTC;
  btc_settings.default_tp_pips = DefaultTpForOpenPips_BTC;
  btc_settings.max_slippage_pips = MaxSlippageForMarketPips_BTC;
  btc_settings.pending_distance_pips = PendingOrderDistanceFromSL_BTC;

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
      StringFind(symLower, "dj") >= 0 || StringFind(symLower, "yinusd") >= 0 ||
      StringFind(symLower, "ym") >= 0)
    return SYMBOL_TYPE_DOW;

  if (StringFind(symLower, "nas100") >= 0 || StringFind(symLower, "nas") >= 0 ||
      StringFind(symLower, "nq") >= 0 || StringFind(symLower, "ustec") >= 0)
    return SYMBOL_TYPE_NASDAQ;

  if (StringFind(symLower, "btc") >= 0 || StringFind(symLower, "bitcoin") >= 0 ||
      StringFind(symLower, "BTCUSD") >= 0 || StringFind(symLower, "XBTUSD") >= 0 ||
      StringFind(symLower, "BCHUSD") >= 0)
    return SYMBOL_TYPE_BITCOIN;

  return SYMBOL_TYPE_FOREX;
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
  case SYMBOL_TYPE_BITCOIN:
    return "BITCOIN";
  case SYMBOL_TYPE_FOREX:
    return "FOREX";
  default:
    return "UNKNOWN";
  }
}

// ================ TELEGRAM FUNCTIONS ================

//+------------------------------------------------------------------+
//| Send Stage Attempt Alert (Enhanced)                             |
//+------------------------------------------------------------------+
void SendStageAttemptAlert(string symbol, string signalID, int stage, int attempt,
                           double profitPips, string status, int maxAttempts)
{
  if (!EnableTelegram)
    return;

  string emoji = "";
  string stageName = "";

  if (stage == 1)
  {
    emoji = "🟢";
    stageName = "Stage 1";
  }
  else if (stage == 2)
  {
    emoji = "🟡";
    stageName = "Stage 2";
  }
  else if (stage == 3)
  {
    emoji = "🔴";
    stageName = "Stage 3";
  }
  else
  {
    emoji = "⚪";
    stageName = "Stage " + IntegerToString(stage);
  }

  string message = emoji + " *" + stageName + " - " + status + "*\n\n";
  message += "🏷️ Symbol: " + symbol + "\n";
  message += "🆔 Signal ID: `" + signalID + "`\n";
  message += "📈 Profit: " + DoubleToString(profitPips, 1) + " pips\n";
  message += "🔰 Stage: " + IntegerToString(stage) + "\n";
  message += "🔄 Attempt: " + IntegerToString(attempt) + "/" + IntegerToString(maxAttempts) + "\n";
  message += "⏱️ Delay: " + IntegerToString(RetryDelaySeconds) + "s\n";

  if (status == "STARTING")
    message += "🚀 Starting stage execution\n";
  else if (status == "ATTEMPTING")
    message += "🔄 Attempting partial close\n";
  else if (status == "FAILED")
    message += "❌ Close attempt failed\n";

  message += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);

  SendTelegramFarsi(message);
}

//+------------------------------------------------------------------+
//| Send Stage Retry Alert                                          |
//+------------------------------------------------------------------+
void SendStageRetryAlert(string symbol, string signalID, int stage, int maxAttempts, double profitPips)
{
  if (!EnableTelegram)
    return;

  string message = "⚠️ *Stage Retry Limit Reached*\n\n";
  message += "🏷️ Symbol: " + symbol + "\n";
  message += "🆔 Signal ID: `" + signalID + "`\n";
  message += "📈 Profit: " + DoubleToString(profitPips, 1) + " pips\n";
  message += "🔰 Stage: " + IntegerToString(stage) + "\n";
  message += "🔄 Max Attempts: " + IntegerToString(maxAttempts) + "\n";
  message += "⏱️ Delay: " + IntegerToString(RetryDelaySeconds) + "s\n";
  message += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);
  message += "\n\nℹ️ Stage will be reset. Will retry if profit target is reached again.";

  SendTelegramFarsi(message);
}

//+------------------------------------------------------------------+
//| Send Risk Management Alert                                       |
//+------------------------------------------------------------------+
void SendRiskManagementAlert(string symbol, string signalID, int stage, string action, double profitPips, double closedPercent)
{
  if (!EnableTelegram)
    return;

  string stageNames[] = {"", "Stage 1", "Stage 2", "Stage 3", "Global Risk-Free"};
  string emojis[] = {"", "🟢", "🟡", "🔴", "🛡️"};

  string message = emojis[stage] + " *" + stageNames[stage] + " Completed!*\n\n";
  message += "🏷️ Symbol: " + symbol + "\n";
  message += "🆔 Signal ID: `" + signalID + "`\n";
  message += "📈 Profit: " + DoubleToString(profitPips, 1) + " pips\n";

  if (stage >= 1 && stage <= 3)
    message += "💰 Closed: " + DoubleToString(closedPercent, 1) + "% of position\n";

  message += "✅ Action: " + action + "\n";

  if (stage == 2)
    message += "⚖️ Stop Loss moved to break-even\n";
  else if (stage == 3)
    message += "🎯 Trailing stop activated\n";
  else if (stage == 4)
    message += "🛡️ Global risk-free activated\n";

  message += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_SECONDS);

  SendTelegramFarsi(message);
}

//+------------------------------------------------------------------+
//| Send Telegram Farsi Message                                      |
//+------------------------------------------------------------------+
bool SendTelegramFarsi(string message)
{
  if (!EnableTelegram || !CheckTelegramSettings())
    return false;

  string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";

  // فرار کردن کاراکترهای خاص برای JSON
  string cleanMsg = message;
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
    PrintLog("Telegram Error: " + IntegerToString(code));
    return false;
  }
  return true;
}

// ================ OTHER NECESSARY FUNCTIONS ================

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
  if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN)
    breakEvenPoints = breakEvenPips * point * 10.0;
  else if (symType == SYMBOL_TYPE_FOREX)
    breakEvenPoints = breakEvenPips * point * 10.0;

  double newSL = 0;
  if (isBuy)
  {
    newSL = entryPrice + breakEvenPoints;
  }
  else
  {
    newSL = entryPrice - breakEvenPoints;
  }

  trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
  PrintLog("Break-even SL set: " + DoubleToString(newSL, 5) +
           " (" + IntegerToString(breakEvenPips) + " pips from entry)");
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

  double trailingPoints = trailingPips * point;
  if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN)
    trailingPoints = trailingPips * point * 10.0;
  else if (symType == SYMBOL_TYPE_FOREX)
    trailingPoints = trailingPips * point * 10.0;

  double newSL = currentSL;

  if (isBuy)
  {
    double proposedSL = currentPrice - trailingPoints;
    if (proposedSL > currentSL && proposedSL > PositionGetDouble(POSITION_PRICE_OPEN))
    {
      newSL = proposedSL;
    }
  }
  else
  {
    double proposedSL = currentPrice + trailingPoints;
    if (proposedSL < currentSL && proposedSL < PositionGetDouble(POSITION_PRICE_OPEN))
    {
      newSL = proposedSL;
    }
  }

  if (newSL != currentSL)
  {
    trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));
    PrintLog("Trailing stop updated: " + DoubleToString(newSL, 5));
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
      if (PositionSelectByTicket(ticket))
      {
        long position_type = PositionGetInteger(POSITION_TYPE);

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
//| Send Pending Order                                              |
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

    if (OrderSelect(result.order))
    {
      PrintLog("  Order Details:");
      PrintLog("    Open Time: " + TimeToString(OrderGetInteger(ORDER_TIME_SETUP)));
      PrintLog("    State: " + EnumToString((ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE)));
    }

    return true;
  }
  else
  {
    PrintLog("❌ ORDER FAILED!");
    PrintLog("  Retcode: " + IntegerToString(result.retcode));
    PrintLog("  Error: " + result.comment);

    string errorDescription = GetTradeErrorDescription(result.retcode);
    if (errorDescription != "")
      PrintLog("  Description: " + errorDescription);

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
}

// ================ JSON PROCESSING FUNCTIONS ================

//+------------------------------------------------------------------+
//| Parse JSON Content                                              |
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

  // Parse prices array
  int priceStart = StringFind(content, "\"prices\":[");
  if (priceStart >= 0)
  {
    priceStart += 10;
    int priceEnd = StringFind(content, "]", priceStart);
    if (priceEnd > priceStart)
    {
      string pricesStr = StringSubstr(content, priceStart, priceEnd - priceStart);
      PrintLog("Prices string: " + pricesStr);

      int pos = 0;
      int priceCount = 0;

      while (true)
      {
        int numStart = StringFind(pricesStr, "\"", pos);
        if (numStart < 0)
          break;

        int numEnd = StringFind(pricesStr, "\"", numStart + 1);
        if (numEnd < 0)
          break;

        string numStr = StringSubstr(pricesStr, numStart + 1, numEnd - numStart - 1);

        if (StringLen(numStr) > 0 && numStr != "price")
        {
          double price = StringToDouble(numStr);

          if (price > 0)
          {
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

  // Parse TP array
  int tpStart = StringFind(content, "\"tp\":[");
  if (tpStart >= 0)
  {
    tpStart += 6;
    int tpEnd = StringFind(content, "]", tpStart);
    if (tpEnd > tpStart)
    {
      string tpStr = StringSubstr(content, tpStart, tpEnd - tpStart);
      PrintLog("TP string: " + tpStr);

      int pos = 0;
      int tpCount = 0;

      while (true)
      {
        int itemStart = StringFind(tpStr, "\"tp_item\":\"", pos);
        if (itemStart < 0)
          break;

        itemStart += 11;
        int itemEnd = StringFind(tpStr, "\"", itemStart);
        if (itemEnd < 0)
          break;

        string itemStr = StringSubstr(tpStr, itemStart, itemEnd - itemStart);

        if (StringCompare(itemStr, "OPEN", true) == 0)
        {
          ArrayResize(out.tp_list, tpCount + 1);
          out.tp_list[tpCount] = 0;
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

      if (out.tp_count == 3)
      {
        PrintLog("Adding OPEN as 4th TP");
        ArrayResize(out.tp_list, 4);
        out.tp_list[3] = 0;
        out.tp_count = 4;
      }
    }
  }

  // Parse SL array
  int slStart = StringFind(content, "\"sl\":[");
  if (slStart >= 0)
  {
    slStart += 6;
    int slEnd = StringFind(content, "]", slStart);
    if (slEnd > slStart)
    {
      string slStr = StringSubstr(content, slStart, slEnd - slStart);
      PrintLog("SL string: " + slStr);

      int itemStart = StringFind(slStr, "\"sl_item\":\"");
      if (itemStart >= 0)
      {
        itemStart += 11;
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
//| Extract Value from JSON string                                  |
//+------------------------------------------------------------------+
string ExtractJsonValue(string json, string key)
{
  string search = "\"" + key + "\":\"";
  int pos = StringFind(json, search);
  if (pos < 0)
  {
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

  if (sl <= 0)
    return 0;

  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
  double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
  if (tickSize <= 0)
    tickSize = point;

  ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

  double slDistance = 0;
  if (type == POSITION_TYPE_BUY)
    slDistance = (openPrice - sl) / tickSize;
  else
    slDistance = (sl - openPrice) / tickSize;

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
    return true;

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

// ================ TP/SL ADJUSTMENT FUNCTIONS ================

//+------------------------------------------------------------------+
//| Get TP Adjustment Pips                                          |
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
      case SYMBOL_TYPE_BITCOIN:
        return Btc_BuyMarketTP_AdjustPips;
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
      case SYMBOL_TYPE_BITCOIN:
        return Btc_SellMarketTP_AdjustPips;
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
      case SYMBOL_TYPE_BITCOIN:
        return Btc_BuyPendingTP_AdjustPips;
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
      case SYMBOL_TYPE_BITCOIN:
        return Btc_SellPendingTP_AdjustPips;
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
//| Get SL Adjustment Pips                                          |
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
      case SYMBOL_TYPE_BITCOIN:
        return Btc_BuyMarketSL_AdjustPips;
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
      case SYMBOL_TYPE_BITCOIN:
        return Btc_SellMarketSL_AdjustPips;
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
      case SYMBOL_TYPE_BITCOIN:
        return Btc_BuyPendingSL_AdjustPips;
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
      case SYMBOL_TYPE_BITCOIN:
        return Btc_SellPendingSL_AdjustPips;
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

  if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN)
    multiplier = 10.0;
  else if (symType == SYMBOL_TYPE_FOREX)
    multiplier = 10.0;

  double adjustmentPoints = adjustPips * point * multiplier;

  if (isBuy)
  {
    if (isTP)
      return originalPrice + adjustmentPoints;
    else
      return originalPrice - adjustmentPoints;
  }
  else // Sell
  {
    if (isTP)
      return originalPrice - adjustmentPoints;
    else
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

// ================ SIGNAL PROCESSING FUNCTIONS ================

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

  PrintLog("Parsed Data Summary:");
  PrintLog("  Prices count: " + IntegerToString(sig.prices_count));
  PrintLog("  TP count: " + IntegerToString(sig.tp_count));
  PrintLog("  SL count: " + IntegerToString(sig.sl_count));
  if (sig.prices_count == 0)
  {
    PrintLog("ERROR: No prices parsed from JSON!");
    return;
  }

  if (sig.tp_count == 0)
  {
    PrintLog("WARNING: No TPs found, adding default TP");
    sig.tp_count = 1;
    ArrayResize(sig.tp_list, 1);
    sig.tp_list[0] = 0;
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
    long currentTime = (long)TimeCurrent();
    sig.signal_id = IntegerToString(currentTime);
  }

  PrintLog("Processing Signal ID: " + sig.signal_id + " on " + symbol);

  ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);

  // ارسال گزارش سیگنال ورودی به تلگرام
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
      return;
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

  // Process signal with smart logic (نیاز به تعریف این تابع دارید)
  ProcessSignalWithSmartLogic(sig, symbol, symType, settings, totalRiskMoney, sig.signal_id, successCount, totalExecutedVolume);

  if (EnableTelegram && successCount > 0)
  {
    SendExecutionReport(sig.signal_id, symbol, sig.order_type, sig.tp_count, successCount,
                        totalExecutedVolume, false, false, 0, symType);
  }
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

  if (sig.prices_count > 0)
  {
    report += "💰 *Entry Prices:*\n";
    for (int i = 0; i < MathMin(sig.prices_count, 5); i++)
    {
      report += "  " + IntegerToString(i + 1) + ". " + DoubleToString(sig.prices_list[i], 5) + "\n";
    }
    if (sig.prices_count > 5)
      report += "  ... + " + IntegerToString(sig.prices_count - 5) + " more\n";
  }

  if (sig.tp_count > 0)
  {
    report += "\n🎯 *Take Profit Levels:*\n";
    for (int i = 0; i < MathMin(sig.tp_count, 4); i++)
    {
      if (sig.tp_list[i] == 0)
        report += "  TP" + IntegerToString(i + 1) + ": OPEN\n";
      else
        report += "  TP" + IntegerToString(i + 1) + ": " + DoubleToString(sig.tp_list[i], 5) + "\n";
    }
    if (sig.tp_count > 4)
      report += "  ... + " + IntegerToString(sig.tp_count - 4) + " more\n";
  }

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
//| Apply Global Risk-Free                                           |
//+------------------------------------------------------------------+
void ApplyGlobalRiskFree(ulong ticket, double entryPrice, int riskFreePips, int riskFreeDistance, bool isBuy, string symbol)
{
  if (!PositionSelectByTicket(ticket))
    return;

  double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
  double profit = PositionGetDouble(POSITION_PROFIT);

  if (profit <= 0)
    return;

  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);

  double riskFreePoints = riskFreeDistance * point;
  if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN)
    riskFreePoints = riskFreeDistance * point * 10.0;
  else if (symType == SYMBOL_TYPE_FOREX)
    riskFreePoints = riskFreeDistance * point * 10.0;

  double newSL = 0;
  if (isBuy)
  {
    newSL = entryPrice + riskFreePoints;
  }
  else
  {
    newSL = entryPrice - riskFreePoints;
  }

  trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP));

  PrintLog("Global Risk-Free Activated: SL = " + DoubleToString(newSL, 5) +
           " (Profit: " + DoubleToString(profit, 2) + ")");
}

//+------------------------------------------------------------------+
//| Check Telegram Settings                                          |
//+------------------------------------------------------------------+
bool CheckTelegramSettings()
{
  return (StringLen(TelegramBotToken) > 20 && StringLen(TelegramChatID) > 5);
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
//| Calculate Default SL                                             |
//+------------------------------------------------------------------+
double CalculateDefaultSL(string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings, double currentPrice, bool isBuy)
{
  double point = 0;
  if (!SymbolInfoDouble(symbol, SYMBOL_POINT, point))
  {
    PrintLog("ERROR: Cannot get point value for " + symbol);
    return 0;
  }

  double pips = settings.default_sl_pips;

  if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN)
    pips = pips * 10.0;
  else if (symType == SYMBOL_TYPE_FOREX)
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
//| Get First TP                                                     |
//+------------------------------------------------------------------+
double GetFirstTP(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType,
                  SymbolSettings &settings, double referencePrice, bool isBuy,
                  string orderType = "", bool isMarketOrder = false, bool isPendingOrder = false)
{
  double firstTP = (sig.tp_count > 0) ? sig.tp_list[0] : 0;

  if (firstTP > 0)
  {
    if (orderType != "" && (isMarketOrder || isPendingOrder))
    {
      firstTP = AdjustTPPrice(firstTP, symbol, symType, orderType, isMarketOrder, isPendingOrder);
    }
    return firstTP;
  }

  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  double pips = settings.default_tp_pips;

  if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN)
    pips = pips * 10.0;
  else if (symType == SYMBOL_TYPE_FOREX)
    pips = pips / 10.0;

  double dist = pips * point;
  firstTP = isBuy ? referencePrice + dist : referencePrice - dist;

  if (orderType != "" && (isMarketOrder || isPendingOrder))
  {
    firstTP = AdjustTPPrice(firstTP, symbol, symType, orderType, isMarketOrder, isPendingOrder);
  }

  return firstTP;
}

//+------------------------------------------------------------------+
//| Calculate Pending Price                                          |
//+------------------------------------------------------------------+
double CalculatePendingPrice(string orderType, double slPrice, double currentPrice, string symbol, int distancePips, ENUM_SYMBOL_TYPE symType, bool isBuy)
{
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
  case SYMBOL_TYPE_BITCOIN:
    multiplier = 10.0;
    break;
  case SYMBOL_TYPE_FOREX:
    multiplier = 10.0;
    break;
  default:
    multiplier = 1.0;
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

        if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN)
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
    if (EnableRiskManagement)
      InitializeRiskDataForPosition(trade.ResultOrder(), signalID, entryPrice, sl_price, tp_val);

    successCount++;
    totalVolume += lot;
  }
}

// ================ PROCESS SIGNAL WITH SMART LOGIC ================

//+------------------------------------------------------------------+
//| Process Signal with Smart Logic                                 |
//+------------------------------------------------------------------+
void ProcessSignalWithSmartLogic(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings,
                                 double totalRiskMoney, string signalID, int &successCount, double &totalVolume)
{
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

  string orderTypeLower = StringToLowerCustom(sig.order_type);

  bool isBuyOrder = (StringFind(orderTypeLower, "buy") >= 0);
  bool isSellOrder = (StringFind(orderTypeLower, "sell") >= 0);
  bool isMarketOrder = false;
  bool isLimitOrder = false;
  bool isStopOrder = false;

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
      isMarketOrder = true;
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

  double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
  double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
  double currentMarketPrice = isBuyOrder ? ask : bid;
  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

  PrintLog("Market Data:");
  PrintLog("  Bid: " + DoubleToString(bid, 2));
  PrintLog("  Ask: " + DoubleToString(ask, 2));
  PrintLog("  Using: " + DoubleToString(currentMarketPrice, 2));
  PrintLog("  Point: " + DoubleToString(point, 5));

  double sl_price = 0;

  if (sig.sl_count > 0 && sig.sl_list[0] > 0)
  {
    sl_price = sig.sl_list[0];
    PrintLog("SL from signal: " + DoubleToString(sl_price, 2));
  }
  else
  {
    double pips = settings.default_sl_pips;

    if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN)
      pips = pips * 10.0;
    else if (symType == SYMBOL_TYPE_FOREX)
      pips = pips / 10.0;

    double dist = pips * point;
    sl_price = isBuy ? currentMarketPrice - dist : currentMarketPrice + dist;
    PrintLog("Default SL calculated: " + DoubleToString(sl_price, 2) +
             " (" + DoubleToString(pips, 1) + " pips from price)");
  }

  double distSL = MathAbs(currentMarketPrice - sl_price);
  double totalLot = CalculatePositionSize(symbol, totalRiskMoney, distSL);
  totalLot = NormalizeLotToSymbol(totalLot, symbol);

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

  int firstMarketIndex = -1;
  int marketEntries = 0;
  int pendingEntries = 0;

  if (isMarketOrder)
  {
    PrintLog("Checking prices for market execution...");

    for (int i = 0; i < sig.prices_count; i++)
    {
      double entryPrice = sig.prices_list[i];
      if (entryPrice <= 0)
        continue;

      double gapPoints = MathAbs(entryPrice - currentMarketPrice) / point;

      double gapPips = gapPoints;
      if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN)
        gapPips = gapPoints / 10.0;
      else if (symType == SYMBOL_TYPE_FOREX)
        gapPips = gapPoints / 10.0;

      PrintLog("Price[" + IntegerToString(i) + "]: " + DoubleToString(entryPrice, 2) +
               " - Gap: " + DoubleToString(gapPips, 1) + " pips" +
               " (Max: " + IntegerToString(settings.max_slippage_pips) + " pips)");

      if (gapPips <= settings.max_slippage_pips)
      {
        if (firstMarketIndex == -1)
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
    pendingEntries = sig.prices_count;
    PrintLog("Limit/Stop order detected - all " + IntegerToString(pendingEntries) + " entries will be pending");
  }

  int totalExpectedPositions = 0;
  string executionMode = "";

  if (isMarketOrder && firstMarketIndex >= 0)
  {
    int marketPositions = sig.tp_count;
    int pendingPositions = (sig.prices_count - 1) * sig.tp_count;

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

  if (!validSplitVolume)
  {
    PrintLog("⚠️ ENTERING SPECIAL EXECUTION MODE");
    PrintLog("Reason: Lot per position (" + DoubleToString(lotPerPosition, 3) +
             ") < minimum (" + DoubleToString(minLot, 3) + ")");

    double pendingPrice = 0;

    if (sig.prices_count > 0 && sig.prices_list[0] > 0)
    {
      pendingPrice = sig.prices_list[0];
      PrintLog("Using first signal price: " + DoubleToString(pendingPrice, 2));
    }
    else
    {
      double pips = settings.pending_distance_pips;
      double multiplier = 1.0;

      if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN)
        multiplier = 10.0;
      else if (symType == SYMBOL_TYPE_FOREX)
        multiplier = 10.0;

      double distance = pips * point * multiplier;
      pendingPrice = isBuy ? sl_price + distance : sl_price - distance;
      PrintLog("Calculated pending price: " + DoubleToString(pendingPrice, 2) +
               " (" + IntegerToString(pips) + " pips from SL)");
    }

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

  PrintLog("✅ PROCEEDING WITH NORMAL EXECUTION");

  int marketOrdersCreated = 0;
  int pendingOrdersCreated = 0;
  int skippedOrders = 0;

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

    bool isThisMarketOrder = (isMarketOrder && priceIndex == firstMarketIndex);

    for (int tpIndex = 0; tpIndex < sig.tp_count; tpIndex++)
    {
      double tp_val = sig.tp_list[tpIndex];

      if (tp_val <= 0)
      {
        tp_val = GetFirstTP(sig, symbol, symType, settings, currentMarketPrice, isBuy,
                            sig.order_type, isThisMarketOrder, !isThisMarketOrder);
      }

      string tpStr = (tp_val == 0) ? "OPEN" : DoubleToString(tp_val, 2);

      if (isThisMarketOrder)
      {
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
//+------------------------------------------------------------------+
//| Get Symbol Settings                                             |
//+------------------------------------------------------------------+
SymbolSettings GetSymbolSettings(ENUM_SYMBOL_TYPE symType)
{
  SymbolSettings settings;

  // Initialize all fields to avoid warnings
  settings.max_lot = 0;
  settings.default_sl_pips = 0;
  settings.default_tp_pips = 0;
  settings.max_slippage_pips = 0;
  settings.pending_distance_pips = 0;
  settings.stage1_pips = 0;
  settings.stage1_close_percent = 0;
  settings.stage2_pips = 0;
  settings.stage2_close_percent = 0;
  settings.stage2_breakeven_pips = 0;
  settings.stage3_pips = 0;
  settings.stage3_close_percent = 0;
  settings.trailing_stop_pips = 0;
  settings.global_riskfree_pips = 0;
  settings.riskfree_distance = 0;
  settings.close_pending_at_profit = 0;

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

  case SYMBOL_TYPE_BITCOIN:
    settings.max_lot = btc_settings.max_lot;
    settings.default_sl_pips = btc_settings.default_sl_pips;
    settings.default_tp_pips = btc_settings.default_tp_pips;
    settings.max_slippage_pips = btc_settings.max_slippage_pips;
    settings.pending_distance_pips = btc_settings.pending_distance_pips;
    settings.stage1_pips = btc_settings.stage1_pips;
    settings.stage1_close_percent = btc_settings.stage1_close_percent;
    settings.stage2_pips = btc_settings.stage2_pips;
    settings.stage2_close_percent = btc_settings.stage2_close_percent;
    settings.stage2_breakeven_pips = btc_settings.stage2_breakeven_pips;
    settings.stage3_pips = btc_settings.stage3_pips;
    settings.stage3_close_percent = btc_settings.stage3_close_percent;
    settings.trailing_stop_pips = btc_settings.trailing_stop_pips;
    settings.global_riskfree_pips = btc_settings.global_riskfree_pips;
    settings.riskfree_distance = btc_settings.riskfree_distance;
    settings.close_pending_at_profit = btc_settings.close_pending_at_profit;
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

// ================ تابع ایجاد داشبورد HTML ================
void CreateHtmlDashboard()
{
  PrintLog("🔄 Updating HTML Dashboard...");

  string html = "";

  // شروع HTML
  html += "<!DOCTYPE html>";
  html += "<html lang='en' dir='ltr'>";
  html += "<head>";
  html += "<meta charset='UTF-8'>";
  html += "<meta name='viewport' content='width=device-width, initial-scale=1.0'>";
  html += "<meta http-equiv='refresh' content='10'>"; // رفرش اتوماتیک هر 10 ثانیه
  html += "<title>📊 SignalExecutor Dashboard</title>";

  // استایل‌ها
  html += "<style>";
  html += "* { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }";
  html += "body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }";
  html += ".container { max-width: 1400px; margin: 0 auto; }";
  html += ".header { background: rgba(255, 255, 255, 0.95); padding: 25px; border-radius: 15px; margin-bottom: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); display: flex; justify-content: space-between; align-items: center; }";
  html += ".header h1 { color: #333; font-size: 28px; }";
  html += ".header-info { display: flex; gap: 20px; }";
  html += ".info-box { background: #f8f9fa; padding: 10px 20px; border-radius: 8px; text-align: center; }";
  html += ".info-label { font-size: 12px; color: #666; margin-bottom: 5px; }";
  html += ".info-value { font-size: 18px; font-weight: bold; color: #333; }";
  html += ".profit { color: #10b981 !important; }";
  html += ".loss { color: #ef4444 !important; }";
  html += ".neutral { color: #6b7280 !important; }";
  html += ".positions-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 20px; }";
  html += ".position-card { background: rgba(255, 255, 255, 0.95); border-radius: 15px; padding: 20px; box-shadow: 0 5px 15px rgba(0,0,0,0.08); transition: transform 0.3s ease; }";
  html += ".position-card:hover { transform: translateY(-5px); }";
  html += ".card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; padding-bottom: 15px; border-bottom: 2px solid #f1f5f9; }";
  html += ".symbol { font-size: 22px; font-weight: bold; color: #1f2937; }";
  html += ".position-type { padding: 5px 15px; border-radius: 20px; font-size: 14px; font-weight: bold; }";
  html += ".buy { background: #d1fae5; color: #065f46; }";
  html += ".sell { background: #fee2e2; color: #991b1b; }";
  html += ".card-body { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }";
  html += ".data-row { display: flex; flex-direction: column; }";
  html += ".data-label { font-size: 12px; color: #6b7280; margin-bottom: 4px; }";
  html += ".data-value { font-size: 16px; font-weight: 600; color: #1f2937; }";
  html += ".stage-indicator { margin-top: 15px; padding: 10px; border-radius: 10px; text-align: center; font-weight: bold; }";
  html += ".stage-0 { background: #f3f4f6; color: #6b7280; }";
  html += ".stage-1 { background: #dbeafe; color: #1e40af; }";
  html += ".stage-2 { background: #fef3c7; color: #92400e; }";
  html += ".stage-3 { background: #dcfce7; color: #166534; }";
  html += ".stage-4 { background: #fce7f3; color: #9d174d; }";
  html += ".footer { text-align: center; margin-top: 30px; color: rgba(255, 255, 255, 0.8); font-size: 14px; }";
  html += ".update-time { background: rgba(0, 0, 0, 0.2); padding: 10px 20px; border-radius: 20px; display: inline-block; }";
  html += ".no-positions { text-align: center; padding: 40px; background: rgba(255, 255, 255, 0.95); border-radius: 15px; color: #6b7280; }";
  html += "@media (max-width: 768px) { .positions-grid { grid-template-columns: 1fr; } .header { flex-direction: column; gap: 15px; } }";
  html += "</style>";

  html += "</head>";
  html += "<body>";

  html += "<div class='container'>";

  // هدر
  html += "<div class='header'>";
  html += "<h1>📊 SignalExecutor Dashboard</h1>";
  html += "<div class='header-info'>";

  // اطلاعات حساب
  double balance = AccountInfoDouble(ACCOUNT_BALANCE);
  double equity = AccountInfoDouble(ACCOUNT_EQUITY);
  double margin = AccountInfoDouble(ACCOUNT_MARGIN);
  double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

  html += "<div class='info-box'>";
  html += "<div class='info-label'>Balance</div>";
  html += "<div class='info-value'>$" + DoubleToString(balance, 2) + "</div>";
  html += "</div>";

  html += "<div class='info-box'>";
  html += "<div class='info-label'>Equity</div>";
  html += "<div class='info-value " + (equity >= balance ? "profit" : "loss") + "'>$" + DoubleToString(equity, 2) + "</div>";
  html += "</div>";

  html += "<div class='info-box'>";
  html += "<div class='info-label'>Positions</div>";
  html += "<div class='info-value'>" + IntegerToString(PositionsTotal()) + "</div>";
  html += "</div>";

  html += "</div>"; // .header-info
  html += "</div>"; // .header

  // پوزیشن‌ها
  int totalPositions = PositionsTotal();

  if (totalPositions > 0)
  {
    html += "<div class='positions-grid'>";

    for (int i = 0; i < totalPositions; i++)
    {
      ulong ticket = PositionGetTicket(i);
      if (!PositionSelectByTicket(ticket))
        continue;

      string symbol = PositionGetString(POSITION_SYMBOL);
      double volume = PositionGetDouble(POSITION_VOLUME);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      double slPrice = PositionGetDouble(POSITION_SL);
      double tpPrice = PositionGetDouble(POSITION_TP);
      double profit = PositionGetDouble(POSITION_PROFIT);
      long type = PositionGetInteger(POSITION_TYPE);
      bool isBuy = (type == POSITION_TYPE_BUY);

      // محاسبه پیپ سود
      ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);
      double profitPips = CalculatePipsProfit(entryPrice, currentPrice, isBuy, symbol, symType);

      // استیج مدیریت ریسک
      string stageText = "Not Tracked";
      int stageLevel = 0;
      string stageClass = "stage-0";

      for (int j = 0; j < risk_data_count; j++)
      {
        if (risk_data_array[j].ticket == ticket)
        {
          stageLevel = risk_data_array[j].stage_completed;
          if (risk_data_array[j].risk_free_active)
          {
            stageText = "Risk-Free Active";
            stageClass = "stage-4";
          }
          else
          {
            stageText = "Stage " + IntegerToString(stageLevel) + " / 3";
            stageClass = "stage-" + IntegerToString(stageLevel);
          }
          break;
        }
      }

      // کارت پوزیشن
      html += "<div class='position-card'>";

      // هدر کارت
      html += "<div class='card-header'>";
      html += "<div class='symbol'>" + symbol + "</div>";
      html += "<div class='position-type " + (isBuy ? "buy" : "sell") + "'>";
      html += (isBuy ? "BUY" : "SELL") + " (" + DoubleToString(volume, 2) + " L)";
      html += "</div>";
      html += "</div>";

      // بدنه کارت
      html += "<div class='card-body'>";

      // سطر 1
      html += "<div class='data-row'>";
      html += "<div class='data-label'>Entry Price</div>";
      html += "<div class='data-value'>" + DoubleToString(entryPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + "</div>";
      html += "</div>";

      html += "<div class='data-row'>";
      html += "<div class='data-label'>Current Price</div>";
      html += "<div class='data-value'>" + DoubleToString(currentPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + "</div>";
      html += "</div>";

      // سطر 2
      html += "<div class='data-row'>";
      html += "<div class='data-label'>Stop Loss</div>";
      html += "<div class='data-value'>" + (slPrice > 0 ? DoubleToString(slPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) : "Not Set") + "</div>";
      html += "</div>";

      html += "<div class='data-row'>";
      html += "<div class='data-label'>Take Profit</div>";
      html += "<div class='data-value'>" + (tpPrice > 0 ? DoubleToString(tpPrice, (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS)) : "OPEN") + "</div>";
      html += "</div>";

      // سطر 3
      html += "<div class='data-row'>";
      html += "<div class='data-label'>Profit/Loss ($)</div>";
      html += "<div class='data-value " + (profit >= 0 ? "profit" : "loss") + "'>";
      html += "$" + DoubleToString(profit, 2);
      html += "</div>";
      html += "</div>";

      html += "<div class='data-row'>";
      html += "<div class='data-label'>Profit/Loss (Pips)</div>";
      html += "<div class='data-value " + (profitPips >= 0 ? "profit" : "loss") + "'>";
      html += DoubleToString(profitPips, 1) + " pips";
      html += "</div>";
      html += "</div>";

      html += "</div>"; // .card-body

      // اندیکاتور استیج
      html += "<div class='stage-indicator " + stageClass + "'>";
      html += stageText;
      html += "</div>";

      html += "</div>"; // .position-card
    }

    html += "</div>"; // .positions-grid
  }
  else
  {
    html += "<div class='no-positions'>";
    html += "<h2>📭 No Open Positions</h2>";
    html += "<p>There are currently no open positions to display.</p>";
    html += "</div>";
  }

  // فوتر
  html += "<div class='footer'>";
  html += "<div class='update-time'>";
  html += "Last Updated: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
  html += " | Next Update: " + TimeToString(TimeCurrent() + 10, TIME_SECONDS);
  html += " | SignalExecutor v1.90";
  html += "</div>";
  html += "</div>";

  html += "</div>"; // .container
  html += "</body>";
  html += "</html>";

  // ذخیره فایل
  string filename = "dashboard.html";
  int handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_ANSI);
  if (handle != INVALID_HANDLE)
  {
    FileWrite(handle, html);
    FileClose(handle);
    PrintLog("✅ Dashboard updated: " + filename);
  }
  else
  {
    PrintLog("❌ Failed to create dashboard file");
  }
}

// ================ تابع باز کردن داشبورد در مرورگر ================
void OpenDashboardInBrowser()
{
  string filename = "dashboard.html";
  if (FileIsExist(filename))
  {
    PrintLog("✅ Dashboard created: " + filename);
    PrintLog("📁 Open manually in browser from: MQL5\\Files\\" + filename);
  }
}
//+------------------------------------------------------------------+