#include <Trade\Trade.mqh>
#include <Telegram\SocketUtils.mqh>
#include <Telegram\InputUtils.mqh>
#include <Telegram\OpenTrade.mqh>
//--- متغیرهای عمومی
#ifndef __ProcessingSignal_MQH__
#define __ProcessingSignal_MQH__

// SignalInfo signalInfos[]; // آرایه‌ای برای نگهداری اطلاعات سیگنال‌ها

//+------------------------------------------------------------------+
//| Process Signal                                                   |
//+------------------------------------------------------------------+
void ProcessSignal(string signal)
{
    Print("Processing Signal: ", signal);

    // استخراج order_type
    string order_type = GetJsonValue(signal, "\"order_type\":\"");
    if (order_type == "")
    {
        Print("Error: Order type is missing in the signal.");
        string disc = "order_type Error";
        RetryRequest("order_type Error");
        return;
    }

    // استخراج currency
    string currency = GetJsonValue(signal, "\"currency\":\"");
    if (currency == "")
    {
        Print("Error: Currency is missing in the signal.");
        RetryRequest("Error: Currency is missing in the signal");
        return;
    }
    string signal_id = GetJsonValue(signal, "\"signal_id\":\""); // شناسه سیگنال
    if (signal_id == "")
    {
        Print("Error: Signal ID is missing.");
        RetryRequest("Error: Signal ID is missing.");
        return;
    }
    // بررسی وجود نماد و معادل آن
    currency = GetValidSymbol(currency);
    if (currency == "")
    {
        Print("Error: Neither the symbol ", currency, " nor its alias is available in the market.");
        RetryRequest("currency alias Error");
        return;
    }
    int symbolGroupNumber = GetGroupNumber(currency);
    // استخراج prices
    string prices_raw = GetJsonArray(signal, "\"prices\":[");
    double prices[]; // آرایه ذخیره قیمت‌ها
    int prices_count = ParseArray(prices_raw, prices, "price");

    if (prices_count == 0)
    {
        Print("Error: Prices are missing or invalid.");
        string disc = "invalid or missing price";
        RetryRequest("Error: Prices are missing or invalid");
        return;
    }

    // استخراج اولین قیمت
    string first_price_str = GetJsonValue(prices_raw, "\"price\"");
    first_price_str = StringSubstr(first_price_str, 2);
    // چاپ اولین قیمت برای بررسی
    Print("First price value: ", first_price_str);

    // بررسی اگر مقدار "market" باشد
    if (StringCompare(first_price_str, "market") == 0 ||
        StringCompare(currency, "US30") == 0 ||
        StringCompare(currency, "US_30") == 0)
    {
        if (!IsPendingOrderType(order_type))
        {
            Print("order Type: ", order_type);
            Print("IsPendingOrderType(order_type): ", IsPendingOrderType(order_type));
            // دریافت قیمت لحظه‌ای بازار
            double market_price;
            if (order_type == "buy")
            {
                market_price = SymbolInfoDouble(currency, SYMBOL_ASK); // قیمت Ask برای خرید
                Print("Market price for buy: ", market_price);         // چاپ قیمت Ask
            }
            else if (order_type == "sell")
            {
                market_price = SymbolInfoDouble(currency, SYMBOL_BID); // قیمت Bid برای فروش
                Print("Market price for sell: ", market_price);        // چاپ قیمت Bid
            }

            if (market_price == 0)
            {
                Print("Error: Failed to get market price. Ensure that the symbol is available and the market is open.");
                string disc = "failed to get market price";
                RetryRequest("Error: Failed to get market price. Ensure that the symbol is available and the market is open");
                return;
            }

            // جایگزینی "market" با قیمت لحظه‌ای بازار
            prices[0] = market_price;
            Print("Market price detected for the first price. Updated to: ", prices[0]);
        }
    }

    // چاپ قیمت‌های پردازش‌شده
    Print("Final Processed Prices:");
    for (int i = 0; i < prices_count; i++)
    {
        Print("Price[", i, "]: ", prices[i]);
    }

    // استخراج TP
    string tp_raw = GetJsonArray(signal, "\"tp\":[");
    double tps[];
    int tps_count = ParseArray(tp_raw, tps, "tp_item");
    // add pips tp TPs
    for (int i = 0; i < tps_count; i++)
    {
        if (tps[i] == 0.0)
        {
            if (order_type == "buy" || order_type == "buy limit")
            {
                tps[i] = prices[0] + (GetTargetValue(symbolGroupNumber, 23) * SymbolInfoDouble(currency, SYMBOL_POINT)); // قیمت Ask برای خرید
            }
            else if (order_type == "sell" || order_type == "sell limit")
            {
                tps[i] = prices[0] - (GetTargetValue(symbolGroupNumber, 23) * SymbolInfoDouble(currency, SYMBOL_POINT)); // قیمت Bid برای فروش
            }
        }
        if (order_type == "buy")
        {
            tps[i] -= GetTargetValue(symbolGroupNumber, 9) * SymbolInfoDouble(currency, SYMBOL_POINT); // برای معامله خرید، پیپ‌ها را اضافه کن
        }
        else if (order_type == "sell")
        {
            tps[i] += GetTargetValue(symbolGroupNumber, 9) * SymbolInfoDouble(currency, SYMBOL_POINT); // برای معامله فروش، پیپ‌ها را کم کن
        }
        else if (order_type == "sell limit")
        {
            tps[i] += GetTargetValue(symbolGroupNumber, 13) * SymbolInfoDouble(currency, SYMBOL_POINT); // برای معامله فروش، پیپ‌ها را کم کن
        }
        else if (order_type == "buy limit")
        {
            tps[i] -= GetTargetValue(symbolGroupNumber, 13) * SymbolInfoDouble(currency, SYMBOL_POINT); // برای معامله خرید، پیپ‌ها را کم کن
        }
    }
    // بررسی و تنظیم TP پیش‌فرض در صورت عدم وجود مقادیر
    if (tps_count == 0)
    {
        ArrayResize(tps, 1);
        tps[0] = (order_type == "buy") ? prices[0] + GetTargetValue(symbolGroupNumber, 11) * SymbolInfoDouble(currency, SYMBOL_POINT)
                                       : prices[0] - GetTargetValue(symbolGroupNumber, 11) * SymbolInfoDouble(currency, SYMBOL_POINT);
    }
    // استخراج SL
    string sl_raw = GetJsonArray(signal, "\"sl\":[");
    double stop_loss = StringToDouble(GetJsonValue(sl_raw, "\"sl_item\":\""));
    if (stop_loss == 0.0)
    {
        Print("Error: SL is missing or invalid.");
        string disc = "SL value error";
        // RetryRequest(disc);
    }

    // تنظیم SL بر اساس نوع سفارش
    if (order_type == "buy")
        stop_loss -= GetTargetValue(symbolGroupNumber, 20) * SymbolInfoDouble(currency, SYMBOL_POINT); // Adjust SL for buy
    else if (order_type == "sell")
    {

        stop_loss += GetTargetValue(symbolGroupNumber, 10) * SymbolInfoDouble(currency, SYMBOL_POINT); // Adjust SL for sell
    }
    else if (order_type == "sell limit")
    {

        stop_loss += GetTargetValue(symbolGroupNumber, 21) * SymbolInfoDouble(currency, SYMBOL_POINT); // Adjust SL for sell
    }
    else if (order_type == "buy limit")
    {

        stop_loss -= GetTargetValue(symbolGroupNumber, 14) * SymbolInfoDouble(currency, SYMBOL_POINT); // Adjust SL for sell
    }
       
    double point = SymbolInfoDouble(currency, SYMBOL_POINT);
    if (point <= 0)
    {
        Print("Error: Invalid point value for symbol ", currency);
        string disc = "Invalid point value Error";
        // RetryRequest("Invalid point value Error");

        return;
    }

    SendMessageToServer("📊Signal Successfully Recieved By Meta", "signal|success");
    // double totalMargin = GetTotalMarginByMagicNumber();
    double account_balance = AccountInfoDouble(ACCOUNT_BALANCE); // بالانس حساب
    double account_margin = AccountInfoDouble(ACCOUNT_MARGIN);   // بالانس حساب
    double max_allowed_margin = account_balance * totalAllowedPercent / 100;
    //  Print("totalMargin: ", totalMargin);
    if (IsPendingOrderType(order_type))
    {
        max_allowed_margin = account_margin;
    }
    if (account_margin > max_allowed_margin)
    {
        PrintFormat("📊🔴Cannot open position: Required margin (%.2f) exceeds (%d)%% of balance (%.2f)", account_margin, totalAllowedPercent, max_allowed_margin);

        string disc = StringFormat("📊🔴Cannot open position: Required margin (%.2f) exceeds 15%% of balance (%.2f)", account_margin, max_allowed_margin);
        string msgToserver = StringFormat("order|%s,%s", signal_id, "0");
        SendMessageToServer(disc, msgToserver);

        return;
    }
    double current_price = (order_type == "buy" || order_type == "buy limit") ? SymbolInfoDouble(currency, SYMBOL_ASK) : SymbolInfoDouble(currency, SYMBOL_BID);
    bool is_first_signal = true; // برای شناسایی اولین قیمت سیگنال
    int k = 0;
    int OrderNumbers = ArraySize(tps) * ArraySize(prices);
    double lotSize = CalculateLotSizeByRisk(totalLotSize, currency, current_price, stop_loss, OrderNumbers);
    // double lotSize = 2;
    Print("lot size : ", lotSize);
    // استفاده
    if (IsPendingOrderType(order_type))
    {

        lotSize = (double)GetTargetValue(symbolGroupNumber, 12) / 100.0;
        Print("lotSize pending: ", lotSize);
    }
    // lotSize = NormalizeDouble(lotSize, 2);
    // Print("Lotisize is: ", lotSize);
    for (int i = 0; i < ArraySize(prices); i++)
    {
        double signal_price = prices[i]; // قیمت سیگنال
        // بررسی فقط برای اولین قیمت سیگنال در صورتی که نوع سفارش "buy" یا "sell" باشد
        if ((order_type == "buy" || order_type == "sell") && is_first_signal)
        {
            double distance = current_price - signal_price;
            double distance_in_pips = distance / point;

            SignalInfo newSignal;
            newSignal.signal_id = signal_id;          // شناسه سیگنال
            newSignal.currency = currency;            // شناسه سیگنال
            newSignal.order_type = order_type;        // شناسه سیگنال
            newSignal.firstOrderPrice = signal_price; // قیمت اولین سفارش
            // newSignal.comment = IntegerToString(signal_id) + "-" + IntegerToString(k+1); // کامنت
            newSignal.isLimitOrdersClosed = false; // وضعیت حذف سفارش‌های لیمیت (در ابتدا false است)
            ArrayResize(signalInfos, ArraySize(signalInfos) + 1);
            signalInfos[ArraySize(signalInfos) - 1] = newSignal; // افزودن سیگنال جدید به آرایه
            Print("Current Price: ", current_price, ", Signal Price: ", signal_price, ", Distance: ", distance, ", Distance in Pips: ", distance_in_pips);
            int filling_modes = SymbolInfoInteger(Symbol(), SYMBOL_FILLING_MODE);
            Print("Supported filling modes for ", Symbol(), ": ", filling_modes);
            double current_price = (order_type == "buy") ? SymbolInfoDouble(currency, SYMBOL_ASK) : SymbolInfoDouble(currency, SYMBOL_BID);

            if (order_type == "buy")
            {
                // فاصله مجاز برای معامله خرید: 30 پیپ کمتر تا 10 پیپ بیشتر
                if (distance_in_pips < (-1) * GetTargetValue(symbolGroupNumber, 16) || distance_in_pips > GetTargetValue(symbolGroupNumber, 17))
                {
                    Print("Distance for buy exceeds allowed range (-30 to +10 pips). No market trade will be opened.");
                    string disc = StringFormat("📊🔴Distance for sell exceeds allowed range (%i to %i pips). No market trade will be opened.", GetTargetValue(symbolGroupNumber, 16), GetTargetValue(symbolGroupNumber, 17));
                    string msgToserver = StringFormat("order|%s,%s", signal_id, "0");
                    SendMessageToServer(disc, msgToserver);

                    return; // اگر فاصله خارج از محدوده باشد، هیچ معامله‌ای باز نمی‌شود
                }
                else
                {
                    signal_price = current_price;
                }
            }
            else if (order_type == "sell")
            {
                // فاصله مجاز برای معامله فروش: 10 پیپ بیشتر تا 30 پیپ کمتر
                if (distance_in_pips > GetTargetValue(symbolGroupNumber, 16) || distance_in_pips < -GetTargetValue(symbolGroupNumber, 17))
                {
                    Print("Distance for sell exceeds allowed range (+10 to -30 pips). No market trade will be opened.");
                    string disc = StringFormat("📊🔴Distance for sell exceeds allowed range (%i to %i pips). No market trade will be opened.", GetTargetValue(symbolGroupNumber, 16), GetTargetValue(symbolGroupNumber, 17));
                    string msgToserver = StringFormat("order|%s,%s", signal_id, "0");
                    SendMessageToServer(disc, msgToserver);

                    return; // اگر فاصله خارج از محدوده باشد، هیچ معامله‌ای باز نمی‌شود
                }
                else
                {
                    signal_price = current_price;
                }
            }

            // باز کردن اولین معامله به صورت Market
            for (int j = 0; j < ArraySize(tps); j++)
            {
                k++;
                if (!OpenTradeIfValid(currency, order_type, signal_price, stop_loss, tps[j], lotSize, signal_id, k, false)) // is_limit=false
                {
                    Print("Failed to place market trade for Price: ", signal_price, ", TP: ", tps[j], ", SL: ", stop_loss);
                    string disc = StringFormat("📊🔴Failed to place market trade for Price: %.2f, TP: %.2f, SL: %.2f",
                                               signal_price, tps[j], stop_loss);
                    string msgToserver = StringFormat("order|%s,%s", signal_id, "0");
                    SendMessageToServer(disc, msgToserver);
                }
            }

            is_first_signal = false; // پس از بررسی اولین قیمت، متغیر به false تغییر می‌کند
        }
        else
        {
            // در صورتی که نوع سیگنال limit باشد، همه قیمت‌ها به صورت Limit باز می‌شوند
            bool is_limit = (order_type == "buy limit" || order_type == "sell limit") || (i > 0); // اگر نوع سفارش limit باشد یا i > 0
            double current_price = SymbolInfoDouble(currency, SYMBOL_ASK);                        // قیمت بازار برای سفارش خرید
            for (int j = 0; j < ArraySize(tps); j++)
            {
                k++;
                if (order_type == "buy limit" && signal_price >= current_price)
                {
                    Print("Signal price for buy limit is invalid (should be lower than current price). Changing to market order.");
                    order_type = "buy"; // تغییر نوع سفارش به buy در صورت نامعتبر بودن قیمت برای buy limit
                }
                Print("signalPrice : ", signal_price);
                if (!OpenTradeIfValid(currency, order_type, signal_price, stop_loss, tps[j], lotSize, signal_id, k, is_limit))
                {
                    Print("Failed to place limit trade for Price: ", signal_price, ", TP: ", tps[j], ", SL: ", stop_loss);
                    string disc = StringFormat("📊🔴Failed to place limit trade for Price:: %.2f, TP: %.2f, SL: %.2f",
                                               signal_price, tps[j], stop_loss);

                    string msgToserver = StringFormat("order|%s,%s", signal_id, "0");
                    SendMessageToServer(disc, msgToserver);
                }
            }
        }
        SendMessageToServer("", "meta|report");
    }
    // OrderReportRequire();
}
bool IsPendingOrderType(string order_type)
{
    return (order_type == "buy limit" || order_type == "sell limit" || order_type == "buy stop" || order_type == "sell stop");
}

#endif // __ProcessingSignal_MQH__