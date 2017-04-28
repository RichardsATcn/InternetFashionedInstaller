//Ϊ�˷�������ͽ�[Code]���ε����ó�����

//����botva2�ĺ�������
#include ".\botva2.iss"

[Code]
CONST
  PRODUCT_REGISTRY_KEY_32 = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppID}_is1';
  PRODUCT_REGISTRY_KEY_64 = 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppID}_is1';
  WM_SYSCOMMAND = $0112;
  ID_BUTTON_ON_CLICK_EVENT = 1;
  WIZARDFORM_WIDTH_NORMAL = 458;
  WIZARDFORM_HEIGHT_NORMAL = 506;
  WIZARDFORM_HEIGHT_MORE = WIZARDFORM_HEIGHT_NORMAL;

VAR
  label_wizardform_main, label_messagebox_main, label_wizardform_more_product_already_installed, label_messagebox_information, label_messagebox_title, label_install_progress : TLabel;
  image_wizardform_background, image_messagebox_background, image_progressbar_background, image_progressbar_foreground, PBOldProc : LONGINT;
  button_license, button_minimize, button_close, button_browse, button_install, button_start, button_customize_setup, button_uncustomize_setup, checkbox_license, button_messagebox_close, button_messagebox_ok, button_messagebox_cancel : HWND;
  is_wizardform_show_normal, is_installer_initialized, is_platform_windows_7, is_wizardform_released, can_exit_setup, need_to_change_associations : BOOLEAN;
  edit_target_path : TEdit;
  version_installed_before : STRING;
  messagebox_close : TSetupForm;

//���������������ʹ���δ���ת��ΪԲ�Ǿ��δ���
PROCEDURE shape_form_round(aForm : TForm; edgeSize : INTEGER);
VAR
  FormRegion : LONGWORD;
BEGIN
  FormRegion := CreateRoundRectRgn(0, 0, aForm.Width, aForm.Height, edgeSize, edgeSize);
  SetWindowRgn(aForm.Handle, FormRegion, TRUE);
END;

//����������������ж��Ƿ��Ѿ���װ�˽�Ҫ��װ�Ĳ�Ʒ�����Ѿ���װ���򷵻�TRUE�����򷵻�FALSE
FUNCTION is_installed_before() : BOOLEAN;
BEGIN
#ifndef x64Build
  IF is_platform_windows_7 THEN
  BEGIN
    IF IsWin64 THEN
    BEGIN
      IF RegKeyExists(HKEY_LOCAL_MACHINE, PRODUCT_REGISTRY_KEY_64) THEN
      BEGIN
        RegQueryStringValue(HKEY_LOCAL_MACHINE, PRODUCT_REGISTRY_KEY_64, 'DisplayVersion', version_installed_before);
        Result := TRUE;
      END ELSE
      BEGIN
        version_installed_before := '0.0.0';
        Result := FALSE;
      END;
    END ELSE
    BEGIN
      IF RegKeyExists(HKEY_LOCAL_MACHINE, PRODUCT_REGISTRY_KEY_32) THEN
      BEGIN
        RegQueryStringValue(HKEY_LOCAL_MACHINE, PRODUCT_REGISTRY_KEY_32, 'DisplayVersion', version_installed_before);
        Result := TRUE;
      END ELSE
      BEGIN
        version_installed_before := '0.0.0';
        Result := FALSE;
      END;
    END;
  END ELSE
  BEGIN
    IF RegKeyExists(HKEY_LOCAL_MACHINE, PRODUCT_REGISTRY_KEY_32) THEN
      BEGIN
        RegQueryStringValue(HKEY_LOCAL_MACHINE, PRODUCT_REGISTRY_KEY_32, 'DisplayVersion', version_installed_before);
        Result := TRUE;
      END ELSE
      BEGIN
        version_installed_before := '0.0.0';
        Result := FALSE;
      END;
  END;
#else
  IF RegKeyExists(HKEY_LOCAL_MACHINE, PRODUCT_REGISTRY_KEY_32) THEN
  BEGIN
    RegQueryStringValue(HKEY_LOCAL_MACHINE, PRODUCT_REGISTRY_KEY_32, 'DisplayVersion', version_installed_before);
    Result := TRUE;
  END ELSE
  BEGIN
    version_installed_before := '0.0.0';
    Result := FALSE;
  END;
#endif
END;

