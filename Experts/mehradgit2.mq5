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
#include <RiskManager.mqh>  // Include the risk management module

// ================ INPUT PARAMETERS ================

input group "General Settings" 
input int PollIntervalSeconds = 2;
input int DashboardRefreshRate = 10;
input bool AutoOpenDashboard = false;
input string SignalFileName = "output";
input string DefaultSymbol = "XAUUSD";
input bool EnableLogging = true;
input long ExpertMagicNumber = 123456;

input group "Risk Management" 
input double RiskPercentPerSignal = 15.0;
input bool EnableGlobalRiskLimit = true;
input double MaxTotalRiskPercent = 45.0;

input group "Execution Settings - GOLD (XAUUSD, GOLD)" 
input double MaxLotSize_GOLD = 10.0;
input double DefaultStopPips_GOLD = 200;
input double DefaultTpForOpenPips_GOLD = 200;
input int MaxSlippageForMarketPips_GOLD = 50;
input int PendingOrderDistanceFromSL_GOLD = 200;

input group "Execution Settings - DOW JONES (US30, DOW)" 
input double MaxLotSize_DOW = 10.0;
input double DefaultStopPips_DOW = 300;
input double DefaultTpForOpenPips_DOW = 300;
input int MaxSlippageForMarketPips_DOW = 100;
input int PendingOrderDistanceFromSL_DOW = 300;

input group "Execution Settings - NASDAQ (NAS100, NAS)" 
input double MaxLotSize_NAS = 10.0;
input double DefaultStopPips_NAS = 400;
input double DefaultTpForOpenPips_NAS = 400;
input int MaxSlippageForMarketPips_NAS = 150;
input int PendingOrderDistanceFromSL_NAS = 400;

input group "Execution Settings - BITCOIN (BTCUSD, BTC)" 
input double MaxLotSize_BTC = 1.0;
input double DefaultStopPips_BTC = 500;
input double DefaultTpForOpenPips_BTC = 500;
input int MaxSlippageForMarketPips_BTC = 200;
input int PendingOrderDistanceFromSL_BTC = 500;

input group "Execution Settings - OTHER PAIRS (EURUSD, GBPUSD, etc)" 
input double MaxLotSize_FOREX = 10.0;
input double DefaultStopPips_FOREX = 100;
input double DefaultTpForOpenPips_FOREX = 100;
input int MaxSlippageForMarketPips_FOREX = 30;
input int PendingOrderDistanceFromSL_FOREX = 100;

// ================ TP/SL ADJUSTMENT SETTINGS ================

input group "TP/SL Adjustment - GOLD (MARKET)" 
input double Gold_BuyMarketTP_AdjustPips = 0.0;
input double Gold_BuyMarketSL_AdjustPips = 0.0;
input double Gold_SellMarketTP_AdjustPips = 0.0;
input double Gold_SellMarketSL_AdjustPips = 0.0;

input group "TP/SL Adjustment - GOLD (PENDING)" 
input double Gold_BuyPendingTP_AdjustPips = 0.0;
input double Gold_BuyPendingSL_AdjustPips = 0.0;
input double Gold_SellPendingTP_AdjustPips = 0.0;
input double Gold_SellPendingSL_AdjustPips = 0.0;

input group "TP/SL Adjustment - DOW JONES (MARKET)" 
input double Dow_BuyMarketTP_AdjustPips = 0.0;
input double Dow_BuyMarketSL_AdjustPips = 0.0;
input double Dow_SellMarketTP_AdjustPips = 0.0;
input double Dow_SellMarketSL_AdjustPips = 0.0;

input group "TP/SL Adjustment - DOW JONES (PENDING)" 
input double Dow_BuyPendingTP_AdjustPips = 0.0;
input double Dow_BuyPendingSL_AdjustPips = 0.0;
input double Dow_SellPendingTP_AdjustPips = 0.0;
input double Dow_SellPendingSL_AdjustPips = 0.0;

input group "TP/SL Adjustment - NASDAQ (MARKET)" 
input double Nas_BuyMarketTP_AdjustPips = 0.0;
input double Nas_BuyMarketSL_AdjustPips = 0.0;
input double Nas_SellMarketTP_AdjustPips = 0.0;
input double Nas_SellMarketSL_AdjustPips = 0.0;

input group "TP/SL Adjustment - NASDAQ (PENDING)" 
input double Nas_BuyPendingTP_AdjustPips = 0.0;
input double Nas_BuyPendingSL_AdjustPips = 0.0;
input double Nas_SellPendingTP_AdjustPips = 0.0;
input double Nas_SellPendingSL_AdjustPips = 0.0;

input group "TP/SL Adjustment - BITCOIN (MARKET)" 
input double Btc_BuyMarketTP_AdjustPips = 0.0;
input double Btc_BuyMarketSL_AdjustPips = 0.0;
input double Btc_SellMarketTP_AdjustPips = 0.0;
input double Btc_SellMarketSL_AdjustPips = 0.0;

input group "TP/SL Adjustment - BITCOIN (PENDING)" 
input double Btc_BuyPendingTP_AdjustPips = 0.0;
input double Btc_BuyPendingSL_AdjustPips = 0.0;
input double Btc_SellPendingTP_AdjustPips = 0.0;
input double Btc_SellPendingSL_AdjustPips = 0.0;

input group "TP/SL Adjustment - FOREX (MARKET)" 
input double Forex_BuyMarketTP_AdjustPips = 0.0;
input double Forex_BuyMarketSL_AdjustPips = 0.0;
input double Forex_SellMarketTP_AdjustPips = 0.0;
input double Forex_SellMarketSL_AdjustPips = 0.0;

input group "TP/SL Adjustment - FOREX (PENDING)" 
input double Forex_BuyPendingTP_AdjustPips = 0.0;
input double Forex_BuyPendingSL_AdjustPips = 0.0;
input double Forex_SellPendingTP_AdjustPips = 0.0;
input double Forex_SellPendingSL_AdjustPips = 0.0;

// ================ OTHER SETTINGS ================

input group "Other Settings" 
input bool CloseOthersOnFirstTP = false;
input bool DeletePendingOnTP = true;
input bool ClosePendingOnProfit = true;
input int RiskCheckInterval = 5;

input group "Telegram Settings" 
input string TelegramBotToken = "7988454640:AAFv_VAwdn_DZZnqtUaU48iGq8Y3IMTTuPI";
input string TelegramChatID = "-4708601845";
input bool EnableTelegram = true;
input int TelegramTimeout = 5000;

