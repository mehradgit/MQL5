//+------------------------------------------------------------------+
//|                           MyTradeRobot.mq5                       |
//|                        Copyright 2024, YourName                  |
//+------------------------------------------------------------------+
#property copyright "Auto Trade Robot"
#property version   "4.0"
#property strict

//--- شامل کردن فایل‌ها
#include <MyTradeRobot/Config.mqh>
#include <MyTradeRobot/SignalParser.mqh>
#include <MyTradeRobot/OrderManager.mqh>
#include <MyTradeRobot/MoneyManager.mqh>
#include <MyTradeRobot/PositionManager.mqh>
#include <MyTradeRobot/Reporter.mqh>
#include <MyTradeRobot/Utils.mqh>

//--- اشیاء اصلی
CSignalParser   *signalParser;
COrderManager   *orderManager;
CPositionManager *positionManager;
CReporter       *reporter;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // ایجاد اشیاء
    signalParser = new CSignalParser();
    orderManager = new COrderManager();
    positionManager = new CPositionManager();
    reporter = new CReporter();
    
    // گزارش شروع
    reporter.ReportStart();
    
    // راه‌اندازی تایمر
    EventSetTimer(InpCheckInterval);
    
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // توقف تایمر
    EventKillTimer();
    
    // گزارش پایان
    reporter.ReportEnd(reason);
    
    // حذف اشیاء
    delete positionManager;
    delete orderManager;
    delete signalParser;
    delete reporter;
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    // 1. بررسی فایل سیگنال
    string content;
    if(signalParser.ReadFromFile(content))
    {
        SSignal signal;
        if(signalParser.ParseSignal(content, signal))
        {
            reporter.ReportSignal(signal);
            
            // اجرای سیگنال
            bool executed = orderManager->ExecuteSignal(signal);
            reporter.ReportOrder(executed, signal.commandType);
        }
    }
    
    // 2. مدیریت پوزیشن‌ها
    positionManager.ManagePositions();
    
    // 3. گزارش وضعیت
    reporter.ReportStatus();
}

//+------------------------------------------------------------------+
//| تابع Tick                                                       |
//+------------------------------------------------------------------+
void OnTick()
{
    // برای واکنش سریع به تغییرات قیمت
}

//+------------------------------------------------------------------+
//| تابع Trade                                                      |
//+------------------------------------------------------------------+
void OnTrade()
{
    // وقتی معامله‌ای اتفاق می‌افتد
    if(InpEnableLogging)
        Print("💱 رویداد معامله رخ داد");
}

//+------------------------------------------------------------------+
//|                                                  Config.mqh      |
//|                        Copyright 2024, YourName                  |
//+------------------------------------------------------------------+
#property strict

//--- پارامترهای ورودی اصلی
input string   InpFileName       = "output.txt";     // نام فایل سیگنال
input int      InpCheckInterval  = 1;                // فاصله چک (ثانیه)
input double   InpRiskPercent    = 1.0;              // درصد ریسک هر سیگنال
input double   InpMaxTotalRisk   = 5.0;              // حداکثر ریسک کلی (%)
input double   InpPipBuffer      = 2.0;              // بافر پیپ برای SL/TP
input bool     InpEnableLogging  = true;             // فعال‌سازی لاگ پیشرفته

//--- ساختار سیگنال
struct SSignal
{
    string   symbol;
    int      orderType;     // ORDER_TYPE_BUY, ORDER_TYPE_SELL
    string   commandType;   // "MARKET", "PENDING"
    double   entryPrices[]; // نقاط ورود
    double   takeProfits[]; // تیک پروفیت‌ها
    double   stopLoss;      // استاپ لاس
    string   rawText;       // متن اصلی
    datetime receiveTime;   // زمان دریافت
};

//--- مپینگ نمادها
string MapSymbol(string inputSymbol)
{
    string symbol = inputSymbol;
    StringToUpper(symbol);
    
    if(symbol == "GOLD") return "XAUUSD";
    if(symbol == "DAWOJONSE" || symbol == "YM") return "US30";
    if(symbol == "NQ100" || symbol == "NASDAQ") return "NAS100";
    
    return inputSymbol;
}

