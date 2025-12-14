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