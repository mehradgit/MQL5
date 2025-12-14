
//+------------------------------------------------------------------+
//| Command Jobs.mqh                                                    |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Telegram\SocketUtils.mqh>
#include <Telegram\RiskUtils.mqh>

// بررسی اگر این فایل قبلاً تعریف نشده است
#ifndef __CommandJosbs_MQH__
#define __CommandJosbs_MQH__
CTrade trade; // Global trade object

//+------------------------------------------------------------------+
//| User Request Commands                                                  |
//+------------------------------------------------------------------+
void UserRequest(string data)
{

    string command = GetJsonValue(data, "\"command\":\"");
    if (command == "close_order")
    {
        Print("Start Close Order");
        string orderId = GetJsonValue(data, "\"orderId\":\"");
        string signalId = GetJsonValue(data, "\"signal_id\":\"");

        Print("Order  ID: ", orderId);
        SendMessageToServer("📊Close Command Successfully Recieved By Meta", "signal|success");
        CloseComment(signalId, orderId);
    }
    if (command == "risk_free")
    {
        Print("Start Risk Free");
        string orderId = GetJsonValue(data, "\"orderId\":\"");
        string signalId = GetJsonValue(data, "\"signal_id\":\"");
        Print("Order  ID: ", orderId);
        SendMessageToServer("📊Risk free Command Successfully Recieved By Meta", "signal|success");

        RiskFree(signalId, orderId, 50);
    }
    else if (command == "getReport")
    {
        Print("Start Get Report");
        string targetId = "client_next";
        string report = GetOrdersReport();

        Print(report);
        // string message = StringFormat("user--report %s", report);
        SendMessageToServer(report, "user|report");
    }
}

//+------------------------------------------------------------------+
//| Get Orders Report                                                   |
//+------------------------------------------------------------------+
string GetOrdersReport()
{

    int total = PositionsTotal();
    string result = "";
    int totalOrders = OrdersTotal();

    //--- go through orders in a loop
    for (int i = 0; i < total; i++) // حلقه از اول به آخر
    {
        string symbol = PositionGetSymbol(i);
        string symbol_name = PositionGetString(POSITION_SYMBOL);
        long ticket = PositionGetInteger(POSITION_IDENTIFIER);
        double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
        string type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "Buy" : "Sell";
        string comment = PositionGetString(POSITION_COMMENT);
        long order_magic = PositionGetInteger(POSITION_MAGIC);
        double volume = PositionGetDouble(POSITION_VOLUME);
        double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
        double Stop_Loss = PositionGetDouble(POSITION_SL);
        double Take_Profit = PositionGetDouble(POSITION_TP);
        double profit = PositionGetDouble(POSITION_PROFIT);

        bool targetFound = false;
        bool risk_Free;
        bool first_Target;
        bool second_Target;
        bool third_Target;
        for (int i = 0; i < ArraySize(ordersArray); i++)
        {

            if (ordersArray[i].orderTicket == ticket)
            {
                targetFound = true;
                risk_Free = ordersArray[i].riskFree;
                first_Target = ordersArray[i].firstTarget;
                second_Target = ordersArray[i].secondTarget;
                third_Target = ordersArray[i].thirdTarget;
                break;
            }
        }
        if (!targetFound)
        {
            Print("Report Part:Order Info not found for ticket: ", ticket);
        }
        PrintFormat("Report Part : risk_free : %d,first_target: %d,second_target : %d,third_target : %d",
                    risk_Free,
                    first_Target,
                    second_Target,
                    third_Target);
        //--- ساخت یک شیء JSON برای هر پوزیشن
        string positionJson = StringFormat(
            "{'ticket': %d,'symbol': '%s','type' : '%s','volume' :' %G','open_price' : %G,'current_price' : %G,'profit' : %G,'take_profit' : %G,'stop_loss' : %G,'magic' : %d,'comment' : '%s','risk_free' : %d,'first_target' : %d,'second_target' : %d,'third_target' : %d,'cat':'market'}",
            ticket,
            symbol_name,
            type,
            volume,
            open_price,
            current_price,
            profit,
            Take_Profit,
            Stop_Loss,
            order_magic,
            comment,
            risk_Free,
            first_Target,
            second_Target,
            third_Target);

        //--- اضافه کردن شیء JSON به آرایه
        result += positionJson;

        //--- اضافه کردن کاما برای جدا کردن اشیاء، به جز برای آخرین پوزیشن
        if (i < total - 1)
        {
            result += ",";
        }
        if (i == total - 1 && totalOrders > 0)
        {
            result += ",";
        }
    }

    //--- go through orders in a loop
    for (int j = 0; j < totalOrders; j++) // حلقه از آخر به اول
    {
        ulong ticket = OrderGetTicket(j);
        double open_price = OrderGetDouble(ORDER_PRICE_OPEN);
        string symbol = OrderGetString(ORDER_SYMBOL);
        long order_magic = OrderGetInteger(ORDER_MAGIC);
        double initial_volume = OrderGetDouble(ORDER_VOLUME_INITIAL);
        string type = EnumToString(ENUM_ORDER_TYPE(OrderGetInteger(ORDER_TYPE)));
        string comment = OrderGetString(ORDER_COMMENT);
        double current_price = OrderGetDouble(ORDER_PRICE_CURRENT);

        //--- ساخت یک شیء JSON برای هر پوزیشن
        string positionJson = StringFormat(
            "{'ticket': %d,'symbol': '%s','type' : '%s','volume' :' %G','open_price' : %G,'current_price' : %G,'magic' : %d,'comment' : '%s','cat':'pending'}",
            ticket,
            symbol,
            type,
            initial_volume,
            open_price,
            current_price,
            order_magic,
            comment);

        //--- اضافه کردن شیء JSON به آرایه
        result += positionJson;

        //--- اضافه کردن کاما برای جدا کردن اشیاء، به جز برای آخرین پوزیشن
        if (j < totalOrders - 1)
        {
            result += ",";
        }
    }
    //--- پایان آرایه JSON
    result += "]";

    //--- اگر هیچ پوزیشن باز نیست
    if (total == 0 && totalOrders == 0)
    {
        return "]"; // آرایه خالی اگر پوزیشن باز وجود ندارد
    }

    //--- برگرداندن رشته JSON
    return result;
}