//--- تبدیل دلیل توقف به متن
string DeinitReasonToString(int reason)
{
    switch(reason)
    {
        case REASON_ACCOUNT:    return "تغییر حساب";
        case REASON_CHARTCHANGE:return "تغییر چارت";
        case REASON_CHARTCLOSE: return "بسته شدن چارت";
        case REASON_PARAMETERS: return "تغییر پارامترها";
        case REASON_RECOMPILE:  return "کامپایل مجدد";
        case REASON_REMOVE:     return "حذف ربات";
        case REASON_TEMPLATE:   return "تغییر تمپلیت";
        case REASON_INITFAILED: return "خطا در راه‌اندازی";
        default:                return "ناشناخته (" + IntegerToString(reason) + ")";
    }
}
//+------------------------------------------------------------------+
//|                                              MoneyManager.mqh    |
//|                        Copyright 2024, YourName                  |
//+------------------------------------------------------------------+
#include "Config.mqh"

class CMoneyManager
{
public:
    // محاسبه حجم
    double CalculateVolume(const SSignal &signal, double currentPrice)
    {
        if(signal.stopLoss <= 0)
        {
            Print("⚠️ استاپ لاس مشخص نشده. استفاده از حجم پیش‌فرض");
            return GetDefaultVolume(signal.symbol);
        }
        
        // محاسبه فاصله تا استاپ
        double stopDistance = CalculateStopDistance(signal, currentPrice);
        if(stopDistance <= 0)
            return GetDefaultVolume(signal.symbol);
        
        // محاسبه ریسک دلاری
        double riskAmount = CalculateRiskAmount();
        
        // تقسیم ریسک بین نقاط ورود
        riskAmount /= MathMax(1, ArraySize(signal.entryPrices));
        
        // محاسبه ارزش پیپ
        double pipValue = GetPipValue(signal.symbol, currentPrice);
        
        // محاسبه حجم
        double volume = riskAmount / (stopDistance * pipValue);
        
        // نرمالایز کردن حجم
        return NormalizeVolume(signal.symbol, volume);
    }
    
private:
    // محاسبه فاصله تا استاپ
    double CalculateStopDistance(const SSignal &signal, double currentPrice)
    {
        if(ArraySize(signal.entryPrices) > 0)
            return MathAbs(signal.entryPrices[0] - signal.stopLoss);
        else
            return MathAbs(currentPrice - signal.stopLoss);
    }
    
    // محاسبه ریسک دلاری
    double CalculateRiskAmount()
    {
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        return MathMin(balance, equity) * (InpRiskPercent / 100.0);
    }
    
    // محاسبه ارزش پیپ
    double GetPipValue(string symbol, double price)
    {
        if(StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "GOLD") >= 0)
            return 0.01;
        
        if(StringFind(symbol, "US30") >= 0 || StringFind(symbol, "NAS") >= 0)
            return 1.0;
        
        // برای جفت ارزها
        double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
        double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        
        if(tickSize > 0 && tickValue > 0)
            return (tickValue / tickSize) * point;
        
        return 0.0001; // مقدار پیش‌فرض
    }
    
    // حجم پیش‌فرض
    double GetDefaultVolume(string symbol)
    {
        double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
        return MathMax(minLot, 0.01);
    }
    
    // نرمالایز کردن حجم
    double NormalizeVolume(string symbol, double volume)
    {
        double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
        double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
        
        if(minLot <= 0) minLot = 0.01;
        if(maxLot <= 0) maxLot = 100.0;
        if(lotStep <= 0) lotStep = 0.01;
        
        // محدود کردن
        volume = MathMax(volume, minLot);
        volume = MathMin(volume, maxLot);
        
        // گرد کردن
        if(lotStep > 0)
            volume = MathRound(volume / lotStep) * lotStep;
        
        volume = NormalizeDouble(volume, 2);
        
        if(volume < minLot)
            volume = minLot;
        
        Print("📦 حجم نهایی: ", volume, " لات");
        return volume;
    }
};
//+------------------------------------------------------------------+
//|                                              OrderManager.mqh    |
//|                        Copyright 2024, YourName                  |
//+------------------------------------------------------------------+
#include "Config.mqh"
#include "MoneyManager.mqh"

class COrderManager
{
private:
    CMoneyManager m_moneyManager;
    int m_totalOrders;
    
public:
    COrderManager() : m_totalOrders(0) {}
    