// ================ STRUCTURES AND ENUMS ================

// ENUM is defined only here (not in RiskManager.mqh)
// enum ENUM_SYMBOL_TYPE
// {
//   SYMBOL_TYPE_GOLD,
//   SYMBOL_TYPE_DOW,
//   SYMBOL_TYPE_NASDAQ,
//   SYMBOL_TYPE_BITCOIN,
//   SYMBOL_TYPE_FOREX,
//   SYMBOL_TYPE_UNKNOWN
// };

struct SymbolSettings
{
  double max_lot;
  double default_sl_pips;
  double default_tp_pips;
  int max_slippage_pips;
  int pending_distance_pips;
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
datetime last_dashboard_update = 0;
SymbolSettings gold_settings, dow_settings, nas_settings, btc_settings, forex_settings;
CRiskManager riskManager; // Risk manager instance

// ================ FUNCTION PROTOTYPES ================

void ProcessSignalFile();
void ManageOpenPositions();
void CloseGroupOrders(string signalID);
void ClosePendingOrdersForSignal(string signalID, string reason);

ENUM_SYMBOL_TYPE GetSymbolType(string symbol);
SymbolSettings GetSymbolSettings(ENUM_SYMBOL_TYPE symType);
string GetSymbolTypeName(ENUM_SYMBOL_TYPE symType);
void InitializeSymbolSettings();
double CalculatePendingPrice(string orderType, double slPrice, double currentPrice, string symbol, int distancePips, ENUM_SYMBOL_TYPE symType, bool isBuy);
double CalculateDefaultSL(string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings, double currentPrice, bool isBuy);
double CalculatePositionSize(string symbol, double totalRiskMoney, double distSL);
double GetFirstTP(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings, double referencePrice, bool isBuy, string orderType = "", bool isMarketOrder = false, bool isPendingOrder = false);

bool SendOrder(string symbol, string order_type, bool isMarket, double entryPrice, double sl_price, double tp_price, double lot, string signalID);
bool SendMarketOrder(string symbol, string order_type, double sl_price, double tp_price, double lot, string signalID);
bool SendPendingOrder(string symbol, string order_type, double entryPrice, double sl_price, double tp_price, double lot, string signalID);
void ProcessSignalWithSmartLogic(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings,
                                 double totalRiskMoney, string signalID, int &successCount, double &totalVolume);

bool SendTelegramMessage(string message);
bool SendTelegramFarsi(string message);
bool CheckTelegramSettings();
void SendExecutionReport(string signalID, string symbol, string orderType, int totalOrders, int successfulOrders,
                         double totalVolume, bool singleOrderMode, bool pendingMode, double pendingPrice, ENUM_SYMBOL_TYPE symType);
void SendSignalAlert(string signalID, string symbol, string message);
void SendSignalEntryReport(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType);

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

void CreateHtmlDashboard();

bool ParseJsonContent(string content, SignalData &out);
string ExtractJsonValue(string json, string key);
bool ExtractJsonArray(string json, string arrayKey, double &outArray[], int &outCount);
string NormalizeContentLines(string content);

// ================ MAIN FUNCTIONS ================

int OnInit()
{
  int poll = PollIntervalSeconds;
  if (poll < 1) poll = 1;

  EventSetTimer(poll);
  trade.SetExpertMagicNumber(ExpertMagicNumber);
  trade.SetTypeFilling(ORDER_FILLING_FOK);

  InitializeSymbolSettings();
  
  // Initialize risk manager
  riskManager.SetMagicNumber(ExpertMagicNumber);
  riskManager.SetTelegramSettings(EnableTelegram, TelegramBotToken, TelegramChatID);
  
  PrintLog("SignalExecutor v1.95 initialized.");

  if (EnableTelegram && CheckTelegramSettings())
    SendTelegramFarsi("🤖 SignalExecutor v1.95 Started");

  last_history_check = TimeCurrent();
  last_dashboard_update = TimeCurrent();
  g_initialized = true;
  return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
  EventKillTimer();
  if (EnableTelegram) SendTelegramFarsi("🔴 SignalExecutor Stopped");
}

void OnTimer()
{
  ProcessSignalFile();
  ManageOpenPositions();

  if (EnableGlobalRiskLimit && TimeCurrent() % 30 == 0)
  {
    double currentRiskPercent = CalculateTotalRiskPercentage();
    if (currentRiskPercent > MaxTotalRiskPercent * 0.8)
      PrintLog("Risk approaching limit: " + DoubleToString(currentRiskPercent, 1) + "%");
  }

  if (TimeCurrent() - last_dashboard_update >= DashboardRefreshRate)
  {
    CreateHtmlDashboard();
    last_dashboard_update = TimeCurrent();
  }

  if (TimeCurrent() % RiskCheckInterval == 0)
  {
    riskManager.ManageRiskForAllPositions();
  }
}

// ================ SYMBOL MANAGEMENT FUNCTIONS ================

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

string GetSymbolTypeName(ENUM_SYMBOL_TYPE symType)
{
  switch (symType)
  {
  case SYMBOL_TYPE_GOLD: return "GOLD";
  case SYMBOL_TYPE_DOW: return "DOW JONES";
  case SYMBOL_TYPE_NASDAQ: return "NASDAQ";
  case SYMBOL_TYPE_BITCOIN: return "BITCOIN";
  case SYMBOL_TYPE_FOREX: return "FOREX";
  default: return "UNKNOWN";
  }
}

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

