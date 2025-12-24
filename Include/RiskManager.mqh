//+------------------------------------------------------------------+
//| RiskManager.mqh                                                  |
//| Risk Management Module - Fixed Comment Issue                    |
//| Version: 1.96                                                   |
//+------------------------------------------------------------------+
#property copyright "Generated for mehradgit"
#property version "1.96"
#property strict

#include <Trade\Trade.mqh>

// ================ INPUT PARAMETERS ================

input group "Risk Management Stages - GOLD" 
input int Gold_Stage1_Pips = 2;
input double Gold_Stage1_ClosePercent = 10.0;
input int Gold_Stage2_Pips = 4;
input double Gold_Stage2_ClosePercent = 15.0;
input int Gold_Stage2_BreakEvenPips = 5;
input int Gold_Stage3_Pips = 25;
input double Gold_Stage3_ClosePercent = 20.0;
input int Gold_TrailingStopPips = 10;
input int Gold_GlobalRiskFreePips = 30;
input int Gold_RiskFreeDistance = 10;
input int Gold_ClosePendingAtProfit = 15;

input group "Risk Management Stages - DOW JONES" 
input int Dow_Stage1_Pips = 15;
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

input group "Risk Management Stages - NASDAQ" 
input int Nas_Stage1_Pips = 20;
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

input group "Risk Management Stages - BITCOIN" 
input int Btc_Stage1_Pips = 100;
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

input group "Risk Management Stages - FOREX" 
input int Forex_Stage1_Pips = 8;
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

input group "Retry Settings" 
input int MaxRetryAttempts_Stage1 = 15;
input int MaxRetryAttempts_Stage2 = 15;
input int MaxRetryAttempts_Stage3 = 15;
input int RetryDelaySeconds = 45;

input group "Risk Management Settings"
input bool EnableRiskManagement = true;

// ================ STRUCTURES ================

struct RiskManagementSettings
{
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

struct PositionInfo
{
  ulong ticket;
  string symbol;
  long magic;
  double open_price;
  double open_time;
  string signal_id;
  datetime stored_time;
};

struct PositionRiskData
{
  string position_id;      // شناسه منحصربه‌فرد پوزیشن
  ulong ticket;           // Ticket فعلی
  string signal_id;       // Signal ID اصلی
  double entry_price;
  double original_sl;
  double original_tp;
  double current_sl;
  int stage_completed;
  bool risk_free_active;
  double best_price;
  datetime last_check;
  bool pending_closed;
  
  bool stage_in_progress[4];
  datetime stage_start_time[4];
  int stage_attempt_count[4];
  int stage_max_attempts[4];
};

// ================ CLASS CRiskManager ================

class CRiskManager
{
private:
  CTrade m_trade;
  PositionRiskData m_risk_data_array[200];  // افزایش ظرفیت
  int m_risk_data_count;
  PositionInfo m_position_info_array[200];  // برای ذخیره اطلاعات پوزیشن
  int m_position_info_count;
  
  long m_magic_number;
  bool m_risk_management_enabled;
  bool m_enable_telegram;
  bool m_debug_logging;
  string m_telegram_bot_token;
  string m_telegram_chat_id;
  
  RiskManagementSettings m_gold_settings;
  RiskManagementSettings m_dow_settings;
  RiskManagementSettings m_nas_settings;
  RiskManagementSettings m_btc_settings;
  RiskManagementSettings m_forex_settings;
  
  // Private methods
  RiskManagementSettings GetRiskSettings(int symType);
  double CalculatePipsProfit(double entryPrice, double currentPrice, bool isBuy, string symbol, int symType);
  bool ClosePartialPosition(ulong ticket, double percent, string reason);
  void MoveToBreakEven(ulong ticket, double entryPrice, int breakEvenPips, bool isBuy, string symbol, int symType);
  void ApplyTrailingStop(ulong ticket, double currentPrice, int trailingPips, bool isBuy, string symbol, int symType);
  void ApplyGlobalRiskFree(ulong ticket, double entryPrice, int riskFreePips, int riskFreeDistance, bool isBuy, string symbol, int symType);
  void ProcessStageWithRetry(ulong ticket, int riskIndex, int stage, double profitPips, double closePercent,
                           string reason, string symbol, bool isBuy, double currentPrice, double entryPrice,
                           string signalID, int symType);
  void SendTelegramMessage(string message);
  void SendRiskManagementAlert(string symbol, string signalID, int stage, string action, double profitPips, double closedPercent);
  void SendStageAttemptAlert(string symbol, string signalID, int stage, int attempt, double profitPips, string status);
  void SendStageRetryAlert(string symbol, string signalID, int stage, int attempt, double profitPips);
  void UpdateRiskDataForPosition(int riskIndex, double currentPrice, bool isBuy);
  
