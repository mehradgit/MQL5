#include <Trade\Trade.mqh>
#include <Telegram\SocketUtils.mqh>
#include <Telegram\InputUtils.mqh>
//--- متغیرهای عمومی
#ifndef __RiskUtils_MQH__
#define __RiskUtils_MQH__

//+------------------------------------------------------------------+
//| Order Structure                                                  |
//+------------------------------------------------------------------+
// تعریف ساختار اطلاعات هر اوردر
struct OrderInfo
{
    ulong orderTicket;    // شماره تیکت اوردر
    double initialVolume; //  حجم اولیه سفارش
    bool riskFree;        // آیا معامله ریسک آزاد است؟
    bool firstTarget;     // آیا هدف اول رسیده است؟
    bool secondTarget;    // آیا هدف دوم رسیده است؟
    bool thirdTarget;     // آیا هدف سوم رسیده است؟
};

// آرایه برای ذخیره اطلاعات تمام اوردرها
OrderInfo ordersArray[];
//+------------------------------------------------------------------+
//| Risk ManageMent Array Functions                                                       |
//+------------------------------------------------------------------+
void AddOrderInfo(ulong ticket, double initialVolume, bool riskFree, bool firstTarget, bool secondTarget, bool thirdTarget)
{
    OrderInfo newOrder;
    newOrder.orderTicket = ticket;
    newOrder.initialVolume = initialVolume;
    newOrder.riskFree = riskFree;
    newOrder.firstTarget = firstTarget;
    newOrder.secondTarget = secondTarget;
    newOrder.thirdTarget = thirdTarget;

    // اضافه کردن به آرایه
    ArrayResize(ordersArray, ArraySize(ordersArray) + 1);
    ordersArray[ArraySize(ordersArray) - 1] = newOrder;
}

void SyncOrdersWithPositions()
{
    int totalPositions = PositionsTotal();

    // پردازش هر پوزیشن باز
    for (int j = 0; j < totalPositions; j++)
    {

        string symbol = PositionGetSymbol(j);
        long ticket = PositionGetInteger(POSITION_IDENTIFIER);
        double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double initialVolume = PositionGetDouble(POSITION_VOLUME);
        double currentStopLoss = PositionGetDouble(POSITION_SL);
        long magicNumber = PositionGetInteger(POSITION_MAGIC);
        int symbolGroupNumber = GetGroupNumber(symbol);
        long positionType = PositionGetInteger(POSITION_TYPE); // نوع معامله (خرید یا فروش)

        // اگر استاپ لاس تنظیم نشده، مقدار پیش‌فرض تنظیم شود
        if (currentStopLoss == 0.0)
        {
            SetDefaultStopLoss(ticket, entryPrice, symbol, positionType);
        }
        // بررسی اینکه آیا این تیکت در ordersArray موجود است
        bool targetFound = false;
        for (int k = 0; k < ArraySize(ordersArray); k++)
        {
            if (ordersArray[k].orderTicket == ticket)
            {
                targetFound = true;
                break;
            }
        }

        // اگر تیکت جدید بود و دارای مجیک نامبر بود، به لیست اضافه کن
        if (!targetFound && magicNumber != 0)
        {
            Print("Magic Number موجود است: ", magicNumber);
            double stopLoss = PositionGetDouble(POSITION_SL);
            if (stopLoss == entryPrice + GetTargetValue(symbolGroupNumber, 8) * _Point || stopLoss == entryPrice - GetTargetValue(symbolGroupNumber, 8) * _Point)
            {

                AddOrderInfo(ticket, initialVolume, true, true, false, false);
            }
            else
            {

                AddOrderInfo(ticket, initialVolume, false, true, false, false);
            }
        }

        // مدیریت بستن بخشی از معامله (Partial Close)
        int decimal = GetDecimals(symbol);
        ManagePartialClose(ticket, entryPrice, decimal);
    }

    // بررسی و حذف تیکت‌هایی که دیگر باز نیستند
    RemoveClosedOrders();
}

