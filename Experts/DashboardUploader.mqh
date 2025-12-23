//+------------------------------------------------------------------+
//| DashboardUploader.mqh                                            |
//| HTTP Upload for Next.js Dashboard                                |
//+------------------------------------------------------------------+

#ifndef DASHBOARD_UPLOADER_MQH
#define DASHBOARD_UPLOADER_MQH

// ================ SETTINGS ==================

input group "Dashboard Upload Settings"
input bool   EnableUpload            = true;
input string ServerUrl               = "https://momtaz-main-server.cldv.dev/api/upload";
input string UploadToken             = "my_secret_token";
input int    UploadIntervalSeconds   = 10;
input string LocalFilename           = "dashboard.html";

// ================ GLOBALS ===================

datetime last_upload_time = 0;
bool last_upload_success = false;

// ================ MAIN ======================

bool UploadDashboard()
{
    if (!EnableUpload)
        return false;

    if (!FileIsExist(LocalFilename))
    {
        Print("Upload: File not found: ", LocalFilename);
        return false;
    }

    // Read file
    int handle = FileOpen(LocalFilename, FILE_READ | FILE_TXT | FILE_ANSI);
    if (handle == INVALID_HANDLE)
    {
        Print("Upload: Cannot open file");
        return false;
    }

    string content = "";
    while (!FileIsEnding(handle))
        content += FileReadString(handle) + "\n";
    FileClose(handle);

    if (StringLen(content) == 0)
    {
        Print("Upload: File empty");
        return false;
    }

    // Multipart body
    string boundary = "----MTBoundary" + IntegerToString(GetTickCount());
    string body =
        "--" + boundary + "\r\n"
        "Content-Disposition: form-data; name=\"token\"\r\n\r\n" +
        UploadToken + "\r\n" +

        "--" + boundary + "\r\n"
        "Content-Disposition: form-data; name=\"file\"; filename=\"dashboard.html\"\r\n"
        "Content-Type: text/html\r\n\r\n" +
        content + "\r\n" +

        "--" + boundary + "--\r\n";

    uchar data[];
    StringToCharArray(body, data);

    string headers =
        "Content-Type: multipart/form-data; boundary=" + boundary + "\r\n";

    uchar result[];
    string result_headers;

    int res = WebRequest(
        "POST",
        ServerUrl,
        headers,
        5000,
        data,
        result,
        result_headers
    );

    if (res == 200)
    {
        last_upload_success = true;
        last_upload_time = TimeCurrent();
        Print("Dashboard upload OK");
        return true;
    }

    Print("Upload failed. Code: ", res);
    last_upload_success = false;
    return false;
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
