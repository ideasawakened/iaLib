{
  Copyright 2019 Ideas Awakened Inc.
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

  1.0 2023-04-20 Darian Miller: Unit created - for enhancing ProcessExecutor
}

unit iaRTL.EnvironmentVariables.Windows;

interface

uses
  System.Classes;

/// <summary>
/// Returns the environment block as a string. The caller should hold the
/// returned string in a variable whose lifetime spans the CreateProcess call
/// and pass PChar(Result) as the lpEnvironment parameter.
/// </summary>
function CreateEnvironmentBlock(const aEnvironmentList:TStrings):string;

function GetEnvironmentVariables(const aDestinationList:TStrings):Boolean;

implementation

uses
  System.SysUtils,
  WinAPI.Windows;


function CreateEnvironmentBlock(const aEnvironmentList:TStrings):string;
begin
  Result := StringReplace(aEnvironmentList.Text, #13#10, #0, [rfReplaceAll]); //+#0 on the end
end;

function GetEnvironmentVariables(const aDestinationList:TStrings):Boolean;
var
  StringsPtr, VarPtr:PChar;
  EnvVar:string;
begin
  StringsPtr := GetEnvironmentStrings;
  if StringsPtr^ = #0 then
    Exit(False);

  Result := True;
  try
    VarPtr := StringsPtr;

    while VarPtr^ <> #0 do
    begin
      EnvVar := StrPas(VarPtr);
      if not EnvVar.StartsWith('=') then // Don't allow invalid/funky names  ("=::=::\")
      begin
        aDestinationList.Add(EnvVar);
      end;
      Inc(VarPtr, StrLen(VarPtr) + 1);
    end;

  finally
    FreeEnvironmentStrings(StringsPtr);
  end;
end;

end.