//����������������ж��Ƿ����ڰ�װ�ɰ汾����ϵͳ���Ѿ���װ�˽�Ҫ��װ�Ĳ�Ʒ�������򷵻�TRUE�����򷵻�FALSE
FUNCTION is_installing_older_version() : BOOLEAN;
VAR
  installedVer : ARRAY[1..10] OF LONGINT;
  installingVer : ARRAY[1..10] OF LONGINT;
  oldVer, nowVer, version_installing_now : STRING;
  i, oldTotal, nowTotal, total : INTEGER;
BEGIN
  oldTotal := 1;
  WHILE (Pos('.', version_installed_before) > 0) DO
  BEGIN
    oldVer := version_installed_before;
    Delete(oldVer, Pos('.', oldVer), ((Length(oldVer) - Pos('.', oldVer)) + 1));
    installedVer[oldTotal] := StrToIntDef(oldVer, 0);
    oldTotal := oldTotal + 1;
    version_installed_before := Copy(version_installed_before, (Pos('.', version_installed_before) + 1), (Length(version_installed_before) - Pos('.', version_installed_before)));
  END;
  IF (version_installed_before <> '') THEN
  BEGIN
    installedVer[oldTotal] := StrToIntDef(version_installed_before, 0);
  END ELSE
  BEGIN
    oldTotal := oldTotal - 1;
  END;
  version_installing_now := '{#MyAppVersion}';
  nowTotal := 1;
  WHILE (Pos('.', version_installing_now) > 0) DO
  BEGIN
    nowVer := version_installing_now;
    Delete(nowVer, Pos('.', nowVer), ((Length(nowVer) - Pos('.', nowVer)) + 1));
    installingVer[nowTotal] := StrToIntDef(nowVer, 0);
    nowTotal := nowTotal + 1;
    version_installing_now := Copy(version_installing_now, (Pos('.', version_installing_now) + 1), (Length(version_installing_now) - Pos('.', version_installing_now)));
  END;
  IF (version_installing_now <> '') THEN
  BEGIN
    installingVer[nowTotal] := StrToIntDef(version_installing_now, 0);
  END ELSE
  BEGIN
    nowTotal := nowTotal - 1;
  END;
  IF (oldTotal < nowTotal) THEN
  BEGIN
    FOR i := (oldTotal + 1) TO nowTotal DO
    BEGIN
      installedVer[i] := 0;
      total := nowTotal;
    END;
  END ELSE IF (oldTotal > nowTotal) THEN
  BEGIN
    FOR i := (nowTotal + 1) TO oldTotal DO
    BEGIN
      installingVer[i] := 0;
      total := oldTotal;
    END;
  END ELSE
  BEGIN
    total := nowTotal;
  END;
  FOR i := 1 TO total DO
  BEGIN
    IF (installedVer[i] > installingVer[i]) THEN
    BEGIN
      Result := TRUE;
      Exit;
    END ELSE IF (installedVer[i] < installingVer[i]) THEN
    BEGIN
      Result := FALSE;
      Exit;
    END ELSE
    BEGIN
      Continue;
    END;
  END;
  Result := FALSE;
END;

//������رհ�ť����ʱִ�еĽű�
PROCEDURE button_close_on_click(hBtn : HWND);
BEGIN
  WizardForm.CancelButton.OnClick(WizardForm);
END;

//��������С����ť����ʱִ�еĽű�
PROCEDURE button_minimize_on_click(hBtn : HWND);
BEGIN
  SendMessage(WizardForm.Handle, WM_SYSCOMMAND, 61472, 0);
END;

//�������Զ��尲װ��ť����ʱִ�еĽű�
PROCEDURE button_customize_setup_on_click(hBtn : HWND);
BEGIN
  IF is_wizardform_show_normal THEN
  BEGIN
    WizardForm.Height := WIZARDFORM_HEIGHT_MORE;
    image_wizardform_background := ImgLoad(WizardForm.Handle, ExpandConstant('{tmp}\background_welcome_more.png'), 0, 0, WIZARDFORM_WIDTH_NORMAL, WIZARDFORM_HEIGHT_MORE, FALSE, TRUE);
    edit_target_path.Show();
    BtnSetVisibility(button_browse, TRUE);
    BtnSetVisibility(button_customize_setup, FALSE);
    BtnSetVisibility(button_uncustomize_setup, TRUE);
