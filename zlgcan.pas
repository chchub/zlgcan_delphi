unit zlgcan;

interface

uses
  WinTypes;



const
  DLL_NAME  = 'zlgcan.dll';//动态库名称

ZCAN_PCI5121=1 ;
ZCAN_USBCAN1=3 ;
ZCAN_USBCAN2=4 ;
ZCAN_PCI9820=5 ;
ZCAN_CAN232=6  ;
ZCAN_PCI5110=7 ;
ZCAN_CANLITE=8 ;
ZCAN_ISA9620=9 ;
ZCAN_ISA5420=10 ;
ZCAN_PC104CAN=11 ;
ZCAN_CANETUDP=12 ;
ZCAN_DNP9810=13  ;
ZCAN_PCI9840=14  ;
ZCAN_PC104CAN2=15 ;
ZCAN_PCI9820I=16 ;
ZCAN_CANETTCP=17 ;
ZCAN_PCIE_9220=18 ;
ZCAN_USBCAN_E_U=20 ;
ZCAN_USBCAN_2E_U=21 ;
ZCAN_PCI5020U=22  ;
ZCAN_EG20T_CAN= 23 ;
ZCAN_PCIE9221 =24 ;
ZCAN_WIFICAN_TCP =25  ;
ZCAN_WIFICAN_UDP = 26 ;
ZCAN_PCIe9120= 27  ;
ZCAN_PCIe9110 =28   ;
ZCAN_PCIe9140 =29 ;
ZCAN_USBCAN_4E_U=31  ;
ZCAN_CANDTU_200UR=32  ;
ZCAN_CANDTU_MINI =33  ;
ZCAN_USBCAN_8E_U =34 ;
ZCAN_CANDTU_NET =36   ;
ZCAN_CANDTU_100UR =37;
ZCAN_PCIE_CANFD_100U =38 ;
ZCAN_PCIE_CANFD_200U =39 ;
ZCAN_PCIE_CANFD_400U =40  ;
ZCAN_USBCANFD_200U  =41  ;
ZCAN_USBCANFD_100U =42  ;
ZCAN_USBCANFD_MINI   =43 ;
ZCAN_CANFDCOM_100IE = 44 ;
ZCAN_CANSCOPE      =45 ;
ZCAN_CLOUD         =46;
ZCAN_CANFDNET_TCP  =48;
ZCAN_CANFDNET_UDP   =49 ;

//CAN Type

TYPE_CAN   = 0;
TYPE_CANFD = 1;

// 错误码定义

//CAN错误码
ZCAN_ERROR_CAN_OVERFLOW       =     $1 ;
ZCAN_ERROR_CAN_ERRALARM       =     $2 ;
ZCAN_ERROR_CAN_PASSIVE        =     $4 ;
ZCAN_ERROR_CAN_LOSE           =     $8 ;
ZCAN_ERROR_CAN_BUSERR         =    $10  ;
ZCAN_ERROR_CAN_BUSOFF         =    $20  ;
ZCAN_ERROR_CAN_BUFFER_OVERFLOW   =  $40 ;
//通用错误码
ZCAN_ERROR_DEVICEOPENED         =   $100 ;
ZCAN_ERROR_DEVICEOPEN           =  $200  ;
ZCAN_ERROR_DEVICENOTOPEN        =   $400 ;
ZCAN_ERROR_BUFFEROVERFLOW       =   $800 ;
ZCAN_ERROR_DEVICENOTEXIST       =   $1000 ;
ZCAN_ERROR_LOADKERNELDLL        =   $2000 ;
ZCAN_ERROR_CMDFAILED            =   $4000 ;
ZCAN_ERROR_BUFFERCREATE         =   $8000 ;

ZCAN_ERROR_CANETE_PORTOPENED    =   $10000 ;
ZCAN_ERROR_CANETE_INDEXUSED     =   $20000 ;
ZCAN_ERROR_REF_TYPE_ID          =   $30001 ;
ZCAN_ERROR_CREATE_SOCKET        =   $30002 ;
ZCAN_ERROR_OPEN_CONNECT         =   $30003 ;
ZCAN_ERROR_NO_STARTUP           =   $30004 ;
ZCAN_ERROR_NO_CONNECTED         =   $30005 ;
ZCAN_ERROR_SEND_PARTIAL         =   $30006 ;
ZCAN_ERROR_SEND_TOO_FAST        =   $30007 ;

type

//声明各个数据结构

