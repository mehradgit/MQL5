//+------------------------------------------------------------------+
//| SignalProcessor.mqh - پردازش فایل سیگنال و JSON                |
//+------------------------------------------------------------------+
#property library
#property strict

#include "SymbolManager.mqh"
#include "OrderManager.mqh"
#include "TelegramBot.mqh"

// --- STRUCTURES ---
struct SignalData
  {
   string currency;
   string order_type;      
   double prices_list[];   
   bool   prices_isMarket[]; 
   int    prices_count;
   double tp_list[];
   int    tp_count;
   double sl_list[];
   int    sl_count;
   string signal_id;
   string status;          
  };

// --- FUNCTION PROTOTYPES ---
void ProcessSignalFile(string fileName, string defaultSymbol, long magicNumber, double riskPercent);
bool ParseJsonContent(string content, SignalData &out);
string ExtractJsonValue(string json, string key);
bool ExtractJsonArray(string json, string arrayKey, double &outArray[], int &outCount);
string NormalizeContentLines(string content);

//+------------------------------------------------------------------+
//| Main Processing Function                                         |
//+------------------------------------------------------------------+
void ProcessSignalFile(string fileName, string defaultSymbol, long magicNumber, double riskPercent)
  {
   string file1 = fileName + ".txt";
   string file2 = fileName;
   
   int handle = INVALID_HANDLE;
   handle = FileOpen(file1, FILE_READ | FILE_TXT | FILE_ANSI);
   if(handle == INVALID_HANDLE)
     {
      handle = FileOpen(file2, FILE_READ | FILE_TXT | FILE_ANSI);
      if(handle == INVALID_HANDLE) return;
     }
   
   string content = "";
   while(!FileIsEnding(handle))
     {
      string line = FileReadString(handle);
      content = content + line;
     }
   FileClose(handle);
   
   FileDelete(file1);
   FileDelete(file2);
   
   content = NormalizeContentLines(content);
   content = StringTrimCustom(content);
   
   if(StringLen(content) < 5) return;
   
   PrintLog("Read Content: " + StringSubstr(content, 0, MathMin(100, StringLen(content))) + "...");

   SignalData sig;
   if(!ParseJsonContent(content, sig))
     {
      PrintLog("Failed to parse JSON content.");
      return;
     }

   if(StringLen(sig.order_type) == 0) return;
   
   string symbol = sig.currency;
   if(StringLen(symbol) == 0 || symbol == "null") symbol = defaultSymbol;
   StringReplace(symbol, "\"", "");
   StringReplace(symbol, "'", "");
   symbol = StringTrimCustom(symbol);
   
   if(!SymbolSelect(symbol, true))
     {
      PrintLog("Symbol " + symbol + " not found. Using default: " + defaultSymbol);
      symbol = defaultSymbol;
      SymbolSelect(symbol, true);
     }
     
   if(StringLen(sig.signal_id) == 0)
      sig.signal_id = IntegerToString((long)TimeCurrent());

   PrintLog("Processing Signal ID: " + sig.signal_id + " on " + symbol);
   
   // Get symbol type and settings
   ENUM_SYMBOL_TYPE symType = GetSymbolType(symbol);
   SymbolSettings settings = GetSymbolSettings(symType);
   
   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double totalRiskMoney = accountBalance * riskPercent / 100.0;
   
   if(sig.prices_count == 0)
     {
      ArrayResize(sig.prices_list, 1);
      ArrayResize(sig.prices_isMarket, 1);
      sig.prices_list[0] = 0.0;
      sig.prices_isMarket[0] = true;
      sig.prices_count = 1;
     }
     
   int successCount = 0;
   double totalExecutedVolume = 0;
   bool singleOrderMode = false;
   bool pendingModeActive = false;
   double pendingOrderPrice = 0;
   
   for(int i = 0; i < sig.prices_count; i++)
     {
      double entryPrice = sig.prices_list[i];
      bool isExplicitMarket = sig.prices_isMarket[i];
      
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      bool isBuy = (StringCompare(sig.order_type, "buy", false) == 0);
      double currentMarketPrice = isBuy ? ask : bid;
      
      bool executeAsMarket = false;
      double gapPoints = 0;
      
      if(isExplicitMarket || entryPrice <= 0)
        {
         executeAsMarket = true;
        }
      else
        {
         double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
         gapPoints = MathAbs(entryPrice - currentMarketPrice) / point;
         
         // Adjust for symbol type
         if(symType == SYMBOL_TYPE_GOLD) 
            gapPoints = gapPoints / 10.0; // For gold, 0.01 = 1 pip
         else if(symType == SYMBOL_TYPE_DOW || symType == SYMBOL_TYPE_NASDAQ)
            gapPoints = gapPoints; // For indices, 1 point = 1 pip
         else
            gapPoints = gapPoints / 10.0; // For forex, 0.0001 = 1 pip
            
         if(gapPoints <= settings.max_slippage_pips)
           {
            executeAsMarket = true;
            PrintLog("Gap " + DoubleToString(gapPoints, 1) + " pips < Limit (" + IntegerToString(settings.max_slippage_pips) + "). Executing MARKET.");
           }
         else
           {
            executeAsMarket = false;
            PrintLog("Gap " + DoubleToString(gapPoints, 1) + " pips > Limit (" + IntegerToString(settings.max_slippage_pips) + "). Will use PENDING logic.");
           }
        }

      double sl_price = 0;
      if(sig.sl_count > 0)
        {
         sl_price = sig.sl_list[0];
        }
      else
        {
         sl_price = CalculateDefaultSL(symbol, symType, settings, currentMarketPrice, isBuy);
        }
        
      double refPrice = executeAsMarket ? currentMarketPrice : entryPrice;
      double distSL = MathAbs(refPrice - sl_price);
      
      double lot = CalculatePositionSize(symbol, totalRiskMoney, distSL);
      lot = NormalizeLotToSymbol(lot, symbol);
      if(lot > settings.max_lot) lot = settings.max_lot;
      
      double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      if(minLot <= 0) minLot = 0.01;
      
      // --- Check price gap for pending mode ---
      if(!executeAsMarket && gapPoints > settings.max_slippage_pips)
        {
         pendingModeActive = true;
         pendingOrderPrice = CalculatePendingPrice(sig.order_type, sl_price, symbol, settings.pending_distance_pips, symType);
         
         double firstTP = GetFirstTP(sig, symbol, symType, settings, currentMarketPrice, isBuy, pendingOrderPrice);
         
         PrintLog("Pending Mode Active for " + GetSymbolTypeName(symType) + 
                  ": Price=" + DoubleToString(pendingOrderPrice, 2) + 
                  ", SL=" + DoubleToString(sl_price, 2) + 
                  ", TP=" + DoubleToString(firstTP, 2) + 
                  ", Distance=" + IntegerToString(settings.pending_distance_pips) + " pips");
         
         if(SendOrder(symbol, sig.order_type, false, pendingOrderPrice, sl_price, firstTP, lot, sig.signal_id, magicNumber))
           {
            successCount++;
            totalExecutedVolume += lot;
           }
        }
      else if(sig.tp_count > 1)
        {
         ProcessMultipleTPs(sig, symbol, symType, settings, executeAsMarket, entryPrice, sl_price, 
                           currentMarketPrice, isBuy, lot, minLot, successCount, totalExecutedVolume, 
                           singleOrderMode, sig.signal_id, magicNumber);
        }
      else
        {
         ProcessSingleTP(sig, symbol, symType, settings, executeAsMarket, entryPrice, sl_price, 
                        currentMarketPrice, isBuy, lot, successCount, totalExecutedVolume, 
                        sig.signal_id, magicNumber);
        }
     }
     
   // Send Telegram report
   if(EnableTelegram && successCount > 0)
     {
      SendExecutionReport(sig.signal_id, symbol, sig.order_type, sig.tp_count, successCount, 
                         totalExecutedVolume, singleOrderMode, pendingModeActive, pendingOrderPrice, symType);
     }
  }