#ifndef PortableBuild
    IF is_installed_before() THEN
    BEGIN
      edit_target_path.Enabled := FALSE;
      BtnSetEnabled(button_browse, FALSE);
      label_wizardform_more_product_already_installed.Show();
    END;
#endif
    is_wizardform_show_normal := FALSE;
  END ELSE
  BEGIN
    edit_target_path.Hide();
    label_wizardform_more_product_already_installed.Hide();
    BtnSetVisibility(button_browse, FALSE);
    WizardForm.Height := WIZARDFORM_HEIGHT_NORMAL;
    image_wizardform_background := ImgLoad(WizardForm.Handle, ExpandConstant('{tmp}\background_welcome.png'), 0, 0, WIZARDFORM_WIDTH_NORMAL, WIZARDFORM_HEIGHT_NORMAL, FALSE, TRUE);
    BtnSetVisibility(button_customize_setup, TRUE);
    BtnSetVisibility(button_uncustomize_setup, FALSE);
    is_wizardform_show_normal := TRUE;
  END;
  ImgApplyChanges(WizardForm.Handle);
END;

//�����������ť����ʱִ�еĽű�
PROCEDURE button_browse_on_click(hBtn : HWND);
BEGIN
  WizardForm.DirBrowseButton.OnClick(WizardForm);
  edit_target_path.Text := WizardForm.DirEdit.Text;
END;

//·��������ı��仯ʱִ�еĽű�
PROCEDURE edit_target_path_on_change(Sender : TObject);
BEGIN
  WizardForm.DirEdit.Text := edit_target_path.Text;
END;

//ͬ�����Э��ĸ�ѡ�򱻵��ʱִ�еĽű�
PROCEDURE checkbox_license_on_click(hBtn : HWND);
BEGIN
    IF BtnGetChecked(checkbox_license) THEN
    BEGIN
      BtnSetEnabled(button_install, TRUE);
    END ELSE
    BEGIN
      BtnSetEnabled(button_install, FALSE);
    END;
END;

//����ΪĬ������ĸ�ѡ�򱻹�ѡ��������ļ����ƽ���ʱִ�д˶νű�
PROCEDURE check_if_need_change_associations();
BEGIN
  MsgBox('�˴�ִ��ע���ļ���׺���Ĳ�����', mbInformation, MB_OK);
END;

//�����氲װ��ť����ʱִ�еĽű�
PROCEDURE button_install_on_click(hBtn : HWND);
BEGIN
  WizardForm.NextButton.OnClick(WizardForm);
END;

//�����ļ�ʱִ�еĽű���ÿ����1%���ᱻ����һ�Σ���Ҫ�����������������ʾ���ڴ˶��޸�
FUNCTION PBProc(h : hWnd; Msg, wParam, lParam : LONGINT) : LONGINT;
VAR
  pr, i1, i2 : EXTENDED;
  w : INTEGER;
BEGIN
  Result := CallWindowProc(PBOldProc, h, Msg, wParam, lParam);
  IF ((Msg = $402) AND (WizardForm.ProgressGauge.Position > WizardForm.ProgressGauge.Min)) THEN
  BEGIN
    i1 := WizardForm.ProgressGauge.Position - WizardForm.ProgressGauge.Min;
    i2 := WizardForm.ProgressGauge.Max - WizardForm.ProgressGauge.Min;
    pr := (i1 * 100) / i2;
    label_install_progress.Caption := Format('%d', [Round(pr)]) + '%';
    ImgApplyChanges(WizardForm.Handle);
  END;
END;

//�Ķ����Э��İ�ť����ʱִ�еĽű�
PROCEDURE button_license_on_click(hBtn : HWND);
VAR
  ErrorCode : INTEGER;
BEGIN
  ShellExec('', '{#MyAppLicenseURL}', '', '', SW_SHOW, ewNoWait, ErrorCode);
END;

//ȡ����װ�����ȷ����ť����ʱִ�еĽű�
PROCEDURE button_messagebox_ok_on_click(hBtn : HWND);
BEGIN
  can_exit_setup := TRUE;
  messagebox_close.Close();
END;

//ȡ����װ�����ȡ����ť����ʱִ�еĽű�
PROCEDURE button_messagebox_cancel_on_click(hBtn : HWND);
BEGIN
  can_exit_setup := FALSE;
  messagebox_close.Close();
END;

