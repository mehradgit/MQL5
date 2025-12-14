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