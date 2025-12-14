
#ifndef __InputUtils_MQH__
#define __InputUtils__
//--- متغیرهای عمومی

sinput string header5 = ""; // =========== Global ===========

input int timer_interval = 3000;                                    // زمان‌بندی تایمر
input int MinimumProfitPips = 150;                                  // Minimum Profit Pips To close Pending Orders
input int totalAllowedPercent = 25;                                 // Allowed Total Margin(percent)
input int totalLotSize = 8;                                         // Total Lot Size each signal
input ENUM_ORDER_TYPE_FILLING OrderFillingType = ORDER_FILLING_FOK; // Order Filling Mode
sinput string header = "";                                          // =========== First Category ===========
input int DefaultTp_1 = 1200;                                       //  Tp (pips) for signals without Tp
input int maxSlPips_1 = 500;                                        // MAximum Sl Distance from Price(pipet)
input int addedTp_1 = 30;                                           // Add Pips To Tp
input int addedSl_Buy_1 = 80;                                       // Add Pips To Sl For Buy Positions
input int addedSl__Sell_1 = 80;                                     // Add Pips To Sl For Sell Positions
input int added_limit_Tp_1 = 30;                                    // Add Pips To Limits Tp
input int added_limit_Sl_Buy_1 = 80;                                // Add Pips To Limits Sl For Buy Positions
input int added_limit_Sl_Sell_1 = 80;                               // Add Pips To Limits Sl For Sell Positions
input int HighAllowed_1 = 550;                                      // Allowed Range from market price(High)
input int LowAllowed_1 = 180;                                       // Allowed Range from market price(Low)
input int manualOrderSL_1 = 500;                                    // Sl Pips For Manual Orders
input int limit_lotSize_1 = 5;                                      // Default Limit Lot Size *100
input int limit_Price_spread_buy_1 = 50;                            // Add Pips To limit Prices(buy)
input int limit_Price_spread_sell_1 = 50;                           // Add Pips To limit Prices(sell)
input int t1_1 = 10;                                                // RM First Target(pip)
input int t2_1 = 15;                                                // RM Second Target(pip)
input int t3_1 = 20;                                                // RM third Target(pip)
input int minimumProfitTpTouch_1 = 20;                              // RM Minimum profits to touch TP
input int cv1_1 = 1;                                                // RM first Close Volume
input int cv2_1 = 1;                                                // RM second Close Volume
input int cv3_1 = 1;                                                // RM third Close Volume
input int rf_1 = 100;                                               // RM Risk Free Pips| for Gold *10
input int ts_1 = 1;                                                 // RM Trailing Step Pips
input int tpTouch_1 = 8;                                            // RM Tp Touch Margin(pip)
input int openTpValue_1 = 500;                                      // add pips for open Tp

sinput string header2 = "";               // =========== Second Category ===========
input int DefaultTp_2 = 150;              //  Tp (pips) for signals without Tp
input int maxSlPips_2 = 500;              // MAximum Sl Distance from Price(pipet)
input int addedTp_2 = 20;                 // Add Pips To Tp
input int addedSl_Buy_2 = 80;             // Add Pips To Sl For Buy Positions
input int addedSl__Sell_2 = 80;           // Add Pips To Sl For Sell Positions
input int added_limit_Tp_2 = 30;          // Add Pips To Limits Tp
input int added_limit_Sl_Buy_2 = 80;      // Add Pips To Limits Sl For Buy Positions
input int added_limit_Sl_Sell_2 = 80;     // Add Pips To Limits Sl For Sell Positions
input int HighAllowed_2 = 450;            // Allowed Range from market price(High)
input int LowAllowed_2 = 60;              // Allowed Range from market price(Low)
input int manualOrderSL_2 = 90;           // Sl Pips For Manual Orders
input double limit_lotSize_2 = 100;       // Default Limit Lot Size *100
input int limit_Price_spread_buy_2 = 20;  // Add Pips To limit Prices(buy)
input int limit_Price_spread_sell_2 = 20; // Add Pips To limit Prices(sell)
input int t1_2 = 500;                     // RM First Target
input int t2_2 = 750;                     // RM Second Target
input int t3_2 = 1000;                    // RM third Target
input int minimumProfitTpTouch_2 = 20;    // RM Minimum profits to touch TP
input int cv1_2 = 1;                      // RM first Close Volume
input int cv2_2 = 1;                      // RM second Close Volume
input int cv3_2 = 1;                      // RM third Close Volume
input int rf_2 = 200;                     // RM Risk Free Pips
input int ts_2 = 200;                     // RM Trailing Step Pips
input int tpTouch_2 = 200;                // RM Tp Touch Margin(pip)
input int openTpValue_2 = 2000;           // add pips for open Tp