//�������鰴ť���º�ִ�еĽű�
PROCEDURE button_start_on_click(hBtn : HWND);
VAR
  ErrorCode : INTEGER;
BEGIN
  ShellExec('', ExpandConstant('{app}\{#MyAppExeName}'), '', '', SW_SHOW, ewNoWait, ErrorCode);
  WizardForm.NextButton.OnClick(WizardForm);
END;

//�����汻��ס��������ƶ��Ľű�
PROCEDURE wizardform_on_mouse_down(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : INTEGER);
BEGIN
  ReleaseCapture();
  SendMessage(WizardForm.Handle, WM_SYSCOMMAND, $F012, 0);
END;

//ȡ�����򱻵�ס��������ƶ��Ľű�
PROCEDURE messagebox_on_mouse_down(Sender : TObject; Button : TMouseButton; Shift : TShiftState; X, Y : INTEGER);
BEGIN
  ReleaseCapture();
  SendMessage(messagebox_close.Handle, WM_SYSCOMMAND, $F012, 0);
END;

//�ж�ϵͳ�Ƿ�ΪWin7�����򷵻�TRUE�����򷵻�FALSE
PROCEDURE determine_wether_is_windows_7_or_not();
VAR
  sysVersion : TWindowsVersion;
BEGIN
  GetWindowsVersionEx(sysVersion);
  IF sysVersion.NTPlatform AND (sysVersion.Major = 6) AND (sysVersion.Minor = 1) THEN
  BEGIN
    is_platform_windows_7 := TRUE;
  END ELSE
  BEGIN
    is_platform_windows_7 := FALSE;
  END;
END;

//����ȡ������Ľű�
PROCEDURE messagebox_close_create();
BEGIN
  messagebox_close := CreateCustomForm();
  WITH messagebox_close DO
  BEGIN
    BorderStyle := bsNone;
    Width := 346;
    Height := 153;
    Color := clWhite;
    Caption := '';
  END;
  label_messagebox_title := TLabel.Create(messagebox_close);
  WITH label_messagebox_title DO
  BEGIN
    Parent := messagebox_close;
    AutoSize := FALSE;
    Left := 9;
    Top := 9;
    Width := 200;
    Height := 20;
    Font.Name := 'Microsoft YaHei';
    Font.Size := 9;
    Font.Color := clGray;
    Caption := '{#MyAppName} ��װ';
    Transparent := TRUE;
    OnMouseDown := @messagebox_on_mouse_down;
  END;
  label_messagebox_information := TLabel.Create(messagebox_close);
  WITH label_messagebox_information DO
  BEGIN
    Parent := messagebox_close;
    AutoSize := FALSE;
    Left := 75;
    Top := 60;
    Width := 400;
    Height := 20;
    Font.Name := 'Microsoft YaHei';
    Font.Size := 10;
    Font.Color := clBlack;
    Caption := '��ȷ��Ҫ�˳���{#MyAppName}����װ����';
    Transparent := TRUE;
    OnMouseDown := @messagebox_on_mouse_down;
  END;
  label_messagebox_main := TLabel.Create(messagebox_close);
  WITH label_messagebox_main DO
  BEGIN
    Parent := messagebox_close;
    AutoSize := FALSE;
    Left := 0;
    Top := 0;
    Width := messagebox_close.Width;
    Height := messagebox_close.Height;
    Caption := '';
    Transparent := TRUE;
    OnMouseDown := @messagebox_on_mouse_down;
  END;
  image_messagebox_background := ImgLoad(messagebox_close.Handle, ExpandConstant('{tmp}\background_messagebox.png'), 0, 0, 346, 153, FALSE, TRUE);
  button_messagebox_close := BtnCreate(messagebox_close.Handle, 326, 9, 10, 10, ExpandConstant('{tmp}\button_close.png'), 0, FALSE);
  BtnSetEvent(button_messagebox_close, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@button_messagebox_cancel_on_click, 1));
  button_messagebox_ok := BtnCreate(messagebox_close.Handle, 172, 118, 73, 24, ExpandConstant('{tmp}\button_ok.png'), 0, FALSE);
  BtnSetEvent(button_messagebox_ok, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@button_messagebox_ok_on_click, 1));
  button_messagebox_cancel := BtnCreate(messagebox_close.Handle, 253, 118, 73, 24, ExpandConstant('{tmp}\button_cancel.png'), 0, FALSE);
  BtnSetEvent(button_messagebox_cancel, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@button_messagebox_cancel_on_click, 1));
  ImgApplyChanges(messagebox_close.Handle);