  case SYMBOL_TYPE_BITCOIN:
    settings.max_lot = btc_settings.max_lot;
    settings.default_sl_pips = btc_settings.default_sl_pips;
    settings.default_tp_pips = btc_settings.default_tp_pips;
    settings.max_slippage_pips = btc_settings.max_slippage_pips;
    settings.pending_distance_pips = btc_settings.pending_distance_pips;
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

// ================ TELEGRAM FUNCTIONS ================

bool SendTelegramFarsi(string message)
{
  if (!EnableTelegram || !CheckTelegramSettings()) return false;
  return SendTelegramMessage(message);
}

bool CheckTelegramSettings()
{
  return (StringLen(TelegramBotToken) > 20 && StringLen(TelegramChatID) > 5);
}

void SendSignalEntryReport(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType)
{
  if (!EnableTelegram) return;
  
  string report = "NEW SIGNAL RECEIVED | ID: " + sig.signal_id + " | Symbol: " + symbol;
  SendTelegramFarsi(report);
}

void SendSignalAlert(string signalID, string symbol, string message)
{
  if (!EnableTelegram) return;
  SendTelegramFarsi("Signal Alert | ID: " + signalID + " | " + message);
}

bool SendTelegramMessage(string message)
{
  if (!EnableTelegram || StringLen(TelegramBotToken) < 10) return false;

  string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
  string cleanMsg = message;
  StringReplace(cleanMsg, "\"", "\\\"");
  StringReplace(cleanMsg, "\n", "\\n");
  StringReplace(cleanMsg, "\r", "");

  string json = "{\"chat_id\": \"" + TelegramChatID + "\", \"text\": \"" + cleanMsg + "\"}";
  char post[], res[];
  StringToCharArray(json, post, 0, WHOLE_ARRAY, CP_UTF8);
  if (ArraySize(post) > 0) ArrayResize(post, ArraySize(post) - 1);

  string headers = "Content-Type: application/json\r\n";
  string res_headers;
  int code = WebRequest("POST", url, headers, TelegramTimeout, post, res, res_headers);

  return (code == 200);
}

void SendExecutionReport(string signalID, string symbol, string orderType, int totalOrders, int successfulOrders,
                         double totalVolume, bool singleOrderMode, bool pendingMode, double pendingPrice, ENUM_SYMBOL_TYPE symType)
{
  if (!EnableTelegram) return;
  
  string report = "Execution Report | Signal: " + signalID + " | Symbol: " + symbol;
  if (pendingMode) report += " | Pending Mode";
  if (singleOrderMode) report += " | Single Order Mode";
  
  SendTelegramFarsi(report);
}

// ================ HELPER FUNCTIONS ================

void PrintLog(string message)
{
  if (EnableLogging) Print(message);
}

string StringTrimCustom(string str)
{
  string s = str;
  StringTrimLeft(s);
  StringTrimRight(s);
  return s;
}

string StringToLowerCustom(string str)
{
  string s = str;
  StringToLower(s);
  return s;
}

bool StringContains(string str, string substr)
{
  return (StringFind(str, substr) >= 0);
}

double EstimatePipValuePerLot(string symbol)
{
  double tickValue = 0;
  double tickSize = 0;

  if (!SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE, tickValue)) return 10.0;
  if (!SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE, tickSize)) return 10.0;

  if (tickValue > 0 && tickSize > 0) return tickValue / tickSize;
  return 10.0;
}

double NormalizeLotToSymbol(double lot, string symbol)
{
  double min = 0;
  double max = 0;
  double step = 0;

  if (!SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN, min)) min = 0.01;
  if (!SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX, max)) max = 100.0;
  if (!SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP, step)) step = 0.01;

  if (min <= 0) min = 0.01;
  if (step <= 0) step = 0.01;

  if (lot < min) lot = min;
  if (lot > max) lot = max;

  double steps = MathFloor(lot / step + 0.000001);
  lot = steps * step;

  return NormalizeDouble(lot, 2);
}

double CalculatePipsProfit(double entryPrice, double currentPrice, bool isBuy, string symbol, ENUM_SYMBOL_TYPE symType)
{
  double point = 0;
  if (!SymbolInfoDouble(symbol, SYMBOL_POINT, point)) return 0;

  double priceDiff = isBuy ? currentPrice - entryPrice : entryPrice - currentPrice;
  double pips = priceDiff / point;

  if (symType == SYMBOL_TYPE_GOLD) pips = pips / 10.0;
  else if (symType == SYMBOL_TYPE_BITCOIN) pips = pips / 10.0;
  else if (symType == SYMBOL_TYPE_FOREX) pips = pips / 10.0;

  return pips;
}

int CountOpenPositionsForSignal(string signalID)
{
  int count = 0;
  for (int i = PositionsTotal() - 1; i >= 0; i--)
  {
    ulong ticket = PositionGetTicket(i);
    if (ticket <= 0) continue;

    long magic = PositionGetInteger(POSITION_MAGIC);
    if (magic != ExpertMagicNumber) continue;

    string cmt = PositionGetString(POSITION_COMMENT);
    if (StringFind(cmt, "SID:" + signalID) >= 0) count++;
  }
  return count;
}

int CountPendingOrdersForSignal(string signalID)
{
  int count = 0;
  for (int i = OrdersTotal() - 1; i >= 0; i--)
  {
    ulong ticket = OrderGetTicket(i);
    if (ticket <= 0) continue;

    long magic = OrderGetInteger(ORDER_MAGIC);
    if (magic != ExpertMagicNumber) continue;

    string cmt = OrderGetString(ORDER_COMMENT);
    if (StringFind(cmt, "SID:" + signalID) >= 0) count++;
  }
  return count;
}

double CalculatePositionRiskMoney(ulong ticket)
{
  if (!PositionSelectByTicket(ticket)) return 0;

  string symbol = PositionGetString(POSITION_SYMBOL);
  double volume = PositionGetDouble(POSITION_VOLUME);
  double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
  double sl = PositionGetDouble(POSITION_SL);

  if (sl <= 0) return 0;

  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
  double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
  if (tickSize <= 0) tickSize = point;

  ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
  double slDistance = (type == POSITION_TYPE_BUY) ? (openPrice - sl) / tickSize : (sl - openPrice) / tickSize;
  double riskMoney = (slDistance * tickValue * volume);

  return MathAbs(riskMoney);
}

double CalculateTotalOpenPositionsRiskMoney()
{
  double totalRiskMoney = 0;

  for (int i = PositionsTotal() - 1; i >= 0; i--)
  {
    ulong ticket = PositionGetTicket(i);
    if (ticket <= 0) continue;

    long magic = PositionGetInteger(POSITION_MAGIC);
    if (magic != ExpertMagicNumber) continue;

    double positionRisk = CalculatePositionRiskMoney(ticket);
    totalRiskMoney += positionRisk;
  }

  return totalRiskMoney;
}

double CalculateTotalRiskPercentage()
{
  double balance = AccountInfoDouble(ACCOUNT_BALANCE);
  if (balance <= 0) return 0;

  double totalRiskMoney = CalculateTotalOpenPositionsRiskMoney();
  double riskPercent = (totalRiskMoney / balance) * 100.0;

  return riskPercent;
}