// تنظیم استاپ لاس پیش‌فرض در صورت نیاز
void SetDefaultStopLoss(long ticket, double entryPrice, string symbol, long positionType)
{
    double stopLossPrice;
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double pipSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
    int symbolGroupNumber = GetGroupNumber(symbol);
    double stopLossDistance = GetTargetValue(symbolGroupNumber, 15) * pipSize;
    if (positionType == POSITION_TYPE_BUY) // معامله خرید
    {
        stopLossPrice = entryPrice - stopLossDistance;
    }
    else
    {
        stopLossPrice = entryPrice + stopLossDistance;
    }

    // تلاش برای تنظیم استاپ لاس تا 3 بار
    int retry = 0;
    while (retry < 3)
    {
        if (trade.PositionModify(ticket, stopLossPrice, 0))
        {
            Print("✅ Stop Loss تنظیم شد: ", stopLossPrice);
            return;
        }
        Print("⚠️ تلاش مجدد برای تنظیم Stop Loss (بار ", retry + 1, ")");
        retry++;
    }

    Print("❌ تنظیم Stop Loss ناموفق بود.");
}

// حذف سفارشات بسته‌شده از آرایه مدیریت ریسک
void RemoveClosedOrders()
{
    for (int i = ArraySize(ordersArray) - 1; i >= 0; i--)
    {
        bool found = false;
        for (int j = 0; j < PositionsTotal(); j++)
        {
            string symbol = PositionGetSymbol(j);
            if (ordersArray[i].orderTicket == PositionGetInteger(POSITION_IDENTIFIER))
            {
                found = true;
                break;
            }
        }

        if (!found)
        {
            Print("🗑 حذف سفارش از لیست: Ticket = ", ordersArray[i].orderTicket);
            ArrayRemove(ordersArray, i);
        }
    }
}
void UpdateRiskFree(ulong ticket, bool riskFree, bool firstTarget, bool secondTarget, bool thirdTarget)
{

    Print("called Update Risk Free : ", ticket);
    for (int i = 0; i < ArraySize(ordersArray); i++) // جستجو در آرایه
    {
        if (ordersArray[i].orderTicket == ticket) // پیدا کردن عضو با تیکت مشخص
        {
            if (riskFree)
            {
                ordersArray[i].riskFree = true; // تغییر مقدار riskFree به true
                Print("Order updated: Ticket = ", ticket, ", RiskFree = true");
                return; // خروج از تابع پس از پیدا کردن و تغییر
            }
            if (firstTarget)
            {
                ordersArray[i].firstTarget = true; // تغییر مقدار riskFree به true
                Print("Order updated: Ticket = ", ticket, ", first Target = true");
                return; // خروج از تابع پس از پیدا کردن و تغییر
            }
            if (secondTarget)
            {
                ordersArray[i].secondTarget = true; // تغییر مقدار riskFree به true
                Print("Order updated: Ticket = ", ticket, ", second Target = true");
                return; // خروج از تابع پس از پیدا کردن و تغییر
            }
            if (thirdTarget)
            {
                ordersArray[i].thirdTarget = true; // تغییر مقدار riskFree به true
                Print("Order updated: Ticket = ", ticket, ", third Target = true");
                return; // خروج از تابع پس از پیدا کردن و تغییر
            }
        }
    }

    // اگر تیکت پیدا نشد
    Print("Order not found: Ticket = ", ticket);
}
//+------------------------------------------------------------------+
//| Risk ManageMent Close Function                                                       |
//+------------------------------------------------------------------+
void ManagePartialClose(ulong ticket, double entryPrice, int decimals)
{

    double volumeToClose;
    // محاسبه سود فعلی
    double initialVolume;
    bool risk_Free;
    bool first_Target;
    bool second_Target;
    bool third_Target;

    //============================== Select Position
    if (PositionSelectByTicket(ticket))
    {
        string type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "Buy" : "Sell";
        string symbol = PositionGetString(POSITION_SYMBOL);
        int symbolGroupNumber = GetGroupNumber(symbol);
        double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);    // قیمت فعلی بازار
        double pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10; // مقدار هر پیپ
        double profitPips = type == "Buy" ? (currentPrice - entryPrice) / pipValue : (entryPrice - currentPrice) / pipValue;
        // if (symbol == "XAUUSD" || symbol == "GOLD")
        // {
        //     profitPips *= 100;
        // }
        string comment = PositionGetString(POSITION_COMMENT);
        long order_magic = PositionGetInteger(POSITION_MAGIC);
        bool targetFound = false;
        Print("profit Pips: ", profitPips, "current Price : ", currentPrice, " Ticket : ", ticket, "risk free : ", risk_Free);
        //============================== Find Selected Position From Array
        for (int i = 0; i < ArraySize(ordersArray); i++)
        {
            if (ordersArray[i].orderTicket == ticket)
            {
                Print("Ticket Number : ", ticket);
                // Print("found position Ticket :", ticket);
                targetFound = true;
                initialVolume = ordersArray[i].initialVolume;
                risk_Free = ordersArray[i].riskFree;
                first_Target = ordersArray[i].firstTarget;
                second_Target = ordersArray[i].secondTarget;
                third_Target = ordersArray[i].thirdTarget;
                break;
            }
        }
        if (!targetFound)
        {
            return;
        }
        // اگر second target یا third target فعال باشند و risk free false باشد، تابع اجرا شود
        if ((second_Target || third_Target) && !risk_Free)
        {
            RiskFree(order_magic, comment, GetTargetValue(symbolGroupNumber, 8));
        }
        double remainingVolume = PositionGetDouble(POSITION_VOLUME); // حجم باقی‌مانده معامله

        //============================== Checking First Target

        if (profitPips >= GetTargetValue(symbolGroupNumber, 1) && !first_Target)
        // if (profitPips * 5 >= 1)
        {
            Print("detected Profit Position");

            // else
            // {
            if (initialVolume < 0.03)
            {
                UpdateRiskFree(ticket, false, true, false, false);
            }
            else
            {

                volumeToClose = NormalizeDouble(initialVolume * GetTargetValue(symbolGroupNumber, 4) / 10, decimals);
                if (initialVolume <= 0.1)
                {
                    volumeToClose = 0.01;
                }

                Print("initialVolume: ", initialVolume);
                if (remainingVolume - volumeToClose > SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN))
                {
                    Print("Volume To Close : ", volumeToClose);

                    if (trade.PositionClosePartial(ticket, volumeToClose, 30))
                    {

                        string disc = StringFormat("📊🟢Closed %.2f of the volume at %d pips profit for currency %s.", volumeToClose, GetTargetValue(symbolGroupNumber, 1), symbol);
                        string msgToserver = StringFormat("order|%s,%s", order_magic, comment);
                        UpdateRiskFree(ticket, false, true, false, false);
                        SendMessageToServer(disc, msgToserver);
                        PrintFormat("📊🟢Closed %.2f of the volume at %d pips profit for currency %s.", volumeToClose, GetTargetValue(symbolGroupNumber, 1), symbol);
                        Print("volume to close 1st target: ", volumeToClose);
                    }
                }
                else
                {
                    string disc = StringFormat("📊🔴Failed to Close %.2f of the volume at %d pips profit for currency %s.", volumeToClose, GetTargetValue(symbolGroupNumber, 1), symbol);
                    string msgToserver = StringFormat("order|%s,%s", order_magic, comment);
                    UpdateRiskFree(ticket, false, true, false, false);
                    SendMessageToServer(disc, msgToserver);
                    PrintFormat("📊🔴Failed to Closed %.2f of the volume at %d pips profit for currency %s.", volumeToClose, GetTargetValue(symbolGroupNumber, 1), symbol);
                    UpdateRiskFree(ticket, false, true, false, false);
                }
            }
        }

        //============================== Checking Second Target
        if (profitPips >= GetTargetValue(symbolGroupNumber, 2) && first_Target && !second_Target)
        {
            Print("detected Profit Position");
            volumeToClose = NormalizeDouble(initialVolume * GetTargetValue(symbolGroupNumber, 5) / 10, decimals);
            int totalpositions = PositionsTotal();
            if (initialVolume <= 0.1)
            {
                volumeToClose = 0.01;
            }
            if (initialVolume < 0.03)
            {
                UpdateRiskFree(ticket, false, false, true, false);
            }
            else
            {
                if (remainingVolume - volumeToClose > SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN))
                {
                    if (trade.PositionClosePartial(ticket, volumeToClose, 30))
                    {
                        string disc = StringFormat("📊🟢Closed %.2f of the volume at %d pips profit for currency %s.", volumeToClose, GetTargetValue(symbolGroupNumber, 2), symbol);
                        string msgToserver = StringFormat("order|%s,%s", order_magic, comment);
                        SendMessageToServer(disc, msgToserver);
                        UpdateRiskFree(ticket, false, false, true, false);
                        PrintFormat("📊🟢Closed %.2f of the volume at %d pips profit for currency %s.", volumeToClose, GetTargetValue(symbolGroupNumber, 2), symbol);
                        Print("volume to close 2nd target: ", volumeToClose);
                    }
                }
                else
                {
                    string disc = StringFormat("📊🔴Failed to Close %.2f of the volume at %d pips profit for currency %s.", volumeToClose, GetTargetValue(symbolGroupNumber, 1), symbol);
                    string msgToserver = StringFormat("order|%s,%s", order_magic, comment);
                    UpdateRiskFree(ticket, false, false, true, false);
                    SendMessageToServer(disc, msgToserver);
                    PrintFormat("📊🔴Failed to Closed %.2f of the volume at %d pips profit for currency %s.", volumeToClose, GetTargetValue(symbolGroupNumber, 1), symbol);
                    UpdateRiskFree(ticket, false, false, true, false);
                }
            }
            RiskFreeInSaveProfit(order_magic, GetTargetValue(symbolGroupNumber, 8));
        }

        //============================== Checking Third Target

        double tp = PositionGetDouble(POSITION_TP); // دریافت مقدار TP
        // double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE); // دریافت اندازه تیک
        double targetLevel;
        // محاسبه TP - 10 پیپ
        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
            targetLevel = tp - (GetTargetValue(symbolGroupNumber, 22) * pipValue);
        }
        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
            targetLevel = tp + (GetTargetValue(symbolGroupNumber, 22) * pipValue);
        }

        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && profitPips > GetTargetValue(symbolGroupNumber, 24)) // برای پوزیشن خرید
        {
            if (currentPrice >= targetLevel && !risk_Free) // قیمت در بازه TP - 10 پیپ تا TP
            {
                string disc = StringFormat("Tp Touched !! at price %.2f of ticket %d of currency %s .", currentPrice, ticket, symbol);
                string msgToserver = StringFormat("order|%s,%s", order_magic, comment);
                SendMessageToServer(disc, msgToserver);
                PrintFormat("Tp Touched !! at price %.2f of ticket %d of currency %s .", currentPrice, ticket, symbol);
                RiskFreeInSaveProfit(order_magic, GetTargetValue(symbolGroupNumber, 8));
            }
        }
        else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && profitPips > GetTargetValue(symbolGroupNumber, 24))  // برای پوزیشن فروش
        {
            if (currentPrice <= targetLevel && !risk_Free) // قیمت در بازه TP - 10 پیپ تا TP
            {
                string disc = StringFormat("Tp Touched !! at price %.2f of ticket %d of currency %s .", currentPrice, ticket, symbol);
                string msgToserver = StringFormat("order|%s,%s", order_magic, comment);
                SendMessageToServer(disc, msgToserver);
                PrintFormat("Tp Touched !! at price %.2f of ticket %d of currency %s .", currentPrice, ticket, symbol);
                RiskFreeInSaveProfit(order_magic, GetTargetValue(symbolGroupNumber, 8));
            }
        }
        if (profitPips >= GetTargetValue(symbolGroupNumber, 3))
        {
            Print("TRAiling ....");
            TrailingStop(ticket, GetTargetValue(symbolGroupNumber, 3), GetTargetValue(symbolGroupNumber, 7));
            if (!third_Target)
            {

                {
                    volumeToClose = NormalizeDouble(initialVolume * GetTargetValue(symbolGroupNumber, 6) / 10, decimals);
                    if (initialVolume <= 0.1)
                    {
                        volumeToClose = 0.01;
                    }
                    if (initialVolume < 0.03)
                    {
                        UpdateRiskFree(ticket, false, false, false, true);
                    }
                    else
                    {
                        if (trade.PositionClosePartial(ticket, volumeToClose, 30))
                        {
                            string disc = StringFormat("📊🟢Closed %.2f of the volume at %d pips profit for currency %s.", volumeToClose, GetTargetValue(symbolGroupNumber, 3), symbol);
                            string msgToserver = StringFormat("order|%s,%s", order_magic, comment);
                            SendMessageToServer(disc, msgToserver);
                            UpdateRiskFree(ticket, false, false, false, true);
                            PrintFormat("📊🟢Closed %.2f of the volume at %d pips profit for currency %s.", volumeToClose, GetTargetValue(symbolGroupNumber, 3), symbol);
                        }
                    }
                }
            }
        }
    }
    else
    {
        Print("Order selection failed for ticket: ", ticket);
    }
}
//+------------------------------------------------------------------+
//| Dependent Functions                                                       |
//+------------------------------------------------------------------+

