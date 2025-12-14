//+------------------------------------------------------------------+
//|                                                   Utils.mqh      |
//|                        Copyright 2024, YourName                  |
//+------------------------------------------------------------------+
#property strict

//--- توابع کمکی عمومی
namespace Utils
{
    // تابع تکرار رشته
    string StringRepeat(string str, int count)
    {
        string result = "";
        for(int i = 0; i < count; i++)
            result += str;
        return result;
    }
    
    // بررسی وجود فایل
    bool FileExists(string filename, bool useCommon = true)
    {
        if(useCommon)
            return FileIsExist(filename, FILE_COMMON);
        else
            return FileIsExist(filename);
    }
    
    // خواندن کل فایل
    string ReadFileContent(string filename, bool useCommon = true)
    {
        int flags = FILE_READ|FILE_TXT|FILE_SHARE_READ;
        if(useCommon) flags |= FILE_COMMON;
        
        int handle = FileOpen(filename, flags);
        if(handle == INVALID_HANDLE)
            return "";
        
        string content = "";
        while(!FileIsEnding(handle))
            content += FileReadString(handle) + "\n";
        
        FileClose(handle);
        return content;
    }
    
    // نوشتن در فایل
    bool WriteFile(string filename, string content, bool useCommon = true)
    {
        int flags = FILE_WRITE|FILE_TXT;
        if(useCommon) flags |= FILE_COMMON;
        
        int handle = FileOpen(filename, flags);
        if(handle == INVALID_HANDLE)
            return false;
        
        FileWrite(handle, content);
        FileClose(handle);
        return true;
    }
    
    // حذف فایل
    bool DeleteFile(string filename, bool useCommon = true)
    {
        if(useCommon)
            return FileDelete(filename, FILE_COMMON);
        else
            return FileDelete(filename);
    }
    
    // بررسی محدوده قیمت
    bool IsPriceInRange(double entryPrice, double currentPrice, string symbol, double maxPips = 500)
    {
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double maxDistance = maxPips * point;
        double distance = MathAbs(entryPrice - currentPrice);
        return distance <= maxDistance;
    }
    
    // محاسبه حداقل فاصله
    double GetMinDistance(string symbol, double minPips = 10)
    {
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        return minPips * point;
    }
};