bool CheckGlobalRiskLimit(double signalRiskMoney)
{
  if (!EnableGlobalRiskLimit) return true;

  double currentRiskMoney = CalculateTotalOpenPositionsRiskMoney();
  double balance = AccountInfoDouble(ACCOUNT_BALANCE);

  if (balance <= 0) return false;

  double potentialRiskMoney = currentRiskMoney + signalRiskMoney;
  double potentialRiskPercent = (potentialRiskMoney / balance) * 100.0;

  if (potentialRiskPercent > MaxTotalRiskPercent)
  {
    if (EnableTelegram)
      SendTelegramFarsi("Global Risk Limit Exceeded | Signal execution BLOCKED");

    return false;
  }

  return true;
}

// ================ TP/SL ADJUSTMENT FUNCTIONS ================

double GetTPAdjustPips(ENUM_SYMBOL_TYPE symType, bool isBuy, bool isMarketOrder, bool isPendingOrder)
{
  if (isMarketOrder)
  {
    if (isBuy)
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD: return Gold_BuyMarketTP_AdjustPips;
      case SYMBOL_TYPE_DOW: return Dow_BuyMarketTP_AdjustPips;
      case SYMBOL_TYPE_NASDAQ: return Nas_BuyMarketTP_AdjustPips;
      case SYMBOL_TYPE_BITCOIN: return Btc_BuyMarketTP_AdjustPips;
      case SYMBOL_TYPE_FOREX: return Forex_BuyMarketTP_AdjustPips;
      default: return 0.0;
      }
    }
    else
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD: return Gold_SellMarketTP_AdjustPips;
      case SYMBOL_TYPE_DOW: return Dow_SellMarketTP_AdjustPips;
      case SYMBOL_TYPE_NASDAQ: return Nas_SellMarketTP_AdjustPips;
      case SYMBOL_TYPE_BITCOIN: return Btc_SellMarketTP_AdjustPips;
      case SYMBOL_TYPE_FOREX: return Forex_SellMarketTP_AdjustPips;
      default: return 0.0;
      }
    }
  }
  else if (isPendingOrder)
  {
    if (isBuy)
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD: return Gold_BuyPendingTP_AdjustPips;
      case SYMBOL_TYPE_DOW: return Dow_BuyPendingTP_AdjustPips;
      case SYMBOL_TYPE_NASDAQ: return Nas_BuyPendingTP_AdjustPips;
      case SYMBOL_TYPE_BITCOIN: return Btc_BuyPendingTP_AdjustPips;
      case SYMBOL_TYPE_FOREX: return Forex_BuyPendingTP_AdjustPips;
      default: return 0.0;
      }
    }
    else
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD: return Gold_SellPendingTP_AdjustPips;
      case SYMBOL_TYPE_DOW: return Dow_SellPendingTP_AdjustPips;
      case SYMBOL_TYPE_NASDAQ: return Nas_SellPendingTP_AdjustPips;
      case SYMBOL_TYPE_BITCOIN: return Btc_SellPendingTP_AdjustPips;
      case SYMBOL_TYPE_FOREX: return Forex_SellPendingTP_AdjustPips;
      default: return 0.0;
      }
    }
  }

  return 0.0;
}

double GetSLAdjustPips(ENUM_SYMBOL_TYPE symType, bool isBuy, bool isMarketOrder, bool isPendingOrder)
{
  if (isMarketOrder)
  {
    if (isBuy)
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD: return Gold_BuyMarketSL_AdjustPips;
      case SYMBOL_TYPE_DOW: return Dow_BuyMarketSL_AdjustPips;
      case SYMBOL_TYPE_NASDAQ: return Nas_BuyMarketSL_AdjustPips;
      case SYMBOL_TYPE_BITCOIN: return Btc_BuyMarketSL_AdjustPips;
      case SYMBOL_TYPE_FOREX: return Forex_BuyMarketSL_AdjustPips;
      default: return 0.0;
      }
    }
    else
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD: return Gold_SellMarketSL_AdjustPips;
      case SYMBOL_TYPE_DOW: return Dow_SellMarketSL_AdjustPips;
      case SYMBOL_TYPE_NASDAQ: return Nas_SellMarketSL_AdjustPips;
      case SYMBOL_TYPE_BITCOIN: return Btc_SellMarketSL_AdjustPips;
      case SYMBOL_TYPE_FOREX: return Forex_SellMarketSL_AdjustPips;
      default: return 0.0;
      }
    }
  }
  else if (isPendingOrder)
  {
    if (isBuy)
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD: return Gold_BuyPendingSL_AdjustPips;
      case SYMBOL_TYPE_DOW: return Dow_BuyPendingSL_AdjustPips;
      case SYMBOL_TYPE_NASDAQ: return Nas_BuyPendingSL_AdjustPips;
      case SYMBOL_TYPE_BITCOIN: return Btc_BuyPendingSL_AdjustPips;
      case SYMBOL_TYPE_FOREX: return Forex_BuyPendingSL_AdjustPips;
      default: return 0.0;
      }
    }
    else
    {
      switch (symType)
      {
      case SYMBOL_TYPE_GOLD: return Gold_SellPendingSL_AdjustPips;
      case SYMBOL_TYPE_DOW: return Dow_SellPendingSL_AdjustPips;
      case SYMBOL_TYPE_NASDAQ: return Nas_SellPendingSL_AdjustPips;
      case SYMBOL_TYPE_BITCOIN: return Btc_SellPendingSL_AdjustPips;
      case SYMBOL_TYPE_FOREX: return Forex_SellPendingSL_AdjustPips;
      default: return 0.0;
      }
    }
  }

  return 0.0;
}

double AdjustPriceWithPips(double originalPrice, double adjustPips, string symbol,
                           ENUM_SYMBOL_TYPE symType, bool isBuy, bool isTP)
{
  if (adjustPips == 0.0 || originalPrice <= 0) return originalPrice;

  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  double multiplier = 1.0;

  if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN) multiplier = 10.0;
  else if (symType == SYMBOL_TYPE_FOREX) multiplier = 10.0;

  double adjustmentPoints = adjustPips * point * multiplier;

  if (isBuy) return isTP ? originalPrice + adjustmentPoints : originalPrice - adjustmentPoints;
  else return isTP ? originalPrice - adjustmentPoints : originalPrice + adjustmentPoints;
}

