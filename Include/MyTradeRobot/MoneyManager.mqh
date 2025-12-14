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