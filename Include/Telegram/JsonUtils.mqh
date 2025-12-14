
//+------------------------------------------------------------------+
//| JsonUtils.mqh                                                    |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Telegram\SocketUtils.mqh>
#include <Telegram\CommandJobs.mqh>
#define DEVIATION 100 // distance for setting a pending order
#define STOP_LIMIT 50 // order StopLimit distance
#ifndef __JSONUTILS_MQH__
#define __JSONUTILS_MQH__

struct SignalInfo
{
    string signal_id;
    double firstOrderPrice;
    bool isLimitOrdersClosed;
    string currency;
    string order_type;
    // string comment;
};
SignalInfo signalInfos[]; // آرایه‌ای برای نگهداری اطلاعات سیگنال‌ها

//+------------------------------------------------------------------+
//| Utility Functions                                                |
//+------------------------------------------------------------------+
// Parse JSON array into values

// معادل‌های جفت ارز
string equivalent_pairs[][2] = {
    {"GOLD", "XAUUSD"},
    {"US30", "US_30"},
    {"BITCOIN", "BTCUSD"},
    {"NAZDAQ", "NAS100"}};

string GetJsonArray(string json, string key)
{
    int start = StringFind(json, key) + StringLen(key);
    if (start == -1)
        return "";
    int end = StringFind(json, "]", start) + 1;
    return StringSubstr(json, start, end - start);
}

//+------------------------------------------------------------------+
//| Get Jason Value                                                    |
//+------------------------------------------------------------------+
string GetJsonValue(string json, string key)
{
    int start = StringFind(json, key) + StringLen(key);
    if (start == -1)
        return "";
    int end = StringFind(json, ",", start);
    if (end == -1)
        end = StringFind(json, "}", start);
    if (end == -1)
        end = StringFind(json, "]", start);

    // استخراج مقدار
    string value = StringSubstr(json, start, end - start);

    // حذف نقل‌قول اضافی در ابتدا و انتها
    if (StringLen(value) > 0 && StringSubstr(value, 0, 1) == "\"")                    // بررسی اولین کاراکتر
        value = StringSubstr(value, 1);                                               // حذف اولین کاراکتر
    if (StringLen(value) > 0 && StringSubstr(value, StringLen(value) - 1, 1) == "\"") // بررسی آخرین کاراکتر
        value = StringSubstr(value, 0, StringLen(value) - 1);                         // حذف آخرین کاراکتر

    return value;
}

//+------------------------------------------------------------------+
//| REsolve Symbol Alias                                                    |
//+------------------------------------------------------------------+
// تابع برای پیدا کردن معادل نماد
string ResolveSymbolAlias(string alias)
{
    Print("alias is : ", alias);
    // تعداد ردیف‌ها را به‌طور دستی تعیین می‌کنیم
    int rows = 3; // تعداد ردیف‌ها در equivalent_pairs

    // بررسی ردیف‌ها برای پیدا کردن معادل
    for (int i = 0; i < rows; i++)
    {
        // اگر نام نماد برابر با alias باشد، معادل آن را باز می‌گرداند
        if (equivalent_pairs[i][0] == alias)
            return equivalent_pairs[i][1];
    }
    for (int i = 0; i < rows; i++)
    {
        // اگر نام نماد برابر با alias باشد، معادل آن را باز می‌گرداند
        if (equivalent_pairs[i][1] == alias)
            return equivalent_pairs[i][0];
    }

    // اگر معادل پیدا نشد، همان alias را باز می‌گرداند
    return alias;
}

//+------------------------------------------------------------------+
//|  Get Valid Symbol                                                    |
//+------------------------------------------------------------------+
// تابع برای بررسی معتبر بودن نماد
string GetValidSymbol(string currency)
{
    // بررسی اینکه آیا نماد اصلی در مارکت موجود است
    if (SymbolSelect(currency, true))
    {
        Print("Symbol ", currency, " is available in the market.");
        return currency;
    }
    else
    {
        // اگر نماد اصلی موجود نیست، بررسی معادل آن
        string alias = ResolveSymbolAlias(currency);
        if (SymbolSelect(alias, true))
        {
            Print("Symbol alias ", alias, " is available in the market.");
            return alias;
        }
        else
        {
            Print("Error: Neither the symbol ", currency, " nor its alias is available in the market.");
            return ""; // در صورت عدم وجود نماد یا معادل
        }
    }
}