//+------------------------------------------------------------------+
//| Parse JSON Content                                               |
//+------------------------------------------------------------------+
bool ParseJsonContent(string content, SignalData &out)
  {
   ArrayResize(out.prices_list, 0); ArrayResize(out.prices_isMarket, 0);
   out.prices_count = 0;
   ArrayResize(out.tp_list, 0); out.tp_count = 0;
   ArrayResize(out.sl_list, 0); out.sl_count = 0;
   
   out.currency = ExtractJsonValue(content, "currency");
   out.order_type = ExtractJsonValue(content, "order_type");
   out.signal_id = ExtractJsonValue(content, "signal_id");
   out.status = ExtractJsonValue(content, "status");
   
   string pVal = ExtractJsonValue(content, "price");
   if(StringFind(StringToLowerCustom(pVal), "market") >= 0)
     {
      ArrayResize(out.prices_list, 1); ArrayResize(out.prices_isMarket, 1);
      out.prices_list[0] = 0; out.prices_isMarket[0] = true; out.prices_count = 1;
     }
   else
     {
      double tmp[]; int cnt;
      if(ExtractJsonArray(content, "prices", tmp, cnt))
        {
         for(int i=0; i<cnt; i++)
           {
            ArrayResize(out.prices_list, i+1); ArrayResize(out.prices_isMarket, i+1);
            out.prices_list[i] = tmp[i];
            out.prices_isMarket[i] = (tmp[i] <= 0);
            out.prices_count++;
           }
        }
      else
        {
         double val = StringToDouble(pVal);
         if(val > 0)
           {
            ArrayResize(out.prices_list, 1); ArrayResize(out.prices_isMarket, 1);
            out.prices_list[0] = val; out.prices_isMarket[0] = false; out.prices_count = 1;
           }
        }
     }
     
   ExtractJsonArray(content, "tp", out.tp_list, out.tp_count);
   ExtractJsonArray(content, "sl", out.sl_list, out.sl_count);
   
   return true;
  }

