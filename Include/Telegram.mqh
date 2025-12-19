//+------------------------------------------------------------------+
//| Telegram.mqh - کتابخانه ساده تلگرام برای MQL5                    |
//+------------------------------------------------------------------+
#property copyright "Telegram Library"
#property version   "1.1"
#property strict

class CTelegramBot
  {
private:
   string            m_bot_token;
   string            m_chat_id;
   int               m_timeout_ms;
   
public:
                     CTelegramBot();
                    ~CTelegramBot();
   
   bool              Init(string bot_token, string chat_id, int timeout_ms = 5000);
   bool              SendMessage(string message);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTelegramBot::CTelegramBot()
  {
   m_timeout_ms = 5000;
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTelegramBot::~CTelegramBot()
  {
  }

//+------------------------------------------------------------------+
//| Initialize the bot                                               |
//+------------------------------------------------------------------+
bool CTelegramBot::Init(string bot_token, string chat_id, int timeout_ms = 5000)
  {
   m_bot_token = bot_token;
   m_chat_id = chat_id;
   m_timeout_ms = timeout_ms;
   
   // بررسی اجازه دسترسی به وب
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      Print("Warning: Terminal doesn't allow web requests");
      return false;
     }
   
   // تست ساده اتصال
   string test_url = "https://api.telegram.org/bot" + m_bot_token + "/getMe";
   uchar result[];
   string headers;
   int response_code;
   
   if(!WebRequest("GET", test_url, NULL, NULL, m_timeout_ms, NULL, 0, result, headers, response_code))
     {
      Print("Failed to connect to Telegram API. Check internet connection and URL permissions.");
      Print("Error: ", GetLastError());
      return false;
     }
   
   string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   
   if(StringFind(response, "\"ok\":true") >= 0)
     {
      Print("Telegram bot initialized successfully");
      return true;
     }
   else
     {
      Print("Failed to initialize Telegram bot. Response: ", response);
      return false;
     }
  }

//+------------------------------------------------------------------+
//| Send simple text message                                         |
//+------------------------------------------------------------------+
bool CTelegramBot::SendMessage(string message)
  {
   // کوتاه کردن پیام اگر خیلی طولانی است
   if(StringLen(message) > 4096)
     {
      message = StringSubstr(message, 0, 4093) + "...";
     }
   
   // Encode پیام برای URL (ساده‌شده)
   string encoded_message = "";
   for(int i = 0; i < StringLen(message); i++)
     {
      ushort ch = StringGetCharacter(message, i);
      if(ch == '\n')
         encoded_message += "%0A";
      else if(ch == ' ')
         encoded_message += "+";
      else if((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') ||
              ch == '.' || ch == ',' || ch == '!' || ch == '?' || ch == ':' || ch == ';' ||
              ch == '-' || ch == '_' || ch == '(' || ch == ')' || ch == '[' || ch == ']' ||
              ch == '@' || ch == '#' || ch == '$' || ch == '%' || ch == '^' || ch == '&' ||
              ch == '*' || ch == '+' || ch == '=' || ch == '/' || ch == '\\')
        {
         encoded_message += ShortToString(ch);
        }
      else
        {
         // Encode سایر کاراکترها به صورت درصدی
         encoded_message += "%" + StringFormat("%02X", ch);
        }
     }
   
   string url = "https://api.telegram.org/bot" + m_bot_token + "/sendMessage";
   string post_data = "chat_id=" + m_chat_id + "&text=" + encoded_message;
   
   uchar data[];
   uchar result[];
   string headers;
   int response_code;
   
   // تبدیل داده به آرایه بایت
   int data_len = StringToCharArray(post_data, data, 0, WHOLE_ARRAY, CP_UTF8);
   ArrayResize(data, data_len - 1);
   
   // ارسال درخواست
   if(!WebRequest("POST", url, NULL, NULL, m_timeout_ms, data, ArraySize(data), result, headers, response_code))
     {
      int error = GetLastError();
      Print("WebRequest failed. Error: ", error);
      
      // خطاهای رایج
      if(error == 4014) // ERR_FUNCTION_NOT_ALLOWED
        {
         Print("Please enable 'Allow WebRequest for listed URL' in MetaTrader settings");
         Print("Add 'api.telegram.org' to the allowed URLs list");
        }
      else if(error == 4016) // ERR_INVALID_URL
        {
         Print("Invalid URL. Check bot token and chat ID");
        }
      
      return false;
     }
   
   string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
   
   if(StringFind(response, "\"ok\":true") >= 0)
     {
      return true;
     }
   else
     {
      Print("Failed to send Telegram message. Response: ", response);
      return false;
     }
  }
//+------------------------------------------------------------------+