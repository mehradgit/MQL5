//+------------------------------------------------------------------+
//|                                              SignalParser.mqh    |
//|                        Copyright 2024, YourName                  |
//+------------------------------------------------------------------+
#include "Config.mqh"

class CSignalParser
{
private:
    string m_lastContent;
    
public:
    // پردازش متن سیگنال
    bool ParseSignal(string text, SSignal &signal)
    {
        signal.rawText = text;
        StringToUpper(text);
        m_lastContent = text;
        
        // تشخیص نماد
        signal.symbol = DetectSymbol(text);
        if(signal.symbol == "")
        {
            Print("⚠️ خطا: نماد تشخیص داده نشد");
            return false;
        }
        
        // تشخیص نوع دستور
        if(!DetectOrderType(text, signal))
        {
            Print("⚠️ خطا: نوع دستور نامعتبر");
            return false;
        }
        
        // استخراج اعداد
        ExtractNumbers(text, signal);
        
        // اعتبارسنجی
        if(ArraySize(signal.entryPrices) == 0)
        {
            Print("⚠️ خطا: هیچ قیمت ورودی پیدا نشد");
            return false;
        }
        
        return true;
    }
    
    // خواندن از فایل
    bool ReadFromFile(string &content)
    {
        int handle = FileOpen(InpFileName, FILE_READ|FILE_TXT|FILE_SHARE_READ|FILE_COMMON);
        if(handle == INVALID_HANDLE) return false;
        
        content = "";
        while(!FileIsEnding(handle))
            content += FileReadString(handle) + "\n";
        FileClose(handle);
        
        FileDelete(InpFileName, FILE_COMMON);
        return StringLen(content) > 0;
    }
    
private:
    // تشخیص نماد
    string DetectSymbol(string text)
    {
        if(StringFind(text, "XAUUSD") >= 0 || StringFind(text, "GOLD") >= 0)
            return MapSymbol("XAUUSD");
        else if(StringFind(text, "US30") >= 0 || StringFind(text, "DAWOJONSE") >= 0 || StringFind(text, "YM") >= 0)
            return MapSymbol("US30");
        else if(StringFind(text, "NAS100") >= 0 || StringFind(text, "NQ100") >= 0 || StringFind(text, "NASDAQ") >= 0)
            return MapSymbol("NAS100");
        else if(StringFind(text, "EURUSD") >= 0)
            return "EURUSD";
        else if(StringFind(text, "GBPUSD") >= 0)
            return "GBPUSD";
        
        return "";
    }
    
    // تشخیص نوع دستور
    bool DetectOrderType(string text, SSignal &signal)
    {
        if(StringFind(text, "BUY LIMIT") >= 0 || StringFind(text, "BUYLIMIT") >= 0)
        {
            signal.orderType = ORDER_TYPE_BUY_LIMIT;
            signal.commandType = "PENDING";
        }
        else if(StringFind(text, "SELL LIMIT") >= 0 || StringFind(text, "SELLLIMIT") >= 0)
        {
            signal.orderType = ORDER_TYPE_SELL_LIMIT;
            signal.commandType = "PENDING";
        }
        else if(StringFind(text, "BUY") >= 0)
        {
            signal.orderType = ORDER_TYPE_BUY;
            signal.commandType = "MARKET";
        }
        else if(StringFind(text, "SELL") >= 0)
        {
            signal.orderType = ORDER_TYPE_SELL;
            signal.commandType = "MARKET";
        }
        else
        {
            return false;
        }
        return true;
    }
    
    // استخراج اعداد
    void ExtractNumbers(string text, SSignal &signal)
    {
        ArrayResize(signal.entryPrices, 0);
        ArrayResize(signal.takeProfits, 0);
        signal.stopLoss = 0;
        
        string lines[];
        int lineCount = StringSplit(text, '\n', lines);
        
        for(int l = 0; l < lineCount; l++)
        {
            string words[];
            int wordCount = StringSplit(lines[l], ' ', words);
            
            for(int w = 0; w < wordCount; w++)
            {
                string clean = CleanNumber(words[w]);
                if(clean != "")
                {
                    double value = StringToDouble(clean);
                    ClassifyNumber(value, lines[l], signal);
                }
            }
        }
        
        // استاپ خودکار اگر پیدا نشد
        if(signal.stopLoss == 0 && ArraySize(signal.entryPrices) > 0)
        {
            CalculateAutoStopLoss(signal);
        }
    }
    
    // تمیز کردن عدد
    string CleanNumber(string input)
    {
        string clean = "";
        bool hasDot = false;
        
        for(int i = 0; i < StringLen(input); i++)
        {
            string ch = StringSubstr(input, i, 1);
            if(ch >= "0" && ch <= "9")
                clean += ch;
            else if(ch == ".")
            {
                clean += ch;
                hasDot = true;
            }
        }
        
        return (hasDot && StringLen(clean) > 0) ? clean : "";
    }
    
    // طبقه‌بندی عدد
    void ClassifyNumber(double value, string line, SSignal &signal)
    {
        if(StringFind(line, "TP") >= 0 || StringFind(line, "Tp") >= 0)
        {
            int size = ArraySize(signal.takeProfits);
            ArrayResize(signal.takeProfits, size + 1);
            signal.takeProfits[size] = value;
        }
        else if(StringFind(line, "SL") >= 0 || StringFind(line, "Sl") >= 0)
        {
            signal.stopLoss = value;
        }
        else if(value > 100) // قیمت منطقی
        {
            int size = ArraySize(signal.entryPrices);
            ArrayResize(signal.entryPrices, size + 1);
            signal.entryPrices[size] = value;
        }
    }
    
    // محاسبه استاپ خودکار
    void CalculateAutoStopLoss(SSignal &signal)
    {
        double entry = signal.entryPrices[0];
        if(signal.orderType == ORDER_TYPE_BUY || signal.orderType == ORDER_TYPE_BUY_LIMIT)
            signal.stopLoss = entry - (entry * 0.002);
        else
            signal.stopLoss = entry + (entry * 0.002);
    }
};