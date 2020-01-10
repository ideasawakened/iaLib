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
unit iaVCL.ScreenCursorStack;

interface
uses
  System.Generics.Collections,
  System.UITypes;

type

  TiaVCLScreenCursorStack = class
  private
    class var fCustomCursors:TStack<SmallInt>;
  public
    class constructor CreateClass;
    class destructor DestroyClass;

    class procedure PushCursor(const aNewCursor:TCursor);
    class procedure PopCursor;
  end;


implementation
uses
  VCL.Forms;


class constructor TiaVCLScreenCursorStack.CreateClass;
begin
  fCustomCursors := TStack<SmallInt>.Create;
end;


class destructor TiaVCLScreenCursorStack.DestroyClass;
begin
  fCustomCursors.Free;
end;


class procedure TiaVCLScreenCursorStack.PushCursor(const aNewCursor:TCursor);
begin
  fCustomCursors.Push(Screen.Cursor);
  Screen.Cursor := aNewCursor;
end;


class procedure TiaVCLScreenCursorStack.PopCursor;
var
  vCount:Integer;
  vPreviousCursor:TCursor;
begin
  vCount := fCustomCursors.Count;
  Assert(vCount > 0, 'PopCursor used without a corresponding PushCursor');

  if vCount > 0 then
  begin
    vPreviousCursor := fCustomCursors.Pop;
    Screen.Cursor := vPreviousCursor;
  end;
end;


end.
