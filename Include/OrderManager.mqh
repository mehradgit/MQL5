//+------------------------------------------------------------------+
//| OrderManager.mqh - مدیریت سفارشات و اجرای معاملات               |
//+------------------------------------------------------------------+
#property library
#property strict

#include <Trade\Trade.mqh>

// --- FUNCTION PROTOTYPES ---
bool SendOrder(string symbol, string order_type, bool isMarket, double entryPrice, double sl_price, double tp_price, double lot, string signalID, long magicNumber);
void ProcessMultipleTPs(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings settings, bool executeAsMarket, double entryPrice, double sl_price, 
                       double currentPrice, bool isBuy, double lot, double minLot, int &successCount, double &totalVolume, bool &singleOrderMode, 
                       string signalID, long magicNumber);
void ProcessSingleTP(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings settings, bool executeAsMarket, double entryPrice, double sl_price, 
                    double currentPrice, bool isBuy, double lot, int &successCount, double &totalVolume, string signalID, long magicNumber);

//+------------------------------------------------------------------+
//| Send Order                                                       |
//+------------------------------------------------------------------+
bool SendOrder(string symbol, string order_type, bool isMarket, double entryPrice, double sl_price, double tp_price, double lot, string signalID, long magicNumber)
  {
   MqlTradeRequest request;
   MqlTradeResult  result;
   ZeroMemory(request);
   ZeroMemory(result);
   
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize == 0) tickSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   if(entryPrice > 0) entryPrice = MathRound(entryPrice/tickSize) * tickSize;
   if(sl_price > 0) sl_price = MathRound(sl_price/tickSize) * tickSize;
   if(tp_price > 0) tp_price = MathRound(tp_price/tickSize) * tickSize;
   
   ENUM_ORDER_TYPE type = (StringCompare(order_type, "sell", false) == 0) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   
   request.symbol = symbol;
   request.volume = lot;
   request.deviation = 50;
   request.magic = magicNumber;
   request.comment = "SID:" + signalID;
   request.type_time = ORDER_TIME_GTC;
   request.type_filling = ORDER_FILLING_FOK;
   
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   if(isMarket)
     {
      request.action = TRADE_ACTION_DEAL;
      request.type = type;
      request.price = (type == ORDER_TYPE_BUY) ? ask : bid;
     }
   else
     {
      request.action = TRADE_ACTION_PENDING;
      request.price = entryPrice;
      
      if(type == ORDER_TYPE_BUY)
        {
         if(entryPrice > ask) request.type = ORDER_TYPE_BUY_STOP;
         else request.type = ORDER_TYPE_BUY_LIMIT;
        }
      else
        {
         if(entryPrice < bid) request.type = ORDER_TYPE_SELL_STOP;
         else request.type = ORDER_TYPE_SELL_LIMIT;
        }
     }
     
   if(sl_price > 0) request.sl = sl_price;
   if(tp_price > 0) request.tp = tp_price;
   
   bool sent = OrderSend(request, result);
   
   if(!sent)
     {
      PrintLog("Order Failed: " + IntegerToString(result.retcode) + " " + result.comment);
      if(EnableTelegram) SendTelegramFarsi("⚠️ *Order Error*\nCode: " + IntegerToString(result.retcode) + "\n" + result.comment);
     }
   else
     {
      PrintLog("Order Successful: Ticket #" + IntegerToString(result.order));
     }
     
   return sent;
  }

//+------------------------------------------------------------------+
//| Process Multiple TPs                                             |
//+------------------------------------------------------------------+
void ProcessMultipleTPs(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings settings, bool executeAsMarket, double entryPrice, double sl_price, 
                       double currentPrice, bool isBuy, double lot, double minLot, int &successCount, double &totalVolume, bool &singleOrderMode, 
                       string signalID, long magicNumber)
  {
   double splitLot = NormalizeLotToSymbol(lot / sig.tp_count, symbol);
   
   // Check if split volume is valid
   if(splitLot >= minLot)
     {
      // Normal mode: Create all TPs
      PrintLog("Normal Mode: Creating " + IntegerToString(sig.tp_count) + " positions with volume " + DoubleToString(splitLot, 2) + " lots");
      
      for(int t=0; t<sig.tp_count; t++)
        {
         double tp_val = sig.tp_list[t];
         if(tp_val <= 0)
           {
            double pt = SymbolInfoDouble(symbol, SYMBOL_POINT);
            double pips = settings.default_tp_pips;
            
            // Adjust for symbol type
            if(symType == SYMBOL_TYPE_GOLD) 
               pips = pips * 10.0;
            else if(symType == SYMBOL_TYPE_DOW || symType == SYMBOL_TYPE_NASDAQ)
               pips = pips;
            else
               pips = pips / 10.0;
               
            double dist = pips * pt;
            tp_val = isBuy ? currentPrice + dist : currentPrice - dist;
           }
           
         if(SendOrder(symbol, sig.order_type, executeAsMarket, entryPrice, sl_price, tp_val, splitLot, signalID, magicNumber))
           {
            successCount++;
            totalVolume += splitLot;
           }
        }
     }
   else
     {
      // Special mode: Only one position with first TP
      singleOrderMode = true;
      PrintLog("Special Mode: Invalid split volume. Creating one position with full volume");
      
      double firstTP = sig.tp_list[0];
      if(firstTP <= 0)
        {
         firstTP = GetFirstTP(sig, symbol, symType, settings, currentPrice, isBuy);
        }
        
      if(SendOrder(symbol, sig.order_type, executeAsMarket, entryPrice, sl_price, firstTP, lot, signalID, magicNumber))
        {
         successCount++;
         totalVolume += lot;
        }
     }
  }

//+------------------------------------------------------------------+
//| Process Single TP                                                |
//+------------------------------------------------------------------+
void ProcessSingleTP(SignalData &sig, string symbol, ENUM_SYMBOL_TYPE symType, SymbolSettings settings, bool executeAsMarket, double entryPrice, double sl_price, 
                    double currentPrice, bool isBuy, double lot, int &successCount, double &totalVolume, string signalID, long magicNumber)
  {
   double tp_val = (sig.tp_count > 0) ? sig.tp_list[0] : 0;
   
   if(tp_val <= 0)
     {
      tp_val = GetFirstTP(sig, symbol, symType, settings, currentPrice, isBuy);
     }
   
   if(SendOrder(symbol, sig.order_type, executeAsMarket, entryPrice, sl_price, tp_val, lot, signalID, magicNumber))
     {
      successCount++;
      totalVolume += lot;
     }
  }
//+------------------------------------------------------------------+