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
  1.0 2020-June-24 Darian Miller: Unit created
}
unit iaVCL.SynEdit.StyleHook;

interface

uses
  Winapi.Messages,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.Styles,
  Vcl.Themes,
  SynEdit;

type

  // Interposer - add this unit after SynEdit in the uses statement so this class will be used rather than the original
  TSynEdit = class(SynEdit.TSynEdit)
  protected
    procedure CMStyleChanged(var Message:TMessage); message CM_STYLECHANGED;
    procedure Loaded(); override;
    procedure UpdateCustomStyle();
  end;


implementation


procedure TSynEdit.CMStyleChanged(var Message:TMessage);
begin
  UpdateCustomStyle();
  Invalidate();
end;


procedure TSynEdit.Loaded();
begin
  inherited;
  UpdateCustomStyle();
end;


procedure TSynEdit.UpdateCustomStyle();
var
  vActiveStyle:TCustomStyleServices;
begin
  vActiveStyle := TStyleManager.ActiveStyle;

  Color := vActiveStyle.GetStyleColor(scEdit);
  Font.Color := vActiveStyle.GetStyleFontColor(sfEditBoxTextNormal);
  RightEdgeColor := vActiveStyle.GetStyleColor(scSplitter);
  ScrollHintColor := vActiveStyle.GetSystemColor(clInfoBk);
  ActiveLineColor := clNone;
  Gutter.Color := vActiveStyle.GetStyleColor(scPanel);
  Gutter.Font.Color := vActiveStyle.GetStyleFontColor(sfPanelTextNormal);
  Gutter.GradientStartColor := vActiveStyle.GetStyleColor(scToolBarGradientBase);
  Gutter.GradientEndColor := vActiveStyle.GetStyleColor(scToolBarGradientEnd);
  Gutter.BorderColor := vActiveStyle.GetStyleColor(scSplitter);
  // Optional items: I tend to prefer the default selected text colors rather than theme colors
  // SelectedColor.Background := vActiveStyle.GetSystemColor(clHighlight);
  // SelectedColor.Foreground := vActiveStyle.GetSystemColor(clHighlightText);
end;


initialization

// handles styling of the scroll bars
TStyleManager.Engine.RegisterStyleHook(TSynEdit, TScrollBoxStyleHook);


finalization

TStyleManager.Engine.UnRegisterStyleHook(TSynEdit, TScrollBoxStyleHook);

end.
