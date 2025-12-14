//+------------------------------------------------------------------+
//|                                                 Reporter.mqh     |
//|                        Copyright 2024, YourName                  |
//+------------------------------------------------------------------+
#include "Config.mqh"

class CReporter
{
private:
    int m_totalSignals;
    int m_totalOrders;
    datetime m_startTime;
    
public:
    CReporter() : m_totalSignals(0), m_totalOrders(0), m_startTime(TimeCurrent()) {}
    
    // گزارش شروع
    void ReportStart()
    {
        Print("==========================================");
        Print("🤖 MyTradeRobot v4.0 - راه‌اندازی شد");
        Print("📊 حساب: ", AccountInfoString(ACCOUNT_SERVER));
        Print("💰 موجودی: $", AccountInfoDouble(ACCOUNT_BALANCE));
        Print("💵 لوریج: 1:", IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE)));
        Print("📁 فایل سیگنال: ", InpFileName);
        Print("📍 پوشه COMMON: ", TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\MQL5\\Files\\");
        Print("⚡ فاصله چک: ", InpCheckInterval, " ثانیه");
        Print("🎯 ریسک هر سیگنال: ", InpRiskPercent, "%");
        Print("📈 حداکثر ریسک کلی: ", InpMaxTotalRisk, "%");
        Print("==========================================");
    }
    
    // گزارش سیگنال
    void ReportSignal(const SSignal &signal)
    {
        m_totalSignals++;
        
        Print("\n🎯 سیگنال #", m_totalSignals, " دریافت شد");
        Print("⏰ زمان: ", TimeToString(TimeLocal(), TIME_DATE|TIME_SECONDS));
        
        if(InpEnableLogging)
        {
            PrintSignalDetails(signal);
        }
    }
    
    // گزارش معامله
    void ReportOrder(bool success, string type = "")
    {
        if(success) m_totalOrders++;
        
        if(InpEnableLogging)
        {
            Print(success ? "✅ معامله موفق" : "❌ معامله ناموفق");
            if(type != "") Print("   نوع: ", type);
        }
    }
    
    // گزارش وضعیت
    void ReportStatus()
    {
        static datetime lastReport = 0;
        if(TimeCurrent() - lastReport < 300) // هر 5 دقیقه
            return;
        
        lastReport = TimeCurrent();
        
        Print("\n📈 وضعیت سیستم:");
        Print("   🤖 ربات: فعال (", GetUptime(), " دقیقه)");
        Print("   📨 سیگنال‌های پردازش شده: ", m_totalSignals);
        Print("   📊 معاملات اجرا شده: ", m_totalOrders);
        Print("   📈 پوزیشن‌های باز: ", PositionsTotal());
        Print("   💰 موجودی: $", AccountInfoDouble(ACCOUNT_BALANCE));
        Print("   💵 اکویتی: $", AccountInfoDouble(ACCOUNT_EQUITY));
        Print("   🏦 مارجین: $", AccountInfoDouble(ACCOUNT_MARGIN));
        Print("   📁 منتظر سیگنال در پوشه COMMON");
    }
    
    // گزارش پایان
    void ReportEnd(int reason)
    {
        Print("\n==========================================");
        Print("📊 آمار عملکرد ربات:");
        Print("   ⏰ مدت زمان: ", GetUptime(), " دقیقه");
        Print("   📨 سیگنال‌های پردازش شده: ", m_totalSignals);
        Print("   📊 معاملات اجرا شده: ", m_totalOrders);
        Print("   💰 موجودی نهایی: $", AccountInfoDouble(ACCOUNT_BALANCE));
        Print("🤖 ربات متوقف شد. دلیل: ", DeinitReasonToString(reason));
        Print("==========================================");
    }
    
private:
    // نمایش جزئیات سیگنال
    void PrintSignalDetails(const SSignal &signal)
    {
        Print("📊 اطلاعات سیگنال:");
        Print("   نماد: ", signal.symbol);
        Print("   نوع: ", signal.commandType == "MARKET" ? "🟢 مارکت" : "🟡 لیمیت", 
              " ", (signal.orderType == ORDER_TYPE_BUY || signal.orderType == ORDER_TYPE_BUY_LIMIT) ? "BUY" : "SELL");
        
        Print("   نقاط ورود (", ArraySize(signal.entryPrices), "):");
        for(int i = 0; i < ArraySize(signal.entryPrices); i++)
            Print("     ", i+1, ". ", DoubleToString(signal.entryPrices[i], 2));
        
        Print("   استاپ لاس: ", DoubleToString(signal.stopLoss, 2));
        
        if(ArraySize(signal.takeProfits) > 0)
        {
            Print("   تیک پروفیت‌ها (", ArraySize(signal.takeProfits), "):");
            for(int i = 0; i < ArraySize(signal.takeProfits); i++)
                Print("     ", i+1, ". ", DoubleToString(signal.takeProfits[i], 2));
        }
    }
    
    // محاسبه مدت زمان اجرا
    int GetUptime()
    {
        return (int)((TimeCurrent() - m_startTime) / 60);
    }
};