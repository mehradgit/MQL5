// #include <WebSocketClient.mqh>
#include <stdlib.mqh>
#include <Telegram\JsonUtils.mqh>
#include <Trade\Trade.mqh>
#include <Telegram\MessageQueue.mqh>
//+------------------------------------------------------------------+
//| SocketUtils.mqh                                                    |
//+------------------------------------------------------------------+

#ifndef __SocketUtils_MQH__
#define __JSocketUtils_MQH__

// CWebSocketClient wsc; // WebSocket client object
// CMessageQueue messageQueue(50);
//--- تنظیمات اولیه
//  string url = "https://trade-momtaz.chbk.app/api/meta"; // آدرس سرور
 string url = "http://46.249.99.128:300/api/meta"; // آدرس سرور
 int timeout = 10000; // زمان‌انتظار برای پاسخ (بر حسب میلی‌ثانیه)

// //+ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --+
//| Retry Request                                                    |
//+------------------------------------------------------------------+
// شمارنده تلاش‌ها
int retryCount = 0;
const int maxRetries = 5; // حداکثر تعداد تلاش‌ها

void RetryRequest(string disc)
{
    if (retryCount >= maxRetries)
    {
        Print("Max retry attempts reached. Aborting request.");
        retryCount = 0;
        SendMessageToServer("signal--failed-- Max retry attempts reached. Aborting request", "signal|failed");
        return;
    }

    retryCount++;
    SendMessageToServer(disc, "signal|resend");
}

//+------------------------------------------------------------------+
void OrderReportRequire()
{
    string targetId = "client_next";
    string message = "report--full";
    string jsonMessage = StringFormat("{\"targetId\":\"%s\",\"message\":\"%s\"}", targetId, message);
    SendMessageToServer("meta", "report-full");
  
}

//--- تابع ارسال درخواست POST
void SendMessageToServer(string msg, string type)
{
        string message = StringFormat("%s**%s", msg, type);

   char post_data[];
//    StringToCharArray(post_data_string, post_data); // تبدیل رشته به آرایه کاراکتر

   // متغیرهای موردنیاز
   char result[];
   string headers = "Content-Type: application/json; charset=utf-8\r\n"; // هدر Content-Type
   string result_headers;
    StringToCharArray(message, post_data);
   // ارسال درخواست
   int res = WebRequest("POST",   // نوع درخواست (POST)
                        url,      // آدرس سرور
                        headers,  // هدرها
                        timeout,  // زمان‌انتظار (میلی‌ثانیه)
                        post_data, // داده‌های ارسالی
                        result,   // پاسخ از سرور
                        result_headers // هدرهای دریافتی
   );

   // بررسی موفقیت درخواست
   if(res == -1)
   {
      Print("خطا در ارسال درخواست: ", GetLastError());
   }
   else
   {
      // پردازش پاسخ
      string response = CharArrayToString(result);
    //   Print("کد پاسخ: ", res);
      Print("پاسخ دریافتی: ", response);
   }
}

 




#endif // __SocketUtils_MQH__

//+------------------------------------------------------------------+
//| Order Error                                                    |
//+------------------------------------------------------------------+
// void OrderError(string disc, string signal_id, string comment)
// {

//     string targetId = "client_next";
//     string message = StringFormat("order--Error Opening Order: %s | signal_id: %s | order_id: %s", disc, signal_id, comment);

//     string jsonMessage = StringFormat("{\"targetId\":\"%s\",\"message\":\"%s\"}",
//                                       targetId,
//                                       message);
//     if (wsc.SendString(jsonMessage))
//     {
//         Print("Request sent to server: ", jsonMessage);
//     }
//     else
//     {
//         Print("Failed to send request to server.");
//     }
// }
// //+------------------------------------------------------------------+
// //| Order Success                                                    |
// //+------------------------------------------------------------------+
// void OrderSuccess(string disc, string signal_id, string comment)
// {

//     string targetId = "client_next";
//     string message = StringFormat("order--Success--%s | signal_id: %s | order_id: %s", disc, signal_id, comment);

//     string jsonMessage = StringFormat("{\"targetId\":\"%s\",\"message\":\"%s\"}",
//                                       targetId,
//                                       message);
//     if (wsc.SendString(jsonMessage))
//     {
//         Print("Request sent to server: ", jsonMessage);
//     }
//     else
//     {
//         Print("Failed to send request to server.");
//     }
//+------------------------------------------------------------------+
//| Send Data                                              |
//+------------------------------------------------------------------+
// void SendMessageToServer(string msg, string type)
// {
//     string targetId = "client_next";
//     string message = StringFormat("%s**%s", msg, type);
//     string jsonMessage = StringFormat("{\"targetId\":\"%s\",\"message\":\"%s\"}", targetId, message);
//     messageQueue.Enqueue(jsonMessage);
//     Print("Next message to send: ", messageQueue.Peek());
//     // ارسال پیام به سرور و حذف آن از صف
//     if (!messageQueue.IsEmpty())
//     {
//         string messageToSend = messageQueue.Dequeue();
//         // ارسال پیام به سرور
//         Print("Sending message: ", messageToSend);
//         if (wsc.SendString(messageToSend))
//         {
//             Print("Success report request sent to server: ", jsonMessage);
//         }
//         else
//         {
//             Print("Failed to send report request to server.");
//         }
//     }
// }

// }