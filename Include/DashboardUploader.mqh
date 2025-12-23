//+------------------------------------------------------------------+
//| DashboardUploader.mqh                                            |
//| HTTP Upload for Next.js Dashboard                                |
//+------------------------------------------------------------------+

#ifndef DASHBOARD_UPLOADER_MQH
#define DASHBOARD_UPLOADER_MQH

// ================ SETTINGS ==================

input group "Dashboard Upload Settings"
input bool   EnableUpload            = true;
input string ServerUrl               = "http://127.0.0.1/api/upload";
// input string ServerUrl               = "https://momtaz-main-server.cldv.dev/api/upload";
input string UploadToken             = "my_secret_token";
input int    UploadIntervalSeconds   = 10;
input string LocalFilename           = "dashboard.html";

// ================ GLOBALS ===================

datetime last_upload_time = 0;
bool last_upload_success = false;

// ================ MAIN ======================

bool UploadDashboard()
{
    if (!FileIsExist(LocalFilename))
        return false;

    int h = FileOpen(LocalFilename, FILE_READ | FILE_BIN);
    if (h == INVALID_HANDLE)
        return false;

    int size = (int)FileSize(h);
    uchar data[];
    ArrayResize(data, size);
    FileReadArray(h, data, 0, size);
    FileClose(h);

    string headers =
        "Content-Type: text/html\r\n" +
        "X-Upload-Token: " + UploadToken + "\r\n" +
        "Content-Length: " + IntegerToString(size) + "\r\n";

    uchar result[];
    string result_headers;

    int res = WebRequest(
        "PUT",
        ServerUrl,
        headers,
        5000,
        data,
        result,
        result_headers
    );

    Print("Upload HTTP code:", res);
    return res == 200;
}

// ================ TIMER =====================

void CheckDashboardUpload()
{
    if (!EnableUpload)
        return;

    if (TimeCurrent() - last_upload_time >= UploadIntervalSeconds)
    {
        UploadDashboard();
    }
}

#endif // DASHBOARD_UPLOADER_MQH
