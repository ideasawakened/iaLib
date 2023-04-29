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
unit iaRTL.Logging.CodeSite;

interface

uses
  iaRTL.Logging,
  CodeSiteLogging;


type

  TiaCodeSiteLogger = class(TiaBaseLogger)
  private
    fCodeSiteLogger:TCodeSiteLogger;
    fOwnCodeSiteLogger:Boolean;
  protected
    function GetLoggingIsEnabled:Boolean; override;
    procedure SetLoggingIsEnabled(const NewEnabledState:Boolean); override;
    procedure DoLog(const LogEntry:string; const LogLevel:TiaLogLevel); override;

    function CodeSiteLogLevel(const LogLevel:TiaLogLevel):Integer;
  public
    constructor Create(const Logger:TCodeSiteLogger; const OwnsLogger:Boolean = False); overload;
    constructor Create(const CodeSiteDestinationAsString:string); overload;
    destructor Destroy; override;
  end;


implementation

uses
  System.SysUtils;


constructor TiaCodeSiteLogger.Create(const Logger:TCodeSiteLogger; const OwnsLogger:Boolean = False);
begin
  inherited Create;
  fCodeSiteLogger := Logger;
  fOwnCodeSiteLogger := OwnsLogger;
  if Logger.Enabled <> IsEnabled then
  begin
    IsEnabled := Logger.Enabled;
  end;
end;


constructor TiaCodeSiteLogger.Create(const CodeSiteDestinationAsString:string);
begin
  inherited Create;
  fCodeSiteLogger := TCodeSiteLogger.Create(nil);
  fOwnCodeSiteLogger := True;

  fCodeSiteLogger.Destination := TCodeSiteDestination.Create(fCodeSiteLogger);
  fCodeSiteLogger.Destination.AsString := CodeSiteDestinationAsString;
end;


destructor TiaCodeSiteLogger.Destroy;
begin
  if fOwnCodeSiteLogger then
  begin
    fCodeSiteLogger.Free;
  end;
  inherited;
end;


function TiaCodeSiteLogger.GetLoggingIsEnabled:Boolean;
begin
  inherited;
  Result := fCodeSiteLogger.Enabled;
end;


procedure TiaCodeSiteLogger.SetLoggingIsEnabled(const NewEnabledState:Boolean);
begin
  inherited;
  fCodeSiteLogger.Enabled := NewEnabledState;
end;


procedure TiaCodeSiteLogger.DoLog(const LogEntry:string; const LogLevel:TiaLogLevel);
begin
  fCodeSiteLogger.Send(CodeSiteLogLevel(LogLevel), LogEntry);
end;


function TiaCodeSiteLogger.CodeSiteLogLevel(const LogLevel:TiaLogLevel):Integer;
begin
  case LogLevel of
    Undefined, All, Verbose, Debug, Info:
      Result := csmInfo;
    Warning:
      Result := csmWarning;
    Error, Fatal:
      Result := csmError;
  else
    Assert(False, 'Invalid LogLevel passed to CodeSiteLogLevel, #' + IntToStr(Ord(LogLevel)));
    Result := csmInfo;
  end;
end;

end.