double AdjustTPPrice(double originalTP, string symbol, ENUM_SYMBOL_TYPE symType,
                     string orderType, bool isMarketOrder, bool isPendingOrder)
{
  if (originalTP <= 0) return originalTP;

  string orderTypeLower = StringToLowerCustom(orderType);
  bool isBuy = (StringFind(orderTypeLower, "buy") >= 0);
  double adjustPips = GetTPAdjustPips(symType, isBuy, isMarketOrder, isPendingOrder);

  if (adjustPips == 0.0) return originalTP;
  return AdjustPriceWithPips(originalTP, adjustPips, symbol, symType, isBuy, true);
}

double AdjustSLPrice(double originalSL, string symbol, ENUM_SYMBOL_TYPE symType,
                     string orderType, bool isMarketOrder, bool isPendingOrder)
{
  if (originalSL <= 0) return originalSL;

  string orderTypeLower = StringToLowerCustom(orderType);
  bool isBuy = (StringFind(orderTypeLower, "buy") >= 0);
  double adjustPips = GetSLAdjustPips(symType, isBuy, isMarketOrder, isPendingOrder);

  if (adjustPips == 0.0) return originalSL;
  return AdjustPriceWithPips(originalSL, adjustPips, symbol, symType, isBuy, false);
}

// ================ POSITION MANAGEMENT FUNCTIONS ================

void ManageOpenPositions()
{
  if (!CloseOthersOnFirstTP && !DeletePendingOnTP) return;
  if (!HistorySelect(last_history_check - 60, TimeCurrent())) return;

  int total = HistoryDealsTotal();
  for (int i = 0; i < total; i++)
  {
    ulong ticket = HistoryDealGetTicket(i);
    if (ticket <= 0) continue;

    long magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
    if (magic != ExpertMagicNumber) continue;

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
        if (space > 0) signalID = StringSubstr(signalID, 0, space);

        if (EnableTelegram)
          SendTelegramFarsi("Target Reached | Signal ID: " + signalID);

        CloseGroupOrders(signalID);
      }
    }
  }
  last_history_check = TimeCurrent();
}

void CloseGroupOrders(string signalID)
{
  if (StringLen(signalID) == 0) return;

  int closedPositions = 0;
  int deletedOrders = 0;

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
        }
      }
    }
  }

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
        }
      }
    }
  }
}

void ClosePendingOrdersForSignal(string signalID, string reason)
{
  if (StringLen(signalID) == 0) return;

  int deletedOrders = 0;
  for (int i = OrdersTotal() - 1; i >= 0; i--)
  {
    ulong ticket = OrderGetTicket(i);
    if (ticket <= 0) continue;

    long magic = OrderGetInteger(ORDER_MAGIC);
    if (magic != ExpertMagicNumber) continue;

    string cmt = OrderGetString(ORDER_COMMENT);
    if (StringFind(cmt, "SID:" + signalID) >= 0)
    {
      trade.OrderDelete(ticket);
      deletedOrders++;
    }
  }

  if (deletedOrders > 0 && EnableTelegram)
    SendTelegramFarsi("Pending Orders Closed | Signal: " + signalID + " | Reason: " + reason);
}

// ================ JSON PROCESSING FUNCTIONS ================

bool ParseJsonContent(string content, SignalData &out)
{
  ArrayResize(out.prices_list, 0);
  ArrayResize(out.prices_isMarket, 0);
  out.prices_count = 0;
  ArrayResize(out.tp_list, 0);
  out.tp_count = 0;
  ArrayResize(out.sl_list, 0);
  out.sl_count = 0;

  out.currency = ExtractJsonValue(content, "currency");
  out.order_type = ExtractJsonValue(content, "order_type");
  out.signal_id = ExtractJsonValue(content, "signal_id");
  out.status = ExtractJsonValue(content, "status");

  int priceStart = StringFind(content, "\"prices\":[");
  if (priceStart >= 0)
  {
    priceStart += 10;
    int priceEnd = StringFind(content, "]", priceStart);
    if (priceEnd > priceStart)
    {
      string pricesStr = StringSubstr(content, priceStart, priceEnd - priceStart);
      int pos = 0;
      int priceCount = 0;

      while (true)
      {
        int numStart = StringFind(pricesStr, "\"", pos);
        if (numStart < 0) break;

        int numEnd = StringFind(pricesStr, "\"", numStart + 1);
        if (numEnd < 0) break;

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
          }
        }
        pos = numEnd + 1;
        if (pos >= StringLen(pricesStr)) break;
      }
      out.prices_count = priceCount;
    }
  }

  int tpStart = StringFind(content, "\"tp\":[");
  if (tpStart >= 0)
  {
    tpStart += 6;
    int tpEnd = StringFind(content, "]", tpStart);
    if (tpEnd > tpStart)
    {
      string tpStr = StringSubstr(content, tpStart, tpEnd - tpStart);
      int pos = 0;
      int tpCount = 0;

      while (true)
      {
        int itemStart = StringFind(tpStr, "\"tp_item\":\"", pos);
        if (itemStart < 0) break;

        itemStart += 11;
        int itemEnd = StringFind(tpStr, "\"", itemStart);
        if (itemEnd < 0) break;

        string itemStr = StringSubstr(tpStr, itemStart, itemEnd - itemStart);
        if (StringCompare(itemStr, "OPEN", true) == 0)
        {
          ArrayResize(out.tp_list, tpCount + 1);
          out.tp_list[tpCount] = 0;
          tpCount++;
        }
        else
        {
          double tpVal = StringToDouble(itemStr);
          if (tpVal > 0)
          {
            ArrayResize(out.tp_list, tpCount + 1);
            out.tp_list[tpCount] = tpVal;
            tpCount++;
          }
        }
        pos = itemEnd + 1;
        if (pos >= StringLen(tpStr)) break;
      }
      out.tp_count = tpCount;
    }
  }

  int slStart = StringFind(content, "\"sl\":[");
  if (slStart >= 0)
  {
    slStart += 6;
    int slEnd = StringFind(content, "]", slStart);
    if (slEnd > slStart)
    {
      string slStr = StringSubstr(content, slStart, slEnd - slStart);
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
        }
      }
    }
  }

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
      }
    }
  }

  return (out.prices_count > 0);
}

