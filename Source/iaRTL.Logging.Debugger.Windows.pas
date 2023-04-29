{
  Copyright 2023 Ideas Awakened Inc.
  Part of the "iaLib" shared code library for Delphi
  For more detail, see: https://github.com/ideasawakened/iaLib

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.


  Module History
  1.0 2023-04-29 Darian Miller: Unit created
}
unit iaRTL.Logging.Debugger.Windows;

interface

uses
  iaRTL.Logging;

type

  TiaWindowsDebugLogging = class(TiaBaseLogger)
  protected
    procedure DoLog(const LogEntry:string; const LogLevel:TiaLogLevel); override;
  end;


implementation

uses
  System.SysUtils,
  WinAPI.Windows;


procedure TiaWindowsDebugLogging.DoLog(const LogEntry:string; const LogLevel:TiaLogLevel);
var
  FormattedEntry:string;
begin
  FormattedEntry := Format('[%s] ' + LogEntry, [LogLevelString[Ord(LogLevel)]]);
  OutputDebugString(PChar(FormattedEntry));
end;


end.