//+------------------------------------------------------------------+
//| Close Pending Orders                                                    |
//+------------------------------------------------------------------+
void ClosePendingOrdersByMagicNumber(long magicNumber)
{
    ulong ticket;
    double open_price;
    double initial_volume;
    datetime time_setup;
    string symbol;
    string type;
    string comment;
    long order_magic;
    long positionID;

    //--- number of current pending orders
    uint total = OrdersTotal();

    //--- go through orders in a loop
    for (int i = (int)total - 1; i >= 0; i--) // حلقه از آخر به اول
    {
        //--- return order ticket by its position in the list
        if ((ticket = OrderGetTicket(i)) > 0)
        {
            //--- return order properties
            open_price = OrderGetDouble(ORDER_PRICE_OPEN);
            time_setup = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
            symbol = OrderGetString(ORDER_SYMBOL);
            order_magic = OrderGetInteger(ORDER_MAGIC);
            positionID = OrderGetInteger(ORDER_POSITION_ID);
            initial_volume = OrderGetDouble(ORDER_VOLUME_INITIAL);
            type = EnumToString(ENUM_ORDER_TYPE(OrderGetInteger(ORDER_TYPE)));
            comment = OrderGetString(ORDER_COMMENT);

            // --- check if the magic number matches
            if (order_magic == magicNumber)
            {
                //--- close the pending order
                if (trade.OrderDelete(ticket))
                {
                    PrintFormat("deleted pending: Successfully deleted pending order #%d with magic number %d", ticket, magicNumber);
                    string disc = StringFormat("📊🟢deleted pending: Successfully deleted pending order #%d with magic number %d", ticket, magicNumber);
                    string msgToserver = StringFormat("order|%s,%s", magicNumber, comment);
                    SendMessageToServer(disc, msgToserver);
                }
                else
                {
                    PrintFormat("Failed to delete pending order #%d with magic number %d. Error: %d",
                                ticket, magicNumber, GetLastError());
                }
            }

            //--- prepare and show information about the order
            printf("#ticket %d %s %G %s %i at %G was set up at %s",
                   ticket,                  // order ticket
                   type,                    // type
                   initial_volume,          // placed volume
                   symbol,                  // symbol
                   order_magic,             // specified open price
                   open_price,              // specified open price
                   TimeToString(time_setup) // time of order placing
            );
        }
    }
}

