#include <Trade\Trade.mqh>
#include <Telegram\SocketUtils.mqh>
#include <Telegram\InputUtils.mqh>
#include <Telegram\RiskUtils.mqh>
//--- متغیرهای عمومی
#ifndef __OpenTrade_MQH__
#define __OpenTrade_MQH__

// SignalInfo signalInfos[]; // آرایه‌ای برای نگهداری اطلاعات سیگنال‌ها

//+------------------------------------------------------------------+
//| Open Trade if Valid                                              |
//+------------------------------------------------------------------+
bool OpenTradeIfValid(string currency, string order_type, double signal_price, double stop_loss, double take_profit, double volume, string signal_id, int k, bool is_limit = false)
{
    double point = SymbolInfoDouble(currency, SYMBOL_POINT);
    int symbolGroupNumber = GetGroupNumber(currency);

    Print(StringFormat(
        "OpenTradeIfValid called with arguments: Currency=%s, Order Type=%s, Signal Price=%.5f, Stop Loss=%.5f, Take Profit=%.5f,Signal Id=%.5s ,Is Limit=%s",
        currency,
        order_type,
        signal_price,
        stop_loss,
        take_profit,
        signal_id,
        is_limit ? "true" : "false"));

    double current_price = (order_type == "buy") ? SymbolInfoDouble(currency, SYMBOL_ASK) : SymbolInfoDouble(currency, SYMBOL_BID);
    double pipValue = SymbolInfoDouble(currency, SYMBOL_POINT);
    // string comment = StringFormat("%s_%i", signal_id, k);
    string comment = "Propiy";
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);

    // اگر سفارش از نوع "buy" یا "sell" باشد و معلق نباشد (Limit نیست)، از Market Order استفاده می‌کنیم.
    if (!is_limit)
    {
        Print("NON LIMIT SECTION");
        // تعیین action برای سفارش بازار
        request.action = TRADE_ACTION_DEAL; // سفارش بلافاصله اجرا می‌شود

        // محاسبه قیمت فعلی بازار

        double current_price = (order_type == "buy") ? SymbolInfoDouble(currency, SYMBOL_ASK) : SymbolInfoDouble(currency, SYMBOL_BID);
        request.price = current_price; // قیمت فعلی بازار را برای سفارش قرار می‌دهیم
    }
    else
    {
        Print(" LIMIT SECTION");
        // برای سفارش‌های Limit یا Stop، از Pending Order استفاده می‌شود
        request.action = TRADE_ACTION_PENDING; // سفارش معلق (Pending) برای Limit و Stop Orders
        (order_type == "buy limit") ? signal_price += GetTargetValue(symbolGroupNumber, 18) * pipValue : (order_type == "sell limit") ? signal_price -= GetTargetValue(symbolGroupNumber, 19) * pipValue
                                                                                                                                      : NULL;
        Print("signal _ price: ", signal_price);
        request.price = signal_price;
    }
    // double finalSlDifference = MathAbs(request.price - stop_loss);
    // double MaxSlpipValue = pipValue * GetTargetValue(symbolGroupNumber, 25);
    // if (finalSlDifference > MaxSlpipValue)
    // {
    //     if (order_type == "buy" || order_type == "buy limit")
    //     {
    //         stop_loss = request.price - MaxSlpipValue;
    //     }
    //     else if (order_type == "sell" || order_type == "sell limit")
    //     {
    //         stop_loss = request.price + MaxSlpipValue;
    //     }

    //     Print("SL adjusted to 50 pips limit. New SL: ", stop_loss);
    // }

    request.symbol = currency;
    request.sl = stop_loss;
    request.tp = take_profit;
    request.magic = StringToInteger(signal_id); // یا یک مقدار خاص مرتبط با سیگنال
    request.comment = comment;                  // درج شناسه در توضیحات
    request.type = (order_type == "buy")          ? (is_limit ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_BUY)
                   : (order_type == "sell")       ? (is_limit ? ORDER_TYPE_SELL_LIMIT : ORDER_TYPE_SELL)
                   : (order_type == "buy limit")  ? ORDER_TYPE_BUY_LIMIT
                   : (order_type == "sell limit") ? ORDER_TYPE_SELL_LIMIT
                                                  : NULL;

    request.type_filling = OrderFillingType;
    // Calculate Stop Level
    double stop_level = SymbolInfoInteger(currency, SYMBOL_TRADE_STOPS_LEVEL) * SymbolInfoDouble(currency, SYMBOL_POINT);
    Print("Order Type: ", order_type, ", Signal Price: ", signal_price, ", Current Price: ", current_price,
          ", SL: ", stop_loss, ", TP: ", take_profit, ", Stop Level: ", stop_level);

    // Validate Stops
    if (order_type == "buy limit")
    {
        if (stop_loss >= signal_price - stop_level || take_profit <= signal_price + stop_level)
        {
            Print("Error: Invalid stops for buy limit. SL: ", stop_loss, ", TP: ", take_profit, ", Signal Price: ", signal_price, ", Stop Level: ", stop_level);
            string msgToserver = StringFormat("order|%s,%s", signal_id, comment);
            SendMessageToServer("📊🔴Error: Invalid stops for buy limit", msgToserver);

            return false;
        }
    }
    else if (order_type == "sell limit")
    {
        if (stop_loss <= signal_price + stop_level || take_profit >= signal_price - stop_level)
        {
            Print("Error: Invalid stops for sell limit. SL: ", stop_loss, ", TP: ", take_profit, ", Signal Price: ", signal_price, ", Stop Level: ", stop_level);
            string msgToserver = StringFormat("order|%s,%s", signal_id, comment);
            SendMessageToServer("📊🔴Error: Invalid stops for sell limit", msgToserver);

            return false;
        }
    }

    request.volume = volume;
    if (OrderSend(request, result))
    {
        AddOrderInfo(result.order, volume, false, false, false, false);
        Print((is_limit ? "Limit " : ""), "Order placed successfully. Ticket: ", result.order);
        string disc = StringFormat("📊🟢 Order placed successfully: Order Type: %s, Signal Price: %.2f, Current Price: %.2f, SL: %.2f, TP: %.2f, Stop Level: %.2f",
                                   order_type, signal_price, current_price, stop_loss, take_profit, stop_level);
        string msgToserver = StringFormat("order|%s,%s", signal_id, comment);
        SendMessageToServer(disc, msgToserver);

        return true;
    }
    else
    {
        Print("Failed to place ", (is_limit ? "Limit " : ""), order_type, " order: ", result.comment);
        string disc = StringFormat("📊🔴Failed to place Order: Type: %s, Signal Price: %.2f,Volume : %.2f, Current Price: %.2f, SL: %.2f, TP: %.2f, Stop Level: %.2f,Reason:%s",
                                   order_type, signal_price, volume, current_price, stop_loss, take_profit, stop_level, result.comment);
        string msgToserver = StringFormat("order|%s,%s", signal_id, comment);
        SendMessageToServer(disc, msgToserver);

        return false;
    }
}

#endif // __OpenTrade_MQH__