  // Helper methods
  string GeneratePositionID(string symbol, long magic, double openPrice, datetime openTime);
  int GetSymbolType(string symbol);
  string StringToLowerCustom(string str);
  void DebugLog(string message);
  
  // Position tracking methods
  void StorePositionInfo(ulong ticket, string symbol, long magic, double openPrice, double sl, double tp, string signalID);
  string FindSignalIDForPosition(ulong ticket);
  int FindRiskIndexByPositionID(string positionID);
  int FindRiskIndexByTicket(ulong ticket);
  
public:
  CRiskManager();
  ~CRiskManager();
  
  // Public methods
  void InitializeRiskManagementSettings();
  void StorePositionInfo(ulong ticket, string symbol, long magic, double openPrice, double sl, double tp, string signalID);
  void InitializeRiskDataForPosition(ulong ticket, string signalID, double entryPrice, double slPrice, double tpPrice);
  void ManageRiskForPosition(ulong ticket, string symbol);
  void ManageRiskForAllPositions();
  void SetMagicNumber(long magic) { m_magic_number = magic; }
  void SetTelegramSettings(bool enable, string botToken, string chatID);
  void SetRiskManagementEnabled(bool enable) { m_risk_management_enabled = enable; }
  void EnableDebugLogging(bool enable) { m_debug_logging = enable; }
  bool IsRiskManagementEnabled() { return m_risk_management_enabled; }
  
