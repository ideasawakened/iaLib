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
}
unit iaRTL.ScreenCursorStack;

{$include iaCrossFramework.inc}
interface
uses
  System.UITypes;

type

  TiaScreenCursorStack = class
  public
    class procedure PushCursor(const aNewCursor:TCursor);
    class procedure PopCursor;
  end;


implementation
{$IFDEF VCL}
uses
  iaVCL.ScreenCursorStack;
{$IFEND}

//Expected compilation error due to two 'Uses' clause if both VCL and FMX are defined in one app

{$IFDEF FMX}
uses
  iaFMX.ScreenCursorStack;
{$IFEND}


{$IFDEF VCL}
class procedure TiaScreenCursorStack.PushCursor(const aNewCursor:TCursor);
begin
  TiaVCLScreenCursorStack.PushCursor(aNewCursor);
end;

class procedure TiaScreenCursorStack.PopCursor;
begin
  TiaVCLScreenCursorStack.PopCursor();
end;
{$IFEND}


{$IFDEF FMX}
class procedure TiaScreenCursorStack.PushCursor(const aNewCursor:TCursor);
begin
  TiaFMXScreenCursorStack.PushCursor(aNewCursor);
end;

class procedure TiaScreenCursorStack.PopCursor;
begin
  TiaFMXScreenCursorStack.PopCursor();
end;
{$IFEND}


end.
