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
  1.0 2023-04-30 Darian Miller: Unit created
}
unit iaVCL.Logging.Memo;

interface

uses
  VCL.StdCtrls,
  iaRTL.Logging;


type

  TiaMemoLogger = class(TiaBaseLogger)
  private const
    defMaxLines = 2000;
  private
    fMaxLines:Integer;
    fMemo:TMemo;
    procedure TruncateLogAsNeeded;
  public
    constructor Create(const pMemo:TMemo);
    destructor Destroy; override;

    procedure Log(const LogEntry:string; const LogLevel:TiaLogLevel); override;

    property MaxLines:Integer read fMaxLines write fMaxLines;
  end;


implementation

uses
  System.SysUtils,
  System.Classes;


constructor TiaMemoLogger.Create(const pMemo:TMemo);
begin
  inherited Create( { UseThreadLock= } True);
  fMaxLines := defMaxLines;
  fMemo := pMemo;
end;


destructor TiaMemoLogger.Destroy;
begin

  inherited;
end;


procedure TiaMemoLogger.TruncateLogAsNeeded;
var
  i:Integer;
  HalfSize:Integer;
  NewList:TStringList;
begin
  if fMemo.Lines.Count >= fMaxLines then
  begin
    NewList := TStringList.Create;
    try
      // cut the log length in half if we reach max capacity
      // (by default, reach 2,000 lines in memo then cut back to the most recent 1,000 lines and keep logging)
      HalfSize := fMaxLines div 2;
      NewList.Capacity := HalfSize;

      NewList.BeginUpdate;
      try
        for i := HalfSize to fMemo.Lines.Count - 1 do
        begin
          NewList.Add(fMemo.Lines[i]);
        end;
      finally
        NewList.EndUpdate;
      end;

      fMemo.Lines.BeginUpdate;
      try
        fMemo.Lines.Assign(NewList);
      finally
        fMemo.Lines.EndUpdate;
      end;
    finally
      NewList.Free;
    end;
  end;
end;


procedure TiaMemoLogger.Log(const LogEntry:string; const LogLevel:TiaLogLevel);
begin
  TruncateLogAsNeeded;
  fMemo.Lines.Add(LogLevelString[Ord(LogLevel)] + ' ' + LogEntry);
end;

end.