sinput string header3 = "";               // =========== Third Category ===========
input int DefaultTp_3 = 600;              //  Tp (pips) for signals without Tp
input int maxSlPips_3 = 500;              // MAximum Sl Distance from Price(pipet)
input int addedTp_3 = 20;                 // Add Pips To Tp
input int addedSl_Buy_3 = 80;             // Add Pips To Sl For Buy Positions
input int addedSl__Sell_3 = 80;           // Add Pips To Sl For Sell Positions
input int added_limit_Tp_3 = 20;          // Add Pips To Limits Tp
input int added_limit_Sl_Buy_3 = 80;      // Add Pips To Limits Sl For Buy Positions
input int added_limit_Sl_Sell_3 = 80;     // Add Pips To Limits Sl For Sell Positions
input int HighAllowed_3 = 550;            // Allowed Range from market price(High)
input int LowAllowed_3 = 80;              // Allowed Range from market price(Low)
input int manualOrderSL_3 = 500;          // Sl Pips For Manual Orders
input double limit_lotSize_3 = 20;        // Default Limit Lot Size *100
input int limit_Price_spread_buy_3 = 30;  // Add Pips To limit Prices(buy)
input int limit_Price_spread_sell_3 = 30; // Add Pips To limit Prices(sell)
input int t1_3 = 10;                      // RM First Target
input int t2_3 = 20;                      // RM Second Target
input int t3_3 = 75;                      // RM third Target
input int minimumProfitTpTouch_3 = 20;    // RM Minimum profits to touch TP
input int cv1_3 = 1;                      // RM first Close Volume
input int cv2_3 = 1;                      // RM second Close Volume
input int cv3_3 = 1;                      // RM third Close Volume
input int rf_3 = 50;                      // RM Risk Free Pips
input int ts_3 = 10;                      // RM Trailing Step Pips
input int tpTouch_3 = 8;                  // RM Tp Touch Margin(pip)
input int openTpValue_3 = 500;            // add pips for open Tp

sinput string header4 = "";               // =========== Forth Category ===========
input int DefaultTp_4 = 600;              //  Tp (pips) for signals without Tp
input int maxSlPips_4 = 500;              // MAximum Sl Distance from Price(pipet)
input int addedTp_4 = 20;                 // Add Pips To Tp
input int addedSl_Buy_4 = 80;             // Add Pips To Sl For Buy Positions
input int addedSl__Sell_4 = 80;           // Add Pips To Sl For Sell Positions
input int added_limit_Tp_4 = 20;          // Add Pips To Limits Tp
input int added_limit_Sl_Buy_4 = 80;      // Add Pips To Limits Sl For Buy Positions
input int added_limit_Sl_Sell_4 = 80;     // Add Pips To Limits Sl For Sell Positions
input int HighAllowed_4 = 550;            // Allowed Range from market price(High)
input int LowAllowed_4 = 80;              // Allowed Range from market price(Low)
input int manualOrderSL_4 = 500;          // Sl Pips For Manual Orders
input double limit_lotSize_4 = 20;        // Default Limit Lot Size *100
input int limit_Price_spread_buy_4 = 30;  // Add Pips To limit Prices(buy)
input int limit_Price_spread_sell_4 = 30; // Add Pips To limit Prices(sell)
input int t1_4 = 10;                      // RM First Target
input int t2_4 = 20;                      // RM Second Target
input int t3_4 = 75;                      // RM third Target
input int minimumProfitTpTouch_4 = 20;    // RM Minimum profits to touch TP
input int cv1_4 = 1;                      // RM first Close Volume
input int cv2_4 = 1;                      // RM second Close Volume
input int cv3_4 = 1;                      // RM third Close Volume
input int rf_4 = 50;                      // RM Risk Free Pips
input int ts_4 = 10;                      // RM Trailing Step Pips
input int tpTouch_4 = 8;                  // RM Tp Touch Margin(pip)
input int openTpValue_4 = 500;            // add pips for open Tp