  // Helper methods
  void ClosePendingOrdersForSignal(string signalID, string reason);
};

// ================ CRiskManager IMPLEMENTATION ================

CRiskManager::CRiskManager()
{
  m_risk_data_count = 0;
  m_position_info_count = 0;
  m_magic_number = 0;
  m_risk_management_enabled = true;
  m_enable_telegram = false;
  m_debug_logging = false;
  m_telegram_bot_token = "";
  m_telegram_chat_id = "";
  
  InitializeRiskManagementSettings();
}

CRiskManager::~CRiskManager()
{
  // Cleanup
}

void CRiskManager::DebugLog(string message)
{
  if (m_debug_logging)
    Print("[RiskManager] ", message);
}

void CRiskManager::InitializeRiskManagementSettings()
{
  m_gold_settings.stage1_pips = Gold_Stage1_Pips;
  m_gold_settings.stage1_close_percent = Gold_Stage1_ClosePercent;
  m_gold_settings.stage2_pips = Gold_Stage2_Pips;
  m_gold_settings.stage2_close_percent = Gold_Stage2_ClosePercent;
  m_gold_settings.stage2_breakeven_pips = Gold_Stage2_BreakEvenPips;
  m_gold_settings.stage3_pips = Gold_Stage3_Pips;
  m_gold_settings.stage3_close_percent = Gold_Stage3_ClosePercent;
  m_gold_settings.trailing_stop_pips = Gold_TrailingStopPips;
  m_gold_settings.global_riskfree_pips = Gold_GlobalRiskFreePips;
  m_gold_settings.riskfree_distance = Gold_RiskFreeDistance;
  m_gold_settings.close_pending_at_profit = Gold_ClosePendingAtProfit;

  m_dow_settings.stage1_pips = Dow_Stage1_Pips;
  m_dow_settings.stage1_close_percent = Dow_Stage1_ClosePercent;
  m_dow_settings.stage2_pips = Dow_Stage2_Pips;
  m_dow_settings.stage2_close_percent = Dow_Stage2_ClosePercent;
  m_dow_settings.stage2_breakeven_pips = Dow_Stage2_BreakEvenPips;
  m_dow_settings.stage3_pips = Dow_Stage3_Pips;
  m_dow_settings.stage3_close_percent = Dow_Stage3_ClosePercent;
  m_dow_settings.trailing_stop_pips = Dow_TrailingStopPips;
  m_dow_settings.global_riskfree_pips = Dow_GlobalRiskFreePips;
  m_dow_settings.riskfree_distance = Dow_RiskFreeDistance;
  m_dow_settings.close_pending_at_profit = Dow_ClosePendingAtProfit;

  m_nas_settings.stage1_pips = Nas_Stage1_Pips;
  m_nas_settings.stage1_close_percent = Nas_Stage1_ClosePercent;
  m_nas_settings.stage2_pips = Nas_Stage2_Pips;
  m_nas_settings.stage2_close_percent = Nas_Stage2_ClosePercent;
  m_nas_settings.stage2_breakeven_pips = Nas_Stage2_BreakEvenPips;
  m_nas_settings.stage3_pips = Nas_Stage3_Pips;
  m_nas_settings.stage3_close_percent = Nas_Stage3_ClosePercent;
  m_nas_settings.trailing_stop_pips = Nas_TrailingStopPips;
  m_nas_settings.global_riskfree_pips = Nas_GlobalRiskFreePips;
  m_nas_settings.riskfree_distance = Nas_RiskFreeDistance;
  m_nas_settings.close_pending_at_profit = Nas_ClosePendingAtProfit;

  m_btc_settings.stage1_pips = Btc_Stage1_Pips;
  m_btc_settings.stage1_close_percent = Btc_Stage1_ClosePercent;
  m_btc_settings.stage2_pips = Btc_Stage2_Pips;
  m_btc_settings.stage2_close_percent = Btc_Stage2_ClosePercent;
  m_btc_settings.stage2_breakeven_pips = Btc_Stage2_BreakEvenPips;
  m_btc_settings.stage3_pips = Btc_Stage3_Pips;
  m_btc_settings.stage3_close_percent = Btc_Stage3_ClosePercent;
  m_btc_settings.trailing_stop_pips = Btc_TrailingStopPips;
  m_btc_settings.global_riskfree_pips = Btc_GlobalRiskFreePips;
  m_btc_settings.riskfree_distance = Btc_RiskFreeDistance;
  m_btc_settings.close_pending_at_profit = Btc_ClosePendingAtProfit;

  m_forex_settings.stage1_pips = Forex_Stage1_Pips;
  m_forex_settings.stage1_close_percent = Forex_Stage1_ClosePercent;
  m_forex_settings.stage2_pips = Forex_Stage2_Pips;
  m_forex_settings.stage2_close_percent = Forex_Stage2_ClosePercent;
  m_forex_settings.stage2_breakeven_pips = Forex_Stage2_BreakEvenPips;
  m_forex_settings.stage3_pips = Forex_Stage3_Pips;
  m_forex_settings.stage3_close_percent = Forex_Stage3_ClosePercent;
  m_forex_settings.trailing_stop_pips = Forex_TrailingStopPips;
  m_forex_settings.global_riskfree_pips = Forex_GlobalRiskFreePips;
  m_forex_settings.riskfree_distance = Forex_RiskFreeDistance;
  m_forex_settings.close_pending_at_profit = Forex_ClosePendingAtProfit;
}

RiskManagementSettings CRiskManager::GetRiskSettings(int symType)
{
  RiskManagementSettings settings;
  
  switch (symType)
  {
  case 0: // SYMBOL_TYPE_GOLD
    settings = m_gold_settings;
    break;
    
  case 1: // SYMBOL_TYPE_DOW
    settings = m_dow_settings;
    break;
    
  case 2: // SYMBOL_TYPE_NASDAQ
    settings = m_nas_settings;
    break;
    
  case 3: // SYMBOL_TYPE_BITCOIN
    settings = m_btc_settings;
    break;
    
  case 4: // SYMBOL_TYPE_FOREX
  default:
    settings = m_forex_settings;
    break;
  }
  
  return settings;
}

// ================ POSITION TRACKING METHODS ================

void CRiskManager::StorePositionInfo(ulong ticket, string symbol, long magic, 
                                    double openPrice, double sl, double tp, string signalID)
{
  // حذف ورژن‌های قدیمی همین پوزیشن
  for (int i = 0; i < m_position_info_count; i++)
  {
    if (m_position_info_array[i].symbol == symbol && 
        m_position_info_array[i].magic == magic &&
        MathAbs(m_position_info_array[i].open_price - openPrice) < 0.00001)
    {
      // به‌روزرسانی ticket و زمان
      m_position_info_array[i].ticket = ticket;
      m_position_info_array[i].signal_id = signalID;
      m_position_info_array[i].stored_time = TimeCurrent();
      DebugLog("Updated position info for ticket: " + IntegerToString(ticket));
      return;
    }
  }
  
  // اضافه کردن جدید
  if (m_position_info_count < ArraySize(m_position_info_array))
  {
    m_position_info_array[m_position_info_count].ticket = ticket;
    m_position_info_array[m_position_info_count].symbol = symbol;
    m_position_info_array[m_position_info_count].magic = magic;
    m_position_info_array[m_position_info_count].open_price = openPrice;
    m_position_info_array[m_position_info_count].open_time = TimeCurrent();
    m_position_info_array[m_position_info_count].signal_id = signalID;
    m_position_info_array[m_position_info_count].stored_time = TimeCurrent();
    
    m_position_info_count++;
    DebugLog("Stored new position info for ticket: " + IntegerToString(ticket) + 
             " | Signal: " + signalID);
  }
}

string CRiskManager::FindSignalIDForPosition(ulong ticket)
{
  // اول از ticket جستجو کن
  for (int i = 0; i < m_position_info_count; i++)
  {
    if (m_position_info_array[i].ticket == ticket)
    {
      DebugLog("Found signal ID by ticket: " + m_position_info_array[i].signal_id);
      return m_position_info_array[i].signal_id;
    }
  }
  
  // اگر ticket پیدا نشد، از مشخصات پوزیشن جستجو کن
  if (PositionSelectByTicket(ticket))
  {
    string symbol = PositionGetString(POSITION_SYMBOL);
    long magic = PositionGetInteger(POSITION_MAGIC);
    double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    
    for (int i = 0; i < m_position_info_count; i++)
    {
      if (m_position_info_array[i].symbol == symbol && 
          m_position_info_array[i].magic == magic &&
          MathAbs(m_position_info_array[i].open_price - openPrice) < 0.00001)
      {
        // به‌روزرسانی ticket
        m_position_info_array[i].ticket = ticket;
        DebugLog("Found signal ID by position details: " + m_position_info_array[i].signal_id);
        return m_position_info_array[i].signal_id;
      }
    }
  }
  
  DebugLog("Signal ID NOT FOUND for ticket: " + IntegerToString(ticket));
  return "";
}

string CRiskManager::GeneratePositionID(string symbol, long magic, double openPrice, datetime openTime)
{
  // ایجاد یک شناسه منحصربه‌فرد برای پوزیشن
  return symbol + "_" + 
         IntegerToString(magic) + "_" + 
         DoubleToString(openPrice, 5) + "_" + 
         IntegerToString(openTime);
}

int CRiskManager::FindRiskIndexByPositionID(string positionID)
{
  for (int i = 0; i < m_risk_data_count; i++)
  {
    if (m_risk_data_array[i].position_id == positionID)
    {
      DebugLog("Found risk index by position ID: " + IntegerToString(i));
      return i;
    }
  }
  
  DebugLog("Risk index NOT FOUND for position ID: " + positionID);
  return -1;
}

int CRiskManager::FindRiskIndexByTicket(ulong ticket)
{
  if (!PositionSelectByTicket(ticket)) return -1;
  
  string symbol = PositionGetString(POSITION_SYMBOL);
  long magic = PositionGetInteger(POSITION_MAGIC);
  double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
  datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
  
  string positionID = GeneratePositionID(symbol, magic, openPrice, openTime);
  
  return FindRiskIndexByPositionID(positionID);
}

// ================ RISK MANAGEMENT METHODS ================

void CRiskManager::InitializeRiskDataForPosition(ulong ticket, string signalID, 
                                                double entryPrice, double slPrice, double tpPrice)
{
  if (!PositionSelectByTicket(ticket)) 
  {
    DebugLog("Cannot initialize risk data - cannot select position: " + IntegerToString(ticket));
    return;
  }
  
  string symbol = PositionGetString(POSITION_SYMBOL);
  long magic = PositionGetInteger(POSITION_MAGIC);
  datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
  
  string positionID = GeneratePositionID(symbol, magic, entryPrice, openTime);
  
  // بررسی آیا از قبل وجود دارد
  int existingIndex = FindRiskIndexByPositionID(positionID);
  if (existingIndex >= 0)
  {
    // به‌روزرسانی ticket و signalID
    m_risk_data_array[existingIndex].ticket = ticket;
    m_risk_data_array[existingIndex].signal_id = signalID;
    DebugLog("Updated existing risk data for position ID: " + positionID);
    return;
  }
  
  // ایجاد جدید
  if (m_risk_data_count < ArraySize(m_risk_data_array))
  {
    m_risk_data_array[m_risk_data_count].position_id = positionID;
    m_risk_data_array[m_risk_data_count].ticket = ticket;
    m_risk_data_array[m_risk_data_count].signal_id = signalID;
    m_risk_data_array[m_risk_data_count].entry_price = entryPrice;
    m_risk_data_array[m_risk_data_count].original_sl = slPrice;
    m_risk_data_array[m_risk_data_count].original_tp = tpPrice;
    m_risk_data_array[m_risk_data_count].current_sl = slPrice;
    m_risk_data_array[m_risk_data_count].stage_completed = 0;
    m_risk_data_array[m_risk_data_count].risk_free_active = false;
    m_risk_data_array[m_risk_data_count].best_price = entryPrice;
    m_risk_data_array[m_risk_data_count].last_check = TimeCurrent();
    m_risk_data_array[m_risk_data_count].pending_closed = false;

    for (int s = 0; s < 4; s++)
    {
      m_risk_data_array[m_risk_data_count].stage_in_progress[s] = false;
      m_risk_data_array[m_risk_data_count].stage_start_time[s] = 0;
      m_risk_data_array[m_risk_data_count].stage_attempt_count[s] = 0;
      if (s == 1) m_risk_data_array[m_risk_data_count].stage_max_attempts[s] = MaxRetryAttempts_Stage1;
      else if (s == 2) m_risk_data_array[m_risk_data_count].stage_max_attempts[s] = MaxRetryAttempts_Stage2;
      else if (s == 3) m_risk_data_array[m_risk_data_count].stage_max_attempts[s] = MaxRetryAttempts_Stage3;
      else m_risk_data_array[m_risk_data_count].stage_max_attempts[s] = 5;
    }

    m_risk_data_count++;
    DebugLog("Initialized new risk data for ticket: " + IntegerToString(ticket) + 
             " | Position ID: " + positionID + 
             " | Signal: " + signalID);
  }
  else
  {
    DebugLog("ERROR: Risk data array is full!");
  }
}

void CRiskManager::ManageRiskForAllPositions()
{
  if (!m_risk_management_enabled) return;
  
  DebugLog("=== Starting risk management cycle ===");
  
  // جمع‌آوری همه tickets قبل از iteration
  ulong tickets[];
  int totalPositions = PositionsTotal();
  ArrayResize(tickets, totalPositions);
  
  for (int i = 0; i < totalPositions; i++)
  {
    tickets[i] = PositionGetTicket(i);
  }
  
  // مدیریت ریسک برای هر ticket
  for (int i = 0; i < totalPositions; i++)
  {
    ulong ticket = tickets[i];
    if (ticket <= 0) continue;
    
    if (!PositionSelectByTicket(ticket)) continue;
    
    long magic = PositionGetInteger(POSITION_MAGIC);
    if (magic != m_magic_number) continue;
    
    string symbol = PositionGetString(POSITION_SYMBOL);
    
    ManageRiskForPosition(ticket, symbol);
  }
  
  DebugLog("=== Finished risk management cycle ===");
}

void CRiskManager::ManageRiskForPosition(ulong ticket, string symbol)
{
  if (!m_risk_management_enabled) return;
  
  DebugLog("Managing risk for ticket: " + IntegerToString(ticket) + " | Symbol: " + symbol);
  
  if (!PositionSelectByTicket(ticket)) 
  {
    DebugLog("ERROR: Cannot select position: " + IntegerToString(ticket));
    return;
  }

  double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
  double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
  long position_type = PositionGetInteger(POSITION_TYPE);
  bool isBuy = (position_type == POSITION_TYPE_BUY);
  
  // پیدا کردن signalID
  string signalID = "";
  
  // اول از کامنت تلاش کن
  string comment = PositionGetString(POSITION_COMMENT);
  DebugLog("Position comment: " + comment);
  
  int sidPos = StringFind(comment, "SID:");
  if (sidPos >= 0)
  {
    string idPart = StringSubstr(comment, sidPos + 4);
    int space = StringFind(idPart, " ");
    if (space > 0) signalID = StringSubstr(idPart, 0, space);
    else signalID = idPart;
    DebugLog("Signal ID from comment: " + signalID);
  }
  
  // اگر از کامنت پیدا نشد، از position info جستجو کن
  if (signalID == "")
  {
    signalID = FindSignalIDForPosition(ticket);
    if (signalID != "")
      DebugLog("Signal ID from stored info: " + signalID);
  }
  
  // اگر باز هم پیدا نشد، از position ID استفاده کن
  if (signalID == "")
  {
    long magic = PositionGetInteger(POSITION_MAGIC);
    datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
    signalID = "POS_" + GeneratePositionID(symbol, magic, entryPrice, openTime);
    DebugLog("Generated signal ID: " + signalID);
  }
  
  int symType = GetSymbolType(symbol);
  double profitPips = CalculatePipsProfit(entryPrice, currentPrice, isBuy, symbol, symType);
  
  DebugLog("Profit pips: " + DoubleToString(profitPips, 2) + 
           " | Entry: " + DoubleToString(entryPrice, 5) + 
           " | Current: " + DoubleToString(currentPrice, 5));
  
  // پیدا کردن risk index
  int riskIndex = FindRiskIndexByTicket(ticket);
  
  if (riskIndex == -1)
  {
    DebugLog("Risk index not found, initializing...");
    InitializeRiskDataForPosition(ticket, signalID, entryPrice,
                                  PositionGetDouble(POSITION_SL),
                                  PositionGetDouble(POSITION_TP));
    
    // دوباره سعی کن پیدا کنی
    riskIndex = FindRiskIndexByTicket(ticket);
    if (riskIndex == -1)
    {
      DebugLog("ERROR: Still cannot find risk index after initialization!");
      return;
    }
  }
  
  DebugLog("Risk index: " + IntegerToString(riskIndex) + 
           " | Stage completed: " + IntegerToString(m_risk_data_array[riskIndex].stage_completed));
  
  UpdateRiskDataForPosition(riskIndex, currentPrice, isBuy);
  
  RiskManagementSettings riskSettings = GetRiskSettings(symType);
  
  if (profitPips <= 0)
  {
    int completedStage = m_risk_data_array[riskIndex].stage_completed;
    for (int s = completedStage + 1; s <= 3; s++)
    {
      if (m_risk_data_array[riskIndex].stage_in_progress[s])
      {
        m_risk_data_array[riskIndex].stage_in_progress[s] = false;
        m_risk_data_array[riskIndex].stage_attempt_count[s] = 0;
        DebugLog("Reset stage " + IntegerToString(s) + " due to negative profit");
      }
    }
    return;
  }
  
  // بررسی Global Risk-Free
  if (profitPips >= riskSettings.global_riskfree_pips && !m_risk_data_array[riskIndex].risk_free_active)
  {
    ApplyGlobalRiskFree(ticket, entryPrice, riskSettings.global_riskfree_pips,
                        riskSettings.riskfree_distance, isBuy, symbol, symType);
    m_risk_data_array[riskIndex].risk_free_active = true;
    m_risk_data_array[riskIndex].stage_completed = 3;

    if (m_enable_telegram)
      SendRiskManagementAlert(symbol, signalID, 4, "Global Risk-Free Activated", profitPips, 0);
    
    DebugLog("Global Risk-Free activated at " + DoubleToString(profitPips, 1) + " pips");
    return;
  }
  
  // بستن سفارشات معلق
  if (!m_risk_data_array[riskIndex].pending_closed &&
      profitPips >= riskSettings.close_pending_at_profit)
  {
    ClosePendingOrdersForSignal(signalID, "Profit target reached: " + DoubleToString(profitPips, 1) + " pips");
    m_risk_data_array[riskIndex].pending_closed = true;
    DebugLog("Pending orders closed at " + DoubleToString(profitPips, 1) + " pips");
  }
  
  // Stage 1
  if (profitPips >= riskSettings.stage1_pips && m_risk_data_array[riskIndex].stage_completed == 0)
  {
    DebugLog("Stage 1 conditions met. Profit: " + DoubleToString(profitPips, 1) + 
             " >= " + IntegerToString(riskSettings.stage1_pips));
    
    ProcessStageWithRetry(ticket, riskIndex, 1, profitPips, riskSettings.stage1_close_percent,
                          "Stage 1 Profit Taking", symbol, isBuy, currentPrice, entryPrice,
                          signalID, symType);
  }
  
  // Stage 2
  if (profitPips >= riskSettings.stage2_pips && m_risk_data_array[riskIndex].stage_completed == 1)
  {
    DebugLog("Stage 2 conditions met. Profit: " + DoubleToString(profitPips, 1) + 
             " >= " + IntegerToString(riskSettings.stage2_pips));
    
    ProcessStageWithRetry(ticket, riskIndex, 2, profitPips, riskSettings.stage2_close_percent,
                          "Stage 2 Profit Taking", symbol, isBuy, currentPrice, entryPrice,
                          signalID, symType);
  }
  
  // Stage 3
  if (profitPips >= riskSettings.stage3_pips && m_risk_data_array[riskIndex].stage_completed == 2)
  {
    DebugLog("Stage 3 conditions met. Profit: " + DoubleToString(profitPips, 1) + 
             " >= " + IntegerToString(riskSettings.stage3_pips));
    
    ProcessStageWithRetry(ticket, riskIndex, 3, profitPips, riskSettings.stage3_close_percent,
                          "Stage 3 Profit Taking", symbol, isBuy, currentPrice, entryPrice,
                          signalID, symType);
  }
  
  // Trailing Stop برای مراحل بعدی
  if (m_risk_data_array[riskIndex].stage_completed >= 3 && !m_risk_data_array[riskIndex].risk_free_active)
  {
    ApplyTrailingStop(ticket, m_risk_data_array[riskIndex].best_price,
                      riskSettings.trailing_stop_pips, isBuy, symbol, symType);
  }
}

// ================ OTHER METHODS (بدون تغییرات عمده) ================

void CRiskManager::UpdateRiskDataForPosition(int riskIndex, double currentPrice, bool isBuy)
{
  if (riskIndex < 0 || riskIndex >= m_risk_data_count) return;
  
  if (isBuy && currentPrice > m_risk_data_array[riskIndex].best_price)
    m_risk_data_array[riskIndex].best_price = currentPrice;
  else if (!isBuy && currentPrice < m_risk_data_array[riskIndex].best_price)
    m_risk_data_array[riskIndex].best_price = currentPrice;
  
  m_risk_data_array[riskIndex].last_check = TimeCurrent();
}

void CRiskManager::ProcessStageWithRetry(ulong ticket, int riskIndex, int stage, double profitPips, double closePercent,
                           string reason, string symbol, bool isBuy, double currentPrice, double entryPrice,
                           string signalID, int symType)
{
  if (riskIndex < 0 || riskIndex >= m_risk_data_count) return;
  if (m_risk_data_array[riskIndex].stage_completed >= stage) 
  {
    DebugLog("Stage " + IntegerToString(stage) + " already completed");
    return;
  }

  RiskManagementSettings riskSettings = GetRiskSettings(symType);
  int maxAttempts = 5;
  if (stage == 1) maxAttempts = MaxRetryAttempts_Stage1;
  else if (stage == 2) maxAttempts = MaxRetryAttempts_Stage2;
  else if (stage == 3) maxAttempts = MaxRetryAttempts_Stage3;

  if (!m_risk_data_array[riskIndex].stage_in_progress[stage])
  {
    m_risk_data_array[riskIndex].stage_in_progress[stage] = true;
    m_risk_data_array[riskIndex].stage_start_time[stage] = TimeCurrent();
    m_risk_data_array[riskIndex].stage_attempt_count[stage] = 0;
    DebugLog("Starting stage " + IntegerToString(stage));
  }

  if (m_risk_data_array[riskIndex].stage_attempt_count[stage] > 0 &&
      (TimeCurrent() - m_risk_data_array[riskIndex].stage_start_time[stage]) < RetryDelaySeconds)
  {
    DebugLog("Stage " + IntegerToString(stage) + " waiting for retry delay");
    return;
  }

  m_risk_data_array[riskIndex].stage_attempt_count[stage]++;
  int attemptCount = m_risk_data_array[riskIndex].stage_attempt_count[stage];

  DebugLog("Stage " + IntegerToString(stage) + " attempt " + IntegerToString(attemptCount) + 
           "/" + IntegerToString(maxAttempts));

  if (m_enable_telegram)
    SendStageAttemptAlert(symbol, signalID, stage, attemptCount, profitPips, "Attempting");

  bool success = ClosePartialPosition(ticket, closePercent,
                                      reason + " (Attempt " +
                                          IntegerToString(attemptCount) +
                                          "/" + IntegerToString(maxAttempts) + ")");

  if (success)
  {
    m_risk_data_array[riskIndex].stage_completed = stage;
    m_risk_data_array[riskIndex].stage_in_progress[stage] = false;
    m_risk_data_array[riskIndex].stage_attempt_count[stage] = 0;
    
    DebugLog("Stage " + IntegerToString(stage) + " completed successfully");
    DebugLog("Stage completed set to: " + IntegerToString(stage));

    if (stage == 2)
    {
      MoveToBreakEven(ticket, entryPrice, riskSettings.stage2_breakeven_pips, isBuy, symbol, symType);
      DebugLog("Break-even applied for stage 2");
    }
    else if (stage == 3)
    {
      ApplyTrailingStop(ticket, currentPrice, riskSettings.trailing_stop_pips, isBuy, symbol, symType);
      DebugLog("Trailing stop applied for stage 3");
    }

    if (m_enable_telegram)
      SendRiskManagementAlert(symbol, signalID, stage, "Stage Completed", profitPips, closePercent);
  }
  else
  {
    m_risk_data_array[riskIndex].stage_start_time[stage] = TimeCurrent();

    if (attemptCount >= maxAttempts)
    {
      m_risk_data_array[riskIndex].stage_in_progress[stage] = false;
      m_risk_data_array[riskIndex].stage_attempt_count[stage] = 0;
      m_risk_data_array[riskIndex].stage_completed = stage;
      
      DebugLog("Stage " + IntegerToString(stage) + " retry limit reached");
      
      if (m_enable_telegram)
        SendStageRetryAlert(symbol, signalID, stage, attemptCount, profitPips);
      
      return;
    }
    
    DebugLog("Stage " + IntegerToString(stage) + " failed, retrying...");
    
    if (m_enable_telegram)
      SendStageAttemptAlert(symbol, signalID, stage, attemptCount, profitPips, "Retrying");
  }
}

// ================ HELPER METHODS (بدون تغییر) ================

bool CRiskManager::ClosePartialPosition(ulong ticket, double percent, string reason)
{
  if (!PositionSelectByTicket(ticket)) 
  {
    DebugLog("Cannot close partial - cannot select ticket: " + IntegerToString(ticket));
    return false;
  }

  double volume = PositionGetDouble(POSITION_VOLUME);
  string symbol = PositionGetString(POSITION_SYMBOL);
  
  DebugLog("Closing partial position. Original volume: " + DoubleToString(volume, 2) + 
           " | Percent: " + DoubleToString(percent, 1) + "%");
  
  double closeVolume = MathFloor(volume * percent / 100.0 * 100) / 100;
  double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);