string ExtractJsonValue(string json, string key)
{
  string search = "\"" + key + "\":\"";
  int pos = StringFind(json, search);
  if (pos < 0)
  {
    search = "\"" + key + "\":";
    pos = StringFind(json, search);
    if (pos < 0) return "";
  }

  pos += StringLen(search);
  int endPos = pos;
  while (endPos < StringLen(json))
  {
    ushort c = StringGetCharacter(json, endPos);
    if (c == '"' || c == ',' || c == '}') break;
    endPos++;
  }

  string res = StringSubstr(json, pos, endPos - pos);
  StringReplace(res, "\"", "");
  return StringTrimCustom(res);
}

bool ExtractJsonArray(string json, string arrayKey, double &outArray[], int &outCount)
{
  outCount = 0;
  ArrayResize(outArray, 0);
  string search = "\"" + arrayKey + "\":";
  int pos = StringFind(json, search);
  if (pos < 0) return false;

  int start = StringFind(json, "[", pos);
  if (start < 0) return false;

  int end = -1;
  int depth = 0;
  for (int i = start; i < StringLen(json); i++)
  {
    ushort c = StringGetCharacter(json, i);
    if (c == '[') depth++;
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
  if (end < 0) return false;

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

string NormalizeContentLines(string content)
{
  if (StringLen(content) == 0) return content;
  string parts[];
  int cnt = StringSplit(content, '\n', parts);
  if (cnt <= 1) return content;

  int singleChars = 0;
  for (int i = 0; i < cnt; i++)
  {
    string s = parts[i];
    StringTrimLeft(s);
    StringTrimRight(s);
    if (StringLen(s) <= 1) singleChars++;
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

// ================ ORDER MANAGEMENT FUNCTIONS ================

bool SendMarketOrder(string symbol, string order_type, double sl_price, double tp_price, double lot, string signalID)
{
  MqlTradeRequest request;
  MqlTradeResult result;
  ZeroMemory(request);
  ZeroMemory(result);

  int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
  double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
  if (tickSize == 0) tickSize = SymbolInfoDouble(symbol, SYMBOL_POINT);

  if (sl_price > 0) sl_price = MathRound(sl_price / tickSize) * tickSize;
  if (tp_price > 0) tp_price = MathRound(tp_price / tickSize) * tickSize;

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

  if (tp_price > 0)
  {
    ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);
    tp_price = AdjustTPPrice(tp_price, symbol, symType, order_type, true, false);
  }

  if (sl_price > 0)
  {
    ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);
    sl_price = AdjustSLPrice(sl_price, symbol, symType, order_type, true, false);
  }

  if (sl_price > 0) request.sl = sl_price;
  if (tp_price > 0) request.tp = tp_price;

  bool sent = OrderSend(request, result);

  if (sent && riskManager.IsRiskManagementEnabled())
    riskManager.InitializeRiskDataForPosition(result.order, signalID, request.price, sl_price, tp_price);

  return sent;
}

bool SendPendingOrder(string symbol, string order_type, double entryPrice, double sl_price, double tp_price, double lot, string signalID)
{
  if (symbol == "" || order_type == "" || entryPrice <= 0 || lot <= 0) return false;

  if (!SymbolSelect(symbol, true)) return false;

  double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
  double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

  if (bid <= 0 || ask <= 0 || point <= 0) return false;

  string orderTypeLower = StringToLowerCustom(order_type);
  bool isBuyOrder = (StringFind(orderTypeLower, "buy") >= 0);
  bool isSellOrder = (StringFind(orderTypeLower, "sell") >= 0);
  bool isLimitOrder = (StringFind(orderTypeLower, "limit") >= 0);
  bool isStopOrder = (StringFind(orderTypeLower, "stop") >= 0);

  if (!isBuyOrder && !isSellOrder) return false;

  double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
  if (tickSize <= 0) tickSize = point;

  double normalizedEntry = MathRound(entryPrice / tickSize) * tickSize;
  double normalizedSL = (sl_price > 0) ? MathRound(sl_price / tickSize) * tickSize : 0;
  double normalizedTP = (tp_price > 0) ? MathRound(tp_price / tickSize) * tickSize : 0;

  ENUM_ORDER_TYPE orderTypeEnum;
  if (isBuyOrder)
  {
    if (isLimitOrder) orderTypeEnum = ORDER_TYPE_BUY_LIMIT;
    else if (isStopOrder) orderTypeEnum = ORDER_TYPE_BUY_STOP;
    else orderTypeEnum = (normalizedEntry > ask) ? ORDER_TYPE_BUY_STOP : ORDER_TYPE_BUY_LIMIT;
  }
  else
  {
    if (isLimitOrder) orderTypeEnum = ORDER_TYPE_SELL_LIMIT;
    else if (isStopOrder) orderTypeEnum = ORDER_TYPE_SELL_STOP;
    else orderTypeEnum = (normalizedEntry < bid) ? ORDER_TYPE_SELL_STOP : ORDER_TYPE_SELL_LIMIT;
  }

  double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
  double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
  double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
  
  double normalizedLot = lot;
  if (lotStep > 0)
  {
    normalizedLot = MathFloor(lot / lotStep) * lotStep;
    normalizedLot = MathMax(normalizedLot, minLot);
    normalizedLot = MathMin(normalizedLot, maxLot);
  }

  if (normalizedLot < minLot || normalizedLot > maxLot) return false;

  MqlTradeRequest request;
  MqlTradeResult result;
  ZeroMemory(request);
  ZeroMemory(result);

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

  bool orderSent = OrderSend(request, result);
  return orderSent;
}

bool SendOrder(string symbol, string order_type, bool isMarket, double entryPrice, double sl_price, double tp_price, double lot, string signalID)
{
  if (isMarket)
    return SendMarketOrder(symbol, order_type, sl_price, tp_price, lot, signalID);
  else
    return SendPendingOrder(symbol, order_type, entryPrice, sl_price, tp_price, lot, signalID);
}

// ================ CALCULATION FUNCTIONS ================

double CalculateDefaultSL(string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings, double currentPrice, bool isBuy)
{
  double point = 0;
  if (!SymbolInfoDouble(symbol, SYMBOL_POINT, point)) return 0;

  double pips = settings.default_sl_pips;
  if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN) pips = pips * 10.0;
  else if (symType == SYMBOL_TYPE_FOREX) pips = pips / 10.0;

  double dist = pips * point;
  return isBuy ? currentPrice - dist : currentPrice + dist;
}

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

double GetFirstTP(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType,
                  SymbolSettings &settings, double referencePrice, bool isBuy,
                  string orderType = "", bool isMarketOrder = false, bool isPendingOrder = false)
{
  double firstTP = (sig.tp_count > 0) ? sig.tp_list[0] : 0;

  if (firstTP > 0)
  {
    if (orderType != "" && (isMarketOrder || isPendingOrder))
      firstTP = AdjustTPPrice(firstTP, symbol, symType, orderType, isMarketOrder, isPendingOrder);
    
    return firstTP;
  }

  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
  double pips = settings.default_tp_pips;

  if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN) pips = pips * 10.0;
  else if (symType == SYMBOL_TYPE_FOREX) pips = pips / 10.0;

  double dist = pips * point;
  firstTP = isBuy ? referencePrice + dist : referencePrice - dist;

  if (orderType != "" && (isMarketOrder || isPendingOrder))
    firstTP = AdjustTPPrice(firstTP, symbol, symType, orderType, isMarketOrder, isPendingOrder);

  return firstTP;
}