END;

//�ͷŰ�װ����ʱ���õĽű�
PROCEDURE release_installer();
BEGIN
  gdipShutdown();
  messagebox_close.Release();
  WizardForm.Release();
END;

//�ڳ�ʼ��֮���ͷŰ�װ����Ľű�
PROCEDURE release_installer_after_init();
BEGIN
  messagebox_close.Release();
  WizardForm.Release();
END;

//�ͷ���Ҫ����ʱ��Դ�ļ�
PROCEDURE extract_temp_files();
BEGIN
  ExtractTemporaryFile('button_customize_setup.png');
  ExtractTemporaryFile('button_uncustomize_setup.png');
  ExtractTemporaryFile('button_finish.png');
  ExtractTemporaryFile('button_install.png');
  ExtractTemporaryFile('background_welcome.png');
  ExtractTemporaryFile('background_welcome_more.png');
  ExtractTemporaryFile('button_browse.png');
  ExtractTemporaryFile('button_license.png');
  ExtractTemporaryFile('checkbox.png');
  ExtractTemporaryFile('background_installing.png');
  ExtractTemporaryFile('background_finish.png');
  ExtractTemporaryFile('button_close.png');
  ExtractTemporaryFile('button_minimize.png');
  ExtractTemporaryFile('background_messagebox.png');
  ExtractTemporaryFile('button_cancel.png');
  ExtractTemporaryFile('button_ok.png');
END;

//����������ȡ����ť�����º�Ĵ������
PROCEDURE CancelButtonClick(CurPageID : INTEGER; VAR Cancel, Confirm: BOOLEAN);
BEGIN
  Confirm := FALSE;
  messagebox_close.Center();
  messagebox_close.ShowModal();
  IF can_exit_setup THEN
  BEGIN
    release_installer();
    Cancel := TRUE;
  END ELSE
  BEGIN
    Cancel := FALSE;
  END;
END;

//���ذ�װ�����ʼ���������ж��Ƿ��Ѿ���װ�°汾�������ֹ��װ
FUNCTION InitializeSetup() : BOOLEAN;
BEGIN
#ifndef PortableBuild
#ifdef OnlyInstallNewVersion
  IF is_installed_before() THEN
  BEGIN
    IF is_installing_older_version() THEN
    BEGIN
      MsgBox('���Ѱ�װ���°汾�ġ�{#MyAppName}����������ʹ�þɰ汾�滻�°汾���뵥����ȷ������ť�˳��˰�װ����', mbInformation, MB_OK);
      Result := FALSE;
    END ELSE
    BEGIN
      Result := TRUE;
    END;
  END ELSE
  BEGIN
    Result := TRUE;
  END;
#else
  Result := TRUE;
#endif
#else
  Result := TRUE;
#endif
END;

