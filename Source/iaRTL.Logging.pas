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
unit iaRTL.Logging;

interface
uses
  System.SyncObjs;

type

  TiaLogLevel = (Undefined, All, Verbose, Debug, Info, Warning, Error, Fatal);


  ILogger = interface
    ['{E30A5B0F-ABD8-4313-8883-2B65C9FECE61}']
    procedure Log(const LogEntry:string; const LogLevel:TiaLogLevel = Debug);

    function GetCurrentLogLevel:TiaLogLevel;
    procedure SetCurrentLogLevel(const NewLevel:TiaLogLevel);

    function GetLoggingIsEnabled:Boolean;
    procedure SetLoggingIsEnabled(const NewEnabledState:Boolean);
  end;


  TiaBaseLogger = class(TInterfacedObject, ILogger)
  private const
    defLogLevel = TiaLogLevel.Debug;
  private
    fLogLevel:TiaLogLevel;
    fIsEnabled:Boolean;
    fThreadLock:TCriticalSection;
    fUseThreadLock:Boolean;
  protected
    function GetCurrentLogLevel:TiaLogLevel; virtual;
    procedure SetCurrentLogLevel(const NewLevel:TiaLogLevel); virtual;

    function GetLoggingIsEnabled:Boolean; virtual;
    procedure SetLoggingIsEnabled(const NewEnabledState:Boolean); virtual;

    procedure DoLog(const LogEntry:string; const LogLevel:TiaLogLevel); virtual;
  public
    constructor Create(const UseThreadLock:Boolean=False);
    destructor Destroy; override;

    procedure Log(const LogEntry:string; const LogLevel:TiaLogLevel = TiaLogLevel.Debug); virtual;

    property LogLevel:TiaLogLevel read GetCurrentLogLevel write SetCurrentLogLevel;
    property IsEnabled:Boolean read GetLoggingIsEnabled write SetLoggingIsEnabled;
  end;


const
  LogLevelString: array [0 .. Ord(TiaLogLevel.Fatal)] of string = ('Undefined', 'All', 'Verbose', 'Debug', 'Info', 'Warning', 'Error', 'Fatal');


implementation


constructor TiaBaseLogger.Create(const UseThreadLock:Boolean=False);
begin
  inherited Create;
  fLogLevel := defLogLevel;
  fUseThreadLock := UseThreadLock;
  if UseThreadLock then
  begin
    fThreadLock := TCriticalSection.Create;
  end;
end;


destructor TiaBaseLogger.Destroy;
begin
  if fUseThreadLock then
  begin
    fThreadLock.Free;
  end;
  inherited;
end;

function TiaBaseLogger.GetCurrentLogLevel:TiaLogLevel;
begin
  Result := fLogLevel;
end;


procedure TiaBaseLogger.SetCurrentLogLevel(const NewLevel:TiaLogLevel);
begin
  fLogLevel := NewLevel;
end;


function TiaBaseLogger.GetLoggingIsEnabled:Boolean;
begin
  Result := fIsEnabled;
end;


procedure TiaBaseLogger.SetLoggingIsEnabled(const NewEnabledState:Boolean);
begin
  fIsEnabled := NewEnabledState;
end;


procedure TiaBaseLogger.Log(const LogEntry:string; const LogLevel:TiaLogLevel = TiaLogLevel.Debug);
    procedure DoIt;
    begin
      if IsEnabled and (Ord(LogLevel) >= Ord(self.LogLevel)) then
      begin
        DoLog(LogEntry, LogLevel);
      end;
    end;
begin
  if fUseThreadLock then
  begin
    fThreadLock.Enter;
    try
      DoIt;
    finally
      fThreadLock.Leave;
    end;
  end
  else
  begin
    DoIt;
  end;
end;



procedure TiaBaseLogger.DoLog(const LogEntry:string; const LogLevel:TiaLogLevel);
begin
  // bitbucket unless overriden
end;


end.