double CalculatePendingPrice(string orderType, double slPrice, double currentPrice, string symbol, int distancePips, ENUM_SYMBOL_TYPE symType, bool isBuy)
{
  double point = 0;
  if (!SymbolInfoDouble(symbol, SYMBOL_POINT, point)) return 0;

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
  return isBuy ? slPrice + distancePoints : slPrice - distancePoints;
}

// ================ PROCESS SIGNAL WITH SMART LOGIC ================

void ProcessSignalWithSmartLogic(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings &settings,
                                 double totalRiskMoney, string signalID, int &successCount, double &totalVolume)
{
  if (sig.prices_count == 0) return;
  if (sig.tp_count == 0)
  {
    sig.tp_count = 1;
    ArrayResize(sig.tp_list, 1);
    sig.tp_list[0] = 0;
  }

  string orderTypeLower = StringToLowerCustom(sig.order_type);
  bool isBuyOrder = (StringFind(orderTypeLower, "buy") >= 0);
  bool isSellOrder = (StringFind(orderTypeLower, "sell") >= 0);
  bool isMarketOrder = false;
  bool isLimitOrder = false;
  bool isStopOrder = false;

  if (isBuyOrder || isSellOrder)
  {
    if (StringFind(orderTypeLower, "limit") >= 0) isLimitOrder = true;
    else if (StringFind(orderTypeLower, "stop") >= 0) isStopOrder = true;
    else if (StringFind(orderTypeLower, "market") >= 0 || orderTypeLower == "buy" || orderTypeLower == "sell")
      isMarketOrder = true;
    else isMarketOrder = true;
  }
  else return;

  bool isBuy = isBuyOrder;
  double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
  double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
  double currentMarketPrice = isBuyOrder ? ask : bid;
  double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

  double sl_price = 0;
  if (sig.sl_count > 0 && sig.sl_list[0] > 0) sl_price = sig.sl_list[0];
  else
  {
    double pips = settings.default_sl_pips;
    if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN) pips = pips * 10.0;
    else if (symType == SYMBOL_TYPE_FOREX) pips = pips / 10.0;

    double dist = pips * point;
    sl_price = isBuy ? currentMarketPrice - dist : currentMarketPrice + dist;
  }

  double distSL = MathAbs(currentMarketPrice - sl_price);
  double totalLot = NormalizeLotToSymbol(CalculatePositionSize(symbol, totalRiskMoney, distSL), symbol);
  if (totalLot > settings.max_lot) totalLot = settings.max_lot;

  double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
  if (minLot <= 0) minLot = 0.01;

  int firstMarketIndex = -1;
  int marketEntries = 0;
  int pendingEntries = 0;

  if (isMarketOrder)
  {
    for (int i = 0; i < sig.prices_count; i++)
    {
      double entryPrice = sig.prices_list[i];
      if (entryPrice <= 0) continue;

      double gapPoints = MathAbs(entryPrice - currentMarketPrice) / point;
      double gapPips = gapPoints;
      
      if (symType == SYMBOL_TYPE_GOLD || symType == SYMBOL_TYPE_BITCOIN) gapPips = gapPoints / 10.0;
      else if (symType == SYMBOL_TYPE_FOREX) gapPips = gapPoints / 10.0;

      if (gapPips <= settings.max_slippage_pips)
      {
        if (firstMarketIndex == -1) firstMarketIndex = i;
        marketEntries++;
      }
      else pendingEntries++;
    }
  }
  else pendingEntries = sig.prices_count;

  int totalExpectedPositions = 0;
  if (isMarketOrder && firstMarketIndex >= 0)
  {
    int marketPositions = sig.tp_count;
    int pendingPositions = (sig.prices_count - 1) * sig.tp_count;
    totalExpectedPositions = marketPositions + pendingPositions;
  }
  else totalExpectedPositions = sig.prices_count * sig.tp_count;

  if (totalExpectedPositions <= 0) return;

  double lotPerPosition = NormalizeLotToSymbol(totalLot / totalExpectedPositions, symbol);
  bool validSplitVolume = (lotPerPosition >= minLot);

  if (!validSplitVolume)
  {
    double pendingPrice = 0;
    if (sig.prices_count > 0 && sig.prices_list[0] > 0) pendingPrice = sig.prices_list[0];
    else pendingPrice = CalculatePendingPrice(sig.order_type, sl_price, currentMarketPrice, symbol, 
                                              settings.pending_distance_pips, symType, isBuy);

    double firstTP = GetFirstTP(sig, symbol, symType, settings, currentMarketPrice, isBuy,
                                sig.order_type, false, true);

    if (SendPendingOrder(symbol, sig.order_type, pendingPrice, sl_price, firstTP, totalLot, signalID))
    {
      successCount = 1;
      totalVolume = totalLot;
    }
    return;
  }

  int marketOrdersCreated = 0;
  int pendingOrdersCreated = 0;

  for (int priceIndex = 0; priceIndex < sig.prices_count; priceIndex++)
  {
    double entryPrice = sig.prices_list[priceIndex];
    if (entryPrice <= 0) continue;

    bool isThisMarketOrder = (isMarketOrder && priceIndex == firstMarketIndex);

    for (int tpIndex = 0; tpIndex < sig.tp_count; tpIndex++)
    {
      double tp_val = sig.tp_list[tpIndex];
      if (tp_val <= 0) tp_val = GetFirstTP(sig, symbol, symType, settings, currentMarketPrice, isBuy,
                                          sig.order_type, isThisMarketOrder, !isThisMarketOrder);

      if (isThisMarketOrder)
      {
        if (SendMarketOrder(symbol, sig.order_type, sl_price, tp_val, lotPerPosition, signalID))
        {
          successCount++;
          totalVolume += lotPerPosition;
          marketOrdersCreated++;
        }
      }
      else
      {
        if (SendPendingOrder(symbol, sig.order_type, entryPrice, sl_price, tp_val, lotPerPosition, signalID))
        {
          successCount++;
          totalVolume += lotPerPosition;
          pendingOrdersCreated++;
        }
      }
    }
  }
}