//���ذ�װ�����ʼ�����������ϱ��Ǹ���һ���������г�ʼ������
PROCEDURE InitializeWizard();
BEGIN
  is_installer_initialized := TRUE;
  is_wizardform_show_normal := TRUE;
  is_wizardform_released := FALSE;
  need_to_change_associations := TRUE;
  determine_wether_is_windows_7_or_not();
  extract_temp_files();
  WizardForm.InnerNotebook.Hide();
  WizardForm.OuterNotebook.Hide();
  WizardForm.Bevel.Hide();
  WITH WizardForm DO
  BEGIN
    BorderStyle := bsNone;
    Position := poDesktopCenter;
    Width := WIZARDFORM_WIDTH_NORMAL;
    Height := WIZARDFORM_HEIGHT_MORE;
    Color := clWhite;
    NextButton.Height := 0;
    CancelButton.Height := 0;
    BackButton.Visible := FALSE;
  END;
  label_wizardform_more_product_already_installed := TLabel.Create(WizardForm);
  WITH label_wizardform_more_product_already_installed DO
  BEGIN
    Parent := WizardForm;
    AutoSize := FALSE;
    Left := 20;
    Top := 400;
    Width := 200;
    Height := 20;
    Font.Name := 'Microsoft YaHei';
    Font.Size := 9;
    Font.Color := clGray;
    Caption := '����Ѿ���װ�����������Ŀ¼��';
    Transparent := TRUE;
    OnMouseDown := @wizardform_on_mouse_down;
  END;
  label_wizardform_more_product_already_installed.Hide();
  label_wizardform_main := TLabel.Create(WizardForm);
  WITH label_wizardform_main DO
  BEGIN
    Parent := WizardForm;
    AutoSize := FALSE;
    Left := 0;
    Top := 0;
    Width := WizardForm.Width;
    Height := WizardForm.Height;
    Caption := '';
    Transparent := TRUE;
    OnMouseDown := @wizardform_on_mouse_down;
  END;
  edit_target_path:= TEdit.Create(WizardForm);
  WITH edit_target_path DO
  BEGIN
    Parent := WizardForm;
    Text := WizardForm.DirEdit.Text;
    Font.Name := 'Microsoft YaHei';
    Font.Size := 9;
    Font.Color := clBlack;
    BorderStyle := bsNone;
    SetBounds(22,430,301,20);
    Color := clWhite;
    OnChange := @edit_target_path_on_change;
    TabStop := FALSE;
  END;
  edit_target_path.Hide();
  button_close := BtnCreate(WizardForm.Handle, 430, 18, 10, 10, ExpandConstant('{tmp}\button_close.png'), 0, FALSE);
  BtnSetEvent(button_close, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@button_close_on_click, 1));
  button_minimize := BtnCreate(WizardForm.Handle, 408, 22, 10, 3, ExpandConstant('{tmp}\button_minimize.png'), 0, FALSE);
  BtnSetEvent(button_minimize, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@button_minimize_on_click, 1));
  button_install := BtnCreate(WizardForm.Handle, 128, 311, 206, 59, ExpandConstant('{tmp}\button_install.png'), 0, FALSE);
  BtnSetEvent(button_install, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@button_install_on_click, 1));
  button_browse := BtnCreate(WizardForm.Handle, 349, 423, 89, 29, ExpandConstant('{tmp}\button_browse.png'), 0, FALSE);
  BtnSetEvent(button_browse, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@button_browse_on_click, 1));
  BtnSetVisibility(button_browse, FALSE);
  button_customize_setup := BtnCreate(WizardForm.Handle, 345, 475, 93, 16, ExpandConstant('{tmp}\button_customize_setup.png'), 0, FALSE);
  BtnSetEvent(button_customize_setup, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@button_customize_setup_on_click, 1));
  button_uncustomize_setup := BtnCreate(WizardForm.Handle, 345, 475, 93, 16, ExpandConstant('{tmp}\button_uncustomize_setup.png'), 0, FALSE);
  BtnSetEvent(button_uncustomize_setup, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@button_customize_setup_on_click, 1));
  BtnSetVisibility(button_uncustomize_setup, FALSE);
  PBOldProc := SetWindowLong(WizardForm.ProgressGauge.Handle, -4, PBCallBack(@PBProc, 4));
  ImgApplyChanges(WizardForm.Handle);
  messagebox_close_create();
END;

//��װ��������ʱ������������
PROCEDURE DeinitializeSetup();
BEGIN
  IF ((is_wizardform_released = FALSE) AND (can_exit_setup = FALSE)) THEN
  BEGIN
    gdipShutdown();
    IF is_installer_initialized THEN
    BEGIN
      release_installer_after_init();
    END;
  END;
END;

