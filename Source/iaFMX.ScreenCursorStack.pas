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
unit iaFMX.ScreenCursorStack;

interface
uses
  System.Generics.Collections,
  System.UITypes,
  FMX.Types;

type

  TiaFMXScreenCursorStack = class(TInterfacedObject, IFMXCursorService)
  private
    class var fCustomCursors:TStack<SmallInt>;
    class var fFMXCursorService:IFMXCursorService;
    class var fIACursorService:TiaFMXScreenCursorStack;
    class var fOriginalCursor:TCursor;
  protected
    class constructor CreateClass;
    class destructor DestroyClass;

    procedure SetCursor(const aNewCursor:TCursor);
    function GetCursor: TCursor;
  public
    class procedure PushCursor(const aNewCursor:TCursor);
    class procedure PopCursor;
  end;


implementation
uses
  FMX.Platform;


class constructor TiaFMXScreenCursorStack.CreateClass;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXCursorService) then
  begin
    fFMXCursorService := TPlatformServices.Current.GetPlatformService(IFMXCursorService) as IFMXCursorService;
    if Assigned(fFMXCursorService) then
    begin
      fIACursorService := TiaFMXScreenCursorStack.Create;
      TPlatformServices.Current.RemovePlatformService(IFMXCursorService);
      TPlatformServices.Current.AddPlatformService(IFMXCursorService, fIACursorService); //FMX will manage fIACursorService instance
    end;
  end;
  fOriginalCursor := crDefault;
  fCustomCursors := TStack<SmallInt>.Create;
end;


class destructor TiaFMXScreenCursorStack.DestroyClass;
begin
  fCustomCursors.Free;
end;


class procedure TiaFMXScreenCursorStack.PushCursor(const aNewCursor:TCursor);
begin
  if Assigned(fFMXCursorService) then
  begin
    //establish a new cursor until popped
    //It is up to developer to always follow a PushCursor with a corresponding PopCursor
    if fCustomCursors.Count = 0 then
    begin
      fOriginalCursor := fFMXCursorService.GetCursor;
    end;
    fCustomCursors.Push(aNewCursor);
    fFMXCursorService.SetCursor(aNewCursor);
  end;
end;


class procedure TiaFMXScreenCursorStack.PopCursor;
var
  vCount:Integer;
  vCustomCursor:TCursor;
begin
  if Assigned(fFMXCursorService) then
  begin
    vCount := fCustomCursors.Count;
    Assert(vCount > 0, 'PopCursor used without a corresponding PushCursor');

    if vCount > 0 then
    begin
      vCustomCursor := fCustomCursors.Pop;
      if fCustomCursors.Count = 0 then
      begin
        //no more custom cursors in our stack, back to system control
        fFMXCursorService.SetCursor(fOriginalCursor);
        fOriginalCursor := crDefault;
      end
      else
      begin
        //continue overriding the cursor with our previous custom cursor
        fFMXCursorService.SetCursor(vCustomCursor);
      end;
    end;
  end;
end;


function TiaFMXScreenCursorStack.GetCursor:TCursor;
begin
  //default FMX behavior
  Result := fFMXCursorService.GetCursor;
end;


procedure TiaFMXScreenCursorStack.SetCursor(const aNewCursor:TCursor);
var
  vCount:Integer;
  vCustomCursor:TCursor;
begin
  vCount := fCustomCursors.Count;
  if vCount > 0 then
  begin
    //Custom behavior as we've pushed at least one custom cursor onto the stack
    //use the custom one instead of what the system wanted to change the cursor to
    vCustomCursor := fCustomCursors.Peek;
    fFMXCursorService.SetCursor(vCustomCursor);
  end
  else
  begin
    //default FMX behavior
    fFMXCursorService.SetCursor(aNewCursor);
  end;
end;


end.