// ================ SIGNAL PROCESSING FUNCTIONS ================

void ProcessSignalFile()
{
  string file1 = SignalFileName + ".txt";
  string file2 = SignalFileName;

  int handle = INVALID_HANDLE;
  handle = FileOpen(file1, FILE_READ | FILE_TXT | FILE_ANSI);
  if (handle == INVALID_HANDLE)
  {
    handle = FileOpen(file2, FILE_READ | FILE_TXT | FILE_ANSI);
    if (handle == INVALID_HANDLE) return;
  }

  string content = "";
  while (!FileIsEnding(handle)) content += FileReadString(handle);
  FileClose(handle);

  FileDelete(file1);
  FileDelete(file2);

  content = NormalizeContentLines(content);
  content = StringTrimCustom(content);
  if (StringLen(content) < 5) return;

  SignalData sig;
  if (!ParseJsonContent(content, sig)) return;

  if (sig.prices_count == 0) return;
  if (sig.tp_count == 0)
  {
    sig.tp_count = 1;
    ArrayResize(sig.tp_list, 1);
    sig.tp_list[0] = 0;
  }
  if (StringLen(sig.order_type) == 0) return;

  string symbol = sig.currency;
  if (StringLen(symbol) == 0 || symbol == "null") symbol = DefaultSymbol;
  StringReplace(symbol, "\"", "");
  StringReplace(symbol, "'", "");
  symbol = StringTrimCustom(symbol);

  if (!SymbolSelect(symbol, true))
  {
    symbol = DefaultSymbol;
    SymbolSelect(symbol, true);
  }

  if (StringLen(sig.signal_id) == 0) sig.signal_id = IntegerToString((long)TimeCurrent());

  ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);
  if (EnableTelegram) SendSignalEntryReport(sig, symbol, symType);

  SymbolSettings settings = GetSymbolSettings(symType);
  double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
  double totalRiskMoney = accountBalance * RiskPercentPerSignal / 100.0;

  if (EnableGlobalRiskLimit && !CheckGlobalRiskLimit(totalRiskMoney)) return;

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
  ProcessSignalWithSmartLogic(sig, symbol, symType, settings, totalRiskMoney, sig.signal_id, successCount, totalExecutedVolume);

  if (EnableTelegram && successCount > 0)
    SendExecutionReport(sig.signal_id, symbol, sig.order_type, sig.tp_count, successCount,
                        totalExecutedVolume, false, false, 0, symType);
}

void CreateHtmlDashboard()
{
  string html = "";
  html += "<!DOCTYPE html>";
  html += "<html lang='en' dir='ltr'>";
  html += "<head>";
  html += "<meta charset='UTF-8'>";
  html += "<meta name='viewport' content='width=device-width, initial-scale=1.0'>";
  html += "<meta http-equiv='refresh' content='10'>";
  html += "<title>SignalExecutor Dashboard</title>";
  html += "<style>";
  html += "* { margin: 0; padding: 0; box-sizing: border-box; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }";
  html += "body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }";
  html += ".container { max-width: 1400px; margin: 0 auto; }";
  html += ".header { background: rgba(255, 255, 255, 0.95); padding: 25px; border-radius: 15px; margin-bottom: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }";
  html += ".positions-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 20px; }";
  html += ".position-card { background: rgba(255, 255, 255, 0.95); border-radius: 15px; padding: 20px; box-shadow: 0 5px 15px rgba(0,0,0,0.08); }";
  html += ".no-positions { text-align: center; padding: 40px; background: rgba(255, 255,255, 0.95); border-radius: 15px; color: #6b7280; }";
  html += ".footer { text-align: center; margin-top: 30px; color: rgba(255, 255, 255, 0.8); font-size: 14px; }";
  html += "</style>";
  html += "</head>";
  html += "<body>";
  html += "<div class='container'>";
  html += "<div class='header'><h1>SignalExecutor Dashboard</h1></div>";

  int totalPositions = PositionsTotal();
  if (totalPositions > 0)
  {
    html += "<div class='positions-grid'>";
    for (int i = 0; i < totalPositions; i++)
    {
      ulong ticket = PositionGetTicket(i);
      if (!PositionSelectByTicket(ticket)) continue;

      string symbol = PositionGetString(POSITION_SYMBOL);
      double volume = PositionGetDouble(POSITION_VOLUME);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      double profit = PositionGetDouble(POSITION_PROFIT);
      long type = PositionGetInteger(POSITION_TYPE);
      bool isBuy = (type == POSITION_TYPE_BUY);

      html += "<div class='position-card'>";
      html += "<div><strong>" + symbol + "</strong> (" + (isBuy ? "BUY" : "SELL") + " " + DoubleToString(volume, 2) + ")</div>";
      html += "<div>Entry: " + DoubleToString(entryPrice, 5) + "</div>";
      html += "<div>Current: " + DoubleToString(currentPrice, 5) + "</div>";
      html += "<div>Profit: <span style='color:" + (profit >= 0 ? "green" : "red") + "'>$" + DoubleToString(profit, 2) + "</span></div>";
      html += "</div>";
    }
    html += "</div>";
  }
  else
  {
    html += "<div class='no-positions'>";
    html += "<h2>No Open Positions</h2>";
    html += "<p>There are currently no open positions to display.</p>";
    html += "</div>";
  }

  html += "<div class='footer'>";
  html += "Last Updated: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
  html += " | SignalExecutor v1.95";
  html += "</div>";
  html += "</div>";
  html += "</body>";
  html += "</html>";

  string filename = "dashboard.html";
  int handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_ANSI);
  if (handle != INVALID_HANDLE)
  {
    FileWrite(handle, html);
    FileClose(handle);
  }
}
//+------------------------------------------------------------------+