//+------------------------------------------------------------------+
//| Close Full Order                                                  |
//+------------------------------------------------------------------+
void CloseComment(string signal_id, string orderNumber)
{

    ulong ticket;

    string comment;

    //--- number of current pending orders
    uint total = OrdersTotal();
    int totalpositions = PositionsTotal();

    bool found = false;

    //--- go through orders in a loop
    for (int i = (int)total - 1; i >= 0; i--) // حلقه از آخر به اول
    {
        //--- return order ticket by its position in the list
        if ((ticket = OrderGetTicket(i)) > 0)
        {
            //--- return order properties

            comment = OrderGetString(ORDER_COMMENT);

            // --- check if the magic number matches
            if (comment == orderNumber)
            {
                long order_magic = OrderGetInteger(ORDER_MAGIC);
                //--- close the pending order
                if (trade.OrderDelete(ticket))
                {
                    found = true;
                    PrintFormat("deleted order: Successfully deleted pending order #%d with magic number %d", ticket, orderNumber);
                    string disc = StringFormat("📊🟢deleted pending: Successfully deleted pending Signal Id  %d with order id number %d", order_magic, orderNumber);
                    // OrderReportRequire();
                    SendMessageToServer("meta", "report");
                    string msgToserver = StringFormat("order|%s,%s", orderNumber, comment);
                    SendMessageToServer(disc, msgToserver);
                    break; // اگر معامله پیدا شد، جستجو را متوقف کنید
                }
            }
        }
    }
    if (!found)
    {

        //--- go through orders in a loop
        for (int i = 0; i < totalpositions; i++) // حلقه از اول به آخر
        {
            string symbol = PositionGetSymbol(i);
            long ticket = PositionGetInteger(POSITION_IDENTIFIER);
            string comment = PositionGetString(POSITION_COMMENT);

            if (comment == orderNumber)
            {
                long order_magic = PositionGetInteger(POSITION_MAGIC);
                //--- close the pending order
                if (trade.PositionClose(ticket))
                {
                    found = true;
                    PrintFormat("deleted position: Successfully deleted market order #%d with magic number %d", ticket, orderNumber);
                    string disc = StringFormat("📊🟢deleted position: Successfully deleted position  %d with magic number %d", order_magic, orderNumber);
                    SendMessageToServer("meta", "report");
                    string msgToserver = StringFormat("order|%s,%s", orderNumber, comment);
                    SendMessageToServer(disc, msgToserver);
                    break; // اگر معامله پیدا شد، جستجو را متوقف کنید
                }
            }
        }
    }
}
#endif // __CommandJosbs_MQH__