    // اجرای سیگنال
    bool ExecuteSignal(const SSignal &signal)
    {
        if(!SymbolSelect(signal.symbol, true))
        {
            Print("❌ نماد ", signal.symbol, " پیدا نشد");
            return false;
        }
        
        // بررسی وضعیت معاملاتی نماد
        if(!CheckSymbolTradable(signal.symbol))
            return false;
        
        // دریافت قیمت جاری
        double currentPrice = GetCurrentPrice(signal);
        
        // محاسبه حجم
        double volume = m_moneyManager.CalculateVolume(signal, currentPrice);
        if(volume <= 0)
        {
            Print("❌ حجم محاسبه شده نامعتبر");
            return false;
        }
        
        // اجرای معامله
        bool success = false;
        if(signal.commandType == "MARKET")
            success = ExecuteMarketOrder(signal, currentPrice, volume);
        else if(signal.commandType == "PENDING")
            success = ExecutePendingOrder(signal, volume);
        
        if(success) m_totalOrders++;
        return success;
    }
    
    // دریافت تعداد کل معاملات
    int GetTotalOrders() const { return m_totalOrders; }
    
private:
    // بررسی وضعیت معاملاتی
    bool CheckSymbolTradable(string symbol)
    {
        long tradeMode = SymbolInfoInteger(symbol, SYMBOL_TRADE_MODE);
        if(tradeMode != SYMBOL_TRADE_MODE_FULL)
        {
            Print("❌ نماد ", symbol, " برای معامله فعال نیست");
            return false;
        }
        return true;
    }
    
    // دریافت قیمت جاری
    double GetCurrentPrice(const SSignal &signal)
    {
        if(signal.orderType == ORDER_TYPE_BUY || signal.orderType == ORDER_TYPE_BUY_LIMIT)
            return SymbolInfoDouble(signal.symbol, SYMBOL_ASK);
        else
            return SymbolInfoDouble(signal.symbol, SYMBOL_BID);
    }
    
    // اجرای سفارش مارکت
    bool ExecuteMarketOrder(const SSignal &signal, double currentPrice, double volume)
    {
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = signal.symbol;
        request.volume = volume;
        request.type = (ENUM_ORDER_TYPE)signal.orderType;
        request.price = GetCurrentPrice(signal);
        
        // تنظیم SL/TP
        SetStopLossTakeProfit(request, signal);
        
        request.deviation = 10;
        request.magic = GenerateMagic(signal, 1);
        request.comment = "AT_MKT_" + TimeToString(TimeCurrent(), TIME_SECONDS);
        request.type_time = ORDER_TIME_GTC;
        request.type_filling = ORDER_FILLING_IOC;
        
        if(OrderSend(request, result))
        {
            PrintOrderResult("مارکت", result, volume, request.price);
            return true;
        }
        else
        {
            PrintOrderError("مارکت", result);
            return false;
        }
    }
    
    // اجرای سفارش لیمیت
    bool ExecutePendingOrder(const SSignal &signal, double volume)
    {
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_PENDING;
        request.symbol = signal.symbol;
        request.volume = volume;
        request.type = (ENUM_ORDER_TYPE)signal.orderType;
        request.price = signal.entryPrices[0];
        
        // تنظیم SL/TP
        SetStopLossTakeProfit(request, signal);
        
        request.deviation = 0;
        request.magic = GenerateMagic(signal, 2);
        request.comment = "AT_LMT_" + TimeToString(TimeCurrent(), TIME_SECONDS);
        request.type_time = ORDER_TIME_GTC;
        request.type_filling = ORDER_FILLING_FOK;
        
        if(OrderSend(request, result))
        {
            PrintOrderResult("لیمیت", result, volume, request.price);
            return true;
        }
        else
        {
            PrintOrderError("لیمیت", result);
            return false;
        }
    }
    
    // تنظیم استاپ‌لس و تیک‌پروفیت
    void SetStopLossTakeProfit(MqlTradeRequest &request, const SSignal &signal)
    {
        double point = SymbolInfoDouble(signal.symbol, SYMBOL_POINT);
        int digits = (int)SymbolInfoInteger(signal.symbol, SYMBOL_DIGITS);
        
        if(signal.stopLoss > 0)
        {
            if(signal.orderType == ORDER_TYPE_BUY || signal.orderType == ORDER_TYPE_BUY_LIMIT)
                request.sl = NormalizeDouble(signal.stopLoss - (InpPipBuffer * point), digits);
            else
                request.sl = NormalizeDouble(signal.stopLoss + (InpPipBuffer * point), digits);
        }
        
        if(ArraySize(signal.takeProfits) > 0)
        {
            if(signal.orderType == ORDER_TYPE_BUY || signal.orderType == ORDER_TYPE_BUY_LIMIT)
                request.tp = NormalizeDouble(signal.takeProfits[0] + (InpPipBuffer * point), digits);
            else
                request.tp = NormalizeDouble(signal.takeProfits[0] - (InpPipBuffer * point), digits);
        }
    }
    
