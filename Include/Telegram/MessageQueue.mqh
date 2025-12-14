//+------------------------------------------------------------------+
//| MessageQueue.mqh                                                 |
//+------------------------------------------------------------------+
#ifndef __MESSAGE_QUEUE_MQH__
#define __MESSAGE_QUEUE_MQH__

// تعریف کلاس MessageQueue
class CMessageQueue
{
private:
    string m_messages[]; // آرایه برای ذخیره پیام‌ها
    int m_maxSize;       // حداکثر تعداد پیام‌ها در صف

public:
    // سازنده
    CMessageQueue(int maxSize = 100)
    {
        m_maxSize = maxSize;
    }

    // افزودن پیام به صف
    bool Enqueue(string message)
    {
        if (ArraySize(m_messages) >= m_maxSize)
        {
            Print("Queue is full. Cannot enqueue message: ", message);
            return false;
        }
        ArrayResize(m_messages, ArraySize(m_messages) + 1);
        m_messages[ArraySize(m_messages) - 1] = message;
        return true;
    }

    // خواندن پیام از صف (بدون حذف)
    string Peek()
    {
        if (ArraySize(m_messages) == 0)
        {
            Print("Queue is empty.");
            return "";
        }
        return m_messages[0];
    }

    // حذف و بازگرداندن پیام از صف
    string Dequeue()
    {
        if (ArraySize(m_messages) == 0)
        {
            Print("Queue is empty.");
            return "";
        }
        string message = m_messages[0];
        ArrayRemove(m_messages, 0); // حذف اولین پیام
        return message;
    }

    // دریافت تعداد پیام‌ها در صف
    int Size()
    {
        return ArraySize(m_messages);
    }

    // بررسی خالی بودن صف
    bool IsEmpty()
    {
        return ArraySize(m_messages) == 0;
    }
};

#endif // __MESSAGE_QUEUE_MQH__