//+------------------------------------------------------------------+
//| Get Setting Functions                                                  |
//+------------------------------------------------------------------+
int GetGroupNumber(string symbol)
{
    if (StringFind("GOLD|XAUUSD", symbol) >= 0)
        return 1; // گروه 1
    if (StringFind("US30|US_30|NAZDAQ|NAS100", symbol) >= 0)
        return 2; // گروه 2
    if (StringFind("BITCOIN|BTCUSD", symbol) >= 0)
        return 3; // گروه 3
                  // به صورت پیش‌فرض دسته 3 را بازگردان
    return 4;
}

int GetTargetValue(int groupNumber, int targetIndex)
{
    switch (groupNumber)
    {
    case 1:
        if (targetIndex == 1)
            return t1_1;
        if (targetIndex == 2)
            return t2_1;
        if (targetIndex == 3)
            return t3_1;
        if (targetIndex == 4)
            return cv1_1;
        if (targetIndex == 5)
            return cv2_1;
        if (targetIndex == 6)
            return cv2_1;
        if (targetIndex == 7)
            return ts_1;
        if (targetIndex == 8)
            return rf_1;
        if (targetIndex == 9)
            return addedTp_1;
        if (targetIndex == 10)
            return addedSl__Sell_1;
        if (targetIndex == 20)
            return addedSl_Buy_1;
        if (targetIndex == 11)
            return DefaultTp_1;
        if (targetIndex == 12)
            return limit_lotSize_1;
        if (targetIndex == 13)
            return added_limit_Tp_1;
        if (targetIndex == 14)
            return added_limit_Sl_Buy_1;
        if (targetIndex == 21)
            return added_limit_Sl_Sell_1;
        if (targetIndex == 15)
            return manualOrderSL_1;
        if (targetIndex == 16)
            return HighAllowed_1;
        if (targetIndex == 17)
            return LowAllowed_1;
        if (targetIndex == 18)
            return limit_Price_spread_buy_1;
        if (targetIndex == 19)
            return limit_Price_spread_sell_1;
        if (targetIndex == 22)
            return tpTouch_1;
        if (targetIndex == 23)
            return openTpValue_1;
        if (targetIndex == 24)
            return minimumProfitTpTouch_1;
        if (targetIndex == 25)
            return maxSlPips_1;
        break;
    case 2:
        if (targetIndex == 1)
            return t1_2;
        if (targetIndex == 2)
            return t2_2;
        if (targetIndex == 3)
            return t3_2;
        if (targetIndex == 4)
            return cv1_2;
        if (targetIndex == 5)
            return cv2_2;
        if (targetIndex == 6)
            return cv3_2;
        if (targetIndex == 7)
            return ts_2;
        if (targetIndex == 8)
            return rf_2;
        if (targetIndex == 9)
            return addedTp_2;
        if (targetIndex == 10)
            return addedSl__Sell_2;
        if (targetIndex == 20)
            return addedSl_Buy_2;
        if (targetIndex == 11)
            return DefaultTp_2;
        if (targetIndex == 12)
            return limit_lotSize_2;
        if (targetIndex == 13)
            return added_limit_Tp_2;
        if (targetIndex == 14)
            return added_limit_Sl_Buy_2;
        if (targetIndex == 21)
            return added_limit_Sl_Sell_2;
        if (targetIndex == 15)
            return manualOrderSL_2;
        if (targetIndex == 16)
            return HighAllowed_2;
        if (targetIndex == 17)
            return LowAllowed_2;
        if (targetIndex == 18)
            return limit_Price_spread_buy_2;
        if (targetIndex == 19)
            return limit_Price_spread_sell_2;
        if (targetIndex == 22)
            return tpTouch_2;
        if (targetIndex == 23)
            return openTpValue_2;
        if (targetIndex == 24)
            return minimumProfitTpTouch_2;
        if (targetIndex == 25)
            return maxSlPips_2;

        break;
    case 3:
        if (targetIndex == 1)
            return t1_3;
        if (targetIndex == 2)
            return t2_3;
        if (targetIndex == 3)
            return t3_3;
        if (targetIndex == 4)
            return cv1_3;
        if (targetIndex == 5)
            return cv2_3;
        if (targetIndex == 6)
            return cv3_3;
        if (targetIndex == 7)
            return ts_3;
        if (targetIndex == 8)
            return rf_3;
        if (targetIndex == 9)
            return addedTp_3;
        if (targetIndex == 10)
            return addedSl__Sell_3;
        if (targetIndex == 20)
            return addedSl_Buy_3;
        if (targetIndex == 11)
            return DefaultTp_3;
        if (targetIndex == 12)
            return limit_lotSize_3;
        if (targetIndex == 13)
            return added_limit_Tp_3;
        if (targetIndex == 14)
            return added_limit_Sl_Buy_3;
        if (targetIndex == 21)
            return added_limit_Sl_Sell_3;
        if (targetIndex == 15)
            return manualOrderSL_3;
        if (targetIndex == 16)
            return HighAllowed_3;
        if (targetIndex == 17)
            return LowAllowed_3;
        if (targetIndex == 18)
            return limit_Price_spread_buy_3;
        if (targetIndex == 19)
            return limit_Price_spread_sell_3;
        if (targetIndex == 22)
            return tpTouch_3;
        if (targetIndex == 23)
            return openTpValue_3;
        if (targetIndex == 24)
            return minimumProfitTpTouch_3;
        if (targetIndex == 25)
            return maxSlPips_3;

        break;
    case 4:
        if (targetIndex == 1)
            return t1_4;
        if (targetIndex == 2)
            return t2_4;
        if (targetIndex == 3)
            return t3_4;
        if (targetIndex == 4)
            return cv1_4;
        if (targetIndex == 5)
            return cv2_4;
        if (targetIndex == 6)
            return cv3_4;
        if (targetIndex == 7)
            return ts_4;
        if (targetIndex == 8)
            return rf_4;
        if (targetIndex == 9)
            return addedTp_4;
        if (targetIndex == 10)
            return addedSl__Sell_4;
        if (targetIndex == 20)
            return addedSl_Buy_4;
        if (targetIndex == 11)
            return DefaultTp_4;
        if (targetIndex == 12)
            return limit_lotSize_4;
        if (targetIndex == 13)
            return added_limit_Tp_4;
        if (targetIndex == 14)
            return added_limit_Sl_Buy_4;
        if (targetIndex == 21)
            return added_limit_Sl_Sell_4;
        if (targetIndex == 15)
            return manualOrderSL_4;
        if (targetIndex == 16)
            return HighAllowed_4;
        if (targetIndex == 17)
            return LowAllowed_4;
        if (targetIndex == 18)
            return limit_Price_spread_buy_4;
        if (targetIndex == 19)
            return limit_Price_spread_sell_4;
        if (targetIndex == 22)
            return tpTouch_4;
        if (targetIndex == 23)
            return openTpValue_4;
        if (targetIndex == 24)
            return minimumProfitTpTouch_4;
        if (targetIndex == 25)
            return maxSlPips_4;

        break;
    default:
        Print("Invalid group number: ", groupNumber);
        return -1;
    }
    return -1;
}
#endif // __InputUtils_MQH__