    // تولید عدد جادویی
    int GenerateMagic(const SSignal &signal, int type)
    {
        string base = signal.symbol + IntegerToString(type) + TimeToString(TimeCurrent(), TIME_SECONDS);
        int hash = 0;
        for(int i = 0; i < StringLen(base); i++)
            hash = hash * 31 + StringGetCharacter(base, i);
        return MathAbs(hash % 1000000);
    }
    
    // چاپ نتیجه سفارش
    void PrintOrderResult(string type, const MqlTradeResult &result, double volume, double price)
    {
        Print("✅ سفارش ", type, " اجرا شد");
        Print("   تیکت: ", result.order);
        Print("   حجم: ", DoubleToString(volume, 2));
        Print("   قیمت: ", DoubleToString(price, 5));
    }
    
    // چاپ خطای سفارش
    void PrintOrderError(string type, const MqlTradeResult &result)
    {
        Print("❌ خطا در سفارش ", type);
        Print("   کد خطا: ", result.retcode);
    }
};

//+------------------------------------------------------------------+
//|                                           PositionManager.mqh    |
//|                        Copyright 2024, YourName                  |
//+------------------------------------------------------------------+
#include "Config.mqh"

class CPositionManager
{
private:
    datetime m_lastCheck;
    
public:
    CPositionManager() : m_lastCheck(0) {}
    
    // مدیریت پوزیشن‌های باز
    void ManagePositions()
    {
        if(TimeCurrent() - m_lastCheck < 10) // هر 10 ثانیه
            return;
        
        m_lastCheck = TimeCurrent();
        
        int totalPositions = PositionsTotal();
        if(totalPositions == 0)
            return;
        
        double totalProfit = 0;
        double totalVolume = 0;
        
        for(int i = 0; i < totalPositions; i++)
        {
            ulong ticket = PositionGetTicket(i);
            if(PositionSelectByTicket(ticket))
            {
                double profit = PositionGetDouble(POSITION_PROFIT);
                double volume = PositionGetDouble(POSITION_VOLUME);
                string symbol = PositionGetString(POSITION_SYMBOL);
                string comment = PositionGetString(POSITION_COMMENT);
                
                totalProfit += profit;
                totalVolume += volume;
                
                // مدیریت پوزیشن ربات
                if(StringFind(comment, "AT_") >= 0)
                {
                    ManageRobotPosition(ticket, symbol, profit, volume, comment);
                }
            }
        }
        
        PrintPositionSummary(totalPositions, totalVolume, totalProfit);
        CheckRiskManagement();
    }
    
private:
    // مدیریت پوزیشن ربات
    void ManageRobotPosition(ulong ticket, string symbol, double profit, double volume, string comment)
    {
        // منطق مدیریت پوزیشن
        if(profit > 0)
        {
            ApplyProfitRules(ticket, symbol, profit, volume);
        }
    }
    
    // اعمال قوانین سود
    void ApplyProfitRules(ulong ticket, string symbol, double profit, double volume)
    {
        // اینجا می‌توانید منطق تریلینگ استاپ، سیو سود و ... را اضافه کنید
        // فعلاً فقط لاگ می‌کنیم
        
        if(InpEnableLogging)
        {
            Print("   📈 پوزیشن سودده: ", symbol, 
                  " | سود: $", DoubleToString(profit, 2),
                  " | حجم: ", DoubleToString(volume, 2));
        }
    }
    
    // چاپ خلاصه پوزیشن‌ها
    void PrintPositionSummary(int count, double volume, double profit)
    {
        if(InpEnableLogging)
        {
            Print("📊 وضعیت پوزیشن‌ها:");
            Print("   تعداد: ", count);
            Print("   حجم کل: ", DoubleToString(volume, 2));
            Print("   سود/ضرر کل: $", DoubleToString(profit, 2));
        }
    }
    