//+------------------------------------------------------------------+
//| Update signal Array                                                  |
//+------------------------------------------------------------------+
void UpdateSignalArray(SignalInfo &signals[])
{
    // بررسی اعضای آرایه signalInfos
    for (int i = ArraySize(signals) - 1; i >= 0; i--) // حلقه معکوس برای حذف اعضا
    {
        bool found = false;

        // جستجوی معامله‌ای که با Magic Number مطابقت داشته باشد
        for (int pos = 0; pos < PositionsTotal(); pos++) // شمارش تمام موقعیت‌های باز
        {
            if (PositionSelect(PositionGetSymbol(pos))) // انتخاب معامله بر اساس سیمبل
            {
                long positionMagic = PositionGetInteger(POSITION_MAGIC); // دریافت Magic Number معامله

                // بررسی تطابق Magic Number با signal_id
                if (positionMagic == StringToInteger(signals[i].signal_id))
                {
                    found = true;
                    break; // اگر معامله پیدا شد، جستجو را متوقف کنید
                }
            }
        }

        // اگر معامله‌ای با Magic Number مربوطه پیدا نشد، عضو آرایه را حذف کنید
        if (!found)
        {
            Print("Removing signal from array: Signal ID = ", signals[i].signal_id);
            ClosePendingOrdersByMagicNumber(signals[i].signal_id);
            ArrayRemove(signals, i);
        }
    }
}
//+------------------------------------------------------------------+
//| Delete Pending Orders                                                  |
//+------------------------------------------------------------------+
void DeletePendingOrders(SignalInfo &signals[], int MinimumProfitPips)
{
    for (int i = 0; i < ArraySize(signals); i++)
    {
        double currentPrice = SymbolInfoDouble(signals[i].currency, (signals[i].order_type == "buy" ? SYMBOL_ASK : SYMBOL_BID));
        double distance = (signals[i].order_type == "buy") ? (currentPrice - signals[i].firstOrderPrice) : (signals[i].firstOrderPrice - currentPrice);
        double distanceInPips = (distance / SymbolInfoDouble(signalInfos[i].currency, SYMBOL_POINT));

        // Print("distanceInPips :", distanceInPips,"currentPrice: ",currentPrice,"openprice : ",signals[i].firstOrderPrice);
        // اگر 50 پیپ سود ایجاد شده باشد و سفارش‌های لیمیت هنوز بسته نشده باشند
        if (distanceInPips >= MinimumProfitPips && !signals[i].isLimitOrdersClosed)
        {
            Print("Signal ", signals[i].signal_id, " has reached 50 pips profit. Closing pending limit orders.");
            string msgToserver = StringFormat("order|%s,%s", signals[i].signal_id, "0");
            string disc = StringFormat("📊🟢 deleted pending: Signal has reached %i pips profit. Closing pending limit orders.", MinimumProfitPips);
            SendMessageToServer(disc, msgToserver);
            int magicNumber = StringToInteger(signals[i].signal_id);
            ClosePendingOrdersByMagicNumber(magicNumber);
            signals[i].isLimitOrdersClosed = true;
            // حذف عنصر از آرایه بعد از بسته شدن سفارش لیمیت
            ArrayRemove(signals, i); // حذف عنصر با ایندکس i از آرایه
            i--;                     // به دلیل کاهش اندازه آرایه، ایندکس را یک واحد کاهش می‌دهیم تا به عنصر بعدی برسیم                                            // تغییر وضعیت به true که نشان می‌دهد سفارش‌های لیمیت بسته شده‌اند
        }
    }
}

//+------------------------------------------------------------------+
//| Parse Array                                                    |
//+------------------------------------------------------------------+

int ParseArray(string json_array, double &output[], string key)
{
    int count = 0;
    while (StringFind(json_array, "\"" + key + "\":\"") != -1)
    {
        int start = StringFind(json_array, "\"" + key + "\":\"") + StringLen(key) + 4;
        int end = StringFind(json_array, "\"", start);
        if (end == -1)
            break;

        string value_str = StringSubstr(json_array, start, end - start);

        // بررسی اینکه آیا باید کار دیگری با value_str انجام شود
        double value = StringToDouble(value_str);

        ArrayResize(output, count + 1);
        output[count++] = value;

        json_array = StringSubstr(json_array, end + 1);
    }
    return count;
}

//+------------------------------------------------------------------+
//| Calculate Lot Size                                                  |
//+------------------------------------------------------------------+

double CalculateLotSizeByRisk(double riskPercentage, string currency, double entryPrice, double stopLossPrice, int orderNumbers)
{
    // دریافت موجودی واقعی حساب
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);

    // محاسبه مقدار ریسک (Risk Amount)
    double riskAmount = equity * (riskPercentage / 100.0);

    // دریافت اطلاعات نماد
    double contractSize = SymbolInfoDouble(currency, SYMBOL_TRADE_CONTRACT_SIZE);
    double tickValue = SymbolInfoDouble(currency, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(currency, SYMBOL_TRADE_TICK_SIZE);

    // محاسبه فاصله بین قیمت ورود و حد ضرر
    double slDistance = MathAbs(entryPrice - stopLossPrice);
    if (currency == "XAUUSD")
    {
        slDistance *= 10; // ده برابر کردن فاصله حد ضرر
    }

    // تبدیل فاصله قیمت به تعداد تیک‌ها
    double ticks = slDistance / tickSize;

    // محاسبه ضرر برای یک لات (Loss per Lot)
    double lossPerLot = ticks * tickValue;

    // محاسبه حجم معامله (لات) بر اساس مقدار ریسک
    double lotSize = riskAmount / lossPerLot;

    lotSize = lotSize / orderNumbers;

    // نرمال کردن لات به دو رقم اعشار
    lotSize = NormalizeDouble(lotSize, 2);

    return lotSize;
}

