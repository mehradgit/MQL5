//+------------------------------------------------------------------+
//| TelegramBot.mqh - ارسال پیام‌های تلگرام                         |
//+------------------------------------------------------------------+
#property library
#property strict

// --- FUNCTION PROTOTYPES ---
bool SendTelegramMessage(string message);
bool SendTelegramFarsi(string message);
bool CheckTelegramSettings();
void SendExecutionReport(string signalID, string symbol, string orderType, int totalOrders, int successfulOrders, 
                        double totalVolume, bool singleOrderMode, bool pendingMode, double pendingPrice, ENUM_SYMBOL_TYPE symType);

//+------------------------------------------------------------------+
//| Check Telegram Settings                                          |
//+------------------------------------------------------------------+
bool CheckTelegramSettings()
  {
   return (StringLen(TelegramBotToken) > 20 && StringLen(TelegramChatID) > 5);
  }

//+------------------------------------------------------------------+
//| Send Telegram Message                                            |
//+------------------------------------------------------------------+
bool SendTelegramMessage(string message)
  {
   if(!EnableTelegram || StringLen(TelegramBotToken) < 10) return false;
   
   string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
   
   string cleanMsg = message;
   StringReplace(cleanMsg, "\"", "\\\"");
   StringReplace(cleanMsg, "\n", "\\n");
   StringReplace(cleanMsg, "\r", "");
   
   string json = "{\"chat_id\": \"" + TelegramChatID + "\", \"text\": \"" + cleanMsg + "\"}";
   
   char post[], res[];
   StringToCharArray(json, post, 0, WHOLE_ARRAY, CP_UTF8);
   if(ArraySize(post) > 0) ArrayResize(post, ArraySize(post)-1); 
   
   string headers = "Content-Type: application/json\r\n";
   string res_headers;
   
   int code = WebRequest("POST", url, headers, TelegramTimeout, post, res, res_headers);
   
   if(code != 200)
     {
      PrintLog("Telegram Error: " + IntegerToString(code));
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Send Telegram Farsi Message                                      |
//+------------------------------------------------------------------+
bool SendTelegramFarsi(string message)
  {
   if(!EnableTelegram) return false;
   
   string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
   
   string json = "{\"chat_id\": \"" + TelegramChatID + "\", " +
                 "\"text\": \"" + message + "\", " +
                 "\"parse_mode\": \"Markdown\", " +
                 "\"disable_web_page_preview\": true}";
   
   char post[], res[];
   StringToCharArray(json, post, 0, WHOLE_ARRAY, CP_UTF8);
   if(ArraySize(post) > 0) ArrayResize(post, ArraySize(post)-1); 
   
   string headers = "Content-Type: application/json\r\n";
   string res_headers;
   
   int code = WebRequest("POST", url, headers, TelegramTimeout, post, res, res_headers);
   
   if(code != 200)
     {
      PrintLog("Telegram Farsi Error: " + IntegerToString(code));
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Send Execution Report                                            |
//+------------------------------------------------------------------+
void SendExecutionReport(string signalID, string symbol, string orderType, int totalOrders, int successfulOrders, 
                        double totalVolume, bool singleOrderMode, bool pendingMode, double pendingPrice, ENUM_SYMBOL_TYPE symType)
  {
   string report = "📊 *Signal Execution Report*\n\n";
   
   report += "🆔 Signal ID: `" + signalID + "`\n";
   report += "🏷️ Symbol: " + symbol + "\n";
   report += "📋 Type: " + GetSymbolTypeName(symType) + "\n";
   report += "📈 Order Type: " + orderType + "\n";
   report += "💰 Total Volume: " + DoubleToString(totalVolume, 2) + " lots\n";
   report += "⏰ Time: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\n\n";
   
   if(pendingMode)
     {
      SymbolSettings settings = GetSymbolSettings(symType);
      report += "⚡ *Special Pending Mode*\n";
      report += "🔸 Reason: Large price gap\n";
      report += "🔸 Symbol Type: " + GetSymbolTypeName(symType) + "\n";
      report += "🔸 Pending Price: " + DoubleToString(pendingPrice, 2) + "\n";
      report += "🔸 Distance from SL: " + IntegerToString(settings.pending_distance_pips) + " pips\n";
      report += "🔸 Max Slippage: " + IntegerToString(settings.max_slippage_pips) + " pips\n";
      report += "✅ 1 pending order created\n";
     }
   else if(singleOrderMode)
     {
      report += "⚠️ *Special Execution Mode*\n";
      report += "Due to small calculated volume, only 1 position with first target created.\n";
     }
   else
     {
      report += "✅ Positions created: " + IntegerToString(successfulOrders) + " of " + IntegerToString(totalOrders) + "\n";
     }
   
   if(successfulOrders > 0)
     {
      if(pendingMode)
         report += "\n🎯 *Pending order successfully placed!*";
      else if(successfulOrders == totalOrders)
         report += "\n🎯 *Signal successfully executed!*";
      else
         report += "\n⚠️ *Signal partially executed*";
     }
   else
     {
      report += "\n❌ *Error executing signal*";
     }
   
   SendTelegramFarsi(report);
  }
//+------------------------------------------------------------------+