//+------------------------------------------------------------------+
//| Extract Value from JSON string                                   |
//+------------------------------------------------------------------+
string ExtractJsonValue(string json, string key)
  {
   string search = "\"" + key + "\":";
   int pos = StringFind(json, search);
   if(pos < 0) return "";
   
   pos += StringLen(search);
   
   while(pos < StringLen(json))
     {
      ushort c = StringGetCharacter(json, pos);
      if(c != ' ' && c != '\t') break;
      pos++;
     }
     
   bool isStr = (StringGetCharacter(json, pos) == '"');
   if(isStr) pos++;
   
   int endPos = pos;
   bool escape = false;
   while(endPos < StringLen(json))
     {
      ushort c = StringGetCharacter(json, endPos);
      if(isStr)
        {
         if(c == '\\') escape = !escape;
         else if(c == '"' && !escape) break;
         else escape = false;
        }
      else
        {
         if(c == ',' || c == '}' || c == ']') break;
        }
      endPos++;
     }
     
   string res = StringSubstr(json, pos, endPos - pos);
   return StringTrimCustom(res);
  }

//+------------------------------------------------------------------+
//| Extract Array from JSON string                                   |
//+------------------------------------------------------------------+
bool ExtractJsonArray(string json, string arrayKey, double &outArray[], int &outCount)
  {
   outCount = 0; ArrayResize(outArray, 0);
   string search = "\"" + arrayKey + "\":";
   int pos = StringFind(json, search);
   if(pos < 0) return false;
   
   int start = StringFind(json, "[", pos);
   if(start < 0) return false;
   
   int end = -1;
   int depth = 0;
   for(int i=start; i<StringLen(json); i++)
     {
      ushort c = StringGetCharacter(json, i);
      if(c == '[') depth++;
      if(c == ']') 
        {
         depth--;
         if(depth == 0) { end = i; break; }
        }
     }
   if(end < 0) return false;
   
   string inner = StringSubstr(json, start+1, end-start-1);
   string items[];
   int cnt = StringSplit(inner, ',', items); 
   
   for(int i=0; i<cnt; i++)
     {
      string s = items[i];
      StringReplace(s, "\"", "");
      StringReplace(s, "{", "");
      StringReplace(s, "}", "");
      StringReplace(s, "tp_item", "");
      StringReplace(s, "sl_item", "");
      StringReplace(s, ":", "");
      s = StringTrimCustom(s);
      
      if(StringFind(StringToLowerCustom(s), "open") >= 0)
        {
         ArrayResize(outArray, outCount+1);
         outArray[outCount] = 0;
         outCount++;
        }
      else
        {
         double val = StringToDouble(s);
         if(val > 0 || s == "0")
           {
            ArrayResize(outArray, outCount+1);
            outArray[outCount] = val;
            outCount++;
           }
        }
     }
   return (outCount > 0);
  }

//+------------------------------------------------------------------+
//| Normalize Content Lines                                          |
//+------------------------------------------------------------------+
string NormalizeContentLines(string content)
  {
   if(StringLen(content) == 0) return content;
   string parts[];
   int cnt = StringSplit(content, '\n', parts); 
   if(cnt <= 1) return content;
   
   int singleChars = 0;
   for(int i=0; i<cnt; i++)
     {
      string s = parts[i];
      StringTrimLeft(s); StringTrimRight(s);
      if(StringLen(s) <= 1) singleChars++;
     }
     
   if(cnt >= 5 && ((double)singleChars/cnt > 0.6))
     {
      string joined = "";
      for(int i=0; i<cnt; i++)
        {
         string s = parts[i];
         StringReplace(s, "\r", "");
         joined += s;
        }
      return joined;
     }
   return content;
  }

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+
string StringTrimCustom(string str)
  {
   string s = str; StringTrimLeft(s); StringTrimRight(s); return s;
  }

string StringToLowerCustom(string str)
  {
   string s = str; StringToLower(s); return s;
  }
  
bool StringContains(string str, string substr)
  {
   return (StringFind(str, substr) >= 0);
  }
//+------------------------------------------------------------------+