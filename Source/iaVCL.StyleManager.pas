{
  Copyright 2020 Ideas Awakened Inc.
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
  1.0 2020-June-26 Darian Miller: Unit created
}
unit iaVCL.StyleManager;

interface

uses
  System.Classes,
  System.Generics.Collections,
  iaVCL.StyleFileList;

type

  /// <summary>
  /// Typical usage is to populate a combo box within the form's OnCreate event via:  TiaVCLStyleManager.PopulateStyleList(cboYourComboBox.Items);
  /// And then set the combo's "OnChange" event to call:  TiaVCLStyleManager.HandleSelectionChange(xx
  /// </summary>
  TiaVCLStyleManager = class
  private const
    defSubdirectoryName = 'Themes';
  private
    class var fStyleFileList:TiaVCLStyleFileList;
    class var fStyleSearchPath:string;
    class var fStyleSearchSpec:string;
    class function GetVCLStyleFileList():TiaVCLStyleFileList; static;
  public
    class constructor CreateClass();
    class destructor DestroyClass();

    // main methods for end user selecting from a list of styles
    class procedure HandleSelectionChange(const pStyleList:TStrings; const pItemIndex:Integer);
    class procedure PopulateStyleList(const pDestinationList:TStrings; const pListSystemStyleFirst:Boolean = True);

    // support
    class function IsStyleLoaded(const pStyleName:string):Boolean;
    class function TrySetStyleFile(const pStyleFile:TiaVCLStyleFile; const pShowErrorDialog:Boolean = True):Boolean;

    // customizations
    class property StyleFileList:TiaVCLStyleFileList read GetVCLStyleFileList write fStyleFileList;
    class property StyleSearchPath:string read fStyleSearchPath write fStyleSearchPath;
    class property StyleSearchSpec:string read fStyleSearchSpec write fStyleSearchSpec;
  end;


resourcestring

  SFailedToLoadStyle = 'Failed to activate style: %s. [%s]';


implementation

uses
  System.SysUtils,
  System.UITypes,
  Vcl.Dialogs,
  Vcl.Styles,
  Vcl.Themes;


class constructor TiaVCLStyleManager.CreateClass();
begin
  StyleSearchPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + defSubdirectoryName;
  StyleSearchSpec := TiaVCLStyleFileList.defVCLStyleSearchPattern;
end;


class destructor TiaVCLStyleManager.DestroyClass();
begin
  if Assigned(fStyleFileList) then
  begin
    fStyleFileList.Free();
  end;
end;


class function TiaVCLStyleManager.GetVCLStyleFileList:TiaVCLStyleFileList;
begin
  if not Assigned(fStyleFileList) then
  begin
    // lazy initialization to allow SearchPath/SearchSpec customizations
    fStyleFileList := TiaVCLStyleFileList.Create();
    StyleFileList.SetListFromPath(StyleSearchPath, StyleSearchSpec);
  end;
  Result := fStyleFileList;
end;


class function TiaVCLStyleManager.IsStyleLoaded(const pStyleName:string):Boolean;
begin
  Result := TStyleManager.Style[pStyleName] <> nil;
end;


class function TiaVCLStyleManager.TrySetStyleFile(const pStyleFile:TiaVCLStyleFile; const pShowErrorDialog:Boolean = True):Boolean;
var
  vLoadedStyle:TStyleManager.TStyleServicesHandle;
begin
  if IsStyleLoaded(pStyleFile.StyleName) then
  begin
    Result := TStyleManager.TrySetStyle(pStyleFile.StyleName, pShowErrorDialog);
  end
  else
  begin
    try
      vLoadedStyle := TStyleManager.LoadFromFile(pStyleFile.SourceFileName);
      TStyleManager.SetStyle(vLoadedStyle);
      Result := True;
    except
      on E:Exception do
      begin
        Result := False;
        if pShowErrorDialog then
        begin
          MessageDlg(Format(SFailedToLoadStyle, [pStyleFile.StyleName, E.Message]), mtError, [mbClose], 0);
        end;
      end;
    end;
  end;
end;


class procedure TiaVCLStyleManager.PopulateStyleList(const pDestinationList:TStrings; const pListSystemStyleFirst:Boolean = True);
var
  vStyleFile:TiaVCLStyleFile;
  vStyleName:string;
  vSortedStyleList:TStringList;
begin
  vSortedStyleList := TStringList.Create();
  try
    vSortedStyleList.Sorted := True;
    // Add pre-loaded styles, which includes those styles set in Project Options->Application->Appearance->Custom Styles
    // and those loaded when AutoDiscoverStyleResources = true
    for vStyleName in TStyleManager.StyleNames do
    begin
      if (not pListSystemStyleFirst) or (not SameText(vStyleName, TStyleManager.SystemStyleName)) then
      begin
        vSortedStyleList.Add(vStyleName);
      end;
    end;

    // Add styles found on disk
    for vStyleFile in StyleFileList do
    begin
      if vSortedStyleList.IndexOf(vStyleFile.StyleName) = - 1 then
      begin
        vSortedStyleList.AddObject(vStyleFile.StyleName, vStyleFile);
      end;
    end;

    pDestinationList.Assign(vSortedStyleList);
  finally
    vSortedStyleList.Free();
  end;

  if pListSystemStyleFirst then
  begin
    // Start combo with system default style "Windows"
    pDestinationList.Insert(0, TStyleManager.SystemStyleName);
  end;
end;


class procedure TiaVCLStyleManager.HandleSelectionChange(const pStyleList:TStrings; const pItemIndex:Integer);
begin
  if pItemIndex > - 1 then
  begin
    if not Assigned(pStyleList.Objects[pItemIndex]) then
    begin
      // must be a pre-loaded style, can be set by name
      TStyleManager.SetStyle(pStyleList[pItemIndex]);
    end
    else if pStyleList.Objects[pItemIndex] is TiaVCLStyleFile then
    begin
      // Will set style by name if already loaded, otherwise will load style from disk
      TiaVCLStyleManager.TrySetStyleFile(TiaVCLStyleFile(pStyleList.Objects[pItemIndex]));
    end;
  end;
end;


end.
