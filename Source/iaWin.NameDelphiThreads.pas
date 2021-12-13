unit iaWin.NameDelphiThreads;

interface
uses
  WinAPI.Windows;

  procedure NameDelphiThreads(const pMainThreadId:THandle);

implementation
uses
  System.SysUtils,
  System.Classes,
  WinAPI.TlHelp32;


procedure NameDelphiThreads(const pMainThreadId:THandle);
var
  vSnapshot:THandle;
  vProcessId:THandle;
  vTE32:TThreadEntry32;
  i:Integer;
begin
  vProcessId := GetCurrentProcessId();

  vSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, vProcessId);
  if vSnapshot <> INVALID_HANDLE_VALUE then
  begin
    try
      vTE32.dwSize := SizeOf(vTE32); //If you do not initialize dwSize, Thread32First fails.
      if Thread32First(vSnapshot, vTE32) then
      begin
        i := 1;
        repeat
          if vTE32.th32OwnerProcessID = vProcessId then
          begin
            if vTE32.th32ThreadID = pMainThreadId then
            begin
              TThread.NameThreadForDebugging('DelphiCreated_Main', pMainThreadId);
            end
            else
            begin
              TThread.NameThreadForDebugging('DelphiCreated_' + AnsiString(IntToStr(i)), vTE32.th32ThreadID);
              Inc(i);
            end;
          end;
        until not Thread32Next(vSnapshot, vTE32);
      end;
    finally
      CloseHandle(vSnapshot);
    end;
  end;
end;

{$IFDEF DEBUG}
initialization
  NameDelphiThreads(GetCurrentThreadId);
{$ENDIF}

end.
