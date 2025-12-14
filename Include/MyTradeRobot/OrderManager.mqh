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