    // بررسی مدیریت ریسک
    void CheckRiskManagement()
    {
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        
        if(equity <= 0) return;
        
        double riskPercent = ((balance - equity) / balance) * 100;
        
        if(riskPercent > InpMaxTotalRisk)
        {
            Print("⚠️ هشدار: ریسک کلی ", DoubleToString(riskPercent, 1), 
                  "% بیش از حد مجاز ", DoubleToString(InpMaxTotalRisk, 1), "%");
        }
    }
};
//+------------------------------------------------------------------+
//|                                              SignalParser.mqh    |
//|                        Copyright 2024, YourName                  |
//+------------------------------------------------------------------+
#include "Config.mqh"

class CSignalParser
{
private:
    string m_lastContent;
    
public:
    // پردازش متن سیگنال
    bool ParseSignal(string text, SSignal &signal)
    {
        signal.rawText = text;
        StringToUpper(text);
        m_lastContent = text;
        
        // تشخیص نماد
        signal.symbol = DetectSymbol(text);
        if(signal.symbol == "")
        {
            Print("⚠️ خطا: نماد تشخیص داده نشد");
            return false;
        }
        
        // تشخیص نوع دستور
        if(!DetectOrderType(text, signal))
        {
            Print("⚠️ خطا: نوع دستور نامعتبر");
            return false;
        }
        
        // استخراج اعداد
        ExtractNumbers(text, signal);
        
        // اعتبارسنجی
        if(ArraySize(signal.entryPrices) == 0)
        {
            Print("⚠️ خطا: هیچ قیمت ورودی پیدا نشد");
            return false;
        }
        
        return true;
    }
    
    // خواندن از فایل
    bool ReadFromFile(string &content)
    {
        int handle = FileOpen(InpFileName, FILE_READ|FILE_TXT|FILE_SHARE_READ|FILE_COMMON);
        if(handle == INVALID_HANDLE) return false;
        
        content = "";
        while(!FileIsEnding(handle))
            content += FileReadString(handle) + "\n";
        FileClose(handle);
        
        FileDelete(InpFileName, FILE_COMMON);
        return StringLen(content) > 0;
    }
    
private:
    // تشخیص نماد
    string DetectSymbol(string text)
    {
        if(StringFind(text, "XAUUSD") >= 0 || StringFind(text, "GOLD") >= 0)
            return MapSymbol("XAUUSD");
        else if(StringFind(text, "US30") >= 0 || StringFind(text, "DAWOJONSE") >= 0 || StringFind(text, "YM") >= 0)
            return MapSymbol("US30");
        else if(StringFind(text, "NAS100") >= 0 || StringFind(text, "NQ100") >= 0 || StringFind(text, "NASDAQ") >= 0)
            return MapSymbol("NAS100");
        else if(StringFind(text, "EURUSD") >= 0)
            return "EURUSD";
        else if(StringFind(text, "GBPUSD") >= 0)
            return "GBPUSD";
        
        return "";
    }
    
    // تشخیص نوع دستور
    bool DetectOrderType(string text, SSignal &signal)
    {
        if(StringFind(text, "BUY LIMIT") >= 0 || StringFind(text, "BUYLIMIT") >= 0)
        {
            signal.orderType = ORDER_TYPE_BUY_LIMIT;
            signal.commandType = "PENDING";
        }
        else if(StringFind(text, "SELL LIMIT") >= 0 || StringFind(text, "SELLLIMIT") >= 0)
        {
            signal.orderType = ORDER_TYPE_SELL_LIMIT;
            signal.commandType = "PENDING";
        }
        else if(StringFind(text, "BUY") >= 0)
        {
            signal.orderType = ORDER_TYPE_BUY;
            signal.commandType = "MARKET";
        }
        else if(StringFind(text, "SELL") >= 0)
        {
            signal.orderType = ORDER_TYPE_SELL;
            signal.commandType = "MARKET";
        }
        else
        {
            return false;
        }
        return true;
    }
    