// void checkingSaveProfit()
// {
//     // Print("cheking Profit Save...");
//     int totalpositions = PositionsTotal();
//     for (int i = 0; i < totalpositions; i++) // حلقه از اول به آخر
//     {
//         string symbol = PositionGetSymbol(i);
//         ulong ticket = PositionGetInteger(POSITION_IDENTIFIER);
//         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
//         int decimal = GetDecimals(symbol);
//         double pipValue = CalculatePipValue(symbol);
//         ManagePartialClose(ticket, open_price, pipValue, decimal);
//     }
// }
// double GetInitialVolume(int ticket)
// {
//     if (OrderSelect(ticket))
//     {
//         Print("orderInitial : ",OrderGetDouble(ORDER_VOLUME_INITIAL));
//         return OrderGetDouble(ORDER_VOLUME_INITIAL); // حجم معامله
//     }
//     return 0;
// }
int GetDecimals(string symbol)
{
    return (int)MathLog10(1.0 / SymbolInfoDouble(symbol, SYMBOL_POINT));
}
double CalculatePipValue(string symbol)
{
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    return tickValue / tickSize;
}
void RiskFreeInSaveProfit(long magicValue, int margin)
{
    int totalpositions = PositionsTotal();

    for (int i = 0; i < totalpositions; i++) // حلقه از اول به آخر
    {
        string symbol = PositionGetSymbol(i);
        long order_magic = PositionGetInteger(POSITION_MAGIC);
        string comment = PositionGetString(POSITION_COMMENT);
        if (order_magic == magicValue)
        {
            RiskFree(order_magic, comment, margin);
        }
    }
}
//+------------------------------------------------------------------+
//| Trailing Stop                                                       |
//+------------------------------------------------------------------+
void TrailingStop(long ticket, double trailingStopPips, double trailingStepPips)
{
    if (PositionSelectByTicket(ticket))
    {
        // Print("TRAiling Started ....");

        string symbol = PositionGetString(POSITION_SYMBOL);
        double volume = PositionGetDouble(POSITION_VOLUME);
        double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
        double stopLoss = PositionGetDouble(POSITION_SL);
        double tp = PositionGetDouble(POSITION_TP);
        double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        long positionType = PositionGetInteger(POSITION_TYPE); // نوع معامله (خرید یا فروش)

        double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE); // اندازه تیک
        // double pipValue = tickSize * MathPow(10, SymbolInfoInteger(symbol, SYMBOL_DIGITS) - 1);
        double pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT) * 10; // مقدار هر پیپ

        // محاسبه حداقل تغییر قیمت برای تریلینگ استاپ
        double trailingStopPrice = trailingStopPips * pipValue;
        double trailingStepPrice = trailingStepPips * pipValue;
        // if (symbol == "XAUUSD" || symbol == "GOLD")
        // {
        //     trailingStepPrice /= 10; // ده برابر کردن فاصله حد ضرر
        // }

        // Print("trailingStopPrice: ", trailingStopPrice);
        // Print("trailingStepPrice: ", trailingStepPrice, "ticket : ", ticket);
        if (positionType == POSITION_TYPE_BUY) // معامله خرید
        {
            double newStopLoss = currentPrice - (trailingStopPrice + trailingStepPrice);
            //  Print("new stop loss  : ",newStopLoss);
            // بررسی اینکه استاپ لاس در فاصله مناسب باشد
            if ((currentPrice - entryPrice >= trailingStopPrice) && (newStopLoss > stopLoss + trailingStepPrice))
            {
                Print("Trailing is Ready ... ");
                if (trade.PositionModify(PositionGetInteger(POSITION_IDENTIFIER), newStopLoss, tp))
                {
                    Print("Trailing Stop updated for Buy position: New SL = ", newStopLoss);
                    if (currentPrice > entryPrice)
                    {
                        UpdateRiskFree(ticket, true, false, false, false);
                    }
                }
                else
                {
                    Print("Failed to update Trailing Stop for Buy position: ", GetLastError());
                }
            }
        }
        else if (positionType == POSITION_TYPE_SELL) // معامله فروش
        {
            double newStopLoss = currentPrice + (trailingStepPrice + trailingStopPrice);

            // بررسی اینکه استاپ لاس در فاصله مناسب باشد
            if ((entryPrice - currentPrice >= trailingStopPrice) &&
                (newStopLoss < stopLoss - trailingStepPrice))
            {
                Print("Trailing is Ready ... ");

                if (trade.PositionModify(PositionGetInteger(POSITION_IDENTIFIER), newStopLoss, tp))
                {
                    Print("Trailing Stop updated for Sell position: New SL = ", newStopLoss);
                    if (currentPrice < entryPrice)
                    {
                        UpdateRiskFree(ticket, true, false, false, false);
                    }
                }
                else
                {
                    Print("Failed to update Trailing Stop for Sell position: ", GetLastError());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Risk Free                                                       |
//+------------------------------------------------------------------+
void RiskFree(string signal_id, string orderNumber, int margin)
{
    int totalpositions = PositionsTotal();
    double newStopLoss, openPrice;
    bool modified = false; // بررسی وضعیت موفقیت‌آمیز بودن تغییر
    int maxRetries = 10;   // تعداد حداکثر تلاش‌ها

    for (int i = 0; i < totalpositions; i++)
    {
        string symbol = PositionGetSymbol(i);
        long ticket = PositionGetInteger(POSITION_IDENTIFIER);
        string comment = PositionGetString(POSITION_COMMENT);
        long order_magic = PositionGetInteger(POSITION_MAGIC);
        openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        bool isValid = false;
        if (order_magic == signal_id)
        {
            UpdateRiskFree(ticket, false, false, true, false);
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && (openPrice + (margin * _Point)) < SymbolInfoDouble(symbol, SYMBOL_ASK))

            {
                newStopLoss = openPrice + (margin * _Point);
                isValid = true;
            }
            else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && (openPrice - (margin * _Point)) > SymbolInfoDouble(symbol, SYMBOL_BID))
            {
                Print("open Price : ", openPrice);
                newStopLoss = openPrice - (margin * _Point);
                isValid = true;
            }

            // تلاش برای تغییر پوزیشن تا 10 بار در صورت دریافت ارور 4756
            // for (int retry = 0; retry < maxRetries; retry++)
            // {
            if (isValid)
            {

                if (trade.PositionModify(ticket, newStopLoss, PositionGetDouble(POSITION_TP)))
                {
                    UpdateRiskFree(ticket, true, false, false, false);
                    string msgToserver = StringFormat("order|%s,%s", signal_id, orderNumber);
                    SendMessageToServer("📊🟢Position Risk Free Successfully.", msgToserver);
                    modified = true; // موفق شدیم، از حلقه خارج شویم
                    break;
                }
                else
                {
                    int errorCode = GetLastError();
                    HandleError(errorCode, signal_id, orderNumber);

                    // PrintFormat("Failed to modify position (Attempt %d/%d) for ticket %d. Error code: %d", retry + 1, maxRetries, ticket, errorCode);
                    PrintFormat("Failed to modify position   for ticket %d. Error code: %d", ticket, errorCode);

                    // if (errorCode == 4756)
                    // {
                    //     Print("⚠️ Modification is prohibited. Retrying...");
                    //     Sleep(1000); // یک ثانیه صبر کن و دوباره تلاش کن
                    //     continue;    // تکرار حلقه
                    // }
                    // else
                    // {
                    //     HandleError(errorCode, signal_id, orderNumber);
                    //     break; // برای خطاهای دیگر، متوقف شو
                    // }
                }
            }
            // }

            // if (!modified)
            // {
            //     Print("❌ Failed to modify position after 10 attempts.");
            //     string msgToserver = StringFormat("order|%s,%s", signal_id, orderNumber);
            //     SendMessageToServer("📊🔴Failed to modify position after multiple attempts.", msgToserver);
            // }

            // break; // خروج از حلقه اصلی، زیرا پوزیشن پردازش شد
        }
    }
}

// تابع برای ارسال پیام‌های خطا
void HandleError(int errorCode, string signal_id, string orderNumber)
{
    string disc;
    switch (errorCode)
    {
    case 1:
        disc = "📊🔴No error returned, but operation was not successful.";
        break;
    case 4108:
        disc = "📊🔴Invalid ticket for the specified position.";
        break;
    case 130:
        disc = "📊🔴Invalid stops (stop loss or take profit values are incorrect).";
        break;
    default:
        disc = StringFormat("📊🔴Unknown error occurred. Code: %d", errorCode);
        break;
    }
    SendMessageToServer(disc, StringFormat("order|%s,%s", signal_id, orderNumber));
}

#endif // __RiskUtils_MQH__