  if (closeVolume <= 0 || closeVolume < minLot) 
  {
    DebugLog("Close volume too small: " + DoubleToString(closeVolume, 2) + " min: " + DoubleToString(minLot, 2));
    return false;
  }

  // مطمئن شو closeVolume از volume اصلی کمتر است
  if (closeVolume >= volume)
  {
    closeVolume = volume * 0.9; // 90% ببند
    DebugLog("Adjusted close volume to: " + DoubleToString(closeVolume, 2));
  }

  DebugLog("Attempting to close " + DoubleToString(closeVolume, 2) + " lots");
  
  bool success = m_trade.PositionClosePartial(ticket, closeVolume);
  
  if (success)
  {
    DebugLog("SUCCESS: Partially closed ticket " + IntegerToString(ticket) + 
             " | Original: " + DoubleToString(volume, 2) + 
             " | Closed: " + DoubleToString(closeVolume, 2) + 
             " | Remaining: " + DoubleToString(volume - closeVolume, 2));
  }
  else
  {
    DebugLog("ERROR: Failed to close partial position for ticket " + IntegerToString(ticket));
  }
  
  return success;
}

// ... بقیه متدها (MoveToBreakEven, ApplyTrailingStop, ApplyGlobalRiskFree, 
// CalculatePipsProfit, GetSymbolType, StringToLowerCustom, SendTelegramMessage, 
// SendRiskManagementAlert, SendStageAttemptAlert, SendStageRetryAlert, 
// ClosePendingOrdersForSignal) همانند قبل بدون تغییرات اساسی

// فقط signature تابع ClosePendingOrdersForSignal را اضافه کن:
void CRiskManager::ClosePendingOrdersForSignal(string signalID, string reason)
{
  // پیاده‌سازی مانند قبل
  if (StringLen(signalID) == 0) return;

  int deletedOrders = 0;
  for (int i = OrdersTotal() - 1; i >= 0; i--)
  {
    ulong ticket = OrderGetTicket(i);
    if (ticket <= 0) continue;

    long magic = OrderGetInteger(ORDER_MAGIC);
    if (magic != m_magic_number) continue;

    string cmt = OrderGetString(ORDER_COMMENT);
    if (StringFind(cmt, "SID:" + signalID) >= 0)
    {
      m_trade.OrderDelete(ticket);
      deletedOrders++;
    }
  }

  if (deletedOrders > 0)
  {
    DebugLog("Pending Orders Closed | Signal: " + signalID + " | Reason: " + reason);
    if (m_enable_telegram)
      SendTelegramMessage("Pending Orders Closed | Signal: " + signalID + " | Reason: " + reason);
  }
}
//+------------------------------------------------------------------+