//+------------------------------------------------------------------+
//| Return open price by order type                                  |
//+------------------------------------------------------------------+
double PriceByOrderType(const string symbol, const ENUM_ORDER_TYPE order_type)
{
    int digits = 0;
    double point = 0;
    MqlTick tick = {};

    //--- get the symbol Point value
    ResetLastError();
    if (!SymbolInfoDouble(symbol, SYMBOL_POINT, point))
    {
        Print("SymbolInfoDouble() failed. Error ", GetLastError());
        return 0;
    }

    //--- get the symbol Digits value
    long value = 0;
    if (!SymbolInfoInteger(symbol, SYMBOL_DIGITS, value))
    {
        Print("SymbolInfoInteger() failed. Error ", GetLastError());
        return 0;
    }
    digits = (int)value;

    //--- get the last prices by symbol
    if (!SymbolInfoTick(symbol, tick))
    {
        Print("SymbolInfoTick() failed. Error ", GetLastError());
        return 0;
    }

    //--- return the price depending on the order type
    switch (order_type)
    {
    case ORDER_TYPE_BUY:
        return (tick.ask);
    case ORDER_TYPE_SELL:
        return (tick.bid);
    case ORDER_TYPE_BUY_LIMIT:
        return (NormalizeDouble(tick.ask - DEVIATION * point, digits));
    case ORDER_TYPE_SELL_LIMIT:
        return (NormalizeDouble(tick.bid + DEVIATION * point, digits));
    case ORDER_TYPE_BUY_STOP:
        return (NormalizeDouble(tick.ask + DEVIATION * point, digits));
    case ORDER_TYPE_SELL_STOP:
        return (NormalizeDouble(tick.bid - DEVIATION * point, digits));
    case ORDER_TYPE_BUY_STOP_LIMIT:
        return (NormalizeDouble(tick.ask + DEVIATION * point - STOP_LIMIT * point, digits));
    case ORDER_TYPE_SELL_STOP_LIMIT:
        return (NormalizeDouble(tick.bid - DEVIATION * point + STOP_LIMIT * point, digits));
    default:
        return (0);
    }
}
//+------------------------------------------------------------------+
//| Get Total Margin                                                  |
//+------------------------------------------------------------------+
double GetTotalMarginByMagicNumber()
{
    double total_margin = 0.0; // متغیر برای ذخیره مجموع مارجین
    int total_positions = PositionsTotal();
    uint total = OrdersTotal();

    for (int i = 0; i < total_positions; i++)
    {
        string symbol = PositionGetSymbol(i);
        string symbol_name = PositionGetString(POSITION_SYMBOL);
        double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
        long order_magic = PositionGetInteger(POSITION_MAGIC);
        double volume = PositionGetDouble(POSITION_VOLUME);
        double requiredMargin = 0.0;
        if (order_magic != 0)
        {
            double contract_size = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
            double leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
            ENUM_ORDER_TYPE type = ENUM_ORDER_TYPE(PositionGetInteger(POSITION_TYPE));
            double price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : SymbolInfoDouble(symbol, SYMBOL_BID);
            int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
            price = NormalizeDouble(price, digits);

            // محاسبه مارجین دستی
            double requiredMargin = (contract_size * price * volume) / leverage;
            PrintFormat("Margin required for %.2f %s position on %s (Price: %.5f, Contract Size: %.2f, Leverage: %.2f): %.2f",
                        volume, EnumToString(type), symbol, price, contract_size, leverage, requiredMargin);

            total_margin += requiredMargin;
        }
    }

    Print("TOtal Margin is : ", total_margin);
    return total_margin; // بازگرداندن مجموع مارجین
                         // انتخاب پوزیشن
}
#endif // __JSONUTILS_MQH__
