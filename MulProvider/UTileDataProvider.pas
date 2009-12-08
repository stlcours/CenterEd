(*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License, Version 1.0 only
 * (the "License").  You may not use this file except in compliance
 * with the License.
 *
 * You can obtain a copy of the license at
 * http://www.opensource.org/licenses/cddl1.php.
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at
 * http://www.opensource.org/licenses/cddl1.php.  If applicable,
 * add the following below this CDDL HEADER, with the fields enclosed
 * by brackets "[]" replaced with your own identifying * information:
 *      Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 *
 *
 *      Portions Copyright 2009 Andreas Schneider
 *)
unit UTileDataProvider;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, UMulProvider, UMulBlock, UTiledata;

type
  TLandTileDataArray = array[$0..$3FFF] of TLandTileData;
  TStaticTileDataArray = array[$0..$3FFF] of TStaticTileData;
  TTiledataProvider = class(TMulProvider)
    constructor Create(AData: TStream; AReadOnly: Boolean = False); overload; override;
    constructor Create(AData: string; AReadOnly: Boolean = False); overload; override;
    destructor Destroy; override;
  protected
    FLandTiles: TLandTileDataArray;
    FStaticTiles: TStaticTileDataArray;
    procedure InitArray;
    function CalculateOffset(AID: Integer): Integer; override;
    function GetData(AID, AOffset: Integer): TMulBlock; override;
    procedure SetData(AID, AOffset: Integer; ABlock: TMulBlock); override;
  public
    function GetBlock(AID: Integer): TMulBlock; override;
    property LandTiles: TLandTileDataArray read FLandTiles;
    property StaticTiles: TStaticTileDataArray read FStaticTiles;
  end;

implementation

{ TTiledataProvider }

function TTiledataProvider.CalculateOffset(AID: Integer): Integer;
begin
  Result := GetTileDataOffset(AID);
end;

constructor TTiledataProvider.Create(AData: TStream; AReadOnly: Boolean = False);
begin
  inherited;
  InitArray;
end;

constructor TTiledataProvider.Create(AData: string; AReadOnly: Boolean = False);
begin
  inherited;
  InitArray;
end;

destructor TTiledataProvider.Destroy;
var
  i: Integer;
begin
  for i := $0 to $3FFF do
  begin
    FreeAndNil(FLandTiles[i]);
    FreeAndNil(FStaticTiles[i]);
  end;

  inherited;
end;

function TTiledataProvider.GetBlock(AID: Integer): TMulBlock;
begin
  Result := GetData(AID, 0);
end;

function TTiledataProvider.GetData(AID, AOffset: Integer): TMulBlock;
begin
  if AID < $4000 then
    Result := TMulBlock(FLandTiles[AID].Clone)
  else
    Result := TMulBlock(FStaticTiles[AID - $4000].Clone);
  Result.ID := AID;
  Result.OnChanged := @OnChanged;
  Result.OnFinished := @OnFinished;
end;

procedure TTiledataProvider.InitArray;
var
  i: Integer;
begin
  for i := $0 to $3FFF do
  begin
    FData.Position := GetTileDataOffset(i);
    FLandTiles[i] := TLandTileData.Create(FData);
  end;

  for i := $0 to $3FFF do
  begin
    FData.Position := GetTileDataOffset($4000 + i);
    FStaticTiles[i] := TStaticTileData.Create(FData);
  end;
end;

procedure TTiledataProvider.SetData(AID, AOffset: Integer;
  ABlock: TMulBlock);
begin
  if AID < $4000 then
  begin
    FreeAndNil(FLandTiles[AID]);
    FLandTiles[AID] := TLandTileData(ABlock.Clone);
  end else
  begin
    FreeAndNil(FStaticTiles[AID - $4000]);
    FStaticTiles[AID - $4000] := TStaticTileData(ABlock.Clone);
  end;

  if not FReadOnly then
  begin
    FData.Position := AOffset;
    ABlock.Write(FData);
  end;
end;

end.