//��װҳ��ı�ʱ������������
PROCEDURE CurPageChanged(CurPageID : INTEGER);
BEGIN
  IF (CurPageID = wpWelcome) THEN
  BEGIN
    image_wizardform_background := ImgLoad(WizardForm.Handle, ExpandConstant('{tmp}\background_welcome.png'), 0, 0, WIZARDFORM_WIDTH_NORMAL, WIZARDFORM_HEIGHT_NORMAL, FALSE, TRUE);
    button_license := BtnCreate(WizardForm.Handle, 118, 477, 96, 12, ExpandConstant('{tmp}\button_license.png'), 0, FALSE);
    BtnSetEvent(button_license, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@button_license_on_click, 1));
    checkbox_license := BtnCreate(WizardForm.Handle, 20, 476, 13, 13, ExpandConstant('{tmp}\checkbox.png'), 0, TRUE);
    BtnSetEvent(checkbox_license, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@checkbox_license_on_click, 1));
    BtnSetChecked(checkbox_license, TRUE);
    WizardForm.Height := WIZARDFORM_HEIGHT_NORMAL;
    ImgApplyChanges(WizardForm.Handle);
  END;
  IF (CurPageID = wpInstalling) THEN
  BEGIN
    edit_target_path.Hide();
    label_wizardform_more_product_already_installed.Hide();
    BtnSetVisibility(button_browse, FALSE);
    WizardForm.Height := WIZARDFORM_HEIGHT_NORMAL;
    is_wizardform_show_normal := TRUE;
    BtnSetVisibility(button_customize_setup, FALSE);
    BtnSetVisibility(button_uncustomize_setup, FALSE);
    BtnSetEnabled(button_close, FALSE);
    BtnSetVisibility(button_license, FALSE);
    BtnSetVisibility(checkbox_license, FALSE);
    label_install_progress := TLabel.Create(WizardForm);
    WITH label_install_progress DO
    BEGIN
      Parent := WizardForm;
      AutoSize := FALSE;
      Left := 55;
      Top := 175;
      Width := 329;
      Height := 174;
      Font.Name := 'Microsoft YaHei';
      Font.Size := 90;
      Font.Color := clWhite;
      Caption := '';
      Transparent := TRUE;
      Alignment := taRightJustify;
      OnMouseDown := @wizardform_on_mouse_down;
    END;
    image_wizardform_background := ImgLoad(WizardForm.Handle, ExpandConstant('{tmp}\background_installing.png'), 0, 0, WIZARDFORM_WIDTH_NORMAL, WIZARDFORM_HEIGHT_NORMAL, FALSE, TRUE);
    BtnSetVisibility(button_install, FALSE);
    ImgApplyChanges(WizardForm.Handle);
  END;
  IF (CurPageID = wpFinished) THEN
  BEGIN
    label_install_progress.Caption := '';
    label_install_progress.Visible := FALSE;
    BtnSetEnabled(button_close, TRUE);
    button_start := BtnCreate(WizardForm.Handle, 128, 311, 206, 59, ExpandConstant('{tmp}\button_finish.png'), 0, FALSE);
    BtnSetEvent(button_start, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@button_start_on_click, 1));
    BtnSetEvent(button_close, ID_BUTTON_ON_CLICK_EVENT, WrapBtnCallback(@button_install_on_click, 1));
    image_wizardform_background := ImgLoad(WizardForm.Handle, ExpandConstant('{tmp}\background_finish.png'), 0, 0, WIZARDFORM_WIDTH_NORMAL, WIZARDFORM_HEIGHT_NORMAL, FALSE, TRUE);
    ImgApplyChanges(WizardForm.Handle);
  END;
END;

//��װ����ı�ʱ������������
PROCEDURE CurStepChanged(CurStep : TSetupStep);
BEGIN
  IF (CurStep = ssPostInstall) THEN
  BEGIN
#ifdef RegisteAssociations
    check_if_need_change_associations();
#endif
    //AND DO OTHER THINGS
  END;
  IF (CurStep = ssDone) THEN
  BEGIN
    is_wizardform_released := TRUE;
    release_installer();
  END;
END;

//ָ��������Щ��׼ҳ��
FUNCTION ShouldSkipPage(PageID : INTEGER) : BOOLEAN;
BEGIN
  IF (PageID = wpLicense) THEN Result := TRUE;
  IF (PageID = wpPassword) THEN Result := TRUE;
  IF (PageID = wpInfoBefore) THEN Result := TRUE;
  IF (PageID = wpUserInfo) THEN Result := TRUE;
  IF (PageID = wpSelectDir) THEN Result := TRUE;
  IF (PageID = wpSelectComponents) THEN Result := TRUE;
  IF (PageID = wpSelectProgramGroup) THEN Result := TRUE;
  IF (PageID = wpSelectTasks) THEN Result := TRUE;
  IF (PageID = wpReady) THEN Result := TRUE;
  IF (PageID = wpPreparing) THEN Result := TRUE;
  IF (PageID = wpInfoAfter) THEN Result := TRUE;
END;

//ж�ز���ı�ʱ����ô˺���
PROCEDURE CurUninstallStepChanged(CurUninstallStep : TUninstallStep);
BEGIN
  IF (CurUninstallStep = usAppMutexCheck) THEN
  BEGIN
    //�˽׶�Ϊ���Ӧ�ó��򻥳�Ľ׶Σ����ڴ˽��л������
  END;
END;