//1.ZLGCAN系列接口卡信息的数据类型。
ZCAN_DEVICE_INFO = Record
		hw_Version : Word;
		fw_Version : Word;
		dr_Version : Word;
		in_Version : Word;
		irq_Num : Word;
		can_Num : BYTE;
		str_Serial_Num : array[0..19] of CHAR;
		str_hw_Type : array[0..39] of CHAR;
		Reserved : array[0..3] of Word;
END;

PZCAN_DEVICE_INFO=^ZCAN_DEVICE_INFO;


 //2.定义CAN帧发送结构

ZCAN_Transmit_Data = Record
  can_id  : Word;
  can_dlc : BYTE;
  pad    : BYTE;
  res0   :BYTE;
  res1   :BYTE;
  data   :array[0..7] of BYTE;
  transmit_type  : Word;
 End;

 PZCAN_Transmit_Data  = ^ZCAN_Transmit_Data;


 //3.定义CAN帧接收结构

ZCAN_Receive_Data = Record
  can_id  : Word;
  can_dlc : BYTE;
  pad    : BYTE;
  res0   :BYTE;
  res1   :BYTE;
  data   :array[0..7] of BYTE;
  timestamp  : Uint64;   //us
 End;

 PZCAN_Receive_Data  = ^ZCAN_Receive_Data;


 //4.定义CANFD帧发送结构

ZCAN_TransmitFD_Data = Record
  can_id  : Word;
  len : BYTE;
  res    : BYTE; //brs(1)+esi(1)+_res(6)
  res0   : BYTE;
  res1   : BYTE;
  data   :array[0..63] of BYTE;
  transmit_type  : Word;
 End;

 PZCAN_TransmitFD_Data  = ^ZCAN_TransmitFD_Data;


 //5.定义CANFD帧接收结构

ZCAN_ReceiveFD_Data = Record
  can_id  : Word;
  len : BYTE;
  res    : BYTE; //brs(1)+esi(1)+_res(6)
  res0   : BYTE;
  res1   : BYTE;
  data   :array[0..63] of BYTE;
  timestamp  : Uint64;  //us
 End;

 PZCAN_ReceiveFD_Data  = ^ZCAN_ReceiveFD_Data;


//5.定义初始化CANFD的数据类型
ZCAN_INIT_CONFIG_CANFD = Record
	acc_code : Word;
	acc_mask : Word;
	abit_timing : Word;
	dbit_timing : Word;
	brp : Word;  //波特率预分频因子，设置为0
	filter : BYTE;
	mode : BYTE;
  pad  : Word;
  reserved : Word;
END;

PZCAN_INIT_CONFIG_CANFD = ^ZCAN_INIT_CONFIG_CANFD;
                    
//导入动态库函数
 function ZCAN_OpenDevice ( device_type  : DWord;
                          device_index : DWord;
                          reserved : DWord) : THandle;
 stdcall;
 external DLL_NAME;

function ZCAN_CloseDevice ( device_handle :THandle ) : Word;
  stdcall;
  external DLL_NAME;

function ZCAN_InitCAN ( device_handle :THandle;
                       can_index : Word;
                       pInitConfig : PZCAN_INIT_CONFIG_CANFD) : THandle;
  stdcall;
  external DLL_NAME;                        

function ZCAN_StartCAN ( ZCAN_InitCAN  : THandle) : Word;
  stdcall;
  external DLL_NAME;

function ZCAN_ResetCAN ( ZCAN_InitCAN  : THandle) : Word;
  stdcall;
  external DLL_NAME;

function ZCAN_ClearBuffer ( ZCAN_InitCAN  : THandle) : Word;
  stdcall;
  external DLL_NAME;

function ZCAN_GetReceiveNum( ZCAN_InitCAN  : THandle;
                             dev_type : BYTE) : Word;
  stdcall;
  external DLL_NAME;

function ZCAN_Transmit ( ZCAN_InitCAN  : THandle;
                         pTransmit : PZCAN_Transmit_Data;
                         len : Word) : Word;
  stdcall;
  external DLL_NAME;

function ZCAN_Receive ( ZCAN_InitCAN  : THandle;
                        pReceive : PZCAN_Receive_Data;
                        len : Word;
                        wait_time: Integer) : Word;
  stdcall;
  external DLL_NAME;

function ZCAN_TransmitFD ( ZCAN_InitCAN  : THandle;
                         pTransmit : PZCAN_TransmitFD_Data;
                         len : Word) : Word;
  stdcall;
  external DLL_NAME;

function ZCAN_ReceiveFD ( ZCAN_InitCAN  : THandle;
                        pReceive : PZCAN_ReceiveFD_Data;
                        len : Word;
                        wait_time: Integer) : Word;

  stdcall;
  external DLL_NAME;


implementation

end.
