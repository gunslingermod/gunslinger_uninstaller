unit main;

{$mode objfpc}{$H+}

interface

uses
  windows, Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls;

type

  { TMainForm }

  TMainForm = class(TForm)
    btn_yes: TButton;
    btn_no: TButton;
    Image1: TImage;
    lbl_info: TLabel;
    procedure btn_noClick(Sender: TObject);
    procedure btn_yesClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

const
  UNINSTALL_DATA_PATH:string='uninstall.dat';
  USERLTX_PATH:string = 'userdata\user.ltx';
  FSGAME_PATH:string='fsgame.ltx';
  RUS_ID:cardinal=1049;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
var
  locale:cardinal;
const
  BTN_OFFSET:integer=100;
begin
  locale:=GetSystemDefaultLangID();
  if locale = RUS_ID then begin
    lbl_info.Caption:='Удалить GUNSLINGER Mod?';
    btn_yes.Caption:='Да';
    btn_no.Caption:='Нет';
  end else begin
    lbl_info.Caption:='Do you really want to uninstall GUNSLINGER Mod?';
    btn_yes.Caption:='Yes';
    btn_no.Caption:='No';
  end;

  self.Image1.Top:=0;
  self.Image1.Left:=0;
  self.Image1.Width:=self.Image1.Picture.Width;
  self.Image1.Height:=self.Image1.Picture.Height;
  self.Width:=self.Image1.Width;
  self.Height:=self.Image1.Height;

  self.btn_yes.Top:=(self.Height*2) div 3;
  self.btn_no.Top:=(self.Height*2) div 3;

  self.btn_yes.Left:=BTN_OFFSET;
  self.btn_no.Left:=self.Width - BTN_OFFSET - self.btn_no.Width;
end;

function GetWorkingDirectory():string;
var
  arr:array of char;
  val:cardinal;
begin
  result:='';
  val:=GetCurrentDirectory(0, nil);
  if val <= 0 then exit;
  setlength(arr, val);

  val:=GetCurrentDirectory(val, @arr[0]);
  if (val <=0) or (val >= cardinal(length(arr))) then exit;

  result:=PAnsiChar(@arr[0]);
end;

function GetExecutableName():string;
var
  buf:array of char;
  res:cardinal;
  dir:string;
begin
  result:='';

  setlength(buf, 260);
  repeat
    res:=GetModuleFileName(0, @buf[0], length(buf));
    if res >= cardinal(length(buf)) then begin
      setlength(buf, length(buf) * 2);
    end else begin
      result:=PAnsiChar(@buf[0]);
      break;
    end;
  until res = 0;

  if length(result) > 0 then begin
    dir:=GetWorkingDirectory();
    if (length(result) > length(dir)) and (leftstr(result, length(dir)) = dir) then begin
      result:=rightstr(result, length(result)-length(dir));
      if (result[1]<>'/') and (result[1]<>'\') then begin
        result:='.\'+result;
      end else begin
        result:='.'+result;
      end;
    end;
  end;
end;

function DropBatFile(batname:string; filename:string):boolean;
var
  f:textfile;
begin
  result:=false;
  assignfile(f, batname);
  try
    rewrite(f);
    writeln(f, 'chcp '+inttostr(GetACP())+' > nul');
    writeln(f, ':1');
    writeln(f, 'del "'+filename+'"');
    writeln(f, 'if exist "'+filename+'" goto 1');
    writeln(f, 'del "'+batname+'" && exit');
    closefile(f);
    result:=true;
  except
    result:=false;
  end;
end;

function DirectoryIsEmpty(Directory:string): boolean;
var
  sr: TSearchRec;
  i: Integer;
begin
   Result := false;
   FindFirst( IncludeTrailingPathDelimiter( Directory ) + '*', faAnyFile, sr );
   for i := 1 to 2 do
      if ( sr.Name = '.' ) or ( sr.Name = '..' ) then
         Result := FindNext( sr ) <> 0;
   FindClose( sr );
end;

procedure KillFileAndEmptyDir(filepath:string);
begin
  DeleteFile(filepath);
  while (length(filepath)>0) and (filepath[length(filepath)]<>'\') and (filepath[length(filepath)]<>'/') do begin
   filepath:=leftstr(filepath, length(filepath)-1);
  end;

  if (length(filepath)>0) and DirectoryExists(filepath) and DirectoryIsEmpty(filepath) then begin
    RemoveDir(filepath);
  end;
end;

function RevertChanges(changes_cfg:string):boolean;
var
   install_log:textfile;
   filepath:string;
   si:TStartupInfo;
   pi:TProcessInformation;
const
  BAT_NAME:string='uninstall.bat';
begin
  result:=false;
  if not FileExists(changes_cfg) then begin
    if GetSystemDefaultLangID() = RUS_ID then begin
      Application.MessageBox(PAnsiChar('Не обнаружен файл "'+changes_cfg+'"'), 'Ошибка', MB_OK or MB_ICONERROR);
    end else begin
      Application.MessageBox(PAnsiChar('Can''t find file "'+changes_cfg+'"'), 'Ошибка', MB_OK or MB_ICONERROR);
    end;
    exit;
  end;

  assignfile(install_log, changes_cfg);
  try
    reset(install_log);
    while not eof(install_log) do begin
      readln(install_log, filepath);
      KillFileAndEmptyDir(filepath);
    end;
    KillFileAndEmptyDir(USERLTX_PATH);
    KillFileAndEmptyDir(FSGAME_PATH);
    CloseFile(install_log);
    KillFileAndEmptyDir(changes_cfg);
    DropBatFile(BAT_NAME, GetExecutableName());
    FillMemory(@si, sizeof(si),0);
    FillMemory(@pi, sizeof(pi),0);
    si.cb:=sizeof(si);
    CreateProcess(nil, PAnsiChar('cmd.exe /C @start "" /B "'+BAT_NAME+'"'), nil, nil, false, CREATE_NO_WINDOW, nil, nil, si, pi);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    result:=true;
  except
    result:=false;
  end;
end;

procedure TMainForm.btn_yesClick(Sender: TObject);
begin
  RevertChanges(UNINSTALL_DATA_PATH);
  Application.Terminate;
end;

procedure TMainForm.btn_noClick(Sender: TObject);
begin
  Application.Terminate;
end;

end.

