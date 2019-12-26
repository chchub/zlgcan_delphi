{#  ------------------------------------------------------------------
#  Author : chenhuachun
#  Last change: 29.11.2019
#
#  Language: delphi 2007
#  ------------------------------------------------------------------}
unit Unit2;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  zlgcan;
  

type
  TForm2 = class(TForm)
    start_Button: TButton;
    can_index_box: TComboBox;
    device_index_box: TComboBox;
    reset_Button: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    mode_box: TComboBox;
    device_setting: TGroupBox;
    resistance: TCheckBox;
    can_type_box: TComboBox;
    Label4: TLabel;
    canfd_standard_box: TComboBox;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    data_display: TGroupBox;
    device_type_box: TComboBox;
    ListBox1: TListBox;
    data_sent_setting: TGroupBox;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    id_edit: TEdit;
    data_edit: TEdit;
    eff_box: TComboBox;
    send_type_box: TComboBox;
    abit_baud_box: TEdit;
    dbit_baud_box: TEdit;
    Label14: TLabel;
    rtr_box: TComboBox;
    send_Button: TButton;
    filter_check: TCheckBox;
    Label15: TLabel;
    filtermode_box: TComboBox;
    Label16: TLabel;
    Label17: TLabel;
    filter_start_edit: TEdit;
    filter_end_edit: TEdit;
    filer_setting: TGroupBox;
    custom_baud_edit: TEdit;
    custom_baud_check: TCheckBox;
    Label9: TLabel;
    canfd_brs: TCheckBox;
    getdevinf_Button: TButton;
    data_clear_Button: TButton;
    procedure FormCreate(Sender: TObject);
    procedure start_ButtonClick(Sender: TObject);
    procedure reset_ButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure send_ButtonClick(Sender: TObject);
    procedure getdevinf_ButtonClick(Sender: TObject);
    procedure data_clear_ButtonClick(Sender: TObject);


  private
    { Private declarations }
  public
    { Public declarations }
  end;

   PTListBox=^TListBox;

   
  //����һЩȫ�ֱ���
var
  Form2: TForm2;
  device_handle,init_handle:THandle;
  device_type,device_index,can_index,reserved:Dword;
  m_arrdevtype:array[0..50] of integer;  {�豸ѡ��}
  m_connect : DWORD;
  m_threadhandle : integer;
  property_: IProperty;


implementation

{$R *.dfm}




{   ID = CAN_ID + EFF/RTR/ERR flags ��Dword ����,�ܹ�32λ

      ��3λ���ڱ�־λ����־λ�������£�
      
      --��31λ(���λ)������չ֡��־��=0��ʾ��׼֡��=1������չ֡������IS_EFF�ɻ�ȡ�ñ�־��
      --��30λ����Զ��֡��־��=0��ʾ����֡��=1��ʾԶ��֡������IS_RTR�ɻ�ȡ�ñ�־��
      --��29λ�������֡��׼��=0��ʾCAN֡��=1��ʾ����֡��Ŀǰֻ������Ϊ0��
      --����λ����ʵ��֡IDֵ��ʹ�ú�MAKE_CAN_ID����ID��ʹ�ú���GET_ID��ȡID}

function MAKE_CAN_ID(id:Dword; eff, rtr, err:Integer):DWord;
begin
  result :=  id or (eff shl 31) or (rtr shl 30) or (err shl 29);
end;

function IS_EFF(id: Dword):DWord;
begin
  result := id and CAN_EFF_FLAG;
end;

function IS_RTR(id: Dword):DWord;
begin
  result := id and CAN_RTR_FLAG;
end;

function GET_ID(id: Dword):DWord;
begin
  result := id and CAN_ID_FLAG;
end;


//���պ���
function ReceiveThread(param : Pointer): integer;
var
receivedata : array[0..199] of ZCAN_Receive_Data;
receivedata_fd : array[0..199] of ZCAN_ReceiveFD_Data;
j,i,len,len_can,len_canfd: integer;
dev_type:Dword;
str : AnsiString;
tmpstr :AnsiString;
box : PTListBox;
begin
  box:=param;
   while TRUE do
    begin
        if m_connect=0 then
          break;
        Sleep(1);
         len_can := ZCAN_GetReceiveNum(init_handle,0);
         len_canfd := ZCAN_GetReceiveNum(init_handle,1);
        if ((len_can <=0) and (len_canfd <=0))  then
        begin
            continue;
        end;
              //����CAN֡
             if len_can>0 then begin
              {��ȡCAN���ݣ�������ʾ}
              len:=ZCAN_Receive(init_handle,@receivedata[0],len_can,-1);
              for i:=0 to len-1 do
                begin
                  str:='���յ�CAN֡:  ';
                  tmpstr:='֡ID:0x'+IntToHex(GET_ID(receivedata[i].can_id),8)+' ';
                  str:=str+tmpstr;
                  str:=str+'֡��ʽ:';
                  if IS_EFF(receivedata[i].can_id)=0 then
                    tmpstr:='��׼֡ '
                  else
                    tmpstr:='��չ֡ ';
                  str:=str+tmpstr;
                  str:=str+'֡����:';
                  if IS_RTR(receivedata[i].can_id)=0 then
                    tmpstr:='����֡ '
                  else
                    tmpstr:='Զ��֡ ';
                  str:=str+tmpstr;
                  box.Items.Add(str);
                  if IS_RTR(receivedata[i].can_id)=0 then {���������֡����ʾ���ݣ�Զ��֡������}
                  begin
                    str:='����:';
                    if receivedata[i].can_dlc>8 then
                      receivedata[i].can_dlc:=8;
                    for j:=0 to receivedata[i].can_dlc-1 do
                      begin
                        tmpstr:=IntToHex(receivedata[i].data[j],2)+' ';
                        str:=str+tmpstr;
                      end;
                     box.Items.Add(str);
                  end;
                end;
              box.ItemIndex:=box.Items.Count-1;

            end else begin
              {��ȡCANFD���ݣ�������ʾ}
              len:=ZCAN_ReceiveFD(init_handle,@receivedata_fd[0],len_canfd,-1);
              for i:=0 to len-1 do
                begin
                  str:='���յ�CANFD֡:  ';
                  tmpstr:='֡ID:0x'+IntToHex(GET_ID(receivedata_fd[i].can_id),8)+' ';
                  str:=str+tmpstr;
                  str:=str+'֡��ʽ:';
                  if IS_EFF(receivedata_fd[i].can_id)=0 then
                    tmpstr:='��׼֡ '
                  else
                    tmpstr:='��չ֡ ';
                  str:=str+tmpstr;
                  str:=str+'֡����:';

                  if IS_RTR(receivedata_fd[i].can_id)=0 then
                    tmpstr:='����֡ '
                  else
                    tmpstr:='Զ��֡ ';
                  str:=str+tmpstr;

                  if receivedata_fd[i].flags =1 then
                    tmpstr:='CANFD���� '
                  else
                    tmpstr:=' ';
                  str:=str+tmpstr;
                  box.Items.Add(str);

                  if IS_RTR(receivedata_fd[i].can_id)=0 then {���������֡����ʾ���ݣ�Զ��֡������}
                  begin
                    str:='����:';

                    for j:=0 to receivedata_fd[i].len-1 do
                      begin
                        tmpstr:=IntToHex(receivedata_fd[i].data[j],2)+' ';
                        str:=str+tmpstr;
                      end;
                     box.Items.Add(str);
                  end;
                end;
              box.ItemIndex:=box.Items.Count-1;
              
            end;
    end;

  EndThread(0);
  ReceiveThread:=0;
end;




 //��ʼ���߳�-������ʾ
procedure TForm2.FormCreate(Sender: TObject);

var
index: integer;
device_handle,init_handle:THandle;
begin
  {��ʼ���豸����ѡ����Ŀ}
  index:=0;
  device_type_box.Items.Clear;
  index:=device_type_box.Items.Add( 'USBCANFD_200U');
  m_arrdevtype[index] :=  ZCAN_USBCANFD_200U;

  index:=device_type_box.Items.Add( 'USBCANFD_100U');
  m_arrdevtype[index] :=  ZCAN_USBCANFD_100U;

  index:=device_type_box.Items.Add( 'USBCANFD_MINI');
  m_arrdevtype[index] :=  ZCAN_USBCANFD_MINI;

  index:=device_type_box.Items.Add( 'USBCAN_2E_U');
  m_arrdevtype[index] :=  ZCAN_USBCAN_2E_U;

  index:=device_type_box.Items.Add( 'USBCAN2');
  m_arrdevtype[index] :=  ZCAN_USBCAN2 ;

  {��ʼ����ʾ���ò���}
  device_type_box.ItemIndex:=2;
  device_index_box.ItemIndex:=0;
  can_index_box.ItemIndex:=0;
  mode_box.ItemIndex:=0;
  can_type_box.ItemIndex:=0;
  canfd_standard_box.ItemIndex:=0;
  eff_box.ItemIndex:=0;
  send_type_box.ItemIndex:=0;
  rtr_box.ItemIndex:=0;
  filtermode_box.ItemIndex:=0;
  {�����ʼ��Ϊ0}
  device_handle:=0;
  init_handle:=0;
end;


// ��ȡ�豸��Ϣ
procedure TForm2.getdevinf_ButtonClick(Sender: TObject);
var
pInfo:ZCAN_DEVICE_INFO;
str : AnsiString;
tmpstr :AnsiString;
Vsion :integer;
begin
 if device_handle<1 then begin
 ListBox1.Items.Add('���ȴ��豸���ٻ�ȡ�豸��Ϣ��');
 end else begin
 ZCAN_GetDeviceInf (device_handle,@pInfo);

       str:= ' ';
       ListBox1.Items.Add(str);
       str:= '�豸��Ϣ���� :(16����,100��ʾV1.00)';
       ListBox1.Items.Add(str);
       str:= '------------------------------------------------------------ ';
       ListBox1.Items.Add(str);
       str:='Ӳ���汾: '+ IntToHex(pInfo.hw_Version,3);
       ListBox1.Items.Add(str);
       str:='�̼��汾: '+ IntToHex(pInfo.fw_Version,3);
       ListBox1.Items.Add(str);
       str:='�����汾: '+ IntToHex(pInfo.dr_Version,3);
       ListBox1.Items.Add(str);
       str:='��̬��汾: '+ IntToHex(pInfo.in_Version,3);
       ListBox1.Items.Add(str);
       str:='CAN·��: '+ IntToHex(pInfo.can_Num,2);
       ListBox1.Items.Add(str);
       str:= '------------------------------------------------------------ ';
       ListBox1.Items.Add(str);
    end
end;



//��λ�߳�
procedure TForm2.reset_ButtonClick(Sender: TObject);
begin
 m_connect:=0;
 ZCAN_ClearBuffer(init_handle);
  if ZCAN_ResetCAN (init_handle)>0 then
    ListBox1.Items.Add('��λ�ɹ�')
    else
    ListBox1.Items.Add('��λʧ��');
 ZCAN_CloseDevice(device_handle);
 device_handle:=0;
 init_handle:=0;

end;



//�����߳�
procedure TForm2.start_ButtonClick(Sender: TObject);

var
 threadid: LongWord;
 initconfig : ZCAN_INIT_CONFIG_CAN;
 initconfig_fd : ZCAN_INIT_CONFIG_CANFD;

begin

   device_type:= m_arrdevtype[device_type_box.ItemIndex];
   device_index:=device_index_box.ItemIndex;
   can_index:=can_index_box.ItemIndex;
   reserved:=0;

   {USBCANFDϵ�г�ʼ������}
   if ((device_type=41) or (device_type= 42) or (device_type=43)) then begin
        device_handle:=ZCAN_OpenDevice(device_type,device_index,reserved);
        if device_handle<1 then
           ListBox1.Items.Add('OPENʧ��,����豸�����Ƿ������������豸�Ѿ��򿪡�')
        else
           begin
              property_ := GetIProperty(device_handle); {�����������ýӿ�}

              property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/canfd_standard'),PAnsiChar(inttostr(canfd_standard_box.ItemIndex))); {����CANFD��׼}


              //��ʼ���ṹ
              initconfig_fd.can_type:=1;             {0:CAN , 1:CANFD}
              initconfig_fd.acc_code:=$0;           {SJA1000֡���������룬USBCANFD��������}
              initconfig_fd.acc_mask:=$FFFFFFFF;    {SJA1000֡���������룬USBCANFD��������}
              initconfig_fd.abit_timing:=0;        {�����ʣ�USBCANFD������������}
              initconfig_fd.dbit_timing:=0;       {�����ʣ�USBCANFD������������}
              initconfig_fd.brp:=0;               {������Ԥ��Ƶ���ӣ�Ĭ������Ϊ0}
              initconfig_fd.filter:=0;            {�˲���ʽ��USBCANFD������������}
              initconfig_fd.mode:= mode_box.ItemIndex;   {����ģʽ��=0��ʾ����ģʽ���൱�������ڵ㣩��=1��ʾֻ��ģʽ��ֻ���գ���Ӱ�����ߣ�}
              initconfig_fd.pad:=0;
              initconfig_fd.reserved:=0;



              if custom_baud_check.Checked then begin     {���ò�����}
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/baud_rate_custom'), PAnsiChar(custom_baud_edit.Text));   {�Զ��岨����}
              end else begin
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/canfd_abit_baud_rate'), PAnsiChar(abit_baud_box.Text+'000'));  {�ٲ�������}
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/canfd_dbit_baud_rate'), PAnsiChar(dbit_baud_box.Text+'000'));  {����������}
              end;

               {��ʼ��}
              init_handle:=ZCAN_InitCAN(device_handle,can_index,@initconfig_fd);
                 if init_handle<1 then
                 begin
                  ListBox1.Items.Add('��ʼ��CANʧ��');
                  Exit;
                 end;

              {�ն˵���}
              if resistance.Checked then begin
                property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/initenal_resistance'), '1');
              end;

              {�˲�����ZCAN_InitCAN��ZCAN_StartCAN֮������}
              if filter_check.Checked then begin
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/filter_clear'), '0');  {����˲�}
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/filter_mode'), PAnsiChar(inttostr(filtermode_box.ItemIndex)));  {�˲�ģʽ}
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/filter_start'), PAnsiChar('0x'+filter_start_edit.Text));   {�˲���ʼ֡}
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/filter_end'), PAnsiChar('0x'+filter_end_edit.Text)); {�˲�����֡, start-endΪһ��������100���˲���}
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/filter_ack'), '0');   {�˲���Ч}
              end;

             if ZCAN_StartCAN(init_handle)>0 then
                ListBox1.Items.Add('�ɹ�����CAN��')
             else
                ListBox1.Items.Add('����CAN��ʧ��');

              ReleaseIProperty(property_); {���������ԣ��ͷ����Խӿڡ���������ã�������ڴ�й©}
              m_connect:=1;
              threadid:=111;
              m_threadhandle:=BeginThread(0,0,ReceiveThread,@ListBox1,0,threadid);
             end;

    end else begin
        {USBCAN-E/2E/4E-U,CANalyst-II+,PCI-50X0-U��ʼ������}
        device_handle:=ZCAN_OpenDevice(device_type,device_index,reserved);
        if device_handle<1 then
           ListBox1.Items.Add('OPENʧ��,����豸�����Ƿ������������豸�Ѿ��򿪡�')
        else
           begin
              property_ := GetIProperty(device_handle);
              initconfig.can_type:=0;             //CAN
              initconfig.acc_code:=$0;           //SJA1000֡����������
              initconfig.acc_mask:=$FFFFFFFF;   //SJA1000֡����������
              initconfig.reserved:=0;
              initconfig.filter:=0;            //�˲���ʽ
              initconfig.timing0:=0;       //������
              initconfig.timing1:=0;      //������
              initconfig.mode:= mode_box.ItemIndex;   //����ģʽ��=0��ʾ����ģʽ���൱�������ڵ㣩��=1��ʾֻ��ģʽ��ֻ���գ���Ӱ�����ߣ���

              {ZCAN_InitCAN֮ǰ���ò�����}
              if custom_baud_check.Checked then begin
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/baud_rate_custom'), PAnsiChar(custom_baud_edit.Text));
              end else begin
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/baud_rate'), PAnsiChar(abit_baud_box.Text+'000'));
              end;
    
               {��ʼ��}
              init_handle:=ZCAN_InitCAN(device_handle,can_index,@initconfig);
                 if init_handle<1 then
                 begin
                  ListBox1.Items.Add('��ʼ��CANʧ��');
                  Exit;
                 end;
                 
              {�˲�����ZCAN_InitCAN��ZCAN_StartCAN֮������}
              if filter_check.Checked then begin
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/filter_clear'), '0');  {����˲�}
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/filter_mode'), PAnsiChar(inttostr(filtermode_box.ItemIndex)));  {�˲�ģʽ}
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/filter_start'), PAnsiChar('0x'+filter_start_edit.Text));   {�˲���ʼ֡}
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/filter_end'), PAnsiChar('0x'+filter_end_edit.Text)); {�˲�����֡, start-endΪһ��������100���˲���}
                 property_.SetValue(PAnsiChar(inttostr(can_index_box.ItemIndex)+'/filter_ack'), '0');   {�˲���Ч}
              end;

             if ZCAN_StartCAN(init_handle)>0 then
                ListBox1.Items.Add('�ɹ�����CAN��')
             else
                ListBox1.Items.Add('����CAN��ʧ��');

              ReleaseIProperty(property_); {���������ԣ��ͷ����Խӿڡ���������ã�������ڴ�й©}
              m_connect:=1;
              threadid:=111;
              m_threadhandle:=BeginThread(0,0,ReceiveThread,@ListBox1,0,threadid);
             end;
    end;

end;


//�����߳�
procedure TForm2.send_ButtonClick(Sender: TObject);
var
sendtype:dword;
frametype,frameformat : BYTE;
id: DWORD;
data : array[0..7] of BYTE;
data_fd : array[0..63] of BYTE;
str : AnsiString;
strdata : AnsiString;
senddata : ZCAN_Transmit_Data;
senddata_fd :ZCAN_TransmitFD_Data;
i : integer;
begin

  if m_connect=0 then
    Exit;

   if can_type_box.ItemIndex =0 then begin
        sendtype:=send_type_box.ItemIndex;
        frametype:=eff_box.ItemIndex;
        frameformat:=rtr_box.ItemIndex;

        id:=MAKE_CAN_ID(StrToInt('0x'+id_edit.Text),frametype,frameformat,0);

        str:=data_edit.Text;
        for i:=0 to 7 do
          begin
            strdata:=Copy(str,3*i+1,2);
            strdata:=Trim(strdata);
            if Length(strdata)=0 then
              break;
            data[i]:=StrToInt('0x'+strdata);
          end;
        senddata.can_id:=id;
        senddata.can_dlc:=i;
        senddata.pad:=0;
        senddata.res0:=0;
        senddata.res1:=0;
        senddata.transmit_type:=sendtype;
        Move(data,senddata.data,i);

   if ZCAN_Transmit(init_handle,@senddata,1)>0 then
        ListBox1.Items.Add('���ͳɹ�')
   else
        ListBox1.Items.Add('����ʧ��');

   end else begin
         {����CANFD֡}
        sendtype:=send_type_box.ItemIndex;
        frametype:=eff_box.ItemIndex;
        frameformat:=rtr_box.ItemIndex;

        id:=MAKE_CAN_ID(StrToInt('0x'+id_edit.Text),frametype,frameformat,0);

        str:=data_edit.Text;
        for i:=0 to 63 do
          begin
            strdata:=Copy(str,3*i+1,2);
            strdata:=Trim(strdata);
            if Length(strdata)=0 then
              break;
            data_fd[i]:=StrToInt('0x'+strdata);
          end;
        senddata_fd.can_id:=id;
        senddata_fd.len:=i;
           if canfd_brs.Checked then
               senddata_fd.flags:=$1
           else
              senddata_fd.flags:=0;
        senddata_fd.res0:=0;
        senddata_fd.res1:=0;
        senddata_fd.transmit_type:=sendtype;
        Move(data_fd,senddata_fd.data,i);

        if ZCAN_TransmitFD(init_handle,@senddata_fd,1)>0 then
          ListBox1.Items.Add('CANFD���ͳɹ�')
        else
          ListBox1.Items.Add('CANFD����ʧ��');
   end;
end;


//�����ʾ
procedure TForm2.data_clear_ButtonClick(Sender: TObject);
begin
ListBox1.Items.Clear;
end;


//�رճ���ʱ���ر�CAN��
procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if m_connect=1 then
  begin
    m_connect:=0;
    WaitForSingleObject(m_threadhandle,1000);
    m_threadhandle:=0;
    ZCAN_ResetCAN (init_handle);
    ZCAN_CloseDevice(device_handle);
  end
end;


end.