    // استخراج اعداد
    void ExtractNumbers(string text, SSignal &signal)
    {
        ArrayResize(signal.entryPrices, 0);
        ArrayResize(signal.takeProfits, 0);
        signal.stopLoss = 0;
        
        string lines[];
        int lineCount = StringSplit(text, '\n', lines);
        
        for(int l = 0; l < lineCount; l++)
        {
            string words[];
            int wordCount = StringSplit(lines[l], ' ', words);
            
            for(int w = 0; w < wordCount; w++)
            {
                string clean = CleanNumber(words[w]);
                if(clean != "")
                {
                    double value = StringToDouble(clean);
                    ClassifyNumber(value, lines[l], signal);
                }
            }
        }
        
        // استاپ خودکار اگر پیدا نشد
        if(signal.stopLoss == 0 && ArraySize(signal.entryPrices) > 0)
        {
            CalculateAutoStopLoss(signal);
        }
    }
    
    // تمیز کردن عدد
    string CleanNumber(string input)
    {
        string clean = "";
        bool hasDot = false;
        
        for(int i = 0; i < StringLen(input); i++)
        {
            string ch = StringSubstr(input, i, 1);
            if(ch >= "0" && ch <= "9")
                clean += ch;
            else if(ch == ".")
            {
                clean += ch;
                hasDot = true;
            }
        }
        
        return (hasDot && StringLen(clean) > 0) ? clean : "";
    }
    
    // طبقه‌بندی عدد
    void ClassifyNumber(double value, string line, SSignal &signal)
    {
        if(StringFind(line, "TP") >= 0 || StringFind(line, "Tp") >= 0)
        {
            int size = ArraySize(signal.takeProfits);
            ArrayResize(signal.takeProfits, size + 1);
            signal.takeProfits[size] = value;
        }
        else if(StringFind(line, "SL") >= 0 || StringFind(line, "Sl") >= 0)
        {
            signal.stopLoss = value;
        }
        else if(value > 100) // قیمت منطقی
        {
            int size = ArraySize(signal.entryPrices);
            ArrayResize(signal.entryPrices, size + 1);
            signal.entryPrices[size] = value;
        }
    }
    
    // محاسبه استاپ خودکار
    void CalculateAutoStopLoss(SSignal &signal)
    {
        double entry = signal.entryPrices[0];
        if(signal.orderType == ORDER_TYPE_BUY || signal.orderType == ORDER_TYPE_BUY_LIMIT)
            signal.stopLoss = entry - (entry * 0.002);
        else
            signal.stopLoss = entry + (entry * 0.002);
    }
};
//+------------------------------------------------------------------+
//|                                                   Utils.mqh      |
//|                        Copyright 2024, YourName                  |
//+------------------------------------------------------------------+

//--- توابع کمکی عمومی
namespace Utils
{
    // تابع تکرار رشته
    string StringRepeat(string str, int count)
    {
        string result = "";
        for(int i = 0; i < count; i++)
            result += str;
        return result;
    }
    
    // بررسی وجود فایل
    bool FileExists(string filename, bool useCommon = true)
    {
        if(useCommon)
            return FileIsExist(filename, FILE_COMMON);
        else
            return FileIsExist(filename);
    }
    
    // خواندن کل فایل
    string ReadFileContent(string filename, bool useCommon = true)
    {
        int flags = FILE_READ|FILE_TXT|FILE_SHARE_READ;
        if(useCommon) flags |= FILE_COMMON;
        
        int handle = FileOpen(filename, flags);
        if(handle == INVALID_HANDLE)
            return "";
        
        string content = "";
        while(!FileIsEnding(handle))
            content += FileReadString(handle) + "\n";
        
        FileClose(handle);
        return content;
    }
    
    // نوشتن در فایل
    bool WriteFile(string filename, string content, bool useCommon = true)
    {
        int flags = FILE_WRITE|FILE_TXT;
        if(useCommon) flags |= FILE_COMMON;
        
        int handle = FileOpen(filename, flags);
        if(handle == INVALID_HANDLE)
            return false;
        
        FileWrite(handle, content);
        FileClose(handle);
        return true;
    }
    
    // حذف فایل
    bool DeleteFile(string filename, bool useCommon = true)
    {
        if(useCommon)
            return FileDelete(filename, FILE_COMMON);
        else
            return FileDelete(filename);
    }
    
    // بررسی محدوده قیمت
    bool IsPriceInRange(double entryPrice, double currentPrice, string symbol, double maxPips = 500)
    {
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double maxDistance = maxPips * point;
        double distance = MathAbs(entryPrice - currentPrice);
        return distance <= maxDistance;
    }
    
    // محاسبه حداقل فاصله
    double GetMinDistance(string symbol, double minPips = 10)
    {
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        return minPips * point;
    }
};