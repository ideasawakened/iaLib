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
unit iaVCL.StyleFileList;

interface

uses
  System.Generics.Collections;

type

  TiaVCLStyleFile = class
  private
    fSourceFileName:string;
    fStyleName:string;
    fAuthor:string;
    fAuthorEMail:string;
    fAuthorURL:string;
    fVersion:string;
  public
    property SourceFileName:string read fSourceFileName write fSourceFileName;
    property StyleName:string read fStyleName write fStyleName;
    property Author:string read fAuthor write fAuthor;
    property AuthorEMail:string read fAuthorEMail write fAuthorEMail;
    property AuthorURL:string read fAuthorURL write fAuthorURL;
    property Version:string read fVersion write fVersion;
  end;


  TiaVCLStyleFileList = class(TObjectList<TiaVCLStyleFile>)
  public const
    defVCLStyleSearchPattern = '*.vsf';
  public
    procedure SetListFromPath(const pPath:string; const pSearchPattern:string=defVCLStyleSearchPattern);
  end;


implementation
uses
  System.IOUtils,
  System.SysUtils,
  System.Types,
  VCL.Themes;


procedure TiaVCLStyleFileList.SetListFromPath(const pPath:string; const pSearchPattern:string=defVCLStyleSearchPattern);
var
  vFiles:TStringDynArray;
  vStyleFileName:string;
  vStyleFile:TiaVCLStyleFile;
  vStyleInfo:TStyleInfo;
begin
  Clear;

  if TDirectory.Exists(pPath) then
  begin
    vFiles := TDirectory.GetFiles(pPath, pSearchPattern);
    for vStyleFileName in vFiles do
    begin
      if TStyleManager.IsValidStyle(vStyleFileName, vStyleInfo) then
      begin
        vStyleFile := TiaVCLStyleFile.Create();
        vStyleFile.SourceFileName := vStyleFileName;
        vStyleFile.StyleName := vStyleInfo.Name;
        vStyleFile.Author := vStyleInfo.Author;
        vStyleFile.AuthorEMail := vStyleInfo.AuthorEMail;
        vStyleFile.AuthorURL := vStyleInfo.AuthorURL;
        vStyleFile.Version := vStyleInfo.Version;
        Add(vStyleFile);
      end;
    end;
  end;
end;

end.
